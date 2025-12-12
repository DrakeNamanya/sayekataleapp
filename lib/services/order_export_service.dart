import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart' as app_order;

class OrderExportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all PSA orders with user details for export
  Future<List<Map<String, dynamic>>> getPSAOrdersForExport(
    String psaId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Base query for PSA's orders (simple query to avoid index requirement)
      Query query = _firestore
          .collection('orders')
          .where('farmer_id', isEqualTo: psaId);

      final orderSnapshot = await query.get();

      // Filter by date in memory to avoid composite index requirement
      List<QueryDocumentSnapshot> filteredDocs = orderSnapshot.docs;
      
      if (startDate != null || endDate != null) {
        filteredDocs = orderSnapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final createdAt = data['created_at'] as Timestamp?;
          
          if (createdAt == null) return false;
          
          final orderDate = createdAt.toDate();
          
          if (startDate != null && orderDate.isBefore(startDate)) {
            return false;
          }
          
          if (endDate != null && orderDate.isAfter(endDate)) {
            return false;
          }
          
          return true;
        }).toList();
      }

      // Sort in memory by created_at (most recent first)
      filteredDocs.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        final aTime = aData['created_at'] as Timestamp?;
        final bTime = bData['created_at'] as Timestamp?;
        
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      List<Map<String, dynamic>> exportData = [];

      for (var orderDoc in filteredDocs) {
        final orderData = orderDoc.data() as Map<String, dynamic>;
        final order =
            app_order.Order.fromFirestore(orderData, orderDoc.id);

        // Get buyer user details
        String buyerName = 'Unknown';
        String buyerDistrict = 'Not Set';
        String buyerContact = 'Unknown';

        try {
          final userDoc =
              await _firestore.collection('users').doc(order.buyerId).get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            buyerName = userData['name'] ?? userData['full_name'] ?? 'Unknown';
            
            // Try multiple field names for district from buyer's profile
            String? districtValue;
            
            // First, check if location object exists
            if (userData['location'] != null) {
              final location = userData['location'] as Map<String, dynamic>;
              districtValue = location['district'] as String?;
            }
            
            // Fallback: check direct district field
            if (districtValue == null || districtValue.isEmpty) {
              districtValue = userData['district'] as String?;
            }
            
            // Fallback: check location_district field
            if (districtValue == null || districtValue.isEmpty) {
              districtValue = userData['location_district'] as String?;
            }
            
            // Only show "Not Set" if user truly didn't set a district
            buyerDistrict = (districtValue != null && districtValue.isNotEmpty) 
                ? districtValue 
                : 'Not Set';
            
            buyerContact = userData['phone'] ?? userData['contact'] ?? userData['mobile'] ?? 'Unknown';
          } else {
            if (kDebugMode) {
              debugPrint('User document not found for buyer ID: ${order.buyerId}');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error fetching user details for ${order.buyerId}: $e');
          }
        }

        // Process order items
        final items = orderData['items'] as List<dynamic>? ?? [];
        String productNames = items
            .map((item) => item['productName'] ?? 'Unknown')
            .join(', ');
        String productQuantities = items
            .map((item) =>
                '${item['productName']}: ${item['quantity']}')
            .join(', ');

        exportData.add({
          'Order ID': order.id,
          'Order Date': DateFormat('yyyy-MM-dd HH:mm')
              .format(order.createdAt),
          'Buyer Name': buyerName,
          'Buyer Contact': buyerContact,
          'District': buyerDistrict,
          'Products Ordered': productNames,
          'Product Details': productQuantities,
          'Total Amount': 'UGX ${order.totalAmount.toStringAsFixed(0)}',
          'Status': _getStatusDisplayName(order.status),
          'Payment Status': order.transactionId != null ? 'Paid' : 'Pending',
          'Delivery Address': order.deliveryAddress ?? 'N/A',
        });
      }

      return exportData;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting PSA orders for export: $e');
      }
      rethrow;
    }
  }

  String _getStatusDisplayName(app_order.OrderStatus status) {
    switch (status) {
      case app_order.OrderStatus.pending:
        return 'Pending';
      case app_order.OrderStatus.paymentPending:
        return 'Payment Pending';
      case app_order.OrderStatus.paymentHeld:
        return 'Payment Held';
      case app_order.OrderStatus.deliveryPending:
        return 'Delivery Pending';
      case app_order.OrderStatus.deliveredPendingConfirmation:
        return 'Delivered - Pending Confirmation';
      case app_order.OrderStatus.confirmed:
        return 'Confirmed';
      case app_order.OrderStatus.completed:
        return 'Completed';
      case app_order.OrderStatus.cancelled:
        return 'Cancelled';
      case app_order.OrderStatus.codPendingBothConfirmation:
        return 'COD - Pending Both Confirmation';
      case app_order.OrderStatus.codOverdue:
        return 'COD - Overdue';
      case app_order.OrderStatus.preparing:
        return 'Preparing';
      case app_order.OrderStatus.ready:
        return 'Ready for Pickup';
      case app_order.OrderStatus.inTransit:
        return 'In Transit';
      case app_order.OrderStatus.delivered:
        return 'Delivered';
      case app_order.OrderStatus.rejected:
        return 'Rejected';
    }
  }

  /// Export PSA orders to CSV file
  Future<String?> exportToCSV(
    String psaId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final ordersData = await getPSAOrdersForExport(
        psaId,
        startDate: startDate,
        endDate: endDate,
      );

      if (ordersData.isEmpty) {
        return null;
      }

      // Get headers from first item
      final headers = ordersData.first.keys.toList();

      // Convert data to rows
      List<List<dynamic>> rows = [headers];
      for (var order in ordersData) {
        rows.add(headers.map((header) => order[header]).toList());
      }

      // Convert to CSV string
      final csvString = const ListToCsvConverter().convert(rows);

      // Save to file
      if (kIsWeb) {
        // For web, return the CSV string directly (will be handled by download)
        return csvString;
      } else {
        // For mobile, save to app directory
        final directory = await getApplicationDocumentsDirectory();
        final fileName =
            'PSA_Orders_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(csvString);
        return file.path;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error exporting to CSV: $e');
      }
      rethrow;
    }
  }

  /// Export PSA orders to PDF file
  Future<String?> exportToPDF(
    String psaId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final ordersData = await getPSAOrdersForExport(
        psaId,
        startDate: startDate,
        endDate: endDate,
      );

      if (ordersData.isEmpty) {
        return null;
      }

      final pdf = pw.Document();

      // Split orders into chunks for multiple pages
      const itemsPerPage = 10;
      for (int i = 0; i < ordersData.length; i += itemsPerPage) {
        final pageOrders = ordersData.skip(i).take(itemsPerPage).toList();

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (context) {
              return [
                // Header
                pw.Header(
                  level: 0,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SAYE KATALE - PSA Orders Report',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      if (startDate != null || endDate != null) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Period: ${startDate != null ? DateFormat('MMM dd, yyyy').format(startDate) : 'All'} - ${endDate != null ? DateFormat('MMM dd, yyyy').format(endDate) : 'Present'}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                      pw.Divider(thickness: 2),
                    ],
                  ),
                ),

                // Orders table
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.5), // Order Date
                    1: const pw.FlexColumnWidth(2), // Buyer Name
                    2: const pw.FlexColumnWidth(1.5), // Contact
                    3: const pw.FlexColumnWidth(1.5), // District
                    4: const pw.FlexColumnWidth(2.5), // Products
                    5: const pw.FlexColumnWidth(1.5), // Amount
                    6: const pw.FlexColumnWidth(1.5), // Status
                  },
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        'Order Date',
                        'Buyer',
                        'Contact',
                        'District',
                        'Products',
                        'Amount',
                        'Status',
                      ]
                          .map((header) => pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(
                                  header,
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 9,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),

                    // Data rows
                    ...pageOrders.map((order) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              (order['Order Date'] as String)
                                  .split(' ')
                                  .first,
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              order['Buyer Name'] as String,
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              order['Buyer Contact'] as String,
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              order['District'] as String,
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              order['Products Ordered'] as String,
                              style: const pw.TextStyle(fontSize: 7),
                              maxLines: 2,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              (order['Total Amount'] as String)
                                  .replaceAll('UGX ', ''),
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              order['Status'] as String,
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),

                // Summary
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Summary',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Total Orders: ${ordersData.length}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'Page ${(i ~/ itemsPerPage) + 1} of ${(ordersData.length / itemsPerPage).ceil()}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),
        );
      }

      // Save PDF - return base64 encoded string for web
      if (kIsWeb) {
        final bytes = await pdf.save();
        // Return base64 encoded string for web
        return base64Encode(bytes);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final fileName =
            'PSA_Orders_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(await pdf.save());
        return file.path;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error exporting to PDF: $e');
      }
      rethrow;
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'package:intl/intl.dart';

/// Web implementation of CSV export service
class CsvExportServiceImpl {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Download CSV file in browser
  void downloadFile(String filename, List<int> bytes) {
    final blob = html.Blob([bytes]);

    // Create download link
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  /// Export users collection to CSV
  Future<void> exportUsers() async {
    try {
      // Fetch all users from Firestore
      final querySnapshot = await _firestore.collection('users').get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('No users found to export');
      }

      // Define CSV headers
      List<List<dynamic>> rows = [
        [
          'ID',
          'Name',
          'Email',
          'Phone',
          'Role',
          'Verification Status',
          'Created At',
          'Updated At',
        ],
      ];

      // Add data rows
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        rows.add([
          doc.id,
          data['name'] ?? '',
          data['email'] ?? '',
          data['phone'] ?? '',
          data['role'] ?? '',
          data['verification_status'] ?? '',
          data['created_at'] != null
              ? DateFormat(
                  'yyyy-MM-dd HH:mm',
                ).format((data['created_at'] as Timestamp).toDate())
              : '',
          data['updated_at'] != null
              ? DateFormat(
                  'yyyy-MM-dd HH:mm',
                ).format((data['updated_at'] as Timestamp).toDate())
              : '',
        ]);
      }

      // Convert to CSV
      String csv = const ListToCsvConverter().convert(rows);

      // Download file
      final bytes = utf8.encode(csv);
      final filename =
          'users_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      downloadFile(filename, bytes);
    } catch (e) {
      throw Exception('Failed to export users: $e');
    }
  }

  /// Export products collection to CSV
  Future<void> exportProducts() async {
    try {
      final querySnapshot = await _firestore.collection('products').get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('No products found to export');
      }

      List<List<dynamic>> rows = [
        [
          'ID',
          'Name',
          'Description',
          'Category',
          'Price',
          'Unit',
          'Stock',
          'Farmer ID',
          'Status',
          'Created At',
        ],
      ];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        rows.add([
          doc.id,
          data['name'] ?? '',
          data['description'] ?? '',
          data['category'] ?? '',
          data['price']?.toString() ?? '',
          data['unit'] ?? '',
          data['stock']?.toString() ?? '',
          data['farmer_id'] ?? '',
          data['status'] ?? '',
          data['created_at'] != null
              ? DateFormat(
                  'yyyy-MM-dd HH:mm',
                ).format((data['created_at'] as Timestamp).toDate())
              : '',
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);
      final bytes = utf8.encode(csv);
      final filename =
          'products_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      downloadFile(filename, bytes);
    } catch (e) {
      throw Exception('Failed to export products: $e');
    }
  }

  /// Export orders collection to CSV
  Future<void> exportOrders() async {
    try {
      final querySnapshot = await _firestore.collection('orders').get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('No orders found to export');
      }

      List<List<dynamic>> rows = [
        [
          'Order ID',
          'Buyer ID',
          'Seller ID',
          'Total Amount',
          'Status',
          'Order Type',
          'Created At',
          'Updated At',
        ],
      ];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        rows.add([
          doc.id,
          data['buyer_id'] ?? '',
          data['seller_id'] ?? '',
          data['total_amount']?.toString() ?? '',
          data['status'] ?? '',
          data['order_type'] ?? '',
          data['created_at'] != null
              ? DateFormat(
                  'yyyy-MM-dd HH:mm',
                ).format((data['created_at'] as Timestamp).toDate())
              : '',
          data['updated_at'] != null
              ? DateFormat(
                  'yyyy-MM-dd HH:mm',
                ).format((data['updated_at'] as Timestamp).toDate())
              : '',
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);
      final bytes = utf8.encode(csv);
      final filename =
          'orders_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      downloadFile(filename, bytes);
    } catch (e) {
      throw Exception('Failed to export orders: $e');
    }
  }

  /// Export complaints collection to CSV
  Future<void> exportComplaints() async {
    try {
      final querySnapshot = await _firestore.collection('complaints').get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('No complaints found to export');
      }

      List<List<dynamic>> rows = [
        [
          'ID',
          'Order ID',
          'Complainant ID',
          'Subject',
          'Description',
          'Status',
          'Priority',
          'Created At',
          'Resolved At',
        ],
      ];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        rows.add([
          doc.id,
          data['order_id'] ?? '',
          data['complainant_id'] ?? '',
          data['subject'] ?? '',
          data['description'] ?? '',
          data['status'] ?? '',
          data['priority'] ?? '',
          data['created_at'] != null
              ? DateFormat(
                  'yyyy-MM-dd HH:mm',
                ).format((data['created_at'] as Timestamp).toDate())
              : '',
          data['resolved_at'] != null
              ? DateFormat(
                  'yyyy-MM-dd HH:mm',
                ).format((data['resolved_at'] as Timestamp).toDate())
              : '',
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);
      final bytes = utf8.encode(csv);
      final filename =
          'complaints_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      downloadFile(filename, bytes);
    } catch (e) {
      throw Exception('Failed to export complaints: $e');
    }
  }
}

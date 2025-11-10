import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

/// Service for exporting Firestore data to CSV files
/// Web-only functionality using dart:html for browser downloads
class CsvExportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Export users collection to CSV
  Future<void> exportUsers() async {
    if (!kIsWeb) {
      throw UnsupportedError('CSV export is only available on web platform');
    }

    try {
      // Fetch all users from Firestore
      final querySnapshot = await _firestore.collection('users').get();
      
      if (querySnapshot.docs.isEmpty) {
        throw Exception('No users found to export');
      }

      // Define CSV headers
      List<List<dynamic>> rows = [
        [
          'User ID',
          'Name',
          'Email',
          'Phone',
          'Role',
          'District',
          'Village/Town',
          'Verification Status',
          'Account Status',
          'Registration Date',
          'Last Login',
        ]
      ];

      // Add data rows
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        
        // Safely extract location data
        String district = '';
        String village = '';
        try {
          final location = data['location'];
          if (location != null && location is Map) {
            district = location['district']?.toString() ?? '';
            village = location['village']?.toString() ?? '';
          }
        } catch (e) {
          // Handle any location parsing errors
          district = '';
          village = '';
        }
        
        rows.add([
          data['id'] ?? doc.id,
          data['name'] ?? '',
          data['email'] ?? '',
          data['phone'] ?? '',
          data['role'] ?? '',
          district,
          village,
          data['verification_status'] ?? '',
          data['account_status'] ?? '',
          _formatDateTime(data['created_at']),
          _formatDateTime(data['last_login']),
        ]);
      }

      // Generate and download CSV
      String csv = const ListToCsvConverter().convert(rows);
      _downloadCsv(csv, 'users_export_${_getTimestamp()}.csv');
    } catch (e) {
      rethrow;
    }
  }

  /// Export products collection to CSV
  Future<void> exportProducts() async {
    if (!kIsWeb) {
      throw UnsupportedError('CSV export is only available on web platform');
    }

    try {
      final querySnapshot = await _firestore.collection('products').get();
      
      if (querySnapshot.docs.isEmpty) {
        throw Exception('No products found to export');
      }

      List<List<dynamic>> rows = [
        [
          'Product ID',
          'Title',
          'Category',
          'Sub-category',
          'Price (UGX)',
          'Unit',
          'Stock Quantity',
          'Seller ID',
          'Seller Name',
          'District',
          'Status',
          'Verification Status',
          'Views',
          'Favorites',
          'Created Date',
        ]
      ];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        rows.add([
          doc.id,
          data['title'] ?? '',
          data['category'] ?? '',
          data['sub_category'] ?? '',
          data['price'] ?? 0,
          data['unit'] ?? '',
          data['stock_quantity'] ?? 0,
          data['seller_id'] ?? '',
          data['seller_name'] ?? '',
          data['location']?['district'] ?? '',
          data['status'] ?? '',
          data['verification_status'] ?? '',
          data['views'] ?? 0,
          data['favorites_count'] ?? 0,
          _formatDateTime(data['created_at']),
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);
      _downloadCsv(csv, 'products_export_${_getTimestamp()}.csv');
    } catch (e) {
      rethrow;
    }
  }

  /// Export orders collection to CSV
  Future<void> exportOrders() async {
    if (!kIsWeb) {
      throw UnsupportedError('CSV export is only available on web platform');
    }

    try {
      final querySnapshot = await _firestore.collection('orders').get();
      
      if (querySnapshot.docs.isEmpty) {
        throw Exception('No orders found to export');
      }

      List<List<dynamic>> rows = [
        [
          'Order ID',
          'User ID',
          'User Name',
          'Farmer ID',
          'Farmer Name',
          'Products',
          'Quantity',
          'Cost (UGX)',
          'Status',
          'Payment Method',
          'Date of Order',
        ]
      ];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString();
        
        // Extract products from items array
        String productNames = '';
        int totalQuantity = 0;
        if (data['items'] is List) {
          final items = data['items'] as List;
          productNames = items.map((item) => item['product_name'] ?? 'Unknown').join(', ');
          for (var item in items) {
            totalQuantity += (item['quantity'] ?? 0) as int;
          }
        }
        
        rows.add([
          data['order_number'] ?? doc.id,
          data['buyer_system_id'] ?? data['buyer_id'] ?? '',
          data['buyer_name'] ?? 'Unknown',
          data['farmer_system_id'] ?? data['farmer_id'] ?? '',
          data['farmer_name'] ?? 'Unknown',
          productNames,
          totalQuantity,
          data['total_amount'] ?? 0,
          status,
          data['payment_method'] ?? '',
          _formatDateTime(data['created_at']),
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);
      _downloadCsv(csv, 'orders_export_${_getTimestamp()}.csv');
    } catch (e) {
      rethrow;
    }
  }

  /// Export complaints collection to CSV
  Future<void> exportComplaints() async {
    if (!kIsWeb) {
      throw UnsupportedError('CSV export is only available on web platform');
    }

    try {
      final querySnapshot = await _firestore.collection('user_complaints').get();
      
      if (querySnapshot.docs.isEmpty) {
        throw Exception('No complaints found to export');
      }

      List<List<dynamic>> rows = [
        [
          'Complaint ID',
          'User ID',
          'User Name',
          'Subject',
          'Category',
          'Priority',
          'Status',
          'Has Attachments',
          'Admin Response',
          'Created Date',
          'Updated Date',
          'Resolved Date',
        ]
      ];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final attachments = data['attachments'] as List?;
        rows.add([
          doc.id,
          data['user_id'] ?? '',
          data['user_name'] ?? '',
          data['subject'] ?? '',
          data['category'] ?? '',
          data['priority'] ?? '',
          data['status'] ?? '',
          attachments != null && attachments.isNotEmpty ? 'Yes' : 'No',
          data['admin_response'] ?? '',
          _formatDateTime(data['created_at']),
          _formatDateTime(data['updated_at']),
          _formatDateTime(data['resolved_at']),
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);
      _downloadCsv(csv, 'complaints_export_${_getTimestamp()}.csv');
    } catch (e) {
      rethrow;
    }
  }

  /// Helper: Format DateTime to readable string
  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return '';
    
    try {
      DateTime dt;
      if (dateTime is Timestamp) {
        dt = dateTime.toDate();
      } else if (dateTime is String) {
        dt = DateTime.parse(dateTime);
      } else {
        return '';
      }
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
    } catch (e) {
      return '';
    }
  }

  /// Helper: Get current timestamp for filename
  String _getTimestamp() {
    return DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  }

  /// Helper: Trigger browser download of CSV file
  void _downloadCsv(String csvContent, String filename) {
    // Create a blob from the CSV content
    final bytes = utf8.encode(csvContent);
    final blob = html.Blob([bytes]);
    
    // Create a download link and trigger it
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    
    // Clean up
    html.Url.revokeObjectUrl(url);
  }
}

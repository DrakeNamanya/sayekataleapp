// Firebase Integration Test
// Tests Firebase connection and Firestore queries

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Test Firebase connection and basic Firestore operations
class FirebaseTest {
  /// Test 1: Check Firebase initialization
  static Future<bool> testFirebaseInitialization() async {
    try {
      if (kDebugMode) {
        print('🔥 Test 1: Firebase Initialization');
      }

      // Firebase is already initialized in main.dart
      // This test just confirms we can access Firestore
      final _ = FirebaseFirestore.instance;

      if (kDebugMode) {
        print('✅ Firebase initialized successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firebase initialization failed: $e');
      }
      return false;
    }
  }

  /// Test 2: Fetch products from Firestore
  static Future<bool> testFetchProducts() async {
    try {
      if (kDebugMode) {
        print('\n🔥 Test 2: Fetch Products');
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .limit(5)
          .get();

      if (kDebugMode) {
        print('✅ Found ${snapshot.docs.length} products');

        // Display first 3 products
        for (var i = 0; i < snapshot.docs.length && i < 3; i++) {
          final data = snapshot.docs[i].data();
          print('  ${i + 1}. ${data['name']} - UGX ${data['price']}');
        }
      }

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to fetch products: $e');
      }
      return false;
    }
  }

  /// Test 3: Fetch users from Firestore
  static Future<bool> testFetchUsers() async {
    try {
      if (kDebugMode) {
        print('\n🔥 Test 3: Fetch Users');
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .limit(3)
          .get();

      if (kDebugMode) {
        print('✅ Found ${snapshot.docs.length} users');

        // Display users by role
        for (var doc in snapshot.docs) {
          final data = doc.data();
          print('  • ${data['name']} (${data['role']})');
        }
      }

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to fetch users: $e');
      }
      return false;
    }
  }

  /// Test 4: Fetch bookings from Firestore
  static Future<bool> testFetchBookings() async {
    try {
      if (kDebugMode) {
        print('\n🔥 Test 4: Fetch Bookings');
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .get();

      if (kDebugMode) {
        print('✅ Found ${snapshot.docs.length} bookings');

        // Count by status
        final pending = snapshot.docs
            .where((d) => d.data()['status'] == 'pending')
            .length;
        final confirmed = snapshot.docs
            .where((d) => d.data()['status'] == 'confirmed')
            .length;
        final completed = snapshot.docs
            .where((d) => d.data()['status'] == 'completed')
            .length;

        print('  • Pending: $pending');
        print('  • Confirmed: $confirmed');
        print('  • Completed: $completed');
      }

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to fetch bookings: $e');
      }
      return false;
    }
  }

  /// Test 5: Test collection counts
  static Future<bool> testCollectionCounts() async {
    try {
      if (kDebugMode) {
        print('\n🔥 Test 5: Collection Counts');
      }

      final collections = [
        'users',
        'products',
        'bookings',
        'messages',
        'consultations',
      ];

      for (var collection in collections) {
        final count =
            (await FirebaseFirestore.instance.collection(collection).get())
                .docs
                .length;
        if (kDebugMode) {
          print('  • $collection: $count documents');
        }
      }

      if (kDebugMode) {
        print('✅ All collections accessible');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to count collections: $e');
      }
      return false;
    }
  }

  /// Run all tests
  static Future<Map<String, bool>> runAllTests() async {
    if (kDebugMode) {
      print('═' * 70);
      print('🧪 FIREBASE INTEGRATION TESTS');
      print('═' * 70);
    }

    final results = <String, bool>{};

    results['initialization'] = await testFirebaseInitialization();
    results['products'] = await testFetchProducts();
    results['users'] = await testFetchUsers();
    results['bookings'] = await testFetchBookings();
    results['collections'] = await testCollectionCounts();

    if (kDebugMode) {
      print('\n${'═' * 70}');
      print('📊 TEST RESULTS SUMMARY');
      print('═' * 70);

      final passed = results.values.where((r) => r).length;
      final total = results.length;

      results.forEach((test, passed) {
        print('${passed ? '✅' : '❌'} $test: ${passed ? 'PASSED' : 'FAILED'}');
      });

      print('\n🎯 Total: $passed/$total tests passed');

      if (passed == total) {
        print('🎉 ALL TESTS PASSED - Firebase integration working perfectly!');
      } else {
        print('⚠️  Some tests failed - check error messages above');
      }
      print('═' * 70);
    }

    return results;
  }
}

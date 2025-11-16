import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

/// Firebase Authentication Service
/// Handles phone OTP authentication and user management with Firestore
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current Firebase user
  User? get currentFirebaseUser => _auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ============================================================================
  // PHONE AUTHENTICATION
  // ============================================================================

  /// Send OTP to phone number
  /// Returns verification ID for OTP verification
  Future<String> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required Function(PhoneAuthCredential credential) onAutoVerify,
  }) async {
    String verificationId = '';

    try {
      // Ensure phone number is in international format
      String formattedPhone = phoneNumber;
      if (!phoneNumber.startsWith('+')) {
        // Uganda country code
        formattedPhone = '+256${phoneNumber.replaceFirst('0', '')}';
      }

      if (kDebugMode) {
        debugPrint('📱 Sending OTP to: $formattedPhone');
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),

        // Auto-verification successful (instant login without OTP)
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (kDebugMode) {
            debugPrint('✅ Auto-verification completed');
          }
          onAutoVerify(credential);
        },

        // Auto-verification failed (user needs to enter OTP)
        verificationFailed: (FirebaseAuthException e) {
          if (kDebugMode) {
            debugPrint('❌ Verification failed: ${e.message}');
          }

          String errorMessage = 'Verification failed';
          if (e.code == 'invalid-phone-number') {
            errorMessage = 'Invalid phone number format';
          } else if (e.code == 'too-many-requests') {
            errorMessage = 'Too many attempts. Please try again later.';
          } else if (e.code == 'quota-exceeded') {
            errorMessage = 'SMS quota exceeded. Please try again later.';
          } else {
            errorMessage = e.message ?? 'Verification failed';
          }

          onError(errorMessage);
        },

        // OTP sent successfully
        codeSent: (String verId, int? resendToken) {
          if (kDebugMode) {
            debugPrint('📨 OTP sent. Verification ID: $verId');
          }
          verificationId = verId;
          onCodeSent(verId);
        },

        // Auto-retrieval timeout
        codeAutoRetrievalTimeout: (String verId) {
          if (kDebugMode) {
            debugPrint('⏱️ Auto-retrieval timeout');
          }
          verificationId = verId;
        },
      );

      return verificationId;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error sending OTP: $e');
      }
      onError('Failed to send OTP: ${e.toString()}');
      rethrow;
    }
  }

  /// Verify OTP code
  Future<UserCredential> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🔐 Verifying OTP code...');
      }

      // Create credential with verification ID and SMS code
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // Sign in with credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      if (kDebugMode) {
        debugPrint(
          '✅ OTP verified successfully. UID: ${userCredential.user?.uid}',
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ OTP verification failed: ${e.message}');
      }

      String errorMessage = 'Invalid OTP code';
      if (e.code == 'invalid-verification-code') {
        errorMessage = 'Invalid OTP code. Please try again.';
      } else if (e.code == 'session-expired') {
        errorMessage = 'OTP expired. Please request a new code.';
      } else {
        errorMessage = e.message ?? 'Verification failed';
      }

      throw FirebaseAuthException(code: e.code, message: errorMessage);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error verifying OTP: $e');
      }
      rethrow;
    }
  }

  /// Sign in with phone credential (for auto-verification)
  Future<UserCredential> signInWithCredential(
    PhoneAuthCredential credential,
  ) async {
    try {
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      if (kDebugMode) {
        debugPrint(
          '✅ Signed in with credential. UID: ${userCredential.user?.uid}',
        );
      }

      return userCredential;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error signing in with credential: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // USER MANAGEMENT WITH FIRESTORE
  // ============================================================================

  /// Create or update user profile in Firestore
  Future<AppUser> createOrUpdateUser({
    required String uid,
    required String name,
    required String phone,
    required UserRole role,
    AppUser? existingUser,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);

      // Check if user exists
      final userDoc = await userRef.get();

      if (userDoc.exists) {
        // User exists, fetch and return existing user data
        if (kDebugMode) {
          debugPrint('👤 User exists. Fetching data...');
        }

        return AppUser.fromFirestore(userDoc.data()!, uid);
      } else {
        // New user, create profile
        if (kDebugMode) {
          debugPrint('✨ Creating new user profile...');
        }

        // ✅ FIXED: Use Firebase UID as id field (not generated system ID)
        // Generate system ID for display purposes only
        final systemId = await _generateUserId(role);

        // Set profile completion deadline (24 hours from now)
        final profileDeadline = DateTime.now().add(const Duration(hours: 24));

        // Create new user
        final newUser = AppUser(
          id: uid, // ✅ Use Firebase UID, not generated system ID
          name: name,
          phone: phone,
          role: role,
          isProfileComplete: false,
          profileCompletionDeadline: profileDeadline,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Save to Firestore
        final userData = newUser.toFirestore();
        // ✅ Store system_id as separate field for display/customer support
        userData['system_id'] = systemId;
        await userRef.set(userData);

        if (kDebugMode) {
          debugPrint('✅ User profile created: $uid');
        }

        return newUser;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating/updating user: $e');
      }
      rethrow;
    }
  }

  /// Get user profile from Firestore
  Future<AppUser?> getUserProfile(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        return AppUser.fromFirestore(userDoc.data()!, uid);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching user profile: $e');
      }
      return null;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();

      await _firestore.collection('users').doc(uid).update(data);

      if (kDebugMode) {
        debugPrint('✅ User profile updated');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating user profile: $e');
      }
      rethrow;
    }
  }

  /// Generate unique user ID based on role
  Future<String> _generateUserId(UserRole role) async {
    try {
      // Get count of users with this role
      final roleStr = role.toString().split('.').last.toUpperCase();
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: roleStr)
          .get();

      final userCount = querySnapshot.docs.length;

      // Generate ID: SHG-00001, SME-00001, PSA-00001
      final userId = '$roleStr-${(userCount + 1).toString().padLeft(5, '0')}';

      return userId;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error generating user ID: $e');
      }
      // Fallback to timestamp-based ID
      return '${role.toString().split('.').last.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // ============================================================================
  // SIGN OUT
  // ============================================================================

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();

      if (kDebugMode) {
        debugPrint('👋 User signed out');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error signing out: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Format phone number for Firebase (Uganda)
  String formatPhoneNumber(String phone) {
    // Remove all non-digit characters
    String digitsOnly = phone.replaceAll(RegExp(r'\D'), '');

    // Handle different formats
    if (digitsOnly.startsWith('256')) {
      // Already has country code
      return '+$digitsOnly';
    } else if (digitsOnly.startsWith('0')) {
      // Remove leading 0 and add country code
      return '+256${digitsOnly.substring(1)}';
    } else if (digitsOnly.length == 9) {
      // Just 9 digits, add country code
      return '+256$digitsOnly';
    } else {
      // Assume it needs country code
      return '+256$digitsOnly';
    }
  }

  /// Check if phone number is valid Uganda format
  bool isValidUgandaPhone(String phone) {
    // Remove all non-digit characters
    String digitsOnly = phone.replaceAll(RegExp(r'\D'), '');

    // Valid formats:
    // - 0712345678 (10 digits starting with 0)
    // - 712345678 (9 digits starting with 7)
    // - 256712345678 (12 digits starting with 256)

    if (digitsOnly.length == 10 && digitsOnly.startsWith('0')) {
      return digitsOnly[1] == '7'; // Second digit must be 7
    } else if (digitsOnly.length == 9) {
      return digitsOnly.startsWith('7');
    } else if (digitsOnly.length == 12 && digitsOnly.startsWith('256')) {
      return digitsOnly[3] == '7'; // Fourth digit must be 7
    }

    return false;
  }
}

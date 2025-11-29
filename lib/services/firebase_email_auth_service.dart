import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

/// Firebase Email Authentication Service
/// Handles email/password authentication and user management with Firestore
/// FREE alternative to phone authentication
class FirebaseEmailAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current Firebase user
  User? get currentFirebaseUser => _auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ============================================================================
  // EMAIL AUTHENTICATION (FREE - No SMS costs!)
  // ============================================================================

  /// Sign up with email and password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserRole role,
    String? district,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('📧 Signing up with email: $email');
      }

      // Create user with email and password
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (kDebugMode) {
        debugPrint('✅ User created. UID: ${userCredential.user?.uid}');
      }

      // Update display name
      await userCredential.user?.updateDisplayName(name);

      // Send email verification
      await userCredential.user?.sendEmailVerification();

      if (kDebugMode) {
        debugPrint('📨 Verification email sent to $email');
      }

      // Create Firestore profile
      try {
        if (kDebugMode) {
          debugPrint('🔄 Creating Firestore profile...');
        }

        await createOrUpdateUser(
          uid: userCredential.user!.uid,
          email: email,
          name: name,
          phone: phone,
          role: role,
          district: district,
        );

        if (kDebugMode) {
          debugPrint('✅ Firestore profile created successfully');
        }
      } catch (firestoreError) {
        if (kDebugMode) {
          debugPrint('❌ Firestore profile creation failed: $firestoreError');
        }
        // Authentication succeeded but profile creation failed
        // User can still sign in, but needs profile
        throw Exception(
          'Account created but profile setup failed. Please try signing in.',
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Sign up failed: ${e.message}');
      }

      String errorMessage = 'Sign up failed';
      if (e.code == 'weak-password') {
        errorMessage = 'Password is too weak. Use at least 6 characters.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Email already registered. Please sign in instead.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email format.';
      } else {
        errorMessage = e.message ?? 'Sign up failed';
      }

      throw FirebaseAuthException(code: e.code, message: errorMessage);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error signing up: $e');
      }
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🔐 Signing in with email: $email');
      }

      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      if (kDebugMode) {
        debugPrint(
          '✅ Signed in successfully. UID: ${userCredential.user?.uid}',
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Sign in failed: ${e.message}');
      }

      String errorMessage = 'Sign in failed';
      if (e.code == 'user-not-found') {
        errorMessage = 'No account found with this email. Please sign up.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password. Please try again.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email format.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This account has been disabled.';
      } else {
        errorMessage = e.message ?? 'Sign in failed';
      }

      throw FirebaseAuthException(code: e.code, message: errorMessage);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error signing in: $e');
      }
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);

      if (kDebugMode) {
        debugPrint('📧 Password reset email sent to $email');
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to send reset email: ${e.message}');
      }

      String errorMessage = 'Failed to send reset email';
      if (e.code == 'user-not-found') {
        errorMessage = 'No account found with this email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email format.';
      } else {
        errorMessage = e.message ?? 'Failed to send reset email';
      }

      throw FirebaseAuthException(code: e.code, message: errorMessage);
    }
  }

  /// Resend email verification
  Future<void> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();

        if (kDebugMode) {
          debugPrint('📨 Verification email resent');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to resend verification email: $e');
      }
      rethrow;
    }
  }

  /// Check if email is verified
  Future<bool> isEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // ============================================================================
  // USER MANAGEMENT WITH FIRESTORE
  // ============================================================================

  /// Create or update user profile in Firestore
  Future<AppUser> createOrUpdateUser({
    required String uid,
    required String email,
    required String name,
    required String phone,
    required UserRole role,
    String? district,
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
        final systemId = await _generateUserId(role, district: district);

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
        userData['email'] = email; // Add email to Firestore
        // ✅ Store system_id as separate field for display/customer support
        userData['system_id'] = systemId;
        await userRef.set(userData);

        if (kDebugMode) {
          debugPrint('✅ User profile created: $uid');
        }

        // 🔧 FIX: Auto-create PSA verification placeholder for new PSA users
        if (role == UserRole.psa) {
          try {
            if (kDebugMode) {
              debugPrint('🔄 Creating PSA verification placeholder...');
            }

            // Create placeholder verification record
            await _firestore.collection('psa_verifications').add({
              'psa_id': uid,
              'business_name': 'Pending Business Information',
              'contact_person': name,
              'email': email,
              'phone_number': phone,
              'business_address': '',
              'business_type': '',
              'status': 'pending',
              'submitted_at': DateTime.now().toIso8601String(),
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });

            if (kDebugMode) {
              debugPrint(
                '✅ PSA verification placeholder created for admin review',
              );
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('⚠️ Failed to create PSA verification placeholder: $e');
              debugPrint('   PSA user can still submit verification manually');
            }
            // Don't throw - user creation succeeded, verification is optional
          }
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
      if (kDebugMode) {
        debugPrint('🔄 AUTH SERVICE - Fetching user profile for UID: $uid');
      }

      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final data = userDoc.data()!;

        if (kDebugMode) {
          debugPrint('📄 AUTH SERVICE - Firestore document data:');
          debugPrint('   - profile_image: ${data['profile_image'] ?? "NULL"}');
          debugPrint(
            '   - national_id_photo: ${data['national_id_photo'] ?? "NULL"}',
          );
          debugPrint('   - name: ${data['name'] ?? "NULL"}');
          debugPrint(
            '   - is_profile_complete: ${data['is_profile_complete'] ?? "NULL"}',
          );
        }

        final user = AppUser.fromFirestore(data, uid);

        if (kDebugMode) {
          debugPrint('✅ AUTH SERVICE - AppUser object created:');
          debugPrint('   - user.profileImage: ${user.profileImage ?? "NULL"}');
          debugPrint(
            '   - user.nationalIdPhoto: ${user.nationalIdPhoto ?? "NULL"}',
          );
        }

        return user;
      }

      if (kDebugMode) {
        debugPrint(
          '⚠️ AUTH SERVICE - User document does not exist for UID: $uid',
        );
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ AUTH SERVICE - Error fetching user profile: $e');
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

  /// Generate unique user ID based on role and district
  /// Format: ROLE + DISTRICT_CODE (3 letters) + SEQUENTIAL_NUMBER
  /// Examples: PSAIGA01, SHGJIN025, SMEBUG045
  /// Uses official district codes from districtinformation.xlsx
  Future<String> _generateUserId(UserRole role, {String? district}) async {
    try {
      final roleStr = role.toString().split('.').last.toUpperCase();

      // Get next sequential number for this role (no district)
      final sequentialNumber = await _getNextUserNumber(roleStr);

      // Format: ROLE-NUMBER (zero-padded to 5 digits)
      final formattedNumber = sequentialNumber.toString().padLeft(5, '0');
      final userId = '$roleStr-$formattedNumber';

      if (kDebugMode) {
        debugPrint('✅ Generated user ID: $userId');
        debugPrint('   - Role: $roleStr');
        debugPrint('   - Sequential Number: $formattedNumber');
      }

      return userId;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error generating user ID: $e');
      }
      // Fallback to timestamp-based ID if generation fails
      return '${role.toString().split('.').last.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Get next sequential number for a role
  /// This ensures unique, incremental user IDs
  Future<int> _getNextUserNumber(String roleStr) async {
    try {
      // Query Firestore to find the highest number for this role
      final prefix = '$roleStr-';

      final querySnapshot = await _firestore
          .collection('users')
          .where('id', isGreaterThanOrEqualTo: prefix)
          .where('id', isLessThan: '$roleStr.') // Get all IDs with this prefix
          .get();

      if (querySnapshot.docs.isEmpty) {
        // First user with this role
        return 1;
      }

      // Find the highest number from existing IDs
      int maxNumber = 0;
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final userId = data['id'] as String?;

        if (userId != null && userId.startsWith(prefix)) {
          // Extract the number part (everything after prefix)
          final numberPart = userId.substring(prefix.length);
          final number = int.tryParse(numberPart);

          if (number != null && number > maxNumber) {
            maxNumber = number;
          }
        }
      }

      // Return next number
      return maxNumber + 1;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error getting sequential number: $e');
        debugPrint('   Falling back to timestamp-based number');
      }
      // Fallback: use last 3 digits of timestamp
      return DateTime.now().millisecondsSinceEpoch % 1000;
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

  /// Validate email format
  bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate password strength
  bool isValidPassword(String password) {
    // At least 6 characters (Firebase minimum)
    return password.length >= 6;
  }

  /// Get password strength message
  String getPasswordStrength(String password) {
    if (password.length < 6) {
      return 'Too weak (min 6 characters)';
    } else if (password.length < 8) {
      return 'Weak';
    } else if (password.length < 12) {
      return 'Medium';
    } else {
      return 'Strong';
    }
  }
}

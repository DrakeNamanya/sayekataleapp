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
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('📧 Signing up with email: $email');
      }

      // Create user with email and password
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

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
        throw Exception('Account created but profile setup failed. Please try signing in.');
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

      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (kDebugMode) {
        debugPrint('✅ Signed in successfully. UID: ${userCredential.user?.uid}');
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

        // Generate user ID based on role
        final userId = await _generateUserId(role);
        
        // Set profile completion deadline (24 hours from now)
        final profileDeadline = DateTime.now().add(const Duration(hours: 24));

        // Create new user
        final newUser = AppUser(
          id: userId,
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
        await userRef.set(userData);

        if (kDebugMode) {
          debugPrint('✅ User profile created: $userId');
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
  /// Uses timestamp-based ID for reliability (no Firestore query needed)
  Future<String> _generateUserId(UserRole role) async {
    try {
      final roleStr = role.toString().split('.').last.toUpperCase();
      
      // Generate timestamp-based ID for reliability
      // Format: SHG-1730423456789, SME-1730423456789, PSA-1730423456789
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final userId = '$roleStr-$timestamp';
      
      if (kDebugMode) {
        debugPrint('✅ Generated user ID: $userId');
      }
      
      return userId;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error generating user ID: $e');
      }
      // Final fallback
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

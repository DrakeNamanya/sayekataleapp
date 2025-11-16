import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/admin_user.dart';

/// Admin authentication service
/// Handles admin login, session management, and access control
class AdminAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _adminSessionKey = 'admin_session';
  static const String _adminIdKey = 'admin_id';
  static const String _adminEmailKey = 'admin_email';

  /// Login admin with email and password
  /// Returns AdminUser on success, throws exception on failure
  Future<AdminUser> loginAdmin(String email, String password) async {
    try {
      // Step 1: Authenticate with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Authentication failed');
      }

      // Step 2: Check if user is admin
      final adminUser = await getAdminByEmail(email);

      if (adminUser == null) {
        // Not an admin - sign out immediately
        await _auth.signOut();
        throw Exception('Access denied. Admin privileges required.');
      }

      if (!adminUser.isActive) {
        // Admin account is deactivated
        await _auth.signOut();
        throw Exception(
          'Admin account is deactivated. Contact system administrator.',
        );
      }

      // Step 3: Save admin session
      await _saveAdminSession(adminUser);

      // Step 4: Update last login time
      await _updateLastLogin(adminUser.id);

      return adminUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      rethrow;
    }
  }

  /// Get admin user by email
  Future<AdminUser?> getAdminByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('admin_users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      return AdminUser.fromFirestore(doc.data(), doc.id);
    } catch (e) {
      throw Exception('Failed to fetch admin user: $e');
    }
  }

  /// Get admin user by ID
  Future<AdminUser?> getAdminById(String adminId) async {
    try {
      final doc = await _firestore.collection('admin_users').doc(adminId).get();

      if (!doc.exists) {
        return null;
      }

      return AdminUser.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to fetch admin user: $e');
    }
  }

  /// Check if current session is valid admin session
  Future<bool> isAdminLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSession = prefs.getBool(_adminSessionKey) ?? false;

      if (!hasSession) {
        return false;
      }

      // Verify Firebase auth is still active
      if (_auth.currentUser == null) {
        await _clearAdminSession();
        return false;
      }

      // Verify admin still exists and is active
      final adminId = prefs.getString(_adminIdKey);
      if (adminId == null) {
        return false;
      }

      final adminUser = await getAdminById(adminId);
      if (adminUser == null || !adminUser.isActive) {
        await _clearAdminSession();
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get current logged-in admin user
  Future<AdminUser?> getCurrentAdmin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final adminId = prefs.getString(_adminIdKey);

      if (adminId == null) {
        return null;
      }

      return await getAdminById(adminId);
    } catch (e) {
      return null;
    }
  }

  /// Logout admin
  Future<void> logoutAdmin() async {
    try {
      await _auth.signOut();
      await _clearAdminSession();
    } catch (e) {
      throw Exception('Failed to logout: $e');
    }
  }

  /// Save admin session to local storage
  Future<void> _saveAdminSession(AdminUser adminUser) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adminSessionKey, true);
    await prefs.setString(_adminIdKey, adminUser.id);
    await prefs.setString(_adminEmailKey, adminUser.email);
  }

  /// Clear admin session from local storage
  Future<void> _clearAdminSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_adminSessionKey);
    await prefs.remove(_adminIdKey);
    await prefs.remove(_adminEmailKey);
  }

  /// Update admin last login time
  Future<void> _updateLastLogin(String adminId) async {
    await _firestore.collection('admin_users').doc(adminId).update({
      'last_login_at': DateTime.now().toIso8601String(),
    });
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No admin account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This admin account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      default:
        return 'Login failed: ${e.message ?? 'Unknown error'}';
    }
  }

  /// Register new admin (Super Admin only)
  Future<AdminUser> registerAdmin({
    required String email,
    required String password,
    required String name,
    required AdminRole role,
  }) async {
    try {
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Failed to create admin user');
      }

      // Create admin document
      final adminUser = AdminUser(
        id: userCredential.user!.uid,
        email: email.toLowerCase(),
        name: name,
        role: role,
        permissions: role.defaultPermissions,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('admin_users')
          .doc(adminUser.id)
          .set(adminUser.toFirestore());

      return adminUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Check if email is registered as admin
  Future<bool> isAdminEmail(String email) async {
    final admin = await getAdminByEmail(email);
    return admin != null;
  }

  /// Create admin account with custom permissions (Super Admin only)
  Future<AdminUser> createAdminAccount({
    required String email,
    required String password,
    required String name,
    required AdminRole role,
    required List<String> permissions,
  }) async {
    try {
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Failed to create admin user');
      }

      // Create admin document with custom permissions
      final adminUser = AdminUser(
        id: userCredential.user!.uid,
        email: email.toLowerCase(),
        name: name,
        role: role,
        permissions: permissions,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('admin_users')
          .doc(adminUser.id)
          .set(adminUser.toFirestore());

      return adminUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      rethrow;
    }
  }
}

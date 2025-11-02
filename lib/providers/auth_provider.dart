import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../services/firebase_email_auth_service.dart';

class AuthProvider with ChangeNotifier {
  AppUser? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  final _authService = FirebaseEmailAuthService();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  User? get firebaseUser => _auth.currentUser;

  AuthProvider() {
    _initializeAuth();
  }

  /// Initialize Firebase Auth listener
  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    // Listen to Firebase Auth state changes
    _auth.authStateChanges().listen((User? firebaseUser) {
      if (firebaseUser != null) {
        _loadUserFromFirestore(firebaseUser.uid);
      } else {
        _currentUser = null;
        _isAuthenticated = false;
        notifyListeners();
      }
    });

    _isLoading = false;
    notifyListeners();
  }

  /// Load user data from Firestore
  Future<void> _loadUserFromFirestore(String uid) async {
    try {
      final user = await _authService.getUserProfile(uid);
      
      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading user from Firestore: $e');
      }
    } finally {
      notifyListeners();
    }
  }

  /// Sign in with email and password (handled in onboarding screen)
  /// This method is kept for compatibility but auth is handled by Firebase
  Future<bool> login(String phone, String name, UserRole role) async {
    // This method is deprecated - use Firebase auth directly
    // Kept for backward compatibility
    return false;
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await _auth.signOut();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      _currentUser = null;
      _isAuthenticated = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Logout error: $e');
      }
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? profileImage,
    String? nationalId,
    String? nationalIdPhoto,
    String? nameOnIdPhoto,
    Sex? sex,
    DisabilityStatus? disabilityStatus,
    Location? location,
  }) async {
    if (_currentUser == null || _auth.currentUser == null) return;

    try {
      // Check if profile is now complete
      final isComplete = nationalId != null &&
                        nationalIdPhoto != null &&
                        nameOnIdPhoto != null &&
                        sex != null &&
                        location != null;

      // Update Firestore
      final updates = <String, dynamic>{
        'updated_at': FieldValue.serverTimestamp(),
        'is_profile_complete': isComplete,
      };

      if (profileImage != null) updates['profile_image'] = profileImage;
      if (nationalId != null) updates['national_id'] = nationalId;
      if (nationalIdPhoto != null) updates['national_id_photo'] = nationalIdPhoto;
      if (nameOnIdPhoto != null) updates['name_on_id_photo'] = nameOnIdPhoto;
      if (sex != null) updates['sex'] = sex.toString().split('.').last.toUpperCase();
      if (disabilityStatus != null) {
        updates['disability_status'] = disabilityStatus.toString().split('.').last;
      }
      if (location != null) {
        updates['location'] = {
          'district': location.district,
          'subcounty': location.subcounty,
          'parish': location.parish,
          'village': location.village,
          'latitude': location.latitude,
          'longitude': location.longitude,
        };
      }

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update(updates);

      // Update local state
      _currentUser = AppUser(
        id: _currentUser!.id,
        name: _currentUser!.name,
        phone: _currentUser!.phone,
        email: _currentUser!.email,
        role: _currentUser!.role,
        profileImage: profileImage ?? _currentUser!.profileImage,
        nationalId: nationalId ?? _currentUser!.nationalId,
        nationalIdPhoto: nationalIdPhoto ?? _currentUser!.nationalIdPhoto,
        nameOnIdPhoto: nameOnIdPhoto ?? _currentUser!.nameOnIdPhoto,
        sex: sex ?? _currentUser!.sex,
        disabilityStatus: disabilityStatus ?? _currentUser!.disabilityStatus,
        location: location ?? _currentUser!.location,
        isProfileComplete: isComplete,
        profileCompletionDeadline: _currentUser!.profileCompletionDeadline,
        createdAt: _currentUser!.createdAt,
        updatedAt: DateTime.now(),
      );

      // Update local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_profile_complete', isComplete);
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Update profile error: $e');
      }
      rethrow;
    }
  }

  void updateUserLocation(Location location) {
    if (_currentUser != null) {
      updateProfile(location: location);
    }
  }
}

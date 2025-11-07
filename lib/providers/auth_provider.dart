import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user.dart';
import '../services/firebase_email_auth_service.dart';
import '../services/image_storage_service.dart';

class AuthProvider with ChangeNotifier {
  AppUser? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  final _authService = FirebaseEmailAuthService();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _imageStorage = ImageStorageService();

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
    if (_currentUser == null || _auth.currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      final userId = _auth.currentUser!.uid;
      String? profileImageUrl;
      String? nationalIdPhotoUrl;

      if (kDebugMode) {
        debugPrint('🔄 Starting profile update for user: $userId');
      }

      // Upload profile image if it's a local file path or blob
      if (profileImage != null && !profileImage.startsWith('http')) {
        try {
          if (kDebugMode) {
            debugPrint('📤 Uploading profile image from: $profileImage');
          }
          final xFile = XFile(profileImage);
          
          profileImageUrl = await _imageStorage.uploadImageFromXFile(
            imageFile: xFile,
            folder: 'profiles',
            userId: userId,
            customName: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
            compress: true,
          ).timeout(
            const Duration(seconds: 45),
            onTimeout: () {
              throw Exception('Profile image upload timeout - please check your internet connection');
            },
          );
          
          if (kDebugMode) {
            debugPrint('✅ Profile image uploaded: $profileImageUrl');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Error uploading profile image: $e');
          }
          // Rethrow to show error to user
          throw Exception('Failed to upload profile image: ${e.toString()}');
        }
      } else if (profileImage != null && profileImage.startsWith('http')) {
        // Already a URL, use as-is
        profileImageUrl = profileImage;
        if (kDebugMode) {
          debugPrint('ℹ️ Using existing profile image URL');
        }
      }

      // Upload national ID photo if it's a local file path or blob
      if (nationalIdPhoto != null && !nationalIdPhoto.startsWith('http')) {
        try {
          if (kDebugMode) {
            debugPrint('📤 Uploading national ID photo from: $nationalIdPhoto');
          }
          final xFile = XFile(nationalIdPhoto);
          
          nationalIdPhotoUrl = await _imageStorage.uploadImageFromXFile(
            imageFile: xFile,
            folder: 'national_ids',
            userId: userId,
            customName: 'national_id_${DateTime.now().millisecondsSinceEpoch}.jpg',
            compress: false, // Don't compress ID photos (need clarity)
          ).timeout(
            const Duration(seconds: 45),
            onTimeout: () {
              throw Exception('National ID photo upload timeout - please check your internet connection');
            },
          );
          
          if (kDebugMode) {
            debugPrint('✅ National ID photo uploaded: $nationalIdPhotoUrl');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Error uploading national ID photo: $e');
          }
          // Rethrow to show error to user
          throw Exception('Failed to upload national ID photo: ${e.toString()}');
        }
      } else if (nationalIdPhoto != null && nationalIdPhoto.startsWith('http')) {
        // Already a URL, use as-is
        nationalIdPhotoUrl = nationalIdPhoto;
        if (kDebugMode) {
          debugPrint('ℹ️ Using existing national ID photo URL');
        }
      }

      // Check if profile is now complete
      final isComplete = nationalId != null &&
                        nationalIdPhotoUrl != null &&
                        nameOnIdPhoto != null &&
                        sex != null &&
                        location != null;

      // Update Firestore
      final updates = <String, dynamic>{
        'updated_at': FieldValue.serverTimestamp(),
        'is_profile_complete': isComplete,
      };

      if (profileImageUrl != null) updates['profile_image'] = profileImageUrl;
      if (nationalId != null) updates['national_id'] = nationalId;
      if (nationalIdPhotoUrl != null) updates['national_id_photo'] = nationalIdPhotoUrl;
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

      // Update local state with uploaded URLs (not file paths)
      _currentUser = AppUser(
        id: _currentUser!.id,
        name: _currentUser!.name,
        phone: _currentUser!.phone,
        email: _currentUser!.email,
        role: _currentUser!.role,
        profileImage: profileImageUrl ?? _currentUser!.profileImage,
        nationalId: nationalId ?? _currentUser!.nationalId,
        nationalIdPhoto: nationalIdPhotoUrl ?? _currentUser!.nationalIdPhoto,
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

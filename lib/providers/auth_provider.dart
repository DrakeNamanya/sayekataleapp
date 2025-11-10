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
      if (kDebugMode) {
        debugPrint('🔄 AUTH PROVIDER - Loading user from Firestore for UID: $uid');
      }
      
      final user = await _authService.getUserProfile(uid);
      
      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
        
        if (kDebugMode) {
          debugPrint('✅ AUTH PROVIDER - User loaded successfully:');
          debugPrint('   - User ID: ${user.id}');
          debugPrint('   - User Name: ${user.name}');
          debugPrint('   - Profile Image URL: ${user.profileImage ?? "NULL"}');
          debugPrint('   - National ID Photo URL: ${user.nationalIdPhoto ?? "NULL"}');
          debugPrint('   - Profile Complete: ${user.isProfileComplete}');
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ AUTH PROVIDER - User is NULL from getUserProfile()');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ AUTH PROVIDER - Error loading user from Firestore: $e');
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
    XFile? profileImageFile,
    String? profileImageUrl,
    String? nationalId,
    XFile? nationalIdPhotoFile,
    String? nationalIdPhotoUrl,
    String? nameOnIdPhoto,
    Sex? sex,
    DisabilityStatus? disabilityStatus,
    Location? location,
    PartnerInfo? partnerInfo,
  }) async {
    if (_currentUser == null || _auth.currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      final userId = _auth.currentUser!.uid;

      if (kDebugMode) {
        debugPrint('🔄 Starting profile update for user: $userId');
        debugPrint('📥 Received parameters:');
        debugPrint('   - profileImageFile: ${profileImageFile?.path ?? "null"}');
        debugPrint('   - profileImageUrl: ${profileImageUrl ?? "null"}');
        debugPrint('   - nationalIdPhotoFile: ${nationalIdPhotoFile?.path ?? "null"}');
        debugPrint('   - nationalIdPhotoUrl: ${nationalIdPhotoUrl ?? "null"}');
        debugPrint('   - nationalId: ${nationalId ?? "null"}');
        debugPrint('   - nameOnIdPhoto: ${nameOnIdPhoto ?? "null"}');
        debugPrint('   - sex: ${sex ?? "null"}');
        debugPrint('   - location: ${location != null ? "${location.district}, ${location.subcounty}" : "null"}');
      }

      // Upload profile image if XFile is provided
      String? finalProfileImageUrl = profileImageUrl;
      if (profileImageFile != null) {
        try {
          if (kDebugMode) {
            debugPrint('📤 Uploading profile image from XFile: ${profileImageFile.path}');
          }
          
          finalProfileImageUrl = await _imageStorage.uploadImageFromXFile(
            imageFile: profileImageFile,
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
            debugPrint('✅ Profile image uploaded: $finalProfileImageUrl');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Error uploading profile image: $e');
          }
          // Rethrow to show error to user
          throw Exception('Failed to upload profile image: ${e.toString()}');
        }
      } else if (profileImageUrl != null) {
        // Already a URL, use as-is
        if (kDebugMode) {
          debugPrint('ℹ️ Using existing profile image URL: $profileImageUrl');
        }
      }

      // Upload national ID photo if XFile is provided
      String? finalNationalIdPhotoUrl = nationalIdPhotoUrl;
      if (nationalIdPhotoFile != null) {
        try {
          if (kDebugMode) {
            debugPrint('📤 Uploading national ID photo from XFile: ${nationalIdPhotoFile.path}');
          }
          
          finalNationalIdPhotoUrl = await _imageStorage.uploadImageFromXFile(
            imageFile: nationalIdPhotoFile,
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
            debugPrint('✅ National ID photo uploaded: $finalNationalIdPhotoUrl');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Error uploading national ID photo: $e');
          }
          // Rethrow to show error to user
          throw Exception('Failed to upload national ID photo: ${e.toString()}');
        }
      } else if (nationalIdPhotoUrl != null) {
        // Already a URL, use as-is
        if (kDebugMode) {
          debugPrint('ℹ️ Using existing national ID photo URL: $nationalIdPhotoUrl');
        }
      }

      if (kDebugMode) {
        debugPrint('📊 Final URLs after upload:');
        debugPrint('   - finalProfileImageUrl: ${finalProfileImageUrl ?? "null"}');
        debugPrint('   - finalNationalIdPhotoUrl: ${finalNationalIdPhotoUrl ?? "null"}');
      }

      // Check if profile is now complete
      final isComplete = nationalId != null &&
                        finalNationalIdPhotoUrl != null &&
                        nameOnIdPhoto != null &&
                        sex != null &&
                        location != null;
      
      if (kDebugMode) {
        debugPrint('✓ Profile completion check:');
        debugPrint('   - nationalId: ${nationalId != null ? "✅" : "❌"}');
        debugPrint('   - finalNationalIdPhotoUrl: ${finalNationalIdPhotoUrl != null ? "✅" : "❌"}');
        debugPrint('   - nameOnIdPhoto: ${nameOnIdPhoto != null ? "✅" : "❌"}');
        debugPrint('   - sex: ${sex != null ? "✅" : "❌"}');
        debugPrint('   - location: ${location != null ? "✅" : "❌"}');
        debugPrint('   - RESULT: ${isComplete ? "✅ COMPLETE" : "❌ INCOMPLETE"}');
      }

      // Update Firestore
      final updates = <String, dynamic>{
        'updated_at': FieldValue.serverTimestamp(),
        'is_profile_complete': isComplete,
      };

      if (finalProfileImageUrl != null) updates['profile_image'] = finalProfileImageUrl;
      if (nationalId != null) updates['national_id'] = nationalId;
      if (finalNationalIdPhotoUrl != null) updates['national_id_photo'] = finalNationalIdPhotoUrl;
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
      if (partnerInfo != null) {
        updates['partner_info'] = partnerInfo.toMap();
      }

      if (kDebugMode) {
        debugPrint('💾 Saving to Firestore:');
        debugPrint('   - Updates: $updates');
        debugPrint('   - Profile complete: $isComplete');
      }
      
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update(updates);
      
      if (kDebugMode) {
        debugPrint('✅ Profile saved to Firestore successfully');
        
        // Verify what was actually saved by reading it back
        final savedDoc = await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .get();
        
        if (savedDoc.exists) {
          final savedData = savedDoc.data();
          debugPrint('🔍 VERIFICATION - Reading back from Firestore:');
          debugPrint('   - profile_image: ${savedData?['profile_image'] ?? "NOT SAVED"}');
          debugPrint('   - national_id_photo: ${savedData?['national_id_photo'] ?? "NOT SAVED"}');
          debugPrint('   - national_id: ${savedData?['national_id'] ?? "NOT SAVED"}');
          debugPrint('   - is_profile_complete: ${savedData?['is_profile_complete'] ?? "NOT SAVED"}');
        }
      }

      // Update local state with uploaded URLs (not file paths)
      _currentUser = AppUser(
        id: _currentUser!.id,
        name: _currentUser!.name,
        phone: _currentUser!.phone,
        email: _currentUser!.email,
        role: _currentUser!.role,
        profileImage: finalProfileImageUrl ?? _currentUser!.profileImage,
        nationalId: nationalId ?? _currentUser!.nationalId,
        nationalIdPhoto: finalNationalIdPhotoUrl ?? _currentUser!.nationalIdPhoto,
        nameOnIdPhoto: nameOnIdPhoto ?? _currentUser!.nameOnIdPhoto,
        sex: sex ?? _currentUser!.sex,
        disabilityStatus: disabilityStatus ?? _currentUser!.disabilityStatus,
        location: location ?? _currentUser!.location,
        partnerInfo: partnerInfo ?? _currentUser!.partnerInfo,
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

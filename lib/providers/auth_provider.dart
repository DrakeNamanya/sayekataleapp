import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  AppUser? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _loadUserFromStorage();
  }

  Future<void> _loadUserFromStorage() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final userName = prefs.getString('user_name');
      final userPhone = prefs.getString('user_phone');
      final userRoleStr = prefs.getString('user_role');
      final isProfileComplete = prefs.getBool('is_profile_complete') ?? false;
      final profileDeadlineStr = prefs.getString('profile_completion_deadline');

      if (userId != null && userName != null && userPhone != null && userRoleStr != null) {
        final role = UserRole.values.firstWhere(
          (e) => e.toString() == 'UserRole.$userRoleStr',
          orElse: () => UserRole.shg,
        );

        _currentUser = AppUser(
          id: userId,
          name: userName,
          phone: userPhone,
          role: role,
          isProfileComplete: isProfileComplete,
          profileCompletionDeadline: profileDeadlineStr != null 
              ? DateTime.parse(profileDeadlineStr)
              : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _isAuthenticated = true;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading user from storage: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String phone, String name, UserRole role) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate OTP verification delay
      await Future.delayed(const Duration(seconds: 2));

      // Get user count for ID generation (in real app, this would come from backend)
      final prefs = await SharedPreferences.getInstance();
      final userCount = prefs.getInt('${role.toString().split('.').last}_count') ?? 0;
      
      // Generate user ID based on role
      final userId = AppUser.generateUserId(role, userCount);
      
      // Save new count
      await prefs.setInt('${role.toString().split('.').last}_count', userCount + 1);

      // Set profile completion deadline (24 hours from now)
      final profileDeadline = DateTime.now().add(const Duration(hours: 24));

      // Create user
      _currentUser = AppUser(
        id: userId,
        name: name,
        phone: phone,
        role: role,
        isProfileComplete: false,
        profileCompletionDeadline: profileDeadline,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to local storage
      await prefs.setString('user_id', _currentUser!.id);
      await prefs.setString('user_name', _currentUser!.name);
      await prefs.setString('user_phone', _currentUser!.phone);
      await prefs.setString('user_role', role.toString().split('.').last);
      await prefs.setBool('is_profile_complete', false);
      await prefs.setString('profile_completion_deadline', profileDeadline.toIso8601String());

      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Login error: $e');
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? profileImage,
    String? nationalId,
    String? nationalIdPhoto,
    String? nameOnIdPhoto,
    Sex? sex,
    DisabilityStatus? disabilityStatus,
    Location? location,
  }) async {
    if (_currentUser == null) return;

    // Check if profile is now complete
    final isComplete = nationalId != null &&
                      nationalIdPhoto != null &&
                      nameOnIdPhoto != null &&
                      sex != null &&
                      location != null;

    _currentUser = AppUser(
      id: _currentUser!.id,
      name: _currentUser!.name,
      phone: _currentUser!.phone,
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
  }

  void updateUserLocation(Location location) {
    if (_currentUser != null) {
      updateProfile(location: location);
    }
  }
}

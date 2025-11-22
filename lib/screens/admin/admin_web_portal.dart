import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../services/admin_auth_service.dart';
import '../../models/admin_user.dart';
import 'admin_dashboard_screen.dart';
import '../auth/admin_login_screen.dart';

/// Web-accessible admin portal
/// Direct URL access: https://your-app.com/#/admin
class AdminWebPortal extends StatefulWidget {
  const AdminWebPortal({super.key});

  @override
  State<AdminWebPortal> createState() => _AdminWebPortalState();
}

class _AdminWebPortalState extends State<AdminWebPortal> {
  final AdminAuthService _authService = AdminAuthService();
  bool _isChecking = true;
  bool _isLoggedIn = false;
  AdminUser? _adminUser;

  @override
  void initState() {
    super.initState();
    _checkAdminSession();
  }

  Future<void> _checkAdminSession() async {
    try {
      final isLoggedIn = await _authService.isAdminLoggedIn();
      
      if (isLoggedIn) {
        final adminUser = await _authService.getCurrentAdmin();
        
        if (mounted) {
          setState(() {
            _isLoggedIn = true;
            _adminUser = adminUser;
            _isChecking = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoggedIn = false;
            _isChecking = false;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking admin session: $e');
      }
      
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading Admin Portal...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoggedIn && _adminUser != null) {
      // Admin is logged in - show dashboard
      return AdminDashboardScreen(adminUser: _adminUser!);
    } else {
      // Admin not logged in - show login screen
      return const AdminLoginScreen();
    }
  }
}

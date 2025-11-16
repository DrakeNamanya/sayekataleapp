import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../utils/app_theme.dart';
import 'onboarding_screen.dart';

/// Wrapper screen that ensures Firebase is ready before showing onboarding
/// This prevents gray/blank screens caused by Firebase init delays
class AppLoaderScreen extends StatefulWidget {
  const AppLoaderScreen({super.key});

  @override
  State<AppLoaderScreen> createState() => _AppLoaderScreenState();
}

class _AppLoaderScreenState extends State<AppLoaderScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkFirebaseAndNavigate();
  }

  Future<void> _checkFirebaseAndNavigate() async {
    try {
      // Wait a moment to ensure Firebase is fully initialized
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Verify Firebase is actually working
      final app = Firebase.app();
      debugPrint('✅ Firebase app verified: ${app.name}');
      
      setState(() {
        _isLoading = false;
      });
      
      // Navigate to onboarding after brief delay
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    } catch (e) {
      debugPrint('❌ Firebase verification failed: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: SafeArea(
        child: Center(
          child: _hasError
              ? _buildErrorView()
              : _isLoading
                  ? _buildLoadingView()
                  : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
        ),
        const SizedBox(height: 24),
        Text(
          'Loading SayeKatale...',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Connecting to services',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.danger,
          ),
          const SizedBox(height: 24),
          Text(
            'Connection Error',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to connect to Firebase services',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
              _checkFirebaseAndNavigate();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              // Skip to onboarding anyway (might work despite error)
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
              );
            },
            child: const Text('Continue Anyway'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../models/user.dart';
import '../utils/app_theme.dart';
import '../widgets/uganda_phone_field.dart';
import '../services/firebase_email_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _agreedToTerms = false;
  bool _isPasswordVisible = false;
  bool _isSignUpMode = true; // true = Sign Up, false = Sign In
  UserRole _selectedRole = UserRole.shg;
  String? _selectedDistrict;
  final _authService = FirebaseEmailAuthService();

  // Official districts from districtinformation.xlsx
  final List<String> _districts = [
    'BUGIRI',
    'BUGWERI',
    'BUYENDE',
    'IGANGA',
    'JINJA',
    'JINJA CITY',
    'KALIRO',
    'KAMULI',
    'LUUKA',
    'MAYUGE',
    'NAMAYINGO',
    'NAMUTUMBA',
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isSignUpMode && !_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to Terms and Privacy Policy'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Block PSA registration
    if (_isSignUpMode && _selectedRole == UserRole.psa) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '📞 PSA registration is not available.\n\nContact admin@sayekatale.com to add your product on PSA products.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    // Auth provider available if needed
    // final authProvider = Provider.of<app_auth.AuthProvider>(
    //   context,
    //   listen: false,
    // );

    try {
      if (_isSignUpMode) {
        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text('Creating your account...'),
                  ),
                ],
              ),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 30),
            ),
          );
        }

        // Sign Up with Email
        await _authService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          role: _selectedRole,
          district: _selectedDistrict,
        );

        if (kDebugMode) {
          debugPrint('✅ ONBOARDING - Sign up completed, account and profile created');
        }

        // 🔧 IMPROVED: Wait for AuthProvider with better UX
        if (kDebugMode) {
          debugPrint('⏳ ONBOARDING - Waiting for AuthProvider to sync...');
        }

        final authProvider = Provider.of<app_auth.AuthProvider>(
          context,
          listen: false,
        );

        // Poll until user is loaded (max 10 seconds - reduced from 30s)
        int attempts = 0;
        const maxAttempts = 20; // 20 × 500ms = 10 seconds
        bool showedSlowNetworkWarning = false;
        
        while ((!authProvider.isAuthenticated || authProvider.currentUser == null) && attempts < maxAttempts) {
          await Future.delayed(const Duration(milliseconds: 500));
          attempts++;

          // Show "still loading" message after 3 seconds
          if (attempts == 6 && !showedSlowNetworkWarning && mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text('Still loading your profile...'),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 10),
              ),
            );
            showedSlowNetworkWarning = true;
          }

          if (kDebugMode && attempts % 4 == 0) {
            debugPrint(
              '⏳ ONBOARDING - Attempt $attempts/$maxAttempts: Auth=${authProvider.isAuthenticated}, User=${authProvider.currentUser != null ? "loaded" : "null"}',
            );
          }
        }

        // Clear any loading snackbars
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
        }

        // Check if profile loaded successfully
        if (!authProvider.isAuthenticated || authProvider.currentUser == null) {
          if (kDebugMode) {
            debugPrint(
              '❌ ONBOARDING - Profile not loaded after ${maxAttempts * 500}ms',
            );
          }
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  '✅ Account created successfully!\n\n⚠️ Slow network detected. Please sign in to continue.',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 6),
                action: SnackBarAction(
                  label: 'Sign In',
                  textColor: Colors.white,
                  onPressed: () {
                    setState(() {
                      _isSignUpMode = false;
                    });
                  },
                ),
              ),
            );
            
            // Auto-switch to sign-in mode
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                setState(() {
                  _isSignUpMode = false;
                });
              }
            });
          }
          return;
        }

        // Success! Show completion message
        if (kDebugMode) {
          debugPrint(
            '✅ ONBOARDING - Profile loaded: ${authProvider.currentUser?.name}',
          );
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Account created successfully! Redirecting...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Sign In with Email
        final userCredential = await _authService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Load user data from Firestore
        final userProfile = await _authService.getUserProfile(
          userCredential.user!.uid,
        );

        if (userProfile != null) {
          setState(() {
            _selectedRole = userProfile.role;
          });
        }
      }

      // ⚡ REMOVED: 2-second artificial delay that slowed registration
      // AuthProvider polling above (lines 112-121) is sufficient
      if (kDebugMode) {
        debugPrint('✅ User loaded, navigating to dashboard');
      }

      if (mounted) {
        String route;
        switch (_selectedRole) {
          case UserRole.shg:
            route = '/shg-dashboard';
            break;
          case UserRole.sme:
            route = '/sme-dashboard';
            break;
          case UserRole.psa:
            // 🔧 SIMPLIFIED FLOW: ALL PSAs (new and existing) go to dashboard
            // Dashboard will check verification status and show appropriate screen
            route = '/psa-dashboard';
            break;
          default:
            route = '/shg-dashboard';
        }
        Navigator.of(context).pushReplacementNamed(route);
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('🔥 FirebaseAuthException: ${e.code} - ${e.message}');
      }

      String errorMessage = 'Authentication failed';

      if (e.code == 'weak-password') {
        errorMessage = 'Password is too weak (min 6 characters)';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = '⚠️ This email is already registered.\n\nPlease sign in instead or use a different email.';
        
        // Clear any loading snackbars first
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: 'Sign In',
                textColor: Colors.white,
                onPressed: () {
                  setState(() {
                    _isSignUpMode = false;
                  });
                },
              ),
            ),
          );
          
          // Auto-switch to sign-in mode after short delay
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              setState(() {
                _isSignUpMode = false;
              });
            }
          });
        }
        return; // IMPORTANT: Stop execution after error
      } else if (e.code == 'user-not-found') {
        errorMessage = 'No account found. Please sign up.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email format';
      } else {
        errorMessage = 'Firebase Auth Error: ${e.code}\n${e.message}';
      }

      if (mounted) {
        // Clear any loading snackbars
        ScaffoldMessenger.of(context).clearSnackBars();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return; // IMPORTANT: Stop execution after showing error
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Unexpected Error: $e');
        debugPrint('📍 Stack Trace: $stackTrace');
      }

      if (mounted) {
        // Clear any loading snackbars
        ScaffoldMessenger.of(context).clearSnackBars();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Unexpected Error:\n${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
      return; // IMPORTANT: Stop execution after error
    }
  }

  Future<void> _handlePasswordReset() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _authService.sendPasswordResetEmail(_emailController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent! Check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_auth.AuthProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // App Icon
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Image.asset(
                        'assets/icons/app_icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Welcome Text
                const Text(
                  'Welcome to SAYE Katale',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Demand Meets Supply',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Mode Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isSignUpMode ? 'Create Account' : 'Sign In',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSignUpMode = !_isSignUpMode;
                        });
                      },
                      child: Text(
                        _isSignUpMode ? 'Sign In Instead' : 'Create Account',
                        style: const TextStyle(
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Name Input (Sign Up Only)
                if (_isSignUpMode) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (_isSignUpMode &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Phone Input with Uganda validation (Sign Up Only)
                  UgandaPhoneField(
                    controller: _phoneController,
                    required: _isSignUpMode,
                    showOperatorIcon: true,
                    showFormatHelper: true,
                  ),
                  const SizedBox(height: 16),
                  // District Selection (Sign Up Only) - Required for User ID generation
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDistrict,
                    decoration: const InputDecoration(
                      labelText: 'District',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      hintText: 'Select your district',
                    ),
                    items: _districts.map((district) {
                      return DropdownMenuItem(
                        value: district,
                        child: Text(district),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDistrict = value;
                      });
                    },
                    validator: (value) {
                      if (_isSignUpMode && value == null) {
                        return 'Please select your district';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                // Email Input
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                    hintText: 'example@email.com',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    // Basic check for @ symbol - Firebase will validate format
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email (e.g., user@example.com)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Password Input
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    hintText: _isSignUpMode
                        ? 'Min 6 characters'
                        : 'Enter your password',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (_isSignUpMode && value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                // Forgot Password (Sign In Only)
                if (!_isSignUpMode)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _handlePasswordReset,
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                // Role Selection (Sign Up Only)
                if (_isSignUpMode) ...[
                  const Text(
                    'I am a:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      _RoleCard(
                        title: 'Farmer (SHG)',
                        subtitle: 'Sell products, buy inputs',
                        icon: Icons.agriculture_outlined,
                        isSelected: _selectedRole == UserRole.shg,
                        onTap: () {
                          setState(() {
                            _selectedRole = UserRole.shg;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _RoleCard(
                        title: 'Buyer (SME)',
                        subtitle: 'Purchase agricultural products',
                        icon: Icons.shopping_bag_outlined,
                        isSelected: _selectedRole == UserRole.sme,
                        onTap: () {
                          setState(() {
                            _selectedRole = UserRole.sme;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _RoleCard(
                        title: 'Supplier (PSA)',
                        subtitle: 'Contact admin to add your product',
                        icon: Icons.store_outlined,
                        isSelected: _selectedRole == UserRole.psa,
                        isDisabled: true,  // Disable PSA registration
                        onTap: () {
                          // Show message instead of allowing selection
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '📞 Contact admin to add your product on PSA products\n\nEmail: admin@sayekatale.com',
                              ),
                              backgroundColor: AppTheme.primaryColor,
                              duration: Duration(seconds: 5),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                // Terms and Privacy (Sign Up Only)
                if (_isSignUpMode)
                  Row(
                    children: [
                      Checkbox(
                        value: _agreedToTerms,
                        onChanged: (value) {
                          setState(() {
                            _agreedToTerms = value ?? false;
                          });
                        },
                        activeColor: AppTheme.primaryColor,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _agreedToTerms = !_agreedToTerms;
                            });
                          },
                          child: const Text(
                            'I agree to Terms of Service and Privacy Policy',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                // Developer Credit
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Developed by DATACOLLECTORS LTD',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Auth Button
                ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _handleAuth,
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(_isSignUpMode ? 'Create Account' : 'Sign In'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.isSelected,
    this.isDisabled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey.shade100
              : isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                  : Colors.white,
          border: Border.all(
            color: isDisabled
                ? Colors.grey.shade300
                : isSelected
                    ? AppTheme.primaryColor
                    : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 36,
              color: isDisabled
                  ? Colors.grey.shade400
                  : isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDisabled
                          ? Colors.grey.shade500
                          : isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDisabled
                            ? Colors.grey.shade500
                            : isSelected
                                ? AppTheme.primaryColor.withValues(alpha: 0.8)
                                : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isDisabled)
              Icon(
                Icons.info_outline,
                size: 20,
                color: Colors.grey.shade500,
              ),
          ],
        ),
      ),
    );
  }
}

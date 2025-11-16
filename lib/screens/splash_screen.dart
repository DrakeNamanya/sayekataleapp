import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../models/user.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _personController;
  late AnimationController _exchangeController;
  late AnimationController _textController;

  late Animation<Offset> _leftPersonAnimation;
  late Animation<Offset> _rightPersonAnimation;
  late Animation<double> _henRotationAnimation;
  late Animation<double> _moneyRotationAnimation;
  late Animation<Offset> _henPositionAnimation;
  late Animation<Offset> _moneyPositionAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _textOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimation();
  }

  void _setupAnimations() {
    // Person movement animation (0-1.5 seconds)
    _personController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Exchange animation (1.5-3 seconds)
    _exchangeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Text animation (2.5-4 seconds)
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Left person (with hen) slides in from left
    _leftPersonAnimation =
        Tween<Offset>(
          begin: const Offset(-1.5, 0.0),
          end: const Offset(-0.15, 0.0),
        ).animate(
          CurvedAnimation(
            parent: _personController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Right person (with money) slides in from right
    _rightPersonAnimation =
        Tween<Offset>(
          begin: const Offset(1.5, 0.0),
          end: const Offset(0.15, 0.0),
        ).animate(
          CurvedAnimation(
            parent: _personController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Hen rotation during exchange
    _henRotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _exchangeController, curve: Curves.easeInOut),
    );

    // Money rotation during exchange
    _moneyRotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _exchangeController, curve: Curves.easeInOut),
    );

    // Hen moves from left person to right person
    _henPositionAnimation =
        Tween<Offset>(
          begin: const Offset(-0.15, 0.0),
          end: const Offset(0.15, 0.0),
        ).animate(
          CurvedAnimation(
            parent: _exchangeController,
            curve: Curves.easeInOutCubic,
          ),
        );

    // Money moves from right person to left person
    _moneyPositionAnimation =
        Tween<Offset>(
          begin: const Offset(0.15, 0.0),
          end: const Offset(-0.15, 0.0),
        ).animate(
          CurvedAnimation(
            parent: _exchangeController,
            curve: Curves.easeInOutCubic,
          ),
        );

    // "SAYE KATALE" text slides from right to left
    _textSlideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
        );

    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));
  }

  Future<void> _startAnimation() async {
    // Start person movement
    await _personController.forward();

    // Wait a moment
    await Future.delayed(const Duration(milliseconds: 300));

    // Start exchange animation and text animation simultaneously
    _exchangeController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _textController.forward();

    // Wait for all animations to complete
    await Future.delayed(const Duration(milliseconds: 2000));

    // DON'T auto-navigate - let user choose
    // Animation complete, buttons are now visible
  }

  Future<void> _navigateToNextScreen() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.isAuthenticated && authProvider.currentUser != null) {
        // Navigate based on user role
        String route;
        switch (authProvider.currentUser!.role) {
          case UserRole.shg:
            route = '/shg-dashboard';
            break;
          case UserRole.sme:
            route = '/sme-dashboard';
            break;
          case UserRole.psa:
            route = '/psa-dashboard';
            break;
          default:
            route = '/shg-dashboard';
        }
        Navigator.of(context).pushReplacementNamed(route);
      } else {
        // Navigate to app loader which will verify Firebase and show onboarding
        Navigator.of(context).pushReplacementNamed('/app-loader');
      }
    } catch (e) {
      // If anything fails, go to app loader with error handling
      debugPrint('❌ Navigation error: $e');
      Navigator.of(context).pushReplacementNamed('/app-loader');
    }
  }

  @override
  void dispose() {
    _personController.dispose();
    _exchangeController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.1),
                    AppTheme.secondary.withValues(alpha: 0.1),
                  ],
                ),
              ),
            ),

            // Hidden Animal Icons for Navigation (bottom center)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Goat Icon (decorative - tap to continue)
                  GestureDetector(
                    onTap: () {
                      _navigateToNextScreen();
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.pets,
                        size: 30,
                        color: Colors.brown,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Hen Icon (ADMIN ACCESS - secret)
                  GestureDetector(
                    onTap: () {
                      // Tap hen to access admin login
                      Navigator.of(context).pushNamed('/admin-login');
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.egg_alt,
                        size: 30,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Crop Icon (decorative - tap to continue)
                  GestureDetector(
                    onTap: () {
                      _navigateToNextScreen();
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.grass,
                        size: 30,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main animation area
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animation container
                  SizedBox(
                    height: 300,
                    child: Stack(
                      children: [
                        // Left Person (Farmer with hen)
                        AnimatedBuilder(
                          animation: _personController,
                          builder: (context, child) {
                            return SlideTransition(
                              position: _leftPersonAnimation,
                              child: child,
                            );
                          },
                          child: Align(
                            alignment: Alignment.center,
                            child: _buildPerson(
                              isLeft: true,
                              showItem: _exchangeController.value < 0.5,
                            ),
                          ),
                        ),

                        // Right Person (Buyer with money)
                        AnimatedBuilder(
                          animation: _personController,
                          builder: (context, child) {
                            return SlideTransition(
                              position: _rightPersonAnimation,
                              child: child,
                            );
                          },
                          child: Align(
                            alignment: Alignment.center,
                            child: _buildPerson(
                              isLeft: false,
                              showItem: _exchangeController.value < 0.5,
                            ),
                          ),
                        ),

                        // Hen moving (visible during exchange)
                        if (_exchangeController.value > 0)
                          AnimatedBuilder(
                            animation: _exchangeController,
                            builder: (context, child) {
                              return SlideTransition(
                                position: _henPositionAnimation,
                                child: Transform.rotate(
                                  angle: _henRotationAnimation.value * 3.14,
                                  child: Transform.scale(
                                    scale:
                                        1.0 +
                                        (_henRotationAnimation.value * 0.3),
                                    child: child,
                                  ),
                                ),
                              );
                            },
                            child: Align(
                              alignment: Alignment.center,
                              child: _buildHen(),
                            ),
                          ),

                        // Money moving (visible during exchange)
                        if (_exchangeController.value > 0)
                          AnimatedBuilder(
                            animation: _exchangeController,
                            builder: (context, child) {
                              return SlideTransition(
                                position: _moneyPositionAnimation,
                                child: Transform.rotate(
                                  angle: -_moneyRotationAnimation.value * 3.14,
                                  child: Transform.scale(
                                    scale:
                                        1.0 +
                                        (_moneyRotationAnimation.value * 0.3),
                                    child: child,
                                  ),
                                ),
                              );
                            },
                            child: Align(
                              alignment: Alignment.center,
                              child: _buildMoney(),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),

                  // "SAYE KATALE" text animation
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return SlideTransition(
                        position: _textSlideAnimation,
                        child: FadeTransition(
                          opacity: _textOpacityAnimation,
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Text(
                          'SAYE KATALE',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: AppTheme.secondary.withValues(
                                  alpha: 0.5,
                                ),
                                offset: const Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Demand Meets Supply',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppTheme.accent,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Continue Button
                        ElevatedButton(
                          onPressed: () {
                            _navigateToNextScreen();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 8,
                            shadowColor: AppTheme.primary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build cartoon person
  Widget _buildPerson({required bool isLeft, required bool showItem}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Person body
        Container(
          width: 80,
          height: 120,
          decoration: BoxDecoration(
            color: isLeft ? AppTheme.secondary : AppTheme.accent,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Head
              Positioned(
                top: 10,
                left: 20,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.brown.shade300,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.brown.shade400, width: 2),
                  ),
                  child: Stack(
                    children: [
                      // Eyes
                      Positioned(
                        top: 12,
                        left: 8,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 8,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Smile
                      Positioned(
                        bottom: 8,
                        left: 10,
                        child: Container(
                          width: 20,
                          height: 10,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.black, width: 2),
                            ),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Arms
              Positioned(
                top: 55,
                left: isLeft ? -10 : null,
                right: isLeft ? null : -10,
                child: Container(
                  width: 30,
                  height: 8,
                  decoration: BoxDecoration(
                    color: (isLeft ? AppTheme.secondary : AppTheme.accent)
                        .withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // Item in hand (hen or money)
              if (showItem)
                Positioned(
                  top: 40,
                  left: isLeft ? -25 : null,
                  right: isLeft ? null : -25,
                  child: isLeft ? _buildHen() : _buildMoney(),
                ),
            ],
          ),
        ),
        // Legs
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.blue.shade900,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 12,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.blue.shade900,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Build cartoon hen
  Widget _buildHen() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.orange.shade700, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Body
          Center(
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange.shade300, width: 1),
              ),
            ),
          ),
          // Head
          Positioned(
            top: 5,
            right: 8,
            child: Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange.shade300, width: 1),
              ),
              child: Stack(
                children: [
                  // Eye
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Beak
                  Positioned(
                    top: 10,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade700,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Comb (red crest)
          Positioned(
            top: 0,
            right: 14,
            child: Container(
              width: 12,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ),
          ),
          // Wings
          Positioned(
            left: 12,
            top: 20,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade400, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build cartoon money
  Widget _buildMoney() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Money bills stacked
        ...List.generate(3, (index) {
          return Transform.translate(
            offset: Offset(index * 4.0, index * -4.0),
            child: Container(
              width: 50,
              height: 30,
              decoration: BoxDecoration(
                color: AppTheme.success,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.success.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'UGX',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

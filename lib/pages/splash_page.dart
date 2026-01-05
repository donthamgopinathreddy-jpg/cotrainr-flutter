import 'package:flutter/material.dart';
import 'dart:async';
import 'login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _dotsController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoRotation;

  @override
  void initState() {
    super.initState();
    
    // Logo animation controller
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Dots animation controller (looping)
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _logoRotation = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _logoController.forward();

    // Navigate to login after delay
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFF7A00),
              const Color(0xFFFFC300),
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _logoController,
            builder: (context, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),
                  
                  // Logo with scale, fade, and rotation
                  Transform.rotate(
                    angle: _logoRotation.value,
                    child: FadeTransition(
                      opacity: _logoOpacity,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 50,
                                spreadRadius: 15,
                              ),
                            ],
                          ),
                          child: Center(
                            child: _buildLogo(isDark),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // Animated dots loader
                  _buildAnimatedDots(),
                  
                  const Spacer(flex: 4),
                  
                  // Version
                  FadeTransition(
                    opacity: _logoOpacity,
                    child: Text(
                      'v1.0',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(bool isDark) {
    // Try to load logo from assets
    return Image.asset(
      isDark ? 'assets/logo_dark.png' : 'assets/logo_light.png',
      width: 140,
      height: 140,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback: Try generic logo.png
        return Image.asset(
          'assets/logo.png',
          width: 140,
          height: 140,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Final fallback: Branded text logo
            return Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF7A00), Color(0xFFFFC300)],
                ),
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Co',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -2,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnimatedDots() {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            // Calculate delay for each dot
            final delay = index * 0.2;
            final animationValue = (_dotsController.value + delay) % 1.0;
            
            // Bounce animation: goes up and down
            final offset = (animationValue < 0.5)
                ? animationValue * 2.0 // 0.0 to 1.0
                : (1.0 - animationValue) * 2.0; // 1.0 to 0.0
            
            // Scale animation: grows and shrinks
            final scale = 0.6 + (offset * 0.4); // 0.6 to 1.0
            
            // Opacity animation: fades in and out
            final opacity = 0.4 + (offset * 0.6); // 0.4 to 1.0
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: Transform.translate(
                offset: Offset(0, -offset * 12), // Move up and down
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

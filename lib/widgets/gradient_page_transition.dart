import 'package:flutter/material.dart';

class GradientPageTransition extends PageTransitionsBuilder {
  final List<Color> gradientColors;

  const GradientPageTransition({required this.gradientColors});

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _GradientTransition(
      animation: animation,
      gradientColors: gradientColors,
      child: child,
    );
  }
}

class _GradientTransition extends StatelessWidget {
  final Animation<double> animation;
  final List<Color> gradientColors;
  final Widget child;

  const _GradientTransition({
    required this.animation,
    required this.gradientColors,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Stack(
          children: [
            // Gradient background that fades in
            FadeTransition(
              opacity: animation,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                ),
              ),
            ),
            // Page content with slide and fade
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                ),
                child: this.child,
              ),
            ),
          ],
        );
      },
      child: child,
    );
  }
}












































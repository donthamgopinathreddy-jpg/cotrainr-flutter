import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Card Press Wrapper for scale animation
class CardPressWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const CardPressWrapper({super.key, required this.child, required this.onTap});

  @override
  State<CardPressWrapper> createState() => _CardPressWrapperState();
}

class _CardPressWrapperState extends State<CardPressWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

// Sparkline Painter for charts
class SparklinePainter extends CustomPainter {
  final List<int> data;
  final double animationValue;
  final bool isDark;
  final Color color;

  SparklinePainter({
    required this.data,
    required this.animationValue,
    required this.isDark,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.reduce((a, b) => a > b ? a : b).toDouble();
    final minValue = data.reduce((a, b) => a < b ? a : b).toDouble();
    final range = maxValue - minValue;
    final stepX = size.width / (data.length - 1);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final visibleCount = (data.length * animationValue).ceil();

    for (int i = 0; i < visibleCount && i < data.length; i++) {
      final x = i * stepX;
      final normalizedValue = range > 0 ? (data[i] - minValue) / range : 0.5;
      final y =
          size.height -
          (normalizedValue * size.height * 0.8) -
          (size.height * 0.1);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw dots on points
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < visibleCount && i < data.length; i++) {
      final x = i * stepX;
      final normalizedValue = range > 0 ? (data[i] - minValue) / range : 0.5;
      final y =
          size.height -
          (normalizedValue * size.height * 0.8) -
          (size.height * 0.1);

      canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Animation helper
Widget buildAnimatedSection(Widget child, int delay) {
  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: 1.0),
    duration: Duration(milliseconds: 480 + delay),
    curve: Curves.easeOut,
    builder: (context, value, child) {
      return Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      );
    },
    child: child,
  );
}

String formatNumber(int value) {
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  return value.toString();
}


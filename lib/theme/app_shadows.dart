import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppShadows {
  static List<BoxShadow> card(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
    ];
  }
  
  static List<BoxShadow> cardSoft(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ];
  }
  
  static List<BoxShadow> button(BuildContext context) {
    return [
      BoxShadow(
        color: AppColors.primaryStart.withValues(alpha: 0.3),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }
}


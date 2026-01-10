import 'package:flutter/material.dart';

class AppText {
  static const String fontFamily = 'Poppins';
  
  // Headings
  static TextStyle heading1(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: isDark ? Colors.white : const Color(0xFF1F2937),
      height: 1.2,
      letterSpacing: -0.5,
    );
  }
  
  static TextStyle heading2(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: isDark ? Colors.white : const Color(0xFF1F2937),
      height: 1.2,
    );
  }
  
  static TextStyle heading3(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: isDark ? Colors.white : const Color(0xFF1F2937),
      height: 1.2,
    );
  }
  
  // Body
  static TextStyle bodyLarge(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: isDark ? Colors.white : const Color(0xFF1F2937),
      height: 1.5,
    );
  }
  
  static TextStyle bodyMedium(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: isDark ? Colors.white : const Color(0xFF1F2937),
      height: 1.5,
    );
  }
  
  static TextStyle bodySmall(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
      height: 1.4,
    );
  }
  
  // Labels
  static TextStyle label(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF1F2937).withValues(alpha: 0.7),
      height: 1.2,
    );
  }
  
  // Caption
  static TextStyle caption(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
      height: 1.3,
    );
  }
}



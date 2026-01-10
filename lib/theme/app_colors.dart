import 'package:flutter/material.dart';

class AppColors {
  // Brand Gradient
  static const Color primaryStart = Color(0xFFFF7A00);
  static const Color primaryEnd = Color(0xFFFFC300);
  
  // Backgrounds
  static const Color backgroundDark = Color(0xFF0B0F14);
  static const Color backgroundLight = Color(0xFFF6F7FB);
  
  // Surface Cards
  static const Color surfaceDark = Color(0xFF121A27);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  
  // Accents
  static const Color accentSteps = Color(0xFF00E5A8);
  static const Color accentCalories = Color(0xFFFF7A00);
  static const Color accentWater = Color(0xFF4DA3FF);
  static const Color accentBMI = Color(0xFF9B7CFF);
  
  // BMI Status Colors
  static const Color bmiUnderweight = Color(0xFF3B82F6);
  static const Color bmiNormal = Color(0xFF10B981);
  static const Color bmiOverweight = Color(0xFFF59E0B);
  static const Color bmiObese = Color(0xFFEF4444);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryStart, primaryEnd],
  );
  
  static LinearGradient get primaryGradientReversed => const LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [primaryStart, primaryEnd],
  );
}



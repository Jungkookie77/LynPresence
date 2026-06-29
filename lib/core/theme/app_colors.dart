import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFFF3E8FF); // Soft lavender
  static const Color cardColor = Colors.white;
  static const Color glassWhite = Color(0xB3FFFFFF); // 70% white for glass
  
  // Primary Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF9B63F8), Color(0xFF7A3FF3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentPinkGradient = LinearGradient(
    colors: [Color(0xFFFF85C2), Color(0xFFFF529D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentYellowGradient = LinearGradient(
    colors: [Color(0xFFFFC671), Color(0xFFFF9E2D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentBlueGradient = LinearGradient(
    colors: [Color(0xFF76D0FF), Color(0xFF38A5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Texts
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
}

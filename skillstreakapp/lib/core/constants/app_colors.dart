import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF008080);
  static const Color secondary = Color(0xFFFF9800);
  static const Color accent = Color(0xFF4CAF50);
  
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFF44336);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFF9E9E9E);
  
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);
  
  // Category colors
  static const Color sports = Color(0xFFFF9800);
  static const Color music = Color(0xFF9C27B0);
  static const Color arts = Color(0xFFE91E63);
  static const Color debate = Color(0xFF2196F3);
  static const Color dance = Color(0xFFF44336);
  static const Color science = Color(0xFF4CAF50);
  static const Color technology = Color(0xFF3F51B5);
  static const Color leadership = Color(0xFFFFC107);
  static const Color writing = Color(0xFF795548);
}

class AppGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF008080), Color(0xFF00BFA5)],
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
  );
}
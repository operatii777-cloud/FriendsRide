import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFF1976D2); // Deep Blue
  static const Color primaryLight = Color(0xFF42A5F5); // Light Blue
  static const Color primaryDark = Color(0xFF0D47A1); // Dark Blue

  // Secondary Colors
  static const Color secondary = Color(0xFF388E3C); // Green for success
  static const Color secondaryLight = Color(0xFF66BB6A); // Light Green
  static const Color secondaryDark = Color(0xFF2E7D32); // Dark Green

  // Accent & Action Colors
  static const Color accent = Color(0xFFFF6B35); // Orange for CTAs
  static const Color warning = Color(0xFFF57C00); // Amber for warnings
  static const Color error = Color(0xFFD32F2F); // Red for errors
  static const Color success = Color(0xFF388E3C); // Green for success

  // Background & Surface Colors
  static const Color background = Color(0xFFF8F9FA); // Very light gray
  static const Color surface = Colors.white; // Pure white
  static const Color surfaceVariant = Color(0xFFF5F5F5); // Light gray

  // Text Colors
  static const Color textPrimary = Color(0xFF212121); // Almost black
  static const Color textSecondary = Color(0xFF757575); // Medium gray
  static const Color textDisabled = Color(0xFFBDBDBD); // Light gray
  static const Color textOnPrimary = Colors.white; // White on blue
  static const Color textHint = Color(0xFFBDBDBD); // Hint / placeholder gray

  // Border & Divider
  static const Color border = Color(0xFFE0E0E0); // Light border

  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, Color(0xFFFF8A65)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Category Specific Colors
  static const Color standardCategory = Color(0xFF1976D2); // Blue
  static const Color familyCategory = Color.fromARGB(255, 179, 182, 19);
  static const Color energyCategory = Color(0xFF388E3C); // Green
  static const Color bestCategory = Color(0xFF7B1FA2); // Purple

  // Quick Address Colors
  static const LinearGradient homeGradient = LinearGradient(
    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
  );

  static const LinearGradient workGradient = LinearGradient(
    colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
  );

  static const LinearGradient favoriteGradient = LinearGradient(
    colors: [Color(0xFFffecd2), Color(0xFFfcb69f)],
  );

  // Shadow Colors
  static Color shadowLight = Colors.black.withValues(alpha: 0.1);
  static Color shadowMedium = Colors.black.withValues(alpha: 0.2);
  static Color shadowDark = Colors.black.withValues(alpha: 0.3);
}

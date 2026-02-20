import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primaryLight,
    scaffoldBackgroundColor: Colors.grey[100],
    colorScheme: ColorScheme.light(
      primary: AppColors.primaryLight,
      secondary: AppColors.secondaryLight,
      surface: Colors.white,
      // background: Colors.grey[100]!, // Deprecated
      error: Colors.red.shade700,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.black87,
      // onBackground: Colors.black87, // Deprecated
      onError: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primaryLight,
      elevation: 4,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: AppColors.primaryLight,
      textTheme: ButtonTextTheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.primaryLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey[400]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: AppColors.primaryLight, width: 2.0),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryDark,
    scaffoldBackgroundColor: const Color(0xFF1A1A2E),
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryDark,
      secondary: AppColors.secondaryDark,
      surface: const Color(0xFF16213E),
      // background: const Color(0xFF1A1A2E), // Deprecated
      error: Colors.red.shade400,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      // REMEDIAT: Am înlocuit withOpacity și am eliminat onBackground
      onSurface: Colors.white.withAlpha(222), // Echivalent cu Opacity 0.87
      // onBackground: Colors.white.withAlpha(222), // Deprecated
      onError: Colors.black,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF16213E),
      elevation: 4,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: AppColors.primaryDark,
      textTheme: ButtonTextTheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.primaryDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: AppColors.primaryDark, width: 2.0),
      ),
    ),
  );

  // High-contrast variants
  static final ThemeData highContrastLight = lightTheme.copyWith(
    colorScheme: lightTheme.colorScheme.copyWith(
      onSurface: Colors.black,
      surface: Colors.white,
    ),
    textTheme: lightTheme.textTheme.apply(
      bodyColor: Colors.black,
      displayColor: Colors.black,
    ),
    dividerColor: Colors.black,
    focusColor: Colors.black,
  );

  static final ThemeData highContrastDark = darkTheme.copyWith(
    colorScheme: darkTheme.colorScheme.copyWith(
      onSurface: Colors.white,
      surface: const Color(0xFF000000),
    ),
    textTheme: darkTheme.textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    dividerColor: Colors.white,
    focusColor: Colors.white,
  );
}
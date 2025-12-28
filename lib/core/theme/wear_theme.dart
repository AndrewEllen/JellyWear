import 'package:flutter/material.dart';

/// Dark AMOLED theme optimized for Wear OS displays.
class WearTheme {
  // Jellyfin brand color
  static const Color jellyfinPurple = Color(0xFF00A4DC);
  static const Color jellyfinPurpleDark = Color(0xFF0084B4);

  // Surface colors for AMOLED
  static const Color background = Colors.black;
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceVariant = Color(0xFF2A2A2A);

  // Text colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textDisabled = Color(0xFF606060);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: jellyfinPurple,
      colorScheme: const ColorScheme.dark(
        primary: jellyfinPurple,
        secondary: jellyfinPurple,
        surface: surface,
        error: Color(0xFFCF6679),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.black,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 12,
          color: textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 10,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
      ),
      iconTheme: const IconThemeData(
        color: textPrimary,
        size: 24,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: jellyfinPurple,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: jellyfinPurple,
          minimumSize: const Size(48, 48),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textPrimary,
          minimumSize: const Size(48, 48),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: jellyfinPurple, width: 2),
        ),
        hintStyle: const TextStyle(color: textSecondary),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: jellyfinPurple,
        circularTrackColor: surfaceVariant,
        linearTrackColor: surfaceVariant,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minLeadingWidth: 24,
        iconColor: textPrimary,
        textColor: textPrimary,
      ),
      dividerTheme: const DividerThemeData(
        color: surfaceVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

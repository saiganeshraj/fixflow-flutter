import 'package:flutter/material.dart';

/// FixFlow Material 3 theme.
/// Palette: deep navy text, teal primary, warm neutral surfaces.
class FixFlowTheme {
  // Brand colours
  static const Color primaryTeal = Color(0xFF245C4A);
  static const Color primaryTealLight = Color(0xFF4CAAA9);
  static const Color navyText = Color(0xFF173E38);
  static const Color warmSurface = Color(0xFFF8F8F2);
  static const Color warmSurfaceVariant = Color(0xFFEDF0E6);
  static const Color errorRed = Color(0xFFC0392B);
  static const Color successGreen = Color(0xFF27AE60);
  static const Color warningAmber = Color(0xFFF39C12);
  static const Color infoBlue = Color(0xFF2980B9);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primaryTeal,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFD9ED92),
      onPrimaryContainer: const Color(0xFF004040),
      secondary: const Color(0xFF5B7FA6),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFD0E4F7),
      onSecondaryContainer: const Color(0xFF1A3A5C),
      tertiary: const Color(0xFFB06000),
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFFFDDB3),
      onTertiaryContainer: const Color(0xFF5A3000),
      error: errorRed,
      onError: Colors.white,
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF410002),
      surface: warmSurface,
      onSurface: navyText,
      surfaceContainerHighest: warmSurfaceVariant,
      onSurfaceVariant: const Color(0xFF4A5568),
      outline: const Color(0xFFB0A99F),
      outlineVariant: const Color(0xFFD5CFC9),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: navyText,
      onInverseSurface: warmSurface,
      inversePrimary: primaryTealLight,
      surfaceTint: primaryTeal,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'FixFlowRoboto',
    );

    return base.copyWith(
      scaffoldBackgroundColor: warmSurface,
      textTheme: base.textTheme.apply(
        bodyColor: navyText,
        displayColor: navyText,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: warmSurface,
        foregroundColor: navyText,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: warmSurface,
        titleTextStyle: TextStyle(
          fontFamily: 'FixFlowRoboto',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: navyText,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFE0E6DC)),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: warmSurfaceVariant,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: TextStyle(
          color: navyText,
          fontFamily: 'FixFlowRoboto',
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: TextStyle(
            fontFamily: 'FixFlowRoboto',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryTeal,
          side: const BorderSide(color: primaryTeal, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: TextStyle(
            fontFamily: 'FixFlowRoboto',
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryTeal,
          textStyle: TextStyle(
            fontFamily: 'FixFlowRoboto',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD5CFC9)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD5CFC9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryTeal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        labelStyle: TextStyle(
          fontFamily: 'FixFlowRoboto',
          fontSize: 14,
          color: const Color(0xFF4A5568),
        ),
        hintStyle: TextStyle(
          fontFamily: 'FixFlowRoboto',
          fontSize: 14,
          color: const Color(0xFF9CA3AF),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(
            fontFamily: 'FixFlowRoboto',
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        elevation: 1,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.white,
        indicatorColor: colorScheme.primaryContainer,
        selectedIconTheme: const IconThemeData(color: primaryTeal),
        unselectedIconTheme: IconThemeData(color: navyText.withAlpha(128)),
        labelType: NavigationRailLabelType.all,
        selectedLabelTextStyle: TextStyle(
          fontFamily: 'FixFlowRoboto',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: primaryTeal,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontFamily: 'FixFlowRoboto',
          fontSize: 12,
          color: navyText.withAlpha(128),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E0DB),
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: navyText,
        contentTextStyle: TextStyle(
          fontFamily: 'FixFlowRoboto',
          color: Colors.white,
          fontSize: 14,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        backgroundColor: Colors.white,
        elevation: 8,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        elevation: 4,
        titleTextStyle: TextStyle(
          fontFamily: 'FixFlowRoboto',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: navyText,
        ),
        contentTextStyle: TextStyle(
          fontFamily: 'FixFlowRoboto',
          fontSize: 14,
          color: const Color(0xFF4A5568),
        ),
      ),
    );
  }
}

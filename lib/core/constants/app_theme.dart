import 'package:flutter/material.dart';

class AppColors {
  // Sacred Temple Palette - Modern, Warm, High Contrast
  static const Color templeMaroon = Color(0xFF7F1D1D);     // Deep crimson maroon
  static const Color maroonDark = Color(0xFF5A1010);       // Ultra high-contrast maroon
  static const Color deepSaffron = Color(0xFFEA580C);      // Sacred saffron
  static const Color saffronLight = Color(0xFFFFF7ED);     // Warm saffron tint
  static const Color goldAccent = Color(0xFFD97706);       // Temple brass gold
  static const Color goldLight = Color(0xFFFEF3C7);        // Soft gold glow

  // Background & Surfaces
  static const Color lightBackground = Color(0xFFFAF8F5);  // Serene temple ivory cream
  static const Color cardBackground = Color(0xFFFFFFFF);   // Crisp pure white
  static const Color surfaceElevated = Color(0xFFFFFFFF);  // Floating cards

  // High-Contrast Typography (WCAG AAA for Seniors)
  static const Color textPrimary = Color(0xFF1C1917);      // Deep charcoal espresso
  static const Color textSecondary = Color(0xFF57534E);    // High contrast warm stone
  static const Color textMuted = Color(0xFF78716C);        // Accessible helper text

  // Semantic Status Colors (Vibrant & Distinct)
  static const Color success = Color(0xFF15803D);          // Forest green
  static const Color successBg = Color(0xFFDCFCE7);        // Soft green tint
  static const Color warning = Color(0xFFB45309);          // Amber warning
  static const Color warningBg = Color(0xFFFEF3C7);        // Soft amber tint
  static const Color error = Color(0xFFB91C1C);            // High-contrast red
  static const Color errorBg = Color(0xFFFEE2E2);          // Soft red tint
  static const Color info = Color(0xFF0369A1);             // Serene divine ocean blue
  static const Color infoBg = Color(0xFFE0F2FE);           // Soft blue tint

  // Accent
  static const Color accentColor = deepSaffron;
}

class AppTheme {
  static const Color primaryColor = AppColors.templeMaroon;
  static const Color accentColor = AppColors.deepSaffron;
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;

  // Adaptive Color Helpers for Dark Mode Consistency
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color cardBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF0A0A0A) : AppColors.cardBackground;

  static Color elevatedBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF141414) : const Color(0xFFFFFFFF);

  static Color textPrimaryOf(BuildContext context) =>
      isDark(context) ? const Color(0xFFFFFFFF) : AppColors.textPrimary;

  static Color textSecondaryOf(BuildContext context) =>
      isDark(context) ? const Color(0xFFA1A1AA) : AppColors.textSecondary;

  static Color borderColor(BuildContext context) =>
      isDark(context) ? const Color(0xFF222222) : const Color(0xFFE2E8F0);

  // Nav label strings (fallback)
  static const String appName = 'Sannidhi';
  static const String appNameTamil = 'சந்நிதி';
  static const String english = 'Eng';
  static const String tamil = 'தமிழ்';
  static const String bookings = 'Bookings';
  static const String bookingsTamil = 'முன்பதிவு';
  static const String festivals = 'Festivals';
  static const String festivalsTamil = 'விழாக்கள்';
  static const String home = 'Home';
  static const String homeTamil = 'முகப்பு';
  static const String services = 'Services';
  static const String servicesTamil = 'சேவைகள்';
  static const String donation = 'Donation';
  static const String donationTamil = 'தானம்';

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: accentColor,
      surface: AppColors.cardBackground,
      surfaceTint: Colors.transparent,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.lightBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      toolbarHeight: 64,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: 0.3,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 12,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE7E5E4), width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        minimumSize: const Size(0, 56), // Large touch target for seniors
        elevation: 2,
        shadowColor: primaryColor.withValues(alpha: 0.3),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        minimumSize: const Size(0, 56),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        minimumSize: const Size(0, 50),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      labelStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD6D3D1), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD6D3D1), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 2.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: const Color(0xFFEF4444),
      secondary: accentColor,
      surface: const Color(0xFF000000),
      onSurface: const Color(0xFFFFFFFF),
      onSurfaceVariant: const Color(0xFFA1A1AA),
      surfaceTint: Colors.transparent,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF000000),
    cardColor: const Color(0xFF0A0A0A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF000000),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      toolbarHeight: 64,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: 0.3,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF000000),
      selectedItemColor: Color(0xFFF97316),
      unselectedItemColor: Color(0xFFA1A1AA),
      type: BottomNavigationBarType.fixed,
      elevation: 12,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF0A0A0A),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFF222222), width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF991B1B),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        minimumSize: const Size(0, 56),
        elevation: 2,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFFDE68A),
        side: const BorderSide(color: Color(0xFFD97706), width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        minimumSize: const Size(0, 56),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF0A0A0A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      labelStyle: const TextStyle(
        color: Color(0xFFA1A1AA),
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF222222), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF222222), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFF97316), width: 2.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    ),
  );
}

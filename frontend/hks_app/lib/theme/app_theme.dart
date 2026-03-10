import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colours
  static const Color primary      = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF60AD5E);
  static const Color primaryDark  = Color(0xFF005005);
  static const Color secondary    = Color(0xFF66BB6A);
  static const Color accent       = Color(0xFFFFA726);
  static const Color error        = Color(0xFFD32F2F);

  // Light semantic
  static const Color background  = Color(0xFFF1F8E9);
  static const Color surface     = Color(0xFFFFFFFF);
  static const Color textDark    = Color(0xFF1B5E20);
  static const Color textMedium  = Color(0xFF388E3C);
  static const Color textLight   = Color(0xFF757575);
  static const Color cardBg      = Color(0xFFFFFFFF);
  static const Color divider     = Color(0xFFE8F5E9);

  // Dark semantic
  static const Color darkBackground = Color(0xFF0D1F0E);
  static const Color darkSurface    = Color(0xFF1A2E1B);
  static const Color darkCard       = Color(0xFF1E3620);
  static const Color darkText       = Color(0xFFE8F5E9);
  static const Color darkTextLight  = Color(0xFF9CCC65);

  static ThemeData get theme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg     = isDark ? darkBackground : background;
    final surf   = isDark ? darkSurface : surface;
    final card   = isDark ? darkCard : cardBg;
    final txDark = isDark ? darkText : textDark;
    final txLite = isDark ? darkTextLight : textLight;
    final inputFill = isDark ? const Color(0xFF1E3620) : Colors.white;

    final cs = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      secondary: secondary,
      surface: surf,
      error: error,
    ).copyWith(
      surfaceContainerHighest: card,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: cs,
      scaffoldBackgroundColor: bg,
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        headlineLarge:  GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold,  color: txDark),
        headlineMedium: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700,  color: txDark),
        titleLarge:     GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600,  color: txDark),
        titleMedium:    GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500,  color: txDark),
        bodyLarge:      GoogleFonts.poppins(fontSize: 15, color: txDark),
        bodyMedium:     GoogleFonts.poppins(fontSize: 14, color: txLite),
        labelLarge:     GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? const Color(0xFF2E5E30) : const Color(0xFFDCEDC8), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? const Color(0xFF2E5E30) : const Color(0xFFDCEDC8), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(color: txLite),
        hintStyle: GoogleFonts.poppins(color: txLite, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        elevation: isDark ? 1 : 2,
        color: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? const Color(0xFF1E3620) : const Color(0xFFE8F5E9),
        labelStyle: GoogleFonts.poppins(color: primary, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surf,
        selectedItemColor: primary,
        unselectedItemColor: txLite,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surf,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

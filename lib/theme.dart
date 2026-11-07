import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palet CleanDrive: Navy, Cream, Red Metal (sesuai desain).
const kNavy = Color(0xFF0B1F44);
const kNavyDark = Color(0xFF071430);
const kNavySoft = Color(0xFF132A57);
const kNavyLight = Color(0xFF1B3A73);
const kCream = Color(0xFFF4E8D6);
const kRed = Color(0xFFB61E1E);
const kSky = Color(0xFF60BBE9);
const kGold = Color(0xFFF5B31B);
const kGreen = Color(0xFF2E9E5B);

// Permukaan terang (desain baru)
const kBg = Color(0xFFF6F7FB);
const kMuted = Color(0xFF6A7691);
const kLine = Color(0x1F0B1F44);

ThemeData buildTheme() {
  const scheme = ColorScheme.light(
    primary: kRed,
    onPrimary: Colors.white,
    secondary: kNavy,
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: kNavy,
    error: Color(0xFFD64545),
    outline: Color(0x330B1F44),
    outlineVariant: kLine,
  );
  final base = ThemeData(brightness: Brightness.light).textTheme;
  final tt = GoogleFonts.plusJakartaSansTextTheme(base).apply(bodyColor: kNavy, displayColor: kNavy);
  OutlineInputBorder b(Color c, [double w = 1]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c, width: w));

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kBg,
    textTheme: tt,
    appBarTheme: AppBarTheme(
      backgroundColor: kBg,
      foregroundColor: kNavy,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      titleTextStyle: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: kNavy, fontSize: 17),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kRed,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: kNavy, textStyle: const TextStyle(fontWeight: FontWeight.w700)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: b(kLine),
      enabledBorder: b(kLine),
      focusedBorder: b(kRed, 2),
      errorBorder: b(const Color(0xFFD64545)),
      focusedErrorBorder: b(const Color(0xFFD64545), 2),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: kNavy,
      behavior: SnackBarBehavior.floating,
      contentTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    ),
    dividerColor: kLine,
  );
}

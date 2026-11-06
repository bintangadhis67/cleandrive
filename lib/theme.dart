import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palet CleanDrive sesuai desain: Navy, Cream, Red Metal.
const kNavy = Color(0xFF0B1F44);
const kNavyDark = Color(0xFF071430);
const kNavySoft = Color(0xFF132A57);
const kCream = Color(0xFFF4E8D6);
const kRed = Color(0xFFB61E1E);
const kSky = Color(0xFF60BBE9); // dipertahankan agar kode lama tetap valid
const kBg = kNavy;

/// Tema utama: latar navy, teks cream, aksen merah.
ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: kRed,
    onPrimary: Colors.white,
    secondary: kCream,
    onSecondary: kNavy,
    surface: kNavy,
    onSurface: kCream,
    onSurfaceVariant: Color(0xB3F4E8D6),
    error: Color(0xFFFF7B7B),
    outline: Color(0x66F4E8D6),
    outlineVariant: Color(0x33F4E8D6),
    surfaceContainerLow: kNavySoft,
    surfaceContainer: kNavySoft,
    surfaceContainerHigh: kNavySoft,
    surfaceContainerHighest: Color(0xFF1E3A6E),
  );
  final base = ThemeData(brightness: Brightness.dark, colorScheme: scheme).textTheme;
  final tt = GoogleFonts.plusJakartaSansTextTheme(base).apply(bodyColor: kCream, displayColor: kCream);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kNavy,
    textTheme: tt,
    appBarTheme: AppBarTheme(
      backgroundColor: kNavy,
      foregroundColor: kCream,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: kCream),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: kNavySoft,
      indicatorColor: kRed.withOpacity(.5),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: kCream,
      contentTextStyle: TextStyle(color: kNavy, fontWeight: FontWeight.w600),
    ),
  );
}

/// Tema untuk permukaan cream (kartu, form login): teks navy, aksen merah.
ThemeData buildCardTheme() {
  const scheme = ColorScheme.light(
    primary: kRed,
    onPrimary: Colors.white,
    secondary: kNavy,
    surface: Colors.white,
    onSurface: kNavy,
    outline: Color(0x330B1F44),
    outlineVariant: Color(0x1F0B1F44),
  );
  final base = ThemeData(brightness: Brightness.light, colorScheme: scheme).textTheme;
  final tt = GoogleFonts.plusJakartaSansTextTheme(base).apply(bodyColor: kNavy, displayColor: kNavy);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    textTheme: tt,
    dividerColor: const Color(0x1F0B1F44),
    iconTheme: const IconThemeData(color: kNavy),
  );
}

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/motion.dart' show SlideFadePageTransitionsBuilder;

// ---------------------------------------------------------------------------
// DESIGN TOKENS CleanDrive
// Semua warna, radius, jarak, dan bayangan dipusatkan di sini supaya konsisten.
// ---------------------------------------------------------------------------

// Warna utama
const kNavy = Color(0xFF10264C); // Primary Navy (identitas utama)
const kCream = Color(0xFFF7F1E7); // Secondary Cream
const kRed = Color(0xFFC62026); // Accent Metal Red (tombol utama, selected state)

// Turunan navy untuk kartu gelap
const kNavyDark = Color(0xFF0A1A38);
const kNavySoft = Color(0xFF163058);
const kNavyLight = Color(0xFF1E3F77);

// Warna pendukung
const kBg = Color(0xFFF5F6FA); // Background
const kText = Color(0xFF152747); // Text Primary
const kMuted = Color(0xFF7B879B); // Text Secondary
const kGold = Color(0xFFE9AD35); // Hanya untuk Coins dan elemen reward
const kGreen = Color(0xFF249B62); // Success
const kWarn = Color(0xFFE9A23B); // Warning
const kError = Color(0xFFD92D35); // Error
const kSky = Color(0xFF60BBE9);
const kLine = Color(0x1F10264C); // Border tipis
const kLineSoft = Color(0x0D10264C); // Border sangat halus untuk kartu

// Radius
const kRadiusCard = 26.0; // kartu lebih membulat (gaya Gen-Z)
const kRadiusButton = 18.0; // tombol
const kRadiusChip = 22.0;

// Spasi
const kSpace = 8.0;

// Bayangan lembut
const kShadowSoft = [BoxShadow(color: Color(0x1410264C), blurRadius: 26, offset: Offset(0, 12))];

ThemeData buildTheme() {
  const scheme = ColorScheme.light(
    primary: kRed,
    onPrimary: Colors.white,
    secondary: kNavy,
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: kText,
    error: kError,
    outline: Color(0x3310264C),
    outlineVariant: kLine,
  );
  final base = ThemeData(brightness: Brightness.light).textTheme;
  // Plus Jakarta Sans: Bold untuk heading, SemiBold judul kartu, Medium tombol/navigasi, Regular deskripsi.
  final tt = GoogleFonts.plusJakartaSansTextTheme(base).apply(bodyColor: kText, displayColor: kText);
  OutlineInputBorder b(Color c, [double w = 1]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(kRadiusButton), borderSide: BorderSide(color: c, width: w));

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kBg,
    textTheme: tt,
    // Transisi halaman yang halus di semua platform.
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: SlideFadePageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: SlideFadePageTransitionsBuilder(),
      TargetPlatform.linux: SlideFadePageTransitionsBuilder(),
      TargetPlatform.fuchsia: SlideFadePageTransitionsBuilder(),
    }),
    appBarTheme: AppBarTheme(
      backgroundColor: kBg,
      foregroundColor: kNavy,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      iconTheme: const IconThemeData(color: kRed), // tombol kembali = bisa diklik = merah
      actionsIconTheme: const IconThemeData(color: kRed),
      titleTextStyle: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: kNavy, fontSize: 17),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kRed,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusButton)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kRed,
        minimumSize: const Size(0, 48),
        side: const BorderSide(color: kRed, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusButton)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: kRed, textStyle: const TextStyle(fontWeight: FontWeight.w600)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: b(kLine),
      enabledBorder: b(kLine),
      focusedBorder: b(kRed, 2),
      errorBorder: b(kError),
      focusedErrorBorder: b(kError, 2),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: kNavy,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusButton)),
      contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusCard)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusCard))),
    ),
    dividerColor: kLine,
  );
}
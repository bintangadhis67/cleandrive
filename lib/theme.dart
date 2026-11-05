import 'package:flutter/material.dart';

/// Palet warna CleanDrive (diambil dari logo).
const kNavy = Color(0xFF12205D);
const kNavyDark = Color(0xFF0B1440);
const kSky = Color(0xFF60BBE9);
const kBg = Color(0xFFF4F8FC);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: kNavy).copyWith(
    primary: kNavy,
    onPrimary: Colors.white,
    secondary: kSky,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: kNavy,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: kSky.withOpacity(.35),
    ),
  );
}

import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'admin.dart';
import 'app_state.dart';
import 'auth.dart';
import 'customer.dart';
import 'data/mock_repository.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  // Frontend berdiri sendiri: semua data memakai MockRepository (data tiruan di memori).
  // Saat nanti diintegrasikan dengan backend, cukup ganti dengan Repository yang memanggil API.
  app.init(MockRepository());
  runApp(const CleanDriveApp());
}

class CleanDriveApp extends StatelessWidget {
  const CleanDriveApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'CleanDrive',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        scrollBehavior: const _AppScrollBehavior(),
        // Batasi ukuran teks sistem supaya tampilan di HP tidak pecah.
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(textScaler: mq.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.15)),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const _Root(),
      );
}

/// Daftar geser (mis. produk di beranda) juga bisa diseret dengan mouse di laptop.
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class _Root extends StatefulWidget {
  const _Root();
  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _splash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) setState(() => _splash = false);
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        child: ListenableBuilder(
          key: ValueKey(_splash || app.booting),
          listenable: app,
          builder: (_, __) {
            if (_splash || app.booting) return const SplashScreen();
            // Halaman perkenalan (onboarding) dihapus: belum login -> langsung ke Login/Daftar.
            if (app.me == null) return const AuthScreen();
            return app.isAdmin ? const AdminScreen() : const HomeScreen();
          },
        ),
      );
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    // Lebar logo mengikuti layar: maksimal 260, minimal 160 (aman di HP kecil maupun laptop).
    final logoW = (MediaQuery.sizeOf(context).width * 0.6).clamp(160.0, 260.0);
    return Scaffold(
      backgroundColor: kNavy,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Kotak putih dihapus; memakai logo transparan agar menyatu dengan latar navy.
          Image.asset('assets/images/logo_transparent.png', width: logoW, fit: BoxFit.contain),
          const SizedBox(height: 24),
          Text('DRIVE CLEANER. GO FURTHER.',
              textAlign: TextAlign.center,
              style: GoogleFonts.orbitron(color: kCream, fontSize: 12, letterSpacing: 3, fontWeight: FontWeight.w600)),
          const SizedBox(height: 36),
          SizedBox(
            width: 150,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 2200),
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 4,
                borderRadius: BorderRadius.circular(4),
                color: kRed,
                backgroundColor: Colors.white12,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/app_state.dart';
import 'data/api_repository.dart';
import 'core/theme.dart';
import 'data/mock_repository.dart';
import 'screens/admin/admin.dart';
import 'screens/auth/auth.dart';
import 'screens/home/customer.dart';
import 'widgets/motion.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  const useMock = bool.fromEnvironment('USE_MOCK');
app.init(useMock ? MockRepository() : ApiRepository());
  runApp(const CleanDriveApp());
}

/// Skala ukuran tampilan di laptop / desktop. TETAP (tidak bergantung pada zoom), jadi zoom Chrome
/// (Ctrl + / Ctrl -) tetap berfungsi normal: tampilan = zoom Chrome x kDesktopScale.
/// Sebelumnya 0.8 (membuat tampilan laptop terlihat kecil). Sekarang 1.0 karena layout laptop sudah memakai
/// menu samping + isi dibatasi lebarnya (lihat desktop_shell.dart). Jika masih terasa besar: turunkan (mis. 0.9).
/// HP / tablet kecil (lebar < 900 px) selalu 1.0 (tidak berubah).
const double kDesktopScale = 1.0;

double uiScaleFor(Size s) => s.width < 900 ? 1.0 : kDesktopScale;

class CleanDriveApp extends StatelessWidget {
  const CleanDriveApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'CleanDrive',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        scrollBehavior: const _AppScrollBehavior(),
        // 1) Batasi ukuran teks sistem supaya tampilan di HP tidak pecah.
        // 2) Di laptop/desktop ukuran tampilan diperkecil sedikit (kDesktopScale) agar normal di zoom 100%.
        //    Admin dan HP tetap skala 1.0.
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return ListenableBuilder(
            listenable: app,
            builder: (_, __) {
              final scale = app.isAdmin ? 1.0 : uiScaleFor(mq.size);
              final w = mq.size.width / scale;
              final h = mq.size.height / scale;
              // Susunan widget selalu sama (juga saat skala 1.0) agar navigasi tidak ter-reset.
              return OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: w,
                maxWidth: w,
                minHeight: h,
                maxHeight: h,
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.topLeft,
                  child: MediaQuery(
                    data: mq.copyWith(
                      size: Size(w, h),
                      textScaler: mq.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.15),
                    ),
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              );
            },
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
      body: Stack(children: [
        // Gelembung sabun naik pelan di latar.
        const Positioned.fill(child: FloatingBubbles()),
        Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Logo muncul membesar + kilau berjalan (ShineLogo).
            ShineLogo(child: Image.asset('assets/images/logo_transparent.png', width: logoW, fit: BoxFit.contain)),
            const SizedBox(height: 24),
            FadeSlideIn(
              delay: const Duration(milliseconds: 600),
              child: Text('DRIVE CLEANER. GO FURTHER.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.orbitron(color: kCream, fontSize: 12, letterSpacing: 3, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 36),
            FadeSlideIn(
              delay: const Duration(milliseconds: 800),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Memeriksa akun...', style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 10),
                SizedBox(
                  width: 150,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1800),
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
          ]),
        ),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_state.dart';
import 'customer.dart';
import 'screens.dart';
import 'theme.dart';

void main() => runApp(const CleanDriveApp());

class CleanDriveApp extends StatelessWidget {
  const CleanDriveApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'CleanDrive',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const _Root(),
      );
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
        child: _splash
            ? const SplashScreen(key: ValueKey('splash'))
            : ListenableBuilder(
                key: const ValueKey('root'),
                listenable: app,
                builder: (_, __) => app.user == null
                    ? const AuthScreen()
                    : (app.isAdmin ? const AdminScreen() : const HomeScreen()),
              ),
      );
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kNavy,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
              child: Image.asset('assets/logo.png', width: 280, fit: BoxFit.contain),
            ),
            const SizedBox(height: 28),
            Text('DRIVE CLEANER. GO FURTHER.',
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

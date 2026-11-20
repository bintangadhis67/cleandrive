import 'package:flutter/material.dart';

import '../screens/rewards/reward_ui.dart';

// ===========================================================================
// HEADER NAVY BERGELOMBANG (dipakai bersama oleh halaman Notifikasi dan halaman lain
// yang butuh header seperti Riwayat / Toko). HANYA tampilan, tanpa logika.
// ===========================================================================

/// Gelombang abstrak transparan (kanan atas, kanan bawah, aksen gold tipis).
class HeaderWavePainter extends CustomPainter {
  const HeaderWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final a = Path()
      ..moveTo(w * .62, 0)
      ..cubicTo(w * .78, h * .05, w * .90, h * .42, w, h * .30)
      ..lineTo(w, 0)
      ..close();
    canvas.drawPath(a, Paint()..color = Colors.white.withValues(alpha: .07));
    final b = Path()
      ..moveTo(w * .58, h)
      ..cubicTo(w * .74, h * .62, w * .88, h * .62, w, h * .40)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(b, Paint()..color = Colors.white.withValues(alpha: .10));
    final c = Path()
      ..moveTo(w * .80, h)
      ..cubicTo(w * .88, h * .78, w * .94, h * .74, w, h * .66)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(c, Paint()..color = const Color(0x40FFB91F));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Kotak header gradasi navy dengan sudut bawah membulat dan gelombang.
/// [child] ditempatkan di bawah status bar (padding atas otomatis mengikuti safe area).
class NavyHeader extends StatelessWidget {
  final Widget child;
  final double bottom;
  const NavyHeader({super.key, required this.child, this.bottom = 18});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kRwNavyDark, kRwNavy, kRwNavyLight]),
        boxShadow: [BoxShadow(color: Color(0x4007347F), blurRadius: 22, offset: Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        child: Stack(children: [
          const Positioned.fill(child: CustomPaint(painter: HeaderWavePainter())),
          Padding(
            padding: EdgeInsets.only(top: top + 8, bottom: bottom),
            child: child,
          ),
        ]),
      ),
    );
  }
}
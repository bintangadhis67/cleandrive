import 'package:flutter/material.dart';

/// Gambar mobil + percikan air untuk latar header (Beranda dan Akun).
///
/// Tata letaknya meniru header Booking supaya gambar dan gradient menyatu:
/// - di layar lebar, gambar dibesarkan sampai MEMENUHI TINGGI header (tepi atas/bawahnya tersembunyi),
///   sehingga tidak tampak sebagai kotak kecil;
/// - di HP, gambar mengambil sebagian besar lebar layar dan menempel di kanan bawah;
/// - tepi kiri dan atas gambar dipudarkan ke latar gradient (bukan garis tegas).
///
/// Pakai di dalam Stack header: `const Positioned.fill(child: HeroCarBackdrop())`.
/// Gambar tidak menerima sentuhan (IgnorePointer).
class HeroCarBackdrop extends StatelessWidget {
  const HeroCarBackdrop({super.key});

  static const _asset = 'assets/images/booking_header_car.png';

  /// Memudarkan tepi kiri (10%) dan tepi atas (12%) gambar ke transparan.
  static Widget _edgeFade(Widget child) => ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0x00000000), Color(0xFF000000)],
          stops: [0.0, 0.10],
        ).createShader(rect),
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x00000000), Color(0xFF000000)],
            stops: [0.0, 0.12],
          ).createShader(rect),
          child: child,
        ),
      );

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: LayoutBuilder(
          builder: (context, box) {
            final phone = box.maxWidth < 600;
            // Lebar gambar: bagian dari lebar header, tapi tidak lebih tinggi dari header
            // (gambar beraspek sekitar 2,4 : 1, jadi lebar maksimal = tinggi header x 2,5).
            final byWidth = box.maxWidth * (phone ? .80 : .62);
            final byHeight = box.maxHeight * 2.5;
            final w = (byWidth < byHeight ? byWidth : byHeight).clamp(240.0, 760.0).toDouble();
            return Align(
              alignment: Alignment.bottomRight,
              child: Transform.translate(
                // Sedikit melewati tepi kanan agar tidak ada celah di sisi kanan header.
                offset: Offset(w * (phone ? .08 : .05), 0),
                child: _edgeFade(
                  SizedBox(
                    width: w,
                    child: Image.asset(_asset, fit: BoxFit.fitWidth, filterQuality: FilterQuality.medium),
                  ),
                ),
              ),
            );
          },
        ),
      );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../widgets/widgets.dart';
import '../profile/help.dart';

// ---------------------------------------------------------------------------
// LOKASI OUTLET
// DATA CONTOH: alamat lengkap (nomor jalan, koordinat) dan nomor telepon belum diisi.
// Ganti [kOutlet] dengan data resmi, atau ambil dari API / admin nanti.
// ---------------------------------------------------------------------------
class Outlet {
  final String name, street, city, province, phone;
  final int openHour, closeHour; // jam operasional WIB
  const Outlet({
    required this.name,
    required this.street,
    required this.city,
    required this.province,
    required this.phone,
    this.openHour = 8,
    this.closeHour = 17,
  });

  String get address => '$street, $city, $province';
  String get shortAddress => '$street, $city';

  /// Tautan pencarian Google Maps berdasarkan alamat (tidak butuh koordinat).
  String get mapsUrl => 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';

  String get hoursLabel => '${_hh(openHour)} - ${_hh(closeHour)} WIB';
  static String _hh(int h) => '${h.toString().padLeft(2, '0')}.00';

  /// Buka / tutup saat ini menurut waktu WIB (tidak bergantung zona waktu perangkat).
  bool get isOpenNow {
    final wib = DateTime.now().toUtc().add(const Duration(hours: 7));
    final m = wib.hour * 60 + wib.minute;
    return m >= openHour * 60 && m < closeHour * 60;
  }
}

const kOutlet = Outlet(
  name: 'CleanDrive Menganti',
  street: 'Jl. Menganti',
  city: 'Gresik',
  province: 'Jawa Timur',
  phone: kSupportPhone,
);

/// Ilustrasi peta sederhana (bukan peta sungguhan).
class _MapPainter extends CustomPainter {
  const _MapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFE6ECF5));
    final block = Paint()..color = const Color(0xFFF3F6FB);
    final cols = (size.width / 70).ceil(), rows = (size.height / 60).ceil();
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(c * 70 + 8.0, r * 60 + 8.0, 54, 44), const Radius.circular(8)),
          block,
        );
      }
    }
    // sungai
    final river = Path()
      ..moveTo(0, size.height * .78)
      ..cubicTo(size.width * .3, size.height * .6, size.width * .55, size.height * .98, size.width, size.height * .7);
    canvas.drawPath(
      river,
      Paint()
        ..color = const Color(0xFFBFDDF2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round,
    );
    // jalan utama
    final road = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, size.height * .38), Offset(size.width, size.height * .3), road);
    canvas.drawLine(Offset(size.width * .55, 0), Offset(size.width * .45, size.height), road..strokeWidth = 9);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Peta ilustrasi dengan pin outlet di tengah.
class OutletMap extends StatelessWidget {
  final double height;
  final double radius;
  const OutletMap({super.key, this.height = 200, this.radius = 28});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(alignment: Alignment.center, children: [
            const Positioned.fill(child: CustomPaint(painter: _MapPainter())),
            Container(
              width: height * .5,
              height: height * .5,
              decoration: BoxDecoration(shape: BoxShape.circle, color: kRed.withValues(alpha: .12)),
            ),
            Container(
              width: height * .28,
              height: height * .28,
              decoration: BoxDecoration(shape: BoxShape.circle, color: kRed.withValues(alpha: .2)),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: height * .12),
              child: Icon(Icons.location_on_rounded, size: height * .3, color: kRed),
            ),
          ]),
        ),
      );
}

class _OpenChip extends StatelessWidget {
  const _OpenChip();
  @override
  Widget build(BuildContext context) {
    final open = kOutlet.isOpenNow;
    final c = open ? kGreen : kError;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: .14), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(open ? 'Buka sekarang' : 'Tutup', style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 12)),
      ]),
    );
  }
}

void openOutlet(BuildContext context) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => const OutletScreen()));

// ---------- KARTU OUTLET DI BERANDA ----------
class OutletHomeCard extends StatelessWidget {
  const OutletHomeCard({super.key});

  @override
  Widget build(BuildContext context) => Panel(
        padding: const EdgeInsets.all(12),
        onTap: () => openOutlet(context),
        child: Row(children: [
          const SizedBox(width: 96, child: OutletMap(height: 96, radius: 20)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Lokasi Outlet', style: TextStyle(color: kMuted, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(kOutlet.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 2),
              Text(kOutlet.address, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 12.5)),
              const SizedBox(height: 8),
              Row(children: [
                const _OpenChip(),
                const SizedBox(width: 8),
                Flexible(child: Text(kOutlet.hoursLabel, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 12))),
              ]),
            ]),
          ),
          const Icon(Icons.chevron_right, color: kMuted),
        ]),
      );
}

// ---------- LAYAR LOKASI OUTLET ----------
class OutletScreen extends StatelessWidget {
  const OutletScreen({super.key});

  void _copy(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    toast(context, '$label disalin');
  }

  Widget _row(IconData icon, String title, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: kNavy, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: kCream, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: kMuted, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.3)),
            ]),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Lokasi Outlet')),
        body: PageList(
          bottom: 32,
          children: [
            const OutletMap(height: 210),
            const SizedBox(height: 16),
            Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(kOutlet.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
                  const _OpenChip(),
                ]),
                const SizedBox(height: 6),
                _row(Icons.location_on_rounded, 'Alamat', kOutlet.address),
                _row(Icons.schedule_rounded, 'Jam operasional', 'Setiap hari, ${kOutlet.hoursLabel}'),
                _row(Icons.phone_rounded, 'Telepon', kOutlet.phone),
              ]),
            ),
            const SizedBox(height: 16),
            RedButton('Salin Alamat', icon: Icons.copy_rounded, onPressed: () => _copy(context, 'Alamat', kOutlet.address)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _copy(context, 'Tautan Google Maps', kOutlet.mapsUrl),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Salin Tautan Google Maps'),
              ),
            ),
            const SizedBox(height: 14),
            const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline, size: 15, color: kMuted),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Gambar peta hanya ilustrasi. Tempel tautan Google Maps di browser untuk melihat peta dan rute. Nomor telepon dan alamat lengkap adalah data contoh.',
                  style: TextStyle(color: kMuted, fontSize: 12, height: 1.4),
                ),
              ),
            ]),
          ],
        ),
      );
}
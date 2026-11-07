import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'data/repository.dart';
import 'models.dart';
import 'theme.dart';

final fmtDateTime = DateFormat('d MMM yyyy, HH:mm', 'id_ID');
final fmtDate = DateFormat('d MMM yyyy', 'id_ID');
final fmtHm = DateFormat('HH:mm');

const kStatusColors = [Color(0xFFD08A00), kRed, Color(0xFF3B5FB8), kGreen];

void toast(BuildContext c, String msg, {bool error = false}) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? const Color(0xFFB3261E) : kNavy,
    ));
}

/// Menjalankan pekerjaan async dan menampilkan pesan error bila gagal.
Future<T?> guard<T>(BuildContext context, Future<T> Function() job) async {
  try {
    return await job();
  } on ApiException catch (e) {
    if (context.mounted) toast(context, e.message, error: true);
  } catch (_) {
    if (context.mounted) toast(context, 'Terjadi kesalahan. Coba lagi.', error: true);
  }
  return null;
}

/// Kartu putih bergaya desain.
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color color;
  final bool outlined;
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color = Colors.white,
    this.outlined = true,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: outlined ? Border.all(color: kLine) : null,
          boxShadow: const [BoxShadow(color: Color(0x0F0B1F44), blurRadius: 14, offset: Offset(0, 6))],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      );
}

/// Kartu navy bergradasi (layanan dan banner).
class NavyCard extends StatelessWidget {
  final Widget child;
  final double radius;
  const NavyCard({super.key, required this.child, this.radius = 24});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kNavyLight, kNavySoft]),
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(radius), child: child),
      );
}

Widget sec(String t, {double top = 22, Widget? trailing}) => Padding(
      padding: EdgeInsets.only(top: top, bottom: 10),
      child: Row(children: [
        Expanded(child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kNavy))),
        if (trailing != null) trailing,
      ]),
    );

Widget pageHeader(String title, String sub) => Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kNavy)),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(color: kMuted)),
      ]),
    );

/// Tombol merah lebar penuh.
class RedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final Color? color;
  const RedButton(this.label, {super.key, this.onPressed, this.icon, this.busy = false, this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: color ?? kRed),
          onPressed: busy ? null : onPressed,
          child: busy
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                  if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                  Text(label),
                ]),
        ),
      );
}

class StatusChip extends StatelessWidget {
  final Booking b;
  const StatusChip(this.b, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = b.cancelled ? const Color(0xFFB3261E) : kStatusColors[b.status];
    final t = b.cancelled ? 'Dibatalkan' : statusLabels[b.status];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withOpacity(.14), borderRadius: BorderRadius.circular(20)),
      child: Text(t, style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}

class PayChip extends StatelessWidget {
  final Booking b;
  const PayChip(this.b, {super.key});

  @override
  Widget build(BuildContext context) {
    final (t, c) = switch (b.payStatus) {
      'paid' => ('Lunas', kGreen),
      'refunded' => ('Dikembalikan', kMuted),
      _ => ('Belum dibayar', const Color(0xFFD08A00)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withOpacity(.14), borderRadius: BorderRadius.circular(20)),
      child: Text(t, style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}

/// Bintang rating (mendukung nilai desimal).
class StarRow extends StatelessWidget {
  final double rating;
  final double size;
  const StarRow(this.rating, {super.key, this.size = 16});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rating >= i ? Icons.star_rounded : (rating >= i - .5 ? Icons.star_half_rounded : Icons.star_outline_rounded),
            size: size,
            color: kGold,
          ),
      ]);
}

/// Ikon metode pembayaran (generik, tanpa logo merek).
class PayLogo extends StatelessWidget {
  final PayMethod m;
  final double size;
  const PayLogo(this.m, {super.key, this.size = 44});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: m.color, borderRadius: BorderRadius.circular(size * .3)),
        child: Icon(m.icon, color: Colors.white, size: size * .58),
      );
}

Widget kv(String k, String v, {bool bold = false, Color? valueColor}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 2, child: Text(k, style: const TextStyle(color: kMuted))),
        Expanded(
          flex: 3,
          child: Text(v,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  fontSize: bold ? 16 : 14,
                  color: valueColor ?? kNavy)),
        ),
      ]),
    );

IconData vehicleIcon(VehicleType v) => switch (v) {
      VehicleType.motor => Icons.two_wheeler,
      VehicleType.mobil => Icons.directions_car_filled,
      VehicleType.suv => Icons.airport_shuttle,
    };

/// Gambar layanan kecil (dipakai di daftar pesanan dan kartu).
class ServiceThumb extends StatelessWidget {
  final WashPackage pack;
  final VehicleType vehicle;
  final double width;
  const ServiceThumb(this.pack, this.vehicle, {super.key, this.width = 84});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: width * .6,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kNavyLight, kNavySoft]),
        ),
        padding: const EdgeInsets.all(4),
        child: Image.asset(pack.imageFor(vehicle), fit: BoxFit.contain),
      );
}

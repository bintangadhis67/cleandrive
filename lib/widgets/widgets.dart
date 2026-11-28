import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';
import '../data/repository.dart';
import '../models/models.dart';
import 'motion.dart';

final fmtDateTime = DateFormat('d MMM yyyy, HH:mm', 'id_ID');
final fmtDate = DateFormat('d MMM yyyy', 'id_ID');
final fmtHm = DateFormat('HH:mm');

/// Warna status pengerjaan: menunggu, proses, finishing, selesai.
const kStatusColors = [kWarn, kRed, Color(0xFF3B5FB8), kGreen];

/// Pesan singkat (sukses / error) yang muncul di ATAS layar.
void toast(BuildContext c, String msg, {bool error = false}) {
  final accent = error ? kError : kGreen;
  showTopToast(
    c,
    title: msg,
    accent: accent,
    duration: Duration(seconds: error ? 4 : 3),
    leading: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withValues(alpha: .20)),
      child: Icon(error ? Icons.error_outline_rounded : Icons.check_circle_rounded, color: error ? const Color(0xFFFF8A90) : const Color(0xFF6FE0A6), size: 24),
    ),
  );
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

/// Kartu putih bergaya desain (radius 20, border tipis, bayangan lembut).
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
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: outlined ? Border.all(color: kLineSoft) : null,
        boxShadow: kShadowSoft,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(kRadiusCard),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    // Kartu yang bisa diklik menyusut sedikit saat ditekan.
    return onTap == null ? card : Pressable(scale: 0.98, child: card);
  }
}

/// Kartu navy bergradasi (layanan dan banner).
class NavyCard extends StatelessWidget {
  final Widget child;
  final double radius;
  const NavyCard({super.key, required this.child, this.radius = 30});

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
        Expanded(child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kNavy))),
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
  Widget build(BuildContext context) => Pressable(
        enabled: !busy && onPressed != null,
        scale: 0.97,
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: color ?? kRed),
            onPressed: busy ? null : onPressed,
            child: busy
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                    if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                    Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                  ]),
          ),
        ),
      );
}

/// Pil filter / kategori (Semua, Selesai, dst). Merah saat dipilih.
class FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  const FilterPill({super.key, required this.label, required this.selected, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 10),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? kRed : Colors.white,
              borderRadius: BorderRadius.circular(kRadiusChip),
              border: Border.all(color: selected ? kRed : kLine),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, size: 17, color: selected ? Colors.white : kNavy), const SizedBox(width: 6)],
              Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? Colors.white : kNavy)),
            ]),
          ),
        ),
      );
}

class StatusChip extends StatelessWidget {
  final Booking b;
  const StatusChip(this.b, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = b.cancelled ? kError : kStatusColors[b.status];
    final t = b.cancelled ? 'Dibatalkan' : b.statusLabel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: .14), borderRadius: BorderRadius.circular(20)),
      child: Text(t, style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 12)),
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
      _ => ('Belum dibayar', kWarn),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: .14), borderRadius: BorderRadius.circular(20)),
      child: Text(t, style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 12)),
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
    };

/// Gambar layanan kecil (dipakai di daftar pesanan dan kartu).
class ServiceThumb extends StatelessWidget {
  final WashPackage pack;
  final VehicleType vehicle;
  final double width;
  const ServiceThumb(this.pack, this.vehicle, {super.key, this.width = 84});

  @override
  Widget build(BuildContext context) {
    final h = width * .6;
    if (pack.isOil) {
      return Container(
        width: width,
        height: h,
        decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.all(4),
        child: Image.asset(pack.imageFor(vehicle), fit: BoxFit.contain, cacheWidth: 300),
      );
    }
    return Container(
      width: width,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kNavyLight, kNavySoft]),
      ),
      padding: const EdgeInsets.all(4),
      child: pack.isShop
          ? Icon(Icons.shopping_bag_rounded, color: kCream, size: h * .5)
          : Image.asset(pack.imageFor(vehicle), fit: BoxFit.contain),
    );
  }
}

// ---------------------------------------------------------------------------
// RESPONSIF: HP, tablet, laptop. Tata letak BOXED: isi dibatasi [kPageMax] dan rata tengah di layar lebar,
// sedangkan menu bawah dan latar tetap selebar layar.
// kPageMax = double.infinity: isi selalu memenuhi lebar layar (laptop 1280 x 720 maupun monitor lebar),
// jarak tepi 16 px. Di HP tampilan tidak berubah.
// ---------------------------------------------------------------------------

/// Di bawah ini = HP (menu bawah). Mulai dari ini = tablet/laptop (menu samping).
const kPhoneMax = 720.0;

/// Lebar layar mulai dari ini memakai tata letak kolom ganda.
const kWideBreakpoint = 900.0;

/// Lebar layar mulai dari ini dianggap monitor besar: menu samping diperluas dan kolom bertambah.
const kDesktopMin = 1200.0;

/// Lebar maksimum kotak isi. double.infinity = isi SELALU penuh selebar layar (HP, laptop, monitor besar).
/// Jika suatu saat ingin dibatasi lagi, ganti dengan angka, misalnya 1600.0.
const kPageMax = double.infinity;

bool isWide(BuildContext c) => MediaQuery.of(c).size.width >= kWideBreakpoint;
bool isPhone(BuildContext c) => MediaQuery.of(c).size.width < kPhoneMax;

/// Jarak tepi halaman. Isi penuh layar dengan jarak tepi tetap 16 px.
/// Jika kPageMax diberi angka, sisa lebar dibagi dua agar isi rata tengah.
double pagePad(double width) {
  const base = 16.0;
  final extra = kPageMax.isFinite ? (width - kPageMax) / 2 : 0.0;
  return extra > 0 ? base + extra : base;
}

/// Jumlah kolom. Selalu 1: semua daftar disusun ke bawah dan penuh selebar layar (tidak menyamping).
int colsFor(double width, {double minWidth = 340}) => 1;

/// Memusatkan isi dengan lebar maksimum (opsional). Bawaan: penuh.
class PageBox extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const PageBox({super.key, required this.child, this.maxWidth = kPageMax});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
      );
}

/// Daftar gulir selebar layar dengan jarak tepi responsif. Dipakai di semua halaman.
class PageList extends StatelessWidget {
  final List<Widget> children;
  final double top, bottom;
  final Future<void> Function()? onRefresh;
  const PageList({super.key, required this.children, this.top = 8, this.bottom = 24, this.onRefresh});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final p = pagePad(c.maxWidth);
        final list = ListView(padding: EdgeInsets.fromLTRB(p, top, p, bottom), children: children);
        if (onRefresh == null) return list;
        return RefreshIndicator(color: kRed, onRefresh: onRefresh!, child: list);
      });
}

/// Panel kiri lalu kanan disusun KE BAWAH (satu kolom penuh) di semua ukuran layar: HP, laptop, desktop.
/// Parameter flex, gap, dan breakpoint dipertahankan agar pemanggil lama tetap valid.
class TwoPane extends StatelessWidget {
  final List<Widget> left, right;
  final int leftFlex, rightFlex;
  final double gap;
  final double breakpoint;
  const TwoPane({
    super.key,
    required this.left,
    required this.right,
    this.leftFlex = 1,
    this.rightFlex = 1,
    this.gap = 20,
    this.breakpoint = kWideBreakpoint,
  });

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...left, ...right]);
}

/// Menyusun widget dalam beberapa kolom (tinggi tiap baris mengikuti isinya).
/// Dengan [cols] = 1 hasilnya sama seperti daftar biasa.
class ColumnsGrid extends StatelessWidget {
  final List<Widget> children;
  final int cols;
  final double gap;
  const ColumnsGrid({super.key, required this.children, required this.cols, this.gap = 14});

  @override
  Widget build(BuildContext context) {
    if (cols <= 1) {
      return Column(children: [
        for (final c in children) Padding(padding: EdgeInsets.only(bottom: gap), child: c),
      ]);
    }
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += cols) {
      rows.add(Padding(
        padding: EdgeInsets.only(bottom: gap),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var j = 0; j < cols; j++) ...[
            if (j > 0) SizedBox(width: gap),
            Expanded(child: i + j < children.length ? children[i + j] : const SizedBox.shrink()),
          ],
        ]),
      ));
    }
    return Column(children: rows);
  }
}

/// Grid kolom otomatis menurut lebar (dipakai LayoutBuilder di dalam).
class AutoGrid extends StatelessWidget {
  final List<Widget> children;
  final double minWidth;
  final double gap;
  const AutoGrid({super.key, required this.children, this.minWidth = 340, this.gap = 14});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) => ColumnsGrid(cols: colsFor(c.maxWidth, minWidth: minWidth), gap: gap, children: children),
      );
}

// ---------------------------------------------------------------------------
// STATE UMUM: skeleton loading, kosong, error
// ---------------------------------------------------------------------------

/// Kotak abu berdenyut sebagai pengganti konten yang sedang dimuat.
class Skeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;
  const Skeleton({super.key, this.width, this.height = 16, this.radius = 12});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(const Color(0xFFE4E8F0), const Color(0xFFF3F5F9), _c.value),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      );
}

/// Tampilan kosong (belum ada data).
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message = '',
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Panel(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: kBg, shape: BoxShape.circle),
              child: Icon(icon, size: 36, color: kMuted),
            ),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: kMuted, height: 1.4)),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 14),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 22)),
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ]),
        ),
      );
}

/// Tampilan error dengan tombol coba lagi.
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorState({super.key, this.message = 'Terjadi kesalahan. Coba lagi.', this.onRetry});

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Gagal memuat',
        message: message,
        actionLabel: onRetry == null ? null : 'Coba Lagi',
        onAction: onRetry,
      );
}


// ---------------------------------------------------------------------------
// MOTIF BERTEMA CUCI MOBIL (kartu Coins, Membership, dan Profil)
// Dibuat dengan kode (tanpa gambar): siluet mobil, busa, tetesan air, kilau, ban, tetes oli, dan jalan.
// ---------------------------------------------------------------------------
class _Ink {
  final Paint fill, glass, line, soft, drop, spark, bubble;
  _Ink(Color c)
      : fill = Paint()..color = c.withValues(alpha: .08),
        glass = Paint()..color = c.withValues(alpha: .14),
        line = Paint()
          ..color = c.withValues(alpha: .20)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round,
        soft = Paint()
          ..color = c.withValues(alpha: .13)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
        drop = Paint()..color = c.withValues(alpha: .24),
        spark = Paint()..color = c.withValues(alpha: .42),
        bubble = Paint()
          ..color = c.withValues(alpha: .28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3;
}

Path _dropPath(Offset c, double s) => Path()
  ..moveTo(c.dx, c.dy - s)
  ..cubicTo(c.dx + s * .9, c.dy - s * .1, c.dx + s * .7, c.dy + s * .9, c.dx, c.dy + s * .9)
  ..cubicTo(c.dx - s * .7, c.dy + s * .9, c.dx - s * .9, c.dy - s * .1, c.dx, c.dy - s)
  ..close();

Path _sparkPath(Offset c, double r) => Path()
  ..moveTo(c.dx, c.dy - r)
  ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
  ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
  ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
  ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
  ..close();

Path _starPath(Offset c, double r) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final a = -math.pi / 2 + i * math.pi / 5;
    final rr = i.isEven ? r : r * .45;
    final o = Offset(c.dx + math.cos(a) * rr, c.dy + math.sin(a) * rr);
    if (i == 0) {
      path.moveTo(o.dx, o.dy);
    } else {
      path.lineTo(o.dx, o.dy);
    }
  }
  path.close();
  return path;
}

Path _diamondPath(Offset c, double r) => Path()
  ..moveTo(c.dx, c.dy - r)
  ..lineTo(c.dx + r * .8, c.dy - r * .25)
  ..lineTo(c.dx, c.dy + r)
  ..lineTo(c.dx - r * .8, c.dy - r * .25)
  ..close();

void _dashed(Canvas canvas, Offset a, Offset b, Paint paint, {double dash = 10, double gap = 8}) {
  final dx = b.dx - a.dx, dy = b.dy - a.dy;
  final len = math.sqrt(dx * dx + dy * dy);
  if (len < 1) return;
  final ux = dx / len, uy = dy / len;
  var t = 0.0;
  while (t < len) {
    final e = t + dash > len ? len : t + dash;
    canvas.drawLine(Offset(a.dx + ux * t, a.dy + uy * t), Offset(a.dx + ux * e, a.dy + uy * e), paint);
    t += dash + gap;
  }
}

void _wheel(Canvas canvas, Offset c, double r, _Ink ink, {int spokes = 5, bool tread = false}) {
  canvas.drawCircle(c, r, ink.fill);
  canvas.drawCircle(c, r, ink.line);
  canvas.drawCircle(c, r * .72, ink.soft);
  canvas.drawCircle(c, r * .26, ink.line);
  for (var i = 0; i < spokes; i++) {
    final a = i * 2 * math.pi / spokes;
    canvas.drawLine(
      Offset(c.dx + math.cos(a) * r * .30, c.dy + math.sin(a) * r * .30),
      Offset(c.dx + math.cos(a) * r * .70, c.dy + math.sin(a) * r * .70),
      ink.soft,
    );
  }
  if (tread) {
    for (var i = 0; i < 28; i++) {
      final a = i * 2 * math.pi / 28;
      canvas.drawLine(
        Offset(c.dx + math.cos(a) * r * .88, c.dy + math.sin(a) * r * .88),
        Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r),
        ink.line,
      );
    }
  }
}

/// Siluet mobil (tampak samping) dalam kotak satuan 0..1; [p] memetakan (u, v) ke posisi layar.
void _car(Canvas canvas, Offset Function(double, double) p, double cH, _Ink ink) {
  final body = Path();
  void mv(double u, double v) {
    final o = p(u, v);
    body.moveTo(o.dx, o.dy);
  }

  void ln(double u, double v) {
    final o = p(u, v);
    body.lineTo(o.dx, o.dy);
  }

  void qd(double cu, double cv, double u, double v) {
    final c = p(cu, cv), o = p(u, v);
    body.quadraticBezierTo(c.dx, c.dy, o.dx, o.dy);
  }

  Path poly(List<List<double>> pts) {
    final path = Path();
    for (var i = 0; i < pts.length; i++) {
      final o = p(pts[i][0], pts[i][1]);
      if (i == 0) {
        path.moveTo(o.dx, o.dy);
      } else {
        path.lineTo(o.dx, o.dy);
      }
    }
    path.close();
    return path;
  }

  mv(.03, .66);
  ln(.03, .52);
  qd(.03, .46, .10, .44);
  ln(.26, .40);
  qd(.34, .14, .50, .12);
  ln(.66, .12);
  qd(.80, .14, .88, .40);
  ln(.95, .44);
  qd(.98, .48, .98, .56);
  ln(.98, .66);
  body.close();
  canvas.drawPath(body, ink.fill);

  final front = poly(const [[.30, .40], [.37, .22], [.47, .17], [.47, .40]]);
  final rear = poly(const [[.53, .40], [.53, .17], [.64, .17], [.76, .25], [.82, .40]]);
  canvas.drawPath(front, ink.glass);
  canvas.drawPath(rear, ink.glass);
  canvas.drawPath(body, ink.line);
  canvas.drawLine(p(.50, .16), p(.50, .46), ink.soft);
  canvas.drawLine(p(.56, .30), p(.62, .30), ink.line);
  canvas.drawLine(p(.05, .60), p(.97, .60), ink.soft);
  canvas.drawOval(Rect.fromPoints(p(.92, .47), p(.985, .54)), ink.spark);
  canvas.drawOval(Rect.fromPoints(p(.03, .50), p(.065, .56)), ink.drop);

  final r = cH * .17;
  _wheel(canvas, p(.24, .68), r, ink);
  _wheel(canvas, p(.76, .68), r, ink);
}

void _foam(Canvas canvas, Offset Function(double, double) p, _Ink ink, double k) {
  const bubbles = [
    [.46, -.04, 7.0],
    [.56, -.16, 9.0],
    [.67, -.06, 6.0],
    [.38, .03, 4.5],
    [.76, .07, 4.5],
    [.52, -.32, 4.0],
    [.63, -.30, 5.5],
    [.30, .11, 3.5],
    [.84, -.12, 3.5],
  ];
  for (final b in bubbles) {
    final c = p(b[0], b[1]);
    final r = b[2] * k;
    canvas.drawCircle(c, r, ink.bubble);
    canvas.drawCircle(Offset(c.dx - r * .3, c.dy - r * .3), r * .2, ink.spark);
  }
}

void _dropsAndSparks(Canvas canvas, Offset Function(double, double) p, _Ink ink, double k) {
  const drops = [
    [-.30, -.40, 5.0],
    [.05, -.62, 6.0],
    [.30, -.78, 5.0],
    [.58, -.70, 6.5],
    [.82, -.50, 5.0],
    [1.02, -.80, 5.5],
    [1.12, -.30, 4.5],
    [-.10, -.15, 4.5],
  ];
  for (final d in drops) {
    canvas.drawPath(_dropPath(p(d[0], d[1]), d[2] * k), ink.drop);
  }
  const sparks = [
    [.20, -.55, 8.0],
    [.78, -.80, 7.0],
    [1.05, -.52, 6.0],
    [-.22, -.78, 5.0],
    [.50, -.58, 4.5],
  ];
  for (final s in sparks) {
    canvas.drawPath(_sparkPath(p(s[0], s[1]), s[2] * k), ink.spark);
  }
}

/// Motif untuk kartu Coins dan Membership. [theme]: 0 umum, 1 koin (Coins), 2 permata dan bintang (Membership).
/// [flip] = true memindahkan motif ke sisi kiri (mobil menghadap kiri). [car] = false menyembunyikan mobil.
class MotifPainter extends CustomPainter {
  final Color color;
  final bool flip;
  final bool car;
  final int theme;
  const MotifPainter(this.color, {this.flip = false, this.car = true, this.theme = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (w < 90 || h < 60) return;
    canvas.clipRect(Offset.zero & size);
    final ink = _Ink(color);
    final dense = w >= 260;

    var cH = h * .34;
    if (cH > 86) cH = 86;
    var cW = cH / .38;
    final maxW = w < 500 ? w * .34 : w * .40;
    if (cW > maxW) {
      cW = maxW;
      cH = cW * .38;
    }
    final y0 = h * .12 + cH * .65;
    final x0 = flip ? w * .05 : w - cW - w * .05;
    Offset p(double u, double v) {
      final uu = flip ? 1 - u : u;
      return Offset(x0 + uu * cW, y0 + v * cH);
    }

    // Tetesan air dan kilau (selalu), lalu gelombang.
    _dropsAndSparks(canvas, p, ink, 1);
    final wave = Path()
      ..moveTo(p(-.12, 1.02).dx, p(-.12, 1.02).dy)
      ..quadraticBezierTo(p(.5, 1.30).dx, p(.5, 1.30).dy, p(1.08, .86).dx, p(1.08, .86).dy);
    canvas.drawPath(wave, ink.soft);
    if (!dense) return;

    // Garis diagonal tipis di sudut.
    final stripe = Paint()
      ..color = color.withValues(alpha: .04)
      ..strokeWidth = 10;
    for (var i = 0; i < 3; i++) {
      final xa = w * (.90 + i * .045), xb = w * (.80 + i * .045);
      canvas.drawLine(Offset(flip ? w - xa : xa, 0), Offset(flip ? w - xb : xb, h * .6), stripe);
    }

    // Jalan putus-putus dan gelombang kedua.
    _dashed(canvas, p(-.60, 1.10), p(1.20, 1.10), ink.soft, dash: 10, gap: 8);
    final wave2 = Path()
      ..moveTo(p(-.20, 1.16).dx, p(-.20, 1.16).dy)
      ..quadraticBezierTo(p(.5, 1.40).dx, p(.5, 1.40).dy, p(1.15, .96).dx, p(1.15, .96).dy);
    canvas.drawPath(wave2, ink.line);

    // Garis kecepatan di belakang mobil.
    const lens = [.46, .34, .24, .16];
    const ys = [.30, .44, .58, .72];
    for (var i = 0; i < 4; i++) {
      canvas.drawLine(p(-.12 - lens[i], ys[i]), p(-.12, ys[i]), ink.soft);
    }

    if (car) {
      _car(canvas, p, cH, ink);
      _foam(canvas, p, ink, 1);
    }

    // Hiasan sesuai tema.
    if (theme == 1) {
      const coins = [
        [-.42, -.58, 11.0],
        [1.14, -.62, 9.0],
        [-.05, -.92, 7.0],
      ];
      for (final c in coins) {
        final o = p(c[0], c[1]);
        final r = c[2];
        canvas.drawCircle(o, r, ink.fill);
        canvas.drawCircle(o, r, ink.line);
        canvas.drawCircle(o, r * .68, ink.soft);
        canvas.drawLine(Offset(o.dx, o.dy - r * .38), Offset(o.dx, o.dy + r * .38), ink.line);
      }
    } else if (theme == 2) {
      const gems = [
        [-.40, -.55, 10.0],
        [1.12, -.60, 8.0],
      ];
      for (final g in gems) {
        final path = _diamondPath(p(g[0], g[1]), g[2]);
        canvas.drawPath(path, ink.glass);
        canvas.drawPath(path, ink.line);
      }
      const stars = [
        [.15, -.92, 8.0],
        [.92, -.95, 6.0],
      ];
      for (final s in stars) {
        final path = _starPath(p(s[0], s[1]), s[2]);
        canvas.drawPath(path, ink.glass);
        canvas.drawPath(path, ink.line);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MotifPainter old) =>
      old.color != color || old.flip != flip || old.car != car || old.theme != theme;
}

/// Motif kartu Profil: pemandangan lebih lengkap. Kanan: mobil berbusa dengan tetesan dan kilau.
/// Kiri: ban, tetes oli, busa, dan semprotan air. Bawah: jalan putus-putus dan gelombang berwarna [accent].
class ProfileMotifPainter extends CustomPainter {
  final Color color;
  final Color accent;
  const ProfileMotifPainter(this.color, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (w < 120 || h < 80) return;
    canvas.clipRect(Offset.zero & size);
    final ink = _Ink(color);
    final warm = _Ink(accent);

    // Jalan dan gelombang di bagian bawah (lebar penuh).
    _dashed(canvas, Offset(w * .02, h * .94), Offset(w * .98, h * .94), ink.soft, dash: 16, gap: 12);
    final wave = Path()
      ..moveTo(0, h * .86)
      ..cubicTo(w * .25, h * .99, w * .55, h * .74, w, h * .90);
    canvas.drawPath(
      wave,
      Paint()
        ..color = accent.withValues(alpha: .38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(wave.shift(const Offset(0, 8)), ink.soft);

    // Layar sempit (HP): hiasan ringan saja.
    if (w < 600) {
      final s = w / 400;
      for (final d in const [
        [.08, .18, 5.0],
        [.90, .22, 5.0],
        [.16, .42, 4.0],
        [.84, .46, 4.0],
      ]) {
        canvas.drawPath(_dropPath(Offset(w * d[0], h * d[1]), d[2] * s), ink.drop);
      }
      for (final d in const [
        [.12, .12, 7.0],
        [.88, .14, 7.0],
        [.92, .62, 5.0],
        [.07, .60, 5.0],
      ]) {
        canvas.drawPath(_sparkPath(Offset(w * d[0], h * d[1]), d[2] * s), ink.spark);
      }
      return;
    }

    // ---- Kanan: mobil menghadap kiri ----
    var cH = h * .40;
    if (cH > 130) cH = 130;
    var cW = cH / .38;
    if (cW > w * .30) {
      cW = w * .30;
      cH = cW * .38;
    }
    final rx0 = w - cW - w * .06;
    final ry0 = h * .36;
    Offset rp(double u, double v) => Offset(rx0 + (1 - u) * cW, ry0 + v * cH);
    _dropsAndSparks(canvas, rp, ink, 1.2);
    const lens = [.50, .36, .26, .16];
    const ys = [.30, .44, .58, .72];
    for (var i = 0; i < 4; i++) {
      canvas.drawLine(rp(-.12 - lens[i], ys[i]), rp(-.12, ys[i]), ink.soft);
    }
    _car(canvas, rp, cH, ink);
    _foam(canvas, rp, ink, 1.3);

    // ---- Kiri: ban besar, tetes oli, busa, semprotan ----
    var tr = h * .30;
    if (tr > 96) tr = 96;
    final tc = Offset(w * .085, h * .66);
    final k = tr / 96;
    _wheel(canvas, tc, tr, ink, spokes: 6, tread: true);
    canvas.drawCircle(tc, tr * .55, ink.soft);

    final oil = _dropPath(Offset(w * .20, h * .30), 24 * k + 8);
    canvas.drawPath(oil, Paint()..color = accent.withValues(alpha: .30));
    canvas.drawPath(
      oil,
      Paint()
        ..color = accent.withValues(alpha: .50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    canvas.drawCircle(Offset(w * .20 - 7 * k, h * .30 + 2 * k), 3.2 * k + 1, ink.spark);

    const foam = [
      [.95, -1.15, 9.0],
      [1.25, -.85, 6.0],
      [1.15, -1.45, 5.0],
      [1.60, -1.05, 7.0],
      [.65, -1.50, 4.0],
      [1.90, -1.45, 4.5],
    ];
    for (final b in foam) {
      final c = Offset(tc.dx + b[0] * tr, tc.dy + b[1] * tr);
      final r = b[2] * (k + .3);
      canvas.drawCircle(c, r, ink.bubble);
      canvas.drawCircle(Offset(c.dx - r * .3, c.dy - r * .3), r * .2, ink.spark);
    }

    // Semprotan air dari sudut kiri atas.
    for (var i = 0; i <= 9; i++) {
      final t = i / 9;
      final c = Offset(w * (.04 + .22 * t), h * (.08 + .26 * t * t + .06 * t));
      canvas.drawPath(_dropPath(c, 3.0 + (1 - t) * 3.5), ink.drop);
    }
    for (final s in const [
      [.27, .60, 8.0],
      [.14, .20, 6.0],
      [.33, .20, 5.0],
      [.40, .46, 4.5],
    ]) {
      canvas.drawPath(_sparkPath(Offset(w * s[0], h * s[1]), s[2]), warm.spark);
    }
  }

  @override
  bool shouldRepaint(covariant ProfileMotifPainter old) => old.color != color || old.accent != accent;
}


// ---------------------------------------------------------------------------
// POPUP DI ATAS LAYAR (turun dari atas, bilah waktu, hilang otomatis; ketuk untuk membuka / geser untuk menutup)
// ---------------------------------------------------------------------------
void showTopToast(
  BuildContext context, {
  required String title,
  String subtitle = '',
  Widget? leading,
  Color accent = kGold,
  Duration duration = const Duration(seconds: 3),
  String? actionLabel,
  VoidCallback? onTap,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _currentToast?.remove(); // satu popup pada satu waktu
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _TopToast(
      title: title,
      subtitle: subtitle,
      leading: leading,
      accent: accent,
      duration: duration,
      actionLabel: actionLabel,
      onTap: onTap,
      onDone: () {
        if (_currentToast == entry) _currentToast = null;
        entry.remove();
      },
    ),
  );
  _currentToast = entry;
  overlay.insert(entry);
}

OverlayEntry? _currentToast;

class _TopToast extends StatefulWidget {
  final String title, subtitle;
  final Widget? leading;
  final Color accent;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onTap;
  final VoidCallback onDone;
  const _TopToast({
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.accent,
    required this.duration,
    required this.actionLabel,
    required this.onTap,
    required this.onDone,
  });
  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _c.forward();
    Future.delayed(widget.duration, _close);
  }

  Future<void> _close() async {
    if (_closing || !mounted) return;
    _closing = true;
    await _c.reverse();
    widget.onDone();
  }

  void _tap() {
    final cb = widget.onTap;
    _close();
    cb?.call();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = pagePad(MediaQuery.sizeOf(context).width);
    final accent = widget.accent;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(pad, 10, pad, 0),
          child: SlideTransition(
            position: Tween(begin: const Offset(0, -1.5), end: Offset.zero)
                .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn)),
            child: FadeTransition(
              opacity: _c,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: widget.onTap == null ? _close : _tap,
                  onVerticalDragEnd: (_) => _close(),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kNavyLight, kNavyDark]),
                      border: Border.all(color: accent.withValues(alpha: .5), width: 1.3),
                      boxShadow: [
                        BoxShadow(color: accent.withValues(alpha: .26), blurRadius: 24, offset: const Offset(0, 8)),
                        const BoxShadow(color: Color(0x3310264C), blurRadius: 22, offset: Offset(0, 12)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Stack(children: [
                        Positioned.fill(child: CustomPaint(painter: MotifPainter(accent))),
                        Column(mainAxisSize: MainAxisSize.min, children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
                            child: Row(children: [
                              if (widget.leading != null) ...[widget.leading!, const SizedBox(width: 12)],
                              Expanded(
                                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(widget.title,
                                      maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14.5)),
                                  if (widget.subtitle.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 3),
                                      child: Text(widget.subtitle,
                                          maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xCCF7F1E7), fontSize: 12.5, height: 1.3)),
                                    ),
                                ]),
                              ),
                              if (widget.actionLabel != null)
                                Container(
                                  margin: const EdgeInsets.only(left: 10),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(20)),
                                  child: Text(widget.actionLabel!, style: const TextStyle(color: kNavy, fontWeight: FontWeight.w800, fontSize: 12.5)),
                                ),
                            ]),
                          ),
                          // bilah waktu yang menyusut
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 1, end: 0),
                            duration: widget.duration,
                            builder: (_, v, __) => Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: v,
                                child: Container(height: 3, color: accent.withValues(alpha: .85)),
                              ),
                            ),
                          ),
                        ]),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
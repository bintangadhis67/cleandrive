import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'data/repository.dart';
import 'models.dart';
import 'theme.dart';

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
  Widget build(BuildContext context) => Container(
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
  Widget build(BuildContext context) => SizedBox(
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
      VehicleType.suv => Icons.airport_shuttle,
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
// ---------------------------------------------------------------------------

/// Di bawah ini = HP (menu bawah). Mulai dari ini = tablet/laptop (menu samping).
const kPhoneMax = 720.0;

/// Lebar layar mulai dari ini memakai tata letak kolom ganda.
const kWideBreakpoint = 900.0;

/// Lebar layar mulai dari ini dianggap monitor besar: menu samping diperluas dan kolom bertambah.
const kDesktopMin = 1200.0;

/// Lebar maksimum kotak isi (Boxed Layout). Ubah angka ini untuk melebarkan / menyempitkan tampilan.
const kPageMax = 800.0;

bool isWide(BuildContext c) => MediaQuery.of(c).size.width >= kWideBreakpoint;
bool isPhone(BuildContext c) => MediaQuery.of(c).size.width < kPhoneMax;

/// Jarak tepi halaman menurut lebar yang tersedia. Di layar lebar, jarak ini sekaligus
/// memusatkan isi dengan lebar [kPageMax].
double pagePad(double width) {
  const base = 16.0;
  final extra = (width - kPageMax) / 2; // sisa kiri-kanan agar isi rata tengah
  return extra > 0 ? base + extra : base;
}

/// Jumlah kolom menurut lebar yang tersedia (minimal 1, maksimal 4).
int colsFor(double width, {double minWidth = 340}) {
  final n = (width / minWidth).floor();
  return n < 1 ? 1 : (n > 4 ? 4 : n);
}

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

/// Dua panel berdampingan di layar lebar, bertumpuk di HP.
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
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        if (c.maxWidth >= breakpoint) {
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: leftFlex, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: left)),
            SizedBox(width: gap),
            Expanded(flex: rightFlex, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: right)),
          ]);
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...left, ...right]);
      });
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


/// Motif dekoratif (lingkaran, cincin, titik, dan garis kecepatan) untuk mengisi area kartu yang kosong.
/// [flip] = true menaruh motif di sisi kiri.
class MotifPainter extends CustomPainter {
  final Color color;
  final bool flip;
  const MotifPainter(this.color, {this.flip = false});

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = color.withValues(alpha: .08);
    final ring = Paint()
      ..color = color.withValues(alpha: .16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final dot = Paint()..color = color.withValues(alpha: .35);
    final sgn = flip ? 1.0 : -1.0;
    final x = flip ? 0.0 : size.width;
    final r = size.shortestSide;
    canvas.drawCircle(Offset(x, size.height * .12), r * .62, fill);
    canvas.drawCircle(Offset(x, size.height * .12), r * .42, ring);
    canvas.drawCircle(Offset(x + sgn * size.width * .10, size.height * .98), r * .30, fill);
    for (var i = 0; i < 3; i++) {
      final y = size.height * (.52 + i * .11);
      final x0 = x + sgn * size.width * (.06 + i * .04);
      canvas.drawLine(Offset(x0, y), Offset(x0 + sgn * size.width * (.24 - i * .05), y - 10), ring..strokeCap = StrokeCap.round);
    }
    canvas.drawCircle(Offset(x + sgn * size.width * .30, size.height * .22), 2.6, dot);
    canvas.drawCircle(Offset(x + sgn * size.width * .18, size.height * .40), 2, dot);
    canvas.drawCircle(Offset(x + sgn * size.width * .42, size.height * .36), 1.8, dot);
  }

  @override
  bool shouldRepaint(covariant MotifPainter old) => old.color != color || old.flip != flip;
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
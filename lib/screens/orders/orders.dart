import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/motion.dart';
import '../../widgets/widgets.dart';
import '../outlet/outlet.dart';
import '../payment/payment.dart';
import '../rewards/reward_ui.dart';
import '../shop/shop.dart' show ProductImage;
import 'order_ui.dart';

// ---------- RIWAYAT PESANAN (tema Navy: header gradasi + filter kapsul + kartu ringkas) ----------
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

// Lencana status kecil. Status pesanan dan status pembayaran adalah dua informasi berbeda.
class _Badge extends StatelessWidget {
  final String text;
  final Color bg, fg;
  const _Badge(this.text, this.bg, this.fg);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 11.5)),
      );
}

/// Status PESANAN: Menunggu (kuning), Diproses (biru), Selesai (hijau), Dibatalkan (merah).
_Badge _orderBadge(Booking b) {
  if (b.cancelled) return const _Badge('Dibatalkan', Color(0xFFFDE3E5), kRwDanger);
  switch (b.status) {
    case 0:
      return const _Badge('Menunggu', kRwGoldLight, kRwGoldDark);
    case 3:
      return const _Badge('Selesai', Color(0xFFDDF3E8), Color(0xFF148A57));
    default:
      return const _Badge('Diproses', kRwBlueSoft, kRwNavy);
  }
}

/// Status PEMBAYARAN: Lunas (hijau), Belum Lunas (merah muda), Dikembalikan (abu biru).
_Badge _payBadge(Booking b) {
  switch (b.payStatus) {
    case 'paid':
      return const _Badge('Lunas', Color(0xFFDDF3E8), Color(0xFF148A57));
    case 'refunded':
      return const _Badge('Dikembalikan', Color(0xFFEAEFF9), kRwSub);
    default:
      return const _Badge('Belum Lunas', Color(0xFFFDE3E5), kRwDanger);
  }
}

/// Gambar kecil di kiri kartu riwayat (juga dipakai di Riwayat Transaksi):
/// - Pembelian toko: foto produk yang dibeli (badge "+N" bila lebih dari satu jenis produk).
/// - Cuci / ganti oli: gambar layanan sesuai jenis kendaraan.
class OrderThumb extends StatelessWidget {
  final Booking b;
  final double size;
  const OrderThumb(this.b, {this.size = 68});

  @override
  Widget build(BuildContext context) {
    final shop = b.pack.isShop;
    final first = shop && b.items.isNotEmpty ? b.items.first.product : null;
    final more = shop ? b.items.length - 1 : 0;
    final Widget inner;
    BoxDecoration deco;
    if (first != null) {
      deco = BoxDecoration(color: kRwBlueSoft.withValues(alpha: .6), borderRadius: BorderRadius.circular(16));
      inner = Padding(padding: const EdgeInsets.all(6), child: ProductImage(first, height: size - 12));
    } else if (shop) {
      deco = BoxDecoration(color: kRwBlueSoft.withValues(alpha: .6), borderRadius: BorderRadius.circular(16));
      inner = Icon(Icons.shopping_bag_rounded, color: kRwNavy, size: size * .5);
    } else if (b.pack.isOil) {
      deco = BoxDecoration(color: kRwBlueSoft.withValues(alpha: .6), borderRadius: BorderRadius.circular(16));
      inner = Padding(padding: const EdgeInsets.all(5), child: Image.asset(b.pack.imageFor(b.vehicle), fit: BoxFit.contain, cacheWidth: 300));
    } else {
      deco = const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kRwNavyLight, kRwNavy]),
      );
      inner = Padding(padding: const EdgeInsets.all(5), child: Image.asset(b.pack.imageFor(b.vehicle), fit: BoxFit.contain));
    }
    return SizedBox(
      width: size,
      height: size,
      child: Stack(children: [
        Container(width: size, height: size, decoration: deco, child: Center(child: inner)),
        if (more > 0)
          Positioned(
            right: 3,
            bottom: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: kRwNavy, borderRadius: BorderRadius.circular(10)),
              child: Text('+$more', style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800)),
            ),
          ),
      ]),
    );
  }
}

class _OrdersScreenState extends State<OrdersScreen> {
  int _filter = 0; // 0 semua, 1 menunggu, 2 diproses, 3 selesai, 4 dibatalkan, 5 ulasan
  int _dir = 1; // arah geser terakhir: 1 = ke filter di kanan, -1 = ke kiri
  int _gen = 0; // naik tiap ganti filter, supaya daftar masuk ulang dengan animasi
  final Object _token = Object(); // pembeda tiap kali layar Riwayat dibuka
  static const _labels = ['Semua', 'Menunggu', 'Diproses', 'Selesai', 'Dibatalkan', 'Ulasan'];

  /// Pil filter di atas header gradasi: aktif = merah + teks putih, tidak aktif = transparan + garis putih.
  Widget _pill(int i) {
    final sel = _filter == i;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          if (_filter == i) return;
          setState(() {
            _dir = i > _filter ? 1 : -1;
            _gen++;
            _filter = i;
          });
        },
        // Menyusut saat ditekan + berdenyut kecil saat terpilih.
        child: Pressable(
          scale: 0.94,
          child: Pop(
            trigger: sel,
            enabled: sel,
            amount: 1.08,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: sel ? kRed : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: sel ? kRed : Colors.white.withValues(alpha: .75), width: 1.3),
                boxShadow: sel ? const [BoxShadow(color: Color(0x55C62026), blurRadius: 10, offset: Offset(0, 4))] : null,
              ),
              child: Text(_labels[i],
                  style: TextStyle(fontWeight: sel ? FontWeight.w800 : FontWeight.w600, fontSize: 13, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, double side) {
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
          // dekorasi gelombang abstrak transparan
          const Positioned.fill(child: CustomPaint(painter: _HeaderWavePainter())),
          Padding(
            padding: EdgeInsets.fromLTRB(0, top + 18, 0, 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: side),
                child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Riwayat', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -.3)),
                  SizedBox(height: 3),
                  Text('Semua pesanan cuci, ganti oli, pembelian toko, dan ulasanmu ada di sini.',
                      style: TextStyle(color: Colors.white, fontSize: 13.5, height: 1.35)),
                ]),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: side),
                child: Row(children: [for (var i = 0; i < _labels.length; i++) _pill(i)]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  /// Dasar kartu: putih, sudut 20, bayangan lembut, bisa diketuk.
  Widget _shell(VoidCallback onTap, Widget child) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: kRwShadowThin,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(padding: const EdgeInsets.all(14), child: child),
          ),
        ),
      );

  void _openDetail(BuildContext context, Booking b) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(id: b.id)));

  /// Kartu ringkas: info pesanan di kiri, status pesanan (atas) dan status pembayaran (bawah) di kanan.
  Widget _card(BuildContext context, Booking b) {
    final canReview = b.status == 3 && !b.cancelled && !b.pack.isShop;
    return _shell(
      () => _openDetail(context, b),
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Align(alignment: Alignment.center, child: OrderThumb(b)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(b.code, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: kRwText)),
              const SizedBox(height: 3),
              Text(b.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: kRwText)),
              const SizedBox(height: 2),
              Text(fmtDateTime.format(b.slot), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: kRwSub)),
              const SizedBox(height: 6),
              Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, children: [
                Text(rp(b.total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: kRwNavy)),
                if (b.review != null)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star_rounded, color: kRwGold, size: 17),
                    const SizedBox(width: 2),
                    Text('${b.review!.rating}.0', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: kRwText)),
                  ])
                else if (canReview)
                  const Text('Beri ulasan', style: TextStyle(color: kRed, fontWeight: FontWeight.w800, fontSize: 12.5)),
              ]),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _orderBadge(b),
            const SizedBox(height: 14),
            _payBadge(b),
          ]),
        ]),
      ),
    );
  }

  /// Kartu pada filter "Ulasan": pesanan selesai (cuci / ganti oli) beserta rating-nya,
  /// atau tombol "Beri ulasan" bila belum dinilai.
  Widget _reviewCard(BuildContext context, Booking b) => _shell(
        () => _openDetail(context, b),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            OrderThumb(b, size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b.code, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: kRwText)),
                const SizedBox(height: 3),
                Text(b.subtitle, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: kRwText)),
                const SizedBox(height: 2),
                Text(fmtDateTime.format(b.slot), style: const TextStyle(fontSize: 11.5, color: kRwSub)),
              ]),
            ),
            _orderBadge(b),
          ]),
          const SizedBox(height: 12),
          if (b.review != null) ...[
            Row(children: [
              StarRow(b.review!.rating.toDouble(), size: 20),
              const SizedBox(width: 8),
              Text(satisfactionLabel(b.review!.rating), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: kRwText)),
            ]),
            if (b.review!.comment.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(b.review!.comment, style: const TextStyle(fontSize: 13.5, height: 1.4, color: kRwText)),
            ],
          ] else
            RedButton('Beri Rating & Ulasan',
                icon: Icons.star_rounded,
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen(bookingId: b.id)))),
        ]),
      );

  /// Tampilan kosong: ikon, judul, keterangan, dan tombol Booking Sekarang (merah).
  Widget _empty() {
    final isReview = _filter == 5;
    final title = _filter == 0
        ? 'Belum ada riwayat pesanan'
        : (isReview ? 'Belum ada ulasan' : 'Tidak ada pesanan ${_labels[_filter].toLowerCase()}');
    final message = isReview
        ? 'Selesaikan pesanan cuci atau ganti oli, lalu beri rating di sini.'
        : 'Riwayat transaksi Anda akan muncul di sini';
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 48, 8, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: kRwShadowThin,
            border: Border.all(color: kRwNavy.withValues(alpha: .10), width: 8),
          ),
          child: Icon(isReview ? Icons.star_outline_rounded : Icons.receipt_long_rounded, size: 46, color: kRwNavy),
        ),
        const SizedBox(height: 20),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kRwText)),
        const SizedBox(height: 6),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, color: kRwSub, height: 1.4)),
        if (_filter == 0) ...[
          const SizedBox(height: 22),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: kRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              onPressed: () => app.requestTab(2),
              icon: const Icon(Icons.event_available_rounded, size: 20),
              label: const Text('Booking Sekarang'),
            ),
          ),
        ],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        // ikon status bar putih karena header berwarna gelap
        value: SystemUiOverlayStyle.light,
        child: ListenableBuilder(
          listenable: app,
          builder: (context, _) {
            // Data diambil dari app.bookings (pesanan milik pengguna yang sedang login) dan ikut berubah saat ada pembaruan.
            final all = app.bookings;
            final list = switch (_filter) {
              1 => all.where((b) => !b.cancelled && b.status == 0).toList(),
              2 => all.where((b) => !b.cancelled && (b.status == 1 || b.status == 2)).toList(),
              3 => all.where((b) => b.status == 3 && !b.cancelled).toList(),
              4 => all.where((b) => b.cancelled).toList(),
              // Ulasan: pesanan cuci/oli yang sudah selesai (belum diulas tampil paling atas).
              5 => (all.where((b) => b.status == 3 && !b.cancelled && !b.pack.isShop).toList()
                ..sort((a, b) {
                  final ra = a.review == null ? 0 : 1, rb = b.review == null ? 0 : 1;
                  return ra != rb ? ra - rb : b.slot.compareTo(a.slot);
                })),
              _ => all,
            };
            return ColoredBox(
              color: kRwBg,
              child: RefreshIndicator(
                color: kRwNavy,
                edgeOffset: MediaQuery.paddingOf(context).top,
                onRefresh: () async {
                  try {
                    await app.refreshAll();
                  } catch (_) {}
                },
                child: LayoutBuilder(builder: (context, cons) {
                  final side = pagePad(cons.maxWidth);
                  return CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _header(context, side)),
                      if (list.isEmpty)
                        SliverToBoxAdapter(
                          child: FadeSlideIn(
                            playOnce: (_token, _gen, 'kosong'),
                            dx: 28.0 * _dir,
                            dy: 0,
                            child: Padding(padding: EdgeInsets.symmetric(horizontal: side), child: _empty()),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(side, 16, side, 28),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              // Item masuk bertahap dari arah geser filter (maks. 8 item pertama), sekali per ganti filter.
                              (context, i) => FadeSlideIn(
                                playOnce: (_token, _gen, list[i].id),
                                delay: Duration(milliseconds: 50 * (i < 8 ? i : 8)),
                                duration: const Duration(milliseconds: 380),
                                dx: 28.0 * _dir,
                                dy: 0,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _filter == 5 ? _reviewCard(context, list[i]) : _card(context, list[i]),
                                ),
                              ),
                              childCount: list.length,
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ),
            );
          },
        ),
      );
}

/// Gelombang transparan lembut di header (kanan atas, kanan bawah, dan aksen gold).
class _HeaderWavePainter extends CustomPainter {
  const _HeaderWavePainter();

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

// ---------- DETAIL PESANAN: TIKET QR + TRACKING (redesign tema Navy) ----------
class DetailScreen extends StatefulWidget {
  final String id;
  const DetailScreen({super.key, required this.id});
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    app.refreshBooking(widget.id);
    // "Real-time" lewat polling tiap 5 detik selama pesanan masih aktif.
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      final b = app.byId(widget.id);
      if (b != null && b.active) app.refreshBooking(widget.id);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _pdf(Booking b) async {
    final doc = pw.Document();
    doc.addPage(pw.Page(
      build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('CleanDrive - Bukti Transaksi', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        pw.Divider(),
        pw.Text('Kode: ${b.code}'),
        pw.Text('Pemilik: ${b.owner}'),
        if (!b.pack.isShop) pw.Text('Kendaraan: ${b.vehicle.label} (${b.plate})'),
        pw.Text('Layanan: ${b.pack.title}'),
        pw.Text('${b.pack.isShop ? 'Waktu pesan' : 'Jadwal'}: ${fmtDateTime.format(b.slot)}'),
        if (!b.pack.isShop) pw.Text('Estimasi selesai: ${fmtDateTime.format(b.estFinish)}'),
        pw.Text('Status: ${b.cancelled ? 'Dibatalkan' : b.statusLabel}'),
        pw.SizedBox(height: 8),
        for (final l in b.items) pw.Text('${l.product.name} x${l.qty}: ${rp(l.subtotal)}'),
        pw.Text('Subtotal: ${rp(b.price)}'),
        if (b.discount > 0) pw.Text('Voucher ${b.voucherCode}: - ${rp(b.discount)}'),
        if (b.memberDiscount > 0) pw.Text('Diskon Membership ${b.memberLabel ?? ''}: - ${rp(b.memberDiscount)}'),
                    if (b.coinDiscount > 0) pw.Text('Tukar ${b.coinsUsed} Coins: - ${rp(b.coinDiscount)}'),
        pw.Text('Total: ${rp(b.total)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text(b.paid ? (b.freeWash ? 'Pembayaran: Cuci gratis membership (${b.trx ?? '-'})' : 'Pembayaran: ${b.payMethod?.label ?? '-'} (${b.trx ?? '-'}) - Lunas') : 'Pembayaran: Belum dibayar'),
        pw.SizedBox(height: 12),
        pw.BarcodeWidget(data: b.code, barcode: pw.Barcode.qrCode(), width: 100, height: 100),
      ]),
    ));
    await Printing.layoutPdf(onLayout: (_) => doc.save(), name: 'bukti-${b.id}.pdf');
  }

  DateTime _stageTime(Booking b, int i) {
    const f = [0.0, .3, .8, 1.0];
    // Bila pesanan selesai sebelum jam slot, jangan hitung mundur (jam tahap tidak boleh menurun).
    final total = b.estFinish.isAfter(b.slot) ? b.estFinish.difference(b.slot).inMinutes : 0;
    return b.slot.add(Duration(minutes: (total * f[i]).round()));
  }

  Future<void> _cancel(Booking b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan pesanan?'),
        content: Text(b.freeWash
            ? 'Jatah cuci gratis membership kamu akan dikembalikan.'
            : b.paid
            ? 'Pembayaran akan dikembalikan, Coins yang didapat dari pesanan ini ditarik, dan voucher (jika ada) bisa dipakai lagi.'
            : 'Slot akan dilepas dan voucher (jika ada) bisa dipakai lagi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tidak')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final done = await guard(context, () async {
      await app.cancel(b.id);
      return true;
    });
    if (done == true && mounted) toast(context, 'Pesanan dibatalkan');
  }

  /// Kartu status pembayaran belum lunas (tampilan baru, aksi "Bayar Sekarang" tidak berubah).
  Widget _unpaidCard(Booking b, bool shop) => RwCard(
        color: kRwGoldLight,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.schedule_rounded, color: kRwGoldDark),
            SizedBox(width: 10),
            Expanded(child: Text('Menunggu pembayaran', style: TextStyle(fontWeight: FontWeight.w800, color: kRwText))),
          ]),
          const SizedBox(height: 4),
          Text(shop ? 'Pembelian selesai setelah pembayaran berhasil.' : 'Pesanan baru diproses petugas setelah dibayar.',
              style: const TextStyle(color: kRwGoldDark, fontSize: 13)),
          const SizedBox(height: 12),
          RwButton('Bayar Sekarang',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentMethodScreen(bookingId: b.id)))),
        ]),
      );

  /// Area utama status layanan: progress 3 tahap, status sekarang, estimasi, ilustrasi, timeline.
  Widget _statusCard(Booking b, int stage) {
    final names = b.pack.stageNames;
    final times = [for (var i = 0; i < 4; i++) '${i > b.status ? '~' : ''}${fmtHm.format(_stageTime(b, i))}'];
    return RwCard(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      child: Column(children: [
        OrderStepper(stage: stage),
        const SizedBox(height: 22),
        Text(b.pack.headlines[b.status],
            textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17.5, color: kRwText)),
        const SizedBox(height: 5),
        Text.rich(
          TextSpan(children: [
            const TextSpan(text: 'Estimasi selesai ', style: TextStyle(color: kRwSub)),
            TextSpan(text: fmtHm.format(b.estFinish), style: const TextStyle(color: kRed, fontWeight: FontWeight.w800)),
          ]),
          style: const TextStyle(fontSize: 14),
        ),
        if (b.active && b.queuePosition > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Antrean ke-${b.queuePosition}', style: const TextStyle(color: kRwSub, fontSize: 13)),
          ),
        const SizedBox(height: 20),
        OrderStatusIllustration(b),
        const SizedBox(height: 14),
        OrderStatusPill(b.statusLabel),
        rwDivider(v: 20),
        OrderTimeline(status: b.status, names: names, times: times),
      ]),
    );
  }

  /// Kartu rincian pesanan (semua data dari booking asli, format Rupiah memakai rp()).
  Widget _detailCard(Booking b, bool shop) {
    final payMethod = b.paid
        ? (b.freeWash ? 'Cuci gratis membership' : (b.payMethod?.label ?? '-'))
        : (b.payStatus == 'refunded' ? 'Dikembalikan' : (b.cancelled && b.freeWash ? 'Jatah dikembalikan' : 'Belum dibayar'));
    return RwCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        rwCardTitle(shop ? 'Rincian Pembelian' : 'Rincian Pesanan', bottom: 6),
        rwDivider(v: 6),
        rwKv(shop ? 'No. Pembelian' : 'No. Pesanan', '#${b.id}'),
        rwKv('Lokasi', '${kOutlet.name}, ${kOutlet.shortAddress}'),
        if (!shop) rwKv('Kendaraan', '${b.vehicle.label} • ${b.plate}'),
        rwKv(shop ? 'Jenis' : (b.pack.isOil ? 'Layanan' : 'Paket'), b.pack.title),
        rwKv(shop ? 'Waktu Beli' : 'Jadwal Booking', fmtDateTime.format(b.slot)),
        if (b.items.isNotEmpty) ...[
          rwDivider(v: 8),
          if (!shop) rwKv(b.pack.title, rp(b.servicePrice)),
          for (final l in b.items) rwKv('${l.product.name} ×${l.qty}', rp(l.subtotal)),
        ],
        rwDivider(v: 8),
        rwKv('Subtotal', rp(b.price)),
        if (b.discount > 0) rwKv('Voucher ${b.voucherCode ?? ''}', '- ${rp(b.discount)}', valueColor: kRwGreen),
        if (b.memberDiscount > 0) rwKv('Diskon Membership ${b.memberLabel ?? ''}', '- ${rp(b.memberDiscount)}', valueColor: kRwGreen),
        if (b.coinDiscount > 0) rwKv('Tukar ${b.coinsUsed} Coins', '- ${rp(b.coinDiscount)}', valueColor: kRwGreen),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: kRwBg, borderRadius: BorderRadius.circular(14)),
          child: rwKv('Total', rp(b.total), bold: true, valueColor: kRwNavy),
        ),
        rwDivider(v: 8),
        rwKv('Metode Pembayaran', payMethod),
        if (b.paid && (b.trx ?? '').isNotEmpty) rwKv('No. Transaksi', b.trx!),
        if (b.perks.isNotEmpty && !b.cancelled) rwKv('Benefit Member', b.perks.join(' • '), valueColor: kRwGreen),
        if (b.paid && b.coinsEarned > 0) rwKv('Coins didapat', '+${b.coinsEarned} Coins', valueColor: const Color(0xFFE39A0B)),
      ]),
    );
  }

  /// Kartu ulasan: sudah diulas -> bintang + kategori + isi; belum -> tombol ke halaman rating.
  Widget _reviewCard(Booking b) => RwCard(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          rwCardTitle('Ulasan', bottom: 10),
          if (b.review == null) ...[
            const Text('Bagaimana pengalamanmu?', style: TextStyle(fontWeight: FontWeight.w800, color: kRwText)),
            const SizedBox(height: 4),
            const Text('Rating dan ulasanmu membantu kami meningkatkan layanan.', style: TextStyle(color: kRwSub, fontSize: 13, height: 1.35)),
            const SizedBox(height: 14),
            RwButton('Beri Rating & Ulasan',
                icon: Icons.star_rounded,
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen(bookingId: b.id)))),
          ] else ...[
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 10, runSpacing: 6, children: [
              RatingStars(b.review!.rating, size: 24),
              RwPill(satisfactionLabel(b.review!.rating), bg: kRwGoldLight, fg: kRwGoldDark),
            ]),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kRwBg, borderRadius: BorderRadius.circular(14)),
              child: Text(
                b.review!.comment.isNotEmpty ? b.review!.comment : 'Ulasanmu membantu kami terus meningkatkan layanan.',
                style: TextStyle(color: b.review!.comment.isNotEmpty ? kRwText : kRwSub, fontSize: 13.5, height: 1.4),
              ),
            ),
          ],
        ]),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final b = app.byId(widget.id);
          if (b == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Pesanan tidak ditemukan.')));
          final stage = b.status == 0 ? 0 : (b.status == 3 ? 2 : 1);
          final shop = b.pack.isShop; // pembelian langsung di toko: tanpa tracking dan tiket
          // Jarak antar kartu konsisten 14 px.
          Widget gap(Widget w) => Padding(padding: const EdgeInsets.only(bottom: 14), child: w);
          return Scaffold(
            backgroundColor: kRwBg,
            appBar: AppBar(
              title: Text(shop ? 'Detail Pembelian' : 'Detail Pesanan'),
              centerTitle: true,
              backgroundColor: kRwBg,
              foregroundColor: kRwText,
              iconTheme: const IconThemeData(color: kRwNavy),
              titleTextStyle: const TextStyle(fontWeight: FontWeight.w800, color: kRwText, fontSize: 17),
              actions: [Padding(padding: const EdgeInsets.only(right: 14), child: Center(child: OrderStatusBadge(b)))],
            ),
            // Tombol utama "Cetak Bukti (PDF)" tetap terlihat di bawah layar.
            bottomNavigationBar: OrderBottomBar(
              child: RwButton('Cetak Bukti (PDF)', icon: Icons.picture_as_pdf_rounded, onPressed: () => _pdf(b)),
            ),
            body: PageList(top: 8, bottom: 24, children: [
              TwoPane(
                leftFlex: 5,
                rightFlex: 6,
                left: [
                  if (b.cancelled)
                    gap(RwCard(
                      color: const Color(0xFFFDE3E5),
                      child: Row(children: [
                        const Icon(Icons.cancel_outlined, color: kRwDanger),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            b.payStatus == 'refunded' ? 'Pesanan dibatalkan. Pembayaran dikembalikan.' : 'Pesanan dibatalkan.',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: kRwText),
                          ),
                        ),
                      ]),
                    ))
                  else ...[
                    if (!b.paid) gap(_unpaidCard(b, shop)),
                    if (shop && b.paid)
                      gap(RwHeroCard(
                        padding: const EdgeInsets.fromLTRB(16, 26, 16, 16),
                        child: Column(children: [
                          const RwCheckCircle(size: 76),
                          const SizedBox(height: 14),
                          const Text('Pembelian berhasil!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 21)),
                          const SizedBox(height: 4),
                          Text('Terima kasih sudah berbelanja!', style: TextStyle(color: Colors.white.withValues(alpha: .88), fontSize: 14)),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                            child: Row(children: [
                              const RwIconBox(Icons.storefront_rounded, size: 54, circle: false),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text('Ambil barang di kasir CleanDrive', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: kRwText)),
                                  const SizedBox(height: 2),
                                  const Text('Tunjukkan nomor pembelian ini ke kasir.', style: TextStyle(color: kRwSub, fontSize: 12.5)),
                                  const SizedBox(height: 6),
                                  SelectableText(b.code, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1, color: kRwNavy)),
                                ]),
                              ),
                            ]),
                          ),
                        ]),
                      ))
                    else if (!shop)
                      gap(_statusCard(b, stage)),
                  ],
                ],
                right: [
                  // Tiket Masuk hanya untuk booking layanan (cuci / ganti oli), sama seperti sebelumnya.
                  if (!shop) gap(OrderTicketCard(b)),
                  gap(_detailCard(b, shop)),
                  if (b.status == 3 && !b.cancelled && !shop) gap(_reviewCard(b)),
                  if (b.cancellable)
                    Center(
                      child: TextButton(
                        style: TextButton.styleFrom(foregroundColor: kError),
                        onPressed: () => _cancel(b),
                        child: Text(shop ? 'Batalkan Pembelian' : 'Batalkan Pesanan'),
                      ),
                    ),
                ],
              ),
            ]),
          );
        },
      );
}

// ---------- BERI RATING & ULASAN (redesign tema Navy) ----------
class ReviewScreen extends StatefulWidget {
  final String bookingId;
  const ReviewScreen({super.key, required this.bookingId});
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 5;
  final _text = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    final gained = await guard(context, () => app.review(widget.bookingId, _rating, _text.text.trim()));
    if (!mounted) return;
    setState(() => _busy = false);
    if (gained != null) {
      toast(context, gained > 0 ? 'Terima kasih! Kamu dapat +$gained Coins' : 'Terima kasih atas ulasanmu!');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        // ikon status bar putih karena header berwarna gelap
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: kRwBg,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  ReviewHero(
                    rating: _rating,
                    onRate: (i) => setState(() => _rating = i),
                    onBack: () => Navigator.maybePop(context),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + MediaQuery.paddingOf(context).bottom),
                    child: RwCard(
                      padding: const EdgeInsets.all(18),
                      radius: 24,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        const Text.rich(TextSpan(children: [
                          TextSpan(text: 'Tulis Ulasan ', style: TextStyle(fontWeight: FontWeight.w800, color: kRwText, fontSize: 15)),
                          TextSpan(text: '(Opsional)', style: TextStyle(color: kRwSub, fontSize: 14)),
                        ])),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _text,
                          minLines: 4,
                          maxLines: 5,
                          maxLength: 200, // batas 200 karakter
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(color: kRwText, fontSize: 14.5, height: 1.4),
                          decoration: reviewFieldDecoration(),
                          buildCounter: (context, {required currentLength, required isFocused, required maxLength}) =>
                              reviewCounter(currentLength, maxLength),
                        ),
                        const SizedBox(height: 8),
                        const RewardInfoBar(),
                        const SizedBox(height: 18),
                        RwButton('Kirim Ulasan', busy: _busy, onPressed: _send),
                        const SizedBox(height: 4),
                        Center(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: kRed,
                              minimumSize: const Size(140, 48),
                              textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Nanti Saja'),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
}
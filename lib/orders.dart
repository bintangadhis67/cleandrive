import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'app_state.dart';
import 'loyalty_models.dart';
import 'models.dart';
import 'payment.dart';
import 'shop.dart';
import 'theme.dart';
import 'widgets.dart';

// ---------- RIWAYAT PESANAN (desain layar 16) ----------
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

/// Gambar kecil di kartu riwayat.
/// - Pembelian toko: foto produk yang dibeli (plus badge "+N" bila lebih dari satu jenis produk).
/// - Cuci / ganti oli: tetap memakai ServiceThumb seperti sebelumnya.
class _OrderThumb extends StatelessWidget {
  final Booking b;
  final double width;
  const _OrderThumb(this.b, {this.width = 84});

  @override
  Widget build(BuildContext context) {
    if (!(b.pack.isShop && b.items.isNotEmpty)) return ServiceThumb(b.pack, b.vehicle, width: width);
    final h = width * .6;
    final first = b.items.first.product;
    final more = b.items.length - 1;
    return SizedBox(
      width: width,
      height: h,
      child: Stack(children: [
        Container(
          width: width,
          height: h,
          decoration: BoxDecoration(color: const Color(0xFFEFF1F5), borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.all(4),
          child: ProductImage(first, height: h - 8),
        ),
        if (more > 0)
          Positioned(
            right: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: kNavy, borderRadius: BorderRadius.circular(10)),
              child: Text('+$more', style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800)),
            ),
          ),
      ]),
    );
  }
}

class _OrdersScreenState extends State<OrdersScreen> {
  int _filter = 0; // 0 semua, 1 selesai, 2 dibatalkan, 3 ulasan
  static const _labels = ['Semua', 'Selesai', 'Dibatalkan', 'Ulasan'];

  Widget _pill(int i) {
    final sel = _filter == i;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => setState(() => _filter = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            color: sel ? kRed : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: sel ? kRed : kLine),
          ),
          child: Text(_labels[i], style: TextStyle(fontWeight: FontWeight.w700, color: sel ? Colors.white : kNavy)),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, Booking b) => Panel(
        padding: const EdgeInsets.all(14),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(id: b.id))),
        child: Row(children: [
          _OrderThumb(b),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(b.code, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13), overflow: TextOverflow.ellipsis)),
                StatusChip(b),
              ]),
              const SizedBox(height: 4),
              Text(b.subtitle, style: const TextStyle(fontSize: 13)),
              Text(fmtDateTime.format(b.slot), style: const TextStyle(fontSize: 12, color: kMuted)),
              const SizedBox(height: 6),
              Row(children: [
                Text(rp(b.total), style: const TextStyle(fontWeight: FontWeight.w800)),
                const Spacer(),
                if (b.review != null) ...[
                  const Icon(Icons.star_rounded, color: kGold, size: 18),
                  const SizedBox(width: 2),
                  Text('${b.review!.rating}.0', style: const TextStyle(fontWeight: FontWeight.w700)),
                ] else if (b.status == 3 && !b.cancelled && !b.pack.isShop)
                  const Text('Beri ulasan', style: TextStyle(color: kRed, fontWeight: FontWeight.w800, fontSize: 12.5))
                else if (!b.cancelled && !b.paid)
                  const Text('Belum dibayar', style: TextStyle(color: Color(0xFFD08A00), fontWeight: FontWeight.w800, fontSize: 12.5)),
              ]),
            ]),
          ),
        ]),
      );

  /// Kartu pada tab "Ulasan": pesanan selesai (cuci / ganti oli) beserta rating-nya,
  /// atau tombol "Beri ulasan" bila belum dinilai.
  Widget _reviewCard(BuildContext context, Booking b) => Panel(
        padding: const EdgeInsets.all(14),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(id: b.id))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _OrderThumb(b, width: 72),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b.code, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                Text(b.subtitle, style: const TextStyle(fontSize: 13)),
                Text(fmtDateTime.format(b.slot), style: const TextStyle(fontSize: 12, color: kMuted)),
              ]),
            ),
          ]),
          const SizedBox(height: 10),
          if (b.review != null) ...[
            Row(children: [
              StarRow(b.review!.rating.toDouble(), size: 20),
              const SizedBox(width: 8),
              Text(ratingLabel(b.review!.rating), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            ]),
            if (b.review!.comment.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(b.review!.comment, style: const TextStyle(fontSize: 13.5)),
            ],
          ] else
            RedButton('Beri Rating & Ulasan', icon: Icons.star_rounded, onPressed: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen(bookingId: b.id)))),
        ]),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final all = app.bookings;
          final list = switch (_filter) {
            1 => all.where((b) => b.status == 3 && !b.cancelled).toList(),
            2 => all.where((b) => b.cancelled).toList(),
            // Ulasan: pesanan cuci/oli yang sudah selesai (belum diulas tampil paling atas).
            3 => (all.where((b) => b.status == 3 && !b.cancelled && !b.pack.isShop).toList()
              ..sort((a, b) {
                final ra = a.review == null ? 0 : 1, rb = b.review == null ? 0 : 1;
                return ra != rb ? ra - rb : b.slot.compareTo(a.slot);
              })),
            _ => all,
          };
          return RefreshIndicator(
            color: kRed,
            onRefresh: () async {
              try {
                await app.refreshAll();
              } catch (_) {}
            },
            child: LayoutBuilder(builder: (context, cons) {
              final cols = colsFor(cons.maxWidth - 32, minWidth: 460);
              return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
                pageHeader('Riwayat', 'Semua pesanan cuci, ganti oli, pembelian toko, dan ulasanmu ada di sini.'),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [for (var i = 0; i < _labels.length; i++) _pill(i)]),
                ),
                const SizedBox(height: 16),
                if (list.isEmpty)
                  Panel(
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                    child: Center(
                      child: Column(children: [
                        Icon(_filter == 3 ? Icons.star_outline_rounded : Icons.history_rounded, size: 48, color: kMuted),
                        const SizedBox(height: 10),
                        Text(_filter == 3 ? 'Belum ada ulasan' : 'Belum ada riwayat',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        Text(
                            _filter == 3
                                ? 'Selesaikan pesanan cuci atau ganti oli, lalu beri rating di sini.'
                                : 'Pesanan dan pembelian yang kamu buat akan muncul di sini.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: kMuted)),
                      ]),
                    ),
                  ),
                ColumnsGrid(cols: cols, gap: 12, children: [
                  for (final b in list) _filter == 3 ? _reviewCard(context, b) : _card(context, b),
                ]),
              ]);
            }),
          );
        },
      );
}

// ---------- DETAIL: TIKET QR + TRACKING (desain layar 14) ----------
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
        if (b.coinDiscount > 0) pw.Text('Tukar ${b.coinsUsed} Coins: - ${rp(b.coinDiscount)}'),
        pw.Text('Total: ${rp(b.total)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text(b.paid ? 'Pembayaran: ${b.payMethod?.label ?? '-'} (${b.trx ?? '-'}) - Lunas' : 'Pembayaran: Belum dibayar'),
        pw.SizedBox(height: 12),
        pw.BarcodeWidget(data: b.code, barcode: pw.Barcode.qrCode(), width: 100, height: 100),
      ]),
    ));
    await Printing.layoutPdf(onLayout: (_) => doc.save(), name: 'bukti-${b.id}.pdf');
  }

  DateTime _stageTime(Booking b, int i) {
    const f = [0.0, .3, .8, 1.0];
    final total = b.estFinish.difference(b.slot).inMinutes;
    return b.slot.add(Duration(minutes: (total * f[i]).round()));
  }

  Widget _stepper(int stage) {
    const names = ['Booking', 'Proses', 'Selesai'];
    Widget dot(int i) {
      final done = i < stage, cur = i == stage;
      return Column(children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(shape: BoxShape.circle, color: cur ? kRed : (done ? kNavy : const Color(0x1F0B1F44))),
          child: (done || cur) ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
        ),
        const SizedBox(height: 4),
        Text(names[i], style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: (done || cur) ? kNavy : kMuted)),
      ]);
    }

    Widget line(int i) => Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 14, left: 4, right: 4),
            child: Container(height: 2, color: i < stage ? kNavy : const Color(0x1F0B1F44)),
          ),
        );

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [dot(0), line(0), dot(1), line(1), dot(2)]);
  }

  Widget _timeline(Booking b) => Column(children: [
        for (var i = 0; i < 4; i++)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(shape: BoxShape.circle, color: i <= b.status ? kRed : const Color(0x330B1F44)),
              ),
              if (i < 3) Container(width: 2, height: 30, color: i < b.status ? kRed : const Color(0x1F0B1F44)),
            ]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(b.pack.stageNames[i],
                  style: TextStyle(fontWeight: i == b.status ? FontWeight.w800 : FontWeight.w600, color: i <= b.status ? kNavy : kMuted)),
            ),
            Text('${i > b.status ? '~' : ''}${fmtHm.format(_stageTime(b, i))}',
                style: TextStyle(fontWeight: FontWeight.w700, color: i <= b.status ? kNavy : kMuted)),
          ]),
      ]);

  Future<void> _cancel(Booking b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan pesanan?'),
        content: Text(b.paid
            ? 'Pembayaran dan Coins yang dipakai akan dikembalikan, Coins yang didapat dari pesanan ini ditarik, dan voucher (jika ada) bisa dipakai lagi.'
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

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final b = app.byId(widget.id);
          if (b == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Pesanan tidak ditemukan.')));
          final stage = b.status == 0 ? 0 : (b.status == 3 ? 2 : 1);
          final shop = b.pack.isShop; // pembelian langsung di toko: tanpa tracking dan tiket
          return Scaffold(
            appBar: AppBar(
              title: Text(shop ? 'Detail Pembelian' : 'Detail Pesanan'),
              actions: [Padding(padding: const EdgeInsets.only(right: 14), child: Center(child: StatusChip(b)))],
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  if (b.cancelled)
                    Panel(
                      color: const Color(0x14D64545),
                      child: Row(children: [
                        const Icon(Icons.cancel_outlined, color: Color(0xFFB3261E)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            b.payStatus == 'refunded' ? 'Pesanan dibatalkan. Pembayaran dikembalikan.' : 'Pesanan dibatalkan.',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ]),
                    )
                  else ...[
                    if (!b.paid)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Panel(
                          color: const Color(0x1FF5B31B),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Row(children: [
                              Icon(Icons.schedule, color: Color(0xFFD08A00)),
                              SizedBox(width: 10),
                              Expanded(child: Text('Menunggu pembayaran', style: TextStyle(fontWeight: FontWeight.w800))),
                            ]),
                            const SizedBox(height: 4),
                            Text(shop ? 'Pembelian selesai setelah pembayaran berhasil.' : 'Pesanan baru diproses petugas setelah dibayar.',
                                style: const TextStyle(color: kMuted, fontSize: 13)),
                            const SizedBox(height: 12),
                            RedButton('Bayar Sekarang', onPressed: () =>
                                Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentMethodScreen(bookingId: b.id)))),
                          ]),
                        ),
                      ),
                    if (shop && b.paid)
                      Panel(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                        child: Column(children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: kGreen),
                            child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
                          ),
                          const SizedBox(height: 14),
                          const Text('Pembelian berhasil', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                          const SizedBox(height: 4),
                          const Text('Terima kasih sudah berbelanja!', style: TextStyle(color: kMuted)),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(14)),
                            child: Row(children: [
                              const Icon(Icons.storefront_outlined, color: kNavy),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text('Ambil barang di kasir CleanDrive', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                                  const Text('Tunjukkan nomor pembelian ini ke kasir.', style: TextStyle(color: kMuted, fontSize: 12.5)),
                                  const SizedBox(height: 4),
                                  SelectableText(b.code, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
                                ]),
                              ),
                            ]),
                          ),
                        ]),
                      )
                    else if (!shop)
                    Panel(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                      child: Column(children: [
                        _stepper(stage),
                        const SizedBox(height: 20),
                        Text(b.pack.headlines[b.status], textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                        const SizedBox(height: 4),
                        Text.rich(TextSpan(children: [
                          const TextSpan(text: 'Estimasi selesai: ', style: TextStyle(color: kMuted)),
                          TextSpan(text: fmtHm.format(b.estFinish), style: const TextStyle(color: kRed, fontWeight: FontWeight.w800)),
                        ])),
                        if (b.active && b.queuePosition > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('Antrean ke-${b.queuePosition}', style: const TextStyle(color: kMuted, fontSize: 13)),
                          ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: 150,
                          height: 150,
                          child: Stack(alignment: Alignment.center, children: [
                            SizedBox.expand(
                              child: CircularProgressIndicator(
                                value: (b.status + 1) / 4,
                                strokeWidth: 10,
                                strokeCap: StrokeCap.round,
                                color: kRed,
                                backgroundColor: const Color(0x140B1F44),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(28),
                              child: b.pack.isShop
                                  ? const Icon(Icons.shopping_bag_rounded, size: 56, color: kNavy)
                                  : Image.asset(b.pack.imageFor(b.vehicle), fit: BoxFit.contain, cacheWidth: 400),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(20)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(width: 9, height: 9, decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(b.statusLabel, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                          ]),
                        ),
                        const SizedBox(height: 22),
                        _timeline(b),
                      ]),
                    ),
                  ],
                  sec(shop ? 'Rincian Pembelian' : 'Tiket Masuk'),
                  Panel(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      if (!shop) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
                        child: Opacity(
                          opacity: b.cancelled ? .25 : 1,
                          child: QrImageView(data: b.code, size: 170, backgroundColor: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SelectableText(b.code, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
                      Text(b.pack.isShop ? 'Tunjukkan QR ini ke kasir untuk mengambil pesanan' : 'Tunjukkan QR ini ke petugas saat tiba',
                          style: const TextStyle(fontSize: 12.5, color: kMuted)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (b.verified ? kStatusColors[3] : kStatusColors[0]).withOpacity(.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(b.verified ? Icons.verified : Icons.hourglass_empty,
                              size: 16, color: b.verified ? kStatusColors[3] : kStatusColors[0]),
                          const SizedBox(width: 6),
                          Text(b.verified ? 'Tiket terverifikasi' : 'Belum diverifikasi petugas',
                              style: TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w700, color: b.verified ? kStatusColors[3] : kStatusColors[0])),
                        ]),
                      ),
                      const Divider(height: 28),
                      ],
                      kv(shop ? 'No. Pembelian' : 'No. Pesanan', '#${b.id}'),
                      if (!b.pack.isShop) kv('Kendaraan', '${b.vehicle.label} • ${b.plate}'),
                      kv(b.pack.isShop ? 'Jenis' : (b.pack.isOil ? 'Layanan' : 'Paket'), b.pack.title),
                      kv(b.pack.isShop ? 'Waktu Beli' : 'Jadwal', fmtDateTime.format(b.slot)),
                      if (b.pack.isOil && b.items.isEmpty) kv('Oli', 'Dibawa sendiri'),
                      if (b.items.isNotEmpty) ...[
                        const Divider(height: 18),
                        if (!b.pack.isShop) kv(b.pack.title, rp(b.servicePrice)),
                        for (final l in b.items) kv('${l.product.name} ×${l.qty}', rp(l.subtotal)),
                        const Divider(height: 18),
                      ],
                      kv('Subtotal', rp(b.price)),
                      if (b.discount > 0) kv('Voucher ${b.voucherCode ?? ''}', '- ${rp(b.discount)}', valueColor: kGreen),
                      if (b.coinDiscount > 0) kv('Tukar ${b.coinsUsed} Coins', '- ${rp(b.coinDiscount)}', valueColor: kGreen),
                      kv('Total', rp(b.total), bold: true),
                      kv('Pembayaran', b.paid ? '${b.payMethod?.label ?? '-'} • ${b.trx ?? ''}' : (b.payStatus == 'refunded' ? 'Dikembalikan' : 'Belum dibayar')),
                      if (b.paid && b.coinsEarned > 0) kv('Coins didapat', '+${b.coinsEarned} Coins', valueColor: const Color(0xFFD08A00)),
                    ]),
                  ),
                  if (b.status == 3 && !b.cancelled && !shop) ...[
                    sec('Ulasan'),
                    Panel(
                      child: b.review == null
                          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('Bagaimana pengalamanmu?', style: TextStyle(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              const Text('Rating dan ulasanmu membantu kami meningkatkan layanan.', style: TextStyle(color: kMuted, fontSize: 13)),
                              const SizedBox(height: 12),
                              RedButton('Beri Rating & Ulasan', icon: Icons.star_rounded, onPressed: () =>
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen(bookingId: b.id)))),
                            ])
                          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                StarRow(b.review!.rating.toDouble(), size: 22),
                                const SizedBox(width: 8),
                                Text(ratingLabel(b.review!.rating), style: const TextStyle(fontWeight: FontWeight.w800)),
                              ]),
                              if (b.review!.comment.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(b.review!.comment, style: const TextStyle(color: kMuted)),
                              ],
                            ]),
                    ),
                  ],
                  const SizedBox(height: 16),
                  RedButton('Cetak Bukti (PDF)', icon: Icons.picture_as_pdf, onPressed: () => _pdf(b)),
                  if (b.cancellable)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: TextButton(
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFFB3261E)),
                        onPressed: () => _cancel(b),
                        child: Text(shop ? 'Batalkan Pembelian' : 'Batalkan Pesanan'),
                      ),
                    ),
                ]),
              ),
            ),
          );
        },
      );
}

// ---------- BERI RATING & ULASAN (desain layar 15) ----------
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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Beri Rating & Ulasan')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(padding: const EdgeInsets.all(24), children: [
              const SizedBox(height: 8),
              const Center(child: Text('Terima kasih!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
              const SizedBox(height: 8),
              const Center(
                child: Text('Bagaimana pengalamanmu\nmenggunakan layanan kami?', textAlign: TextAlign.center, style: TextStyle(color: kMuted, height: 1.4)),
              ),
              const SizedBox(height: 22),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 1; i <= 5; i++)
                  GestureDetector(
                    onTap: () => setState(() => _rating = i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(i <= _rating ? Icons.star_rounded : Icons.star_outline_rounded, size: 50, color: kGold),
                    ),
                  ),
              ]),
              const SizedBox(height: 10),
              Center(child: Text(ratingLabel(_rating), style: const TextStyle(fontWeight: FontWeight.w800, color: kNavy))),
              const SizedBox(height: 26),
              const Text.rich(TextSpan(children: [
                TextSpan(text: 'Tulis Ulasan ', style: TextStyle(fontWeight: FontWeight.w800)),
                TextSpan(text: '(Opsional)', style: TextStyle(color: kMuted)),
              ])),
              const SizedBox(height: 8),
              TextField(
                controller: _text,
                maxLines: 4,
                maxLength: 200,
                decoration: const InputDecoration(hintText: 'Ceritakan pengalamanmu...'),
              ),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.monetization_on_rounded, size: 16, color: kGold),
                const SizedBox(width: 6),
                Text('Dapat +$kReviewCoins Coins, +$kReviewCommentBonus bonus bila menulis ulasan',
                    style: const TextStyle(color: kMuted, fontSize: 12.5)),
              ]),
              const SizedBox(height: 14),
              RedButton('Kirim Ulasan', busy: _busy, onPressed: _send),
              const SizedBox(height: 6),
              Center(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Nanti Saja'))),
            ]),
          ),
        ),
      );
}
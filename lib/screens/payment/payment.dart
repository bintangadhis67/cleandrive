import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/loyalty_models.dart';
import '../../models/models.dart';
import '../../widgets/motion.dart';
import '../../widgets/widgets.dart';
import '../orders/orders.dart';
import '../rewards/loyalty.dart';
import '../rewards/reward_ui.dart';

// ---------- PILIH METODE PEMBAYARAN ----------
// Coins bisa dipakai sebagai potongan (1 Coin = Rp 50, maks 30% total). Total = harga - voucher - diskon membership - Coins.

/// AppBar sederhana bergaya desain baru: latar biru muda, judul navy di tengah, panah kembali navy.
PreferredSizeWidget _payBar(String title, {bool back = true}) => AppBar(
      title: Text(title),
      automaticallyImplyLeading: back,
      backgroundColor: kRwBg,
      foregroundColor: kRwText,
      iconTheme: const IconThemeData(color: kRwText),
      titleTextStyle: const TextStyle(fontWeight: FontWeight.w800, color: kRwText, fontSize: 17),
    );

class PaymentMethodScreen extends StatefulWidget {
  final String bookingId;
  const PaymentMethodScreen({super.key, required this.bookingId});
  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  bool _busy = false;
  int _coins = 0;
  PayMethod? _picked; // hanya untuk efek visual metode yang dipilih

  Future<void> _choose(Booking b, PayMethod m, int coins) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _picked = m;
    });
    final p = await guard(context, () => app.startPayment(b.id, m, coins: coins));
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (p == null) _picked = null;
    });
    if (p == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => m.isQris ? QrisPayScreen(payment: p) : EwalletPayScreen(payment: p)),
    );
  }

  /// Ringkasan pesanan pada kartu navy: harga, potongan, dan Total Bayar yang menonjol.
  Widget _summary(Booking b, int coins) {
    final pay = b.total - coins * kCoinValue;
    final est = coinsForPayment(shop: b.pack.isShop, paid: pay);
    const green = Color(0xFF6FE0A6);
    return RwHeroCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        rwKv('Pesanan', b.code, onDark: true),
        rwKv('Layanan', b.pack.isShop ? 'Pembelian Toko' : b.pack.title, onDark: true),
        rwKv('Total Harga', rp(b.price), onDark: true),
        if (b.memberDiscount > 0) rwKv('Diskon Membership ${b.memberLabel ?? ''}', '- ${rp(b.memberDiscount)}', onDark: true, valueColor: green),
        if (b.discount > 0) rwKv('Voucher ${b.voucherCode ?? ''}', '- ${rp(b.discount)}', onDark: true, valueColor: green),
        if (coins > 0) rwKv('Tukar $coins Coins', '- ${rp(coins * kCoinValue)}', onDark: true, valueColor: green),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1, color: Colors.white.withValues(alpha: .22)),
        ),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          const Expanded(child: Text('Total Bayar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15.5))),
          Text(rp(pay), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 28, letterSpacing: -.3)),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .10), borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            const Icon(Icons.monetization_on_rounded, size: 18, color: kRwGold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                est > 0 ? 'Dapat +$est Coins setelah pembayaran.' : 'Belum dapat Coins (belanja toko minimal ${rp(kShopCoinStepRp)}).',
                style: TextStyle(color: Colors.white.withValues(alpha: .9), fontSize: 12.5, height: 1.35),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  /// Satu baris metode pembayaran: ikon, nama, deskripsi, panah. Terpilih = border navy + latar biru muda.
  Widget _methodTile(Booking b, PayMethod m) {
    final sel = _picked == m;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: sel ? kRwBlueSoft : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: sel ? kRwNavy : Colors.transparent, width: 1.8),
          boxShadow: kRwShadowThin,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: _busy ? null : () => _choose(b, m, _coins),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                PayLogo(m, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: kRwText)),
                    const SizedBox(height: 2),
                    Text(m.hint, style: const TextStyle(fontSize: 12.5, color: kRwSub)),
                  ]),
                ),
                if (sel && _busy)
                  const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: kRwNavy))
                else
                  Icon(sel ? Icons.check_circle_rounded : Icons.chevron_right_rounded, color: sel ? kRwNavy : kRwSub, size: sel ? 24 : 26),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final b = app.byId(widget.bookingId);
          if (b != null) {
            // pastikan pilihan Coins tidak melebihi batas bila saldo/total berubah
            final mx = maxRedeemCoins(total: b.total, balance: app.loyalty.balance);
            if (_coins > mx) _coins = mx;
          }
          if (b == null) {
            return Scaffold(backgroundColor: kRwBg, appBar: _payBar(''), body: const Center(child: Text('Pesanan tidak ditemukan.')));
          }
          return Scaffold(
            backgroundColor: kRwBg,
            appBar: _payBar('Pilih Metode Pembayaran'),
            body: PageList(
              bottom: 32,
              children: [
                TwoPane(
                  leftFlex: 5,
                  rightFlex: 6,
                  left: [_summary(b, _coins)],
                  right: [
                    const SizedBox(height: 14),
                    RedeemCard(total: b.total, coins: _coins, onChanged: (v) => setState(() => _coins = v)),
                    const RwSectionTitle('Metode Pembayaran', top: 22),
                    for (final m in PayMethod.values) _methodTile(b, m),
                    const SizedBox(height: 4),
                    const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.info_outline, size: 15, color: kRwSub),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text('Mode simulasi: tidak ada uang sungguhan yang diproses.',
                            style: TextStyle(fontSize: 12, color: kRwSub)),
                      ),
                    ]),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                        child: const Text('Bayar nanti'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
}

String _mmss(Duration d) {
  final s = d.inSeconds < 0 ? 0 : d.inSeconds;
  return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

void _goSuccess(BuildContext context, Payment p) => Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PaymentSuccessScreen(payment: p)),
    );

// ---------- PEMBAYARAN QRIS ----------
class QrisPayScreen extends StatefulWidget {
  final Payment payment;
  const QrisPayScreen({super.key, required this.payment});
  @override
  State<QrisPayScreen> createState() => _QrisPayScreenState();
}

class _QrisPayScreenState extends State<QrisPayScreen> {
  late Payment _p = widget.payment;
  Timer? _tick, _poll;
  bool _busy = false, _done = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _check(silent: true));
  }

  @override
  void dispose() {
    _tick?.cancel();
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _finish(Payment p) async {
    if (_done) return;
    _done = true;
    _tick?.cancel();
    _poll?.cancel();
    await app.refreshBooking(p.bookingId);
    if (mounted) _goSuccess(context, p);
  }

  Future<void> _check({bool silent = false}) async {
    try {
      final p = await app.payment(_p.id);
      if (!mounted) return;
      setState(() => _p = p);
      if (p.paid) {
        await _finish(p);
      } else if (!silent) {
        toast(context, p.expired ? 'QR sudah kedaluwarsa.' : 'Pembayaran belum diterima.');
      }
    } on ApiException catch (e) {
      if (!silent && mounted) toast(context, e.message, error: true);
    }
  }

  Future<void> _simulate() async {
    setState(() => _busy = true);
    final p = await guard(context, () => app.simulateQrisPaid(_p.id));
    if (!mounted) return;
    setState(() => _busy = false);
    if (p != null) await _finish(p);
  }

  Future<void> _renew() async {
    setState(() => _busy = true);
    final p = await guard(context, () => app.startPayment(_p.bookingId, PayMethod.qris));
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (p != null) _p = p;
    });
  }

  @override
  Widget build(BuildContext context) {
    final left = _p.expiresAt.difference(DateTime.now());
    final expired = _p.expired;
    return Scaffold(
      backgroundColor: kRwBg,
      appBar: _payBar('Pembayaran QRIS'),
      body: PageList(
        bottom: 32,
        children: [
          TwoPane(
            left: [
              _PayHero(
                amount: _p.amount,
                rows: [
                  ('No. Transaksi', _p.trx),
                  ('Metode', 'QRIS'),
                  ('Status', expired ? 'Kedaluwarsa' : 'Menunggu pembayaran'),
                  ('Batas waktu', expired ? 'Kedaluwarsa' : _mmss(left)),
                ],
              ),
              const SizedBox(height: 14),
            ],
            right: [
              RwCard(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                child: Column(children: [
                  const Text('Scan QR Code berikut', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kRwText)),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kRwLine, width: 1.5),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('QRIS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2, color: kRwText)),
                      const SizedBox(height: 8),
                      Opacity(
                        opacity: expired ? .25 : 1,
                        child: QrImageView(data: _p.qrString ?? _p.trx, size: 220, backgroundColor: Colors.white),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  const Text('Gunakan aplikasi e-wallet / mobile banking yang mendukung QRIS',
                      textAlign: TextAlign.center, style: TextStyle(color: kRwSub, fontSize: 13, height: 1.4)),
                  const SizedBox(height: 12),
                  Text(expired ? 'Kedaluwarsa' : _mmss(left),
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: expired ? kRed : kRwNavy)),
                  const SizedBox(height: 14),
                  if (expired)
                    RwButton('Buat QR Baru', busy: _busy, onPressed: _renew)
                  else
                    RwButton('Cek Pembayaran', busy: _busy, onPressed: () => _check()),
                  if (_p.sandbox && !expired) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _busy ? null : _simulate,
                      style: TextButton.styleFrom(foregroundColor: kRwNavy),
                      icon: const Icon(Icons.science_outlined, size: 18),
                      label: const Text('Simulasikan pembayaran (mode demo)'),
                    ),
                  ],
                  const SizedBox(height: 6),
                  RwButton('Pilih Metode Lain', outlined: true, onPressed: () => Navigator.pop(context)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Kartu navy berisi Total Pembayaran (besar) dan rincian transaksi. Dipakai QRIS dan e-wallet.
class _PayHero extends StatelessWidget {
  final int amount;
  final List<(String, String)> rows;
  const _PayHero({required this.amount, required this.rows});

  @override
  Widget build(BuildContext context) => RwHeroCard(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Total Pembayaran', style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 14)),
          const SizedBox(height: 4),
          Text(rp(amount), style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -.5)),
          const SizedBox(height: 14),
          for (final r in rows) rwKv(r.$1, r.$2, onDark: true, vPad: 6),
        ]),
      );
}

// ---------- PEMBAYARAN E-WALLET ----------
class EwalletPayScreen extends StatefulWidget {
  final Payment payment;
  const EwalletPayScreen({super.key, required this.payment});
  @override
  State<EwalletPayScreen> createState() => _EwalletPayScreenState();
}

class _EwalletPayScreenState extends State<EwalletPayScreen> {
  bool _busy = false;

  Future<void> _pay() async {
    setState(() => _busy = true);
    final p = await guard(context, () => app.confirmPayment(widget.payment.id));
    if (!mounted) return;
    setState(() => _busy = false);
    if (p != null) _goSuccess(context, p);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payment;
    final balance = p.balance ?? 0;
    final enough = balance >= p.amount;
    final tone = enough ? kRwGreen : kRed;
    return Scaffold(
      backgroundColor: kRwBg,
      appBar: _payBar('Pembayaran ${p.method.label}'),
      body: PageList(
        bottom: 32,
        children: [
          TwoPane(
            left: [
              _PayHero(
                amount: p.amount,
                rows: [
                  ('No. Transaksi', p.trx),
                  ('Metode', p.method.label),
                  ('Status', 'Menunggu pembayaran'),
                  ('Batas waktu', fmtHm.format(p.expiresAt)),
                ],
              ),
              const SizedBox(height: 14),
            ],
            right: [
              RwCard(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Akan dibayarkan dengan', style: TextStyle(color: kRwText, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kRwLine, width: 1.4),
                    ),
                    child: Row(children: [
                      PayLogo(p.method, size: 48),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.method.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kRwText)),
                          const SizedBox(height: 2),
                          Text('${p.method.isBank ? 'Saldo rekening' : 'Saldo'} (simulasi): ${rp(balance)}',
                              style: TextStyle(fontSize: 13, color: enough ? kRwSub : kRed, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    Icon(enough ? Icons.check_circle_rounded : Icons.error_rounded, size: 19, color: tone),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(enough ? 'Saldo cukup untuk transaksi ini' : 'Saldo tidak cukup. Pilih metode lain.',
                          style: TextStyle(color: tone, fontSize: 13.5, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  const SizedBox(height: 22),
                  RwButton('Bayar Sekarang', busy: _busy, onPressed: enough ? _pay : null),
                  const SizedBox(height: 10),
                  RwButton('Pilih Metode Lain', outlined: true, onPressed: () => Navigator.pop(context)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------- PEMBAYARAN BERHASIL ----------
class PaymentSuccessScreen extends StatelessWidget {
  final Payment payment;
  const PaymentSuccessScreen({super.key, required this.payment});

  /// Titik konfeti dekoratif di kartu navy.
  Widget _dot(Alignment a, Color c, double s, {bool round = true}) => Align(
        alignment: a,
        child: Container(
          width: s,
          height: s,
          decoration: BoxDecoration(color: c, shape: round ? BoxShape.circle : BoxShape.rectangle, borderRadius: round ? null : BorderRadius.circular(2)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final shop = app.byId(payment.bookingId)?.pack.isShop ?? false;
    return Scaffold(
      backgroundColor: kRwBg,
      appBar: _payBar('Pembayaran Berhasil', back: false),
      body: SafeArea(
        child: PageList(
          top: 8,
          bottom: 32,
          children: [
            RwHeroCard(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
              child: Stack(children: [
                _dot(const Alignment(-.82, -.9), const Color(0xFFFFB91F), 9, round: false),
                _dot(const Alignment(-.55, -.55), const Color(0xFF19A66A), 7),
                _dot(const Alignment(.78, -.85), const Color(0xFF6FE0A6), 8, round: false),
                _dot(const Alignment(.9, -.3), const Color(0xFFFF6B73), 8),
                _dot(const Alignment(-.9, .1), const Color(0xFFFFB91F), 8),
                _dot(const Alignment(.55, .15), const Color(0xFFFFB91F), 7, round: false),
                SizedBox(
                  width: double.infinity, // memenuhi lebar kartu supaya isi benar-benar di tengah
                  child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  // Centang animasi + gelombang + konfeti (SuccessBurst).
                  const SuccessBurst(size: 96),
                  const SizedBox(height: 18),
                  const FadeSlideIn(
                    delay: Duration(milliseconds: 400),
                    child: Text('Pembayaran Berhasil!',
                        textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 6),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 520),
                    child: Text(
                      shop
                          ? 'Terima kasih, pembelianmu berhasil. Ambil barang di kasir CleanDrive.'
                          : 'Terima kasih, pesanan Anda sudah dikonfirmasi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withValues(alpha: .88), fontSize: 14, height: 1.4),
                    ),
                  ),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 650),
              child: RwCard(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              child: Column(children: [
                rwKv('No. Transaksi', payment.trx, bold: true, vPad: 8),
                rwDivider(v: 2),
                rwKv('Nomor Pesanan', '#${payment.bookingId}', vPad: 8),
                rwDivider(v: 2),
                rwKv('Metode', payment.method.label, bold: true, vPad: 8),
                if (payment.coinsUsed > 0) ...[
                  rwDivider(v: 2),
                  rwKv('Tukar ${payment.coinsUsed} Coins', '- ${rp(payment.coinDiscount)}', valueColor: kRwGreen, vPad: 8),
                ],
                rwDivider(v: 2),
                rwKv('Total Pembayaran', rp(payment.amount), bold: true, vPad: 8),
              ]),
            )),
            if (payment.coinsEarned > 0) ...[
              const SizedBox(height: 14),
              FadeSlideIn(
                delay: const Duration(milliseconds: 800),
                child: RwCard(
                color: const Color(0xFFFFF7E0),
                borderColor: const Color(0xFFFFE3A0),
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  const RwCoin(size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Kamu dapat +${payment.coinsEarned} Coins!',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: kRwText)),
                      const SizedBox(height: 2),
                      const Text('Coins akan masuk ke saldo Coins kamu.', style: TextStyle(color: kRwSub, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(
                          shop
                              ? 'Belanja toko ${rp(payment.amount)}: +$kShopCoinReward Coins tiap ${rp(kShopCoinStepRp)}.'
                              : 'Transaksi tingkat ${payBandFor(payment.amount).label} (${payBandFor(payment.amount).range}).',
                          style: const TextStyle(color: kRwSub, fontSize: 12.5, height: 1.3)),
                    ]),
                  ),
                ]),
              )),
            ],
            const SizedBox(height: 22),
            FadeSlideIn(
              delay: const Duration(milliseconds: 950),
              child: RwButton(shop ? 'Lihat Pembelian' : 'Lihat Pesanan', onPressed: () {
              final nav = Navigator.of(context);
              app.requestTab(1);
              nav.popUntil((r) => r.isFirst);
              nav.push(MaterialPageRoute(builder: (_) => DetailScreen(id: payment.bookingId)));
            })),
            Center(
              child: TextButton(
                onPressed: () {
                  app.requestTab(0);
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
                style: TextButton.styleFrom(foregroundColor: kRwText, textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                child: const Text('Kembali ke Beranda'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
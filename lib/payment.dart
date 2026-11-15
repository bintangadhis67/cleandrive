import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'app_state.dart';
import 'data/repository.dart';
import 'loyalty.dart';
import 'loyalty_models.dart';
import 'models.dart';
import 'orders.dart';
import 'theme.dart';
import 'widgets.dart';

// ---------- PILIH METODE PEMBAYARAN ----------
// Coins bisa dipakai sebagai potongan (1 Coin = Rp 25, maks 50% total). Total = harga - voucher - diskon membership - Coins.
class PaymentMethodScreen extends StatefulWidget {
  final String bookingId;
  const PaymentMethodScreen({super.key, required this.bookingId});
  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  bool _busy = false;
  int _coins = 0;

  Future<void> _choose(Booking b, PayMethod m, int coins) async {
    if (_busy) return;
    setState(() => _busy = true);
    final p = await guard(context, () => app.startPayment(b.id, m, coins: coins));
    if (!mounted) return;
    setState(() => _busy = false);
    if (p == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => m.isQris ? QrisPayScreen(payment: p) : EwalletPayScreen(payment: p)),
    );
  }

  Widget _summary(Booking b, int coins) {
    final pay = b.total - coins * kCoinValue;
    final est = payBandFor(pay).coins;
    return Panel(
      child: Column(children: [
        kv('Pesanan', b.code),
        kv('Layanan', b.pack.isShop ? 'Pembelian Toko' : b.pack.title),
        const Divider(height: 22),
        kv('Total Harga', rp(b.price)),
        if (b.memberDiscount > 0) kv('Diskon Membership ${b.memberLabel ?? ''}', '- ${rp(b.memberDiscount)}', valueColor: kGreen),
        if (b.discount > 0) kv('Voucher ${b.voucherCode ?? ''}', '- ${rp(b.discount)}', valueColor: kGreen),
        if (coins > 0) kv('Tukar $coins Coins', '- ${rp(coins * kCoinValue)}', valueColor: kGreen),
        const Divider(height: 22),
        Row(children: [
          const Expanded(child: Text('Total Bayar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
          Text(rp(pay), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.monetization_on_rounded, size: 18, color: kGold),
          const SizedBox(width: 6),
          Expanded(
            child: Text('Dapat +$est Coins setelah pembayaran.',
                style: const TextStyle(color: kMuted, fontSize: 12.5, height: 1.35)),
          ),
        ]),
      ]),
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
            return Scaffold(appBar: AppBar(), body: const Center(child: Text('Pesanan tidak ditemukan.')));
          }
          return Scaffold(
            appBar: AppBar(title: const Text('Pilih Metode Pembayaran')),
            body: PageList(
              bottom: 32,
              children: [
                TwoPane(
                  leftFlex: 5,
                  rightFlex: 6,
                  left: [_summary(b, _coins)],
                  right: [
                    RedeemCard(total: b.total, coins: _coins, onChanged: (v) => setState(() => _coins = v)),
                    sec('Metode Pembayaran'),
                    for (final m in PayMethod.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Panel(
                          onTap: _busy ? null : () => _choose(b, m, _coins),
                          padding: const EdgeInsets.all(12),
                          child: Row(children: [
                            PayLogo(m),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(m.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                Text(m.hint, style: const TextStyle(fontSize: 12, color: kMuted)),
                              ]),
                            ),
                            const Icon(Icons.chevron_right, color: kMuted),
                          ]),
                        ),
                      ),
                    const SizedBox(height: 6),
                    const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.info_outline, size: 15, color: kMuted),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text('Mode simulasi: tidak ada uang sungguhan yang diproses.',
                            style: TextStyle(fontSize: 12, color: kMuted)),
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
      appBar: AppBar(title: const Text('Pembayaran QRIS')),
      body: PageList(
        bottom: 32,
        children: [
          TwoPane(
            left: [
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Total Pembayaran', style: TextStyle(color: kMuted)),
                  Text(rp(_p.amount), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  kv('No. Transaksi', _p.trx),
                  kv('Metode', 'QRIS'),
                  kv('Status', expired ? 'Kedaluwarsa' : 'Menunggu pembayaran'),
                  const SizedBox(height: 6),
                  Text(expired ? 'Buat QR baru untuk melanjutkan' : 'Batas waktu pembayaran ${_mmss(left)}',
                      style: TextStyle(color: expired ? kRed : kMuted, fontWeight: FontWeight.w600)),
                ]),
              ),
            ],
            right: [
              Panel(
                child: Column(children: [
                  const Text('Scan QR Code berikut', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kLine),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('QRIS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2)),
                      const SizedBox(height: 8),
                      Opacity(
                        opacity: expired ? .25 : 1,
                        child: QrImageView(data: _p.qrString ?? _p.trx, size: 220, backgroundColor: Colors.white),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  const Text('Gunakan aplikasi e-wallet / mobile banking yang mendukung QRIS',
                      textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 13, height: 1.4)),
                  const SizedBox(height: 12),
                  Text(expired ? 'Kedaluwarsa' : _mmss(left),
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: expired ? kRed : kNavy)),
                  const SizedBox(height: 14),
                  if (expired)
                    RedButton('Buat QR Baru', busy: _busy, onPressed: _renew)
                  else
                    RedButton('Cek Pembayaran', color: kNavy, busy: _busy, onPressed: () => _check()),
                  if (_p.sandbox && !expired) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _busy ? null : _simulate,
                      icon: const Icon(Icons.science_outlined, size: 18),
                      label: const Text('Simulasikan pembayaran (mode demo)'),
                    ),
                  ],
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Pilih Metode Lain')),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
    return Scaffold(
      appBar: AppBar(title: Text('Pembayaran ${p.method.label}')),
      body: PageList(
        bottom: 32,
        children: [
          TwoPane(
            left: [
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Total Pembayaran', style: TextStyle(color: kMuted)),
                  Text(rp(p.amount), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  kv('No. Transaksi', p.trx),
                  kv('Metode', p.method.label),
                  kv('Status', 'Menunggu pembayaran'),
                  kv('Batas waktu', fmtHm.format(p.expiresAt)),
                ]),
              ),
            ],
            right: [
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Akan dibayarkan dengan', style: TextStyle(color: kMuted, fontSize: 13)),
                  const SizedBox(height: 12),
                  Row(children: [
                    PayLogo(p.method, size: 46),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.method.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        Text('${p.method.isBank ? 'Saldo rekening' : 'Saldo'} (simulasi): ${rp(balance)}',
                            style: TextStyle(fontSize: 13, color: enough ? kMuted : kRed, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Icon(enough ? Icons.check_circle_outline : Icons.error_outline, size: 17, color: enough ? kGreen : kRed),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(enough ? 'Saldo cukup untuk transaksi ini' : 'Saldo tidak cukup. Pilih metode lain.',
                          style: TextStyle(color: enough ? kMuted : kRed, fontSize: 13)),
                    ),
                  ]),
                  const SizedBox(height: 22),
                  RedButton('Bayar Sekarang', busy: _busy, onPressed: enough ? _pay : null),
                  Center(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Pilih Metode Lain'))),
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

  @override
  Widget build(BuildContext context) {
    final shop = app.byId(payment.bookingId)?.pack.isShop ?? false;
    return Scaffold(
      body: SafeArea(
        child: PageList(
          top: 24,
          bottom: 32,
          children: [
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 650),
                curve: Curves.elasticOut,
                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: kGreen),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 54),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Center(
              child: Text('Pembayaran Berhasil!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kGreen)),
            ),
            const SizedBox(height: 22),
            TwoPane(
              left: [
                Panel(
                  child: Column(children: [
                    kv('Transaksi', payment.trx, bold: true),
                    const Divider(height: 18),
                    kv('Pesanan', '#${payment.bookingId}'),
                    const Divider(height: 18),
                    kv('Metode', payment.method.label, bold: true),
                    const Divider(height: 18),
                    if (payment.coinsUsed > 0) ...[
                      const Divider(height: 18),
                      kv('Tukar ${payment.coinsUsed} Coins', '- ${rp(payment.coinDiscount)}', valueColor: kGreen),
                    ],
                    const Divider(height: 18),
                    kv('Total Pembayaran', rp(payment.amount), bold: true),
                  ]),
                ),
              ],
              right: [
                if (payment.coinsEarned > 0)
                  Panel(
                    color: const Color(0x1FE9AD35),
                    child: Row(children: [
                      const Icon(Icons.monetization_on_rounded, color: kGold, size: 38),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Kamu dapat +${payment.coinsEarned} Coins!',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          Text('Transaksi tingkat ${payBandFor(payment.amount).label} (${payBandFor(payment.amount).range}).',
                              style: const TextStyle(color: kMuted, fontSize: 12.5)),
                        ]),
                      ),
                    ]),
                  ),
                const SizedBox(height: 14),
                Text(
                  shop
                      ? 'Terima kasih, pembelianmu berhasil. Ambil barang di kasir CleanDrive.'
                      : 'Terima kasih, pesanan Anda sudah dikonfirmasi.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: kMuted),
                ),
                const SizedBox(height: 20),
                RedButton(shop ? 'Lihat Pembelian' : 'Lihat Pesanan', onPressed: () {
                  final nav = Navigator.of(context);
                  app.requestTab(1);
                  nav.popUntil((r) => r.isFirst);
                  nav.push(MaterialPageRoute(builder: (_) => DetailScreen(id: payment.bookingId)));
                }),
                Center(
                  child: TextButton(
                    onPressed: () {
                      app.requestTab(0);
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    },
                    child: const Text('Kembali ke Beranda'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
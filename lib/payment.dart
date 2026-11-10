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

// ---------- PILIH METODE PEMBAYARAN (desain layar 10) ----------
class PaymentMethodScreen extends StatefulWidget {
  final String bookingId;
  const PaymentMethodScreen({super.key, required this.bookingId});
  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  bool _busy = false;
  int _coins = 0; // Coins yang dipilih untuk ditukar jadi potongan

  /// Coins efektif: tidak melebihi batas penukaran dan minimal 10.
  int _effCoins(Booking b) {
    final max = maxRedeemCoins(total: b.total, balance: app.loyalty.balance, tier: app.loyalty.tier);
    final c = _coins > max ? max : _coins;
    return c < 10 ? 0 : c;
  }

  Future<void> _choose(Booking b, PayMethod m) async {
    if (_busy) return;
    final coins = _effCoins(b);
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

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final b = app.byId(widget.bookingId);
          if (b == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Pesanan tidak ditemukan.')));
          final coins = _effCoins(b);
          final pay = b.total - coins * kCoinValue;
          return Scaffold(
            appBar: AppBar(title: const Text('Pilih Metode Pembayaran')),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  Panel(
                    child: Column(children: [
                      Row(children: [
                        const Expanded(child: Text('Total Bayar', style: TextStyle(fontWeight: FontWeight.w800))),
                        Text(rp(pay), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                      ]),
                      if (coins > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(children: [
                            Expanded(child: Text('${rp(b.total)} dipotong $coins Coins', style: const TextStyle(color: kMuted, fontSize: 12.5))),
                            Text('- ${rp(coins * kCoinValue)}', style: const TextStyle(color: kGreen, fontWeight: FontWeight.w800, fontSize: 13)),
                          ]),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  RedeemCard(total: b.total, coins: coins, onChanged: (v) => setState(() => _coins = v)),
                  const SizedBox(height: 14),
                  for (final m in PayMethod.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Panel(
                        onTap: _busy ? null : () => _choose(b, m),
                        padding: const EdgeInsets.all(12),
                        child: Row(children: [
                          PayLogo(m),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(m.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                              Text(m.hint, style: const TextStyle(fontSize: 12, color: kMuted)),
                            ]),
                          ),
                          const Icon(Icons.chevron_right, color: kMuted),
                        ]),
                      ),
                    ),
                  const SizedBox(height: 10),
                  const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.info_outline, size: 15, color: kMuted),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text('Mode simulasi: tidak ada uang sungguhan yang diproses.',
                          style: TextStyle(fontSize: 12, color: kMuted)),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        final nav = Navigator.of(context);
                        nav.popUntil((r) => r.isFirst);
                      },
                      child: const Text('Bayar nanti'),
                    ),
                  ),
                ]),
              ),
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

// ---------- PEMBAYARAN QRIS (desain layar 11) ----------
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
    final p = await guard(context, () => app.startPayment(_p.bookingId, PayMethod.qris, coins: _p.coinsUsed));
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(padding: const EdgeInsets.all(20), children: [
            const Text('Total Pembayaran', style: TextStyle(color: kMuted)),
            Text(rp(_p.amount), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            if (_p.coinsUsed > 0)
              Text('Sudah dipotong ${_p.coinsUsed} Coins (- ${rp(_p.coinDiscount)})',
                  style: const TextStyle(color: kGreen, fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 18),
            const Center(child: Text('Scan QR Code berikut', style: TextStyle(fontWeight: FontWeight.w700))),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kLine),
                  boxShadow: const [BoxShadow(color: Color(0x140B1F44), blurRadius: 18, offset: Offset(0, 8))],
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
            ),
            const SizedBox(height: 14),
            const Text(
              'Gunakan aplikasi e-wallet / mobile banking yang mendukung QRIS',
              textAlign: TextAlign.center,
              style: TextStyle(color: kMuted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(expired ? 'Kedaluwarsa' : _mmss(left),
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: expired ? kRed : kNavy)),
            ),
            Center(child: Text(expired ? 'Buat QR baru untuk melanjutkan' : 'Waktu tersisa', style: const TextStyle(color: kMuted, fontSize: 12.5))),
            const SizedBox(height: 18),
            if (expired)
              RedButton('Buat QR Baru', busy: _busy, onPressed: _renew)
            else
              RedButton('Cek Pembayaran', color: kNavy, busy: _busy, onPressed: () => _check()),
            if (_p.sandbox && !expired) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _busy ? null : _simulate,
                  icon: const Icon(Icons.science_outlined, size: 18),
                  label: const Text('Simulasikan pembayaran (mode demo)'),
                ),
              ),
            ],
            Center(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Pilih Metode Lain'))),
          ]),
        ),
      ),
    );
  }
}

// ---------- PEMBAYARAN E-WALLET (desain layar 12) ----------
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(padding: const EdgeInsets.all(20), children: [
            const Text('Total Pembayaran', style: TextStyle(color: kMuted)),
            Text(rp(p.amount), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            if (p.coinsUsed > 0)
              Text('Sudah dipotong ${p.coinsUsed} Coins (- ${rp(p.coinDiscount)})',
                  style: const TextStyle(color: kGreen, fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 18),
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
              ]),
            ),
            const SizedBox(height: 18),
            Row(children: [
              Icon(enough ? Icons.check_circle_outline : Icons.error_outline, size: 17, color: enough ? kGreen : kRed),
              const SizedBox(width: 8),
              Expanded(
                child: Text(enough ? 'Saldo cukup untuk transaksi ini' : 'Saldo tidak cukup. Pilih metode lain.',
                    style: TextStyle(color: enough ? kMuted : kRed, fontSize: 13)),
              ),
            ]),
            const SizedBox(height: 8),
            const Row(children: [
              Icon(Icons.wifi, size: 17, color: kMuted),
              SizedBox(width: 8),
              Expanded(child: Text('Pastikan koneksi internet stabil', style: TextStyle(color: kMuted, fontSize: 13))),
            ]),
            const SizedBox(height: 26),
            RedButton('Bayar Sekarang', busy: _busy, onPressed: enough ? _pay : null),
            const SizedBox(height: 6),
            Center(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Pilih Metode Lain'))),
          ]),
        ),
      ),
    );
  }
}

// ---------- PEMBAYARAN BERHASIL (desain layar 13) ----------
class PaymentSuccessScreen extends StatelessWidget {
  final Payment payment;
  const PaymentSuccessScreen({super.key, required this.payment});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(padding: const EdgeInsets.all(24), children: [
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: kGreen),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 54),
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text('Pembayaran Berhasil!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kGreen)),
                ),
                const SizedBox(height: 24),
                Panel(
                  child: Column(children: [
                    kv('Transaksi', payment.trx, bold: true),
                    const Divider(height: 18),
                    kv('Metode', payment.method.label, bold: true),
                    const Divider(height: 18),
                    kv('Total Pembayaran', rp(payment.amount), bold: true),
                    if (payment.coinsUsed > 0) ...[
                      const Divider(height: 18),
                      kv('Potongan Coins', '- ${rp(payment.coinDiscount)} (${payment.coinsUsed} Coins)', valueColor: kGreen),
                    ],
                  ]),
                ),
                if (payment.coinsEarned > 0) ...[
                  const SizedBox(height: 14),
                  Panel(
                    color: const Color(0x1FF5B31B),
                    child: Row(children: [
                      const Icon(Icons.monetization_on_rounded, color: kGold, size: 38),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Kamu dapat +${payment.coinsEarned} Coins!', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          Text('Transaksi tingkat ${payBandFor(payment.amount).label} (${payBandFor(payment.amount).range}).',
                              style: const TextStyle(color: kMuted, fontSize: 12.5)),
                        ]),
                      ),
                    ]),
                  ),
                ],
                if (payment.levelUp != null) ...[
                  const SizedBox(height: 10),
                  Panel(
                    onTap: () => showLevelUp(context, payment.levelUp!),
                    child: Row(children: [
                      Icon(payment.levelUp!.icon, color: payment.levelUp!.color, size: 34),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Selamat, kamu naik ke ${payment.levelUp!.label}!', style: const TextStyle(fontWeight: FontWeight.w800)),
                          const Text('Ketuk untuk lihat keuntungan barumu.', style: TextStyle(color: kMuted, fontSize: 12.5)),
                        ]),
                      ),
                      const Icon(Icons.chevron_right, color: kMuted),
                    ]),
                  ),
                ],
                const SizedBox(height: 20),
                const Text('Terima kasih, pesanan Anda sudah dikonfirmasi.',
                    textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
                const SizedBox(height: 28),
                RedButton('Lihat Pesanan', onPressed: () {
                  final nav = Navigator.of(context);
                  app.requestTab(1);
                  nav.popUntil((r) => r.isFirst);
                  nav.push(MaterialPageRoute(builder: (_) => DetailScreen(id: payment.bookingId)));
                }),
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    onPressed: () {
                      app.requestTab(0);
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    },
                    child: const Text('Kembali ke Beranda'),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
}

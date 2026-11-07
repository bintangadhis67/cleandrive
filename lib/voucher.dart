import 'package:flutter/material.dart';

import 'app_state.dart';
import 'models.dart';
import 'theme.dart';
import 'widgets.dart';

/// Kartu voucher di beranda (desain layar 5).
class VoucherHomeCard extends StatelessWidget {
  const VoucherHomeCard({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final v = app.claimable;
          if (v == null) {
            final mine = app.usableVouchers;
            if (mine.isEmpty) return const SizedBox.shrink();
            return Panel(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyVouchersScreen())),
              child: Row(children: [
                const Icon(Icons.local_offer_rounded, color: kRed),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('${mine.length} voucher siap dipakai', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                const Icon(Icons.chevron_right, color: kMuted),
              ]),
            );
          }
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kLine),
              boxShadow: const [BoxShadow(color: Color(0x0F0B1F44), blurRadius: 14, offset: Offset(0, 6))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(children: [
                Positioned(
                  right: -28,
                  top: -28,
                  child: Container(width: 150, height: 150, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x2060BBE9))),
                ),
                const Positioned(right: 30, top: 22, child: Icon(Icons.percent_rounded, size: 54, color: kSky)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Voucher Spesial', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 6),
                    const Text('Diskon hingga', style: TextStyle(color: kMuted, fontSize: 12.5)),
                    Text(v.shortValue, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Expanded(
                        child: Text('Syarat & ketentuan berlaku', style: TextStyle(fontSize: 11.5, color: kMuted)),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: kNavy,
                          minimumSize: const Size(0, 42),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VoucherClaimScreen(voucher: v))),
                        child: const Text('Klaim Sekarang'),
                      ),
                    ]),
                  ]),
                ),
              ]),
            ),
          );
        },
      );
}

/// Kartu detail voucher.
class VoucherTicket extends StatelessWidget {
  final Voucher v;
  const VoucherTicket(this.v, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kLine),
          boxShadow: const [BoxShadow(color: Color(0x140B1F44), blurRadius: 18, offset: Offset(0, 8))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(v.code, style: const TextStyle(fontWeight: FontWeight.w700, color: kMuted)),
          const SizedBox(height: 8),
          Text(v.headline, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          if (v.note.isNotEmpty) Text(v.note, style: const TextStyle(color: kMuted)),
          Text('Min. transaksi ${rp(v.minTransaction)}', style: const TextStyle(color: kMuted)),
          Text('Berlaku hingga ${fmtDate.format(v.validUntil)}', style: const TextStyle(color: kMuted)),
        ]),
      );
}

Widget _terms(Voucher v) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Syarat & Ketentuan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      const SizedBox(height: 8),
      for (final t in v.terms)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(padding: EdgeInsets.only(top: 6, right: 8), child: Icon(Icons.circle, size: 5, color: kMuted)),
            Expanded(child: Text(t, style: const TextStyle(fontSize: 13, color: kMuted))),
          ]),
        ),
    ]);

void _useVoucher(BuildContext context, Voucher v) {
  final nav = Navigator.of(context);
  app.pendingVoucher = v;
  app.requestTab(2);
  nav.popUntil((r) => r.isFirst);
}

// ---------- KLAIM VOUCHER (desain layar 6) ----------
class VoucherClaimScreen extends StatefulWidget {
  final Voucher voucher;
  const VoucherClaimScreen({super.key, required this.voucher});
  @override
  State<VoucherClaimScreen> createState() => _VoucherClaimScreenState();
}

class _VoucherClaimScreenState extends State<VoucherClaimScreen> {
  late bool _claimed = widget.voucher.claimed;
  bool _busy = false;

  Future<void> _claim() async {
    setState(() => _busy = true);
    final ok = await guard(context, () async {
      await app.claim(widget.voucher);
      return true;
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok == true) _claimed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.voucher;
    return Scaffold(
      appBar: AppBar(title: const Text('Klaim Voucher')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(padding: const EdgeInsets.all(20), children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _claimed ? kGreen : kRed),
                child: Icon(_claimed ? Icons.check_rounded : Icons.local_offer_rounded, color: Colors.white, size: 36),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: _claimed
                  ? const Text.rich(TextSpan(children: [
                      TextSpan(text: 'Voucher ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                      TextSpan(text: 'berhasil diklaim!', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: kGreen)),
                    ]))
                  : const Text('Klaim voucher spesialmu', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            ),
            const SizedBox(height: 20),
            VoucherTicket(v),
            const SizedBox(height: 22),
            _terms(v),
            const SizedBox(height: 28),
            if (!_claimed)
              RedButton('Klaim Sekarang', busy: _busy, onPressed: _claim)
            else ...[
              RedButton('Gunakan Sekarang', onPressed: () => _useVoucher(context, v)),
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MyVouchersScreen())),
                  child: const Text('Lihat Voucher Saya'),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

// ---------- VOUCHER SAYA ----------
class MyVouchersScreen extends StatelessWidget {
  const MyVouchersScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Voucher Saya')),
        body: ListenableBuilder(
          listenable: app,
          builder: (context, _) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(padding: const EdgeInsets.all(16), children: [
                for (final v in app.vouchers)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(children: [
                      VoucherTicket(v),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          child: Text(
                            v.used ? 'Sudah dipakai' : (v.expired ? 'Kedaluwarsa' : (v.claimed ? 'Siap dipakai' : 'Belum diklaim')),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: v.usable ? kGreen : kMuted,
                            ),
                          ),
                        ),
                        if (!v.claimed && !v.expired)
                          FilledButton(
                            style: FilledButton.styleFrom(minimumSize: const Size(0, 40), backgroundColor: kNavy),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VoucherClaimScreen(voucher: v))),
                            child: const Text('Klaim'),
                          )
                        else if (v.usable)
                          FilledButton(
                            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                            onPressed: () => _useVoucher(context, v),
                            child: const Text('Gunakan'),
                          ),
                      ]),
                    ]),
                  ),
              ]),
            ),
          ),
        ),
      );
}

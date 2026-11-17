import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

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
                // Gambar ilustrasi voucher (menggantikan ikon % polos).
                Positioned(
                  right: 8,
                  top: 6,
                  height: 112,
                  child: IgnorePointer(child: Image.asset('assets/images/voucher_banner.png', fit: BoxFit.contain)),
                ),
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
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(v.weekly ? Icons.autorenew_rounded : Icons.looks_one_rounded, size: 15, color: kMuted),
              const SizedBox(width: 5),
              Text(v.periodLabel, style: const TextStyle(color: kMuted, fontSize: 12)),
            ]),
          ),
          if (v.minTier > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(v.locked ? Icons.lock_outline_rounded : Icons.workspace_premium_rounded, size: 16, color: kRed),
                const SizedBox(width: 5),
                Text(v.locked ? 'Terkunci • khusus member ${v.tierLabel} (beli membership)' : 'Reward member ${v.tierLabel}',
                    style: const TextStyle(color: kRed, fontWeight: FontWeight.w800, fontSize: 12.5)),
              ]),
            ),
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

/// Banner kuota klaim voucher hari ini (1x per hari, Gold 2x, Platinum 3x).
class VoucherQuotaBanner extends StatelessWidget {
  const VoucherQuotaBanner({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final q = app.quota;
          return Panel(
            color: q.reached ? const Color(0xFFFBEAEA) : const Color(0xFFEAF6F0),
            padding: const EdgeInsets.all(14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(q.reached ? Icons.hourglass_bottom_rounded : Icons.confirmation_number_outlined,
                  color: q.reached ? kRed : kGreen),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Kuota klaim hari ini: ${q.used}/${q.limit}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    q.reached
                        ? 'Kuota habis. Kembali lagi besok untuk klaim voucher lain.'
                        : 'Klaim 1 voucher per hari. Member Gold 2x sehari, Platinum 3x sehari.',
                    style: const TextStyle(color: kMuted, fontSize: 12.5, height: 1.3),
                  ),
                ]),
              ),
            ]),
          );
        },
      );
}

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
    final blocked = !_claimed && v.blockReason != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Klaim Voucher')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
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
            const SizedBox(height: 14),
            const VoucherQuotaBanner(),
            const SizedBox(height: 22),
            _terms(v),
            const SizedBox(height: 28),
            if (!_claimed)
              RedButton(
                  v.locked ? 'Khusus Member ${v.tierLabel}' : (blocked ? 'Kuota Klaim Hari Ini Habis' : 'Klaim Sekarang'),
                  busy: _busy,
                  onPressed: (v.locked || blocked) ? null : _claim)
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
class MyVouchersScreen extends StatefulWidget {
  const MyVouchersScreen({super.key});
  @override
  State<MyVouchersScreen> createState() => _MyVouchersScreenState();
}

class _MyVouchersScreenState extends State<MyVouchersScreen> {
  @override
  void initState() {
    super.initState();
    // Muat ulang agar voucher mingguan yang baru (Senin) dan kuota hari ini selalu terbaru.
    app.refreshVouchers();
  }

  String _status(Voucher v) {
    if (v.used) return 'Sudah dipakai';
    if (v.expired) return 'Kedaluwarsa';
    if (v.claimed) return 'Siap dipakai';
    if (v.locked) return 'Khusus member ${v.tierLabel}';
    if (v.blockReason != null) return 'Kuota klaim hari ini habis';
    return 'Belum diklaim';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Voucher Saya')),
        body: ListenableBuilder(
          listenable: app,
          builder: (context, _) => PageList(
            top: 16,
            onRefresh: app.refreshVouchers,
            children: [
              const VoucherQuotaBanner(),
              const SizedBox(height: 14),
              AutoGrid(minWidth: 420, gap: 14, children: [
                for (final v in app.vouchers)
                  Column(children: [
                    VoucherTicket(v),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: Text(
                          _status(v),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: v.usable ? kGreen : kMuted,
                          ),
                        ),
                      ),
                      if (v.claimable)
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
              ]),
            ],
          ),
        ),
      );
}
import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import 'reward_ui.dart';

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
                const Icon(Icons.chevron_right, color: kRed),
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
                          backgroundColor: kRed,
                          foregroundColor: Colors.white,
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

/// Kartu voucher: panel navy di kiri (ikon tiket emas) dan informasi di kanan.
/// [action] = tombol kecil di kanan atas (mis. Klaim), [statusText] = status voucher di bagian bawah.
class VoucherTicket extends StatelessWidget {
  final Voucher v;
  final Widget? action;
  final String? statusText;
  final Color? statusColor;
  const VoucherTicket(this.v, {super.key, this.action, this.statusText, this.statusColor});

  Widget _iconLine(IconData icon, String text, {Color color = kRwSub, FontWeight weight = FontWeight.w500}) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 1), child: Icon(icon, size: 16, color: kRwNavy)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 12.5, fontWeight: weight, height: 1.3))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final sc = statusColor ?? kRwSub;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: kRwShadowThin,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // ---- panel kiri navy ----
            Container(
              width: 92,
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [kRwNavyLight, kRwNavyDark]),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: kRwGold, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.percent_rounded, color: kRwNavyDark, size: 30),
                ),
                const SizedBox(height: 10),
                const Text('DISKON', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: .4)),
              ]),
            ),
            // ---- informasi kanan ----
            Expanded(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Kode voucher di kiri; tombol aksi (Klaim / Gunakan) selalu di pojok kanan atas kartu.
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: kRwGoldLight, borderRadius: BorderRadius.circular(8)),
                          child: Text(v.code,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: kRwText, fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                      ),
                    ),
                    if (action != null) ...[const SizedBox(width: 10), action!],
                  ]),
                  const SizedBox(height: 8),
                  Text(v.headline, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: kRwText, height: 1.15)),
                  if (v.note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(v.note, style: const TextStyle(color: kRwSub, fontSize: 13)),
                    ),
                  const SizedBox(height: 4),
                  Text('Min. transaksi ${rp(v.minTransaction)}', style: const TextStyle(color: kRwSub, fontSize: 13)),
                  _iconLine(Icons.calendar_month_rounded, 'Berlaku hingga ${fmtDate.format(v.validUntil)}'),
                  _iconLine(v.weekly ? Icons.autorenew_rounded : Icons.looks_one_rounded, v.periodLabel),
                  if (v.minTier > 0)
                    _iconLine(
                      v.locked ? Icons.lock_outline_rounded : Icons.workspace_premium_rounded,
                      v.locked ? 'Terkunci • khusus member ${v.tierLabel} (beli membership)' : 'Reward member ${v.tierLabel}',
                      color: v.locked ? kError : kRwGoldDark,
                      weight: FontWeight.w700,
                    ),
                  if (statusText != null) ...[
                    const SizedBox(height: 10),
                    RwPill(statusText!, bg: sc.withValues(alpha: .13), fg: sc),
                  ],
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

Widget _bullets(List<String> items) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final t in items)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(padding: EdgeInsets.only(top: 6, right: 8), child: Icon(Icons.circle, size: 5, color: kRwSub)),
            Expanded(child: Text(t, style: const TextStyle(fontSize: 13, color: kRwSub, height: 1.4))),
          ]),
        ),
    ]);

Widget _terms(Voucher v) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Syarat & Ketentuan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: kRwText)),
      const SizedBox(height: 8),
      _bullets(v.terms),
    ]);

/// Banner kuota klaim voucher hari ini (1x per hari, Gold 2x, Platinum 3x).
class VoucherQuotaBanner extends StatelessWidget {
  const VoucherQuotaBanner({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final q = app.quota;
          return RwHeroCard(
            padding: const EdgeInsets.all(18),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .10), shape: BoxShape.circle),
                child: const Icon(Icons.confirmation_number_outlined, color: kRwGold, size: 34),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text.rich(
                    TextSpan(children: [
                      const TextSpan(text: 'Kuota klaim hari ini: ', style: TextStyle(color: Colors.white)),
                      TextSpan(text: '${q.used}/${q.limit}', style: const TextStyle(color: kRwGold)),
                    ]),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    q.reached
                        ? 'Kuota habis. Kembali lagi besok untuk klaim voucher lain.'
                        : 'Klaim 1 voucher per hari. Member Gold 2x sehari, Platinum 3x sehari.',
                    style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.4),
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
      backgroundColor: kRwBg,
      appBar: AppBar(title: const Text('Klaim Voucher'), backgroundColor: kRwBg),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(padding: const EdgeInsets.all(20), children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _claimed ? kRwGreen : kRwNavy,
                  boxShadow: kRwShadow,
                ),
                child: Icon(_claimed ? Icons.check_rounded : Icons.local_offer_rounded,
                    color: _claimed ? Colors.white : kRwGold, size: 36),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: _claimed
                  ? const Text.rich(TextSpan(children: [
                      TextSpan(text: 'Voucher ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: kRwText)),
                      TextSpan(text: 'berhasil diklaim!', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: kRwGreen)),
                    ]))
                  : const Text('Klaim voucher spesialmu',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: kRwText)),
            ),
            const SizedBox(height: 20),
            VoucherTicket(v),
            const SizedBox(height: 14),
            const VoucherQuotaBanner(),
            const SizedBox(height: 22),
            RwCard(padding: const EdgeInsets.all(18), child: _terms(v)),
            const SizedBox(height: 24),
            if (!_claimed)
              RwButton(
                  v.locked ? 'Khusus Member ${v.tierLabel}' : (blocked ? 'Kuota Klaim Hari Ini Habis' : 'Klaim Sekarang'),
                  busy: _busy,
                  onPressed: (v.locked || blocked) ? null : _claim)
            else ...[
              RwButton('Gunakan Sekarang', onPressed: () => _useVoucher(context, v)),
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
  int _tab = 0; // 0 = Voucher Saya, 1 = Voucher Kedaluwarsa (hanya penyaring tampilan)

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

  Color _statusColor(Voucher v) {
    if (v.usable) return kRwGreen;
    if (v.expired) return kError;
    return kRwSub;
  }

  Widget? _action(Voucher v) {
    if (v.claimable) {
      return RwSmallButton(
        'Klaim',
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VoucherClaimScreen(voucher: v))),
      );
    }
    if (v.usable) {
      return RwSmallButton('Gunakan', onPressed: () => _useVoucher(context, v));
    }
    return null;
  }

  Widget _tabBtn(int i, String label) {
    final sel = _tab == i;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tab = i),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: sel ? kRed : Colors.transparent, width: 3)),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: .3, color: sel ? kRed : kRwSub)),
          ),
        ),
      ),
    );
  }

  Widget _tabs() => RwCard(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Row(children: [
            _tabBtn(0, 'VOUCHER SAYA'),
            _tabBtn(1, 'VOUCHER KEDALUWARSA'),
          ]),
        ),
      );

  void _showTerms() {
    final list = app.vouchers;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * .75),
          child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(20, 20, 20, 24), children: [
            const Text('Syarat & Ketentuan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kRwText)),
            const SizedBox(height: 6),
            const Text('Voucher hanya bisa digunakan sesuai syarat dan ketentuan yang tertera pada masing-masing voucher.',
                style: TextStyle(color: kRwSub, fontSize: 13, height: 1.4)),
            for (final v in list) ...[
              const SizedBox(height: 18),
              Text('${v.code} • ${v.headline}', style: const TextStyle(fontWeight: FontWeight.w800, color: kRwText)),
              const SizedBox(height: 4),
              _bullets(v.terms),
            ],
            const SizedBox(height: 20),
            RwButton('Mengerti', height: 48, onPressed: () => Navigator.pop(ctx)),
          ]),
        ),
      ),
    );
  }

  Widget _termsCard() => RwCard(
        onTap: _showTerms,
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          const RwIconBox(Icons.info_outline_rounded, size: 58, bg: kRwBlueSoft, fg: kRwNavy),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Syarat & Ketentuan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: kRwText)),
              SizedBox(height: 3),
              Text('Voucher hanya bisa digunakan sesuai syarat dan ketentuan yang tertera pada masing-masing voucher.',
                  style: TextStyle(color: kRwSub, fontSize: 12.5, height: 1.4)),
            ]),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: kRed, size: 30),
        ]),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kRwBg,
        appBar: AppBar(title: const Text('Voucher Saya'), backgroundColor: kRwBg),
        body: ListenableBuilder(
          listenable: app,
          builder: (context, _) {
            final list = [for (final v in app.vouchers) if (_tab == 0 ? !v.expired : v.expired) v];
            return PageList(
              top: 8,
              onRefresh: app.refreshVouchers,
              children: [
                const VoucherQuotaBanner(),
                const SizedBox(height: 16),
                _tabs(),
                const SizedBox(height: 16),
                if (list.isEmpty)
                  EmptyState(
                    icon: Icons.local_offer_outlined,
                    title: _tab == 0 ? 'Belum ada voucher' : 'Belum ada voucher kedaluwarsa',
                    message: _tab == 0
                        ? 'Voucher yang bisa kamu klaim dan pakai akan muncul di sini.'
                        : 'Voucher yang masa berlakunya sudah habis akan muncul di sini.',
                  )
                else
                  for (final v in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: VoucherTicket(v, action: _action(v), statusText: _status(v), statusColor: _statusColor(v)),
                    ),
                const SizedBox(height: 4),
                _termsCard(),
              ],
            );
          },
        ),
      );
}
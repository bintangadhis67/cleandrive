import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'app_state.dart';
import 'data/repository.dart';
import 'membership_models.dart';
import 'models.dart';
import 'theme.dart';
import 'widgets.dart';

// ===========================================================================
// CLEANDRIVE MEMBERSHIP (produk berbayar).
// Terpisah dari Coins: data, transaksi, dan riwayatnya sendiri.
// Dibeli langsung tanpa syarat Coins, dan tidak naik level otomatis.
// ===========================================================================

const _creamMuted = Color(0xB3F7F1E7);

/// Membuka layar Membership (dipakai beranda, akun, notifikasi).
void openMembership(BuildContext context) => Navigator.push(
      context,
      MaterialPageRoute(settings: const RouteSettings(name: 'membership'), builder: (_) => const MembershipScreen()),
    );

/// Lencana paket (Bronze / Silver / Gold / Platinum).
class TierBadge extends StatelessWidget {
  final MembershipTier tier;
  const TierBadge(this.tier, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: tier.soft, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(tier.icon, size: 16, color: tier.color),
          const SizedBox(width: 5),
          Text(tier.label, style: TextStyle(color: tier.color, fontWeight: FontWeight.w700, fontSize: 12.5)),
        ]),
      );
}

/// Chip status membership (Belum berlangganan, Menunggu pembayaran, Aktif, Kedaluwarsa, Dibatalkan).
class MembershipStatusChip extends StatelessWidget {
  final MembershipStatus status;
  const MembershipStatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: status.color.withValues(alpha: .14), borderRadius: BorderRadius.circular(20)),
        child: Text(status.label, style: TextStyle(color: status.color, fontWeight: FontWeight.w700, fontSize: 12)),
      );
}

/// Kartu membership digital.
class MembershipCard extends StatelessWidget {
  final UserMembership m;
  final String holder;
  const MembershipCard({super.key, required this.m, required this.holder});

  @override
  Widget build(BuildContext context) {
    final t = m.tier;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.color, Color.lerp(t.color, kNavy, .7)!],
        ),
        boxShadow: const [BoxShadow(color: Color(0x3310264C), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(t.icon, color: t.soft, size: 22),
                const SizedBox(width: 8),
                const Text('CleanDrive Membership', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 12.5)),
              ]),
              const SizedBox(height: 14),
              Text(t.label, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, height: 1)),
              const SizedBox(height: 4),
              Text(holder, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: QrImageView(data: 'CDMEMBER|${m.id}|${t.name}', size: 74, backgroundColor: Colors.white),
          ),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: _date('Mulai', m.startDate)),
          Expanded(child: _date('Berakhir', m.endDate)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(16)),
            child: Text(m.isActive ? 'Aktif' : 'Tidak aktif',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ]),
        if (m.isActive) ...[
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: m.remaining,
            minHeight: 6,
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            backgroundColor: Colors.white24,
          ),
          const SizedBox(height: 6),
          Text('Sisa ${m.daysLeft} hari', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ]),
    );
  }

  Widget _date(String label, DateTime? d) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11.5)),
        Text(d == null ? '-' : fmtDate.format(d), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      ]);
}

// ---------- KARTU MEMBERSHIP DI BERANDA ----------
class MembershipHomeCard extends StatelessWidget {
  const MembershipHomeCard({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final info = app.membership;
          final cur = info.current;
          final active = info.hasActive && cur != null;
          final t = cur?.tier;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kRadiusCard + 4),
              gradient: active
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [t!.color, Color.lerp(t.color, kNavy, .7)!],
                    )
                  : const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kNavySoft, kNavyDark]),
              boxShadow: const [BoxShadow(color: Color(0x2910264C), blurRadius: 18, offset: Offset(0, 8))],
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(kRadiusCard + 4),
                onTap: () => openMembership(context),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(12)),
                        child: Icon(active ? t!.icon : Icons.workspace_premium_outlined, color: kCream, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('Membership', style: TextStyle(color: kCream, fontWeight: FontWeight.w700, fontSize: 14.5)),
                      ),
                      MembershipStatusChip(info.status),
                    ]),
                    const SizedBox(height: 14),
                    if (active) ...[
                      Text(t!.label, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1)),
                      const SizedBox(height: 6),
                      Text('Aktif hingga ${fmtDate.format(cur!.endDate!)}  •  Diskon layanan ${cur.plan.discountPct}%',
                          style: const TextStyle(color: _creamMuted, fontSize: 12.5)),
                    ] else ...[
                      const Text('Dapatkan benefit eksklusif', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(
                          info.status == MembershipStatus.pending
                              ? 'Pembelian membership menunggu pembayaran.'
                              : 'Diskon layanan, prioritas booking, dan voucher eksklusif mulai ${rp(kMembershipPlans.first.price)}.',
                          style: const TextStyle(color: _creamMuted, fontSize: 12.5, height: 1.35)),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: kCream, foregroundColor: kNavy, minimumSize: const Size(0, 46)),
                        onPressed: () => openMembership(context),
                        child: const Text('Lihat Membership'),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          );
        },
      );
}

// ---------- LAYAR MEMBERSHIP ----------
class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});
  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  @override
  void initState() {
    super.initState();
    app.refreshMeta();
  }

  void _detail(MembershipTier t) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => MembershipPlanDetailScreen(tier: t)));

  void _checkout(MembershipTier t) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => MembershipCheckoutScreen(tier: t)));

  Widget _statusPanel(MembershipInfo info) {
    final cur = info.current;
    if (info.hasActive && cur != null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        MembershipCard(m: cur, holder: app.user ?? ''),
        const SizedBox(height: 12),
        RedButton('Perpanjang Membership', icon: Icons.autorenew_rounded, onPressed: () => _checkout(cur.tier)),
      ]);
    }
    final pending = info.pending;
    if (pending != null && !pending.expired) {
      return Panel(
        color: const Color(0x1FE9A23B),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.schedule_rounded, color: kWarn),
            SizedBox(width: 10),
            Expanded(child: Text('Menunggu pembayaran', style: TextStyle(fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 4),
          Text('Membership ${pending.plan.name} • ${rp(pending.amount)} via ${pending.method.label}',
              style: const TextStyle(color: kMuted, fontSize: 13)),
          const SizedBox(height: 12),
          RedButton('Lanjutkan Pembayaran',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MembershipPayScreen(order: pending)))),
          Center(
            child: TextButton(
              onPressed: () async {
                final ok = await guard(context, () async {
                  await app.cancelMembershipOrder(pending.id);
                  return true;
                });
                if (ok == true && mounted) toast(context, 'Pesanan membership dibatalkan');
              },
              child: const Text('Batalkan Pesanan'),
            ),
          ),
        ]),
      );
    }
    final s = info.status;
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.workspace_premium_outlined, size: 30, color: kNavy),
          const SizedBox(width: 12),
          const Expanded(child: Text('Status Membership', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
          MembershipStatusChip(s),
        ]),
        const SizedBox(height: 10),
        Text(
          switch (s) {
            MembershipStatus.expired => 'Membership ${cur?.tier.label ?? ''} kamu sudah kedaluwarsa. Beli lagi untuk mendapatkan benefit.',
            MembershipStatus.cancelled => 'Pembelian membership dibatalkan. Pilih paket lagi kapan saja.',
            _ => 'Kamu belum berlangganan. Pilih paket di bawah untuk mendapatkan diskon layanan, prioritas booking, dan voucher eksklusif.',
          },
          style: const TextStyle(color: kMuted, height: 1.4),
        ),
        const SizedBox(height: 10),
        const Text('Membership dibeli langsung tanpa perlu Coins dan tidak naik level otomatis.',
            style: TextStyle(color: kMuted, fontSize: 12.5)),
      ]),
    );
  }

  Widget _planCard(MembershipPlan p, MembershipInfo info) {
    final isCurrent = info.hasActive && info.current!.tier == p.tier;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: isCurrent || p.popular ? p.tier.color : kLine, width: isCurrent || p.popular ? 2 : 1),
        boxShadow: kShadowSoft,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: p.tier.soft, shape: BoxShape.circle),
            child: Icon(p.tier.icon, color: p.tier.color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17))),
          if (isCurrent)
            const MembershipStatusChip(MembershipStatus.active)
          else if (p.popular)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(8)),
              child: const Text('Populer', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700)),
            ),
        ]),
        const SizedBox(height: 12),
        Text(rp(p.price), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kNavy)),
        Text('/ ${p.durationLabel}', style: const TextStyle(color: kMuted, fontSize: 12.5)),
        const SizedBox(height: 10),
        for (final b in p.benefits.take(3))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.check_circle_rounded, size: 16, color: kGreen),
              const SizedBox(width: 8),
              Expanded(child: Text(b, style: const TextStyle(fontSize: 12.5, height: 1.3))),
            ]),
          ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44), padding: EdgeInsets.zero),
              onPressed: () => _detail(p.tier),
              child: const Text('Lihat Detail', style: TextStyle(fontSize: 13)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44), padding: EdgeInsets.zero),
              onPressed: () => _checkout(p.tier),
              child: Text(isCurrent ? 'Perpanjang' : 'Pilih Paket', style: const TextStyle(fontSize: 13)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _compareTable(MembershipInfo info) {
    TableRow row(String label, String Function(MembershipPlan) v, {bool bold = false}) => TableRow(children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            child: Text(label, style: const TextStyle(color: kMuted, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          for (final p in kMembershipPlans)
            Container(
              color: info.hasActive && info.current!.tier == p.tier ? p.tier.soft.withValues(alpha: .45) : null,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Text(v(p),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: 13)),
            ),
        ]);

    return Panel(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth < 620 ? 620.0 : c.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: w,
            child: Table(
              columnWidths: const {0: FlexColumnWidth(1.5)},
              defaultColumnWidth: const FlexColumnWidth(1),
              border: const TableBorder(horizontalInside: BorderSide(color: kLine)),
              children: [
                TableRow(children: [
                  const SizedBox(),
                  for (final p in kMembershipPlans)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(children: [
                        Icon(p.tier.icon, color: p.tier.color, size: 22),
                        Text(p.name, style: TextStyle(fontWeight: FontWeight.w800, color: p.tier.color)),
                      ]),
                    ),
                ]),
                row('Harga', (p) => rp(p.price), bold: true),
                row('Durasi', (p) => p.durationLabel),
                row('Diskon layanan', (p) => '${p.discountPct}%'),
                row('Prioritas booking', (p) => p.priority),
                row('Promo eksklusif', (p) => p.promo),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _history(MembershipInfo info) {
    if (info.history.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Belum ada transaksi membership',
        message: 'Riwayat pembelian dan perpanjangan membership muncul di sini, terpisah dari riwayat Coins.',
      );
    }
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(children: [
        for (var i = 0; i < info.history.length; i++) ...[
          if (i > 0) const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: info.history[i].tier.soft, borderRadius: BorderRadius.circular(11)),
                child: Icon(info.history[i].tier.icon, size: 19, color: info.history[i].tier.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${info.history[i].renewal ? 'Perpanjangan' : 'Pembelian'} ${info.history[i].tier.label}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                  Text('${info.history[i].trx} • ${fmtDate.format(info.history[i].createdAt)}',
                      style: const TextStyle(color: kMuted, fontSize: 11.5)),
                ]),
              ),
              Text(rp(info.history[i].amount), style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
          ),
        ],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Membership')),
        body: ListenableBuilder(
          listenable: app,
          builder: (context, _) {
            final info = app.membership;
            return PageList(
              onRefresh: app.refreshMeta,
              bottom: 32,
              children: [
                TwoPane(
                  leftFlex: 4,
                  rightFlex: 7,
                  left: [
                    _statusPanel(info),
                    sec('Riwayat Transaksi Membership'),
                    _history(info),
                  ],
                  right: [
                    sec('Pilih Paket', top: 0),
                    AutoGrid(minWidth: 250, children: [for (final p in kMembershipPlans) _planCard(p, info)]),
                    sec('Perbandingan Paket'),
                    _compareTable(info),
                    const SizedBox(height: 10),
                    const Text('Harga dan benefit adalah data contoh dan dapat diubah administrator.',
                        style: TextStyle(color: kMuted, fontSize: 12)),
                  ],
                ),
              ],
            );
          },
        ),
      );
}

// ---------- DETAIL PAKET ----------
class MembershipPlanDetailScreen extends StatelessWidget {
  final MembershipTier tier;
  const MembershipPlanDetailScreen({super.key, required this.tier});

  @override
  Widget build(BuildContext context) {
    final p = planOf(tier);
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final renew = app.membership.hasActive && app.membership.current!.tier == tier;
        return Scaffold(
          appBar: AppBar(title: Text('Membership ${p.name}')),
          body: PageList(
            bottom: 24,
            children: [
              TwoPane(
                left: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [p.tier.color, Color.lerp(p.tier.color, kNavy, .7)!],
                      ),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(p.tier.icon, color: p.tier.soft, size: 38),
                      const SizedBox(height: 10),
                      Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      Text(rp(p.price), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                      Text('untuk ${p.durationLabel}', style: const TextStyle(color: Colors.white70)),
                    ]),
                  ),
                  sec('Ringkasan'),
                  Panel(
                    child: Column(children: [
                      kv('Durasi', p.durationLabel),
                      kv('Diskon layanan', '${p.discountPct}%'),
                      kv('Prioritas booking', p.priority),
                      kv('Promo eksklusif', p.promo),
                    ]),
                  ),
                ],
                right: [
                  sec('Benefit', top: 0),
                  Panel(
                    child: Column(children: [
                      for (final b in p.benefits)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Icon(Icons.check_circle_rounded, size: 19, color: kGreen),
                            const SizedBox(width: 10),
                            Expanded(child: Text(b, style: const TextStyle(height: 1.3))),
                          ]),
                        ),
                    ]),
                  ),
                  sec('Syarat & Ketentuan'),
                  Panel(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      for (final t in const [
                        'Diskon membership berlaku untuk jasa layanan (cuci dan ganti oli), tidak untuk produk toko.',
                        'Membership aktif setelah pembayaran berhasil dan berlaku selama durasi paket.',
                        'Membership tidak diperpanjang otomatis. Perpanjang kapan saja sebelum atau sesudah berakhir.',
                        'Membership dibeli dengan pembayaran, tidak memerlukan Coins, dan Coins tidak bisa dipakai untuk membelinya.',
                      ])
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Padding(padding: EdgeInsets.only(top: 6, right: 8), child: Icon(Icons.circle, size: 5, color: kMuted)),
                            Expanded(child: Text(t, style: const TextStyle(fontSize: 13, color: kMuted, height: 1.35))),
                          ]),
                        ),
                    ]),
                  ),
                ],
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: EdgeInsets.fromLTRB(pagePad(MediaQuery.sizeOf(context).width), 12, pagePad(MediaQuery.sizeOf(context).width), 12),
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: kLine))),
            child: SafeArea(
              top: false,
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(rp(p.price), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    Text(p.durationLabel, style: const TextStyle(color: kMuted, fontSize: 12.5)),
                  ]),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 26)),
                  onPressed: () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => MembershipCheckoutScreen(tier: tier))),
                  child: Text(renew ? 'Perpanjang Membership' : 'Beli Membership'),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}

// ---------- CHECKOUT MEMBERSHIP ----------
class MembershipCheckoutScreen extends StatefulWidget {
  final MembershipTier tier;
  const MembershipCheckoutScreen({super.key, required this.tier});
  @override
  State<MembershipCheckoutScreen> createState() => _MembershipCheckoutScreenState();
}

class _MembershipCheckoutScreenState extends State<MembershipCheckoutScreen> {
  bool _busy = false;

  Future<void> _pay(PayMethod m) async {
    if (_busy) return;
    setState(() => _busy = true);
    final o = await guard(context, () => app.startMembershipPurchase(widget.tier, m));
    if (!mounted) return;
    setState(() => _busy = false);
    if (o == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => MembershipPayScreen(order: o)));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final p = planOf(widget.tier);
          final info = app.membership;
          final cur = info.current;
          final renew = info.hasActive && cur!.tier == widget.tier;
          final replace = info.hasActive && cur!.tier != widget.tier;
          final start = renew ? cur!.endDate! : DateTime.now();
          final end = start.add(Duration(days: p.durationDays));
          return Scaffold(
            appBar: AppBar(title: Text(renew ? 'Perpanjang Membership' : 'Checkout Membership')),
            body: PageList(
              bottom: 32,
              children: [
                TwoPane(
                  leftFlex: 5,
                  rightFlex: 6,
                  left: [
                    Panel(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(color: p.tier.soft, shape: BoxShape.circle),
                            child: Icon(p.tier.icon, color: p.tier.color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Membership ${p.name}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                              Text(p.durationLabel, style: const TextStyle(color: kMuted)),
                            ]),
                          ),
                        ]),
                        const Divider(height: 24),
                        kv('Mulai', fmtDate.format(start)),
                        kv('Berakhir', fmtDate.format(end)),
                        kv('Diskon layanan', '${p.discountPct}%'),
                        const Divider(height: 24),
                        Row(children: [
                          const Expanded(child: Text('Total Bayar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                          Text(rp(p.price), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                        ]),
                      ]),
                    ),
                    if (replace) ...[
                      const SizedBox(height: 12),
                      Panel(
                        color: const Color(0x1FE9A23B),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Icon(Icons.info_outline_rounded, color: kWarn),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Membership ${cur!.tier.label} yang masih aktif sampai ${fmtDate.format(cur.endDate!)} akan diganti paket ${p.name} mulai hari ini.',
                              style: const TextStyle(fontSize: 13, height: 1.35),
                            ),
                          ),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.info_outline, size: 15, color: kMuted),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text('Harga membership tidak dapat dipotong dengan Coins. Mode simulasi: tidak ada uang sungguhan yang diproses.',
                            style: TextStyle(fontSize: 12, color: kMuted, height: 1.35)),
                      ),
                    ]),
                  ],
                  right: [
                    sec('Metode Pembayaran', top: 0),
                    for (final m in PayMethod.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Panel(
                          onTap: _busy ? null : () => _pay(m),
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
                            _busy
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: kRed))
                                : const Icon(Icons.chevron_right, color: kMuted),
                          ]),
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

// ---------- PEMBAYARAN MEMBERSHIP (QRIS / e-wallet) ----------
class MembershipPayScreen extends StatefulWidget {
  final MembershipOrder order;
  const MembershipPayScreen({super.key, required this.order});
  @override
  State<MembershipPayScreen> createState() => _MembershipPayScreenState();
}

class _MembershipPayScreenState extends State<MembershipPayScreen> {
  late MembershipOrder _o = widget.order;
  Timer? _tick, _poll;
  bool _busy = false, _done = false;

  @override
  void initState() {
    super.initState();
    if (_o.method.isQris) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
      _poll = Timer.periodic(const Duration(seconds: 3), (_) => _check(silent: true));
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _poll?.cancel();
    super.dispose();
  }

  String _mmss(Duration d) {
    final s = d.inSeconds < 0 ? 0 : d.inSeconds;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _finish(MembershipOrder o) async {
    if (_done) return;
    _done = true;
    _tick?.cancel();
    _poll?.cancel();
    await app.refreshAll();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MembershipSuccessScreen(order: o)));
  }

  Future<void> _check({bool silent = false}) async {
    try {
      final o = await app.membershipOrder(_o.id);
      if (!mounted) return;
      setState(() => _o = o);
      if (o.paid) {
        await _finish(o);
      } else if (!silent) {
        toast(context, o.expired ? 'QR sudah kedaluwarsa.' : 'Pembayaran belum diterima.');
      }
    } on ApiException catch (e) {
      if (!silent && mounted) toast(context, e.message, error: true);
    }
  }

  Future<void> _simulate() async {
    setState(() => _busy = true);
    final o = await guard(context, () => app.simulateMembershipQris(_o.id));
    if (!mounted) return;
    setState(() => _busy = false);
    if (o != null) await _finish(o);
  }

  Future<void> _payWallet() async {
    setState(() => _busy = true);
    final o = await guard(context, () => app.confirmMembershipPayment(_o.id));
    if (!mounted) return;
    setState(() => _busy = false);
    if (o != null) await _finish(o);
  }

  Future<void> _renewQr() async {
    setState(() => _busy = true);
    final o = await guard(context, () => app.startMembershipPurchase(_o.tier, _o.method));
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (o != null) _o = o;
    });
  }

  Future<void> _cancel() async {
    final ok = await guard(context, () async {
      await app.cancelMembershipOrder(_o.id);
      return true;
    });
    if (ok == true && mounted) {
      toast(context, 'Pesanan membership dibatalkan');
      Navigator.pop(context);
    }
  }

  Widget _summary() => Panel(
        child: Column(children: [
          kv('Paket', 'Membership ${_o.plan.name}'),
          kv('Durasi', _o.plan.durationLabel),
          kv('Metode', _o.method.label),
          kv('No. Transaksi', _o.trx),
          const Divider(height: 22),
          Row(children: [
            const Expanded(child: Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.w800))),
            Text(rp(_o.amount), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
          ]),
        ]),
      );

  Widget _qris() {
    final left = _o.expiresAt.difference(DateTime.now());
    final expired = _o.expired;
    return Panel(
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
              child: QrImageView(data: _o.qrString ?? _o.trx, size: 210, backgroundColor: Colors.white),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        const Text('Gunakan aplikasi e-wallet / mobile banking yang mendukung QRIS',
            textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 13, height: 1.4)),
        const SizedBox(height: 12),
        Text(expired ? 'Kedaluwarsa' : _mmss(left),
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: expired ? kRed : kNavy)),
        Text(expired ? 'Buat QR baru untuk melanjutkan' : 'Batas waktu pembayaran', style: const TextStyle(color: kMuted, fontSize: 12.5)),
        const SizedBox(height: 16),
        if (expired)
          RedButton('Buat QR Baru', busy: _busy, onPressed: _renewQr)
        else
          RedButton('Cek Pembayaran', color: kNavy, busy: _busy, onPressed: () => _check()),
        if (_o.sandbox && !expired) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _busy ? null : _simulate,
            icon: const Icon(Icons.science_outlined, size: 18),
            label: const Text('Simulasikan pembayaran (mode demo)'),
          ),
        ],
      ]),
    );
  }

  Widget _wallet() {
    final balance = _o.balance ?? 0;
    final enough = balance >= _o.amount;
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Akan dibayarkan dengan', style: TextStyle(color: kMuted, fontSize: 13)),
        const SizedBox(height: 12),
        Row(children: [
          PayLogo(_o.method, size: 46),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_o.method.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Text('${_o.method.isBank ? 'Saldo rekening' : 'Saldo'} (simulasi): ${rp(balance)}',
                  style: TextStyle(fontSize: 13, color: enough ? kMuted : kRed, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Icon(enough ? Icons.check_circle_outline : Icons.error_outline, size: 17, color: enough ? kGreen : kRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(enough ? 'Saldo cukup untuk transaksi ini' : 'Saldo tidak cukup. Pilih metode lain.',
                style: TextStyle(color: enough ? kMuted : kRed, fontSize: 13)),
          ),
        ]),
        const SizedBox(height: 18),
        RedButton('Bayar Sekarang', busy: _busy, onPressed: enough ? _payWallet : null),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Bayar ${_o.method.label}')),
        body: PageList(
          bottom: 32,
          children: [
            TwoPane(
              left: [_summary()],
              right: [
                _o.method.isQris ? _qris() : _wallet(),
                const SizedBox(height: 6),
                Center(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Pilih Metode Lain'))),
                Center(
                  child: TextButton(
                    style: TextButton.styleFrom(foregroundColor: kError),
                    onPressed: _cancel,
                    child: const Text('Batalkan Pesanan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

// ---------- MEMBERSHIP BERHASIL ----------
class MembershipSuccessScreen extends StatelessWidget {
  final MembershipOrder order;
  const MembershipSuccessScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final cur = app.membership.current;
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
            Center(
              child: Text(order.renewal ? 'Membership Diperpanjang!' : 'Membership Aktif!',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kGreen)),
            ),
            const SizedBox(height: 22),
            TwoPane(
              left: [
                if (cur != null) MembershipCard(m: cur, holder: app.user ?? ''),
              ],
              right: [
                Panel(
                  child: Column(children: [
                    kv('No. Transaksi', order.trx, bold: true),
                    kv('Paket', 'Membership ${order.plan.name}'),
                    kv('Metode', order.method.label),
                    kv('Total Pembayaran', rp(order.amount), bold: true),
                    if (cur?.startDate != null) kv('Mulai', fmtDate.format(cur!.startDate!)),
                    if (cur?.endDate != null) kv('Berakhir', fmtDate.format(cur!.endDate!)),
                  ]),
                ),
                const SizedBox(height: 18),
                RedButton('Lihat Membership', onPressed: () {
                  final nav = Navigator.of(context);
                  nav.popUntil((r) => r.isFirst);
                  nav.push(MaterialPageRoute(
                      settings: const RouteSettings(name: 'membership'), builder: (_) => const MembershipScreen()));
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
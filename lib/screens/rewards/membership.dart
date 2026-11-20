import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/membership_models.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import 'reward_ui.dart';

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

/// Kartu membership digital (desain Modern Clean Blue & Gold).
/// Data tetap dari [UserMembership]; QR Code memakai data yang sama seperti sebelumnya.
class MembershipCard extends StatelessWidget {
  final UserMembership m;
  final String holder;
  const MembershipCard({super.key, required this.m, required this.holder});

  @override
  Widget build(BuildContext context) {
    final t = m.tier;
    final accent = rwTierOnDark(t);
    return RwHeroCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.military_tech_rounded, color: accent, size: 22),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text('Status Membership',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
                ),
              ]),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(t.label.toUpperCase(),
                        style: TextStyle(color: accent, fontSize: 36, fontWeight: FontWeight.w800, height: 1)),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(t.icon, color: accent, size: 24),
              ]),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'Clean', style: TextStyle(color: Colors.white)),
                  TextSpan(text: 'Drive', style: TextStyle(color: accent)),
                ]),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              if (holder.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(holder,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                ),
            ]),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: QrImageView(data: 'CDMEMBER|${m.id}|${t.name}', size: 74, backgroundColor: Colors.white),
          ),
        ]),
        const SizedBox(height: 18),
        Wrap(spacing: 22, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.end, children: [
          _date('Berlaku sejak', m.startDate),
          _date('Berlaku hingga', m.endDate),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(16)),
            child: Text(m.isActive ? (m.cancelAtEnd ? 'Tidak diperpanjang' : 'Aktif') : 'Tidak aktif',
                style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ]),
        if (m.isActive) ...[
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: m.remaining,
            minHeight: 7,
            borderRadius: BorderRadius.circular(8),
            color: accent,
            backgroundColor: Colors.white24,
          ),
          const SizedBox(height: 8),
          Text('Sisa ${m.daysLeft} hari masa aktif', style: const TextStyle(color: Colors.white, fontSize: 12.5)),
          if (m.plan.hasFreeWash)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('Cuci gratis tersisa ${m.freeLeft} dari ${m.freeTotal}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
            ),
        ],
      ]),
    );
  }

  Widget _date(String label, DateTime? d) => Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 2),
        Text(d == null ? '-' : fmtDate.format(d), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
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
                      Text('Aktif hingga ${fmtDate.format(cur.endDate!)}  •  Diskon layanan ${cur.plan.discountPct}%',
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
                        style: FilledButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white, minimumSize: const Size(0, 46)),
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
  /// Paket yang sedang dilihat detailnya (hanya tampilan; tidak mengubah data).
  MembershipTier? _picked;

  @override
  void initState() {
    super.initState();
    app.refreshMeta();
  }

  void _detail(MembershipTier t) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => MembershipPlanDetailScreen(tier: t)));

  void _checkout(MembershipTier t) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => MembershipCheckoutScreen(tier: t)));

  Widget _benefitRow(IconData icon, String label, String value, {Color? valueColor}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          RwIconBox(icon, size: 38),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Text(label, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: kRwText)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: valueColor ?? kRwText, height: 1.25)),
          ),
        ]),
      );

  /// Ringkasan benefit aktif: sisa cuci gratis, status minggu ini, makanan/minuman, VIP, kuota klaim voucher.
  Widget _benefitPanel(UserMembership cur) {
    final p = cur.plan;
    return RwCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.workspace_premium_outlined, color: kRwNavy, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Benefit ${cur.tier.label}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5, color: kRwText)),
          ),
        ]),
        const SizedBox(height: 8),
        if (p.hasFreeWash) ...[
          _benefitRow(Icons.local_car_wash_rounded, 'Cuci gratis', '${p.freePackage} Wash • ${p.freeVehiclesLabel}'),
          _benefitRow(Icons.confirmation_number_outlined, 'Sisa jatah', '${cur.freeLeft} dari ${cur.freeTotal}'),
          _benefitRow(Icons.event_available_rounded, 'Minggu ini',
              cur.freeUsedThisWeek ? 'Sudah terpakai' : 'Tersedia (1x per minggu)',
              valueColor: cur.freeUsedThisWeek ? kRwSub : kRwGreen),
        ],
        _benefitRow(Icons.local_offer_outlined, 'Diskon layanan', '${p.discountPct}%'),
        for (final perk in p.visitPerks) _benefitRow(Icons.redeem_rounded, 'Kunjungan', perk),
        _benefitRow(Icons.bolt_rounded, 'Prioritas booking', p.priority),
        _benefitRow(Icons.card_giftcard_rounded, 'Klaim voucher', '${cur.tier.dailyVoucherLimit}x per hari'),
      ]),
    );
  }

  Future<void> _cancelSubscription(UserMembership cur) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan langganan?'),
        content: Text(
          'Membership ${cur.tier.label} akan langsung berakhir dan seluruh benefitnya hilang. '
          'Uang pembayaranmu akan dikembalikan otomatis.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tidak')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya, Batalkan')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final refund = await guard(context, () => app.cancelMembership());
    if (refund != null && mounted) toast(context, 'Langganan dibatalkan. Dana ${rp(refund)} dikembalikan.');
  }

  Widget _statusPanel(MembershipInfo info) {
    final cur = info.current;
    if (info.hasActive && cur != null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        MembershipCard(m: cur, holder: app.user ?? ''),
        const SizedBox(height: 14),
        _benefitPanel(cur),
        const SizedBox(height: 14),
        RwButton('Perpanjang Membership', icon: Icons.autorenew_rounded, onPressed: () => _checkout(cur.tier)),
        const SizedBox(height: 10),
        if (cur.cancelAtEnd)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(
              'Langganan dibatalkan. Benefit tetap aktif sampai ${fmtDate.format(cur.endDate!)}, lalu tidak diperpanjang. Perpanjang kapan saja bila ingin lanjut.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: kRwSub, fontSize: 12.5, height: 1.4),
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Perpanjang sebelum ${fmtDate.format(cur.endDate!)},\nuntuk tetap menikmati semua keuntungan ${cur.tier.label}.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: kRwSub, fontSize: 12.5, height: 1.4),
            ),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () => _cancelSubscription(cur),
            icon: const Icon(Icons.cancel_outlined, size: 18, color: kRed),
            label: const Text('Batalkan Langganan', style: TextStyle(color: kRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ]);
    }
    final pending = info.pending;
    if (pending != null && !pending.expired) {
      return RwCard(
        color: kRwGoldLight,
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.schedule_rounded, color: kRwGoldDark),
            SizedBox(width: 10),
            Expanded(child: Text('Menunggu pembayaran', style: TextStyle(fontWeight: FontWeight.w800, color: kRwText))),
          ]),
          const SizedBox(height: 6),
          Text('Membership ${pending.plan.name} • ${rp(pending.amount)} via ${pending.method.label}',
              style: const TextStyle(color: kRwSub, fontSize: 13)),
          const SizedBox(height: 14),
          RwButton('Lanjutkan Pembayaran',
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
    return RwHeroCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.military_tech_rounded, size: 28, color: kRwGold),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Status Membership', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
          ),
          MembershipStatusChip(s),
        ]),
        const SizedBox(height: 12),
        Text(
          switch (s) {
            MembershipStatus.expired => 'Membership ${cur?.tier.label ?? ''} kamu sudah kedaluwarsa. Beli lagi untuk mendapatkan benefit.',
            MembershipStatus.cancelled => 'Pembelian membership dibatalkan. Pilih paket lagi kapan saja.',
            _ => 'Kamu belum berlangganan. Pilih paket di bawah untuk mendapatkan diskon layanan, prioritas booking, dan voucher eksklusif.',
          },
          style: const TextStyle(color: Colors.white, height: 1.45, fontSize: 13.5),
        ),
        const SizedBox(height: 10),
        const Text('Membership dibeli langsung tanpa perlu Coins dan tidak naik level otomatis.',
            style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4)),
      ]),
    );
  }

  /// Kartu pilihan paket. Menekan kartu menampilkan detail paket di bawah daftar.
  Widget _planTile(MembershipPlan p, MembershipInfo info, MembershipTier selected) {
    final isCurrent = info.hasActive && info.current!.tier == p.tier;
    final isSel = selected == p.tier;
    return RwCard(
      onTap: () => setState(() => _picked = p.tier),
      borderColor: isCurrent ? kRwGold : (isSel ? kRed.withValues(alpha: .6) : null),
      borderWidth: isCurrent ? 1.8 : 1.4,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(children: [
        RwTierMedal(p.tier, size: 58),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(p.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kRwText)),
              ),
              if (!isCurrent && p.popular) ...[
                const SizedBox(width: 8),
                const RwPill('Populer', bg: kRwGoldLight, fg: kRwGoldDark),
              ],
            ]),
            Text(rp(p.price), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kRwText, height: 1.2)),
            Text('/ ${p.durationLabel}', style: const TextStyle(fontSize: 13, color: kRwSub)),
          ]),
        ),
        const SizedBox(width: 8),
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (isCurrent) ...[
            const RwPill('Aktif', bg: kRwGold, fg: Color(0xFF5A3A00)),
            const SizedBox(height: 4),
          ],
          const Icon(Icons.chevron_right_rounded, color: kRed, size: 30),
        ]),
      ]),
    );
  }

  /// Detail paket terpilih: harga, durasi, daftar keuntungan, tombol Lihat Detail dan Pilih Paket.
  Widget _planDetail(MembershipPlan p, MembershipInfo info) {
    final isCurrent = info.hasActive && info.current!.tier == p.tier;
    return RwCard(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          RwTierMedal(p.tier, size: 50),
          const SizedBox(width: 12),
          Expanded(child: Text(p.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kRwText))),
        ]),
        const SizedBox(height: 14),
        Text(rp(p.price), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: kRwText, height: 1.1)),
        Text('/ ${p.durationLabel}', style: const TextStyle(fontSize: 15, color: kRwSub)),
        const SizedBox(height: 14),
        for (final b in p.benefits)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(padding: EdgeInsets.only(top: 1), child: Icon(Icons.check_circle_rounded, size: 20, color: kRwGreen)),
              const SizedBox(width: 10),
              Expanded(child: Text(b, style: const TextStyle(fontSize: 14.5, height: 1.3, color: kRwText))),
            ]),
          ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: RwButton('Lihat Detail', outlined: true, height: 48, onPressed: () => _detail(p.tier))),
          const SizedBox(width: 12),
          Expanded(child: RwButton(isCurrent ? 'Perpanjang' : 'Pilih Paket', height: 48, onPressed: () => _checkout(p.tier))),
        ]),
      ]),
    );
  }

  Widget _compareTable(MembershipInfo info) {
    const labelW = 128.0;
    const minColW = 124.0;

    return RwCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LayoutBuilder(builder: (context, c) {
          final colW = ((c.maxWidth - labelW) / kMembershipPlans.length).clamp(minColW, 400.0).toDouble();
          final total = labelW + colW * kMembershipPlans.length;

          bool isCur(MembershipPlan p) => info.hasActive && info.current!.tier == p.tier;

          TableRow row(String label, String Function(MembershipPlan) v, {bool bold = false}) => TableRow(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  child: Text(label, style: const TextStyle(color: kRwSub, fontWeight: FontWeight.w500, fontSize: 12.5, height: 1.3)),
                ),
                for (final p in kMembershipPlans)
                  Container(
                    color: isCur(p) ? rwTierSoft(p.tier).withValues(alpha: .5) : null,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    child: Text(v(p),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: kRwText, height: 1.3)),
                  ),
              ]);

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: total,
              child: Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                columnWidths: {
                  0: const FixedColumnWidth(labelW),
                  for (var i = 1; i <= kMembershipPlans.length; i++) i: FixedColumnWidth(colW),
                },
                border: const TableBorder(
                  horizontalInside: BorderSide(color: kRwLine),
                  verticalInside: BorderSide(color: kRwLine),
                ),
                children: [
                  TableRow(children: [
                    const SizedBox(height: 92),
                    for (final p in kMembershipPlans)
                      Container(
                        color: isCur(p) ? rwTierSoft(p.tier).withValues(alpha: .5) : null,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          RwTierMedal(p.tier, size: 42),
                          const SizedBox(height: 6),
                          Text(p.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: rwTierColor(p.tier))),
                        ]),
                      ),
                  ]),
                  row('Harga', (p) => rp(p.price), bold: true),
                  row('Durasi', (p) => p.durationLabel),
                  row('Cuci gratis', (p) => p.hasFreeWash ? '${p.freeWashQuota}x ${p.freePackage}\n(${p.freeVehiclesLabel})\nmaks. 1x/minggu' : '-'),
                  row('Makanan & minuman', (p) => p.snack ? 'Gratis' : '-'),
                  row('Ruang tunggu VIP', (p) => p.vip ? 'Ya' : '-'),
                  row('Kursi pijat', (p) => p.massage ? 'Ya' : '-'),
                  row('Klaim voucher', (p) => '${p.tier.dailyVoucherLimit}x / hari'),
                  row('Diskon layanan', (p) => '${p.discountPct}%'),
                  row('Prioritas booking', (p) => p.priority),
                  row('Promo eksklusif', (p) => p.promo),
                ],
              ),
            ),
          );
        }),
      ),
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
    return RwCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(children: [
        for (var i = 0; i < info.history.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: kRwLine),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [
              RwTierMedal(info.history[i].tier, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${info.history[i].refund ? 'Pengembalian dana' : (info.history[i].renewal ? 'Perpanjangan' : 'Pembelian')} ${info.history[i].tier.label}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: kRwText)),
                  Text('${info.history[i].trx} • ${fmtDate.format(info.history[i].createdAt)}',
                      style: const TextStyle(color: kRwSub, fontSize: 11.5)),
                ]),
              ),
              Text(info.history[i].refund ? '+${rp(info.history[i].amount)}' : rp(info.history[i].amount),
                  style: TextStyle(fontWeight: FontWeight.w800, color: info.history[i].refund ? kGreen : kRwText)),
            ]),
          ),
        ],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kRwBg,
        appBar: AppBar(title: const Text('Membership'), backgroundColor: kRwBg),
        body: ListenableBuilder(
          listenable: app,
          builder: (context, _) {
            final info = app.membership;
            final selected = _picked ??
                (info.hasActive && info.current != null
                    ? info.current!.tier
                    : kMembershipPlans.firstWhere((p) => p.popular, orElse: () => kMembershipPlans.first).tier);
            return PageList(
              onRefresh: app.refreshMeta,
              bottom: 32,
              children: [
                _statusPanel(info),
                const RwSectionTitle('Pilih Paket'),
                for (final p in kMembershipPlans)
                  Padding(padding: const EdgeInsets.only(bottom: 12), child: _planTile(p, info, selected)),
                const RwSectionTitle('Detail Paket', top: 12),
                _planDetail(planOf(selected), info),
                const RwSectionTitle('Perbandingan Paket'),
                _compareTable(info),
                const SizedBox(height: 10),
                const Text('Harga dan benefit adalah data contoh dan dapat diubah administrator.',
                    style: TextStyle(color: kRwSub, fontSize: 12)),
                const RwSectionTitle('Riwayat Transaksi Membership'),
                _history(info),
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
          backgroundColor: kRwBg,
          appBar: AppBar(title: Text('Membership ${p.name}'), backgroundColor: kRwBg),
          body: PageList(
            bottom: 24,
            children: [
              TwoPane(
                left: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: kRwGradient,
                      boxShadow: kRwShadow,
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(p.tier.icon, color: rwTierOnDark(p.tier), size: 38),
                      const SizedBox(height: 10),
                      Text(p.name, style: TextStyle(color: rwTierOnDark(p.tier), fontSize: 30, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      Text(rp(p.price), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                      Text('untuk ${p.durationLabel}', style: const TextStyle(color: Colors.white70)),
                    ]),
                  ),
                  sec('Ringkasan'),
                  Panel(
                    child: Column(children: [
                      kv('Durasi', p.durationLabel),
                      kv('Cuci gratis', p.freeWashLabel),
                      for (final perk in p.visitPerks) kv('Saat cuci', perk),
                      kv('Klaim voucher', '${p.tier.dailyVoucherLimit}x per hari'),
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
                      for (final t in [
                        'Diskon membership berlaku untuk jasa layanan (cuci dan ganti oli), tidak untuk produk toko.',
                        if (p.hasFreeWash)
                          'Cuci gratis hanya untuk paket ${p.freePackage} Wash (${p.freeVehiclesLabel}), maksimal 1x per minggu (Senin-Minggu), total ${p.freeWashQuota}x selama masa aktif. Jatah yang tidak dipakai di suatu minggu tidak bisa dipindah ke minggu lain.',
                        if (p.hasFreeWash)
                          'Cuci gratis tidak bisa digabung dengan voucher, diskon lain, atau Coins, dan tidak mendapat Coins. Jadwal harus dalam masa aktif. Jika pesanan dibatalkan sebelum diproses, jatah dikembalikan.',
                        if (p.visitPerks.isNotEmpty)
                          '${p.visitPerks.join(' dan ')} berlaku untuk pencucian, 1 kunjungan per hari, selama masa aktif.',
                        'Membership aktif setelah pembayaran berhasil dan berlaku 1 bulan (30 hari).',
                        'Membership tidak diperpanjang otomatis. Perpanjang kapan saja sebelum atau sesudah berakhir; perpanjangan menambah 1 bulan dan jatah cuci gratis.',
                        'Batalkan langganan: membership langsung berakhir dan seluruh pembayaran dikembalikan otomatis.',
                        'Voucher eksklusif membership diperbarui tiap minggu dan dihitung dalam kuota klaim harian (Bronze/Silver 1x, Gold 2x, Platinum 3x per hari).',
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
          final start = renew ? cur.endDate! : DateTime.now();
          final end = start.add(Duration(days: p.durationDays));
          return Scaffold(
            backgroundColor: kRwBg,
            appBar: AppBar(title: Text(renew ? 'Perpanjang Membership' : 'Checkout Membership'), backgroundColor: kRwBg),
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
                        if (p.hasFreeWash) kv('Cuci gratis', p.freeWashLabel),
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
                              'Membership ${cur.tier.label} yang masih aktif sampai ${fmtDate.format(cur.endDate!)} akan diganti paket ${p.name} mulai hari ini.',
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
                                : const Icon(Icons.chevron_right, color: kRed),
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
          RedButton('Cek Pembayaran', busy: _busy, onPressed: () => _check()),
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
        backgroundColor: kRwBg,
        appBar: AppBar(title: Text('Bayar ${_o.method.label}'), backgroundColor: kRwBg),
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
      backgroundColor: kRwBg,
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
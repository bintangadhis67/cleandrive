import 'package:flutter/material.dart';

import 'app_state.dart';
import 'loyalty_models.dart';
import 'models.dart';
import 'theme.dart';
import 'voucher.dart';
import 'widgets.dart';

const _creamMuted = Color(0xB3F4E8D6);

/// Lencana level (Bronze / Silver / Gold / Platinum).
class TierBadge extends StatelessWidget {
  final Tier tier;
  final bool dark; // untuk latar gelap
  const TierBadge(this.tier, {super.key, this.dark = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: tier.soft, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(tier.icon, size: 16, color: tier.color),
          const SizedBox(width: 5),
          Text(tier.label, style: TextStyle(color: dark ? kNavy : tier.color, fontWeight: FontWeight.w800, fontSize: 12.5)),
        ]),
      );
}

/// Dialog selamat saat naik level.
void showLevelUp(BuildContext context, Tier t) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(t.icon, size: 52, color: t.color),
      title: Text('Naik ke ${t.label}!'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Keuntungan barumu:', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (final p in t.perks)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.check_circle_rounded, size: 17, color: kGreen),
              const SizedBox(width: 8),
              Expanded(child: Text(p, style: const TextStyle(fontSize: 13.5))),
            ]),
          ),
      ]),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MyVouchersScreen()));
          },
          child: const Text('Lihat Voucher'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Mantap'),
        ),
      ],
    ),
  );
}

/// Check-in harian dari mana pun (beranda atau layar membership).
Future<void> doCheckIn(BuildContext context) async {
  final r = await guard(context, () => app.checkIn());
  if (r == null || !context.mounted) return;
  toast(context, '+${r.coins} Coins • ${r.title}');
  if (r.levelUp != null) showLevelUp(context, r.levelUp!);
}

// ---------- KARTU MEMBER DI BERANDA ----------
class MemberHomeCard extends StatefulWidget {
  const MemberHomeCard({super.key});
  @override
  State<MemberHomeCard> createState() => _MemberHomeCardState();
}

class _MemberHomeCardState extends State<MemberHomeCard> {
  bool _busy = false;

  Future<void> _checkIn() async {
    setState(() => _busy = true);
    await doCheckIn(context);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final l = app.loyalty;
          final t = l.tier;
          final next = l.nextTier;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kNavyLight, kNavySoft]),
              boxShadow: const [BoxShadow(color: Color(0x290B1F44), blurRadius: 18, offset: Offset(0, 8))],
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoyaltyScreen())),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      TierBadge(t, dark: true),
                      const Spacer(),
                      const Text('Membership & Coins', style: TextStyle(color: _creamMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                      const Icon(Icons.chevron_right, color: _creamMuted, size: 18),
                    ]),
                    const SizedBox(height: 12),
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      const Icon(Icons.monetization_on_rounded, color: kGold, size: 32),
                      const SizedBox(width: 8),
                      Text('${l.balance}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, height: 1)),
                      const SizedBox(width: 6),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 3),
                        child: Text('Coins', style: TextStyle(color: kCream, fontWeight: FontWeight.w700)),
                      ),
                      const Spacer(),
                      Text('≈ ${rp(l.balance * kCoinValue)}', style: const TextStyle(color: _creamMuted, fontSize: 12.5)),
                    ]),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(
                      value: l.progress,
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(8),
                      color: kGold,
                      backgroundColor: Colors.white24,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      next == null ? 'Level tertinggi tercapai' : '${l.toNext} Coins lagi menuju ${next.label}',
                      style: const TextStyle(color: _creamMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    if (l.checkedInToday)
                      Row(children: [
                        const Icon(Icons.check_circle_rounded, color: kGreen, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Sudah check-in • streak ${l.activeStreak} hari',
                              style: const TextStyle(color: kCream, fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ])
                    else
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: kCream,
                            foregroundColor: kNavy,
                            minimumSize: const Size(0, 46),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _busy ? null : _checkIn,
                          icon: _busy
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: kNavy))
                              : const Icon(Icons.event_available_rounded),
                          label: Text('Check-in hari ini  +${l.rewardFor(l.todayIndex)} Coins',
                              style: const TextStyle(fontWeight: FontWeight.w800)),
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

// ---------- KARTU TUKAR COINS (di layar pembayaran) ----------
class RedeemCard extends StatelessWidget {
  final int total; // total sebelum Coins
  final int coins; // Coins yang dipilih (0 = tidak dipakai)
  final ValueChanged<int> onChanged;
  const RedeemCard({super.key, required this.total, required this.coins, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l = app.loyalty;
    final max = maxRedeemCoins(total: total, balance: l.balance, tier: l.tier);
    final canUse = max >= 10;
    final on = canUse && coins > 0;
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.monetization_on_rounded, color: kGold, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Tukar Coins', style: TextStyle(fontWeight: FontWeight.w800)),
              Text('Saldo ${l.balance} Coins • 1 Coin = ${rp(kCoinValue)}', style: const TextStyle(color: kMuted, fontSize: 12.5)),
            ]),
          ),
          Switch(
            value: on,
            activeColor: kRed,
            onChanged: canUse ? (v) => onChanged(v ? max : 0) : null,
          ),
        ]),
        const SizedBox(height: 6),
        if (!canUse)
          Text(
            l.balance < 10 ? 'Kumpulkan minimal 10 Coins untuk bisa menukar.' : 'Total pembayaran terlalu kecil untuk ditukar.',
            style: const TextStyle(color: kMuted, fontSize: 12.5),
          )
        else if (on) ...[
          Text('Pakai $coins Coins = potongan ${rp(coins * kCoinValue)}',
              style: const TextStyle(color: kGreen, fontWeight: FontWeight.w800, fontSize: 13)),
          if (max > 10)
            Slider(
              value: coins.clamp(10, max).toDouble(),
              min: 10,
              max: max.toDouble(),
              divisions: (max - 10) ~/ 10,
              label: '$coins',
              activeColor: kRed,
              onChanged: (v) => onChanged((v / 10).round() * 10),
            ),
        ] else
          Text('Bisa ditukar hingga $max Coins (${rp(max * kCoinValue)}). Batas ${l.tier.redeemCapPct}% untuk level ${l.tier.label}.',
              style: const TextStyle(color: kMuted, fontSize: 12.5)),
      ]),
    );
  }
}

// ---------- LAYAR MEMBERSHIP & COINS ----------
class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});
  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  Tier? _sel;
  bool _busy = false;
  String? _claiming;

  @override
  void initState() {
    super.initState();
    app.refreshMeta();
  }

  Future<void> _checkIn() async {
    setState(() => _busy = true);
    await doCheckIn(context);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _claim(CoinPromo p) async {
    setState(() => _claiming = p.id);
    final r = await guard(context, () => app.claimPromo(p.id));
    if (!mounted) return;
    setState(() => _claiming = null);
    if (r == null) return;
    toast(context, '+${r.coins} Coins • ${p.title}');
    if (r.levelUp != null) showLevelUp(context, r.levelUp!);
  }

  Widget _hero(LoyaltyInfo l) {
    final t = l.tier;
    final next = l.nextTier;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.color, Color.lerp(t.color, kNavy, .6)!],
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(t.icon, color: t.soft, size: 30),
          const SizedBox(width: 8),
          Text('Member ${t.label}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          const Spacer(),
          if (t.bonusPct > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(14)),
              child: Text('Bonus +${t.bonusPct}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
            ),
        ]),
        const SizedBox(height: 18),
        const Text('Coins kamu', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${l.balance}', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800, height: 1.1)),
          const SizedBox(width: 6),
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text('Coins', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ]),
        Text('Setara potongan ${rp(l.balance * kCoinValue)}', style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
        const SizedBox(height: 18),
        LinearProgressIndicator(
          value: l.progress,
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
          backgroundColor: Colors.white24,
        ),
        const SizedBox(height: 8),
        Text(
          next == null
              ? 'Kamu sudah di level tertinggi. Terima kasih sudah setia!'
              : '${l.toNext} Coins lagi menuju ${next.label} (total ${l.lifetime} dari ${next.minCoins})',
          style: const TextStyle(color: Colors.white, fontSize: 12.5),
        ),
      ]),
    );
  }

  Widget _dayTile(LoyaltyInfo l, int i) {
    final done = i < l.doneDays;
    final today = i == l.todayIndex && !l.checkedInToday;
    final fg = done ? Colors.white : kNavy;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: done ? kGreen : (today ? const Color(0x1AB61E1E) : kBg),
          borderRadius: BorderRadius.circular(12),
          border: today ? Border.all(color: kRed, width: 1.5) : null,
        ),
        child: Column(children: [
          Text('H${i + 1}', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg)),
          const SizedBox(height: 4),
          Icon(done ? Icons.check_circle_rounded : Icons.monetization_on_rounded, size: 20, color: done ? Colors.white : kGold),
          const SizedBox(height: 2),
          Text('+${l.rewardFor(i)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: fg)),
        ]),
      ),
    );
  }

  Widget _checkInPanel(LoyaltyInfo l) => Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('Check-in Harian', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0x1FF5B31B), borderRadius: BorderRadius.circular(14)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.local_fire_department_rounded, size: 16, color: Color(0xFFD08A00)),
                const SizedBox(width: 4),
                Text('${l.activeStreak} hari', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
              ]),
            ),
          ]),
          const SizedBox(height: 4),
          const Text('Check-in setiap hari. Hari ke-7 berhadiah terbesar. Jika terlewat sehari, streak mulai dari awal.',
              style: TextStyle(color: kMuted, fontSize: 12.5, height: 1.35)),
          const SizedBox(height: 14),
          Row(children: [for (var i = 0; i < 7; i++) _dayTile(l, i)]),
          const SizedBox(height: 14),
          RedButton(
            l.checkedInToday ? 'Sudah check-in hari ini' : 'Check-in Sekarang  +${l.rewardFor(l.todayIndex)} Coins',
            icon: l.checkedInToday ? Icons.check_rounded : Icons.event_available_rounded,
            busy: _busy,
            onPressed: l.checkedInToday ? null : _checkIn,
          ),
        ]),
      );

  Widget _ruleRow(IconData icon, String title, String desc) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: kNavy, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: kCream, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              Text(desc, style: const TextStyle(color: kMuted, fontSize: 12.5, height: 1.3)),
            ]),
          ),
        ]),
      );

  Widget _earnPanel(Tier t) => Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _ruleRow(Icons.event_available_rounded, 'Check-in harian', '+5 sampai +30 Coins per hari sesuai streak 7 hari.'),
          _ruleRow(Icons.receipt_long_rounded, 'Transaksi', 'Coins sesuai total pembayaran (cuci, ganti oli, toko):'),
          Container(
            margin: const EdgeInsets.only(left: 48, bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              for (final b in PayBand.values)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    SizedBox(width: 74, child: Text(b.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5))),
                    Expanded(child: Text(b.range, style: const TextStyle(color: kMuted, fontSize: 12))),
                    Text('+${b.coins}', style: const TextStyle(fontWeight: FontWeight.w800, color: kRed)),
                  ]),
                ),
            ]),
          ),
          _ruleRow(Icons.star_rounded, 'Ulasan', '+$kReviewCoins Coins, ditambah +$kReviewCommentBonus bila menulis komentar.'),
          _ruleRow(Icons.card_giftcard_rounded, 'Promo', 'Klaim promo Coins pada daftar di bawah.'),
          _ruleRow(Icons.local_offer_rounded, 'Tukar jadi potongan',
              '1 Coin = ${rp(kCoinValue)}. Dipakai saat memilih metode pembayaran, maksimal ${t.redeemCapPct}% dari total untuk level ${t.label}.'),
          if (t.bonusPct > 0)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: t.soft, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(t.icon, size: 18, color: t.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Level ${t.label}: semua Coins yang kamu dapat bertambah ${t.bonusPct}%.',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                ),
              ]),
            ),
        ]),
      );

  Widget _promoPanel(LoyaltyInfo l) => Panel(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(children: [
          for (var i = 0; i < l.promos.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _promoRow(l.promos[i]),
          ],
        ]),
      );

  Widget _promoRow(CoinPromo p) {
    Widget action;
    if (p.claimed) {
      action = const Text('Diklaim', style: TextStyle(color: kGreen, fontWeight: FontWeight.w800, fontSize: 13));
    } else if (p.lockedReason != null) {
      action = const Icon(Icons.lock_outline_rounded, color: kMuted, size: 20);
    } else {
      action = FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 38),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          backgroundColor: kNavy,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _claiming != null ? null : () => _claim(p),
        child: _claiming == p.id
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Klaim'),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        const Icon(Icons.card_giftcard_rounded, color: kRed),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${p.title}  +${p.coins}', style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(p.lockedReason ?? p.desc, style: const TextStyle(color: kMuted, fontSize: 12.5)),
          ]),
        ),
        const SizedBox(width: 8),
        action,
      ]),
    );
  }

  Widget _tierChip(Tier t, Tier sel) {
    final on = t == sel;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _sel = t),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: on ? t.color : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: on ? t.color : kLine),
          ),
          child: Column(children: [
            Icon(t.icon, size: 20, color: on ? Colors.white : t.color),
            const SizedBox(height: 2),
            Text(t.label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: on ? Colors.white : kNavy)),
          ]),
        ),
      ),
    );
  }

  Widget _tierPanel(LoyaltyInfo l) {
    final sel = _sel ?? l.tier;
    final reached = l.lifetime >= sel.minCoins;
    final status = sel == l.tier
        ? 'Level kamu saat ini'
        : (reached ? 'Sudah terlewati' : 'Butuh ${sel.minCoins - l.lifetime} Coins lagi');
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [for (final t in Tier.values) _tierChip(t, sel)]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: Text(sel.minCoins == 0 ? 'Level awal' : 'Mulai ${sel.minCoins} Coins',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: reached ? const Color(0x1F2E9E5B) : const Color(0x14D08A00), borderRadius: BorderRadius.circular(14)),
            child: Text(status,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: reached ? kGreen : const Color(0xFFD08A00))),
          ),
        ]),
        const SizedBox(height: 10),
        for (final p in sel.perks)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(reached ? Icons.check_circle_rounded : Icons.lock_outline_rounded, size: 18, color: reached ? kGreen : kMuted),
              const SizedBox(width: 10),
              Expanded(child: Text(p, style: const TextStyle(fontSize: 13.5, height: 1.3))),
            ]),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 44),
            foregroundColor: kNavy,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyVouchersScreen())),
          icon: const Icon(Icons.local_offer_outlined, size: 18),
          label: const Text('Lihat voucher reward'),
        ),
      ]),
    );
  }

  Widget _history(LoyaltyInfo l) {
    if (l.entries.isEmpty) {
      return const Panel(
        child: Text('Belum ada riwayat. Check-in atau selesaikan pembayaran untuk mulai mengumpulkan Coins.',
            style: TextStyle(color: kMuted)),
      );
    }
    final list = l.entries.take(15).toList();
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(children: [
        for (var i = 0; i < list.length; i++) ...[
          if (i > 0) const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: list[i].amount >= 0 ? const Color(0x1F2E9E5B) : const Color(0x1FB61E1E),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(list[i].kind.icon, size: 19, color: list[i].amount >= 0 ? kGreen : kRed),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(list[i].title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  Text(
                    [if (list[i].note.isNotEmpty) list[i].note, fmtDate.format(list[i].createdAt)].join(' • '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: kMuted, fontSize: 11.5),
                  ),
                ]),
              ),
              const SizedBox(width: 8),
              Text(
                '${list[i].amount >= 0 ? '+' : ''}${list[i].amount}',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: list[i].amount >= 0 ? kGreen : kRed),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Membership & Coins')),
        body: ListenableBuilder(
          listenable: app,
          builder: (context, _) {
            final l = app.loyalty;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: RefreshIndicator(
                  color: kRed,
                  onRefresh: app.refreshMeta,
                  child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 28), children: [
                    _hero(l),
                    const SizedBox(height: 16),
                    _checkInPanel(l),
                    sec('Cara mendapat Coins'),
                    _earnPanel(l.tier),
                    sec('Promo Coins'),
                    _promoPanel(l),
                    sec('Keuntungan membership'),
                    _tierPanel(l),
                    sec('Riwayat Coins'),
                    _history(l),
                  ]),
                ),
              ),
            );
          },
        ),
      );
}

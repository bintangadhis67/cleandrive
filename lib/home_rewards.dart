import 'package:flutter/material.dart';

import 'app_state.dart';
import 'loyalty.dart';
import 'membership.dart';
import 'membership_models.dart';
import 'models.dart';
import 'theme.dart';
import 'widgets.dart';

const _creamMuted = Color(0xB3F7F1E7);

/// Kartu gabungan di beranda: Coins (kiri) dan Membership (kanan), dipisah garis tengah.
/// Dua sistem tetap terpisah: datanya berbeda, hanya ditampilkan berdampingan.
class RewardsHomeCard extends StatefulWidget {
  const RewardsHomeCard({super.key});
  @override
  State<RewardsHomeCard> createState() => _RewardsHomeCardState();
}

class _RewardsHomeCardState extends State<RewardsHomeCard> {
  bool _busy = false;

  Future<void> _checkIn() async {
    setState(() => _busy = true);
    await doCheckIn(context);
    if (mounted) setState(() => _busy = false);
  }

  void _openCoins() => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoinsScreen()));

  Widget _coinsHalf() {
    final l = app.loyalty;
    return InkWell(
      onTap: _openCoins,
      child: Stack(children: [
        const Positioned.fill(child: CustomPaint(painter: MotifPainter(kGold))),
        Positioned(right: -6, bottom: -10, child: Icon(Icons.monetization_on_rounded, size: 96, color: kGold.withValues(alpha: .13))),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const CoinBadge(size: 30),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Coins', style: TextStyle(color: kCream, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              const Icon(Icons.chevron_right, color: _creamMuted, size: 18),
            ]),
            const SizedBox(height: 12),
            Text('${l.balance}', style: const TextStyle(color: kGold, fontSize: 34, fontWeight: FontWeight.w800, height: 1)),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.local_fire_department_rounded, size: 16, color: kGold),
              const SizedBox(width: 3),
              Expanded(
                child: Text('Streak ${l.activeStreak} hari',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _creamMuted, fontSize: 12)),
              ),
            ]),
            const SizedBox(height: 14),
            if (l.checkedInToday)
              Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: kGreen.withValues(alpha: .22), borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle_rounded, size: 17, color: Color(0xFF6FE0A6)),
                  SizedBox(width: 6),
                  Text('Sudah check-in', style: TextStyle(color: kCream, fontWeight: FontWeight.w600, fontSize: 12.5)),
                ]),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 40,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: kCream,
                    foregroundColor: kNavy,
                    minimumSize: const Size(0, 40),
                    padding: EdgeInsets.zero,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: _busy ? null : _checkIn,
                  child: _busy
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.2, color: kNavy))
                      : Text('Check-in +${l.rewardFor(l.todayIndex)}', style: const TextStyle(fontSize: 13)),
                ),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _memberHalf() {
    final info = app.membership;
    final cur = info.current;
    final active = info.hasActive && cur != null;
    final accent = active ? cur!.tier.color : kRed;
    return InkWell(
      onTap: () => openMembership(context),
      child: Stack(children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [accent.withValues(alpha: .42), Colors.transparent],
              ),
            ),
          ),
        ),
        const Positioned.fill(child: CustomPaint(painter: MotifPainter(Colors.white))),
        Positioned(
          right: -6,
          bottom: -10,
          child: Icon(active ? cur!.tier.icon : Icons.workspace_premium_rounded, size: 96, color: Colors.white.withValues(alpha: .10)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), shape: BoxShape.circle),
                child: Icon(active ? cur!.tier.icon : Icons.workspace_premium_outlined, size: 17, color: kCream),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Membership', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: kCream, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ]),
            const SizedBox(height: 12),
            Text(active ? cur!.tier.label : 'Belum aktif',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1.15)),
            const SizedBox(height: 6),
            Text(
              active
                  ? 'Hingga ${fmtDate.format(cur!.endDate!)}'
                  : (info.status == MembershipStatus.pending ? 'Menunggu pembayaran' : 'Mulai ${rp(kMembershipPlans.first.price)}'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _creamMuted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: .35)),
              ),
              child: Text(active ? 'Diskon ${cur!.plan.discountPct}% • Lihat' : 'Lihat Paket',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kCream, fontWeight: FontWeight.w600, fontSize: 12.5)),
            ),
          ]),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kNavyLight, kNavyDark]),
            boxShadow: const [BoxShadow(color: Color(0x3310264C), blurRadius: 28, offset: Offset(0, 14))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Material(
              type: MaterialType.transparency,
              child: IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(child: _coinsHalf()),
                  // garis pemisah tengah
                  Container(
                    width: 1.2,
                    margin: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.white.withValues(alpha: .45), Colors.transparent],
                      ),
                    ),
                  ),
                  Expanded(child: _memberHalf()),
                ]),
              ),
            ),
          ),
        ),
      );
}
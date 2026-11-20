import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../models/loyalty_models.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import 'reward_ui.dart';

// ===========================================================================
// CLEANDRIVE COINS (reward gratis).
// Terpisah dari Membership. Coins tidak menentukan level; bisa dipakai sebagai potongan saat pembayaran.
// ===========================================================================

const _creamMuted = Color(0xB3F7F1E7);

/// Check-in harian dari mana pun (beranda atau layar Coins).
Future<void> doCheckIn(BuildContext context) async {
  final r = await guard(context, () => app.checkIn());
  if (r == null || !context.mounted) return;
  showCoinToast(context, coins: r.coins, title: 'Check-in berhasil!', subtitle: '${r.title} • Streak ${r.streak} hari');
}

/// Popup Coins di atas layar (check-in dan klaim promo).
void showCoinToast(BuildContext context, {required int coins, required String title, String subtitle = ''}) {
  showTopToast(
    context,
    title: title,
    subtitle: subtitle.isEmpty ? '+$coins Coins diterima' : '+$coins Coins • $subtitle',
    leading: Stack(alignment: Alignment.center, children: [
      const CoinBadge(size: 46),
      Text('+$coins', style: const TextStyle(color: kNavy, fontWeight: FontWeight.w900, fontSize: 13)),
    ]),
  );
}

/// Koin emas kecil (identitas visual Coins).
class CoinBadge extends StatelessWidget {
  final double size;
  const CoinBadge({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF6CF72), kGold]),
          border: Border.all(color: const Color(0xFFFFE9A8), width: size * .06),
          boxShadow: const [BoxShadow(color: Color(0x33E9AD35), blurRadius: 14, offset: Offset(0, 5))],
        ),
        child: Icon(Icons.check_rounded, color: kNavy, size: size * .56),
      );
}

// ---------- KARTU COINS DI BERANDA ----------
class CoinsHomeCard extends StatefulWidget {
  const CoinsHomeCard({super.key});
  @override
  State<CoinsHomeCard> createState() => _CoinsHomeCardState();
}

class _CoinsHomeCardState extends State<CoinsHomeCard> {
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
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kRadiusCard + 4),
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kNavyLight, kNavy]),
              boxShadow: const [BoxShadow(color: Color(0x2910264C), blurRadius: 18, offset: Offset(0, 8))],
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(kRadiusCard + 4),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoinsScreen())),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const CoinBadge(size: 38),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('CleanDrive Coins', style: TextStyle(color: kCream, fontWeight: FontWeight.w700, fontSize: 14.5)),
                      ),
                      const Text('Lihat Coins', style: TextStyle(color: _creamMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                      const Icon(Icons.chevron_right, color: _creamMuted, size: 18),
                    ]),
                    const SizedBox(height: 14),
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('${l.balance}',
                          style: const TextStyle(color: kGold, fontSize: 34, fontWeight: FontWeight.w800, height: 1)),
                      const SizedBox(width: 6),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 3),
                        child: Text('Coins', style: TextStyle(color: kCream, fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      const Icon(Icons.local_fire_department_rounded, size: 18, color: kGold),
                      const SizedBox(width: 3),
                      Text('Streak ${l.activeStreak} hari', style: const TextStyle(color: _creamMuted, fontSize: 12.5)),
                    ]),
                    const SizedBox(height: 14),
                    if (l.checkedInToday)
                      Row(children: [
                        const Icon(Icons.check_circle_rounded, color: kGreen, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('Sudah check-in hari ini',
                              style: TextStyle(color: kCream, fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      ])
                    else
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: kRed,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 46),
                          ),
                          onPressed: _busy ? null : _checkIn,
                          icon: _busy
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                              : const Icon(Icons.event_available_rounded),
                          label: Text('Check-in  +${l.rewardFor(l.todayIndex)} Coins'),
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

// ---------- LAYAR COINS ----------
class CoinsScreen extends StatefulWidget {
  const CoinsScreen({super.key});
  @override
  State<CoinsScreen> createState() => _CoinsScreenState();
}

class _CoinsScreenState extends State<CoinsScreen> {
  bool _busy = false;
  String? _claiming;
  int _tab = 0; // 0 perolehan, 1 penggunaan
  bool _showAll = false; // hanya tampilan: tampilkan lebih dari 20 riwayat
  final _earnKey = GlobalKey();
  final _historyKey = GlobalKey();

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
    showCoinToast(context, coins: r.coins, title: 'Promo diklaim!', subtitle: p.title);
  }

  void _scrollTo(GlobalKey k) {
    final c = k.currentContext;
    if (c == null) return;
    Scrollable.ensureVisible(c, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic, alignment: .02);
  }

  // ---------------- KARTU SALDO ----------------
  Widget _heroPill(IconData icon, String label, VoidCallback onTap) => SizedBox(
        height: 44,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: kRed,
            foregroundColor: Colors.white,
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          onPressed: onTap,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 17),
              const SizedBox(width: 6),
              Text(label),
            ]),
          ),
        ),
      );

  Widget _hero(LoyaltyInfo l) => RwHeroCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const CoinBadge(size: 62),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Saldo Coins', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('${l.balance}',
                          style: const TextStyle(color: kRwGold, fontSize: 44, fontWeight: FontWeight.w800, height: 1.1)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('Coins', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _chip(Icons.local_fire_department_rounded, 'Streak ${l.activeStreak} hari'),
            _chip(Icons.trending_up_rounded, 'Total diperoleh ${l.earned} Coins'),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _heroPill(Icons.history_rounded, 'Riwayat Coins', () => _scrollTo(_historyKey))),
            const SizedBox(width: 10),
            Expanded(child: _heroPill(Icons.help_outline_rounded, 'Cara dapatkan Coins', () => _scrollTo(_earnKey))),
          ]),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .10), borderRadius: BorderRadius.circular(14)),
            child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline_rounded, size: 18, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text(kCoinsUsageNote, style: TextStyle(color: Colors.white, fontSize: 13, height: 1.45))),
            ]),
          ),
        ]),
      );

  Widget _chip(IconData icon, String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: const Color(0xFF5B8DEF).withValues(alpha: .30), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: kRwGold),
          const SizedBox(width: 6),
          Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12.5)),
        ]),
      );

  // ---------------- CHECK-IN HARIAN ----------------
  Widget _dayTile(LoyaltyInfo l, int i) {
    final done = i < l.doneDays;
    final today = i == l.todayIndex && !l.checkedInToday;
    final bonus = i == kCheckInRewards.length - 1;
    final fg = done ? Colors.white : kRwText;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2.5),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 1),
        decoration: BoxDecoration(
          color: done ? kRwGreen : kRwBlueSoft,
          borderRadius: BorderRadius.circular(12),
          border: today ? Border.all(color: kRwGold, width: 1.6) : null,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('Hari ${i + 1}', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: fg)),
          ),
          const SizedBox(height: 7),
          Icon(done ? Icons.check_circle_rounded : (bonus ? Icons.emoji_events_rounded : Icons.stars_rounded),
              size: 22, color: done ? Colors.white : kRwGold),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('+${l.rewardFor(i)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: fg)),
          ),
        ]),
      ),
    );
  }

  Widget _checkInPanel(LoyaltyInfo l) => RwCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(
              child: Text('Check-in Harian', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5, color: kRwText)),
            ),
            RwPill('${l.activeStreak} hari', bg: kRwGoldLight, fg: kRwGoldDark, icon: Icons.local_fire_department_rounded),
          ]),
          const SizedBox(height: 6),
          const Text('Check-in setiap hari. Hari ke-7 adalah bonus streak terbesar. Jika terlewat sehari, streak mulai dari awal.',
              style: TextStyle(color: kRwSub, fontSize: 12.5, height: 1.4)),
          const SizedBox(height: 14),
          Row(children: [for (var i = 0; i < 7; i++) _dayTile(l, i)]),
          const SizedBox(height: 16),
          RwButton(
            l.checkedInToday ? 'Sudah check-in hari ini' : 'Check-in Sekarang  +${l.rewardFor(l.todayIndex)} Coins',
            icon: l.checkedInToday ? Icons.check_rounded : Icons.event_available_rounded,
            height: 50,
            busy: _busy,
            onPressed: l.checkedInToday ? null : _checkIn,
          ),
        ]),
      );

  // ---------------- CARA MENDAPATKAN COINS ----------------
  Widget _ruleRow(IconData icon, String title, String desc) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RwIconBox(icon, size: 40, bg: kRwNavy, fg: Colors.white, circle: false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: kRwText)),
              const SizedBox(height: 1),
              Text(desc, style: const TextStyle(color: kRwSub, fontSize: 12.5, height: 1.4)),
            ]),
          ),
        ]),
      );

  Widget _earnPanel() => RwCard(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _ruleRow(Icons.event_available_rounded, 'Check-in harian',
              '+${kCheckInRewards.first} sampai +${kCheckInRewards.last} Coins per hari sesuai streak 7 hari.'),
          _ruleRow(Icons.emoji_events_rounded, 'Bonus streak',
              'Check-in 7 hari berturut-turut: hari ke-7 memberi +${kCheckInRewards.last} Coins.'),
          _ruleRow(Icons.receipt_long_rounded, 'Transaksi',
              'Cuci dan ganti oli: Coins sesuai total pembayaran (cuci gratis membership tidak dapat Coins):'),
          Container(
            margin: const EdgeInsets.only(left: 52, bottom: 6, top: 2),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kRwBlueSoft, borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              for (final b in PayBand.values)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    SizedBox(
                      width: 74,
                      child: Text(b.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: kRwText)),
                    ),
                    Expanded(child: Text(b.range, style: const TextStyle(color: kRwSub, fontSize: 12))),
                    Text('+${b.coins}', style: const TextStyle(fontWeight: FontWeight.w800, color: kRwNavy)),
                  ]),
                ),
            ]),
          ),
          _ruleRow(Icons.shopping_bag_rounded, 'Belanja di Toko',
              '+$kShopCoinReward Coins tiap kelipatan ${rp(kShopCoinStepRp)} yang dibayar (minimal ${rp(kShopCoinStepRp)}). Contoh: ${rp(kShopCoinStepRp * 2)} = +${shopCoinsFor(kShopCoinStepRp * 2)} Coins.'),
          _ruleRow(Icons.star_rounded, 'Ulasan', '+$kReviewCoins Coins, ditambah +$kReviewCommentBonus bila menulis komentar.'),
          _ruleRow(Icons.card_giftcard_rounded, 'Promo khusus',
              'Promo bulanan berganti tiap bulan. Bonus selamat datang, lengkapi profil, dan transaksi pertama hanya sekali per akun.'),
          _ruleRow(Icons.local_offer_rounded, 'Tukar saat bayar',
              '1 Coin = Rp $kCoinValue, kelipatan $kCoinStep, maksimal $kCoinRedeemCapPct% dari total. Tidak untuk membeli membership.'),
        ]),
      );

  // ---------------- PROMO COINS ----------------
  Widget _promoPanel(LoyaltyInfo l) => RwCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(children: [
          for (var i = 0; i < l.promos.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: kRwLine),
            _promoRow(l.promos[i]),
          ],
        ]),
      );

  Widget _promoRow(CoinPromo p) {
    Widget action;
    if (p.claimed) {
      action = const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle_rounded, color: kRwGreen, size: 17),
        SizedBox(width: 4),
        Text('Diklaim', style: TextStyle(color: kRwGreen, fontWeight: FontWeight.w800, fontSize: 13)),
      ]);
    } else if (p.lockedReason != null) {
      action = const Icon(Icons.lock_outline_rounded, color: kRwSub, size: 22);
    } else {
      action = RwSmallButton(
        'Klaim',
        busy: _claiming == p.id,
        onPressed: _claiming != null ? null : () => _claim(p),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        const RwIconBox(Icons.card_giftcard_rounded, size: 42, bg: kRwGoldLight, fg: Color(0xFFD98A00), circle: false),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 4, children: [
              Text('${p.title}  +${p.coins}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kRwText)),
              if (p.monthly)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: kError, borderRadius: BorderRadius.circular(8)),
                  child: const Text('Bulan ini', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800)),
                ),
            ]),
            const SizedBox(height: 2),
            Text(p.lockedReason ?? p.desc, style: const TextStyle(color: kRwSub, fontSize: 12.5, height: 1.35)),
            const SizedBox(height: 2),
            Text(
              p.monthly && p.endsAt != null ? '1x per bulan • berakhir ${fmtDate.format(p.endsAt!)}' : 'Sekali per akun',
              style: const TextStyle(color: kRwSub, fontSize: 11.5),
            ),
          ]),
        ),
        const SizedBox(width: 10),
        action,
      ]),
    );
  }

  // ---------------- RIWAYAT COINS ----------------
  Widget _historyList(List<CoinEntry> list, {required String emptyText}) {
    if (list.isEmpty) {
      return EmptyState(icon: Icons.receipt_long_outlined, title: 'Belum ada riwayat', message: emptyText);
    }
    final shown = _showAll ? list : list.take(20).toList();
    return RwCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(children: [
        for (var i = 0; i < shown.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: kRwLine),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [
              RwIconBox(
                shown[i].kind.icon,
                size: 40,
                circle: false,
                bg: shown[i].amount >= 0 ? const Color(0x2619A66A) : const Color(0x1FD91F2B),
                fg: shown[i].amount >= 0 ? kRwGreen : kError,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(shown[i].title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: kRwText)),
                  if (shown[i].note.isNotEmpty)
                    Text(shown[i].note, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kRwSub, fontSize: 12)),
                  Text(fmtDateTime.format(shown[i].createdAt), style: const TextStyle(color: kRwSub, fontSize: 11.5)),
                ]),
              ),
              const SizedBox(width: 8),
              Text(
                '${shown[i].amount >= 0 ? '+' : ''}${shown[i].amount}',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: shown[i].amount >= 0 ? kRwGreen : kError),
              ),
            ]),
          ),
        ],
        if (list.length > 20) ...[
          const Divider(height: 1, color: kRwLine),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _showAll = !_showAll),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_showAll ? 'Tampilkan lebih sedikit' : 'Lihat semua riwayat'),
                Icon(_showAll ? Icons.expand_less_rounded : Icons.chevron_right_rounded, size: 20),
              ]),
            ),
          ),
        ],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kRwBg,
        appBar: AppBar(title: const Text('CleanDrive Coins'), backgroundColor: kRwBg),
        body: ListenableBuilder(
          listenable: app,
          builder: (context, _) {
            final l = app.loyalty;
            return PageList(
              onRefresh: app.refreshMeta,
              bottom: 32,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _hero(l),
                  const SizedBox(height: 16),
                  _checkInPanel(l),
                  RwSectionTitle('Cara mendapatkan Coins', key: _earnKey),
                  _earnPanel(),
                  const RwSectionTitle('Promo Coins'),
                  _promoPanel(l),
                  RwSectionTitle('Riwayat Coins', key: _historyKey),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(children: [
                      FilterPill(
                          label: 'Perolehan',
                          selected: _tab == 0,
                          onTap: () => setState(() {
                                _tab = 0;
                                _showAll = false;
                              })),
                      FilterPill(
                          label: 'Penggunaan',
                          selected: _tab == 1,
                          onTap: () => setState(() {
                                _tab = 1;
                                _showAll = false;
                              })),
                    ]),
                  ),
                  if (_tab == 0)
                    _historyList(l.gains, emptyText: 'Check-in atau selesaikan pembayaran untuk mulai mengumpulkan Coins.')
                  else
                    _historyList(l.usage,
                        emptyText: 'Belum ada Coins yang dipakai. Tukar Coins saat membayar pesanan atau pembelian toko.'),
                ]),
              ],
            );
          },
        ),
      );
}

// ---------- TUKAR COINS SAAT PEMBAYARAN ----------
// Hanya untuk pesanan layanan dan pembelian toko (bukan membership).
class RedeemCard extends StatelessWidget {
  final int total; // total sebelum Coins
  final int coins; // Coins yang dipilih (0 = tidak dipakai)
  final ValueChanged<int> onChanged;
  const RedeemCard({super.key, required this.total, required this.coins, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l = app.loyalty;
    final max = maxRedeemCoins(total: total, balance: l.balance);
    final canUse = max >= kCoinStep;
    final on = canUse && coins > 0;
    return RwCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const RwCoin(size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Tukar Coins', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: kRwText)),
              const SizedBox(height: 2),
              Text('Saldo ${l.balance} Coins = ${rp(l.balance * kCoinValue)}', style: const TextStyle(color: kRwSub, fontSize: 12.5)),
              Text('1 Coin = ${rp(kCoinValue)}', style: const TextStyle(color: kRwSub, fontSize: 12)),
            ]),
          ),
          Switch(
            value: on,
            activeThumbColor: Colors.white,
            activeTrackColor: kRwNavy,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFC9D5EC),
            trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
            onChanged: canUse ? (v) => onChanged(v ? max : 0) : null,
          ),
        ]),
        const SizedBox(height: 8),
        if (!canUse)
          Text(
            l.balance < kCoinStep ? 'Gunakan minimal $kCoinStep Coins untuk bisa menukar.' : 'Total pembayaran terlalu kecil untuk ditukar.',
            style: const TextStyle(color: kRwSub, fontSize: 12.5),
          )
        else if (on) ...[
          Text('Pakai $coins Coins = potongan ${rp(coins * kCoinValue)}',
              style: const TextStyle(color: kRwGreen, fontWeight: FontWeight.w800, fontSize: 13)),
          if (max > kCoinStep)
            Slider(
              value: coins.clamp(kCoinStep, max).toDouble(),
              min: kCoinStep.toDouble(),
              max: max.toDouble(),
              divisions: (max - kCoinStep) ~/ kCoinStep,
              label: '$coins',
              activeColor: kRwNavy,
              inactiveColor: const Color(0xFFD5DFF2),
              onChanged: (v) => onChanged((v / kCoinStep).round() * kCoinStep),
            ),
        ] else
          Text('Bisa ditukar hingga $max Coins (${rp(max * kCoinValue)}). Maksimal $kCoinRedeemCapPct% dari total.',
              style: const TextStyle(color: kRwSub, fontSize: 12.5)),
      ]),
    );
  }
}
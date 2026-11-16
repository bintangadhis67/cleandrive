import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../loyalty_models.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'admin_data.dart';
import 'admin_ui.dart';

// ---------------------------------------------------------------------------
// CLEANDRIVE COINS (panel terpisah dari Membership): saldo, riwayat, check-in, penukaran, aturan reward.
// ---------------------------------------------------------------------------
class AdminCoinsPage extends StatefulWidget {
  const AdminCoinsPage({super.key});

  @override
  State<AdminCoinsPage> createState() => _AdminCoinsPageState();
}

class _AdminCoinsPageState extends State<AdminCoinsPage> {
  int _tab = 0;

  static String _kind(CoinKind k) => switch (k) {
        CoinKind.checkin => 'Check-in',
        CoinKind.transaction => 'Transaksi',
        CoinKind.review => 'Ulasan',
        CoinKind.promo => 'Promo',
        CoinKind.redeem => 'Penukaran',
        CoinKind.refund => 'Pembatalan',
      };

  Widget _entries(List<AdminCoinRow> rows) => AdminCard(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
        child: AdminTable(
          minWidth: 860,
          emptyText: 'Belum ada data.',
          cols: const [TCol('Waktu', flex: 2), TCol('Pelanggan', flex: 3), TCol('Jenis', flex: 2), TCol('Keterangan', flex: 4), TCol('Coins', flex: 2)],
          rows: [
            for (final r in rows)
              [
                TwoLine(fmtDate.format(r.entry.createdAt), fmtHm.format(r.entry.createdAt), false),
                PersonCell(r.customer),
                leftCell(StatusBadge(_kind(r.entry.kind), r.entry.amount >= 0 ? kGoldDeep : kError)),
                TwoLine(r.entry.title, r.entry.note, false),
                Text('${r.entry.amount > 0 ? '+' : ''}${fmtNum(r.entry.amount)}',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: r.entry.amount >= 0 ? kGreen : kError)),
              ],
          ],
        ),
      );

  Widget _balances(AdminOverview ov) {
    final list = [...ov.customers]..sort((a, b) => b.coins.compareTo(a.coins));
    return AdminCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      child: AdminTable(
        minWidth: 640,
        emptyText: 'Belum ada pelanggan.',
        cols: const [TCol('Pelanggan', flex: 4), TCol('Saldo Coins', flex: 2), TCol('Setara Rupiah', flex: 2)],
        rows: [
          for (final c in list)
            [
              PersonCell(c.name, c.email),
              Row(children: [
                const Icon(Icons.monetization_on_rounded, color: kGold, size: 18),
                const SizedBox(width: 6),
                Text(fmtNum(c.coins), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ]),
              Text(rp(c.coins * kCoinValue), style: const TextStyle(fontSize: 13)),
            ],
        ],
      ),
    );
  }

  Widget _rule(String title, List<Widget> rows) => AdminCard(
        border: kCreamLine,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [CardTitle(title, color: kGoldDeep), const SizedBox(height: 8), ...rows]),
      );

  Widget _rewards(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const InfoBanner('Nilai reward dibaca dari aturan aplikasi (loyalty_models.dart). Mengubahnya dari panel admin belum tersambung ke backend.'),
        const SizedBox(height: 14),
        AutoGrid(minWidth: 300, gap: 14, children: [
          _rule('Check-in harian', [for (var i = 0; i < kCheckInRewards.length; i++) kv('Hari ke-${i + 1}${i == 6 ? ' (bonus streak)' : ''}', '+${kCheckInRewards[i]} Coins')]),
          _rule('Coins transaksi', [for (final b in PayBand.values) kv('${b.label} (${b.range})', '+${b.coins} Coins')]),
          _rule('Ulasan', [kv('Beri rating', '+$kReviewCoins Coins'), kv('Bonus komentar', '+$kReviewCommentBonus Coins')]),
          _rule('Penukaran', [
            kv('Nilai 1 Coin', rp(kCoinValue)),
            kv('Kelipatan tukar', '$kCoinStep Coins'),
            kv('Maksimal potongan', '$kCoinRedeemCapPct% dari total'),
          ]),
        ]),
        const SizedBox(height: 14),
        Align(alignment: Alignment.centerLeft, child: RedAction('Ubah pengaturan reward', () => showNotConnected(context, 'Pengaturan reward'), icon: Icons.tune_rounded)),
      ]);

  @override
  Widget build(BuildContext context) => OverviewGate(builder: (ov) {
        final s = ov.coins;
        Widget content;
        switch (_tab) {
          case 0:
            content = _balances(ov);
          case 1:
            content = _entries(ov.coinRows.where((r) => r.entry.amount > 0).toList());
          case 2:
            content = _entries(ov.coinRows.where((r) => r.entry.amount < 0).toList());
          case 3:
            content = _entries(ov.coinRows.where((r) => r.entry.kind == CoinKind.checkin).toList());
          case 4:
            content = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const InfoBanner(kCoinsUsageNote),
              const SizedBox(height: 14),
              _entries(ov.coinRows.where((r) => r.entry.kind == CoinKind.redeem).toList()),
            ]);
          default:
            content = _rewards(context);
        }
        return AdminPageBody(children: [
          StatGrid([
            MiniStat(Icons.savings_outlined, kGold, 'Total Coins Beredar', fmtNum(s.circulating), bg: kCreamSoft, border: kCreamLine),
            MiniStat(Icons.event_available_outlined, kGold, 'Check-in Hari Ini', '${fmtNum(s.checkinsToday)} pengguna', bg: kCreamSoft, border: kCreamLine),
            MiniStat(Icons.card_giftcard_rounded, kGold, 'Penukaran Coins', '${fmtNum(s.redeemCount)} transaksi', bg: kCreamSoft, border: kCreamLine),
            MiniStat(Icons.monetization_on_outlined, kGold, 'Coins Terpakai', fmtNum(s.redeemedCoins), bg: kCreamSoft, border: kCreamLine),
          ]),
          const SizedBox(height: 16),
          PillBar(
            labels: const ['Saldo Pelanggan', 'Penambahan', 'Pengurangan', 'Check-in Harian', 'Penukaran', 'Pengaturan Reward'],
            index: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: 8),
          content,
        ]);
      });
}

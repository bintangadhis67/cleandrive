import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;

import '../../../core/app_state.dart';
import '../../../core/theme.dart';
import '../../../data/repository.dart';
import '../../../models/loyalty_models.dart';
import '../../../models/models.dart';
import '../../../widgets/widgets.dart';
import '../shared/admin_data.dart';
import '../shared/admin_ui.dart';

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

  Future<void> _editRewards() async {
    final saved = await showDialog<bool>(context: context, barrierDismissible: false, builder: (_) => const _RewardDialog());
    if (!mounted) return;
    if (saved == true) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengaturan reward disimpan.')));
    }
  }

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
        const InfoBanner('Nilai reward tersimpan di server dan berlaku untuk transaksi berikutnya. Saldo dan riwayat Coins yang sudah ada tidak berubah.'),
        const SizedBox(height: 14),
        AutoGrid(minWidth: 300, gap: 14, children: [
          _rule('Check-in harian', [for (var i = 0; i < kCheckInRewards.length; i++) kv('Hari ke-${i + 1}${i == 6 ? ' (bonus streak)' : ''}', '+${kCheckInRewards[i]} Coins')]),
          _rule('Coins transaksi cuci / oli', [for (final b in PayBand.values) kv('${b.label} (${b.range})', '+${b.coins} Coins')]),
          _rule('Coins belanja Toko', [
            kv('Tiap kelipatan ${rp(kShopCoinStepRp)}', '+$kShopCoinReward Coins'),
            kv('Di bawah ${rp(kShopCoinStepRp)}', '0 Coins'),
            kv('Cuci gratis membership', '0 Coins'),
          ]),
          _rule('Ulasan', [kv('Beri rating', '+$kReviewCoins Coins'), kv('Bonus komentar', '+$kReviewCommentBonus Coins')]),
          _rule('Penukaran', [
            kv('Nilai 1 Coin', rp(kCoinValue)),
            kv('Kelipatan tukar', '$kCoinStep Coins'),
            kv('Maksimal potongan', '$kCoinRedeemCapPct% dari total'),
          ]),
        ]),
        const SizedBox(height: 14),
        Align(alignment: Alignment.centerLeft, child: RedAction('Ubah pengaturan reward', _editRewards, icon: Icons.tune_rounded)),
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
              InfoBanner(kCoinsUsageNote),
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

// ---------------------------------------------------------------------------
// Dialog pengaturan reward Coins. Validasi sama dengan server (RewardSettings.php).
// ---------------------------------------------------------------------------
class _RewardDialog extends StatefulWidget {
  const _RewardDialog();

  @override
  State<_RewardDialog> createState() => _RewardDialogState();
}

class _RewardDialogState extends State<_RewardDialog> {
  final RewardConfig _c = RewardRules.current;
  final Map<String, TextEditingController> _f = {};
  final List<TextEditingController> _days = [];
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final v = <String, int>{
      'coinValue': _c.coinValue,
      'coinStep': _c.coinStep,
      'cap': _c.coinRedeemCapPct,
      'review': _c.reviewCoins,
      'bonus': _c.reviewCommentBonus,
      'bandMid': _c.bandMid,
      'bandHigh': _c.bandHigh,
      'low': _c.bandLowCoins,
      'mid': _c.bandMidCoins,
      'high': _c.bandHighCoins,
      'shopStep': _c.shopCoinStepRp,
      'shopReward': _c.shopCoinReward,
    };
    for (final e in v.entries) {
      _f[e.key] = TextEditingController(text: '${e.value}');
    }
    for (final d in _c.checkInRewards) {
      _days.add(TextEditingController(text: '$d'));
    }
  }

  @override
  void dispose() {
    for (final x in _f.values) {
      x.dispose();
    }
    for (final x in _days) {
      x.dispose();
    }
    super.dispose();
  }

  int? _n(String k) => int.tryParse(_f[k]!.text.trim());

  String? _check(String k, String label, int min, int max) {
    final v = _n(k);
    if (v == null || v < min || v > max) return '$label harus berupa angka bulat antara $min dan $max.';
    return null;
  }

  Future<void> _save() async {
    final err = _check('coinValue', 'Nilai 1 Coin', 1, 100000) ??
        _check('coinStep', 'Kelipatan tukar', 1, 10000) ??
        _check('cap', 'Batas potongan (%)', 1, 100) ??
        _check('review', 'Coins ulasan', 0, 10000) ??
        _check('bonus', 'Bonus komentar', 0, 10000) ??
        _check('bandMid', 'Batas tingkat menengah', 1000, 100000000) ??
        _check('bandHigh', 'Batas tingkat tertinggi', 1000, 100000000) ??
        _check('low', 'Coins tingkat terendah', 0, 100000) ??
        _check('mid', 'Coins tingkat menengah', 0, 100000) ??
        _check('high', 'Coins tingkat tertinggi', 0, 100000) ??
        _check('shopStep', 'Kelipatan belanja Toko', 1000, 100000000) ??
        _check('shopReward', 'Coins belanja Toko', 0, 10000);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    final days = [for (final d in _days) int.tryParse(d.text.trim())];
    if (days.any((d) => d == null || d < 0 || d > 10000)) {
      setState(() => _error = 'Coins check-in tiap hari harus berupa angka bulat antara 0 dan 10000.');
      return;
    }
    if (_n('bandHigh')! <= _n('bandMid')!) {
      setState(() => _error = 'Batas tingkat tertinggi harus lebih besar dari batas tingkat menengah.');
      return;
    }
    final cfg = RewardConfig(
      coinValue: _n('coinValue')!,
      coinStep: _n('coinStep')!,
      coinRedeemCapPct: _n('cap')!,
      checkInRewards: [for (final d in days) d!],
      reviewCoins: _n('review')!,
      reviewCommentBonus: _n('bonus')!,
      bandMid: _n('bandMid')!,
      bandHigh: _n('bandHigh')!,
      bandLowCoins: _n('low')!,
      bandMidCoins: _n('mid')!,
      bandHighCoins: _n('high')!,
      shopCoinStepRp: _n('shopStep')!,
      shopCoinReward: _n('shopReward')!,
    );
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await app.repo.saveRewards(cfg);
      await app.loadCatalog(force: true);
      await app.refreshAll();
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Gagal menyimpan. Periksa koneksi ke server lalu coba lagi.';
        });
      }
    }
  }

  Widget _num(TextEditingController c, String label) => TextField(
        controller: c,
        enabled: !_saving,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText: label),
      );

  Widget _pair(Widget a, Widget b) => Row(children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)]);

  Widget _head(String s) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 4),
        child: Text(s, style: const TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
      );

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Pengaturan reward Coins', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              _head('Penukaran'),
              _pair(_num(_f['coinValue']!, 'Nilai 1 Coin (Rp)'), _num(_f['coinStep']!, 'Kelipatan tukar')),
              const SizedBox(height: 8),
              _num(_f['cap']!, 'Maksimal potongan (% dari total)'),
              _head('Check-in harian (hari ke-1 sampai ke-7)'),
              Wrap(spacing: 10, runSpacing: 8, children: [
                for (var i = 0; i < _days.length; i++) SizedBox(width: 100, child: _num(_days[i], 'Hari ${i + 1}')),
              ]),
              _head('Coins transaksi cuci / oli'),
              _pair(_num(_f['bandMid']!, 'Batas menengah (Rp)'), _num(_f['bandHigh']!, 'Batas tertinggi (Rp)')),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _num(_f['low']!, 'Terendah')),
                const SizedBox(width: 10),
                Expanded(child: _num(_f['mid']!, 'Menengah')),
                const SizedBox(width: 10),
                Expanded(child: _num(_f['high']!, 'Tertinggi')),
              ]),
              _head('Coins belanja Toko'),
              _pair(_num(_f['shopStep']!, 'Tiap kelipatan (Rp)'), _num(_f['shopReward']!, 'Dapat (Coins)')),
              _head('Ulasan'),
              _pair(_num(_f['review']!, 'Beri rating'), _num(_f['bonus']!, 'Bonus komentar')),
              const SizedBox(height: 12),
              const Text(
                'Berlaku untuk transaksi berikutnya. Saldo dan riwayat Coins yang sudah ada tidak berubah.',
                style: TextStyle(fontSize: 12, color: kMuted),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: kError, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Menyimpan...' : 'Simpan')),
        ],
      );
}

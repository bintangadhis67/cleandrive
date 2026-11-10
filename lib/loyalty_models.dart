import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Aturan Coins & Membership. Semua angka ada di sini supaya mudah diubah.
// ---------------------------------------------------------------------------

/// 1 Coin = Rp 100 potongan harga saat pembayaran.
const kCoinValue = 100;

/// Coins check-in harian untuk hari ke-1 sampai ke-7 (lalu mengulang).
const kCheckInRewards = [5, 5, 10, 10, 15, 15, 30];

/// Coins dari ulasan (ditambah bonus bila menulis komentar).
const kReviewCoins = 10;
const kReviewCommentBonus = 5;

/// Batas tingkat pembayaran (rupiah) untuk Coins transaksi.
const kBandMid = 50000;
const kBandHigh = 150000;

/// Tiga tingkat Coins transaksi berdasarkan jumlah yang dibayar.
enum PayBand {
  low('Terendah', 10, 'di bawah Rp 50.000'),
  mid('Menengah', 30, 'Rp 50.000 - Rp 149.999'),
  high('Tertinggi', 75, 'mulai Rp 150.000');

  const PayBand(this.label, this.coins, this.range);
  final String label, range;
  final int coins;
}

PayBand payBandFor(int amount) =>
    amount >= kBandHigh ? PayBand.high : (amount >= kBandMid ? PayBand.mid : PayBand.low);

/// Level membership. Naik level berdasarkan total Coins yang pernah didapat
/// (Coins yang dipakai untuk potongan tidak menurunkan level).
enum Tier {
  bronze('Bronze', 0, 0, 30, Color(0xFFB0703A), Color(0xFFF1DCC6), 'Akses voucher umum dan promo Coins'),
  silver('Silver', 300, 10, 40, Color(0xFF7D8AA3), Color(0xFFE3E8F0), 'Voucher eksklusif: diskon Rp 15.000'),
  gold('Gold', 1000, 20, 50, Color(0xFFD99A00), Color(0xFFFBE7A6), 'Voucher eksklusif: diskon 20% (maks. Rp 40.000)'),
  platinum('Platinum', 2500, 30, 60, Color(0xFF4A5B7D), Color(0xFFDCE4F2), 'Voucher eksklusif: diskon Rp 50.000');

  const Tier(this.label, this.minCoins, this.bonusPct, this.redeemCapPct, this.color, this.soft, this.reward);
  final String label, reward;
  final int minCoins, bonusPct, redeemCapPct;
  final Color color, soft;

  Tier? get next => index + 1 < Tier.values.length ? Tier.values[index + 1] : null;
  IconData get icon => this == Tier.platinum ? Icons.diamond_rounded : Icons.workspace_premium_rounded;

  List<String> get perks => [
        bonusPct == 0
            ? 'Kumpulkan Coins dari check-in, transaksi, dan ulasan'
            : 'Bonus Coins +$bonusPct% di setiap check-in, transaksi, dan ulasan',
        'Tukar Coins hingga $redeemCapPct% dari total pembayaran',
        reward,
      ];
}

Tier tierFor(int lifetimeCoins) => Tier.values.lastWhere((t) => lifetimeCoins >= t.minCoins);

/// Coins dasar ditambah bonus level.
int withTierBonus(int base, Tier t) => base + base * t.bonusPct ~/ 100;

/// Coins maksimal yang boleh ditukar pada satu pembayaran (kelipatan 10).
int maxRedeemCoins({required int total, required int balance, required Tier tier}) {
  final byCap = total * tier.redeemCapPct ~/ 100 ~/ kCoinValue;
  final c = balance < byCap ? balance : byCap;
  return c ~/ 10 * 10;
}

enum CoinKind {
  checkin(Icons.event_available_rounded),
  transaction(Icons.receipt_long_rounded),
  review(Icons.star_rounded),
  promo(Icons.card_giftcard_rounded),
  redeem(Icons.local_offer_rounded),
  refund(Icons.undo_rounded);

  const CoinKind(this.icon);
  final IconData icon;
}

class CoinEntry {
  final String id, title, note;
  final CoinKind kind;
  final int amount; // positif = dapat, negatif = dipakai
  final DateTime createdAt;
  const CoinEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.amount,
    required this.createdAt,
    this.note = '',
  });

  factory CoinEntry.fromJson(Map<String, dynamic> j) => CoinEntry(
        id: j['id'].toString(),
        kind: CoinKind.values.firstWhere((k) => k.name == j['kind'], orElse: () => CoinKind.promo),
        title: j['title'] as String,
        note: (j['note'] ?? '') as String,
        amount: (j['amount'] as num).toInt(),
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

/// Promo Coins sekali klaim.
class CoinPromo {
  final String id, title, desc;
  final int coins;
  final bool claimed;
  final String? lockedReason; // null = bisa diklaim
  const CoinPromo({
    required this.id,
    required this.title,
    required this.desc,
    required this.coins,
    required this.claimed,
    this.lockedReason,
  });
  bool get available => !claimed && lockedReason == null;
}

/// Hasil check-in / klaim promo.
class CoinAward {
  final int coins, streak;
  final Tier? levelUp;
  final String title;
  const CoinAward(this.coins, this.streak, this.levelUp, this.title);
}

class LoyaltyInfo {
  final int balance, lifetime, streak;
  final DateTime? lastCheckIn;
  final List<CoinEntry> entries;
  final List<CoinPromo> promos;
  const LoyaltyInfo({
    this.balance = 0,
    this.lifetime = 0,
    this.streak = 0,
    this.lastCheckIn,
    this.entries = const [],
    this.promos = const [],
  });

  Tier get tier => tierFor(lifetime);
  Tier? get nextTier => tier.next;
  int get toNext => nextTier == null ? 0 : nextTier!.minCoins - lifetime;

  double get progress {
    final n = nextTier;
    if (n == null) return 1;
    final span = n.minCoins - tier.minCoins;
    return ((lifetime - tier.minCoins) / span).clamp(0.0, 1.0).toDouble();
  }

  static bool _same(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  bool get checkedInToday => lastCheckIn != null && _same(lastCheckIn!, DateTime.now());

  bool get streakAlive =>
      lastCheckIn != null &&
      (checkedInToday || _same(lastCheckIn!, DateTime.now().subtract(const Duration(days: 1))));

  /// Streak yang masih berjalan (0 bila kemarin terlewat).
  int get activeStreak => streakAlive ? streak : 0;

  /// Jumlah hari yang sudah terisi pada siklus 7 hari saat ini.
  int get doneDays {
    final s = activeStreak;
    if (s == 0) return 0;
    final m = s % 7;
    if (m == 0) return checkedInToday ? 7 : 0;
    return m;
  }

  /// Indeks (0-6) tile "hari ini" pada kalender check-in.
  int get todayIndex => checkedInToday ? doneDays - 1 : doneDays;

  /// Coins check-in untuk hari ke-[dayIndex]+1, sudah termasuk bonus level.
  int rewardFor(int dayIndex) => withTierBonus(kCheckInRewards[dayIndex], tier);

  factory LoyaltyInfo.fromJson(Map<String, dynamic> j) => LoyaltyInfo(
        balance: (j['balance'] as num).toInt(),
        lifetime: (j['lifetime'] as num).toInt(),
        streak: (j['streak'] as num? ?? 0).toInt(),
        lastCheckIn: j['last_check_in'] == null ? null : DateTime.parse(j['last_check_in'] as String),
        entries: [for (final e in (j['entries'] as List? ?? [])) CoinEntry.fromJson(e as Map<String, dynamic>)],
      );
}

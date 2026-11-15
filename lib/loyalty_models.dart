import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// CLEANDRIVE COINS: sistem reward GRATIS dari aktivitas.
// Semua angka ada di sini supaya mudah diubah.
//
// ATURAN:
// - Coins TIDAK menentukan level membership (membership adalah produk berbayar, lihat membership_models.dart).
// - Coins BISA dipakai sebagai potongan saat membayar pesanan layanan dan pembelian toko.
// - Coins TIDAK bisa dipakai untuk membeli membership.
// ---------------------------------------------------------------------------

/// 1 Coin = Rp 25 potongan harga saat pembayaran.
const kCoinValue = 25;

/// Coins ditukar dalam kelipatan ini, dan maksimal persen dari total yang boleh dipotong.
const kCoinStep = 10;
const kCoinRedeemCapPct = 50;

/// Catatan yang ditampilkan di layar Coins dan pembayaran.
const kCoinsUsageNote =
    'Coins bisa dipakai sebagai potongan saat membayar pesanan dan pembelian toko (1 Coin = Rp $kCoinValue, maksimal $kCoinRedeemCapPct% dari total). Tidak berlaku untuk membeli membership.';

/// Coins maksimal yang boleh ditukar pada satu pembayaran (kelipatan [kCoinStep]).
int maxRedeemCoins({required int total, required int balance}) {
  final byCap = total * kCoinRedeemCapPct ~/ 100 ~/ kCoinValue;
  final c = balance < byCap ? balance : byCap;
  return c ~/ kCoinStep * kCoinStep;
}

/// Coins check-in harian untuk hari ke-1 sampai ke-7 (lalu mengulang). Hari ke-7 = bonus streak.
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
  final int amount; // positif = dapat, negatif = ditarik kembali
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
  final String title;
  const CoinAward(this.coins, this.streak, this.title);
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

  /// Total Coins yang pernah didapat (hanya statistik, tidak menentukan apa pun).
  int get earned => entries.where((e) => e.amount > 0).fold(0, (s, e) => s + e.amount);

  List<CoinEntry> get gains => entries.where((e) => e.amount > 0).toList();
  List<CoinEntry> get usage => entries.where((e) => e.amount < 0).toList();

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

  /// Coins check-in untuk hari ke-[dayIndex]+1.
  int rewardFor(int dayIndex) => kCheckInRewards[dayIndex];

  factory LoyaltyInfo.fromJson(Map<String, dynamic> j) => LoyaltyInfo(
        balance: (j['balance'] as num).toInt(),
        lifetime: (j['lifetime'] as num).toInt(),
        streak: (j['streak'] as num? ?? 0).toInt(),
        lastCheckIn: j['last_check_in'] == null ? null : DateTime.parse(j['last_check_in'] as String),
        entries: [for (final e in (j['entries'] as List? ?? [])) CoinEntry.fromJson(e as Map<String, dynamic>)],
      );
}
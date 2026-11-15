import 'package:flutter/material.dart';

import 'models.dart';

// ---------------------------------------------------------------------------
// CLEANDRIVE MEMBERSHIP: produk BERBAYAR yang dibeli pengguna.
// Terpisah total dari Coins. Tidak ada kenaikan level otomatis.
//
// DATA CONTOH: harga, durasi, diskon, dan benefit di bawah adalah nilai awal.
// Nantinya diambil dari admin / API (MembershipPlans) tanpa mengubah kode layar.
// ---------------------------------------------------------------------------

enum MembershipTier {
  bronze('Bronze', Color(0xFFB0703A), Color(0xFFF1DCC6)),
  silver('Silver', Color(0xFF7D8AA3), Color(0xFFE3E8F0)),
  gold('Gold', Color(0xFFC98F12), Color(0xFFFBE7A6)),
  platinum('Platinum', Color(0xFF4A5B7D), Color(0xFFDCE4F2));

  const MembershipTier(this.label, this.color, this.soft);
  final String label;
  final Color color, soft;

  IconData get icon => this == MembershipTier.platinum ? Icons.diamond_rounded : Icons.workspace_premium_rounded;

  /// Peringkat voucher: 0 = semua pengguna, 1 = Bronze ke atas, dst.
  int get rank => index + 1;
}

class MembershipPlan {
  final MembershipTier tier;
  final int price; // rupiah
  final int durationDays;
  final int discountPct; // diskon jasa layanan (cuci dan ganti oli)
  final String priority; // prioritas booking
  final List<String> benefits;
  final String promo; // promo eksklusif
  final bool popular;
  const MembershipPlan({
    required this.tier,
    required this.price,
    required this.durationDays,
    required this.discountPct,
    required this.priority,
    required this.benefits,
    required this.promo,
    this.popular = false,
  });

  String get name => tier.label;
  String get durationLabel => durationDays % 30 == 0 ? '${durationDays ~/ 30} bulan' : '$durationDays hari';

  /// Potongan untuk harga jasa layanan.
  int discountFor(int servicePrice) => servicePrice * discountPct ~/ 100;

  factory MembershipPlan.fromJson(Map<String, dynamic> j) => MembershipPlan(
        tier: MembershipTier.values.firstWhere((t) => t.name == j['tier'], orElse: () => MembershipTier.bronze),
        price: (j['price'] as num).toInt(),
        durationDays: (j['duration_days'] as num).toInt(),
        discountPct: (j['discount_pct'] as num).toInt(),
        priority: j['priority'] as String,
        benefits: [for (final b in (j['benefits'] as List? ?? [])) b as String],
        promo: (j['promo'] ?? '') as String,
        popular: (j['popular'] ?? false) as bool,
      );
}

/// Paket bawaan (data contoh). Mudah diubah.
const kMembershipPlans = <MembershipPlan>[
  MembershipPlan(
    tier: MembershipTier.bronze,
    price: 49000,
    durationDays: 90,
    discountPct: 5,
    priority: 'Prioritas standar',
    promo: 'Voucher Bronze Rp 5.000',
    benefits: ['Diskon jasa layanan 5%', 'Akses promo member', 'Voucher eksklusif Bronze'],
  ),
  MembershipPlan(
    tier: MembershipTier.silver,
    price: 99000,
    durationDays: 90,
    discountPct: 10,
    priority: 'Prioritas booking',
    promo: 'Voucher Silver Rp 15.000',
    benefits: ['Diskon jasa layanan 10%', 'Prioritas booking', 'Voucher eksklusif Silver'],
  ),
  MembershipPlan(
    tier: MembershipTier.gold,
    price: 199000,
    durationDays: 90,
    discountPct: 20,
    priority: 'Prioritas tinggi',
    promo: 'Voucher Gold diskon 20%',
    popular: true,
    benefits: ['Diskon jasa layanan 20%', 'Prioritas booking tinggi', 'Voucher eksklusif Gold', 'Promo spesial member'],
  ),
  MembershipPlan(
    tier: MembershipTier.platinum,
    price: 399000,
    durationDays: 90,
    discountPct: 30,
    priority: 'Prioritas utama',
    promo: 'Voucher Platinum Rp 50.000',
    benefits: [
      'Diskon jasa layanan 30%',
      'Prioritas booking utama',
      'Voucher eksklusif Platinum',
      'Promo eksklusif bulanan',
    ],
  ),
];

MembershipPlan planOf(MembershipTier t) => kMembershipPlans.firstWhere((p) => p.tier == t);

enum MembershipStatus {
  none('Belum berlangganan', Color(0xFF7B879B)),
  pending('Menunggu pembayaran', Color(0xFFE9A23B)),
  active('Aktif', Color(0xFF249B62)),
  expired('Kedaluwarsa', Color(0xFFD92D35)),
  cancelled('Dibatalkan', Color(0xFF7B879B));

  const MembershipStatus(this.label, this.color);
  final String label;
  final Color color;
}

/// Langganan milik pengguna (satu per pengguna).
class UserMembership {
  final String id;
  final MembershipTier tier;
  final MembershipStatus status; // active | expired | cancelled
  final DateTime? startDate, endDate;
  const UserMembership({required this.id, required this.tier, required this.status, this.startDate, this.endDate});

  bool get isActive => status == MembershipStatus.active && endDate != null && endDate!.isAfter(DateTime.now());
  MembershipPlan get plan => planOf(tier);

  int get daysLeft {
    final e = endDate;
    if (e == null) return 0;
    final d = e.difference(DateTime.now()).inHours;
    return d <= 0 ? 0 : (d / 24).ceil();
  }

  /// Persentase sisa masa aktif (untuk bar progres kartu).
  double get remaining {
    final s = startDate, e = endDate;
    if (s == null || e == null) return 0;
    final total = e.difference(s).inMinutes;
    if (total <= 0) return 0;
    return (e.difference(DateTime.now()).inMinutes / total).clamp(0.0, 1.0).toDouble();
  }
}

/// Pesanan pembelian membership (siklus pembayaran tersendiri, terpisah dari booking).
class MembershipOrder {
  final String id, trx;
  final MembershipTier tier;
  final int amount;
  final PayMethod method;
  final bool renewal;
  String status; // pending | paid | expired | cancelled
  final DateTime expiresAt;
  final String? qrString;
  final int? balance;
  final bool sandbox;

  MembershipOrder({
    required this.id,
    required this.trx,
    required this.tier,
    required this.amount,
    required this.method,
    required this.status,
    required this.expiresAt,
    this.renewal = false,
    this.qrString,
    this.balance,
    this.sandbox = true,
  });

  bool get paid => status == 'paid';
  bool get expired => status == 'expired' || (status == 'pending' && DateTime.now().isAfter(expiresAt));
  MembershipPlan get plan => planOf(tier);
}

/// Riwayat transaksi membership (terpisah dari riwayat Coins).
class MembershipTransaction {
  final String id, trx;
  final MembershipTier tier;
  final int amount;
  final PayMethod method;
  final bool renewal;
  final DateTime createdAt;
  const MembershipTransaction({
    required this.id,
    required this.trx,
    required this.tier,
    required this.amount,
    required this.method,
    required this.renewal,
    required this.createdAt,
  });
}

class MembershipInfo {
  final UserMembership? current;
  final MembershipOrder? pending;
  final List<MembershipTransaction> history;
  const MembershipInfo({this.current, this.pending, this.history = const []});

  bool get hasActive => current?.isActive ?? false;
  MembershipTier? get activeTier => hasActive ? current!.tier : null;

  MembershipStatus get status {
    if (hasActive) return MembershipStatus.active;
    final p = pending;
    if (p != null && !p.expired) return MembershipStatus.pending;
    final c = current;
    if (c == null) return MembershipStatus.none;
    return c.status == MembershipStatus.cancelled ? MembershipStatus.cancelled : MembershipStatus.expired;
  }

  /// Diskon membership untuk harga jasa layanan (0 bila tidak ada membership aktif).
  int discountFor(int servicePrice) => hasActive ? current!.plan.discountFor(servicePrice) : 0;

  /// Peringkat untuk voucher eksklusif: 0 = tanpa membership aktif.
  int get rank => hasActive ? current!.tier.rank : 0;
}
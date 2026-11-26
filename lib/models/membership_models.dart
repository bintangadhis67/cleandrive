import 'package:flutter/material.dart';

import 'models.dart';

// ---------------------------------------------------------------------------
// CLEANDRIVE MEMBERSHIP: produk BERBAYAR yang dibeli pengguna.
// Terpisah total dari Coins. Tidak ada kenaikan level otomatis.
//
// Masa aktif semua paket: 1 bulan (30 hari). Tiap paket punya jatah cuci gratis: maksimal 1x per minggu (Senin-Minggu)
// dan total kuota selama masa aktif (Bronze 2x, Silver 3x, Gold 4x, Platinum 4x).
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

  /// Jumlah voucher yang boleh diklaim per hari: Bronze/Silver 1x, Gold 2x, Platinum 3x.
  int get dailyVoucherLimit => this == MembershipTier.gold ? 2 : (this == MembershipTier.platinum ? 3 : 1);
}

/// Kuota klaim voucher per hari untuk pengguna tanpa membership aktif.
const kBaseDailyVoucherLimit = 1;

class MembershipPlan {
  final MembershipTier tier;
  final int price; // rupiah
  final int durationDays;
  final int discountPct; // diskon jasa layanan (cuci dan ganti oli)
  final String priority; // prioritas booking
  final List<String> benefits;
  final String promo; // promo eksklusif
  final bool popular;

  /// Cuci gratis: nama paket ('Express' / 'Reguler' / 'Detailing'), kosong = tidak ada.
  final String freePackage;
  final int freeWashQuota; // total jatah selama masa aktif (maksimal 1x per minggu)
  final Set<VehicleType> freeVehicles; // kendaraan yang boleh memakai cuci gratis
  final bool snack; // makanan dan minuman gratis selama pencucian
  final bool vip; // ruang tunggu VIP (TV dan AC)
  final bool massage; // kursi pijat selama menunggu proses pencucian
  const MembershipPlan({
    required this.tier,
    required this.price,
    required this.durationDays,
    required this.discountPct,
    required this.priority,
    required this.benefits,
    required this.promo,
    this.popular = false,
    this.freePackage = '',
    this.freeWashQuota = 0,
    this.freeVehicles = const {},
    this.snack = false,
    this.vip = false,
    this.massage = false,
  });

  String get name => tier.label;

  bool get hasFreeWash => freePackage.isNotEmpty && freeWashQuota > 0;

  /// Mis. "Motor & Mobil" atau "Semua kendaraan".
  String get freeVehiclesLabel => freeVehicles.map((v) => v.label).join(' & ');

  /// Mis. "2x Express Wash (Motor & Mobil)".
  String get freeWashLabel => hasFreeWash ? '${freeWashQuota}x $freePackage Wash ($freeVehiclesLabel)' : 'Tidak ada';

  /// Benefit kunjungan: makanan dan minuman gratis, ruang tunggu VIP.
  List<String> get visitPerks => [
        if (snack) 'Makanan & minuman gratis',
        if (vip) 'Ruang tunggu VIP (TV & AC)',
        if (massage) 'Kursi pijat saat menunggu',
      ];
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
        freePackage: (j['free_package'] ?? '') as String,
        freeWashQuota: (j['free_wash_quota'] as num? ?? 0).toInt(),
        freeVehicles: {
          for (final v in (j['free_vehicles'] as List? ?? const [])) vehicleFrom(v as String),
        },
        snack: (j['snack'] ?? false) as bool,
        vip: (j['vip'] ?? false) as bool,
        massage: (j['massage'] ?? false) as bool,
      );
}

/// Paket bawaan (data contoh). Mudah diubah.
/// Semua paket berlaku 1 bulan (30 hari).
final List<MembershipPlan> kMembershipPlans = <MembershipPlan>[
  MembershipPlan(
    tier: MembershipTier.bronze,
    price: 99000,
    durationDays: 30,
    discountPct: 5,
    priority: 'Prioritas standar',
    promo: 'Voucher Bronze Rp 5.000 / minggu',
    freePackage: 'Express',
    freeWashQuota: 2,
    freeVehicles: {VehicleType.motor, VehicleType.mobil},
    benefits: [
      'Gratis 2x Express Wash (Motor & Mobil)',
      'Diskon jasa layanan 5%',
      'Voucher eksklusif Bronze tiap minggu',
      'Akses promo member',
    ],
  ),
  MembershipPlan(
    tier: MembershipTier.silver,
    price: 149000,
    durationDays: 30,
    discountPct: 10,
    priority: 'Prioritas booking',
    promo: 'Voucher Silver Rp 10.000 / minggu',
    freePackage: 'Express',
    freeWashQuota: 3,
    freeVehicles: {VehicleType.motor, VehicleType.mobil},
    benefits: [
      'Gratis 3x Express Wash (Motor & Mobil)',
      'Diskon jasa layanan 10%',
      'Prioritas booking',
      'Voucher eksklusif Silver tiap minggu',
    ],
  ),
  MembershipPlan(
    tier: MembershipTier.gold,
    price: 599000,
    durationDays: 30,
    discountPct: 20,
    priority: 'Prioritas tinggi',
    promo: 'Voucher Gold 20% (maks. Rp 30.000) / minggu',
    popular: true,
    freePackage: 'Reguler',
    freeWashQuota: 4,
    freeVehicles: {VehicleType.motor, VehicleType.mobil},
    snack: true,
    vip: true,
    benefits: [
      'Gratis Reguler Wash 1x/minggu (Motor & Mobil)',
      'Makanan & minuman gratis saat cuci',
      'Ruang tunggu VIP (TV & AC)',
      'Diskon jasa layanan 20%',
      'Prioritas booking tinggi',
      'Voucher eksklusif Gold tiap minggu',
      'Klaim voucher 2x sehari',
    ],
  ),
  MembershipPlan(
    tier: MembershipTier.platinum,
    price: 999000,
    durationDays: 30,
    discountPct: 30,
    priority: 'Prioritas utama',
    promo: 'Voucher Platinum Rp 50.000 / minggu',
    freePackage: 'Detailing',
    freeWashQuota: 4,
    freeVehicles: {VehicleType.motor, VehicleType.mobil},
    snack: true,
    vip: true,
    massage: true,
    benefits: [
      'Gratis Detailing Wash 1x/minggu (Motor & Mobil)',
      'Makanan & minuman gratis saat cuci',
      'Ruang tunggu VIP (TV & AC)',
      'Kursi pijat saat menunggu proses pencucian',
      'Diskon jasa layanan 30%',
      'Prioritas booking utama',
      'Voucher eksklusif Platinum tiap minggu',
      'Klaim voucher 3x sehari',
    ],
  ),
];

/// Ganti paket bawaan dengan data dari server (per tingkatan). Tingkatan yang tidak ada di [list] dibiarkan.
void applyServerPlans(List<MembershipPlan> list) {
  for (final p in list) {
    final i = kMembershipPlans.indexWhere((x) => x.tier == p.tier);
    if (i >= 0) {
      kMembershipPlans[i] = p;
    } else {
      kMembershipPlans.add(p);
    }
  }
  kMembershipPlans.sort((a, b) => a.tier.index.compareTo(b.tier.index));
}

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

  /// true = langganan sudah dibatalkan: benefit tetap aktif sampai [endDate], lalu tidak diperpanjang dan tanpa refund.
  final bool cancelAtEnd;

  /// Jatah cuci gratis: total selama masa aktif, yang sudah terpakai, dan minggu mana saja yang sudah terpakai.
  final int freeTotal, freeUsed;
  final Set<String> freeWeeks; // kunci minggu (lihat weekKey) yang jatah cuci gratisnya sudah dipakai
  const UserMembership({
    required this.id,
    required this.tier,
    required this.status,
    this.startDate,
    this.endDate,
    this.cancelAtEnd = false,
    this.freeTotal = 0,
    this.freeUsed = 0,
    this.freeWeeks = const {},
  });

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

  /// Sisa jatah cuci gratis selama masa aktif.
  int get freeLeft => freeTotal > freeUsed ? freeTotal - freeUsed : 0;

  /// Apakah jatah cuci gratis minggu ini (Senin-Minggu) sudah dipakai.
  bool get freeUsedThisWeek => freeWeeks.contains(weekKey(DateTime.now()));

  /// Alasan cuci gratis TIDAK bisa dipakai untuk pesanan ini (null = boleh).
  /// Aturan: paket dan kendaraan sesuai, jadwal dalam masa aktif, kuota masih ada, dan 1x per minggu.
  String? freeWashBlock(WashPackage pack, VehicleType v, DateTime slot) {
    final p = plan;
    if (!isActive) return 'Membership tidak aktif.';
    if (!p.hasFreeWash) return 'Paket ${p.name} tidak mendapat cuci gratis.';
    if (pack.kind != ServiceKind.wash || pack.name != p.freePackage) {
      return 'Cuci gratis ${p.name} hanya untuk paket ${p.freePackage} Wash.';
    }
    if (!p.freeVehicles.contains(v)) return 'Cuci gratis ${p.name} hanya untuk ${p.freeVehiclesLabel}.';
    final end = endDate;
    if (end != null && slot.isAfter(end)) {
      return 'Jadwal ini melewati masa aktif membership (berakhir ${end.day}/${end.month}/${end.year}).';
    }
    if (freeLeft <= 0) return 'Kuota cuci gratis membership sudah habis.';
    if (freeWeeks.contains(weekKey(slot))) {
      return 'Cuci gratis di minggu itu sudah terpakai (maksimal 1x per minggu). Pilih tanggal di minggu lain.';
    }
    return null;
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

  /// true = pengembalian dana akibat langganan dibatalkan.
  final bool refund;
  const MembershipTransaction({
    required this.id,
    required this.trx,
    required this.tier,
    required this.amount,
    required this.method,
    required this.renewal,
    required this.createdAt,
    this.refund = false,
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

  /// Kuota klaim voucher per hari (1x, Gold 2x, Platinum 3x).
  int get dailyVoucherLimit => hasActive ? current!.tier.dailyVoucherLimit : kBaseDailyVoucherLimit;

  /// Alasan cuci gratis tidak bisa dipakai (null = boleh). Server tetap memvalidasi ulang.
  String? freeWashBlock(WashPackage pack, VehicleType v, DateTime slot) =>
      hasActive ? current!.freeWashBlock(pack, v, slot) : 'Kamu belum punya membership aktif.';
}
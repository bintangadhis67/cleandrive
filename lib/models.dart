import 'package:flutter/material.dart';

// ---------------- kendaraan dan paket ----------------
enum VehicleType { motor, mobil, suv }

extension VehicleX on VehicleType {
  String get label => const {'motor': 'Motor', 'mobil': 'Mobil', 'suv': 'SUV'}[name]!;
  double get factor => const {'motor': 1.0, 'mobil': 2.0, 'suv': 2.5}[name]!;
}

VehicleType vehicleFrom(String s) =>
    VehicleType.values.firstWhere((v) => v.name == s, orElse: () => VehicleType.mobil);

class WashPackage {
  final String name, desc;
  final int basePrice, minutes;
  const WashPackage(this.name, this.desc, this.basePrice, this.minutes);
  int priceFor(VehicleType v) => (basePrice * v.factor).round();

  /// Gambar layanan: assets/images/svc_{paket}_{kendaraan}.png
  String imageFor(VehicleType v) => 'assets/images/svc_${name.toLowerCase()}_${v.name}.png';
}

const packages = [
  WashPackage('Express', 'Cuci luar + keringkan', 25000, 20),
  WashPackage('Reguler', 'Cuci luar, vakum interior, semir ban', 50000, 40),
  WashPackage('Detailing', 'Poles body, cuci mesin, interior deep clean', 150000, 120),
];

WashPackage packageByName(String n) =>
    packages.firstWhere((p) => p.name.toLowerCase() == n.toLowerCase(), orElse: () => packages[1]);

const statusLabels = ['Menunggu', 'Dicuci', 'Finishing', 'Selesai'];

String rp(int n) =>
    'Rp ${n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';

int _i(dynamic v) => (v as num).toInt();
DateTime _dt(dynamic v) => DateTime.parse(v as String);

// ---------------- pembayaran ----------------
enum PayMethod {
  qris('QRIS', 'Bayar dengan QR Code', Color(0xFF111111), Icons.qr_code_2_rounded),
  gopay('GoPay', 'Bayar dengan GoPay', Color(0xFF00AED6), Icons.account_balance_wallet_rounded),
  ovo('OVO', 'Bayar dengan OVO', Color(0xFF4C2A86), Icons.radio_button_unchecked_rounded),
  dana('DANA', 'Bayar dengan DANA', Color(0xFF118EEA), Icons.blur_circular_rounded),
  shopeepay('ShopeePay', 'Bayar dengan ShopeePay', Color(0xFFEE4D2D), Icons.account_balance_wallet_outlined);

  const PayMethod(this.label, this.hint, this.color, this.icon);
  final String label, hint;
  final Color color;
  final IconData icon;
  bool get isQris => this == qris;
}

PayMethod payMethodFrom(String s) =>
    PayMethod.values.firstWhere((m) => m.name == s, orElse: () => PayMethod.qris);

class Payment {
  final String id, trx, bookingId;
  final PayMethod method;
  final int amount;
  String status; // pending | paid | expired
  final DateTime expiresAt;
  final String? qrString;
  final int? balance;
  final bool sandbox;
  Payment({
    required this.id,
    required this.trx,
    required this.bookingId,
    required this.method,
    required this.amount,
    required this.status,
    required this.expiresAt,
    this.qrString,
    this.balance,
    this.sandbox = true,
  });

  bool get paid => status == 'paid';
  bool get expired => status == 'expired' || (status == 'pending' && DateTime.now().isAfter(expiresAt));

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
        id: j['id'].toString(),
        trx: j['trx'] as String,
        bookingId: j['booking_id'].toString(),
        method: payMethodFrom(j['method'] as String),
        amount: _i(j['amount']),
        status: j['status'] as String,
        expiresAt: _dt(j['expires_at']),
        qrString: j['qr_string'] as String?,
        balance: j['balance'] == null ? null : _i(j['balance']),
        sandbox: (j['sandbox'] ?? true) as bool,
      );
}

// ---------------- voucher ----------------
class Voucher {
  final String id, code, title;
  final int amount; // potongan tetap (rupiah), 0 jika persen
  final int percent; // potongan persen, 0 jika tetap
  final int maxDiscount; // batas potongan untuk persen (0 = tanpa batas)
  final int minTransaction;
  final DateTime validUntil;
  final List<String> terms;
  bool claimed, used;

  Voucher({
    required this.id,
    required this.code,
    required this.title,
    required this.amount,
    required this.percent,
    required this.maxDiscount,
    required this.minTransaction,
    required this.validUntil,
    required this.terms,
    this.claimed = false,
    this.used = false,
  });

  bool get expired => DateTime.now().isAfter(validUntil.add(const Duration(days: 1)));
  bool get usable => claimed && !used && !expired;
  bool eligible(int price) => price >= minTransaction;

  int discountFor(int price) {
    if (!eligible(price)) return 0;
    if (amount > 0) return amount > price ? price : amount;
    var d = price * percent ~/ 100;
    if (maxDiscount > 0 && d > maxDiscount) d = maxDiscount;
    return d;
  }

  String get headline => amount > 0 ? 'Diskon ${rp(amount)}' : 'Diskon $percent%';
  String get shortValue => amount > 0 ? rp(amount) : '$percent%';
  String get note => amount > 0 ? '' : (maxDiscount > 0 ? 'Maks. ${rp(maxDiscount)}' : '');

  factory Voucher.fromJson(Map<String, dynamic> j) => Voucher(
        id: j['id'].toString(),
        code: j['code'] as String,
        title: (j['title'] ?? j['code']) as String,
        amount: _i(j['amount'] ?? 0),
        percent: _i(j['percent'] ?? 0),
        maxDiscount: _i(j['max_discount'] ?? 0),
        minTransaction: _i(j['min_transaction'] ?? 0),
        validUntil: _dt(j['valid_until']),
        terms: [for (final t in (j['terms'] as List? ?? [])) t as String],
        claimed: (j['claimed'] ?? false) as bool,
        used: (j['used'] ?? false) as bool,
      );
}

// ---------------- ulasan ----------------
class Review {
  final int rating;
  final String comment;
  final DateTime createdAt;
  const Review(this.rating, this.comment, this.createdAt);

  factory Review.fromJson(Map<String, dynamic> j) =>
      Review(_i(j['rating']), (j['comment'] ?? '') as String, _dt(j['created_at']));
}

String ratingLabel(int r) => const ['', 'Sangat Buruk', 'Kurang Puas', 'Cukup', 'Puas', 'Sangat Puas'][r.clamp(1, 5)];

// ---------------- pesanan ----------------
class Booking {
  final String id, code, plate;
  String owner;
  final VehicleType vehicle;
  final WashPackage pack;
  final DateTime slot;
  DateTime estFinish;
  final int price; // harga sebelum voucher
  int discount;
  String? voucherCode;
  int status; // index pada statusLabels
  bool verified; // sudah discan/diverifikasi petugas saat tiba
  bool cancelled;
  String payStatus; // unpaid | paid | refunded
  PayMethod? payMethod;
  String? trx;
  Review? review;
  int queuePosition;

  Booking({
    required this.id,
    required this.code,
    required this.plate,
    required this.owner,
    required this.vehicle,
    required this.pack,
    required this.slot,
    required this.estFinish,
    required this.price,
    this.discount = 0,
    this.voucherCode,
    this.status = 0,
    this.verified = false,
    this.cancelled = false,
    this.payStatus = 'unpaid',
    this.payMethod,
    this.trx,
    this.review,
    this.queuePosition = 0,
  });

  int get total => price - discount;
  bool get paid => payStatus == 'paid';
  bool get active => !cancelled && status < 3;
  bool get cancellable => !cancelled && status == 0 && !verified;

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: j['id'].toString(),
        code: j['code'] as String,
        plate: j['plate'] as String,
        owner: (j['owner'] ?? '') as String,
        vehicle: vehicleFrom(j['vehicle'] as String),
        pack: packageByName(j['package'] as String),
        slot: _dt(j['slot']),
        estFinish: _dt(j['est_finish']),
        price: _i(j['price']),
        discount: _i(j['discount'] ?? 0),
        voucherCode: j['voucher_code'] as String?,
        status: _i(j['status']),
        verified: (j['verified'] ?? false) as bool,
        cancelled: (j['cancelled'] ?? false) as bool,
        payStatus: (j['pay_status'] ?? 'unpaid') as String,
        payMethod: j['pay_method'] == null ? null : payMethodFrom(j['pay_method'] as String),
        trx: j['trx'] as String?,
        review: j['review'] == null ? null : Review.fromJson(j['review'] as Map<String, dynamic>),
        queuePosition: _i(j['queue_position'] ?? 0),
      );
}

import 'package:flutter/material.dart';

import 'catalog.dart';
import 'loyalty_models.dart';

// ---------------- kendaraan dan paket ----------------
enum VehicleType { motor, mobil, suv }

extension VehicleX on VehicleType {
  String get label => const {'motor': 'Motor', 'mobil': 'Mobil', 'suv': 'SUV'}[name]!;
  double get factor => const {'motor': 1.0, 'mobil': 2.0, 'suv': 2.5}[name]!;
}

VehicleType vehicleFrom(String s) =>
    VehicleType.values.firstWhere((v) => v.name == s, orElse: () => VehicleType.mobil);

/// Jenis pesanan: cuci, ganti oli, atau belanja di toko.
enum ServiceKind { wash, oil, shop }

class WashPackage {
  final String name, desc;
  final int basePrice, minutes;
  final ServiceKind kind;
  const WashPackage(this.name, this.desc, this.basePrice, this.minutes, {this.kind = ServiceKind.wash});

  bool get isOil => kind == ServiceKind.oil;
  bool get isShop => kind == ServiceKind.shop;

  String get title => kind == ServiceKind.wash ? '$name Wash' : name;

  int priceFor(VehicleType v) => (basePrice * v.factor).round();

  /// Gambar layanan. Cuci: assets/images/svc_{paket}_{kendaraan}.png
  String imageFor(VehicleType v) {
    switch (kind) {
      case ServiceKind.wash:
        return 'assets/images/svc_${name.toLowerCase()}_${v.name}.png';
      case ServiceKind.oil:
        return v == VehicleType.motor ? 'assets/images/Oli_3.jpeg' : 'assets/images/Oli_4.jpeg';
      case ServiceKind.shop:
        return 'assets/images/Makanan_Ringan_8.jpeg';
    }
  }

  /// Label status (indeks 0-3) sesuai jenis pesanan.
  List<String> get statusNames {
    switch (kind) {
      case ServiceKind.wash:
        return statusLabels;
      case ServiceKind.oil:
        return const ['Menunggu', 'Ganti Oli', 'Finishing', 'Selesai'];
      case ServiceKind.shop:
        return const ['Belum Dibayar', 'Dibeli', 'Dibeli', 'Dibeli'];
    }
  }

  List<String> get stageNames {
    switch (kind) {
      case ServiceKind.wash:
        return const ['Menunggu giliran', 'Sedang dicuci', 'Finishing', 'Siap diambil'];
      case ServiceKind.oil:
        return const ['Menunggu giliran', 'Oli sedang diganti', 'Finishing', 'Siap diambil'];
      case ServiceKind.shop:
        return const ['Menunggu pembayaran', 'Pembayaran diterima', 'Pembelian berhasil', 'Pembelian berhasil'];
    }
  }

  List<String> get headlines {
    switch (kind) {
      case ServiceKind.wash:
        return const [
          'Kendaraanmu menunggu giliran',
          'Kendaraanmu sedang dicuci!',
          'Hampir selesai, tahap finishing!',
          'Cucian selesai, siap diambil!',
        ];
      case ServiceKind.oil:
        return const [
          'Kendaraanmu menunggu giliran',
          'Oli kendaraanmu sedang diganti!',
          'Hampir selesai, tahap finishing!',
          'Ganti oli selesai, siap diambil!',
        ];
      case ServiceKind.shop:
        return const [
          'Menunggu pembayaran',
          'Pembelian berhasil!',
          'Pembelian berhasil!',
          'Pembelian berhasil, terima kasih!',
        ];
    }
  }
}

const packages = [
  WashPackage('Express', 'Cuci luar + keringkan', 25000, 20),
  WashPackage('Reguler', 'Cuci luar, vakum interior, semir ban', 50000, 40),
  WashPackage('Detailing', 'Poles body, cuci mesin, interior deep clean', 150000, 120),
];

/// Jasa penggantian oli (harga jasa per jenis kendaraan; harga oli dihitung terpisah).
const oilChangePackage = WashPackage(
    'Ganti Oli', 'Jasa penggantian oli mesin + cek level cairan', 20000, 30,
    kind: ServiceKind.oil);

/// Pembelian langsung di Toko (makanan, minuman, oli) tanpa booking: bayar, lalu selesai.
const shopPackage = WashPackage('Pembelian Toko', 'Pembelian langsung di Toko CleanDrive', 0, 5, kind: ServiceKind.shop);

const allServices = [...packages, oilChangePackage, shopPackage];

WashPackage packageByName(String n) =>
    allServices.firstWhere((p) => p.name.toLowerCase() == n.toLowerCase(), orElse: () => packages[1]);

const statusLabels = ['Menunggu', 'Dicuci', 'Finishing', 'Selesai'];

String rp(int n) =>
    'Rp ${n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';

int _i(dynamic v) => (v as num).toInt();
DateTime _dt(dynamic v) => DateTime.parse(v as String);

// ---------------- produk toko ----------------
enum ProductCategory {
  makanan('Makanan', Icons.fastfood_rounded),
  minuman('Minuman', Icons.local_drink_rounded),
  oli('Oli', Icons.opacity_rounded);

  const ProductCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

class Product {
  final String id, name, desc, image;
  final int price;
  final ProductCategory category;

  /// Stok awal (data tiruan). Stok yang berjalan dikelola repository, baca lewat app.stockOf(produk).
  final int stock;

  /// Khusus oli: jenis kendaraan yang cocok. Kosong = cocok untuk semua.
  final Set<VehicleType> vehicles;

  const Product(this.id, this.name, this.desc, this.price, this.category, this.image,
      {this.vehicles = const {}, this.stock = 20});

  bool fits(VehicleType v) => vehicles.isEmpty || vehicles.contains(v);

  /// Label kendaraan untuk oli ("Motor" atau "Mobil"), kosong untuk produk lain.
  String get vehicleTag {
    if (vehicles.isEmpty) return '';
    return vehicles.contains(VehicleType.motor) ? 'Motor' : 'Mobil';
  }
}

class OrderLine {
  final Product product;
  final int qty;
  const OrderLine(this.product, this.qty);
  int get subtotal => product.price * qty;
}

// ---------------- pembayaran ----------------
enum PayMethod {
  qris('QRIS', 'Bayar dengan QR Code', Color(0xFF111111), Icons.qr_code_2_rounded),
  gopay('GoPay', 'Bayar dengan GoPay', Color(0xFF00AED6), Icons.account_balance_wallet_rounded),
  ovo('OVO', 'Bayar dengan OVO', Color(0xFF4C2A86), Icons.radio_button_unchecked_rounded),
  dana('DANA', 'Bayar dengan DANA', Color(0xFF118EEA), Icons.blur_circular_rounded),
  shopeepay('ShopeePay', 'Bayar dengan ShopeePay', Color(0xFFEE4D2D), Icons.account_balance_wallet_outlined),
  livin("Livin' by Mandiri", "Bayar dengan Livin' by Mandiri", Color(0xFF003D79), Icons.account_balance_rounded);

  const PayMethod(this.label, this.hint, this.color, this.icon);
  final String label, hint;
  final Color color;
  final IconData icon;
  bool get isQris => this == qris;
  bool get isBank => this == livin;
}

PayMethod payMethodFrom(String s) =>
    PayMethod.values.firstWhere((m) => m.name == s, orElse: () => PayMethod.qris);

class Payment {
  final String id, trx, bookingId;
  final PayMethod method;

  /// Total yang dibayar (sudah dipotong Coins bila ada).
  final int amount;
  final int coinsUsed, coinDiscount;
  String status; // pending | paid | expired
  final DateTime expiresAt;
  final String? qrString;
  final int? balance;
  final bool sandbox;

  /// Diisi setelah pembayaran berhasil.
  int coinsEarned;
  Tier? levelUp;

  Payment({
    required this.id,
    required this.trx,
    required this.bookingId,
    required this.method,
    required this.amount,
    required this.status,
    required this.expiresAt,
    this.coinsUsed = 0,
    this.coinDiscount = 0,
    this.qrString,
    this.balance,
    this.sandbox = true,
    this.coinsEarned = 0,
    this.levelUp,
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
        coinsUsed: _i(j['coins_used'] ?? 0),
        coinDiscount: _i(j['coin_discount'] ?? 0),
        qrString: j['qr_string'] as String?,
        balance: j['balance'] == null ? null : _i(j['balance']),
        sandbox: (j['sandbox'] ?? true) as bool,
        coinsEarned: _i(j['coins_earned'] ?? 0),
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
  final int minTier; // indeks Tier minimal (0 = untuk semua)
  final bool locked; // level membership pengguna belum cukup
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
    this.minTier = 0,
    this.locked = false,
    this.claimed = false,
    this.used = false,
  });

  bool get expired => DateTime.now().isAfter(validUntil.add(const Duration(days: 1)));
  bool get usable => claimed && !used && !expired;
  bool get claimable => !claimed && !expired && !locked;
  bool eligible(int price) => price >= minTransaction;
  String get tierLabel => Tier.values[minTier].label;

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
        minTier: _i(j['min_tier'] ?? 0),
        locked: (j['locked'] ?? false) as bool,
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
  final int price; // harga jasa + produk, sebelum voucher dan Coins
  int discount; // potongan voucher
  String? voucherCode;
  final List<OrderLine> items; // produk (oli, makanan, minuman)
  int coinsUsed, coinDiscount, coinsEarned;
  int status; // index pada pack.statusNames
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
    this.items = const [],
    this.coinsUsed = 0,
    this.coinDiscount = 0,
    this.coinsEarned = 0,
    this.status = 0,
    this.verified = false,
    this.cancelled = false,
    this.payStatus = 'unpaid',
    this.payMethod,
    this.trx,
    this.review,
    this.queuePosition = 0,
  });

  int get total => price - discount - coinDiscount;
  int get itemCount => items.fold(0, (s, l) => s + l.qty);
  int get itemsTotal => items.fold(0, (s, l) => s + l.subtotal);
  int get servicePrice => price - itemsTotal;
  bool get paid => payStatus == 'paid';
  bool get active => !cancelled && status < 3;
  bool get cancellable => !cancelled && status == 0 && !verified;
  String get statusLabel => pack.statusNames[status];

  /// Judul singkat untuk kartu/daftar.
  String get label => pack.isShop ? 'Pembelian Toko • $itemCount item' : '${pack.name} • $plate';
  String get subtitle => pack.isShop ? 'Pembelian Toko • $itemCount item' : '${pack.title} • ${vehicle.label}';

  static List<OrderLine> _lines(dynamic raw) {
    final out = <OrderLine>[];
    for (final e in (raw as List? ?? const [])) {
      final m = e as Map<String, dynamic>;
      final p = productById(m['product_id'].toString());
      if (p != null) out.add(OrderLine(p, _i(m['qty'])));
    }
    return out;
  }

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
        items: _lines(j['items']),
        coinsUsed: _i(j['coins_used'] ?? 0),
        coinDiscount: _i(j['coin_discount'] ?? 0),
        coinsEarned: _i(j['coins_earned'] ?? 0),
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
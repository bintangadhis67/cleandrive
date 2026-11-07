import 'package:intl/intl.dart';

import '../models.dart';
import 'repository.dart';

class _MockUser {
  String name, email, phone, pass;
  final bool isAdmin;
  _MockUser(this.name, this.email, this.phone, this.pass, {this.isAdmin = false});
  SessionUser get session => SessionUser(name: name, email: email, phone: phone, isAdmin: isAdmin);
}

class _Tpl {
  final String id, code, title;
  final int amount, percent, maxDiscount, minTransaction, validDays;
  final List<String> terms;
  const _Tpl(this.id, this.code, this.title, this.amount, this.percent, this.maxDiscount, this.minTransaction,
      this.validDays, this.terms);
}

/// Data tiruan di memori supaya UI bisa dijalankan tanpa backend.
/// Akun demo: admin@cleandrive.com / admin123 dan budi@mail.com / 123456
class MockRepository implements Repository {
  static const _balances = {
    PayMethod.gopay: 120000,
    PayMethod.ovo: 200000,
    PayMethod.dana: 90000,
    PayMethod.shopeepay: 75000,
  };

  static const _tpls = [
    _Tpl('v1', 'VOUCHER-20K', 'Voucher Spesial', 20000, 0, 0, 75000, 30,
        ['Berlaku untuk semua paket', 'Tidak dapat digabung dengan promo lain', 'Berlaku 1 kali per akun']),
    _Tpl('v2', 'HEMAT10', 'Hemat 10%', 0, 10, 15000, 50000, 14,
        ['Potongan 10% maksimal Rp 15.000', 'Berlaku untuk semua paket', 'Berlaku 1 kali per akun']),
    _Tpl('v3', 'WELCOME-10K', 'Selamat Datang', 10000, 0, 0, 40000, 60,
        ['Khusus pengguna baru', 'Berlaku untuk semua paket', 'Berlaku 1 kali per akun']),
  ];

  final List<_MockUser> _users = [
    _MockUser('Admin CleanDrive', 'admin@cleandrive.com', '', 'admin123', isAdmin: true),
    _MockUser('Budi Santoso', 'budi@mail.com', '081200000002', '123456'),
  ];
  _MockUser? _me;

  final List<Booking> _bookings = [];
  final Map<String, String> _owner = {}; // bookingId -> email
  final Map<String, String> _claims = {}; // "email|voucherId" -> bookingId pemakai ('' = belum dipakai)
  final Map<String, Payment> _payments = {};
  int _bookingSeq = 0, _paySeq = 0;

  MockRepository() {
    _seedHistory();
  }

  Future<void> _lag([int ms = 250]) => Future.delayed(Duration(milliseconds: ms));
  _MockUser get _u => _me ?? (throw ApiException('Silakan masuk dulu.'));

  void _seedHistory() {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final rows = [
      (VehicleType.mobil, packages[1], 'L 1234 AB', 10, 3, 5, 'Pelayanannya cepat, mobil jadi bersih banget. Recommended!'),
      (VehicleType.motor, packages[0], 'W 5678 CD', 14, 5, 4, 'Proses cepat dan hasilnya memuaskan.'),
      (VehicleType.mobil, packages[2], 'L 1234 AB', 9, 9, 5, 'Detailing sangat rapi dan wangi.'),
    ];
    for (final r in rows) {
      final slot = day.subtract(Duration(days: r.$5)).add(Duration(hours: r.$4));
      final b = _make(_users[1], r.$1, r.$2, r.$3, slot, 0, null);
      b.status = 3;
      b.verified = true;
      b.payStatus = 'paid';
      b.payMethod = PayMethod.qris;
      b.trx = 'TRX-${DateFormat('yyMMdd').format(slot)}-${(++_paySeq).toString().padLeft(3, '0')}';
      b.estFinish = slot.add(Duration(minutes: r.$2.minutes));
      b.review = Review(r.$6, r.$7, slot.add(const Duration(hours: 3)));
    }
  }

  Booking _make(_MockUser u, VehicleType v, WashPackage p, String plate, DateTime slot, int discount, String? voucher) {
    final id = (++_bookingSeq).toString().padLeft(4, '0');
    final ahead = _bookings.where((b) => !b.cancelled && b.slot == slot).length;
    final clean = plate.replaceAll(' ', '').toUpperCase();
    final b = Booking(
      id: id,
      code: 'CD-$id-$clean',
      plate: plate.toUpperCase(),
      owner: u.name,
      vehicle: v,
      pack: p,
      slot: slot,
      estFinish: slot.add(Duration(minutes: p.minutes + ahead * 10)),
      price: p.priceFor(v),
      discount: discount,
      voucherCode: voucher,
    );
    _bookings.insert(0, b);
    _owner[id] = u.email;
    return b;
  }

  Booking _find(String id) =>
      _bookings.where((b) => b.id == id).firstOrNull ?? (throw ApiException('Pesanan tidak ditemukan.'));

  Booking _own(String id) {
    final b = _find(id);
    if (!_u.isAdmin && _owner[id] != _u.email) throw ApiException('Bukan pesananmu.');
    return b;
  }

  Booking _decorate(Booking b) {
    if (!b.active) {
      b.queuePosition = 0;
    } else {
      b.queuePosition = _bookings
              .where((o) =>
                  o.active &&
                  o.id != b.id &&
                  (o.slot.isBefore(b.slot) || (o.slot == b.slot && int.parse(o.id) < int.parse(b.id))))
              .length +
          1;
    }
    return b;
  }

  // ---------- auth ----------
  @override
  Future<SessionUser?> restore() async => null;

  @override
  Future<SessionUser> login(String email, String password) async {
    await _lag();
    final u = _users.where((e) => e.email.toLowerCase() == email.trim().toLowerCase()).firstOrNull;
    if (u == null || u.pass != password) throw ApiException('Email atau password salah');
    _me = u;
    return u.session;
  }

  @override
  Future<SessionUser> register(String name, String email, String phone, String password) async {
    await _lag();
    if (_users.any((e) => e.email.toLowerCase() == email.trim().toLowerCase())) {
      throw ApiException('Email sudah terdaftar. Gunakan email lain atau masuk.');
    }
    final u = _MockUser(name.trim(), email.trim(), phone.trim(), password);
    _users.add(u);
    _me = u;
    return u.session;
  }

  @override
  Future<void> logout() async => _me = null;

  @override
  Future<SessionUser> updateProfile(String name, String phone) async {
    final u = _u;
    for (final b in _bookings) {
      if (_owner[b.id] == u.email) b.owner = name;
    }
    u.name = name;
    u.phone = phone;
    return u.session;
  }

  @override
  Future<void> changePassword(String oldPass, String newPass) async {
    if (_u.pass != oldPass) throw ApiException('Password lama salah');
    _u.pass = newPass;
  }

  // ---------- pesanan ----------
  @override
  Future<List<Booking>> bookings() async {
    await _lag(150);
    final list = _u.isAdmin ? _bookings.toList() : _bookings.where((b) => _owner[b.id] == _u.email).toList();
    list.sort((a, b) => b.slot.compareTo(a.slot));
    return list.map(_decorate).toList();
  }

  @override
  Future<Booking> booking(String id) async => _decorate(_own(id));

  @override
  Future<Map<int, int>> slotCounts(DateTime day) async {
    await _lag(100);
    final m = <int, int>{};
    for (final b in _bookings) {
      if (!b.cancelled && b.slot.year == day.year && b.slot.month == day.month && b.slot.day == day.day) {
        m[b.slot.hour] = (m[b.slot.hour] ?? 0) + 1;
      }
    }
    return m;
  }

  Voucher _voucher(_Tpl t) {
    final key = '${_u.email}|${t.id}';
    return Voucher(
      id: t.id,
      code: t.code,
      title: t.title,
      amount: t.amount,
      percent: t.percent,
      maxDiscount: t.maxDiscount,
      minTransaction: t.minTransaction,
      validUntil: DateTime.now().add(Duration(days: t.validDays)),
      terms: t.terms,
      claimed: _claims.containsKey(key),
      used: (_claims[key] ?? '').isNotEmpty,
    );
  }

  @override
  Future<Booking> createBooking({
    required VehicleType vehicle,
    required WashPackage pack,
    required String plate,
    required DateTime slot,
    String? voucherCode,
  }) async {
    await _lag(400);
    if (plate.trim().isEmpty) throw ApiException('Plat nomor wajib diisi.');
    if (slot.isBefore(DateTime.now())) throw ApiException('Jam tersebut sudah lewat. Pilih jam lain.');
    final taken = _bookings.where((b) => !b.cancelled && b.slot == slot).length;
    if (taken >= 3) throw ApiException('Slot jam ${DateFormat('HH:mm').format(slot)} sudah penuh.');

    var discount = 0;
    String? code;
    if (voucherCode != null && voucherCode.isNotEmpty) {
      final t = _tpls.where((e) => e.code == voucherCode).firstOrNull;
      if (t == null) throw ApiException('Voucher tidak ditemukan.');
      final v = _voucher(t);
      if (!v.claimed) throw ApiException('Voucher belum diklaim.');
      if (v.used) throw ApiException('Voucher sudah pernah dipakai.');
      if (v.expired) throw ApiException('Voucher sudah kedaluwarsa.');
      final price = pack.priceFor(vehicle);
      if (!v.eligible(price)) throw ApiException('Minimal transaksi voucher ${rp(v.minTransaction)}.');
      discount = v.discountFor(price);
      code = v.code;
    }
    final b = _make(_u, vehicle, pack, plate, slot, discount, code);
    if (code != null) {
      final t = _tpls.firstWhere((e) => e.code == code);
      _claims['${_u.email}|${t.id}'] = b.id;
    }
    return _decorate(b);
  }

  @override
  Future<Booking> cancelBooking(String id) async {
    await _lag();
    final b = _own(id);
    if (b.cancelled) throw ApiException('Pesanan sudah dibatalkan.');
    if (!b.cancellable) throw ApiException('Pesanan yang sudah diproses tidak bisa dibatalkan.');
    b.cancelled = true;
    if (b.paid) b.payStatus = 'refunded';
    if (b.voucherCode != null) {
      _claims.removeWhere((k, v) => v == b.id);
      final t = _tpls.firstWhere((e) => e.code == b.voucherCode);
      _claims['${_owner[b.id]}|${t.id}'] = ''; // voucher kembali tersedia
    }
    return _decorate(b);
  }

  // ---------- voucher ----------
  @override
  Future<List<Voucher>> vouchers() async {
    await _lag(100);
    return _tpls.map(_voucher).toList();
  }

  @override
  Future<Voucher> claimVoucher(String id) async {
    await _lag();
    final t = _tpls.where((e) => e.id == id).firstOrNull ?? (throw ApiException('Voucher tidak ditemukan.'));
    final key = '${_u.email}|$id';
    if (_claims.containsKey(key)) throw ApiException('Voucher ini sudah kamu klaim.');
    _claims[key] = '';
    return _voucher(t);
  }

  // ---------- pembayaran (simulasi) ----------
  @override
  Future<Payment> startPayment(String bookingId, PayMethod method) async {
    await _lag(300);
    final b = _own(bookingId);
    if (b.cancelled) throw ApiException('Pesanan sudah dibatalkan.');
    if (b.paid) throw ApiException('Pesanan ini sudah dibayar.');
    final n = ++_paySeq;
    final trx = 'TRX-${DateFormat('yyMMdd').format(DateTime.now())}-${n.toString().padLeft(3, '0')}';
    final p = Payment(
      id: 'p$n',
      trx: trx,
      bookingId: bookingId,
      method: method,
      amount: b.total,
      status: 'pending',
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      qrString: method.isQris ? 'CLEANDRIVE-QRIS|$trx|${b.total}|${b.code}' : null,
      balance: method.isQris ? null : _balances[method],
    );
    _payments[p.id] = p;
    return p;
  }

  Payment _pay(String id) => _payments[id] ?? (throw ApiException('Transaksi tidak ditemukan.'));

  void _markPaid(Payment p) {
    p.status = 'paid';
    final b = _find(p.bookingId);
    b.payStatus = 'paid';
    b.payMethod = p.method;
    b.trx = p.trx;
  }

  @override
  Future<Payment> payment(String id) async {
    final p = _pay(id);
    if (p.status == 'pending' && DateTime.now().isAfter(p.expiresAt)) p.status = 'expired';
    return p;
  }

  @override
  Future<Payment> confirmPayment(String id) async {
    await _lag(500);
    final p = _pay(id);
    if (p.method.isQris) throw ApiException('Pembayaran QRIS dilakukan dengan scan QR.');
    if (p.status == 'paid') return p;
    if (DateTime.now().isAfter(p.expiresAt)) {
      p.status = 'expired';
      throw ApiException('Waktu pembayaran sudah habis.');
    }
    if ((p.balance ?? 0) < p.amount) throw ApiException('Saldo ${p.method.label} tidak cukup.');
    _markPaid(p);
    return p;
  }

  @override
  Future<Payment> simulateQrisPaid(String id) async {
    await _lag(400);
    final p = _pay(id);
    if (p.status == 'paid') return p;
    if (DateTime.now().isAfter(p.expiresAt)) {
      p.status = 'expired';
      throw ApiException('QR sudah kedaluwarsa. Buat QR baru.');
    }
    _markPaid(p);
    return p;
  }

  // ---------- ulasan ----------
  @override
  Future<Booking> submitReview(String bookingId, int rating, String comment) async {
    await _lag();
    final b = _own(bookingId);
    if (b.cancelled || b.status != 3) throw ApiException('Ulasan hanya untuk pesanan yang sudah selesai.');
    if (b.review != null) throw ApiException('Pesanan ini sudah diulas.');
    if (rating < 1 || rating > 5) throw ApiException('Rating harus 1 sampai 5.');
    if (comment.length > 200) throw ApiException('Ulasan maksimal 200 karakter.');
    b.review = Review(rating, comment.trim(), DateTime.now());
    return b;
  }

  RatingSummary _rating() {
    final rs = _bookings.where((b) => b.review != null).map((b) => b.review!.rating).toList();
    if (rs.isEmpty) return const RatingSummary(0, 0);
    return RatingSummary(rs.reduce((a, b) => a + b) / rs.length, rs.length);
  }

  @override
  Future<RatingSummary> ratingSummary() async => _rating();

  // ---------- admin ----------
  @override
  Future<Booking> verify(String code) async {
    await _lag(300);
    final c = code.trim().toUpperCase();
    final b = _bookings.where((x) => x.code.toUpperCase() == c).firstOrNull ??
        (throw ApiException('Kode tidak ditemukan'));
    if (b.cancelled) throw ApiException('Tiket ${b.code} sudah dibatalkan.');
    if (!b.paid) throw ApiException('Tiket ${b.code} belum dibayar.');
    b.verified = true;
    return _decorate(b);
  }

  @override
  Future<Booking> advance(String bookingId) async {
    await _lag(200);
    final b = _find(bookingId);
    if (b.cancelled) throw ApiException('Pesanan sudah dibatalkan.');
    if (!b.paid) throw ApiException('Pesanan belum dibayar.');
    if (b.status >= 3) return b;
    b.status++;
    b.verified = true;
    if (b.status == 3) b.estFinish = DateTime.now();
    return _decorate(b);
  }

  @override
  Future<AdminSummary> summary() async {
    await _lag(200);
    final valid = _bookings.where((b) => !b.cancelled).toList();
    final done = valid.where((b) => b.status == 3 && b.paid).toList();
    final by = <String, int>{for (final p in packages) p.name: 0};
    for (final b in valid) {
      by[b.pack.name] = (by[b.pack.name] ?? 0) + 1;
    }
    return AdminSummary(
      total: valid.length,
      done: valid.where((b) => b.status == 3).length,
      revenue: done.fold(0, (s, b) => s + b.total),
      byPackage: by,
      rating: _rating(),
    );
  }

  @override
  Future<List<Booking>> allReviews() async {
    await _lag(150);
    return _bookings.where((b) => b.review != null).toList()
      ..sort((a, b) => b.review!.createdAt.compareTo(a.review!.createdAt));
  }
}

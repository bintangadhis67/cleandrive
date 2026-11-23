import 'package:intl/intl.dart';

import '../models/catalog.dart';
import '../models/catalog_remote.dart';
import '../models/loyalty_models.dart';
import '../models/membership_models.dart';
import '../models/models.dart';
import '../models/notification_models.dart';
import 'repository.dart';

class _MockUser {
  String name, email, phone, pass;
  final bool isAdmin;
  final DateTime createdAt;
  _MockUser(this.name, this.email, this.phone, this.pass, {this.isAdmin = false, DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();
  SessionUser get session => SessionUser(name: name, email: email, phone: phone, isAdmin: isAdmin);
}

class _Tpl {
  final String id, code, title;
  final int amount, percent, maxDiscount, minTransaction, validDays, minTier;
  final List<String> terms;
  final bool weekly; // true = diperbarui tiap minggu, false = sekali per akun
  const _Tpl(this.id, this.code, this.title, this.amount, this.percent, this.maxDiscount, this.minTransaction,
      this.validDays, this.terms,
      {this.minTier = 0, this.weekly = false});
}

/// Dompet Coins satu pengguna.
class _Wallet {
  int balance = 0, lifetime = 0, streak = 0;
  DateTime? last;
  final List<CoinEntry> entries = [];
  final Set<String> promos = {};
}

/// Catatan langganan membership satu pengguna (terpisah dari dompet Coins).
class _MemberRec {
  final String id;
  final MembershipTier tier;
  final DateTime start;
  DateTime end;
  final bool cancelled;
  final int period; // nomor periode langganan (berganti saat beli baru / ganti paket, tetap saat perpanjang)
  bool cancelAtEnd = false; // langganan dibatalkan: aktif sampai [end], tidak diperpanjang
  int freeTotal; // total jatah cuci gratis
  int freeUsed = 0;
  final Set<String> freeWeeks = {}; // minggu yang jatahnya sudah dipakai
  _MemberRec(this.id, this.tier, this.start, this.end, {this.cancelled = false, required this.period, this.freeTotal = 0});
}

/// Data tiruan di memori supaya UI bisa dijalankan tanpa backend.
/// Akun demo: admin@cleandrive.com / admin123 dan budi@mail.com / 123456
class MockRepository implements Repository {
  static const _balances = {
    // Saldo simulasi (data contoh). Semua >= Rp 399.000 agar paket Platinum bisa dibeli dengan metode apa pun.
    PayMethod.gopay: 1500000,
    PayMethod.ovo: 2000000,
    PayMethod.dana: 1000000,
    PayMethod.shopeepay: 800000,
    PayMethod.livin: 3000000,
  };

  /// Aturan voucher:
  /// - Klaim dibatasi 1 voucher per hari (Gold 2x, Platinum 3x), semua voucher dihitung bersama.
  /// - VOUCHER-20K dan WELCOME-10K: hanya 1 kali per akun.
  /// - HEMAT10 dan voucher membership: diperbarui tiap minggu (Senin), bisa diklaim lagi minggu depan.
  static const _tpls = [
    _Tpl('v1', 'VOUCHER-20K', 'Voucher Spesial', 20000, 0, 0, 75000, 30,
        ['Berlaku untuk semua paket', 'Tidak dapat digabung dengan promo lain', 'Hanya 1 kali per akun (klaim dan pakai)']),
    _Tpl('v2', 'HEMAT10', 'Hemat 10%', 0, 10, 15000, 50000, 7,
        ['Potongan 10% maksimal Rp 15.000', 'Berlaku untuk semua paket', 'Diperbarui tiap Senin, bisa diklaim lagi minggu depan'],
        weekly: true),
    _Tpl('v3', 'WELCOME-10K', 'Selamat Datang', 10000, 0, 0, 40000, 60,
        ['Khusus pengguna baru', 'Berlaku untuk semua paket', 'Hanya 1 kali per akun (klaim dan pakai)']),
    // Voucher eksklusif membership BERBAYAR (bukan dari Coins), diperbarui tiap minggu. minTier: 1 Bronze, 2 Silver, 3 Gold, 4 Platinum.
    _Tpl('v7', 'BRONZE-5K', 'Reward Bronze', 5000, 0, 0, 30000, 7,
        ['Khusus member Bronze ke atas', 'Berlaku untuk cuci, ganti oli, dan toko', 'Diperbarui tiap Senin selama membership aktif'],
        minTier: 1, weekly: true),
    _Tpl('v4', 'SILVER-10K', 'Reward Silver', 10000, 0, 0, 60000, 7,
        ['Khusus member Silver ke atas', 'Berlaku untuk cuci, ganti oli, dan toko', 'Diperbarui tiap Senin selama membership aktif'],
        minTier: 2, weekly: true),
    _Tpl('v5', 'GOLD-20', 'Reward Gold', 0, 20, 30000, 75000, 7,
        ['Khusus member Gold ke atas', 'Potongan 20% maksimal Rp 30.000', 'Diperbarui tiap Senin selama membership aktif'],
        minTier: 3, weekly: true),
    _Tpl('v6', 'PLATINUM-50K', 'Reward Platinum', 50000, 0, 0, 150000, 7,
        ['Khusus member Platinum', 'Berlaku untuk cuci, ganti oli, dan toko', 'Diperbarui tiap Senin selama membership aktif'],
        minTier: 4, weekly: true),
  ];

  /// Promo Coins sekali klaim: (id, judul, deskripsi, coins)
  static const _promos = [
    ('welcome', 'Bonus Selamat Datang', 'Hadiah Coins untuk member CleanDrive.', 50),
    ('profile', 'Lengkapi Profil', 'Isi nomor HP di Edit Profil, lalu klaim bonusnya.', 25),
    ('first', 'Transaksi Pertama', 'Klaim setelah kamu menyelesaikan satu pembayaran.', 40),
  ];

  final List<_MockUser> _users = [
    _MockUser('Admin CleanDrive', 'admin@cleandrive.com', '', 'admin123', isAdmin: true),
    _MockUser('Budi Santoso', 'budi@mail.com', '081200000002', '123456', createdAt: DateTime.now().subtract(const Duration(days: 12))),
    _MockUser('Bintang', 'bintang@gmail.com', '', 'bin1234', createdAt: DateTime.now()),
  ];
  _MockUser? _me;

  final List<Booking> _bookings = [];
  final Map<String, String> _owner = {}; // bookingId -> email
  final Map<String, String> _claims = {}; // "email|voucherId" -> bookingId pemakai ('' = belum dipakai)
  final Map<String, Payment> _payments = {};
  final Map<String, _Wallet> _wallets = {}; // email -> dompet Coins
  final Map<String, List<AppNotification>> _notifs = {}; // email -> notifikasi
  final Set<String> _reminded = {}; // bookingId yang sudah dikirimi pengingat
  final Map<String, int> _stock = {for (final p in products) p.id: p.stock}; // stok produk toko
  // Waktu kejadian untuk panel admin (Aktivitas Terbaru).
  final Map<String, DateTime> _created = {}; // bookingId -> waktu pesanan dibuat
  final Map<String, DateTime> _verifiedAt = {}; // bookingId -> waktu tiket diverifikasi
  final Map<String, DateTime> _cancelledAt = {}; // bookingId -> waktu pesanan dibatalkan
  int _bookingSeq = 0, _paySeq = 0, _coinSeq = 0, _notifSeq = 0, _memSeq = 0, _garageSeq = 0, _memberPeriod = 0;

  // Voucher: log waktu klaim (untuk kuota harian), kunci klaim yang dipakai tiap pesanan, dan jatah cuci gratis tiap pesanan.
  final Map<String, List<DateTime>> _claimLog = {}; // email -> waktu klaim voucher
  final Map<String, String> _bookingClaimKey = {}; // bookingId -> kunci klaim voucher yang dipakai
  final Map<String, String> _freeRec = {}; // bookingId -> "periode|kunciMinggu" jatah cuci gratis yang dipakai

  // Membership: data dan transaksi terpisah dari Coins.
  final Map<String, _MemberRec> _members = {}; // email -> langganan terakhir
  final Map<String, MembershipOrder> _mOrders = {}; // id pesanan membership
  final Map<String, String> _mOwner = {}; // id pesanan membership -> email
  final Map<String, List<MembershipTransaction>> _mTx = {}; // email -> riwayat transaksi membership

  // Garasi kendaraan per pengguna.
  final Map<String, List<GarageVehicle>> _garage = {};

  MockRepository() {
    _seedHistory();
  }

  Future<void> _lag([int ms = 250]) => Future.delayed(Duration(milliseconds: ms));
  _MockUser get _u => _me ?? (throw ApiException('Silakan masuk dulu.'));
  _Wallet _walletOf(String email) => _wallets.putIfAbsent(email, _Wallet.new);

  // ---------- coins & notifikasi (logika sisi server) ----------
  AppNotification _notify(String email, NotifType type, String title, String body,
      {String? target, bool push = true, DateTime? at}) {
    final n = AppNotification(
      id: 'n${++_notifSeq}',
      type: type,
      title: title,
      body: body,
      createdAt: at ?? DateTime.now(),
      target: target,
      push: push,
    );
    (_notifs[email] ??= <AppNotification>[]).insert(0, n);
    return n;
  }

  /// Menambah Coins (reward gratis). Coins tidak memengaruhi level membership. Mengembalikan jumlah Coins.
  int _earn(String email, CoinKind kind, String title, int base, {String? note, DateTime? at}) {
    final w = _walletOf(email);
    w.balance += base;
    w.lifetime += base;
    w.entries.insert(
      0,
      CoinEntry(
        id: 'c${++_coinSeq}',
        kind: kind,
        title: title,
        note: note ?? '',
        amount: base,
        createdAt: at ?? DateTime.now(),
      ),
    );
    return base;
  }

  void _spend(String email, int coins, String title, String note) {
    final w = _walletOf(email);
    w.balance -= coins;
    w.entries.insert(
      0,
      CoinEntry(id: 'c${++_coinSeq}', kind: CoinKind.redeem, title: title, note: note, amount: -coins, createdAt: DateTime.now()),
    );
  }

  void _seedCoins(String email, CoinKind kind, String title, int coins, DateTime at, {String note = ''}) {
    final w = _walletOf(email);
    w.balance += coins;
    w.lifetime += coins;
    w.entries.add(CoinEntry(id: 'c${++_coinSeq}', kind: kind, title: title, note: note, amount: coins, createdAt: at));
  }

  void _seedHistory() {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final email = _users[1].email;
    _garage[email] = [
      GarageVehicle(id: 'g${++_garageSeq}', type: VehicleType.mobil, brand: 'Toyota', model: 'Avanza', year: 2019, color: 'Putih', plate: 'L 1234 AB'),
      GarageVehicle(id: 'g${++_garageSeq}', type: VehicleType.motor, brand: 'Honda', model: 'Beat', year: 2021, color: 'Hitam', plate: 'W 5678 CD'),
    ];
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

      final band = payBandFor(b.total);
      b.coinsEarned = coinsForPayment(shop: false, paid: b.total);
      _seedCoins(email, CoinKind.transaction, 'Transaksi ${b.code}', b.coinsEarned, b.estFinish, note: 'Tingkat ${band.label}');
      _seedCoins(email, CoinKind.review, 'Ulasan ${b.code}', kReviewCoins + kReviewCommentBonus, b.review!.createdAt);
      _notify(email, NotifType.order, b.pack.headlines[3], '${b.code} • ${b.pack.title} sudah selesai.',
              target: 'order:${b.id}', push: false, at: b.estFinish)
          .read = true;
    }

    // Riwayat check-in lama (streak sudah terputus).
    final w = _walletOf(email);
    for (var i = 0; i < 7; i++) {
      _seedCoins(email, CoinKind.checkin, 'Check-in harian', kCheckInRewards[i],
          day.subtract(Duration(days: 20 - i)).add(const Duration(hours: 8)), note: 'Hari ke-${i + 1}');
    }
    w.streak = 7;
    w.last = day.subtract(const Duration(days: 14)).add(const Duration(hours: 8));

    _notify(email, NotifType.promo, 'Selamat datang di CleanDrive!', 'Kumpulkan Coins gratis dan nikmati berbagai reward.',
            target: 'loyalty', push: false, at: day.subtract(const Duration(days: 12)))
        .read = true;
    _notify(email, NotifType.voucher, 'Voucher spesial menunggumu', 'Klaim VOUCHER-20K sebelum kedaluwarsa.',
        target: 'vouchers', push: false, at: now.subtract(const Duration(hours: 3)));
    _notify(email, NotifType.points, 'Check-in harian dibuka', 'Check-in hari ini dan dapatkan Coins gratis.',
        target: 'loyalty', push: false, at: now.subtract(const Duration(minutes: 30)));
  }

  Booking _make(_MockUser u, VehicleType v, WashPackage p, String plate, DateTime slot, int discount, String? voucher,
      {List<OrderLine> items = const []}) {
    final id = (++_bookingSeq).toString().padLeft(4, '0');
    final ahead = p.isShop ? 0 : _bookings.where((b) => !b.cancelled && !b.pack.isShop && b.slot == slot).length;
    final clean = p.isShop ? 'TOKO' : plate.replaceAll(' ', '').toUpperCase();
    final price = p.priceFor(v) + items.fold<int>(0, (s, l) => s + l.subtotal);
    final b = Booking(
      id: id,
      code: 'CD-$id-$clean',
      plate: p.isShop ? '-' : plate.toUpperCase(),
      owner: u.name,
      vehicle: v,
      pack: p,
      slot: slot,
      estFinish: slot.add(Duration(minutes: p.minutes + ahead * 10)),
      price: price,
      discount: discount,
      voucherCode: voucher,
      items: items,
    );
    _bookings.insert(0, b);
    _owner[id] = u.email;
    _created[id] = slot.isBefore(DateTime.now()) ? slot.subtract(const Duration(hours: 1)) : DateTime.now();
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
    if (!b.active || b.pack.isShop) {
      b.queuePosition = 0;
    } else {
      b.queuePosition = _bookings
              .where((o) =>
                  o.active &&
                  !o.pack.isShop &&
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
    _notify(u.email, NotifType.promo, 'Selamat datang di CleanDrive!',
        'Klaim Bonus Selamat Datang dan mulai check-in harian untuk kumpulkan Coins.',
        target: 'loyalty', push: false);
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
      if (!b.cancelled && !b.pack.isShop && b.slot.year == day.year && b.slot.month == day.month && b.slot.day == day.day) {
        m[b.slot.hour] = (m[b.slot.hour] ?? 0) + 1;
      }
    }
    return m;
  }

  // ---------- aturan klaim voucher ----------
  /// Kunci klaim: voucher sekali-per-akun = email|id, voucher mingguan = email|id|minggu (otomatis baru tiap Senin).
  String _claimKey(String email, _Tpl t, [DateTime? at]) =>
      t.weekly ? '$email|${t.id}|${weekKey(at ?? DateTime.now())}' : '$email|${t.id}';

  int _dailyLimit(String email) {
    final m = _userMembership(email);
    return (m != null && m.isActive) ? m.tier.dailyVoucherLimit : kBaseDailyVoucherLimit;
  }

  VoucherQuota _quota(String email) {
    final now = DateTime.now();
    final used = (_claimLog[email] ?? const <DateTime>[])
        .where((d) => d.year == now.year && d.month == now.month && d.day == now.day)
        .length;
    return VoucherQuota(used: used, limit: _dailyLimit(email));
  }

  String _quotaMessage(VoucherQuota q) =>
      'Batas klaim voucher hari ini sudah tercapai (${q.used}/${q.limit}). '
      '${q.limit == 1 ? 'Coba lagi besok. Member Gold bisa klaim 2x sehari, Platinum 3x sehari.' : 'Coba lagi besok.'}';

  Voucher _voucher(_Tpl t) {
    final email = _u.email;
    final key = _claimKey(email, t);
    final claimed = _claims.containsKey(key);
    final q = _quota(email);
    final now = DateTime.now();
    return Voucher(
      id: t.id,
      code: t.code,
      title: t.title,
      amount: t.amount,
      percent: t.percent,
      maxDiscount: t.maxDiscount,
      minTransaction: t.minTransaction,
      // Voucher mingguan berlaku sampai Minggu; yang belum dipakai hangus dan bisa diklaim lagi mulai Senin.
      validUntil: t.weekly ? endOfWeek(now) : now.add(Duration(days: t.validDays)),
      terms: t.terms,
      minTier: t.minTier,
      locked: _memberRank(email) < t.minTier,
      weekly: t.weekly,
      blockReason: (!claimed && q.reached) ? _quotaMessage(q) : null,
      claimed: claimed,
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
    List<OrderLine> items = const [],
    bool useFreeWash = false,
  }) async {
    await _lag(400);
    final when = pack.isShop ? DateTime.now() : slot;
    if (pack.isShop) {
      if (items.isEmpty) throw ApiException('Keranjang masih kosong.');
    } else {
      if (plate.trim().isEmpty) throw ApiException('Plat nomor wajib diisi.');
      if (slot.isBefore(DateTime.now())) throw ApiException('Jam tersebut sudah lewat. Pilih jam lain.');
      final taken = _bookings.where((b) => !b.cancelled && !b.pack.isShop && b.slot == slot).length;
      if (taken >= 3) throw ApiException('Slot jam ${DateFormat('HH:mm').format(slot)} sudah penuh.');
    }
    if (pack.isOil) {
      if (items.isEmpty) throw ApiException('Pilih oli dari toko CleanDrive. Oli dari luar tidak diperbolehkan.');
      if (items.length > 1) throw ApiException('Pilih satu jenis oli saja.');
      for (final l in items) {
        if (l.product.category != ProductCategory.oli || !l.product.fits(vehicle)) {
          throw ApiException('Oli ${l.product.name} tidak cocok untuk ${vehicle.label}.');
        }
      }
    } else if (!pack.isShop && items.isNotEmpty) {
      throw ApiException('Produk hanya bisa dibeli lewat Toko atau jasa ganti oli.');
    }

    for (final l in items) {
      final left = _stock[l.product.id] ?? 0;
      if (left <= 0) throw ApiException('${l.product.name} sudah habis.');
      if (l.qty > left) throw ApiException('Stok ${l.product.name} tinggal $left.');
    }

    // Cuci gratis membership: validasi di sisi server (paket, kendaraan, kuota, 1x per minggu, masa aktif).
    if (useFreeWash) {
      if (voucherCode != null && voucherCode.isNotEmpty) {
        throw ApiException('Cuci gratis membership tidak bisa digabung dengan voucher.');
      }
      final m = _userMembership(_u.email);
      if (m == null) throw ApiException('Kamu belum punya membership aktif.');
      final block = m.freeWashBlock(pack, vehicle, slot);
      if (block != null) throw ApiException(block);
    }

    final price = pack.priceFor(vehicle) + items.fold<int>(0, (s, l) => s + l.subtotal);
    var discount = 0;
    String? code;
    if (voucherCode != null && voucherCode.isNotEmpty) {
      final t = _tpls.where((e) => e.code == voucherCode).firstOrNull;
      if (t == null) throw ApiException('Voucher tidak ditemukan.');
      final v = _voucher(t);
      if (v.locked) throw ApiException('Voucher ini khusus member ${v.tierLabel}. Beli membership untuk membukanya.');
      if (!v.claimed) throw ApiException('Voucher belum diklaim.');
      if (v.used) throw ApiException('Voucher sudah pernah dipakai.');
      if (v.expired) throw ApiException('Voucher sudah kedaluwarsa.');
      if (!v.eligible(price)) throw ApiException('Minimal transaksi voucher ${rp(v.minTransaction)}.');
      discount = v.discountFor(price);
      code = v.code;
    }
    final b = _make(_u, vehicle, pack, plate, when, discount, code, items: items);
    // Diskon membership aktif untuk jasa layanan (bukan produk toko). Dihitung di sisi server.
    final mem = _userMembership(_u.email);
    if (useFreeWash && mem != null) {
      // Cuci gratis: total Rp 0, otomatis lunas, tanpa Coins. Jatah dikurangi dan dikunci untuk minggu jadwal ini.
      final rec = _members[_u.email]!;
      rec.freeUsed++;
      rec.freeWeeks.add(weekKey(slot));
      _freeRec[b.id] = '${rec.period}|${weekKey(slot)}';
      b.freeWash = true;
      b.memberDiscount = b.price;
      b.memberLabel = 'Cuci Gratis ${rec.tier.label}';
      b.payStatus = 'paid';
      b.trx = 'FREE-${DateFormat('yyMMdd').format(DateTime.now())}-${(++_paySeq).toString().padLeft(3, '0')}';
      b.coinsEarned = 0;
    } else if (!pack.isShop && mem != null && mem.isActive) {
      var md = mem.plan.discountFor(pack.priceFor(vehicle));
      if (md > price - discount) md = price - discount;
      b.memberDiscount = md;
      b.memberLabel = '${mem.plan.name} ${mem.plan.discountPct}%';
    }
    // Benefit kunjungan Gold/Platinum (makanan & minuman gratis, ruang tunggu VIP): hanya untuk cuci, 1 kunjungan per hari.
    if (pack.kind == ServiceKind.wash &&
        mem != null &&
        mem.isActive &&
        !slot.isAfter(mem.endDate!) &&
        mem.plan.visitPerks.isNotEmpty &&
        !_perkUsedOn(_u.email, slot, b.id)) {
      b.perks = mem.plan.visitPerks;
    }
    if (code != null) {
      final t = _tpls.firstWhere((e) => e.code == code);
      final ck = _claimKey(_u.email, t);
      _claims[ck] = b.id;
      _bookingClaimKey[b.id] = ck;
    }
    _notify(
      _u.email,
      NotifType.order,
      pack.isShop ? 'Pembelian dibuat' : (b.freeWash ? 'Cuci gratis dipakai' : 'Pesanan dibuat'),
      pack.isShop
          ? '${b.code} • ${b.itemCount} item. Selesaikan pembayaran untuk menyelesaikan pembelian.'
          : (b.freeWash
              ? '${b.code} • ${pack.title}. Jatah cuci gratis membership terpakai, tidak perlu membayar.'
              : '${b.code} • ${pack.title}. Selesaikan pembayaran agar pesanan diproses.'),
      target: 'order:${b.id}',
      push: false,
    );
    return _decorate(b);
  }

  /// Sudah ada kunjungan lain di hari yang sama yang mendapat benefit makanan/minuman/VIP?
  bool _perkUsedOn(String email, DateTime slot, String exceptId) => _bookings.any((o) =>
      o.id != exceptId &&
      _owner[o.id] == email &&
      !o.cancelled &&
      o.perks.isNotEmpty &&
      o.slot.year == slot.year &&
      o.slot.month == slot.month &&
      o.slot.day == slot.day);

  @override
  Future<Booking> cancelBooking(String id) async {
    await _lag();
    final b = _own(id);
    if (b.cancelled) throw ApiException('Pesanan sudah dibatalkan.');
    if (!b.cancellable) throw ApiException('Pesanan yang sudah diproses tidak bisa dibatalkan.');
    final wasPaid = b.paid && !b.freeWash;
    final email = _owner[b.id]!;
    b.cancelled = true;
    _cancelledAt[b.id] = DateTime.now();
    if (b.freeWash) {
      // Jatah cuci gratis dikembalikan (hanya bila periode langganannya masih sama).
      final ref = _freeRec.remove(b.id);
      final rec = _members[email];
      if (ref != null && rec != null) {
        final parts = ref.split('|');
        if (parts[0] == rec.period.toString()) {
          if (rec.freeUsed > 0) rec.freeUsed--;
          rec.freeWeeks.remove(parts[1]);
        }
      }
      b.payStatus = 'unpaid';
    }
    if (wasPaid) {
      for (final l in b.items) {
        _stock[l.product.id] = (_stock[l.product.id] ?? 0) + l.qty; // stok dikembalikan
      }
      b.payStatus = 'refunded';
      final w = _walletOf(email);
      if (b.coinsUsed > 0) {
        w.balance += b.coinsUsed;
        w.entries.insert(
          0,
          CoinEntry(
              id: 'c${++_coinSeq}',
              kind: CoinKind.refund,
              title: 'Coins dikembalikan',
              note: b.code,
              amount: b.coinsUsed,
              createdAt: DateTime.now()),
        );
      }
      if (b.coinsEarned > 0) {
        final back = b.coinsEarned > w.balance ? w.balance : b.coinsEarned;
        w.balance -= back;
        w.lifetime = w.lifetime > b.coinsEarned ? w.lifetime - b.coinsEarned : 0;
        if (back > 0) {
          w.entries.insert(
            0,
            CoinEntry(
                id: 'c${++_coinSeq}',
                kind: CoinKind.refund,
                title: 'Coins pesanan dibatalkan',
                note: b.code,
                amount: -back,
                createdAt: DateTime.now()),
          );
        }
      }
    }
    final ck = _bookingClaimKey.remove(b.id);
    if (b.voucherCode != null && ck != null) {
      _claims[ck] = ''; // voucher kembali tersedia (selama periodenya masih berjalan)
    }
    _notify(email, NotifType.order, 'Pesanan dibatalkan',
        b.freeWash
            ? '${b.code} dibatalkan. Jatah cuci gratis membership kamu dikembalikan.'
            : (wasPaid ? '${b.code} dibatalkan. Pembayaran dikembalikan dan Coins pesanan ini ditarik.' : '${b.code} dibatalkan.'),
        target: 'order:${b.id}', push: false);
    return _decorate(b);
  }

  @override
  Future<Map<String, int>> stocks() async {
    await _lag(80);
    return Map<String, int>.of(_stock);
  }

  // ---------- voucher ----------
  @override
  Future<List<Voucher>> vouchers() async {
    await _lag(100);
    return _tpls.map(_voucher).toList();
  }

  @override
  Future<VoucherQuota> voucherQuota() async => _quota(_u.email);

  @override
  Future<Voucher> claimVoucher(String id) async {
    await _lag();
    final t = _tpls.where((e) => e.id == id).firstOrNull ?? (throw ApiException('Voucher tidak ditemukan.'));
    final v = _voucher(t);
    if (v.locked) throw ApiException('Voucher ini khusus member ${v.tierLabel}. Beli membership untuk membukanya.');
    final key = _claimKey(_u.email, t);
    if (_claims.containsKey(key)) {
      throw ApiException(t.weekly
          ? 'Voucher ini sudah kamu klaim minggu ini. Bisa diklaim lagi mulai Senin depan.'
          : 'Voucher ini hanya bisa diklaim 1 kali per akun.');
    }
    final q = _quota(_u.email);
    if (q.reached) throw ApiException(_quotaMessage(q));
    _claims[key] = '';
    (_claimLog[_u.email] ??= <DateTime>[]).add(DateTime.now());
    _notify(_u.email, NotifType.voucher, 'Voucher berhasil diklaim', '${t.code} siap dipakai di pembayaran berikutnya.',
        target: 'vouchers', push: false);
    return _voucher(t);
  }

  // ---------- pembayaran (simulasi) ----------
  @override
  Future<Payment> startPayment(String bookingId, PayMethod method, {int coins = 0}) async {
    await _lag(300);
    final b = _own(bookingId);
    if (b.cancelled) throw ApiException('Pesanan sudah dibatalkan.');
    if (b.paid) throw ApiException('Pesanan ini sudah dibayar.');

    // Total dihitung server: harga - voucher - diskon membership - Coins (bila dipakai).
    var discount = 0;
    if (coins > 0) {
      final w = _walletOf(_u.email);
      final max = maxRedeemCoins(total: b.total, balance: w.balance);
      if (coins % kCoinStep != 0) throw ApiException('Coins ditukar dalam kelipatan $kCoinStep.');
      if (coins > max) throw ApiException('Coins melebihi batas penukaran ($max Coins).');
      discount = coins * kCoinValue;
    }
    final amount = b.total - discount;

    final n = ++_paySeq;
    final trx = 'TRX-${DateFormat('yyMMdd').format(DateTime.now())}-${n.toString().padLeft(3, '0')}';
    final p = Payment(
      id: 'p$n',
      trx: trx,
      bookingId: bookingId,
      method: method,
      amount: amount,
      coinsUsed: coins,
      coinDiscount: discount,
      status: 'pending',
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      qrString: method.isQris ? 'CLEANDRIVE-QRIS|$trx|$amount|${b.code}' : null,
      balance: method.isQris ? null : _balances[method],
    );
    _payments[p.id] = p;
    return p;
  }

  Payment _pay(String id) => _payments[id] ?? (throw ApiException('Transaksi tidak ditemukan.'));

  /// Menandai lunas, memotong Coins yang dipakai, lalu memberi Coins transaksi sesuai tingkat pembayaran.
  void _markPaid(Payment p) {
    final b = _find(p.bookingId);
    final email = _owner[b.id]!;
    if (p.coinsUsed > _walletOf(email).balance) {
      throw ApiException('Coins kamu tidak mencukupi lagi. Ulangi pembayaran tanpa Coins.');
    }
    for (final l in b.items) {
      final left = _stock[l.product.id] ?? 0;
      if (l.qty > left) {
        throw ApiException(left <= 0
            ? 'Maaf, ${l.product.name} baru saja habis.'
            : 'Maaf, stok ${l.product.name} tinggal $left.');
      }
    }
    for (final l in b.items) {
      _stock[l.product.id] = (_stock[l.product.id] ?? 0) - l.qty; // stok berkurang saat dibayar
    }
    p.status = 'paid';
    b.payStatus = 'paid';
    if (b.pack.isShop) {
      // Beli langsung: begitu dibayar, pembelian selesai (tanpa antrean/proses).
      b.status = 3;
      b.verified = true;
      b.estFinish = DateTime.now();
    }
    b.payMethod = p.method;
    b.trx = p.trx;
    if (p.coinsUsed > 0) {
      b.coinsUsed = p.coinsUsed;
      b.coinDiscount = p.coinDiscount;
      _spend(email, p.coinsUsed, 'Tukar Coins', b.code);
    }
    // Coins: toko = +5 tiap Rp 10.000 yang dibayar; cuci/oli = sesuai tingkat pembayaran; Rp 0 = tanpa Coins.
    final earn = coinsForPayment(shop: b.pack.isShop, paid: b.total);
    var r = 0;
    if (earn > 0) {
      r = _earn(email, CoinKind.transaction, 'Transaksi ${b.code}', earn,
          note: b.pack.isShop
              ? 'Belanja ${rp(b.total)} (+$kShopCoinReward tiap ${rp(kShopCoinStepRp)})'
              : 'Tingkat ${payBandFor(b.total).label} • ${rp(b.total)}');
    }
    b.coinsEarned = r;
    p.coinsEarned = r;
    _notify(email, NotifType.payment, b.pack.isShop ? 'Pembelian berhasil' : 'Pembayaran berhasil',
        '${b.code} • ${rp(b.total)} via ${p.method.label}.${r > 0 ? ' Kamu dapat +$r Coins.' : ''}',
        target: 'order:${b.id}', push: false);
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
    final email = _owner[b.id]!;
    final hasText = comment.trim().isNotEmpty;
    final r = _earn(email, CoinKind.review, 'Ulasan ${b.code}', kReviewCoins + (hasText ? kReviewCommentBonus : 0),
        note: hasText ? 'Ulasan dengan komentar' : 'Rating');
    _notify(email, NotifType.points, 'Terima kasih atas ulasanmu', 'Kamu dapat +$r Coins.',
        target: 'loyalty', push: false);
    return b;
  }

  RatingSummary _rating() {
    final rs = _bookings.where((b) => b.review != null).map((b) => b.review!.rating).toList();
    if (rs.isEmpty) return const RatingSummary(0, 0);
    return RatingSummary(rs.reduce((a, b) => a + b) / rs.length, rs.length);
  }

  @override
  Future<RatingSummary> ratingSummary() async => _rating();

  // ---------- coins & membership ----------
  String? _promoLock(String id) {
    switch (id) {
      case 'profile':
        return _u.phone.trim().isEmpty ? 'Isi No. HP di Edit Profil dulu' : null;
      case 'first':
        final any = _bookings.any((b) => _owner[b.id] == _u.email && b.paid && b.total > 0);
        return any ? null : 'Selesaikan satu pembayaran dulu';
      default:
        return null;
    }
  }

  /// Promo bulan ini: berganti otomatis tiap bulan, bisa diklaim 1 kali per bulan per akun.
  CoinPromo _monthlyPromo(_Wallet w) {
    final now = DateTime.now();
    final t = kMonthlyPromos[now.month - 1];
    final id = monthlyPromoId(now);
    return CoinPromo(
      id: id,
      title: t.$1,
      desc: t.$2,
      coins: t.$3,
      claimed: w.promos.contains(id),
      monthly: true,
      endsAt: DateTime(now.year, now.month + 1, 0),
    );
  }

  @override
  Future<LoyaltyInfo> loyalty() async {
    await _lag(100);
    final w = _walletOf(_u.email);
    final entries = List<CoinEntry>.of(w.entries)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return LoyaltyInfo(
      balance: w.balance,
      lifetime: w.lifetime,
      streak: w.streak,
      lastCheckIn: w.last,
      entries: entries,
      promos: [
        _monthlyPromo(w),
        for (final p in _promos)
          CoinPromo(
            id: p.$1,
            title: p.$2,
            desc: p.$3,
            coins: p.$4,
            claimed: w.promos.contains(p.$1),
            lockedReason: w.promos.contains(p.$1) ? null : _promoLock(p.$1),
          ),
      ],
    );
  }

  @override
  Future<CoinAward> checkIn() async {
    await _lag(300);
    final w = _walletOf(_u.email);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = w.last;
    if (last != null && DateTime(last.year, last.month, last.day) == today) {
      throw ApiException('Kamu sudah check-in hari ini. Kembali lagi besok!');
    }
    final yesterday = today.subtract(const Duration(days: 1));
    final alive = last != null && DateTime(last.year, last.month, last.day) == yesterday;
    w.streak = alive ? w.streak + 1 : 1;
    w.last = now;
    final dayNo = (w.streak - 1) % kCheckInRewards.length;
    final r = _earn(_u.email, CoinKind.checkin, 'Check-in harian', kCheckInRewards[dayNo],
        note: 'Hari ke-${dayNo + 1}');
    _notify(_u.email, NotifType.points, 'Check-in berhasil',
        '+$r Coins. Streak ${w.streak} hari, jangan putus ya!',
        target: 'loyalty', push: false);
    return CoinAward(r, w.streak, 'Check-in hari ke-${dayNo + 1}');
  }

  @override
  Future<CoinAward> claimPromo(String id) async {
    await _lag(300);
    final w = _walletOf(_u.email);
    final now = DateTime.now();
    final tpl = id == monthlyPromoId(now)
        ? (id, kMonthlyPromos[now.month - 1].$1, '', kMonthlyPromos[now.month - 1].$3)
        : (_promos.where((p) => p.$1 == id).firstOrNull ?? (throw ApiException('Promo tidak ditemukan atau sudah berakhir.')));
    if (w.promos.contains(id)) throw ApiException('Promo ini sudah kamu klaim.');
    final lock = _promoLock(id);
    if (lock != null) throw ApiException(lock);
    w.promos.add(id);
    final r = _earn(_u.email, CoinKind.promo, tpl.$2, tpl.$4);
    _notify(_u.email, NotifType.points, 'Promo Coins diklaim', '+$r Coins dari ${tpl.$2}.',
        target: 'loyalty', push: false);
    return CoinAward(r, w.streak, tpl.$2);
  }

  // ---------- membership (produk berbayar, terpisah dari Coins) ----------
  UserMembership? _userMembership(String email) {
    final r = _members[email];
    if (r == null) return null;
    final ended = DateTime.now().isAfter(r.end);
    final status = r.cancelled
        ? MembershipStatus.cancelled
        : (ended ? (r.cancelAtEnd ? MembershipStatus.cancelled : MembershipStatus.expired) : MembershipStatus.active);
    return UserMembership(
      id: r.id,
      tier: r.tier,
      status: status,
      startDate: r.start,
      endDate: r.end,
      cancelAtEnd: r.cancelAtEnd,
      freeTotal: r.freeTotal,
      freeUsed: r.freeUsed,
      freeWeeks: Set<String>.of(r.freeWeeks),
    );
  }

  /// 0 = tanpa membership aktif, 1 = Bronze, ... 4 = Platinum.
  int _memberRank(String email) {
    final m = _userMembership(email);
    return (m != null && m.isActive) ? m.tier.rank : 0;
  }

  MembershipOrder? _pendingOrder(String email) {
    for (final o in _mOrders.values) {
      if (_mOwner[o.id] == email && o.status == 'pending' && !o.expired) return o;
    }
    return null;
  }

  MembershipOrder _mOrder(String id) {
    final o = _mOrders[id] ?? (throw ApiException('Pesanan membership tidak ditemukan.'));
    if (_mOwner[id] != _u.email) throw ApiException('Bukan pesananmu.');
    if (o.status == 'pending' && DateTime.now().isAfter(o.expiresAt)) o.status = 'expired';
    return o;
  }

  @override
  Future<MembershipInfo> membership() async {
    await _lag(100);
    final email = _u.email;
    final hist = List<MembershipTransaction>.of(_mTx[email] ?? const <MembershipTransaction>[])
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return MembershipInfo(current: _userMembership(email), pending: _pendingOrder(email), history: hist);
  }

  @override
  Future<MembershipOrder> startMembershipPurchase(MembershipTier tier, PayMethod method) async {
    await _lag(300);
    final email = _u.email;
    final plan = planOf(tier);
    final cur = _userMembership(email);
    final renewal = cur != null && cur.isActive && cur.tier == tier;
    // Satu pesanan menunggu pembayaran per pengguna: yang lama dibatalkan.
    for (final o in _mOrders.values) {
      if (_mOwner[o.id] == email && o.status == 'pending') o.status = 'cancelled';
    }
    final n = ++_memSeq;
    final trx = 'MBR-${DateFormat('yyMMdd').format(DateTime.now())}-${n.toString().padLeft(3, '0')}';
    final o = MembershipOrder(
      id: 'm$n',
      trx: trx,
      tier: tier,
      amount: plan.price, // harga dari paket (server), tidak bisa diubah dari layar
      method: method,
      status: 'pending',
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      renewal: renewal,
      qrString: method.isQris ? 'CLEANDRIVE-QRIS|$trx|${plan.price}|MEMBERSHIP-${tier.name.toUpperCase()}' : null,
      balance: method.isQris ? null : _balances[method],
    );
    _mOrders[o.id] = o;
    _mOwner[o.id] = email;
    return o;
  }

  @override
  Future<MembershipOrder> membershipOrder(String id) async => _mOrder(id);

  /// Mengaktifkan atau memperpanjang membership setelah pembayaran berhasil (sisi server).
  void _activateMembership(MembershipOrder o) {
    if (o.status == 'paid') return;
    final email = _mOwner[o.id]!;
    final now = DateTime.now();
    final cur = _userMembership(email);
    final plan = o.plan;
    final old = _members[email];
    if (old != null && cur != null && cur.isActive && cur.tier == o.tier) {
      // Perpanjang: masa aktif ditambah 1 bulan dari tanggal berakhir saat ini, jatah cuci gratis bertambah,
      // dan status batal langganan dicabut. Jatah tetap maksimal 1x per minggu.
      old.end = old.end.add(Duration(days: plan.durationDays));
      old.freeTotal += plan.freeWashQuota;
      old.cancelAtEnd = false;
    } else {
      // Beli baru / ganti paket / beli setelah kedaluwarsa: periode baru dengan jatah cuci gratis baru.
      _members[email] = _MemberRec('um$email', o.tier, now, now.add(Duration(days: plan.durationDays)),
          period: ++_memberPeriod, freeTotal: plan.freeWashQuota);
    }
    final end = _members[email]!.end;
    o.status = 'paid';
    (_mTx[email] ??= <MembershipTransaction>[]).add(MembershipTransaction(
      id: o.id,
      trx: o.trx,
      tier: o.tier,
      amount: o.amount,
      method: o.method,
      renewal: o.renewal,
      createdAt: now,
    ));
    _notify(email, NotifType.membership, o.renewal ? 'Membership diperpanjang' : 'Membership ${plan.name} aktif',
        'Berlaku hingga ${DateFormat('d MMM yyyy', 'id_ID').format(end)}.',
        target: 'membership', push: false);
  }

  @override
  Future<MembershipOrder> confirmMembershipPayment(String id) async {
    await _lag(500);
    final o = _mOrder(id);
    if (o.method.isQris) throw ApiException('Pembayaran QRIS dilakukan dengan scan QR.');
    if (o.paid) return o;
    if (o.status == 'cancelled') throw ApiException('Pesanan membership sudah dibatalkan.');
    if (o.expired) throw ApiException('Waktu pembayaran sudah habis.');
    if ((o.balance ?? 0) < o.amount) throw ApiException('Saldo ${o.method.label} tidak cukup.');
    _activateMembership(o);
    return o;
  }

  @override
  Future<MembershipOrder> simulateMembershipQris(String id) async {
    await _lag(400);
    final o = _mOrder(id);
    if (o.paid) return o;
    if (o.status == 'cancelled') throw ApiException('Pesanan membership sudah dibatalkan.');
    if (o.expired) throw ApiException('QR sudah kedaluwarsa. Buat QR baru.');
    _activateMembership(o);
    return o;
  }

  @override
  Future<void> cancelMembershipOrder(String id) async {
    await _lag(200);
    final o = _mOrder(id);
    if (o.paid) throw ApiException('Pesanan sudah dibayar dan tidak bisa dibatalkan.');
    o.status = 'cancelled';
    final email = _u.email;
    if (_members[email] == null) {
      final now = DateTime.now();
      _members[email] = _MemberRec('um$email', o.tier, now, now, cancelled: true, period: ++_memberPeriod);
    }
  }

  /// Batalkan langganan: membership langsung dihapus dan seluruh pembayaran periode ini dikembalikan.
  /// Mengembalikan nominal refund (Rp).
  @override
  Future<int> cancelMembership() async {
    await _lag(250);
    final email = _u.email;
    final r = _members[email];
    final m = _userMembership(email);
    if (r == null || m == null || !m.isActive) throw ApiException('Tidak ada membership aktif untuk dibatalkan.');

    // Total pembayaran periode langganan ini (pembelian + perpanjangan) dikembalikan ke metode bayar terakhir.
    final txs = _mTx.putIfAbsent(email, () => <MembershipTransaction>[]);
    final paid = txs.where((t) => !t.refund && !t.createdAt.isBefore(r.start)).toList();
    final refund = paid.fold<int>(0, (s, t) => s + t.amount);
    final method = paid.isNotEmpty ? paid.last.method : PayMethod.qris;

    // Pesanan cuci gratis yang belum diproses ikut dibatalkan, karena benefitnya sudah hilang.
    for (final b in _bookings) {
      if (_owner[b.id] == email && b.freeWash && !b.cancelled && b.status == 0) {
        b.cancelled = true;
        b.payStatus = 'unpaid';
        _cancelledAt[b.id] = DateTime.now();
        _freeRec.remove(b.id);
      }
    }

    // Status membership langsung hilang.
    _members.remove(email);

    final now = DateTime.now();
    txs.add(MembershipTransaction(
      id: 'rf${++_memSeq}',
      trx: 'RFD-${DateFormat('yyMMdd').format(now)}-${_memSeq.toString().padLeft(3, '0')}',
      tier: r.tier,
      amount: refund,
      method: method,
      renewal: false,
      createdAt: now,
      refund: true,
    ));
    _notify(email, NotifType.membership, 'Langganan dibatalkan',
        'Membership ${r.tier.label} dihentikan. Dana Rp ${NumberFormat.decimalPattern('id_ID').format(refund)} dikembalikan ke ${method.label}.',
        target: 'membership', push: false);
    return refund;
  }

  // ---------- garasi kendaraan ----------
  @override
  Future<List<GarageVehicle>> garage() async {
    await _lag(100);
    return List<GarageVehicle>.of(_garage[_u.email] ?? const <GarageVehicle>[]);
  }

  @override
  Future<GarageVehicle> saveVehicle(GarageVehicle v) async {
    await _lag(250);
    final list = _garage.putIfAbsent(_u.email, () => <GarageVehicle>[]);
    final plate = v.plate.trim().toUpperCase();
    if (plate.isEmpty) throw ApiException('Nomor polisi wajib diisi.');
    if (v.brand.trim().isEmpty || v.model.trim().isEmpty) throw ApiException('Merek dan model wajib diisi.');
    if (v.year < 1980 || v.year > DateTime.now().year + 1) throw ApiException('Tahun kendaraan tidak valid.');
    if (list.any((e) => e.plate.replaceAll(' ', '') == plate.replaceAll(' ', '') && e.id != v.id)) {
      throw ApiException('Nomor polisi $plate sudah ada di garasimu.');
    }
    final saved = GarageVehicle(
      id: v.id.isEmpty ? 'g${++_garageSeq}' : v.id,
      type: v.type,
      brand: v.brand.trim(),
      model: v.model.trim(),
      year: v.year,
      color: v.color.trim(),
      plate: plate,
    );
    final i = list.indexWhere((e) => e.id == saved.id);
    if (i >= 0) {
      list[i] = saved;
    } else {
      list.add(saved);
    }
    return saved;
  }

  @override
  Future<void> deleteVehicle(String id) async {
    await _lag(200);
    _garage[_u.email]?.removeWhere((e) => e.id == id);
  }

  // ---------- notifikasi ----------
  /// Pengingat otomatis: pesanan berbayar yang jadwalnya kurang dari 1 jam lagi.
  void _genReminders() {
    final me = _me;
    if (me == null || me.isAdmin) return;
    final now = DateTime.now();
    for (final b in _bookings) {
      if (_owner[b.id] != me.email || !b.active || !b.paid || b.pack.isShop || _reminded.contains(b.id)) continue;
      final mins = b.slot.difference(now).inMinutes;
      if (mins >= 0 && mins <= 60) {
        _reminded.add(b.id);
        _notify(me.email, NotifType.reminder, 'Jadwalmu sebentar lagi',
            '${b.pack.title} • ${b.plate} pukul ${DateFormat('HH:mm').format(b.slot)}. Tunjukkan tiket QR ke petugas saat tiba.',
            target: 'order:${b.id}');
      }
    }
  }

  @override
  Future<List<AppNotification>> notifications() async {
    await _lag(80);
    _genReminders();
    final list = List<AppNotification>.of(_notifs[_u.email] ?? <AppNotification>[]);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> markNotificationRead(String id) async {
    for (final n in _notifs[_u.email] ?? <AppNotification>[]) {
      if (n.id == id) n.read = true;
    }
  }

  @override
  Future<void> markAllNotificationsRead() async {
    for (final n in _notifs[_u.email] ?? <AppNotification>[]) {
      n.read = true;
    }
  }

  @override
  Future<void> deleteNotification(String id) async {
    _notifs[_u.email]?.removeWhere((n) => n.id == id);
  }

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
    _verifiedAt[b.id] = DateTime.now();
    final owner = _owner[b.id];
    if (owner != null) {
      _notify(owner, NotifType.order, 'Tiket terverifikasi', '${b.code} sudah diverifikasi petugas.',
          target: 'order:${b.id}');
    }
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
    final owner = _owner[b.id];
    if (owner != null) {
      _notify(owner, NotifType.order, b.pack.headlines[b.status],
          '${b.code} • ${b.pack.title}: ${b.pack.statusNames[b.status]}.',
          target: 'order:${b.id}');
    }
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
  Future<ServerCatalog> catalog() async => ServerCatalog(products: products);

  @override
  Future<Product> saveProduct(Product p, {PickedImage? image}) async =>
      throw ApiException('Mode demo (tanpa server) tidak menyimpan perubahan katalog.');

  @override
  Future<void> savePackage(String name, {required String desc, required int minutes, required int priceMotor, required int priceMobil}) async =>
      throw ApiException('Mode demo (tanpa server) tidak menyimpan perubahan katalog.');

  @override
  Future<String> deleteProduct(String id) async =>
      throw ApiException('Mode demo (tanpa server) tidak menyimpan perubahan katalog.');

  @override
  Future<AdminOverview> adminOverview() async {
    await _lag(150);
    if (!_u.isAdmin) throw ApiException('Khusus admin.');
    final now = DateTime.now();
    bool today(DateTime d) => d.year == now.year && d.month == now.month && d.day == now.day;
    final customers = <AdminCustomer>[];
    final nameOf = <String, String>{};
    final coinRows = <AdminCoinRow>[];
    final acts = <AdminActivity>[];
    var circulating = 0, checkinsToday = 0, redeemCount = 0, redeemed = 0;

    for (final u in _users.where((e) => !e.isAdmin)) {
      nameOf[u.email] = u.name;
      final mine = _bookings.where((b) => _owner[b.id] == u.email && !b.cancelled).toList();
      final w = _wallets[u.email];
      customers.add(AdminCustomer(
        name: u.name,
        email: u.email,
        phone: u.phone,
        joinedAt: u.createdAt,
        orders: mine.length,
        spent: mine.where((b) => b.paid).fold(0, (s, b) => s + b.total),
        coins: w?.balance ?? 0,
        membership: _userMembership(u.email),
      ));
      acts.add(AdminActivity(AdminActivityKind.customer, 'Pelanggan baru terdaftar', u.name, u.createdAt));
      if (w == null) continue;
      circulating += w.balance;
      if (w.last != null && today(w.last!)) checkinsToday++;
      for (final e in w.entries) {
        coinRows.add(AdminCoinRow(u.name, e));
        if (e.kind == CoinKind.redeem) {
          redeemCount++;
          redeemed += -e.amount;
        }
        if (e.kind == CoinKind.checkin) {
          acts.add(AdminActivity(AdminActivityKind.checkin, 'Check-in harian', '+${e.amount} Coins oleh ${u.name}', e.createdAt));
        }
      }
    }
    coinRows.sort((a, b) => b.entry.createdAt.compareTo(a.entry.createdAt));

    for (final b in _bookings) {
      final at = _created[b.id] ?? b.slot;
      acts.add(AdminActivity(AdminActivityKind.order, 'Pesanan #${b.code}', '${b.pack.title} oleh ${b.owner}', at));
      if (b.status >= 3 && !b.cancelled) {
        acts.add(AdminActivity(AdminActivityKind.done, 'Pesanan #${b.code}', 'Telah selesai dan dibayar', b.estFinish));
      }
      final v = _verifiedAt[b.id];
      if (v != null) acts.add(AdminActivity(AdminActivityKind.verified, 'Tiket #${b.code}', 'Berhasil diverifikasi', v));
      final c = _cancelledAt[b.id];
      if (c != null) acts.add(AdminActivity(AdminActivityKind.cancelled, 'Pesanan #${b.code}', 'Dibatalkan oleh pelanggan', c));
    }
    acts.sort((a, b) => b.at.compareTo(a.at));

    final memberTx = <AdminMemberTx>[
      for (final e in _mTx.entries)
        for (final t in e.value) AdminMemberTx(nameOf[e.key] ?? e.key, t),
    ]..sort((a, b) => b.tx.createdAt.compareTo(a.tx.createdAt));

    return AdminOverview(
      customers: customers,
      coins: AdminCoinStats(circulating: circulating, checkinsToday: checkinsToday, redeemCount: redeemCount, redeemedCoins: redeemed),
      coinRows: coinRows,
      memberTx: memberTx,
      activities: acts.take(40).toList(),
    );
  }

  @override
  Future<List<Booking>> allReviews() async {
    await _lag(150);
    return _bookings.where((b) => b.review != null).toList()
      ..sort((a, b) => b.review!.createdAt.compareTo(a.review!.createdAt));
  }
}
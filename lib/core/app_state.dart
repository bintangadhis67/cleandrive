import 'package:flutter/foundation.dart';

import '../data/repository.dart';
import '../models/catalog.dart' show setLiveProducts;
import '../models/loyalty_models.dart';
import '../models/membership_models.dart';
import '../models/models.dart';
import '../models/notification_models.dart';

/// State aplikasi. Semua akses data lewat [repo] (data tiruan atau API Laravel).
class AppState extends ChangeNotifier {
  static const maxPerSlot = 3;

  late Repository repo;
  SessionUser? me;
  bool booting = true;

  List<Booking> bookings = [];
  List<Voucher> vouchers = [];
  VoucherQuota quota = const VoucherQuota();
  RatingSummary rating = const RatingSummary(0, 0);

  // Coins (reward gratis) dan Membership (produk berbayar) adalah dua sistem yang terpisah.
  LoyaltyInfo loyalty = const LoyaltyInfo();
  MembershipInfo membership = const MembershipInfo();

  // Garasi kendaraan
  List<GarageVehicle> garage = [];

  // Notifikasi
  List<AppNotification> notifications = [];
  final Set<String> _seenNotifs = {};
  bool _notifReady = false;

  /// Notifikasi baru yang perlu ditampilkan sebagai banner (dibaca dan dikosongkan oleh HomeScreen).
  AppNotification? banner;

  // Keranjang Toko
  List<OrderLine> cart = [];

  /// Stok produk toko (id produk -> sisa). Diisi dari repository.
  Map<String, int> stock = {};

  /// Dipakai layar lain untuk meminta HomeScreen pindah tab.
  int? requestedTab;
  WashPackage? requestedPack;
  VehicleType? requestedVehicle;
  Product? requestedOil; // oli dari toko yang dibawa ke booking jasa ganti oli

  /// Voucher yang dipilih dari layar klaim ("Gunakan Sekarang").
  Voucher? pendingVoucher;

  String? get user => me?.name;
  String get email => me?.email ?? '';
  String get phone => me?.phone ?? '';
  bool get isAdmin => me?.isAdmin ?? false;

  int get unreadCount => notifications.where((n) => !n.read).length;

  Future<void> init(Repository r) async {
    repo = r;
    try {
      me = await repo.restore();
      if (me != null) await refreshAll();
    } catch (_) {
      me = null;
    }
    booting = false;
    notifyListeners();
  }

  DateTime? _catalogAt;

  /// Memuat katalog produk dari server (disimpan sekitar 1 menit di memori). Bila gagal, katalog yang ada tetap dipakai.
  Future<void> loadCatalog({bool force = false}) async {
    final at = _catalogAt;
    if (!force && at != null && DateTime.now().difference(at) < const Duration(minutes: 1)) return;
    try {
      final c = await repo.catalog();
      setLiveProducts(c.products);
      _catalogAt = DateTime.now();
    } catch (_) {}
  }

  Future<void> refreshAll() async {
    await loadCatalog();
    final r = await Future.wait([repo.bookings(), repo.ratingSummary(), repo.stocks()]);
    bookings = r[0] as List<Booking>;
    rating = r[1] as RatingSummary;
    stock = r[2] as Map<String, int>;
    _clampCart();
    if (!isAdmin) {
      // Semua data pelanggan diminta sekaligus (bukan satu per satu) supaya layar awal cepat terbuka.
      final m = await Future.wait<Object?>([
        repo.vouchers(),
        repo.voucherQuota(),
        repo.loyalty(),
        repo.membership(),
        repo.garage(),
        _fetchNotifications(),
      ]);
      vouchers = m[0] as List<Voucher>;
      quota = m[1] as VoucherQuota;
      loyalty = m[2] as LoyaltyInfo;
      membership = m[3] as MembershipInfo;
      garage = m[4] as List<GarageVehicle>;
    }
    notifyListeners();
  }

  /// Memuat ulang Coins, membership, dan notifikasi (dipanggil setelah pembayaran, check-in, dan seterusnya).
  Future<void> refreshMeta() async {
    if (isAdmin || me == null) return;
    try {
      loyalty = await repo.loyalty();
      membership = await repo.membership();
      // Tampilkan Coins & Membership terbaru SEGERA (jangan menunggu notifikasi selesai dimuat).
      notifyListeners();
      await _fetchNotifications();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> refreshNotifications() async {
    if (isAdmin || me == null) return;
    try {
      await _fetchNotifications();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _fetchNotifications() async {
    final list = await repo.notifications();
    if (_notifReady) {
      final fresh = list.where((n) => !n.read && n.push && !_seenNotifs.contains(n.id)).toList();
      if (fresh.isNotEmpty) banner = fresh.first;
    }
    _seenNotifs.addAll(list.map((n) => n.id));
    _notifReady = true;
    notifications = list;
  }

  Future<void> _afterLogin() async {
    try {
      await refreshAll();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> login(String email, String pass) async {
    me = await repo.login(email, pass);
    await _afterLogin();
  }

  Future<void> register(String name, String email, String phone, String pass) async {
    me = await repo.register(name, email, phone, pass);
    await _afterLogin();
  }

  Future<void> logout() async {
    try {
      await repo.logout();
    } catch (_) {}
    me = null;
    bookings = [];
    vouchers = [];
    quota = const VoucherQuota();
    loyalty = const LoyaltyInfo();
    membership = const MembershipInfo();
    garage = [];
    notifications = [];
    _seenNotifs.clear();
    _notifReady = false;
    banner = null;
    cart = [];
    pendingVoucher = null;
    requestedTab = null;
    requestedPack = null;
    requestedVehicle = null;
    requestedOil = null;
    notifyListeners();
  }

  Future<void> updateProfile(String name, String phone) async {
    me = await repo.updateProfile(name, phone);
    await refreshAll();
  }

  Future<void> changePassword(String oldPass, String newPass) => repo.changePassword(oldPass, newPass);

  void requestTab(int i, {WashPackage? pack, VehicleType? vehicle, Product? oil}) {
    requestedTab = i;
    requestedPack = pack;
    requestedVehicle = vehicle;
    requestedOil = oil;
    notifyListeners();
  }

  // ---------- pesanan ----------
  List<Booking> get queue => List.of(bookings)..sort((a, b) => a.slot.compareTo(b.slot));

  Booking? byId(String id) => bookings.where((b) => b.id == id).firstOrNull;

  Future<Map<int, int>> slotCounts(DateTime day) => repo.slotCounts(day);

  Future<Booking> create({
    required VehicleType vehicle,
    required WashPackage pack,
    required String plate,
    required DateTime slot,
    String? voucherCode,
    List<OrderLine> items = const [],
    bool useFreeWash = false,
  }) async {
    final b = await repo.createBooking(
        vehicle: vehicle,
        pack: pack,
        plate: plate,
        slot: slot,
        voucherCode: voucherCode,
        items: items,
        useFreeWash: useFreeWash);
    pendingVoucher = null;
    if (pack.isShop) cart = [];
    await refreshAll();
    return byId(b.id) ?? b;
  }

  Future<void> refreshBooking(String id) async {
    try {
      final fresh = await repo.booking(id);
      final i = bookings.indexWhere((b) => b.id == id);
      if (i >= 0) {
        bookings[i] = fresh;
      } else {
        bookings.insert(0, fresh);
      }
      if (!isAdmin) await _fetchNotifications();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> cancel(String id) async {
    await repo.cancelBooking(id);
    await refreshAll();
  }

  // ---------- keranjang toko ----------
  int get cartCount => cart.fold(0, (s, l) => s + l.qty);
  int get cartTotal => cart.fold(0, (s, l) => s + l.subtotal);

  int qtyOf(Product p) => cart.where((l) => l.product.id == p.id).firstOrNull?.qty ?? 0;

  /// Sisa stok produk (bila belum dimuat, pakai stok awal dari katalog).
  int stockOf(Product p) => stock[p.id] ?? p.stock;

  /// Memuat ulang stok (dipanggil saat membuka Toko).
  Future<void> refreshStock() async {
    try {
      stock = await repo.stocks();
      _clampCart();
      notifyListeners();
    } catch (_) {}
  }

  /// Jumlah di keranjang tidak boleh melebihi stok.
  void _clampCart() {
    cart = [
      for (final l in cart)
        if (stockOf(l.product) > 0) OrderLine(l.product, l.qty > stockOf(l.product) ? stockOf(l.product) : l.qty),
    ];
  }

  void setQty(Product p, int q) {
    final max = stockOf(p);
    if (q > max) q = max;
    final i = cart.indexWhere((l) => l.product.id == p.id);
    if (q <= 0) {
      if (i >= 0) cart.removeAt(i);
    } else if (i >= 0) {
      cart[i] = OrderLine(p, q);
    } else {
      cart.add(OrderLine(p, q));
    }
    notifyListeners();
  }

  void clearCart() {
    cart = [];
    notifyListeners();
  }

  // ---------- voucher ----------
  Future<void> claim(Voucher v) async {
    await repo.claimVoucher(v.id);
    await refreshVouchers();
    await refreshMeta();
  }

  /// Memuat ulang voucher dan kuota klaim hari ini (voucher mingguan otomatis muncul lagi tiap Senin).
  Future<void> refreshVouchers() async {
    if (isAdmin || me == null) return;
    try {
      vouchers = await repo.vouchers();
      quota = await repo.voucherQuota();
    } catch (_) {}
    notifyListeners();
  }

  Voucher? get claimable => vouchers.where((v) => v.claimable).firstOrNull;
  List<Voucher> get usableVouchers => vouchers.where((v) => v.usable).toList();

  // ---------- pembayaran ----------
  Future<Payment> startPayment(String bookingId, PayMethod m, {int coins = 0}) =>
      repo.startPayment(bookingId, m, coins: coins);
  Future<Payment> payment(String id) => repo.payment(id);

  Future<Payment> confirmPayment(String id) async {
    final p = await repo.confirmPayment(id);
    await refreshBooking(p.bookingId);
    await refreshMeta();
    return p;
  }

  Future<Payment> simulateQrisPaid(String id) async {
    final p = await repo.simulateQrisPaid(id);
    await refreshBooking(p.bookingId);
    await refreshMeta();
    return p;
  }

  // ---------- ulasan ----------
  /// Mengembalikan jumlah Coins yang didapat dari ulasan ini.
  Future<int> review(String bookingId, int rating, String comment) async {
    final before = loyalty.lifetime;
    await repo.submitReview(bookingId, rating, comment);
    await refreshAll();
    return loyalty.lifetime - before;
  }

  // ---------- coins ----------
  Future<CoinAward> checkIn() async {
    final r = await repo.checkIn();
    await refreshMeta();
    return r;
  }

  Future<CoinAward> claimPromo(String id) async {
    final r = await repo.claimPromo(id);
    await refreshMeta();
    return r;
  }

  // ---------- membership (produk berbayar) ----------
  /// Diskon membership untuk harga jasa layanan. Hanya perkiraan di layar; server menghitung ulang.
  int memberDiscountFor(int servicePrice) => membership.discountFor(servicePrice);

  Future<MembershipOrder> startMembershipPurchase(MembershipTier t, PayMethod m) async {
    final o = await repo.startMembershipPurchase(t, m);
    await refreshMeta();
    return o;
  }

  Future<MembershipOrder> membershipOrder(String id) => repo.membershipOrder(id);

  Future<MembershipOrder> confirmMembershipPayment(String id) async {
    final o = await repo.confirmMembershipPayment(id);
    await refreshAll();
    return o;
  }

  Future<MembershipOrder> simulateMembershipQris(String id) async {
    final o = await repo.simulateMembershipQris(id);
    await refreshAll();
    return o;
  }

  Future<void> cancelMembershipOrder(String id) async {
    await repo.cancelMembershipOrder(id);
    await refreshMeta();
  }

  /// Batalkan langganan: membership langsung hilang dan uangnya dikembalikan. Mengembalikan nominal refund.
  Future<int> cancelMembership() async {
    final refund = await repo.cancelMembership();
    await refreshMeta();
    return refund;
  }

  // ---------- garasi kendaraan ----------
  Future<void> saveVehicle(GarageVehicle v) async {
    await repo.saveVehicle(v);
    garage = await repo.garage();
    notifyListeners();
  }

  Future<void> deleteVehicle(String id) async {
    await repo.deleteVehicle(id);
    garage = await repo.garage();
    notifyListeners();
  }

  // ---------- notifikasi ----------
  Future<void> markRead(AppNotification n) async {
    if (n.read) return;
    n.read = true;
    notifyListeners();
    try {
      await repo.markNotificationRead(n.id);
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    for (final n in notifications) {
      n.read = true;
    }
    notifyListeners();
    try {
      await repo.markAllNotificationsRead();
    } catch (_) {}
  }

  Future<void> deleteNotification(AppNotification n) async {
    notifications.remove(n);
    notifyListeners();
    try {
      await repo.deleteNotification(n.id);
    } catch (_) {}
  }

  // ---------- admin ----------
  Future<Booking> verify(String code) async {
    final b = await repo.verify(code);
    await refreshAll();
    return b;
  }

  Future<void> advance(Booking b) async {
    await repo.advance(b.id);
    await refreshAll();
  }

  Future<AdminSummary> summary() => repo.summary();
  Future<List<Booking>> allReviews() => repo.allReviews();
}

final app = AppState();
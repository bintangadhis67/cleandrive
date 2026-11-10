import 'package:flutter/foundation.dart';

import 'data/repository.dart';
import 'loyalty_models.dart';
import 'models.dart';
import 'notification_models.dart';

/// State aplikasi. Semua akses data lewat [repo] (data tiruan atau API Laravel).
class AppState extends ChangeNotifier {
  static const maxPerSlot = 3;

  late Repository repo;
  SessionUser? me;
  bool booting = true;

  List<Booking> bookings = [];
  List<Voucher> vouchers = [];
  RatingSummary rating = const RatingSummary(0, 0);

  // Coins & membership
  LoyaltyInfo loyalty = const LoyaltyInfo();

  // Notifikasi
  List<AppNotification> notifications = [];
  final Set<String> _seenNotifs = {};
  bool _notifReady = false;

  /// Notifikasi baru yang perlu ditampilkan sebagai banner (dibaca dan dikosongkan oleh HomeScreen).
  AppNotification? banner;

  // Keranjang Toko
  List<OrderLine> cart = [];

  /// Dipakai layar lain untuk meminta HomeScreen pindah tab.
  int? requestedTab;
  WashPackage? requestedPack;
  VehicleType? requestedVehicle;

  /// Voucher yang dipilih dari layar klaim ("Gunakan Sekarang").
  Voucher? pendingVoucher;

  String? get user => me?.name;
  String get email => me?.email ?? '';
  String get phone => me?.phone ?? '';
  bool get isAdmin => me?.isAdmin ?? false;

  Tier get tier => loyalty.tier;
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

  Future<void> refreshAll() async {
    final r = await Future.wait([repo.bookings(), repo.ratingSummary()]);
    bookings = r[0] as List<Booking>;
    rating = r[1] as RatingSummary;
    if (!isAdmin) {
      vouchers = await repo.vouchers();
      loyalty = await repo.loyalty();
      await _fetchNotifications();
    }
    notifyListeners();
  }

  /// Memuat ulang Coins dan notifikasi (dipanggil setelah pembayaran, check-in, dan seterusnya).
  Future<void> refreshMeta() async {
    if (isAdmin || me == null) return;
    try {
      loyalty = await repo.loyalty();
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
    loyalty = const LoyaltyInfo();
    notifications = [];
    _seenNotifs.clear();
    _notifReady = false;
    banner = null;
    cart = [];
    pendingVoucher = null;
    requestedTab = null;
    requestedPack = null;
    requestedVehicle = null;
    notifyListeners();
  }

  Future<void> updateProfile(String name, String phone) async {
    me = await repo.updateProfile(name, phone);
    await refreshAll();
  }

  Future<void> changePassword(String oldPass, String newPass) => repo.changePassword(oldPass, newPass);

  void requestTab(int i, {WashPackage? pack, VehicleType? vehicle}) {
    requestedTab = i;
    requestedPack = pack;
    requestedVehicle = vehicle;
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
  }) async {
    final b = await repo.createBooking(
        vehicle: vehicle, pack: pack, plate: plate, slot: slot, voucherCode: voucherCode, items: items);
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

  void setQty(Product p, int q) {
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
    vouchers = await repo.vouchers();
    await refreshMeta();
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

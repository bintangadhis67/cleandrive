import 'package:flutter/foundation.dart';

import 'data/repository.dart';
import 'models.dart';

/// State aplikasi. Semua akses data lewat [repo] (data tiruan atau API Laravel).
class AppState extends ChangeNotifier {
  static const maxPerSlot = 3;

  late Repository repo;
  SessionUser? me;
  bool booting = true;

  List<Booking> bookings = [];
  List<Voucher> vouchers = [];
  RatingSummary rating = const RatingSummary(0, 0);

  /// Dipakai layar lain untuk meminta HomeScreen pindah tab.
  int? requestedTab;

  /// Voucher yang dipilih dari layar klaim ("Gunakan Sekarang").
  Voucher? pendingVoucher;

  String? get user => me?.name;
  String get email => me?.email ?? '';
  String get phone => me?.phone ?? '';
  bool get isAdmin => me?.isAdmin ?? false;

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
    if (!isAdmin) vouchers = await repo.vouchers();
    notifyListeners();
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
    pendingVoucher = null;
    requestedTab = null;
    notifyListeners();
  }

  Future<void> updateProfile(String name, String phone) async {
    me = await repo.updateProfile(name, phone);
    await refreshAll();
  }

  Future<void> changePassword(String oldPass, String newPass) => repo.changePassword(oldPass, newPass);

  void requestTab(int i) {
    requestedTab = i;
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
  }) async {
    final b = await repo.createBooking(vehicle: vehicle, pack: pack, plate: plate, slot: slot, voucherCode: voucherCode);
    pendingVoucher = null;
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
      notifyListeners();
    } catch (_) {}
  }

  Future<void> cancel(String id) async {
    await repo.cancelBooking(id);
    await refreshAll();
  }

  // ---------- voucher ----------
  Future<void> claim(Voucher v) async {
    await repo.claimVoucher(v.id);
    vouchers = await repo.vouchers();
    notifyListeners();
  }

  Voucher? get claimable => vouchers.where((v) => !v.claimed && !v.expired).firstOrNull;
  List<Voucher> get usableVouchers => vouchers.where((v) => v.usable).toList();

  // ---------- pembayaran ----------
  Future<Payment> startPayment(String bookingId, PayMethod m) => repo.startPayment(bookingId, m);
  Future<Payment> payment(String id) => repo.payment(id);

  Future<Payment> confirmPayment(String id) async {
    final p = await repo.confirmPayment(id);
    await refreshBooking(p.bookingId);
    return p;
  }

  Future<Payment> simulateQrisPaid(String id) async {
    final p = await repo.simulateQrisPaid(id);
    await refreshBooking(p.bookingId);
    return p;
  }

  // ---------- ulasan ----------
  Future<void> review(String bookingId, int rating, String comment) async {
    await repo.submitReview(bookingId, rating, comment);
    await refreshAll();
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

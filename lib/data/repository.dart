import '../loyalty_models.dart';
import '../models.dart';
import '../notification_models.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class SessionUser {
  final String name, email, phone;
  final bool isAdmin;
  const SessionUser({required this.name, required this.email, required this.phone, required this.isAdmin});

  factory SessionUser.fromJson(Map<String, dynamic> j) => SessionUser(
        name: j['name'] as String,
        email: j['email'] as String,
        phone: (j['phone'] ?? '') as String,
        isAdmin: j['role'] == 'admin',
      );
}

class RatingSummary {
  final double avg;
  final int count;
  const RatingSummary(this.avg, this.count);

  factory RatingSummary.fromJson(Map<String, dynamic> j) =>
      RatingSummary((j['avg'] as num).toDouble(), (j['count'] as num).toInt());
}

class AdminSummary {
  final int total, done, revenue;
  final Map<String, int> byPackage;
  final RatingSummary rating;
  const AdminSummary({
    required this.total,
    required this.done,
    required this.revenue,
    required this.byPackage,
    required this.rating,
  });

  factory AdminSummary.fromJson(Map<String, dynamic> j) {
    final bp = j['by_package'];
    return AdminSummary(
      total: (j['total'] as num).toInt(),
      done: (j['done'] as num).toInt(),
      revenue: (j['revenue'] as num).toInt(),
      byPackage: bp is Map ? {for (final e in bp.entries) e.key as String: (e.value as num).toInt()} : {},
      rating: RatingSummary.fromJson(j['rating'] as Map<String, dynamic>),
    );
  }
}

/// Kontrak sumber data. Saat ini hanya ada MockRepository (data tiruan di memori, tanpa backend).
/// Integrasi ke backend nanti dilakukan dengan membuat implementasi baru dari kelas ini,
/// tanpa mengubah layar-layar aplikasi.
abstract class Repository {
  Future<SessionUser?> restore();
  Future<SessionUser> login(String email, String password);
  Future<SessionUser> register(String name, String email, String phone, String password);
  Future<void> logout();
  Future<SessionUser> updateProfile(String name, String phone);
  Future<void> changePassword(String oldPass, String newPass);

  Future<List<Booking>> bookings(); // konsumen: milik sendiri, admin: semua
  Future<Booking> booking(String id);
  Future<Map<int, int>> slotCounts(DateTime day); // jam -> jumlah booking
  Future<Booking> createBooking({
    required VehicleType vehicle,
    required WashPackage pack,
    required String plate,
    required DateTime slot,
    String? voucherCode,
    List<OrderLine> items = const [],
  });
  Future<Booking> cancelBooking(String id);

  Future<List<Voucher>> vouchers();
  Future<Voucher> claimVoucher(String id);

  /// [coins] = jumlah Coins yang ditukar jadi potongan (kelipatan 10). Coins baru dipotong saat pembayaran berhasil.
  Future<Payment> startPayment(String bookingId, PayMethod method, {int coins = 0});
  Future<Payment> payment(String id);
  Future<Payment> confirmPayment(String id); // e-wallet
  Future<Payment> simulateQrisPaid(String id); // hanya mode sandbox

  Future<Booking> submitReview(String bookingId, int rating, String comment);
  Future<RatingSummary> ratingSummary();

  // coins & membership
  Future<LoyaltyInfo> loyalty();
  Future<CoinAward> checkIn();
  Future<CoinAward> claimPromo(String id);

  // notifikasi
  Future<List<AppNotification>> notifications();
  Future<void> markNotificationRead(String id);
  Future<void> markAllNotificationsRead();
  Future<void> deleteNotification(String id);

  // admin
  Future<Booking> verify(String code);
  Future<Booking> advance(String bookingId);
  Future<AdminSummary> summary();
  Future<List<Booking>> allReviews();
}

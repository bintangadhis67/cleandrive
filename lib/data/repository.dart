import '../models/catalog_remote.dart';
import '../models/loyalty_models.dart';
import '../models/membership_models.dart';
import '../models/models.dart';
import '../models/notification_models.dart';

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

// ---------------------------------------------------------------------------
// DATA KHUSUS PANEL ADMIN (ringkasan lintas pelanggan)
// ---------------------------------------------------------------------------
enum AdminActivityKind { order, done, verified, checkin, customer, cancelled }

/// Satu kejadian di panel "Aktivitas Terbaru".
class AdminActivity {
  final AdminActivityKind kind;
  final String title, subtitle;
  final DateTime at;
  const AdminActivity(this.kind, this.title, this.subtitle, this.at);
}

/// Pelanggan beserta ringkasan transaksi, Coins, dan membership.
class AdminCustomer {
  final String name, email, phone;
  final DateTime joinedAt;
  final int orders; // jumlah pesanan (tidak dibatalkan)
  final int spent; // total pembayaran lunas
  final int coins; // saldo CleanDrive Coins
  final UserMembership? membership;
  const AdminCustomer({
    required this.name,
    required this.email,
    required this.phone,
    required this.joinedAt,
    required this.orders,
    required this.spent,
    required this.coins,
    this.membership,
  });

  bool get hasActiveMembership => membership?.isActive ?? false;
  MembershipTier? get activeTier => hasActiveMembership ? membership!.tier : null;
}

/// Satu baris riwayat Coins milik seorang pelanggan.
class AdminCoinRow {
  final String customer;
  final CoinEntry entry;
  const AdminCoinRow(this.customer, this.entry);
}

class AdminCoinStats {
  final int circulating; // total saldo Coins semua pelanggan
  final int checkinsToday; // pelanggan yang check-in hari ini
  final int redeemCount; // jumlah penukaran Coins
  final int redeemedCoins; // total Coins yang dipakai
  const AdminCoinStats({
    this.circulating = 0,
    this.checkinsToday = 0,
    this.redeemCount = 0,
    this.redeemedCoins = 0,
  });
}

/// Satu baris riwayat pembelian membership milik seorang pelanggan.
class AdminMemberTx {
  final String customer;
  final MembershipTransaction tx;
  const AdminMemberTx(this.customer, this.tx);
}

class AdminOverview {
  final List<AdminCustomer> customers;
  final AdminCoinStats coins;
  final List<AdminCoinRow> coinRows;
  final List<AdminMemberTx> memberTx;
  final List<AdminActivity> activities;
  const AdminOverview({
    this.customers = const [],
    this.coins = const AdminCoinStats(),
    this.coinRows = const [],
    this.memberTx = const [],
    this.activities = const [],
  });
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
    bool useFreeWash = false, // pakai jatah cuci gratis membership (total Rp 0, tidak bisa digabung voucher/Coins)
  });
  Future<Booking> cancelBooking(String id);

  /// Stok tiap produk toko: id produk -> jumlah tersisa.
  Future<Map<String, int>> stocks();

  Future<List<Voucher>> vouchers();
  Future<Voucher> claimVoucher(String id);

  /// Kuota klaim voucher hari ini (1x per hari, Gold 2x, Platinum 3x).
  Future<VoucherQuota> voucherQuota();

  /// [coins] = Coins yang ditukar jadi potongan (kelipatan 10, maks 30% total). Server memvalidasi dan
  /// menghitung total sendiri. Coins baru dipotong saat pembayaran berhasil.
  Future<Payment> startPayment(String bookingId, PayMethod method, {int coins = 0});
  Future<Payment> payment(String id);
  Future<Payment> confirmPayment(String id); // e-wallet
  Future<Payment> simulateQrisPaid(String id); // hanya mode sandbox

  Future<Booking> submitReview(String bookingId, int rating, String comment);
  Future<RatingSummary> ratingSummary();

  // coins (reward gratis)
  Future<LoyaltyInfo> loyalty();
  Future<CoinAward> checkIn();
  Future<CoinAward> claimPromo(String id);

  // membership (produk berbayar, siklus pembayaran sendiri, terpisah dari Coins)
  Future<MembershipInfo> membership();
  Future<MembershipOrder> startMembershipPurchase(MembershipTier tier, PayMethod method);
  Future<MembershipOrder> membershipOrder(String id);
  Future<MembershipOrder> confirmMembershipPayment(String id); // e-wallet
  Future<MembershipOrder> simulateMembershipQris(String id); // hanya mode sandbox
  Future<void> cancelMembershipOrder(String id);

  /// Batalkan langganan membership aktif: membership langsung hilang dan uang dikembalikan penuh.
  /// Mengembalikan nominal refund (Rp).
  Future<int> cancelMembership();

  // garasi kendaraan
  Future<List<GarageVehicle>> garage();
  Future<GarageVehicle> saveVehicle(GarageVehicle v); // id kosong = tambah baru
  Future<void> deleteVehicle(String id);

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

  /// Ringkasan lintas pelanggan untuk panel admin: pelanggan, Coins, membership, dan aktivitas terbaru.
  Future<AdminOverview> adminOverview();

  // katalog (server)

  /// Katalog produk terbaru dari server. Termasuk produk yang sudah dinonaktifkan, supaya pesanan lama tetap terbaca.
  Future<ServerCatalog> catalog();

  /// Admin: tambah produk (id kosong) atau ubah produk. [image] = foto baru; kosong = foto lama dipertahankan.
  Future<Product> saveProduct(Product p, {PickedImage? image});

  /// Admin: hapus produk. Yang sudah pernah dipesan hanya dinonaktifkan. Hasil: pesan untuk ditampilkan.
  Future<String> deleteProduct(String id);

  /// Admin: ubah deskripsi, durasi, dan harga satu paket layanan (cuci atau ganti oli) yang sudah ada.
  Future<void> savePackage(String name, {required String desc, required int minutes, required int priceMotor, required int priceMobil});
}
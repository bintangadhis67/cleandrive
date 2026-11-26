import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/catalog_remote.dart';
import '../models/loyalty_models.dart';
import '../models/membership_models.dart';
import '../models/models.dart';
import '../models/notification_models.dart';
import 'repository.dart';

/// Repository yang memanggil backend Laravel (folder backend/).
///
/// Alamat server:
///  - Chrome / desktop : http://127.0.0.1:8000/api (127.0.0.1 lebih cepat daripada localhost di Windows)
///  - Emulator Android : http://10.0.2.2:8000/api
///  - HP fisik         : jalankan dengan --dart-define=API_BASE_URL=http://IP-LAPTOP:8000/api
class ApiRepository implements Repository {
  ApiRepository({String? baseUrl, http.Client? client})
      : _base = baseUrl ?? _defaultBaseUrl(),
        _client = client ?? http.Client();

  final String _base;
  final http.Client _client;
  static const _tokenKey = 'cleandrive_token';
  static const _timeout = Duration(seconds: 20);

  String? _token;
  bool _tokenLoaded = false;

  static String _defaultBaseUrl() {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8000/api';
    return 'http://127.0.0.1:8000/api';
  }

  // ------------------------------------------------------------------ jaringan

  Future<void> _loadToken() async {
    if (_tokenLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _tokenLoaded = true;
  }

  Future<void> _setToken(String? token) async {
    _token = token;
    _tokenLoaded = true;
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, token);
    }
  }

  /// Memanggil API. Error dari server ({"message": "..."}) dilempar sebagai [ApiException].
  Future<dynamic> _call(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    bool auth = true,
  }) async {
    await _loadToken();
    final uri = Uri.parse('$_base$path').replace(queryParameters: query);
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (auth && _token != null) 'Authorization': 'Bearer $_token',
    };
    final payload = body == null ? '{}' : jsonEncode(body);

    final http.Response res;
    try {
      final Future<http.Response> req;
      switch (method) {
        case 'GET':
          req = _client.get(uri, headers: headers);
        case 'POST':
          req = _client.post(uri, headers: headers, body: payload);
        case 'PUT':
          req = _client.put(uri, headers: headers, body: payload);
        case 'DELETE':
          req = _client.delete(uri, headers: headers);
        default:
          throw ArgumentError('Metode HTTP tidak dikenal: $method');
      }
      res = await req.timeout(_timeout);
    } on TimeoutException {
      throw ApiException('Server tidak merespons. Coba lagi sebentar lagi.');
    } on http.ClientException {
      throw ApiException('Tidak dapat terhubung ke server ($_base). Pastikan backend sedang berjalan.');
    }

    return _finish(res, auth: auth);
  }

  /// Membaca jawaban server: 2xx = isi JSON, selain itu dilempar sebagai [ApiException].
  Future<dynamic> _finish(http.Response res, {required bool auth}) async {
    dynamic data;
    if (res.bodyBytes.isNotEmpty) {
      try {
        data = jsonDecode(utf8.decode(res.bodyBytes));
      } on FormatException {
        data = null;
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return data;

    if (res.statusCode == 401 && auth) {
      await _setToken(null); // token tidak berlaku lagi
      throw ApiException('Sesi berakhir. Silakan masuk lagi.');
    }
    final msg = (data is Map && data['message'] is String) ? data['message'] as String : 'Terjadi kesalahan (${res.statusCode}).';
    throw ApiException(msg);
  }

  /// Mengirim form dengan file (multipart), dipakai untuk unggah foto produk.
  Future<dynamic> _multipart(String path, Map<String, String> fields, PickedImage? image) async {
    await _loadToken();
    final req = http.MultipartRequest('POST', Uri.parse('$_base$path'))
      ..headers['Accept'] = 'application/json'
      ..fields.addAll(fields);
    if (_token != null) req.headers['Authorization'] = 'Bearer $_token';
    if (image != null) {
      req.files.add(http.MultipartFile.fromBytes('image', image.bytes, filename: image.name));
    }

    final http.Response res;
    try {
      final streamed = await _client.send(req).timeout(_timeout);
      res = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException('Server tidak merespons. Coba lagi sebentar lagi.');
    } on http.ClientException {
      throw ApiException('Tidak dapat terhubung ke server ($_base). Pastikan backend sedang berjalan.');
    }
    return _finish(res, auth: true);
  }

  // ------------------------------------------------------------------ pembantu parsing

  static int _int(dynamic v) => (v as num).toInt();
  static DateTime _date(dynamic v) => DateTime.parse(v as String);
  static DateTime? _dateOrNull(dynamic v) => v == null ? null : DateTime.parse(v as String);
  static Map<String, dynamic> _obj(dynamic v) => v as Map<String, dynamic>;
  static List<Map<String, dynamic>> _maps(dynamic v) => [for (final e in (v as List? ?? const [])) e as Map<String, dynamic>];

  static String _dateParam(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static MembershipTier _tier(dynamic v) =>
      MembershipTier.values.firstWhere((t) => t.name == v, orElse: () => MembershipTier.bronze);

  static UserMembership _userMembership(Map<String, dynamic> j) => UserMembership(
        id: j['id'].toString(),
        tier: _tier(j['tier']),
        status: MembershipStatus.values.firstWhere((s) => s.name == j['status'], orElse: () => MembershipStatus.none),
        startDate: _dateOrNull(j['start_date']),
        endDate: _dateOrNull(j['end_date']),
        cancelAtEnd: (j['cancel_at_end'] ?? false) as bool,
        freeTotal: _int(j['free_total'] ?? 0),
        freeUsed: _int(j['free_used'] ?? 0),
        freeWeeks: {for (final w in (j['free_weeks'] as List? ?? const [])) w.toString()},
      );

  static MembershipTransaction _memberTx(Map<String, dynamic> j) => MembershipTransaction(
        id: j['id'].toString(),
        trx: j['trx'] as String,
        tier: _tier(j['tier']),
        amount: _int(j['amount']),
        method: payMethodFrom(j['method'] as String),
        renewal: (j['renewal'] ?? false) as bool,
        createdAt: _date(j['created_at']),
        refund: (j['refund'] ?? false) as bool,
      );

  static MembershipOrder _memberOrder(Map<String, dynamic> j) => MembershipOrder(
        id: j['id'].toString(),
        trx: j['trx'] as String,
        tier: _tier(j['tier']),
        amount: _int(j['amount']),
        method: payMethodFrom(j['method'] as String),
        status: j['status'] as String,
        expiresAt: _date(j['expires_at']),
        renewal: (j['renewal'] ?? false) as bool,
        qrString: j['qr_string'] as String?,
        balance: j['balance'] == null ? null : _int(j['balance']),
        sandbox: (j['sandbox'] ?? true) as bool,
      );

  static CoinAward _award(dynamic v) {
    final j = _obj(v);
    return CoinAward(_int(j['coins']), _int(j['streak'] ?? 0), j['title'] as String);
  }

  // ------------------------------------------------------------------ akun

  @override
  Future<SessionUser?> restore() async {
    await _loadToken();
    if (_token == null) return null;
    try {
      return SessionUser.fromJson(_obj(await _call('GET', '/me')));
    } on ApiException {
      return null; // sesi tidak valid atau server tidak terjangkau: tampilkan layar masuk
    }
  }

  @override
  Future<SessionUser> login(String email, String password) async {
    final j = _obj(await _call('POST', '/auth/login', auth: false, body: {'email': email, 'password': password}));
    await _setToken(j['token'] as String);
    return SessionUser.fromJson(_obj(j['user']));
  }

  @override
  Future<SessionUser> register(String name, String email, String phone, String password) async {
    final j = _obj(await _call('POST', '/auth/register',
        auth: false, body: {'name': name, 'email': email, 'phone': phone, 'password': password}));
    await _setToken(j['token'] as String);
    return SessionUser.fromJson(_obj(j['user']));
  }

  @override
  Future<void> logout() async {
    try {
      await _call('POST', '/auth/logout');
    } on ApiException {
      // tetap keluar di perangkat ini walau server tidak terjangkau
    }
    await _setToken(null);
  }

  @override
  Future<SessionUser> updateProfile(String name, String phone) async =>
      SessionUser.fromJson(_obj(await _call('PUT', '/me', body: {'name': name, 'phone': phone})));

  @override
  Future<void> changePassword(String oldPass, String newPass) async {
    await _call('PUT', '/me/password', body: {'old_password': oldPass, 'new_password': newPass});
  }

  // ------------------------------------------------------------------ pesanan

  @override
  Future<List<Booking>> bookings() async => _maps(await _call('GET', '/bookings')).map(Booking.fromJson).toList();

  @override
  Future<Booking> booking(String id) async => Booking.fromJson(_obj(await _call('GET', '/bookings/$id')));

  @override
  Future<Map<int, int>> slotCounts(DateTime day) async {
    final data = await _call('GET', '/bookings/slots', query: {'date': _dateParam(day)});
    if (data is! Map) return {};
    return {for (final e in data.entries) int.parse(e.key.toString()): (e.value as num).toInt()};
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
    final j = await _call('POST', '/bookings', body: {
      'vehicle': vehicle.name,
      'package': pack.name,
      'plate': plate,
      'slot': slot.toIso8601String(), // waktu lokal tanpa zona waktu, dibaca server sebagai WIB
      'voucher_code': voucherCode,
      'items': [
        for (final l in items) {'product_id': l.product.id, 'qty': l.qty},
      ],
      'use_free_wash': useFreeWash,
    });
    return Booking.fromJson(_obj(j));
  }

  @override
  Future<Booking> cancelBooking(String id) async => Booking.fromJson(_obj(await _call('POST', '/bookings/$id/cancel')));

  @override
  Future<Map<String, int>> stocks() async {
    final data = _obj(await _call('GET', '/stocks'));
    return {for (final e in data.entries) e.key: (e.value as num).toInt()};
  }

  // ------------------------------------------------------------------ voucher

  @override
  Future<List<Voucher>> vouchers() async => _maps(await _call('GET', '/vouchers')).map(Voucher.fromJson).toList();

  @override
  Future<Voucher> claimVoucher(String id) async => Voucher.fromJson(_obj(await _call('POST', '/vouchers/$id/claim')));

  @override
  Future<VoucherQuota> voucherQuota() async => VoucherQuota.fromJson(_obj(await _call('GET', '/vouchers/quota')));

  // ------------------------------------------------------------------ pembayaran

  @override
  Future<Payment> startPayment(String bookingId, PayMethod method, {int coins = 0}) async => Payment.fromJson(
      _obj(await _call('POST', '/payments', body: {'booking_id': bookingId, 'method': method.name, 'coins': coins})));

  @override
  Future<Payment> payment(String id) async => Payment.fromJson(_obj(await _call('GET', '/payments/$id')));

  @override
  Future<Payment> confirmPayment(String id) async => Payment.fromJson(_obj(await _call('POST', '/payments/$id/confirm')));

  @override
  Future<Payment> simulateQrisPaid(String id) async =>
      Payment.fromJson(_obj(await _call('POST', '/payments/$id/simulate-qris')));

  // ------------------------------------------------------------------ ulasan

  @override
  Future<Booking> submitReview(String bookingId, int rating, String comment) async => Booking.fromJson(
      _obj(await _call('POST', '/bookings/$bookingId/review', body: {'rating': rating, 'comment': comment})));

  @override
  Future<RatingSummary> ratingSummary() async => RatingSummary.fromJson(_obj(await _call('GET', '/ratings/summary')));

  // ------------------------------------------------------------------ Coins

  @override
  Future<LoyaltyInfo> loyalty() async {
    final j = _obj(await _call('GET', '/loyalty'));
    return LoyaltyInfo(
      balance: _int(j['balance']),
      lifetime: _int(j['lifetime']),
      streak: _int(j['streak'] ?? 0),
      lastCheckIn: _dateOrNull(j['last_check_in']),
      entries: _maps(j['entries']).map(CoinEntry.fromJson).toList(),
      promos: [
        for (final p in _maps(j['promos']))
          CoinPromo(
            id: p['id'].toString(),
            title: p['title'] as String,
            desc: (p['desc'] ?? '') as String,
            coins: _int(p['coins']),
            claimed: (p['claimed'] ?? false) as bool,
            monthly: (p['monthly'] ?? false) as bool,
            endsAt: _dateOrNull(p['ends_at']),
            lockedReason: p['locked_reason'] as String?,
          ),
      ],
    );
  }

  @override
  Future<CoinAward> checkIn() async => _award(await _call('POST', '/loyalty/check-in'));

  @override
  Future<CoinAward> claimPromo(String id) async => _award(await _call('POST', '/loyalty/promos/$id/claim'));

  // ------------------------------------------------------------------ membership

  @override
  Future<MembershipInfo> membership() async {
    final j = _obj(await _call('GET', '/membership'));
    return MembershipInfo(
      current: j['current'] == null ? null : _userMembership(_obj(j['current'])),
      pending: j['pending'] == null ? null : _memberOrder(_obj(j['pending'])),
      history: _maps(j['history']).map(_memberTx).toList(),
    );
  }

  @override
  Future<MembershipOrder> startMembershipPurchase(MembershipTier tier, PayMethod method) async =>
      _memberOrder(_obj(await _call('POST', '/membership/purchase', body: {'tier': tier.name, 'method': method.name})));

  @override
  Future<MembershipOrder> membershipOrder(String id) async => _memberOrder(_obj(await _call('GET', '/membership/orders/$id')));

  @override
  Future<MembershipOrder> confirmMembershipPayment(String id) async =>
      _memberOrder(_obj(await _call('POST', '/membership/orders/$id/confirm')));

  @override
  Future<MembershipOrder> simulateMembershipQris(String id) async =>
      _memberOrder(_obj(await _call('POST', '/membership/orders/$id/simulate-qris')));

  @override
  Future<void> cancelMembershipOrder(String id) async {
    await _call('DELETE', '/membership/orders/$id');
  }

  @override
  Future<int> cancelMembership() async => _int(_obj(await _call('POST', '/membership/cancel'))['refund']);

  // ------------------------------------------------------------------ garasi

  @override
  Future<List<GarageVehicle>> garage() async => _maps(await _call('GET', '/garage')).map(GarageVehicle.fromJson).toList();

  @override
  Future<GarageVehicle> saveVehicle(GarageVehicle v) async {
    final body = {
      'type': v.type.name,
      'brand': v.brand,
      'model': v.model,
      'year': v.year,
      'color': v.color,
      'plate': v.plate,
    };
    final j = v.id.isEmpty ? await _call('POST', '/garage', body: body) : await _call('PUT', '/garage/${v.id}', body: body);
    return GarageVehicle.fromJson(_obj(j));
  }

  @override
  Future<void> deleteVehicle(String id) async {
    await _call('DELETE', '/garage/$id');
  }

  // ------------------------------------------------------------------ notifikasi

  @override
  Future<List<AppNotification>> notifications() async =>
      _maps(await _call('GET', '/notifications')).map(AppNotification.fromJson).toList();

  @override
  Future<void> markNotificationRead(String id) async {
    await _call('POST', '/notifications/$id/read');
  }

  @override
  Future<void> markAllNotificationsRead() async {
    await _call('POST', '/notifications/read-all');
  }

  @override
  Future<void> deleteNotification(String id) async {
    await _call('DELETE', '/notifications/$id');
  }

  // ------------------------------------------------------------------ admin

  @override
  Future<Booking> verify(String code) async => Booking.fromJson(_obj(await _call('POST', '/admin/verify', body: {'code': code})));

  @override
  Future<Booking> advance(String bookingId) async =>
      Booking.fromJson(_obj(await _call('POST', '/admin/bookings/$bookingId/advance')));

  @override
  Future<AdminSummary> summary() async => AdminSummary.fromJson(_obj(await _call('GET', '/admin/summary')));

  @override
  Future<List<Booking>> allReviews() async => _maps(await _call('GET', '/admin/reviews')).map(Booking.fromJson).toList();

  // ------------------------------------------------------------------ katalog

  static Product _product(Map<String, dynamic> j) => Product(
        j['id'].toString(),
        j['name'] as String,
        (j['description'] ?? '') as String,
        _int(j['price']),
        ProductCategory.values.firstWhere((c) => c.name == j['category'], orElse: () => ProductCategory.makanan),
        (j['image'] ?? '') as String, // URL foto di server, atau jalur asset bawaan aplikasi
        vehicles: {
          for (final v in (j['vehicles'] as List? ?? const []))
            VehicleType.values.firstWhere((t) => t.name == v, orElse: () => VehicleType.mobil),
        },
        stock: _int(j['stock'] ?? 0),
        detailsText: j['details'] as String?,
        active: (j['active'] ?? true) as bool,
      );

  @override
  Future<ServerCatalog> catalog() async {
    final j = _obj(await _call('GET', '/catalog'));
    return ServerCatalog(
      rewards: j['rewards'] is Map ? RewardConfig.fromJson(_obj(j['rewards'])) : null,
      plans: [for (final p in _maps(j['plans'])) MembershipPlan.fromJson(p)],
      products: _maps(j['products']).map(_product).toList(),
      packages: [
        for (final p in _maps(j['packages']))
          LivePackage(
            name: p['name'] as String,
            desc: (p['desc'] ?? '') as String,
            basePrice: _int(_obj(p['prices'])['motor']),
            minutes: _int(p['minutes']),
            prices: {
              VehicleType.motor: _int(_obj(p['prices'])['motor']),
              VehicleType.mobil: _int(_obj(p['prices'])['mobil']),
            },
          ),
      ],
    );
  }

  @override
  Future<Product> saveProduct(Product p, {PickedImage? image}) async {
    final fields = <String, String>{
      'name': p.name,
      'description': p.desc,
      'details': p.detailsText ?? '',
      'price': '${p.price}',
      'category': p.category.name,
      'stock': '${p.stock}',
      'vehicles': p.vehicles.map((v) => v.name).join(','),
    };
    final j = await _multipart(p.id.isEmpty ? '/admin/products' : '/admin/products/${p.id}', fields, image);
    return _product(_obj(j));
  }

  @override
  Future<String> deleteProduct(String id) async {
    final j = _obj(await _call('DELETE', '/admin/products/$id'));
    return (j['message'] ?? 'Produk dihapus.') as String;
  }

  @override
  Future<void> savePackage(
    String name, {
    required String desc,
    required int minutes,
    required int priceMotor,
    required int priceMobil,
  }) async {
    await _call('PUT', '/admin/packages/${Uri.encodeComponent(name)}', body: {
      'desc': desc,
      'minutes': minutes,
      'price_motor': priceMotor,
      'price_mobil': priceMobil,
    });
  }

  @override
  Future<AdminOverview> adminOverview() async {
    final j = _obj(await _call('GET', '/admin/overview'));
    final c = _obj(j['coins']);
    return AdminOverview(
      customers: [
        for (final e in _maps(j['customers']))
          AdminCustomer(
            name: e['name'] as String,
            email: e['email'] as String,
            phone: (e['phone'] ?? '') as String,
            joinedAt: _date(e['joined_at']),
            orders: _int(e['orders']),
            spent: _int(e['spent']),
            coins: _int(e['coins']),
            membership: e['membership'] == null ? null : _userMembership(_obj(e['membership'])),
          ),
      ],
      coins: AdminCoinStats(
        circulating: _int(c['circulating']),
        checkinsToday: _int(c['checkins_today']),
        redeemCount: _int(c['redeem_count']),
        redeemedCoins: _int(c['redeemed_coins']),
      ),
      coinRows: [
        for (final e in _maps(j['coin_rows'])) AdminCoinRow(e['customer'] as String, CoinEntry.fromJson(_obj(e['entry']))),
      ],
      memberTx: [
        for (final e in _maps(j['member_tx'])) AdminMemberTx(e['customer'] as String, _memberTx(_obj(e['tx']))),
      ],
      activities: [
        for (final e in _maps(j['activities']))
          AdminActivity(
            AdminActivityKind.values.firstWhere((k) => k.name == e['kind'], orElse: () => AdminActivityKind.order),
            e['title'] as String,
            e['subtitle'] as String,
            _date(e['at']),
          ),
      ],
    );
  }

  @override
  Future<RewardConfig> saveRewards(RewardConfig config) async =>
      RewardConfig.fromJson(_obj(await _call('PUT', '/admin/rewards', body: config.toJson())));

  @override
  Future<MembershipPlan> savePlan(MembershipPlan plan) async => MembershipPlan.fromJson(_obj(await _call(
        'PUT',
        '/admin/plans/${plan.tier.name}',
        body: {
          'price': plan.price,
          'discount_pct': plan.discountPct,
          'priority': plan.priority,
          'promo': plan.promo,
          'benefits': plan.benefits,
          'free_package': plan.freePackage,
          'free_wash_quota': plan.freeWashQuota,
          'free_vehicles': [for (final v in plan.freeVehicles) v.name],
          'snack': plan.snack,
          'vip': plan.vip,
          'massage': plan.massage,
        },
      )));
}
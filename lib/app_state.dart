import 'package:flutter/foundation.dart';
import 'models.dart';

/// Lapisan data sementara (mock). Saat backend Laravel siap, ganti isi tiap
/// method dengan pemanggilan HTTP ke endpoint REST API.
class AppState extends ChangeNotifier {
  static const adminEmail = 'admin@cleandrive.com';
  static const adminPass = 'admin123';
  static const maxPerSlot = 3;

  String? user;
  String email = '';
  String phone = '';
  String _pass = '';
  bool isAdmin = false;
  final List<Booking> bookings = [];

  // TODO API: POST /api/login , POST /api/register (respons membawa role)
  bool login(String name, String email, String pass) {
    final isAdminEmail = email.trim().toLowerCase() == adminEmail;
    if (isAdminEmail && pass != adminPass) return false;
    isAdmin = isAdminEmail;
    user = isAdmin ? 'Admin' : name;
    this.email = email.trim();
    _pass = pass;
    notifyListeners();
    return true;
  }

  void logout() {
    user = null;
    isAdmin = false;
    email = '';
    phone = '';
    notifyListeners();
  }

  // TODO API: PUT /api/profile
  void updateProfile(String name, String phoneNumber) {
    for (final b in bookings) {
      if (b.owner == user) b.owner = name;
    }
    user = name;
    phone = phoneNumber;
    notifyListeners();
  }

  // TODO API: PUT /api/password
  bool changePassword(String oldPass, String newPass) {
    if (oldPass != _pass) return false;
    _pass = newPass;
    return true;
  }

  // TODO API: GET /api/bookings (konsumen: milik sendiri, admin: semua)
  List<Booking> get myBookings => bookings.where((b) => b.owner == user).toList();
  List<Booking> get queue =>
      (List.of(bookings)..sort((a, b) => a.slot.compareTo(b.slot)));

  // TODO API: GET /api/slots?date=...
  int slotCount(DateTime d, int hour) => bookings
      .where((b) => b.slot.year == d.year && b.slot.month == d.month &&
          b.slot.day == d.day && b.slot.hour == hour).length;

  /// Estimasi selesai = jam datang + durasi paket + 10 menit per antrean di depan.
  DateTime estimate(DateTime slot, WashPackage p) {
    final ahead = slotCount(slot, slot.hour);
    return slot.add(Duration(minutes: p.minutes + ahead * 10));
  }

  // TODO API: POST /api/bookings
  Booking create(VehicleType v, WashPackage p, String plate, DateTime slot) {
    final id = (bookings.length + 1).toString().padLeft(4, '0');
    final b = Booking(
      id: id, code: 'CD-$id-${plate.replaceAll(' ', '').toUpperCase()}',
      plate: plate.toUpperCase(), owner: user!, vehicle: v, pack: p, slot: slot,
      estFinish: estimate(slot, p), price: p.priceFor(v),
    );
    bookings.insert(0, b);
    notifyListeners();
    return b;
  }

  // TODO API: PATCH /api/bookings/{id}/status (khusus admin)
  void advance(Booking b) {
    if (b.status < statusLabels.length - 1) { b.status++; notifyListeners(); }
  }

  // TODO API: POST /api/bookings/verify {code}
  Booking? verify(String code) {
    final c = code.trim().toUpperCase();
    for (final b in bookings) {
      if (b.code.toUpperCase() == c) { b.verified = true; notifyListeners(); return b; }
    }
    return null;
  }

  // Ringkasan admin
  int get doneCount => bookings.where((b) => b.status == 3).length;
  int get revenue => bookings.where((b) => b.status == 3).fold(0, (s, b) => s + b.price);
}

final app = AppState();

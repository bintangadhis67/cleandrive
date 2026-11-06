enum VehicleType { motor, mobil, suv }

extension VehicleX on VehicleType {
  String get label => const {'motor': 'Motor', 'mobil': 'Mobil', 'suv': 'SUV'}[name]!;
  double get factor => const {'motor': 1.0, 'mobil': 2.0, 'suv': 2.5}[name]!;
}

class WashPackage {
  final String name, desc;
  final int basePrice, minutes;
  const WashPackage(this.name, this.desc, this.basePrice, this.minutes);
  int priceFor(VehicleType v) => (basePrice * v.factor).round();
}

const packages = [
  WashPackage('Express', 'Cuci luar + keringkan', 25000, 20),
  WashPackage('Reguler', 'Cuci luar, vakum interior, semir ban', 50000, 40),
  WashPackage('Detailing', 'Poles body, cuci mesin, interior deep clean', 150000, 120),
];

const statusLabels = ['Menunggu', 'Dicuci', 'Finishing', 'Selesai'];

class Booking {
  final String id, code, plate;
  String owner;
  final VehicleType vehicle;
  final WashPackage pack;
  final DateTime slot, estFinish;
  final int price;
  int status; // index pada statusLabels
  bool verified; // sudah discan/diverifikasi petugas saat tiba
  Booking({
    required this.id, required this.code, required this.plate, required this.owner,
    required this.vehicle, required this.pack, required this.slot,
    required this.estFinish, required this.price, this.status = 0, this.verified = false,
  });
}

String rp(int n) =>
    'Rp ${n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';

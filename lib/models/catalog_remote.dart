import 'dart:typed_data';

import 'loyalty_models.dart';
import 'membership_models.dart';
import 'models.dart';

/// Foto yang dipilih admin dari perangkat, siap diunggah ke server.
class PickedImage {
  final Uint8List bytes;
  final String name;
  const PickedImage(this.bytes, this.name);
}

/// Katalog dari server: daftar produk (Toko dan oli) serta harga, durasi, dan deskripsi paket layanan.
class ServerCatalog {
  final List<Product> products;
  final List<LivePackage> packages;
  final RewardConfig? rewards; // null = server lama tanpa pengaturan reward
  final List<MembershipPlan> plans; // kosong = server lama
  const ServerCatalog({required this.products, this.packages = const [], this.rewards, this.plans = const []});
}

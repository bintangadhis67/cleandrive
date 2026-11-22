import 'dart:typed_data';

import 'models.dart';

/// Foto yang dipilih admin dari perangkat, siap diunggah ke server.
class PickedImage {
  final Uint8List bytes;
  final String name;
  const PickedImage(this.bytes, this.name);
}

/// Katalog dari server. Saat ini berisi daftar produk (Toko dan oli).
class ServerCatalog {
  final List<Product> products;
  const ServerCatalog({required this.products});
}

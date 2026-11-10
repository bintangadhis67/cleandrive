import 'models.dart';

/// Daftar produk Toko CleanDrive. Ubah nama, harga, atau gambar di sini.
/// Gambar ada di assets/images/.
const products = <Product>[
  // ---------- Makanan ----------
  Product('mk1', 'Roti Sisir Original', 'Roti sisir lembut, 140 g', 12000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_1.jpeg'),
  Product('mk2', 'Taro Net Seaweed', 'Snack rumput laut, 140 g', 12000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_2.jpeg'),
  Product('mk3', 'Japota Seaweed', 'Keripik kentang rasa rumput laut', 10000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_3.jpeg'),
  Product('mk4', 'Pop Mie Pedas', 'Mi instan cup rasa pedas, 75 g', 8000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_4.jpeg'),
  Product('mk5', 'Pop Mie Goreng Pedas', 'Mi goreng instan cup, 75 g', 9000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_5.jpeg'),
  Product('mk6', 'Sari Roti Sandwich Cokelat', 'Roti sandwich isi cokelat', 9000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_6.jpeg'),
  Product('mk7', 'Oishi Udang Pedas', 'Snack rasa udang pedas', 8000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_7.jpeg'),
  Product('mk8', 'Chitato Sapi Panggang', 'Keripik kentang bergelombang', 12000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_8.jpeg'),
  Product('mk9', 'Pop Mie Ayam Bawang', 'Mi instan cup, 75 g', 8000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_9.jpeg'),
  Product('mk10', 'Doritos Roasted Corn', 'Tortilla chips jagung panggang', 14000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_10.jpg'),

  // ---------- Minuman ----------
  Product('mn1', 'Aqua 600 ml', 'Air mineral', 5000, ProductCategory.minuman, 'assets/images/Minuman_1.jpeg'),
  Product('mn2', 'Le Minerale 600 ml', 'Air mineral', 5000, ProductCategory.minuman, 'assets/images/Minuman_2.jpeg'),
  Product('mn3', 'Golda Dolce Latte', 'Kopi susu dingin siap minum', 8000, ProductCategory.minuman, 'assets/images/Minuman_3.jpeg'),
  Product('mn4', 'Coca-Cola', 'Minuman bersoda, botol', 7000, ProductCategory.minuman, 'assets/images/Minuman_4.png'),
  Product('mn5', 'Sprite', 'Minuman bersoda lemon-lime', 7000, ProductCategory.minuman, 'assets/images/Minuman_5.png'),
  Product('mn6', 'Teh Pucuk Harum', 'Teh manis siap minum', 6000, ProductCategory.minuman, 'assets/images/Minuman_6.png'),

  // ---------- Oli ----------
  Product('ol1', 'Pertamina Enduro Matic', 'SAE 10W-30 • 0,8 L • motor matic', 48000, ProductCategory.oli, 'assets/images/Oli_1.jpeg',
      vehicles: {VehicleType.motor}),
  Product('ol3', 'Castrol Power1 4T', 'SAE 10W-40 • 1 L • full synthetic', 95000, ProductCategory.oli, 'assets/images/Oli_3.jpeg',
      vehicles: {VehicleType.motor}),
  Product('ol5', 'Federal Ultratec 4T', 'SAE 10W-40 • 0,8 L • motor', 52000, ProductCategory.oli, 'assets/images/Oli_5.jpeg',
      vehicles: {VehicleType.motor}),
  Product('ol6', 'Shell Advance Ultra 4T', 'SAE 15W-50 • 1 L • 100% synthetic', 125000, ProductCategory.oli, 'assets/images/Oli_6.jpeg',
      vehicles: {VehicleType.motor}),
  Product('ol4', 'Shell Helix AH', 'SAE 15W-40 • 4 L • mobil', 285000, ProductCategory.oli, 'assets/images/Oli_4.jpeg',
      vehicles: {VehicleType.mobil, VehicleType.suv}),
  Product('ol2', 'Fastron Gold', 'SAE 5W-30 • 5 L • synthetic', 395000, ProductCategory.oli, 'assets/images/Oli_2.jpeg',
      vehicles: {VehicleType.mobil, VehicleType.suv}),
];

Product? productById(String id) => products.where((p) => p.id == id).firstOrNull;

Iterable<Product> productsIn(ProductCategory c) => products.where((p) => p.category == c);

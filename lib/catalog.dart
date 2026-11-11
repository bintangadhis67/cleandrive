import 'models.dart';

/// Stok di bawah angka ini akan ditampilkan ke pembeli (mis. "Sisa 3").
const kLowStock = 5;

/// Daftar produk Toko CleanDrive. Ubah nama, harga, gambar, atau stok (stock:) di sini.
/// Gambar ada di assets/images/.
const products = <Product>[
  // ---------- Makanan ----------
  Product('mk1', 'Roti Sisir Original', 'Roti sisir lembut, 140 g', 12000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_1.jpeg', stock: 3),
  Product('mk2', 'Taro Net Seaweed', 'Snack rumput laut, 140 g', 12000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_2.jpeg', stock: 12),
  Product('mk3', 'Japota Seaweed', 'Keripik kentang rasa rumput laut', 10000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_3.jpeg', stock: 8),
  Product('mk4', 'Pop Mie Pedas', 'Mi instan cup rasa pedas, 75 g', 8000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_4.jpeg', stock: 4),
  Product('mk5', 'Pop Mie Goreng Pedas', 'Mi goreng instan cup, 75 g', 9000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_5.jpeg', stock: 15),
  Product('mk6', 'Sari Roti Sandwich Cokelat', 'Roti sandwich isi cokelat', 9000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_6.jpeg', stock: 2),
  Product('mk7', 'Oishi Udang Pedas', 'Snack rasa udang pedas', 8000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_7.jpeg', stock: 9),
  Product('mk8', 'Chitato Sapi Panggang', 'Keripik kentang bergelombang', 12000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_8.jpeg', stock: 20),
  Product('mk9', 'Pop Mie Ayam Bawang', 'Mi instan cup, 75 g', 8000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_9.jpeg', stock: 0),
  Product('mk10', 'Doritos Roasted Corn', 'Tortilla chips jagung panggang', 14000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_10.jpg', stock: 6),

  // ---------- Minuman ----------
  Product('mn1', 'Aqua 600 ml', 'Air mineral', 5000, ProductCategory.minuman, 'assets/images/Minuman_1.jpg', stock: 25),
  Product('mn2', 'Le Minerale 600 ml', 'Air mineral', 5000, ProductCategory.minuman, 'assets/images/Minuman_2.jpeg', stock: 30),
  Product('mn3', 'Golda Dolce Latte', 'Kopi susu dingin siap minum', 8000, ProductCategory.minuman, 'assets/images/Minuman_3.jpeg', stock: 5),
  Product('mn4', 'Coca-Cola', 'Minuman bersoda, botol', 7000, ProductCategory.minuman, 'assets/images/Minuman_4.png', stock: 3),
  Product('mn5', 'Sprite', 'Minuman bersoda lemon-lime', 7000, ProductCategory.minuman, 'assets/images/Minuman_5.png', stock: 18),
  Product('mn6', 'Teh Pucuk Harum', 'Teh manis siap minum', 6000, ProductCategory.minuman, 'assets/images/Minuman_6.png', stock: 4),

  // ---------- Oli ----------
  Product('ol1', 'Pertamina Enduro Matic', 'SAE 10W-30 • 0,8 L • motor matic', 48000, ProductCategory.oli, 'assets/images/Oli_1.jpeg',
      vehicles: {VehicleType.motor}, stock: 10),
  Product('ol3', 'Castrol Power1 4T', 'SAE 10W-40 • 1 L • full synthetic', 95000, ProductCategory.oli, 'assets/images/Oli_3.jpeg',
      vehicles: {VehicleType.motor}, stock: 2),
  Product('ol5', 'Federal Ultratec 4T', 'SAE 10W-40 • 0,8 L • motor', 52000, ProductCategory.oli, 'assets/images/Oli_5.jpeg',
      vehicles: {VehicleType.motor}, stock: 7),
  Product('ol6', 'Shell Advance Ultra 4T', 'SAE 15W-50 • 1 L • 100% synthetic', 125000, ProductCategory.oli, 'assets/images/Oli_6.jpeg',
      vehicles: {VehicleType.motor}, stock: 1),
  Product('ol4', 'Shell Helix AH', 'SAE 15W-40 • 4 L • mobil', 285000, ProductCategory.oli, 'assets/images/Oli_4.jpeg',
      vehicles: {VehicleType.mobil, VehicleType.suv}, stock: 6),
  Product('ol2', 'Fastron Gold', 'SAE 5W-30 • 5 L • synthetic', 395000, ProductCategory.oli, 'assets/images/Oli_2.jpeg',
      vehicles: {VehicleType.mobil, VehicleType.suv}, stock: 3),
];

Product? productById(String id) => products.where((p) => p.id == id).firstOrNull;

Iterable<Product> productsIn(ProductCategory c) => products.where((p) => p.category == c);
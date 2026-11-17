import 'models.dart';

/// Stok di bawah angka ini akan ditampilkan ke pembeli (mis. "Sisa 3").
const kLowStock = 5;

/// Daftar produk Toko CleanDrive. Ubah nama, harga, gambar, atau stok (stock:) di sini.
/// Gambar ada di assets/images/.
const products = <Product>[
  // ---------- Makanan ----------
  Product('mk1', 'Roti Sisir Original', 'Roti sisir lembut, 140 g', 12000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_1_nobg.png', stock: 3),
  Product('mk2', 'Taro Net Seaweed', 'Snack rumput laut, 140 g', 12000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_2_nobg.png', stock: 12),
  Product('mk3', 'Japota Seaweed', 'Keripik kentang rasa rumput laut', 10000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_3_nobg.png', stock: 8),
  Product('mk4', 'Pop Mie Pedas', 'Mi instan cup rasa pedas, 75 g', 8000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_4_nobg.png', stock: 4),
  Product('mk5', 'Pop Mie Goreng Pedas', 'Mi goreng instan cup, 75 g', 9000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_5_nobg.png', stock: 15),
  Product('mk6', 'Sari Roti Sandwich Cokelat', 'Roti sandwich isi cokelat', 9000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_6_nobg.png', stock: 2),
  Product('mk7', 'Oishi Udang Pedas', 'Snack rasa udang pedas', 8000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_7_nobg.png', stock: 9),
  Product('mk8', 'Chitato Sapi Panggang', 'Keripik kentang bergelombang', 12000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_8_nobg.png', stock: 20),
  Product('mk9', 'Pop Mie Ayam Bawang', 'Mi instan cup, 75 g', 8000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_9_nobg.png', stock: 0),
  Product('mk10', 'Doritos Roasted Corn', 'Tortilla chips jagung panggang', 14000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_10_nobg.png', stock: 6),
  Product('mk11', 'Cheetos Jagung Bakar Keju', 'Snack jagung rasa jagung bakar keju, 50 g', 8000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_17_nobg.png', stock: 14),
  Product('mk12', 'Better Sandwich Biscuit', 'Biskuit sandwich lapis cokelat krim vanila, 120 g', 10000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_18_nobg.png', stock: 18),
  Product('mk13', 'Roma Sari Gandum Sandwich', 'Biskuit gandum sandwich krim susu & cokelat', 9000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_19_nobg.png', stock: 3),
  Product('mk14', 'Qtela Singkong Barbeque', 'Keripik singkong rasa barbeque, 60 g', 9000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_20_nobg.png', stock: 11),
  Product('mk15', 'Gery Snack Bantal Chocolate', 'Snack bantal isi krim cokelat, 75 g', 9000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_21_nobg.png', stock: 9),
  Product('mk16', 'KitKat', 'Wafer renyah berlapis cokelat susu', 10000, ProductCategory.makanan, 'assets/images/Makanan_Ringan_22_nobg.png', stock: 4),

  // ---------- Minuman ----------
  Product('mn1', 'Aqua 600 ml', 'Air mineral', 5000, ProductCategory.minuman, 'assets/images/Minuman_1_nobg.png', stock: 25),
  Product('mn2', 'Le Minerale 600 ml', 'Air mineral', 5000, ProductCategory.minuman, 'assets/images/Minuman_2_nobg.png', stock: 30),
  Product('mn3', 'Golda Dolce Latte', 'Kopi susu dingin siap minum', 8000, ProductCategory.minuman, 'assets/images/Minuman_3_nobg.png', stock: 5),
  Product('mn4', 'Coca-Cola', 'Minuman bersoda, botol', 7000, ProductCategory.minuman, 'assets/images/Minuman_4_nobg.png', stock: 3),
  Product('mn5', 'Sprite', 'Minuman bersoda lemon-lime', 7000, ProductCategory.minuman, 'assets/images/Minuman_5_nobg.png', stock: 18),
  Product('mn6', 'Teh Pucuk Harum', 'Teh manis siap minum', 6000, ProductCategory.minuman, 'assets/images/Minuman_6_nobg.png', stock: 4),
  Product('mn7', 'Miliku Susu Cokelat', 'Susu UHT rasa cokelat premium, botol', 5000, ProductCategory.minuman, 'assets/images/Minuman_11_nobg.png', stock: 20),
  Product('mn8', 'Nipis Madu Lime Soda', 'Minuman soda rasa jeruk nipis madu, botol', 6000, ProductCategory.minuman, 'assets/images/Minuman_12_nobg.png', stock: 12),
  Product('mn9', 'Teh Kotak Teh Melati', 'Teh melati kemasan kotak, 200 ml', 4500, ProductCategory.minuman, 'assets/images/Minuman_13_nobg.png', stock: 4),
  Product('mn10', 'Pocari Sweat 500 ml', 'Minuman isotonik, botol 500 ml', 8000, ProductCategory.minuman, 'assets/images/Minuman_14_nobg.png', stock: 16),

  // ---------- Oli ----------
  Product('ol1', 'Pertamina Enduro Matic', 'SAE 10W-30 • 0,8 L • motor matic', 48000, ProductCategory.oli, 'assets/images/Oli_1_nobg.png',
      vehicles: {VehicleType.motor}, stock: 10),
  Product('ol3', 'Castrol Power1 4T', 'SAE 10W-40 • 1 L • full synthetic', 95000, ProductCategory.oli, 'assets/images/Oli_3_nobg.png',
      vehicles: {VehicleType.motor}, stock: 2),
  Product('ol5', 'Federal Ultratec 4T', 'SAE 10W-40 • 0,8 L • motor', 52000, ProductCategory.oli, 'assets/images/Oli_5_nobg.png',
      vehicles: {VehicleType.motor}, stock: 7),
  Product('ol6', 'Shell Advance Ultra 4T', 'SAE 15W-50 • 1 L • 100% synthetic', 125000, ProductCategory.oli, 'assets/images/Oli_6_nobg.png',
      vehicles: {VehicleType.motor}, stock: 1),
  Product('ol4', 'Shell Helix AH', 'SAE 15W-40 • 4 L • mobil', 285000, ProductCategory.oli, 'assets/images/Oli_4_nobg.png',
      vehicles: {VehicleType.mobil}, stock: 6),
  Product('ol2', 'Fastron Gold', 'SAE 5W-30 • 5 L • synthetic', 395000, ProductCategory.oli, 'assets/images/Oli_2_nobg.png',
      vehicles: {VehicleType.mobil}, stock: 3),
  Product('ol7', 'Castrol GTX Ultraclean', 'SAE 5W-20 • 4,73 L (5 qt) • mobil bensin', 420000, ProductCategory.oli, 'assets/images/Oli_11_nobg.png',
      vehicles: {VehicleType.mobil}, stock: 4),
  Product('ol8', 'OLIM 100% Synthetic', 'SAE 5W-40 • 4 L • synthetic • mobil', 380000, ProductCategory.oli, 'assets/images/Oli_12_nobg.png',
      vehicles: {VehicleType.mobil}, stock: 3),
  Product('ol9', 'elf Evolution Full-Tech FE', 'SAE 5W-30 • 1 L • full synthetic • mobil', 115000, ProductCategory.oli, 'assets/images/Oli_13_nobg.png',
      vehicles: {VehicleType.mobil}, stock: 8),
  Product('ol10', 'Mobil Super Everyday Protection', 'SAE 10W-30 • 4 L • mineral • mobil', 300000, ProductCategory.oli, 'assets/images/Oli_14_nobg.png',
      vehicles: {VehicleType.mobil}, stock: 5),
];

/// Deskripsi lengkap tiap produk (tampil di halaman detail saat produk diklik di toko).
/// Kunci = id produk. Produk yang belum punya deskripsi di sini memakai deskripsi singkatnya.
const kProductDetails = <String, String>{
  // ----- Makanan -----
  'mk1': 'Roti sisir lembut dengan rasa original yang gurih manis. Teman santai yang praktis untuk mengganjal lapar sambil menunggu kendaraan selesai dicuci. Berat bersih 140 g.',
  'mk2': 'Snack renyah rasa rumput laut dengan tekstur khas yang ringan dan gurih. Cocok dinikmati sebagai camilan selama menunggu. Berat bersih 140 g.',
  'mk3': 'Keripik kentang tipis yang renyah dengan bumbu rumput laut yang gurih. Camilan ringan untuk berbagi atau dinikmati sendiri.',
  'mk4': 'Mi instan dalam cup dengan rasa pedas. Cukup seduh dengan air panas dan siap disantap dalam beberapa menit. Berat 75 g.',
  'mk5': 'Mi goreng instan dalam cup dengan bumbu pedas yang menggugah selera. Praktis disiapkan, cukup tuang air panas lalu tiriskan. Berat 75 g.',
  'mk6': 'Roti sandwich yang lembut dengan isian selai cokelat manis. Mudah dibawa dan pas sebagai camilan atau sarapan ringan.',
  'mk7': 'Snack renyah dengan rasa udang pedas yang gurih. Camilan kriuk dengan sensasi pedas yang pas untuk teman menunggu.',
  'mk8': 'Keripik kentang bergelombang rasa sapi panggang. Teksturnya renyah dengan bumbu gurih yang melekat di setiap lembarannya.',
  'mk9': 'Mi instan dalam cup dengan rasa ayam bawang yang gurih dan ringan. Praktis, cukup seduh dengan air panas. Berat 75 g.',
  'mk10': 'Tortilla chips berbahan jagung dengan rasa jagung panggang yang gurih. Renyah dan cocok disantap bersama teman.',
  'mk11': 'Snack jagung renyah dengan rasa jagung bakar keju yang gurih dan sedikit manis. Bentuknya ringan dan mudah dimakan, cocok untuk camilan saat menunggu kendaraan dicuci. Berat bersih 50 g.',
  'mk12': 'Biskuit sandwich lapis cokelat dengan krim vanila di tengahnya. Dikemas dalam beberapa potong kecil sehingga mudah dibagi. Berat bersih 120 g.',
  'mk13': 'Biskuit gandum dengan isian krim susu dan cokelat. Rasanya manis lembut dengan tekstur biskuit yang renyah, pas ditemani minuman hangat atau dingin.',
  'mk14': 'Keripik singkong tipis rasa barbeque yang renyah dan gurih dengan aroma bumbu panggang. Camilan khas yang cocok untuk dinikmati kapan saja. Berat bersih 60 g.',
  'mk15': 'Snack berbentuk bantal dengan kulit renyah rasa cokelat dan isian krim cokelat yang lembut di dalamnya. Disukai anak-anak maupun dewasa. Berat bersih 75 g.',
  'mk16': 'Wafer renyah berlapis cokelat susu. Mudah dipatahkan dan dinikmati per batang, cocok untuk camilan manis singkat saat istirahat.',
  // ----- Minuman -----
  'mn1': 'Air mineral dalam kemasan botol 600 ml untuk melepas dahaga selama menunggu. Segar dan praktis dibawa.',
  'mn2': 'Air mineral dengan kandungan mineral alami dalam botol 600 ml. Menyegarkan dan pas untuk menemani perjalanan.',
  'mn3': 'Kopi susu dingin siap minum dengan rasa latte yang manis dan lembut. Pilihan tepat untuk menemani waktu menunggu.',
  'mn4': 'Minuman bersoda dengan rasa cola yang segar dan sensasi karbonasi. Paling nikmat saat disajikan dingin.',
  'mn5': 'Minuman bersoda rasa lemon-lime yang segar dan jernih. Menyegarkan saat cuaca panas.',
  'mn6': 'Teh manis siap minum dengan aroma melati yang harum. Rasanya ringan dan segar saat diminum dingin.',
  'mn7': 'Susu UHT rasa cokelat premium dalam kemasan botol yang praktis. Dibuat dari susu sapi dengan rasa cokelat yang lembut dan manis. Pas untuk teman camilan.',
  'mn8': 'Minuman soda rasa jeruk nipis dan madu yang segar dengan sensasi karbonasi ringan. Segar diminum dingin, cocok untuk melepas dahaga.',
  'mn9': 'Teh melati dalam kemasan kotak yang praktis. Rasanya manis harum dan menyegarkan. Isi bersih 200 ml.',
  'mn10': 'Minuman isotonik dengan rasa segar yang membantu mengganti cairan dan elektrolit tubuh. Cocok diminum saat lelah atau setelah beraktivitas. Botol 500 ml.',
  // ----- Oli -----
  'ol1': 'Oli mesin 4 tak untuk sepeda motor matic dengan kekentalan SAE 10W-30. Isi 0,8 liter, cocok untuk pemakaian harian dan penggantian oli berkala.',
  'ol3': 'Oli mesin 4 tak full synthetic dengan kekentalan SAE 10W-40. Isi 1 liter, dirancang untuk melindungi mesin motor pada pemakaian harian maupun berkendara lebih sporty.',
  'ol5': 'Oli mesin 4 tak dengan kekentalan SAE 10W-40, isi 0,8 liter. Cocok untuk sepeda motor dan penggantian oli rutin.',
  'ol6': 'Oli mesin 4 tak 100% synthetic dengan kekentalan SAE 15W-50. Isi 1 liter, untuk motor yang membutuhkan perlindungan mesin lebih baik.',
  'ol4': 'Oli mesin mobil dengan kekentalan SAE 15W-40. Isi 4 liter, cocok untuk penggantian oli berkala pada mobil.',
  'ol2': 'Oli mesin mobil synthetic dengan kekentalan SAE 5W-30. Isi 5 liter, cocok untuk mesin mobil modern.',
  'ol7': 'Oli mesin untuk mobil bensin dengan kekentalan SAE 5W-20. Kemasan 4,73 liter (5 quart). Pastikan viskositasnya sesuai rekomendasi buku manual kendaraan Anda.',
  'ol8': 'Oli mesin 100% synthetic dengan kekentalan SAE 5W-40, spesifikasi API SN/CF dan ACEA C3/B3/B4. Isi 4 liter, dapat dipakai untuk mobil bensin maupun diesel.',
  'ol9': 'Oli mesin full synthetic dengan kekentalan SAE 5W-30 untuk mobil. Kemasan 1 liter, cocok untuk menambah atau mengganti oli sesuai kebutuhan mesin.',
  'ol10': 'Oli mesin mineral untuk perlindungan sehari-hari dengan kekentalan SAE 10W-30 dan spesifikasi API SP. Isi 4 liter, dirancang untuk menjaga usia mesin mobil.',
};

extension ProductInfo on Product {
  /// Deskripsi lengkap untuk halaman detail produk.
  String get details => kProductDetails[id] ?? desc;
}

Product? productById(String id) => products.where((p) => p.id == id).firstOrNull;

Iterable<Product> productsIn(ProductCategory c) => products.where((p) => p.category == c);
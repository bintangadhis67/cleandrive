# Menerapkan perubahan kecil pada file Flutter yang sudah ada (tahap B: katalog produk dari server).
# Jalankan dari folder utama proyek:
#   powershell -ExecutionPolicy Bypass -File tools\patch_katalog.ps1
# Setiap file yang diubah dicadangkan dulu sebagai <nama>.bak. Aman dijalankan ulang (yang sudah diubah dilewati).

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$script:failed = 0

function Apply-Patch([string]$RelPath, [string]$Find, [string]$Replace, [string]$Marker) {
    $path = Join-Path $root $RelPath
    if (-not (Test-Path $path)) {
        Write-Host "TIDAK ADA  $RelPath" -ForegroundColor Red
        $script:failed++
        return
    }
    $text = [System.IO.File]::ReadAllText($path)
    if ($text.Contains($Marker)) {
        Write-Host "SUDAH      $RelPath  ($Marker)" -ForegroundColor DarkGray
        return
    }
    $count = ([regex]::Matches($text, [regex]::Escape($Find))).Count
    if ($count -ne 1) {
        Write-Host "GAGAL      $RelPath  (baris acuan ditemukan $count kali): $Find" -ForegroundColor Red
        $script:failed++
        return
    }
    $nl = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
    $new = $Replace.Replace("`r`n", "`n").Replace("`n", $nl)
    if (-not (Test-Path "$path.bak")) { Copy-Item $path "$path.bak" }
    [System.IO.File]::WriteAllText($path, $text.Replace($Find, $new))
    Write-Host "OK         $RelPath" -ForegroundColor Green
}

# ---------------------------------------------------------------- lib/models/models.dart (kelas Product)
$r = @'
  final Set<VehicleType> vehicles;

  /// Keterangan lengkap dari server. Kosong = pakai kProductDetails atau deskripsi singkat.
  final String? detailsText;

  /// false = sudah dinonaktifkan admin: tidak tampil di Toko, tetapi pesanan lama tetap terbaca.
  final bool active;
'@
Apply-Patch 'lib/models/models.dart' '  final Set<VehicleType> vehicles;' $r 'final String? detailsText;'

Apply-Patch 'lib/models/models.dart' '      {this.vehicles = const {}, this.stock = 20});' '      {this.vehicles = const {}, this.stock = 20, this.detailsText, this.active = true});' 'this.detailsText, this.active'

# ---------------------------------------------------------------- lib/models/catalog.dart (daftar produk hidup)
$r = @'
/// Daftar produk yang sedang dipakai: dari server bila sudah dimuat, selain itu daftar bawaan di atas.
List<Product>? _liveProducts;
List<Product> get catalogProducts => _liveProducts ?? products;
void setLiveProducts(List<Product> list) => _liveProducts = list;

Product? productById(String id) => catalogProducts.where((p) => p.id == id).firstOrNull;
'@
Apply-Patch 'lib/models/catalog.dart' 'Product? productById(String id) => products.where((p) => p.id == id).firstOrNull;' $r 'setLiveProducts'

Apply-Patch 'lib/models/catalog.dart' 'Iterable<Product> productsIn(ProductCategory c) => products.where((p) => p.category == c);' 'Iterable<Product> productsIn(ProductCategory c) => catalogProducts.where((p) => p.active && p.category == c);' 'catalogProducts.where((p) => p.active'

Apply-Patch 'lib/models/catalog.dart' '  String get details => kProductDetails[id] ?? desc;' '  String get details => detailsText ?? kProductDetails[id] ?? desc;' 'detailsText ??'

# ---------------------------------------------------------------- lib/screens/shop/shop.dart (foto dari server)
$r = @'
  Widget build(BuildContext context) => p.image.startsWith('http')
      ? Image.network(
          p.image,
          height: height,
          fit: BoxFit.contain,
          cacheWidth: cacheWidth,
          errorBuilder: (_, __, ___) => Icon(p.category.icon, size: (height ?? 100) * .4, color: kMuted),
        )
      : Image.asset(
'@
Apply-Patch 'lib/screens/shop/shop.dart' '  Widget build(BuildContext context) => Image.asset(' $r 'Image.network('

# ---------------------------------------------------------------- lib/core/app_state.dart (memuat katalog)
Apply-Patch 'lib/core/app_state.dart' "import '../data/repository.dart';" "import '../data/repository.dart';`nimport '../models/catalog.dart' show setLiveProducts;" 'show setLiveProducts'

$r = @'
  DateTime? _catalogAt;

  /// Memuat katalog produk dari server (disimpan sekitar 1 menit di memori). Bila gagal, katalog yang ada tetap dipakai.
  Future<void> loadCatalog({bool force = false}) async {
    final at = _catalogAt;
    if (!force && at != null && DateTime.now().difference(at) < const Duration(minutes: 1)) return;
    try {
      final c = await repo.catalog();
      setLiveProducts(c.products);
      _catalogAt = DateTime.now();
    } catch (_) {}
  }

  Future<void> refreshAll() async {
    await loadCatalog();
'@
Apply-Patch 'lib/core/app_state.dart' '  Future<void> refreshAll() async {' $r 'Future<void> loadCatalog'

# ---------------------------------------------------------------- lib/data/repository.dart (antarmuka)
Apply-Patch 'lib/data/repository.dart' "import '../models/loyalty_models.dart';" "import '../models/catalog_remote.dart';`nimport '../models/loyalty_models.dart';" "catalog_remote.dart"

$r = @'
  Future<AdminOverview> adminOverview();

  // katalog (server)

  /// Katalog produk terbaru dari server. Termasuk produk yang sudah dinonaktifkan, supaya pesanan lama tetap terbaca.
  Future<ServerCatalog> catalog();

  /// Admin: tambah produk (id kosong) atau ubah produk. [image] = foto baru; kosong = foto lama dipertahankan.
  Future<Product> saveProduct(Product p, {PickedImage? image});

  /// Admin: hapus produk. Yang sudah pernah dipesan hanya dinonaktifkan. Hasil: pesan untuk ditampilkan.
  Future<String> deleteProduct(String id);
'@
Apply-Patch 'lib/data/repository.dart' '  Future<AdminOverview> adminOverview();' $r 'Future<ServerCatalog> catalog();'

# ---------------------------------------------------------------- lib/data/mock_repository.dart (mode demo)
Apply-Patch 'lib/data/mock_repository.dart' "import '../models/catalog.dart';" "import '../models/catalog.dart';`nimport '../models/catalog_remote.dart';" "catalog_remote.dart"

# Anotasi @override yang sudah ada di atas baris acuan kini berlaku untuk catalog().
$r = @'
  Future<ServerCatalog> catalog() async => ServerCatalog(products: products);

  @override
  Future<Product> saveProduct(Product p, {PickedImage? image}) async =>
      throw ApiException('Mode demo (tanpa server) tidak menyimpan perubahan katalog.');

  @override
  Future<String> deleteProduct(String id) async =>
      throw ApiException('Mode demo (tanpa server) tidak menyimpan perubahan katalog.');

  @override
  Future<AdminOverview> adminOverview() async {
'@
Apply-Patch 'lib/data/mock_repository.dart' '  Future<AdminOverview> adminOverview() async {' $r 'Future<ServerCatalog> catalog()'

Write-Host ''
if ($script:failed -gt 0) {
    Write-Host "$($script:failed) perubahan GAGAL. Kirim tampilan di atas ke Claude, atau ubah barisnya secara manual." -ForegroundColor Red
    exit 1
}
Write-Host 'Semua perubahan terpasang. Jalankan: flutter pub add image_picker, lalu flutter analyze.' -ForegroundColor Green

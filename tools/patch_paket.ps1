# Tahap C1: harga, durasi, dan deskripsi paket layanan dibaca dari server (bukan dari kode).
# Jalankan dari folder utama proyek:
#   powershell -ExecutionPolicy Bypass -File tools\patch_paket.ps1
# Setiap file yang diubah dicadangkan dulu sebagai <nama>.bak. Aman dijalankan ulang.

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
    # Samakan gaya baris baru (LF atau CRLF) pada teks cari dan teks pengganti dengan isi file.
    $nl = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
    $Find = $Find.Replace("`r`n", "`n").Replace("`n", $nl)
    $new = $Replace.Replace("`r`n", "`n").Replace("`n", $nl)
    $count = ([regex]::Matches($text, [regex]::Escape($Find))).Count
    if ($count -ne 1) {
        Write-Host "GAGAL      $RelPath  (bagian acuan ditemukan $count kali)" -ForegroundColor Red
        $script:failed++
        return
    }
    if (-not (Test-Path "$path.bak")) { Copy-Item $path "$path.bak" }
    [System.IO.File]::WriteAllText($path, $text.Replace($Find, $new))
    Write-Host "OK         $RelPath" -ForegroundColor Green
}

# ---------------------------------------------------------------- lib/models/models.dart (kelas WashPackage)
# Harga, durasi, dan deskripsi menjadi getter yang membaca nilai dari server bila sudah dimuat.
$find = @'
class WashPackage {
  final String name, desc;
  final int basePrice, minutes;
  final ServiceKind kind;

  /// Harga khusus per jenis kendaraan. Bila kosong, harga = basePrice x faktor kendaraan.
  final Map<VehicleType, int> prices;
  const WashPackage(this.name, this.desc, this.basePrice, this.minutes,
      {this.kind = ServiceKind.wash, this.prices = const {}});
'@
$rep = @'
/// Harga, durasi, dan deskripsi paket yang dikirim server.
class LivePackage {
  final String name, desc;
  final int basePrice, minutes;
  final Map<VehicleType, int> prices;
  const LivePackage({required this.name, required this.desc, required this.basePrice, required this.minutes, required this.prices});
}

class WashPackage {
  final String name;
  final String _desc;
  final int _basePrice, _minutes;
  final ServiceKind kind;

  /// Harga khusus per jenis kendaraan. Bila kosong, harga = basePrice x faktor kendaraan.
  final Map<VehicleType, int> _prices;
  const WashPackage(this.name, this._desc, this._basePrice, this._minutes,
      {this.kind = ServiceKind.wash, Map<VehicleType, int> prices = const {}})
      : _prices = prices;

  /// Nilai terbaru dari server (diisi saat katalog dimuat). Kosong = nilai bawaan di kode.
  static final Map<String, LivePackage> _live = {};
  static void applyLive(Iterable<LivePackage> list) {
    _live
      ..clear()
      ..addEntries(list.map((e) => MapEntry(e.name, e)));
  }

  String get desc => _live[name]?.desc ?? _desc;
  int get basePrice => _live[name]?.basePrice ?? _basePrice;
  int get minutes => _live[name]?.minutes ?? _minutes;
  Map<VehicleType, int> get prices => _live[name]?.prices ?? _prices;
'@
Apply-Patch 'lib/models/models.dart' $find $rep 'static void applyLive'

# ---------------------------------------------------------------- lib/core/app_state.dart
Apply-Patch 'lib/core/app_state.dart' '      setLiveProducts(c.products);' "      setLiveProducts(c.products);`n      WashPackage.applyLive(c.packages);" 'WashPackage.applyLive'

# ---------------------------------------------------------------- lib/data/repository.dart (antarmuka)
$rep = @'
  Future<String> deleteProduct(String id);

  /// Admin: ubah deskripsi, durasi, dan harga satu paket layanan (cuci atau ganti oli) yang sudah ada.
  Future<void> savePackage(String name, {required String desc, required int minutes, required int priceMotor, required int priceMobil});
'@
Apply-Patch 'lib/data/repository.dart' '  Future<String> deleteProduct(String id);' $rep 'Future<void> savePackage'

# ---------------------------------------------------------------- lib/data/mock_repository.dart (mode demo)
# Anotasi @override yang sudah ada di atas baris acuan kini berlaku untuk savePackage().
$rep = @'
  Future<void> savePackage(String name, {required String desc, required int minutes, required int priceMotor, required int priceMobil}) async =>
      throw ApiException('Mode demo (tanpa server) tidak menyimpan perubahan katalog.');

  @override
  Future<String> deleteProduct(String id) async =>
'@
Apply-Patch 'lib/data/mock_repository.dart' '  Future<String> deleteProduct(String id) async =>' $rep 'Future<void> savePackage'

Write-Host ''
if ($script:failed -gt 0) {
    Write-Host "$($script:failed) perubahan GAGAL. Kirim tampilan di atas ke Claude." -ForegroundColor Red
    exit 1
}
Write-Host 'Semua perubahan terpasang. Jalankan: flutter analyze' -ForegroundColor Green

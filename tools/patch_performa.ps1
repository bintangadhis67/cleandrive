# Mempercepat pemuatan data aplikasi (tahap performa).
# Jalankan dari folder utama proyek:
#   powershell -ExecutionPolicy Bypass -File tools\patch_performa.ps1
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

# ---------------------------------------------------------------- lib/core/app_state.dart
# Data pelanggan diminta sekaligus (bukan satu per satu), sehingga layar awal terbuka lebih cepat.
$find = @'
    if (!isAdmin) {
      vouchers = await repo.vouchers();
      quota = await repo.voucherQuota();
      loyalty = await repo.loyalty();
      membership = await repo.membership();
      garage = await repo.garage();
      await _fetchNotifications();
    }
'@
$rep = @'
    if (!isAdmin) {
      // Semua data pelanggan diminta sekaligus (bukan satu per satu) supaya layar awal cepat terbuka.
      final m = await Future.wait<Object?>([
        repo.vouchers(),
        repo.voucherQuota(),
        repo.loyalty(),
        repo.membership(),
        repo.garage(),
        _fetchNotifications(),
      ]);
      vouchers = m[0] as List<Voucher>;
      quota = m[1] as VoucherQuota;
      loyalty = m[2] as LoyaltyInfo;
      membership = m[3] as MembershipInfo;
      garage = m[4] as List<GarageVehicle>;
    }
'@
Apply-Patch 'lib/core/app_state.dart' $find $rep 'Future.wait<Object?>'

# ---------------------------------------------------------------- lib/screens/admin/shared/admin_data.dart
# Panel admin memuat 4 kelompok data sekaligus, dan memuat ulang tiap 20 detik (sebelumnya tiap 8 detik, satu per satu).
$find = @'
      await app.refreshAll();
      summary = await app.summary();
      overview = await app.repo.adminOverview();
      reviews = await app.allReviews();
'@
$rep = @'
      await Future.wait([
        app.refreshAll(),
        app.summary().then((v) => summary = v),
        app.repo.adminOverview().then((v) => overview = v),
        app.allReviews().then((v) => reviews = v),
      ]);
'@
Apply-Patch 'lib/screens/admin/shared/admin_data.dart' $find $rep '.then((v) => summary = v)'

Apply-Patch 'lib/screens/admin/shared/admin_data.dart' '      _timer = Timer.periodic(const Duration(seconds: 8), (_) => load());' '      _timer = Timer.periodic(const Duration(seconds: 20), (_) => load());' 'Duration(seconds: 20), (_) => load()'

Write-Host ''
if ($script:failed -gt 0) {
    Write-Host "$($script:failed) perubahan GAGAL. Kirim tampilan di atas ke Claude." -ForegroundColor Red
    exit 1
}
Write-Host 'Semua perubahan terpasang. Jalankan: flutter analyze' -ForegroundColor Green

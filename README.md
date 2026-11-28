# CleanDrive

**Aplikasi Mobile Booking dan Pelacakan Antrean Cuci Kendaraan** *Drive Cleaner, Go Further.*

Proyek aplikasi mobile untuk layanan cuci kendaraan. Aplikasi Flutter (Android, iOS, dan web) terhubung ke backend Laravel REST API dengan basis data MySQL. Pelanggan dapat memesan cuci atau ganti oli, memilih jam kedatangan, membayar, lalu memantau antrean lewat tiket QR. Tersedia juga Toko, voucher, program hadiah **Coins**, **Membership** berjenjang, dan panel admin untuk operasional outlet.

> Pembayaran pada versi ini masih berupa **sandbox (simulasi)**. Tidak ada uang sungguhan yang dipindahkan dan tidak ada data kartu yang disimpan. Data outlet, produk, dan voucher adalah data contoh untuk pengembangan.

## Fitur

### Pelanggan

| Fitur | Status |
|-------|--------|
| Splash beranimasi, daftar, dan masuk (token Sanctum, sesi dipulihkan otomatis) | Selesai |
| Beranda: sapaan berbeda untuk pengguna baru dan pengguna lama, kartu Coins dan Membership, akses cepat, outlet terdekat | Selesai |
| Garasi kendaraan (motor/mobil), plat ganda ditolak | Selesai |
| Booking cuci (Express, Reguler, Detailing) dan ganti oli, maksimal 3 booking per jam, estimasi selesai | Selesai |
| Pembayaran QRIS dan e-wallet (GoPay, OVO, DANA, ShopeePay, Livin') dengan batas waktu 10 menit | Selesai |
| Tiket QR, pelacakan antrean empat tahap, pembatalan, dan bukti pesanan PDF | Selesai |
| Ulasan dan rating setelah pesanan selesai | Selesai |
| Toko: makanan, minuman, dan oli (oli menurut jenis kendaraan), keranjang, dan stok | Selesai |
| Voucher: klaim, batas klaim harian, dan voucher mingguan | Selesai |
| Coins: check-in 7 hari, promo, riwayat, dan tukar saat pembayaran | Selesai |
| Membership Bronze sampai Platinum: diskon, cuci gratis, dan benefit | Selesai |
| Notifikasi dan pengingat jadwal, profil, ganti password, pengaturan, bantuan | Selesai |

### Admin

| Fitur | Status |
|-------|--------|
| Dashboard ringkasan pesanan, pendapatan, dan rating | Selesai |
| Antrean layanan dan penaikan status pesanan | Selesai |
| Verifikasi tiket dengan mengetik kode atau memindai QR | Selesai |
| Data pelanggan serta pesanan dan transaksi | Selesai |
| Kelola produk (foto, stok, harga) dan harga paket | Selesai |
| Statistik dan **pengaturan reward Coins** | Selesai |
| Statistik dan **ubah tingkatan Membership** | Selesai |
| Ulasan pelanggan | Selesai |

### Tampilan dan animasi

- Identitas visual navy, krem, dan merah metalik, dengan emas khusus untuk Coins. Huruf Plus Jakarta Sans, dan Orbitron pada banner Beranda.
- Animasi dibuat dengan widget bawaan Flutter tanpa paket tambahan: efek tekan pada tombol dan kartu, daftar yang muncul bertahap, transisi halaman geser-pudar, skeleton pemuatan, serta animasi centang dan konfeti saat pembayaran atau klaim voucher berhasil. Panduan lengkap ada di `docs/PANDUAN-ANIMASI.md`.
- Panel admin responsif: sidebar tetap pada layar lebar dan laci (drawer) pada layar sempit.

## Aturan bisnis penting

1. Pendaftaran dari aplikasi selalu menghasilkan akun pelanggan. Akun admin dibuat melalui seeder.
2. Jam operasional 08.00 sampai 17.00 WIB dengan maksimal 3 booking per jam. Estimasi selesai dihitung dari slot, durasi paket, dan antrean di depannya.
3. Harga, diskon voucher dan membership, kapasitas slot, stok, dan Coins dihitung di server, bukan di aplikasi.
4. Pembayaran kedaluwarsa setelah 10 menit dan dapat dibuat ulang.
5. 1 Coin bernilai Rp 50. Coins ditukar dalam kelipatan 10 dan maksimal 30% dari total.
6. Verifikasi tiket hanya untuk pesanan yang sudah dibayar dan tidak dibatalkan. Pesanan yang sudah diproses tidak dapat dibatalkan.
7. Cuci gratis membership dibatasi satu kali per minggu sesuai jatah tingkatannya.
8. Nilai reward Coins dan tingkatan membership dapat diubah admin dan berlaku untuk transaksi berikutnya.

## Teknologi

| Bagian | Teknologi |
|--------|-----------|
| Aplikasi | Flutter (Dart 3.3 ke atas), `http`, `shared_preferences`, `image_picker`, `qr_flutter`, `mobile_scanner`, `pdf`, `printing`, `intl`, `google_fonts` |
| Backend | PHP 8.3, Laravel 13, Laravel Sanctum (autentikasi token) |
| Basis data | MySQL (Laragon), 19 tabel domain |
| Pengujian | Uji manual (`docs/UJI-MENYELURUH.md`), PHPUnit pada backend |

Arsitektur aplikasi: `Screens -> AppState (ChangeNotifier) -> Repository (abstrak) -> ApiRepository | MockRepository -> REST API`. Pada backend: `Route -> Controller -> Service -> Model -> MySQL`.

## Struktur folder

```
cleandrive/
├── lib/
│   ├── core/            state aplikasi dan tema (design tokens)
│   ├── data/            Repository, ApiRepository, MockRepository
│   ├── models/          model data
│   ├── screens/         auth, home, orders, payment, shop, rewards,
│   │                    profile, garage, outlet, notifications, admin
│   ├── widgets/         komponen bersama dan animasi (motion.dart)
│   └── main.dart
├── assets/              gambar dan ilustrasi
├── backend/             Laravel REST API
│   ├── app/             Http/Controllers/Api, Services, Models, Support
│   ├── config/          cleandrive.php (nilai awal aturan bisnis)
│   ├── database/        migrations (19 tabel), seeders (data awal + demo)
│   └── routes/          api.php
├── docs/                DIAGRAM, UJI-MENYELURUH, SKRIP-DEMO, PANDUAN-ANIMASI
├── tools/               skrip pendukung
└── pubspec.yaml
```

## Cara menjalankan

Prasyarat: Laragon (PHP 8.3+ dan MySQL), Composer, dan Flutter SDK.

### 1. Backend (Laravel)

Buat database kosong bernama `cleandrive` di MySQL, lalu:

```bat
cd backend
copy .env.example .env
composer install
php artisan key:generate
php artisan migrate:fresh --seed
php artisan serve --host=0.0.0.0 --port=8000
```

Pastikan pengaturan `DB_*` pada `.env` menunjuk ke database tersebut. Perintah `migrate:fresh --seed` menghapus seluruh data lalu mengisi data awal **dan data demo**.

### 2. Aplikasi Flutter

```bat
flutter pub get
flutter run -d chrome --release
```

| Target | Alamat server |
|--------|---------------|
| Chrome / desktop | `http://127.0.0.1:8000/api` (bawaan) |
| Emulator Android | `http://10.0.2.2:8000/api` (otomatis) |
| HP fisik | `--dart-define=API_BASE_URL=http://IP-LAPTOP:8000/api` |

**Mode demo tanpa server** (data tiruan di memori):

```bat
flutter run -d chrome --release --dart-define=USE_MOCK=true
```

### Akun demo (dari seeder)

| Peran | Email |
|-------|-------|
| Pelanggan | budi@mail.com |
| Admin | admin@cleandrive.com |

Kata sandi akun demo diatur pada `backend/database/seeders/UserSeeder.php` dan hanya untuk pengujian lokal. Ganti sebelum aplikasi dipasang di server publik.

## Pengujian

```bat
cd backend
php artisan test

flutter analyze
```

PHPUnit sudah terpasang, tetapi folder `backend/tests` saat ini baru berisi contoh tes bawaan Laravel. Pengujian alur utama dilakukan secara manual mengikuti skenario pada `docs/UJI-MENYELURUH.md`, dan alur presentasi ada di `docs/SKRIP-DEMO.md`.

## Dokumentasi

- `docs/DIAGRAM.md`: arsitektur, ERD, dan alur pemesanan.
- `docs/UJI-MENYELURUH.md`: daftar skenario uji pelanggan dan admin.
- `docs/SKRIP-DEMO.md`: urutan langkah untuk demo aplikasi.
- `docs/PANDUAN-ANIMASI.md`: komponen animasi dan cara memakainya.

## Catatan teknis dan batasan

- Pembayaran masih sandbox (`config('cleandrive.sandbox')`). Pembayaran sungguhan membutuhkan payment gateway (misalnya Midtrans atau Xendit) dan webhook.
- Foto produk disimpan di database (kolom MEDIUMBLOB), dikecilkan ke WebP, dan disajikan dengan ETag dan cache.
- Status antrean, notifikasi, dan pembayaran diperbarui secara berkala (polling), bukan notifikasi dorong.
- `route:cache` belum dapat dipakai karena dua rute (health dan login) memakai closure.
- Sebelum dipasang online: ganti password admin bawaan, set `APP_DEBUG=false`, gunakan HTTPS (hapus `usesCleartextTraffic`), batasi CORS, dan atur masa berlaku token.
- Belum tersedia: lupa password, verifikasi email, notifikasi dorong, tambah paket cuci dari admin, dan balasan ulasan.

---

Dikembangkan oleh **Bintang Adhi Susanto**, NIM 24051214197.
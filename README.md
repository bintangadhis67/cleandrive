# CleanDrive

Aplikasi booking dan pelacakan antrean cuci kendaraan, lengkap dengan Toko, Coins (reward), Membership, dan panel admin.
Satu repo berisi aplikasi **Flutter** (root) dan **backend Laravel + MySQL** (`backend/`).

## Fitur
**Pelanggan:** daftar/masuk, garasi kendaraan, booking cuci dan ganti oli (slot 3 per jam, estimasi selesai), voucher,
pembayaran QRIS dan e-wallet (sandbox), tiket QR dan pelacakan antrean, ulasan, Toko (makanan, minuman, oli),
Coins (check-in 7 hari, promo, tukar saat bayar), Membership Bronze sampai Platinum (diskon, cuci gratis, benefit), notifikasi.

**Admin:** dashboard, verifikasi tiket (ketik atau pindai), antrean layanan, pelanggan, pesanan, ulasan,
statistik Coins dan Membership, **pengaturan reward Coins**, **ubah tingkatan membership**, kelola produk (foto, stok) dan harga paket.

Semua perhitungan (harga, diskon, kapasitas, stok, Coins) dilakukan di server.

## Menjalankan
Prasyarat: Laragon (PHP 8.2+, MySQL), Flutter SDK, Composer.

```bat
:: 1. Backend
cd C:\cleandrive\backend
copy .env.example .env
composer install
php artisan key:generate
php artisan migrate:fresh --seed
php artisan serve --host=0.0.0.0 --port=8000

:: 2. Aplikasi (terminal lain)
cd C:\cleandrive
flutter pub get
flutter run -d chrome --release
```
Database `cleandrive` harus dibuat dulu di MySQL, dan `.env` backend menunjuk ke sana (`DB_*`).
`migrate:fresh --seed` menghapus semua data lalu mengisi data awal **dan data demo**.

| Target | Alamat server |
|--------|---------------|
| Chrome / desktop | `http://127.0.0.1:8000/api` (bawaan) |
| Emulator Android | `http://10.0.2.2:8000/api` (otomatis) |
| HP fisik | `--dart-define=API_BASE_URL=http://IP-LAPTOP:8000/api` |

**Mode demo tanpa server:** `flutter run -d chrome --release --dart-define=USE_MOCK=true`

## Akun demo
| Peran | Email | Password |
|-------|-------|----------|
| Pelanggan | budi@mail.com | 123456 |
| Admin | admin@cleandrive.com | admin123 |

## Struktur
```
lib/                 Flutter: core (state, tema), data (ApiRepository, MockRepository), models, screens (+ admin), widgets
backend/app/         Laravel: Http/Controllers/Api, Services (logika bisnis), Models, Support/Presenter
backend/config/cleandrive.php   nilai awal aturan bisnis (reward Coins ditimpa pengaturan admin di tabel settings)
backend/database/    migrations (19 tabel), seeders (data awal + DemoSeeder)
docs/                DIAGRAM.md (arsitektur, ERD, alur), UJI-MENYELURUH.md, SKRIP-DEMO.md
tools/               skrip tambalan dan tokens.cmd
```

## Catatan teknis
- Pembayaran masih **sandbox** (`config('cleandrive.sandbox')`). Pembayaran sungguhan butuh Midtrans/Xendit dan webhook.
- Foto produk disimpan di database (kolom MEDIUMBLOB), dikecilkan ke WebP, dengan ETag dan cache.
- `route:cache` belum dapat dipakai karena dua rute (health, login) memakai closure.
- Sebelum dipasang online: ganti `admin123`, `APP_DEBUG=false`, HTTPS (hapus `usesCleartextTraffic`), batasi CORS, masa berlaku token.
- Belum ada: lupa password, verifikasi email, notifikasi dorong.

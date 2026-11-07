# CleanDrive - Frontend (Flutter)

Frontend ini BERDIRI SENDIRI dan belum terhubung ke backend. Semua data memakai data tiruan di memori
(`lib/data/mock_repository.dart`), jadi aplikasi bisa dijalankan dan didemokan tanpa Laravel atau MySQL.

Desain mengikuti mockup 17 layar: splash, onboarding, login/register, beranda dengan voucher, klaim voucher,
layanan, konfirmasi pesanan, metode pembayaran (QRIS, GoPay, OVO, DANA, ShopeePay), pembayaran berhasil,
tiket dan tracking, rating dan ulasan, riwayat pesanan, ulasan saya.

## Cara memasang

1. Salin isi folder ini ke project Flutter kamu, timpa yang lama:
   - `lib/`, `assets/`, `pubspec.yaml`
   - `android/` dan `web/` (ikon aplikasi dari logo baru; salin dengan "merge/replace")
2. Hapus file lama di `lib/` yang tidak ada di paket ini (`screens.dart`).
3. Jalankan:
   ```bash
   flutter pub get
   flutter run -d chrome
   ```

## Akun demo

| Peran | Email | Password |
|---|---|---|
| Konsumen | budi@mail.com | 123456 |
| Admin | admin@cleandrive.com | admin123 |

Data yang dibuat saat aplikasi berjalan (akun baru, pesanan, voucher, ulasan) hilang saat aplikasi ditutup atau di-refresh.

## Struktur

```
lib/
 main.dart                  splash dan pengarah (onboarding, login, konsumen, admin)
 theme.dart                 palet navy, cream, merah (tema terang sesuai desain)
 models.dart                Booking, Voucher, Payment, Review, WashPackage
 app_state.dart             state aplikasi
 data/repository.dart       kontrak data (titik sambung ke backend nanti)
 data/mock_repository.dart  data tiruan
 auth.dart                  onboarding, login, register
 customer.dart              beranda, layanan, booking, konfirmasi, akun
 voucher.dart               kartu voucher, klaim voucher, voucher saya
 payment.dart               metode bayar, QRIS, e-wallet, berhasil
 orders.dart                riwayat, detail (tiket QR, tracking, PDF), ulasan
 admin.dart                 antrean, verifikasi, ringkasan, ulasan
assets/images/               gambar layanan (9), banner beranda, onboarding (4)
```

## Catatan

- Pembayaran adalah SIMULASI. Tombol "Simulasikan pembayaran" pada QRIS dipakai untuk demo.
- Gambar layanan dan banner adalah ilustrasi buatan sendiri. Untuk memakai foto asli, ganti file dengan nama
  yang sama di `assets/images/` (`svc_{express|reguler|detailing}_{motor|mobil|suv}.png`).
- Tombol masuk dengan Google/Apple dan "Lupa password" hanya tampilan sesuai desain (belum berfungsi).

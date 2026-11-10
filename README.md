CleanDrive - Frontend (Flutter)
Frontend ini BERDIRI SENDIRI dan belum terhubung ke backend. Semua data memakai data tiruan di memori
(`lib/data/mock_repository.dart`), jadi aplikasi bisa dijalankan dan didemokan tanpa Laravel atau MySQL.
Desain mengikuti mockup 17 layar: splash, onboarding, login/register, beranda dengan voucher, klaim voucher,
layanan, konfirmasi pesanan, metode pembayaran (QRIS, GoPay, OVO, DANA, ShopeePay, Livin' by Mandiri),
pembayaran berhasil, tiket dan tracking, rating dan ulasan, riwayat pesanan, ulasan saya.
Fitur tambahan (v1.2.0, sisi pelanggan)
Toko CleanDrive: daftar makanan, minuman, dan oli (`lib/catalog.dart`), keranjang, checkout, bayar, lalu ambil
di kasir dengan tiket QR. Ubah nama, harga, dan gambar produk di `catalog.dart`.
Jasa ganti oli: pada layar Booking pilih mode "Ganti Oli", pilih oli yang cocok dengan kendaraan
(atau bawa oli sendiri), jam kedatangan, lalu bayar. Harga = jasa (Rp 20.000 x faktor kendaraan) + harga oli.
Livin' by Mandiri sebagai metode pembayaran (saldo simulasi).
Notifikasi: ikon lonceng di beranda (badge belum dibaca), daftar notifikasi dengan filter, geser untuk hapus,
ketuk untuk membuka layar terkait, dan banner di dalam aplikasi untuk kejadian baru
(status cucian berubah, pengingat jadwal, naik level).
Membership & Coins (`lib/loyalty.dart`, aturan di `lib/loyalty_models.dart`):
Coins dari check-in harian (streak 7 hari: 5, 5, 10, 10, 15, 15, 30), transaksi, ulasan, dan promo.
Coins transaksi tergantung total pembayaran: terendah (< Rp 50.000) +10, menengah (Rp 50.000 - 149.999) +30,
tertinggi (>= Rp 150.000) +75.
Ulasan +10 Coins (+5 bila menulis komentar).
1 Coin = Rp 100 potongan, ditukar di layar metode pembayaran.
Level Bronze (0), Silver (300), Gold (1.000), Platinum (2.500 Coins yang pernah didapat). Semakin tinggi level:
bonus Coins 0/10/20/30%, batas tukar Coins 30/40/50/60% dari total, dan voucher reward eksklusif.
Frontend admin belum diubah pada versi ini.
Cara memasang
Salin isi folder ini ke project Flutter kamu, timpa yang lama:
`lib/`, `assets/`, `pubspec.yaml`
`android/` dan `web/` (ikon aplikasi dari logo baru; salin dengan "merge/replace")
Hapus file lama di `lib/` yang tidak ada di paket ini (`screens.dart`).
Jalankan:
```bash
   flutter pub get
   flutter run -d chrome
   ```
Struktur
```
lib/
 main.dart                  splash dan pengarah (onboarding, login, konsumen, admin)
 theme.dart                 palet navy, cream, merah (tema terang sesuai desain)
 models.dart                Booking, Voucher, Payment, Review, WashPackage, Product
 catalog.dart               daftar produk toko (makanan, minuman, oli)
 loyalty_models.dart        aturan Coins, level membership, check-in
 notification_models.dart   model notifikasi
 shop.dart                  toko dan keranjang
 loyalty.dart               membership, check-in, tukar Coins
 notifications.dart         pusat notifikasi
 app_state.dart             state aplikasi
 data/repository.dart       kontrak data (titik sambung ke backend nanti)
 data/mock_repository.dart  data tiruan
 auth.dart                  onboarding, login, register
 customer.dart              beranda, layanan, booking, konfirmasi, akun
 voucher.dart               kartu voucher, klaim voucher, voucher saya
 payment.dart               metode bayar, QRIS, e-wallet, berhasil
 orders.dart                riwayat, detail (tiket QR, tracking, PDF), ulasan
 admin.dart                 antrean, verifikasi, ringkasan, ulasan
assets/images/               gambar layanan (9), produk toko, banner beranda, onboarding (4)
```
Catatan
Pembayaran adalah SIMULASI. Tombol "Simulasikan pembayaran" pada QRIS dipakai untuk demo.
Gambar layanan dan banner adalah ilustrasi buatan sendiri. Untuk memakai foto asli, ganti file dengan nama
yang sama di `assets/images/` (`svc_{express|reguler|detailing}_{motor|mobil|suv}.png`).
Tombol masuk dengan Google/Apple dan "Lupa password" hanya tampilan sesuai desain (belum berfungsi).
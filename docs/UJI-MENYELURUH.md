# Daftar uji menyeluruh CleanDrive

Jalankan di aplikasi (bukan curl). Centang `[x]` bila lolos; bila gagal, catat di kolom Temuan.
Awali dengan `php artisan migrate:fresh --seed` agar data demo bersih. Akun: `budi@mail.com / 123456`, `admin@cleandrive.com / admin123`.

Yang **belum pernah diuji** menurut catatan proyek diberi tanda (!).

## A. Pelanggan
| # | Skenario | Hasil yang diharapkan | Lolos | Temuan |
|---|----------|-----------------------|:----:|--------|
| 1 | (!) Daftar akun baru | Masuk otomatis, ada notifikasi selamat datang | [ ] | |
| 2 | Daftar dengan email yang sudah ada / HP salah / password < 6 | Pesan kesalahan jelas, tidak membuat akun | [ ] | |
| 3 | Masuk lalu keluar, tutup dan buka lagi aplikasi | Sesi pulih saat masih masuk; kembali ke login setelah keluar | [ ] | |
| 4 | (!) Ubah profil (nama, HP) | Tersimpan, tampil di Akun | [ ] | |
| 5 | (!) Ganti password (lama salah / baru < 6 / benar) | Pesan sesuai; password baru bisa dipakai masuk | [ ] | |
| 6 | (!) Garasi: tambah, ubah, hapus, plat ganda ("L 1 A" = "L1A") | Ganda ditolak; ubah tersimpan | [ ] | |
| 7 | Booking cuci mobil dan motor | Harga sesuai paket dan kendaraan | [ ] | |
| 8 | Booking pada slot penuh (3 per jam) | Slot tampil penuh / ditolak | [ ] | |
| 9 | Klaim voucher lalu pakai saat booking | Potongan benar; kuota harian berlaku | [ ] | |
| 10 | Bayar QRIS (sandbox) | Lunas, tiket QR muncul, stok produk berkurang | [ ] | |
| 11 | Bayar e-wallet (saldo cukup dan tidak cukup) | Sukses / pesan saldo tidak cukup | [ ] | |
| 12 | (!) Tukar Coins bukan kelipatan, melebihi batas 30%, dan sah | Ditolak / ditolak / potongan benar | [ ] | |
| 13 | (!) Biarkan pembayaran lewat 10 menit | Status kedaluwarsa, tidak bisa dibayar, bisa dibuat ulang | [ ] | |
| 14 | Batalkan sebelum dan sesudah bayar | Sesuai aturan; Coins dikembalikan bila dipakai | [ ] | |
| 15 | Beri ulasan | Coins ulasan masuk; ulasan tampil di admin | [ ] | |
| 16 | Check-in harian 2x di hari yang sama; klaim promo | Check-in ganda ditolak; promo sekali klaim | [ ] | |
| 17 | Beli membership, lihat benefit | Aktif, diskon dan cuci gratis berlaku | [ ] | |
| 18 | (!) Perpanjang membership berbayar | Masa aktif bertambah, riwayat tercatat | [ ] | |
| 19 | Batalkan membership | Refund penuh tercatat | [ ] | |
| 20 | Cuci gratis (maks 1x per minggu) | Total Rp 0; kali kedua minggu itu ditolak | [ ] | |
| 21 | Toko: keranjang, stok habis, checkout | Stok dicek ulang saat bayar | [ ] | |
| 22 | Notifikasi dan pengingat jadwal | Muncul, bisa dibaca; hapus dengan menggeser kartu ke kiri (klik, tahan, seret di Chrome) | [ ] | |

## B. Admin
| # | Skenario | Hasil yang diharapkan | Lolos | Temuan |
|---|----------|-----------------------|:----:|--------|
| 1 | Verifikasi tiket (ketik kode / pindai) pada pesanan yang sudah dibayar | Lencana jadi "Tiket terverifikasi" dan pelanggan menerima notifikasi. **Status antrean tidak berubah** (itu tugas tombol naikkan status). Pesanan belum dibayar atau dibatalkan ditolak | [ ] | |
| 2 | Naikkan status sampai Selesai (verifikasi tidak wajib: menaikkan status otomatis menandai terverifikasi). Coba pada pesanan belum dibayar | Pelanggan melihat perubahan (maks ~20 detik). Pesanan belum dibayar ditolak: "Pesanan belum dibayar." | [ ] | |
| 3 | Dashboard, Pesanan, Pelanggan, Ulasan | Angka cocok dengan data | [ ] | |
| 4 | Coins dan Membership: tab statistik | Tampil tanpa error | [ ] | |
| 5 | **Baru (C2)** Pengaturan Reward: ubah nilai 1 Coin, simpan | Pelanggan melihat nilai baru setelah muat ulang katalog (<= 1 menit) | [ ] | |
| 6 | **Baru (C2)** Pengaturan Reward: isi tidak valid (batas tertinggi <= menengah) | Pesan kesalahan dari dialog / server | [ ] | |
| 7 | **Baru (C2)** Ubah tingkatan membership (harga, diskon, benefit) | Isi kolom angka DAN teks benefit dengan nilai sama. Di akun member, rincian harga pesanan berikutnya menampilkan persen baru (member lama ikut, karena diskon dibaca langsung dari tingkatan). Harga dan jatah cuci gratis hanya berlaku untuk pembelian/perpanjangan berikutnya | [ ] | |
| 8 | Katalog: tambah, ubah, hapus produk (foto, stok), ubah harga paket | Tersimpan dan tampil di pelanggan | [ ] | |

## C. Android (bila dipakai)
Emulator atau HP, izin `INTERNET` di manifest, alamat server `10.0.2.2:8000` (emulator) atau `--dart-define=API_BASE_URL=http://IP-LAPTOP:8000/api` (HP).

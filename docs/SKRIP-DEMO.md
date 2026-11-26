# Skrip demo presentasi CleanDrive

## Persiapan (10 menit sebelum mulai)
1. Laragon: **Start All** (MySQL hijau).
2. `cd C:\cleandrive\backend` lalu `php artisan migrate:fresh --seed` (data demo siap).
3. `php artisan serve --host=0.0.0.0 --port=8000` (biarkan terbuka).
4. Terminal lain: `cd C:\cleandrive` lalu `flutter run -d chrome --release`.
5. **Cadangan bila server bermasalah:** `flutter run -d chrome --release --dart-define=USE_MOCK=true`.

## Alur (sekitar 10 menit)
1. **Masuk** sebagai `budi@mail.com / 123456`. Tunjukkan Beranda, voucher, dan antrean.
2. **Garasi**: dua kendaraan yang sudah ada.
3. **Booking** cuci Reguler untuk mobil, pilih slot, pakai voucher.
4. **Bayar** QRIS (sandbox), lalu tunjukkan tiket QR. Sebutkan total dihitung server.
5. **Coins**: check-in harian, riwayat, tukar Coins pada pembayaran berikutnya.
6. **Membership**: bandingkan tingkatan, beli satu (sandbox), tunjukkan diskon dan cuci gratis.
7. **Toko**: belanja oli/minuman, tunjukkan stok berkurang.
8. **Keluar**, masuk sebagai `admin@cleandrive.com / admin123`.
9. **Admin**: Dashboard, Verifikasi Tiket (kode tiket tadi), naikkan status sampai Selesai.
10. **Admin, Coins, Pengaturan Reward**: ubah nilai reward, jelaskan berlaku untuk transaksi berikutnya.
11. **Admin, Membership, Tingkatan**: ubah satu benefit.
12. **Admin, Layanan & Produk**: ubah harga paket atau tambah produk berfoto.
13. Kembali ke pelanggan: tunjukkan perubahan ikut terlihat.

## Keterbatasan yang jujur disebutkan
- Pembayaran masih sandbox (tanpa Midtrans/Xendit).
- Belum ada lupa password, verifikasi email, notifikasi dorong.
- Paket cuci baru tidak bisa ditambah dari admin (butuh ilustrasi per kendaraan); balasan ulasan oleh admin belum ada.

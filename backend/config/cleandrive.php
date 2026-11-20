<?php

/*
|--------------------------------------------------------------------------
| Aturan bisnis CleanDrive
|--------------------------------------------------------------------------
| Nilai di sini disalin dari kode Flutter (lib/models/loyalty_models.dart, app_state.dart,
| mock_repository.dart). Server yang menghitung dan memvalidasi, jadi angka harus sama dengan Flutter.
| Baca di kode dengan config('cleandrive.coin_value'), dst.
*/

return [
    // ---- jadwal ----
    'open_hour' => 8,          // jam operasional 08.00 - 17.00 WIB
    'close_hour' => 17,
    'max_per_slot' => 3,       // maksimal booking per jam
    'queue_extra_minutes' => 10, // tiap antrean di depan menambah estimasi selesai 10 menit

    // ---- pembayaran (sandbox / simulasi) ----
    'payment_expiry_minutes' => 10,
    'sandbox' => true,
    'wallet_balances' => [     // saldo simulasi e-wallet
        'gopay' => 1500000,
        'ovo' => 2000000,
        'dana' => 1000000,
        'shopeepay' => 800000,
        'livin' => 3000000,
    ],

    // ---- Coins ----
    'coin_value' => 50,            // 1 Coin = Rp 50 potongan
    'coin_step' => 10,             // ditukar kelipatan 10 Coins
    'coin_redeem_cap_pct' => 30,   // maksimal 30% dari total
    'checkin_rewards' => [3, 3, 5, 5, 8, 8, 15], // check-in hari ke-1 s/d ke-7, lalu mengulang
    'review_coins' => 10,
    'review_comment_bonus' => 5,
    'band_mid' => 50000,           // batas tingkat Coins transaksi
    'band_high' => 150000,
    'band_coins' => ['low' => 10, 'mid' => 30, 'high' => 75],
    'shop_coin_step_rp' => 10000,  // Toko: tiap Rp 10.000 yang dibayar dapat +5 Coins
    'shop_coin_reward' => 5,

    // Promo Coins sekali klaim per akun: id => [judul, deskripsi, coins]
    'promos' => [
        'welcome' => ['Bonus Selamat Datang', 'Hadiah Coins untuk member CleanDrive.', 50],
        'profile' => ['Lengkapi Profil', 'Isi nomor HP di Edit Profil, lalu klaim bonusnya.', 25],
        'first' => ['Transaksi Pertama', 'Klaim setelah kamu menyelesaikan satu pembayaran.', 40],
    ],

    // Promo bulanan (indeks 0 = Januari): [judul, deskripsi, coins]. Bisa diklaim 1x per bulan.
    'monthly_promos' => [
        ['Bonus Tahun Baru', 'Mulai tahun dengan kendaraan bersih. Klaim Coins bulan Januari.', 30],
        ['Bonus Bulan Kasih', 'Hadiah Coins spesial bulan Februari untuk member CleanDrive.', 25],
        ['Bonus Musim Hujan', 'Hujan bikin kotor? Klaim Coins bulan Maret lalu cuci kendaraanmu.', 25],
        ['Bonus Awal Kuartal', 'Klaim Coins bulan April dan tukar saat pembayaran berikutnya.', 25],
        ['Bonus Long Weekend', 'Siapkan kendaraan untuk akhir pekan panjang. Klaim Coins bulan Mei.', 30],
        ['Bonus Liburan Sekolah', 'Klaim Coins bulan Juni sebelum berangkat liburan.', 30],
        ['Bonus Pertengahan Tahun', 'Hadiah Coins bulan Juli untuk pelanggan setia.', 25],
        ['Bonus Kemerdekaan', 'Klaim Coins merah putih bulan Agustus.', 30],
        ['Bonus Kinclong September', 'Klaim Coins bulan September dan tampil kinclong.', 25],
        ['Bonus Oktober Ceria', 'Klaim Coins bulan Oktober, tukar saat membayar.', 25],
        ['Bonus November Hemat', 'Klaim Coins bulan November untuk potongan pembayaran.', 30],
        ['Bonus Akhir Tahun', 'Tutup tahun dengan Coins bulan Desember.', 35],
    ],

    // ---- voucher ----
    'base_daily_voucher_limit' => 1,                // tanpa membership aktif
    'daily_voucher_limit' => ['gold' => 2, 'platinum' => 3], // tier lain 1x

    // ---- toko ----
    'low_stock' => 5,
];

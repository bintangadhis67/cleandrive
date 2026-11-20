<?php

namespace Database\Seeders;

use App\Models\Voucher;
use Illuminate\Database\Seeder;

class VoucherSeeder extends Seeder
{
    /**
     * Template voucher dari MockRepository._tpls.
     * Kolom: kode, judul, amount, percent, max_discount, min_transaction, valid_days, min_tier, weekly, terms
     */
    public function run(): void
    {
        $rows = [
            ['VOUCHER-20K', 'Voucher Spesial', 20000, 0, 0, 75000, 30, 0, false,
                ['Berlaku untuk semua paket', 'Tidak dapat digabung dengan promo lain', 'Hanya 1 kali per akun (klaim dan pakai)']],
            ['HEMAT10', 'Hemat 10%', 0, 10, 15000, 50000, 7, 0, true,
                ['Potongan 10% maksimal Rp 15.000', 'Berlaku untuk semua paket', 'Diperbarui tiap Senin, bisa diklaim lagi minggu depan']],
            ['WELCOME-10K', 'Selamat Datang', 10000, 0, 0, 40000, 60, 0, false,
                ['Khusus pengguna baru', 'Berlaku untuk semua paket', 'Hanya 1 kali per akun (klaim dan pakai)']],
            ['BRONZE-5K', 'Reward Bronze', 5000, 0, 0, 30000, 7, 1, true,
                ['Khusus member Bronze ke atas', 'Berlaku untuk cuci, ganti oli, dan toko', 'Diperbarui tiap Senin selama membership aktif']],
            ['SILVER-10K', 'Reward Silver', 10000, 0, 0, 60000, 7, 2, true,
                ['Khusus member Silver ke atas', 'Berlaku untuk cuci, ganti oli, dan toko', 'Diperbarui tiap Senin selama membership aktif']],
            ['GOLD-20', 'Reward Gold', 0, 20, 30000, 75000, 7, 3, true,
                ['Khusus member Gold ke atas', 'Potongan 20% maksimal Rp 30.000', 'Diperbarui tiap Senin selama membership aktif']],
            ['PLATINUM-50K', 'Reward Platinum', 50000, 0, 0, 150000, 7, 4, true,
                ['Khusus member Platinum', 'Berlaku untuk cuci, ganti oli, dan toko', 'Diperbarui tiap Senin selama membership aktif']],
        ];

        foreach ($rows as [$code, $title, $amount, $percent, $max, $min, $days, $tier, $weekly, $terms]) {
            Voucher::updateOrCreate(
                ['code' => $code],
                [
                    'title' => $title,
                    'amount' => $amount,
                    'percent' => $percent,
                    'max_discount' => $max,
                    'min_transaction' => $min,
                    'valid_days' => $days,
                    'min_tier' => $tier,
                    'weekly' => $weekly,
                    'terms' => $terms,
                ],
            );
        }
    }
}

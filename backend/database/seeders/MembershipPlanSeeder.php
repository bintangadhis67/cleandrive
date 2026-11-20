<?php

namespace Database\Seeders;

use App\Models\MembershipPlan;
use Illuminate\Database\Seeder;

class MembershipPlanSeeder extends Seeder
{
    /** Dari kMembershipPlans di lib/models/membership_models.dart. Semua paket berlaku 30 hari. */
    public function run(): void
    {
        $both = ['motor', 'mobil'];

        $plans = [
            [
                'tier' => 'bronze', 'price' => 99000, 'discount_pct' => 5,
                'priority' => 'Prioritas standar',
                'promo' => 'Voucher Bronze Rp 5.000 / minggu',
                'free_package' => 'Express', 'free_wash_quota' => 2,
                'benefits' => [
                    'Gratis 2x Express Wash (Motor & Mobil)',
                    'Diskon jasa layanan 5%',
                    'Voucher eksklusif Bronze tiap minggu',
                    'Akses promo member',
                ],
            ],
            [
                'tier' => 'silver', 'price' => 149000, 'discount_pct' => 10,
                'priority' => 'Prioritas booking',
                'promo' => 'Voucher Silver Rp 10.000 / minggu',
                'free_package' => 'Express', 'free_wash_quota' => 3,
                'benefits' => [
                    'Gratis 3x Express Wash (Motor & Mobil)',
                    'Diskon jasa layanan 10%',
                    'Prioritas booking',
                    'Voucher eksklusif Silver tiap minggu',
                ],
            ],
            [
                'tier' => 'gold', 'price' => 599000, 'discount_pct' => 20,
                'priority' => 'Prioritas tinggi',
                'promo' => 'Voucher Gold 20% (maks. Rp 30.000) / minggu',
                'popular' => true,
                'free_package' => 'Reguler', 'free_wash_quota' => 4,
                'snack' => true, 'vip' => true,
                'benefits' => [
                    'Gratis Reguler Wash 1x/minggu (Motor & Mobil)',
                    'Makanan & minuman gratis saat cuci',
                    'Ruang tunggu VIP (TV & AC)',
                    'Diskon jasa layanan 20%',
                    'Prioritas booking tinggi',
                    'Voucher eksklusif Gold tiap minggu',
                    'Klaim voucher 2x sehari',
                ],
            ],
            [
                'tier' => 'platinum', 'price' => 999000, 'discount_pct' => 30,
                'priority' => 'Prioritas utama',
                'promo' => 'Voucher Platinum Rp 50.000 / minggu',
                'free_package' => 'Detailing', 'free_wash_quota' => 4,
                'snack' => true, 'vip' => true, 'massage' => true,
                'benefits' => [
                    'Gratis Detailing Wash 1x/minggu (Motor & Mobil)',
                    'Makanan & minuman gratis saat cuci',
                    'Ruang tunggu VIP (TV & AC)',
                    'Kursi pijat saat menunggu proses pencucian',
                    'Diskon jasa layanan 30%',
                    'Prioritas booking utama',
                    'Voucher eksklusif Platinum tiap minggu',
                    'Klaim voucher 3x sehari',
                ],
            ],
        ];

        foreach ($plans as $p) {
            MembershipPlan::updateOrCreate(
                ['tier' => $p['tier']],
                [
                    'price' => $p['price'],
                    'duration_days' => 30,
                    'discount_pct' => $p['discount_pct'],
                    'priority' => $p['priority'],
                    'benefits' => $p['benefits'],
                    'promo' => $p['promo'],
                    'popular' => $p['popular'] ?? false,
                    'free_package' => $p['free_package'],
                    'free_wash_quota' => $p['free_wash_quota'],
                    'free_vehicles' => $both,
                    'snack' => $p['snack'] ?? false,
                    'vip' => $p['vip'] ?? false,
                    'massage' => $p['massage'] ?? false,
                ],
            );
        }
    }
}

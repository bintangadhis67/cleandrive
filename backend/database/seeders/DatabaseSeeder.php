<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            UserSeeder::class,
            WashPackageSeeder::class,
            ProductSeeder::class,
            ProductImageSeeder::class,
            VoucherSeeder::class,
            MembershipPlanSeeder::class,
        ]);

        // Data demo (pesanan, ulasan, Coins). Bila gagal, seeder utama tetap dianggap berhasil.
        try {
            $this->call(DemoSeeder::class);
        } catch (\Throwable $e) {
            $this->command?->warn('DemoSeeder dilewati: '.$e->getMessage());
        }
    }
}

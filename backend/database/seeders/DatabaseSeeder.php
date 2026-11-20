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
            VoucherSeeder::class,
            MembershipPlanSeeder::class,
        ]);
    }
}

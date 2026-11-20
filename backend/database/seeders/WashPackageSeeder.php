<?php

namespace Database\Seeders;

use App\Models\WashPackage;
use Illuminate\Database\Seeder;

class WashPackageSeeder extends Seeder
{
    /** Dari lib/models/models.dart (packages, oilChangePackage, shopPackage). */
    public function run(): void
    {
        $rows = [
            ['Express', 'Cuci luar + keringkan', 'wash', 25000, 20, null],
            ['Reguler', 'Cuci luar, vakum interior, semir ban', 'wash', 50000, 40, null],
            ['Detailing', 'Poles body, cuci mesin, interior deep clean', 'wash', 150000, 120, ['motor' => 100000, 'mobil' => 250000]],
            ['Ganti Oli', 'Jasa penggantian oli mesin + cek level cairan', 'oil', 20000, 30, null],
            ['Pembelian Toko', 'Pembelian langsung di Toko CleanDrive', 'shop', 0, 5, null],
        ];

        foreach ($rows as [$name, $desc, $kind, $base, $minutes, $prices]) {
            WashPackage::updateOrCreate(
                ['name' => $name],
                ['description' => $desc, 'kind' => $kind, 'base_price' => $base, 'minutes' => $minutes, 'prices' => $prices],
            );
        }
    }
}

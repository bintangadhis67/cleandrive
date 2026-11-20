<?php

namespace Database\Seeders;

use App\Models\Product;
use Illuminate\Database\Seeder;

class ProductSeeder extends Seeder
{
    /** 36 produk dari lib/models/catalog.dart, tersimpan di data/products.json. */
    public function run(): void
    {
        $path = database_path('seeders/data/products.json');
        $items = json_decode(file_get_contents($path), true, 512, JSON_THROW_ON_ERROR);

        foreach ($items as $p) {
            Product::updateOrCreate(
                ['id' => $p['id']],
                [
                    'name' => $p['name'],
                    'description' => $p['description'],
                    'details' => $p['details'],
                    'price' => $p['price'],
                    'category' => $p['category'],
                    'image' => $p['image'],
                    'stock' => $p['stock'],
                    'vehicles' => $p['vehicles'] ?: null,
                    'sort' => $p['sort'],
                ],
            );
        }
    }
}

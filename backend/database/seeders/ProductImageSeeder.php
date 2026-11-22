<?php

namespace Database\Seeders;

use App\Models\Product;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Storage;

/**
 * Memindahkan foto produk bawaan aplikasi (assets/images di folder Flutter) menjadi file di server.
 * Aman dijalankan berulang dan tanpa menghapus data:  php artisan db:seed --class=ProductImageSeeder
 */
class ProductImageSeeder extends Seeder
{
    public function run(): void
    {
        $disk = Storage::disk('public');
        $root = realpath(base_path('..')); // folder utama repo, tempat assets/ milik Flutter berada
        $moved = 0;
        $missing = 0;

        foreach (Product::where('image', 'like', 'assets/%')->get() as $p) {
            $src = $root ? $root.DIRECTORY_SEPARATOR.str_replace('/', DIRECTORY_SEPARATOR, $p->image) : null;
            if (! $src || ! is_file($src)) {
                $missing++;
                continue;
            }
            $ext = strtolower(pathinfo($src, PATHINFO_EXTENSION)) ?: 'png';
            $path = "products/{$p->id}.{$ext}";
            $disk->put($path, file_get_contents($src));
            $p->update(['image' => $path]);
            $moved++;
        }

        $this->command?->info("Foto produk dipindahkan ke server: {$moved}. File tidak ditemukan: {$missing}.");
    }
}

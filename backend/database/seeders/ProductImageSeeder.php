<?php

namespace Database\Seeders;

use App\Models\Product;
use App\Services\ProductImageService;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Storage;

/**
 * Memasukkan foto produk ke DATABASE (tabel product_images). Aman dijalankan berulang dan tanpa menghapus data:
 *   php artisan db:seed --class=ProductImageSeeder
 *
 * Sumber gambar, berurutan:
 *  1. database/seeders/images/<id>.webp : foto bawaan yang sudah dikecilkan (untuk produk bawaan)
 *  2. file hasil unggahan admin di storage (tahap sebelumnya), dipindah ke database
 *  3. assets/images milik Flutter (cadangan terakhir, dikecilkan otomatis)
 */
class ProductImageSeeder extends Seeder
{
    public function run(): void
    {
        $root = realpath(base_path('..')); // folder utama repo, tempat assets/ milik Flutter
        $disk = Storage::disk('public');
        $count = ['bawaan' => 0, 'unggahan' => 0, 'aset' => 0, 'tidak ada' => 0];

        foreach (Product::where('image', 'not like', 'db:%')->get() as $p) {
            $legacy = (string) $p->image;
            $ready = database_path("seeders/images/{$p->id}.webp");
            $isSeedName = (bool) preg_match('#^products/'.preg_quote($p->id, '#').'\.\w+$#', $legacy); // products/mk1.png
            $asset = ($root && str_starts_with($legacy, 'assets/'))
                ? $root.DIRECTORY_SEPARATOR.str_replace('/', DIRECTORY_SEPARATOR, $legacy)
                : null;

            if (is_file($ready) && ($legacy === '' || str_starts_with($legacy, 'assets/') || $isSeedName)) {
                $from = 'bawaan';
                $bytes = (string) file_get_contents($ready);
                $mime = 'image/webp';
                $optimize = false;
            } elseif (str_starts_with($legacy, 'products/') && $disk->exists($legacy)) {
                $from = 'unggahan'; // foto yang diunggah admin: tetap dipertahankan, hanya dipindah
                $bytes = (string) $disk->get($legacy);
                $mime = $disk->mimeType($legacy) ?: 'image/png';
                $optimize = true;
            } elseif ($asset && is_file($asset)) {
                $from = 'aset';
                $bytes = (string) file_get_contents($asset);
                $mime = 'image/png';
                $optimize = true;
            } else {
                $count['tidak ada']++;
                continue;
            }

            $p->update(['image' => ProductImageService::save($p->id, $bytes, $mime, $optimize)]);
            ProductImageService::deleteLegacyFile($legacy);
            $count[$from]++;
        }

        $this->command?->info(sprintf(
            'Foto produk dimasukkan ke database: %d bawaan, %d unggahan, %d dari aset. Tidak ditemukan: %d.',
            $count['bawaan'], $count['unggahan'], $count['aset'], $count['tidak ada'],
        ));
    }
}

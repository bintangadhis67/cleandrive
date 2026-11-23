<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

/**
 * Foto produk disimpan LANGSUNG DI DATABASE (tabel product_images, kolom data bertipe MEDIUMBLOB).
 * Kolom products.image hanya berisi penanda versi: "db:<hash>". Nilai lama "assets/..." berarti gambar
 * bawaan aplikasi Flutter. Gambar dilayani lewat GET /api/media/products/{id} dengan ETag dan cache.
 */
class ProductImageService
{
    private const MAX_SIDE = 640;          // sisi terpanjang setelah dikecilkan (piksel)
    private const MAX_PIXELS = 16_000_000; // gambar yang lebih besar tidak diproses (hemat memori)

    /** Simpan foto unggahan admin ke database. Hasil: nilai untuk kolom products.image. */
    public static function saveUpload(string $productId, UploadedFile $file): string
    {
        return self::save($productId, (string) file_get_contents($file->getRealPath()), $file->getMimeType() ?: 'image/png');
    }

    /** Simpan (atau ganti) gambar produk di database. Hasil: "db:<hash>". */
    public static function save(string $productId, string $bytes, string $mime, bool $optimize = true): string
    {
        if ($optimize) {
            [$bytes, $mime] = self::optimize($bytes, $mime);
        }
        $hash = md5($bytes);
        $now = now();

        DB::table('product_images')->updateOrInsert(
            ['product_id' => $productId],
            ['mime' => $mime, 'data' => $bytes, 'hash' => $hash, 'size' => strlen($bytes), 'created_at' => $now, 'updated_at' => $now],
        );

        return 'db:'.$hash;
    }

    /** Alamat yang dibaca aplikasi. Foto di database: URL lengkap + penanda versi; asset bawaan: apa adanya. */
    public static function url(string $productId, ?string $image): string
    {
        $image = (string) $image;
        if (str_starts_with($image, 'db:')) {
            return url('/api/media/products/'.$productId).'?v='.substr($image, 3, 8);
        }

        // "products/..." = file lama tahap sebelumnya yang belum dipindah ke database (jalankan ProductImageSeeder).
        return str_starts_with($image, 'products/') ? '' : $image;
    }

    /** Hapus file foto versi lama (sebelum gambar dipindah ke database), bila masih ada. */
    public static function deleteLegacyFile(?string $image): void
    {
        if ($image && str_starts_with($image, 'products/')) {
            Storage::disk('public')->delete($image);
        }
    }

    /**
     * Kecilkan dan ubah ke WebP supaya database dan jaringan tidak terbebani (foto 2 MB menjadi puluhan KB).
     * Tanpa ekstensi GD, atau bila hasilnya tidak lebih kecil, gambar asli dipakai apa adanya.
     */
    private static function optimize(string $bytes, string $mime): array
    {
        if (! function_exists('imagecreatefromstring') || ! function_exists('imagewebp')) {
            return [$bytes, $mime];
        }
        $info = @getimagesizefromstring($bytes);
        if (! $info || $info[0] * $info[1] > self::MAX_PIXELS) {
            return [$bytes, $mime];
        }

        try {
            $src = @imagecreatefromstring($bytes);
            if (! $src) {
                return [$bytes, $mime];
            }
            if (function_exists('imagepalettetotruecolor')) {
                imagepalettetotruecolor($src);
            }
            $w = imagesx($src);
            $h = imagesy($src);

            if (max($w, $h) > self::MAX_SIDE) {
                $scale = self::MAX_SIDE / max($w, $h);
                $dst = imagecreatetruecolor(max(1, (int) round($w * $scale)), max(1, (int) round($h * $scale)));
                imagealphablending($dst, false);
                imagesavealpha($dst, true);
                imagefill($dst, 0, 0, imagecolorallocatealpha($dst, 0, 0, 0, 127)); // latar transparan
                imagecopyresampled($dst, $src, 0, 0, 0, 0, imagesx($dst), imagesy($dst), $w, $h);
                $src = $dst;
            }
            imagealphablending($src, false);
            imagesavealpha($src, true);

            ob_start();
            $ok = imagewebp($src, null, 84);
            $out = (string) ob_get_clean();

            if ($ok && $out !== '' && strlen($out) < strlen($bytes)) {
                return [$out, 'image/webp'];
            }
        } catch (\Throwable) {
            // pakai gambar asli
        }

        return [$bytes, $mime];
    }
}

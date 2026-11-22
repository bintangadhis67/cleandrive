<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

/**
 * Foto produk disimpan sebagai file di storage/app/public/products, dan database hanya menyimpan
 * jalur filenya ("products/mk1.png"). Nilai lama berawalan "assets/" berarti gambar bawaan aplikasi Flutter.
 * File dilayani lewat /api/media/... (bukan /storage) supaya ikut aturan CORS API dan terbaca di Chrome.
 */
class ProductImageService
{
    public static function store(UploadedFile $file, string $productId): string
    {
        $ext = strtolower($file->guessExtension() ?: 'png');
        if ($ext === 'jpeg') {
            $ext = 'jpg';
        }
        // Nama acak supaya alamat berubah saat foto diganti (cache browser tidak menampilkan foto lama).
        $name = $productId.'-'.Str::lower(Str::random(8)).'.'.$ext;
        Storage::disk('public')->putFileAs('products', $file, $name);

        return 'products/'.$name;
    }

    /** Hapus file foto di server. Gambar bawaan aplikasi ("assets/...") tidak disentuh. */
    public static function delete(?string $image): void
    {
        if ($image && str_starts_with($image, 'products/')) {
            Storage::disk('public')->delete($image);
        }
    }

    /** Alamat yang dibaca aplikasi: URL lengkap untuk foto di server, atau jalur asset bawaan apa adanya. */
    public static function url(?string $image): string
    {
        $image = (string) $image;

        return str_starts_with($image, 'products/') ? url('/api/media/'.$image) : $image;
    }
}

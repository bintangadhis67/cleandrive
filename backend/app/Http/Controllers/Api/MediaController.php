<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\ApiException;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

/** Menayangkan foto produk. Terbuka untuk umum karena widget gambar tidak mengirim token login. */
class MediaController extends ApiController
{
    public function show(string $path): BinaryFileResponse
    {
        $disk = Storage::disk('public');
        if (! $disk->exists($path)) {
            throw new ApiException('Gambar tidak ditemukan.', 404);
        }

        return response()->file($disk->path($path), ['Cache-Control' => 'public, max-age=604800']);
    }
}

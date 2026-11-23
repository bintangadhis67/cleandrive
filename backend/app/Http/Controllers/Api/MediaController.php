<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\ApiException;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;

/** Menayangkan foto produk dari database. Terbuka untuk umum karena widget gambar tidak mengirim token login. */
class MediaController extends ApiController
{
    public function product(Request $request, string $id): Response
    {
        // Metadata dibaca dulu tanpa isi gambar, supaya permintaan ulang cukup dijawab 304 tanpa membaca BLOB.
        $meta = DB::table('product_images')->select('hash', 'mime')->where('product_id', $id)->first();
        if (! $meta) {
            throw new ApiException('Gambar tidak ditemukan.', 404);
        }

        $etag = '"'.$meta->hash.'"';
        // Alamat gambar memuat penanda versi (?v=...), jadi aman di-cache lama; foto baru = alamat baru.
        $headers = ['Content-Type' => $meta->mime, 'ETag' => $etag, 'Cache-Control' => 'public, max-age=31536000, immutable'];

        if ($request->header('If-None-Match') === $etag) {
            return response('', 304, $headers);
        }

        $data = DB::table('product_images')->where('product_id', $id)->value('data');

        return response($data, 200, $headers);
    }
}

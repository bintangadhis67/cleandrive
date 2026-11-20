<?php

namespace App\Http\Controllers\Api;

use App\Models\Product;
use App\Models\Review;
use App\Support\Presenter;
use Illuminate\Http\JsonResponse;

class CatalogController extends ApiController
{
    /** Daftar produk toko (untuk admin katalog dan sinkronisasi harga). */
    public function products(): JsonResponse
    {
        $items = Product::where('is_active', true)->orderBy('sort')->get();

        return response()->json($items->map(fn (Product $p) => Presenter::product($p))->values());
    }

    /** Repository.stocks(): {"mk1": 3, "mn1": 25, ...} */
    public function stocks(): JsonResponse
    {
        $stocks = Product::where('is_active', true)->pluck('stock', 'id')->map(fn ($v) => (int) $v);

        return response()->json($stocks);
    }

    /** Repository.ratingSummary(): {"avg": 4.5, "count": 12} */
    public function ratingSummary(): JsonResponse
    {
        return response()->json([
            'avg' => round((float) Review::avg('rating'), 2),
            'count' => Review::count(),
        ]);
    }
}

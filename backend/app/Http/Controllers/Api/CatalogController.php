<?php

namespace App\Http\Controllers\Api;

use App\Models\Product;
use App\Models\Review;
use App\Support\Presenter;
use Illuminate\Http\JsonResponse;

class CatalogController extends ApiController
{
    /**
     * Semua produk, termasuk yang sudah dinonaktifkan admin (flag "active"), supaya pesanan lama
     * yang memuat produk itu tetap terbaca di aplikasi. Toko hanya menampilkan yang aktif.
     */
    public function products(): JsonResponse
    {
        return response()->json($this->allProducts());
    }

    /** Katalog untuk aplikasi: {"products": [...]}. */
    public function catalog(): JsonResponse
    {
        return response()->json(['products' => $this->allProducts()]);
    }

    /** Repository.stocks(): {"mk1": 3, "mn1": 25, ...} (hanya produk aktif) */
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

    private function allProducts()
    {
        return Product::orderBy('sort')->get()->map(fn (Product $p) => Presenter::product($p))->values();
    }
}

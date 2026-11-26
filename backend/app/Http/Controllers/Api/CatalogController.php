<?php

namespace App\Http\Controllers\Api;

use App\Models\MembershipPlan;
use App\Models\Product;
use App\Models\Review;
use App\Models\WashPackage;
use App\Services\RewardSettings;
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

    /** Katalog untuk aplikasi: produk, paket, pengaturan reward Coins, dan paket membership. */
    public function catalog(): JsonResponse
    {
        return response()->json([
            'products' => $this->allProducts(),
            'packages' => $this->allPackages(),
            'rewards' => RewardSettings::current(),
            'plans' => $this->allPlans(),
        ]);
    }

    /** Pengaturan reward Coins yang berlaku sekarang (nilai awal dari config, ditimpa pengaturan admin). */
    public function rewards(): JsonResponse
    {
        return response()->json(RewardSettings::current());
    }

    /** Paket membership (Bronze sampai Platinum) dengan harga, diskon, kuota cuci gratis, dan benefit terbaru. */
    public function plans(): JsonResponse
    {
        return response()->json($this->allPlans());
    }

    /** Paket layanan (Express, Reguler, Detailing, Ganti Oli) dengan harga efektif motor dan mobil. */
    public function packages(): JsonResponse
    {
        return response()->json($this->allPackages());
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

    private function allPlans()
    {
        return MembershipPlan::where('is_active', true)->orderBy('id')->get()
            ->map(fn (MembershipPlan $m) => Presenter::plan($m))->values();
    }

    private function allPackages()
    {
        return WashPackage::where('is_active', true)->where('kind', '!=', 'shop')->orderBy('id')->get()
            ->map(fn (WashPackage $p) => Presenter::package($p))->values();
    }

    private function allProducts()
    {
        return Product::orderBy('sort')->get()->map(fn (Product $p) => Presenter::product($p))->values();
    }
}

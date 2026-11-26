<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\ApiException;
use App\Models\MembershipPlan;
use App\Models\WashPackage;
use App\Services\RewardSettings;
use App\Support\Presenter;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/** Admin: pengaturan reward Coins dan benefit tiap tingkatan membership. */
class AdminSettingsController extends ApiController
{
    /** PUT admin/rewards: simpan nilai reward. Berlaku untuk transaksi berikutnya. */
    public function saveRewards(Request $request): JsonResponse
    {
        return response()->json(RewardSettings::save($request->all()));
    }

    /**
     * PUT admin/plans/{tier}: ubah harga, diskon, kuota cuci gratis, dan benefit satu tingkatan.
     * Membership yang sudah aktif tidak berubah; nilai baru berlaku untuk pembelian dan perpanjangan berikutnya.
     */
    public function savePlan(Request $request, string $tier): JsonResponse
    {
        $plan = MembershipPlan::where('tier', $tier)->first() ?? throw new ApiException('Tingkat membership tidak ditemukan.', 404);

        $price = $request->input('price');
        $discount = $request->input('discount_pct');
        $quota = $request->input('free_wash_quota');
        $priority = trim((string) $request->input('priority'));
        $promo = trim((string) $request->input('promo', ''));
        $freePackage = trim((string) $request->input('free_package', ''));

        if (! is_numeric($price) || (int) $price < 1000 || (int) $price > 100000000) {
            throw new ApiException('Harga membership harus berupa angka minimal Rp 1.000.');
        }
        if (! is_numeric($discount) || (int) $discount < 0 || (int) $discount > 100) {
            throw new ApiException('Diskon harus berupa angka 0 sampai 100.');
        }
        if ($priority === '' || mb_strlen($priority) > 60) {
            throw new ApiException('Prioritas booking wajib diisi (maksimal 60 karakter).');
        }
        if (mb_strlen($promo) > 120) {
            throw new ApiException('Promo maksimal 120 karakter.');
        }

        $benefits = $request->input('benefits', []);
        $benefits = is_array($benefits) ? $benefits : explode("\n", (string) $benefits);
        $benefits = array_values(array_filter(array_map(fn ($b) => trim((string) $b), $benefits), fn ($b) => $b !== ''));
        if (count($benefits) < 1 || count($benefits) > 12) {
            throw new ApiException('Benefit minimal 1 baris dan maksimal 12 baris.');
        }
        foreach ($benefits as $b) {
            if (mb_strlen($b) > 120) {
                throw new ApiException('Setiap baris benefit maksimal 120 karakter.');
            }
        }

        $washNames = WashPackage::where('kind', 'wash')->pluck('name')->all();
        if ($freePackage !== '' && ! in_array($freePackage, $washNames, true)) {
            throw new ApiException('Paket cuci gratis tidak valid.');
        }
        if (! is_numeric($quota) || (int) $quota < 0 || (int) $quota > 100) {
            throw new ApiException('Jatah cuci gratis harus berupa angka 0 sampai 100.');
        }
        $quota = $freePackage === '' ? 0 : (int) $quota; // tanpa paket gratis, jatahnya otomatis 0

        $raw = $request->input('free_vehicles', []);
        $list = is_array($raw) ? $raw : explode(',', (string) $raw);
        $vehicles = array_values(array_unique(array_filter(array_map(fn ($v) => strtolower(trim((string) $v)), $list))));
        if (array_diff($vehicles, ['motor', 'mobil'])) {
            throw new ApiException('Jenis kendaraan tidak valid.');
        }
        if ($freePackage !== '' && ! $vehicles) {
            throw new ApiException('Pilih minimal satu jenis kendaraan untuk cuci gratis.');
        }

        $flag = fn (string $k) => filter_var($request->input($k, false), FILTER_VALIDATE_BOOLEAN);

        $plan->update([
            'price' => (int) $price,
            'discount_pct' => (int) $discount,
            'priority' => $priority,
            'promo' => $promo,
            'benefits' => $benefits,
            'free_package' => $freePackage,
            'free_wash_quota' => $quota,
            'free_vehicles' => $vehicles,
            'snack' => $flag('snack'),
            'vip' => $flag('vip'),
            'massage' => $flag('massage'),
        ]);

        return response()->json(Presenter::plan($plan->fresh()));
    }
}

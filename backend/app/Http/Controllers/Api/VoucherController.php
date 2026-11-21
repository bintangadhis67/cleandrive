<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\ApiException;
use App\Models\Voucher;
use App\Services\MembershipService;
use App\Services\VoucherService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class VoucherController extends ApiController
{
    /** Semua voucher beserta status milik pengguna: diklaim, dipakai, terkunci, dan alasan tidak bisa diklaim. */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $quota = VoucherService::quota($user);
        $rank = MembershipService::rank($user);

        $list = Voucher::where('is_active', true)->orderBy('id')->get()
            ->map(fn (Voucher $v) => VoucherService::present($user, $v, $quota, $rank));

        return response()->json($list->values());
    }

    /** {"used": 0, "limit": 1} */
    public function quota(Request $request): JsonResponse
    {
        return response()->json(VoucherService::quota($request->user()));
    }

    public function claim(Request $request, string $id): JsonResponse
    {
        $user = $request->user();
        $v = Voucher::where('is_active', true)->find($id);
        if (! $v) {
            throw new ApiException('Voucher tidak ditemukan.', 404);
        }

        VoucherService::claimVoucher($user, $v);

        return response()->json(
            VoucherService::present($user, $v, VoucherService::quota($user), MembershipService::rank($user))
        );
    }
}

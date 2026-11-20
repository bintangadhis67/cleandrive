<?php

namespace App\Services;

use App\Models\User;
use App\Models\Voucher;
use App\Models\VoucherClaim;
use Carbon\Carbon;
use Carbon\CarbonInterface;

class VoucherService
{
    /** Voucher mingguan: kunci minggu (Senin); voucher sekali-per-akun: string kosong. */
    public static function claimKey(Voucher $v, ?CarbonInterface $at = null): string
    {
        return $v->weekly ? MembershipService::weekKey($at ?? now()) : '';
    }

    /** Klaim milik pengguna untuk periode berjalan (minggu ini bila mingguan), atau null bila belum diklaim. */
    public static function claim(User|int $user, Voucher $v, bool $lock = false): ?VoucherClaim
    {
        $id = $user instanceof User ? $user->id : $user;
        $q = VoucherClaim::where('user_id', $id)->where('voucher_id', $v->id)->where('week_key', self::claimKey($v));
        if ($lock) {
            $q->lockForUpdate();
        }

        return $q->first();
    }

    /**
     * Batas berlaku. Mingguan: Minggu 23.59 (yang belum dipakai hangus, bisa diklaim lagi mulai Senin).
     * Sekali-per-akun: tanggal klaim + valid_days (atau sekarang + valid_days bila belum diklaim).
     */
    public static function validUntil(Voucher $v, ?VoucherClaim $claim): Carbon
    {
        if ($v->weekly) {
            return now()->endOfWeek();
        }

        return ($claim?->created_at ?? now())->copy()->addDays($v->valid_days);
    }
}

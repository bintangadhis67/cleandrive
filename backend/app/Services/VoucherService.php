<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\User;
use App\Models\Voucher;
use App\Models\VoucherClaim;
use App\Support\Presenter;
use Carbon\Carbon;
use Carbon\CarbonInterface;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Support\Facades\DB;

class VoucherService
{
    private const TIER_NAMES = ['', 'Bronze', 'Silver', 'Gold', 'Platinum'];

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

    // ---------------------------------------------------------------- kuota klaim harian

    /** Batas klaim per hari: 1x, Gold 2x, Platinum 3x (hanya bila membership aktif). */
    public static function limitFor(User $u): int
    {
        $base = (int) config('cleandrive.base_daily_voucher_limit');
        $m = MembershipService::active($u);

        return $m ? (int) (config('cleandrive.daily_voucher_limit')[$m->tier] ?? $base) : $base;
    }

    /** {used, limit}: used = jumlah klaim hari ini. */
    public static function quota(User $u): array
    {
        $used = VoucherClaim::where('user_id', $u->id)->whereDate('created_at', now()->toDateString())->count();

        return ['used' => $used, 'limit' => self::limitFor($u)];
    }

    public static function quotaMessage(array $q): string
    {
        return "Batas klaim voucher hari ini sudah tercapai ({$q['used']}/{$q['limit']}). "
            .($q['limit'] === 1 ? 'Coba lagi besok. Member Gold bisa klaim 2x sehari, Platinum 3x sehari.' : 'Coba lagi besok.');
    }

    // ---------------------------------------------------------------- klaim

    /** Klaim voucher, urutan pengecekan sama dengan MockRepository.claimVoucher. */
    public static function claimVoucher(User $user, Voucher $v): void
    {
        if (MembershipService::rank($user) < $v->min_tier) {
            $tier = self::TIER_NAMES[$v->min_tier] ?? '';
            throw new ApiException("Voucher ini khusus member {$tier}. Beli membership untuk membukanya.");
        }

        $already = $v->weekly
            ? 'Voucher ini sudah kamu klaim minggu ini. Bisa diklaim lagi mulai Senin depan.'
            : 'Voucher ini hanya bisa diklaim 1 kali per akun.';

        try {
            DB::transaction(function () use ($user, $v, $already) {
                User::lockForUpdate()->find($user->id); // klaim satu pengguna diproses berurutan

                if (self::claim($user, $v)) {
                    throw new ApiException($already);
                }
                $q = self::quota($user);
                if ($q['used'] >= $q['limit']) {
                    throw new ApiException(self::quotaMessage($q));
                }

                VoucherClaim::create(['user_id' => $user->id, 'voucher_id' => $v->id, 'week_key' => self::claimKey($v)]);
                NotifyService::send($user->id, 'voucher', 'Voucher berhasil diklaim', "{$v->code} siap dipakai di pembayaran berikutnya.", 'vouchers', false);
            });
        } catch (UniqueConstraintViolationException) {
            throw new ApiException($already);
        }
    }

    /** Dibaca Voucher.fromJson di Flutter, lengkap dengan status milik pengguna ini. */
    public static function present(User $u, Voucher $v, array $quota, int $rank): array
    {
        $claim = self::claim($u, $v);
        $claimed = $claim !== null;

        return [
            'id' => $v->id,
            'code' => $v->code,
            'title' => $v->title,
            'amount' => (int) $v->amount,
            'percent' => (int) $v->percent,
            'max_discount' => (int) $v->max_discount,
            'min_transaction' => (int) $v->min_transaction,
            'valid_until' => Presenter::dt(self::validUntil($v, $claim)),
            'terms' => $v->terms ?? [],
            'min_tier' => (int) $v->min_tier,
            'locked' => $rank < $v->min_tier,
            'weekly' => (bool) $v->weekly,
            'block_reason' => (! $claimed && $quota['used'] >= $quota['limit']) ? self::quotaMessage($quota) : null,
            'claimed' => $claimed,
            'used' => (bool) ($claim?->used ?? false),
        ];
    }
}

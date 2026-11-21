<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\Booking;
use App\Models\CoinEntry;
use App\Models\CoinPromoClaim;
use App\Models\User;
use App\Support\Presenter;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Support\Facades\DB;

/** CleanDrive Coins: ringkasan, check-in harian, dan klaim promo. Sama dengan loyalty/checkIn/claimPromo di mock Flutter. */
class LoyaltyService
{
    /** Dibaca LoyaltyInfo di Flutter. */
    public function info(User $user): array
    {
        $entries = CoinEntry::where('user_id', $user->id)->orderByDesc('created_at')->orderByDesc('id')->limit(100)->get();

        return [
            'balance' => CoinService::balance($user),
            'lifetime' => $this->lifetime($user),
            'streak' => (int) $user->streak,
            'last_check_in' => Presenter::dt($user->last_check_in),
            'entries' => $entries->map(fn (CoinEntry $e) => Presenter::coinEntry($e))->values()->all(),
            'promos' => $this->promos($user),
        ];
    }

    /** Check-in harian: Coins sesuai hari ke-N dalam siklus 7 hari, streak putus bila kemarin terlewat. */
    public function checkIn(User $user): array
    {
        return DB::transaction(function () use ($user) {
            $u = User::lockForUpdate()->find($user->id);
            $last = $u->last_check_in;

            if ($last && $last->isToday()) {
                throw new ApiException('Kamu sudah check-in hari ini. Kembali lagi besok!');
            }

            $streak = ($last && $last->isYesterday()) ? $u->streak + 1 : 1;
            $rewards = config('cleandrive.checkin_rewards');
            $dayNo = ($streak - 1) % count($rewards);
            $coins = (int) $rewards[$dayNo];
            $day = $dayNo + 1;

            $u->update(['last_check_in' => now(), 'streak' => $streak]);
            CoinService::add($u, 'checkin', 'Check-in harian', $coins, "Hari ke-{$day}");
            NotifyService::send($u->id, 'points', 'Check-in berhasil', "+{$coins} Coins. Streak {$streak} hari, jangan putus ya!", 'loyalty', false);

            return ['coins' => $coins, 'streak' => $streak, 'title' => "Check-in hari ke-{$day}"];
        });
    }

    /** Klaim promo Coins: welcome, profile, first (sekali per akun) atau promo bulanan (sekali per bulan). */
    public function claimPromo(User $user, string $id): array
    {
        $now = now();
        $promos = config('cleandrive.promos');

        if ($id === $this->monthlyId($now)) {
            [$title, , $coins] = config('cleandrive.monthly_promos')[$now->month - 1];
        } elseif (isset($promos[$id])) {
            [$title, , $coins] = $promos[$id];
        } else {
            throw new ApiException('Promo tidak ditemukan atau sudah berakhir.', 404);
        }

        try {
            return DB::transaction(function () use ($user, $id, $title, $coins) {
                User::lockForUpdate()->find($user->id);

                if (CoinPromoClaim::where('user_id', $user->id)->where('promo_id', $id)->exists()) {
                    throw new ApiException('Promo ini sudah kamu klaim.');
                }
                if ($lock = $this->promoLock($user, $id)) {
                    throw new ApiException($lock);
                }

                CoinPromoClaim::create(['user_id' => $user->id, 'promo_id' => $id, 'coins' => $coins]);
                CoinService::add($user, 'promo', $title, (int) $coins);
                NotifyService::send($user->id, 'points', 'Promo Coins diklaim', "+{$coins} Coins dari {$title}.", 'loyalty', false);

                return ['coins' => (int) $coins, 'streak' => (int) $user->streak, 'title' => $title];
            });
        } catch (UniqueConstraintViolationException) {
            throw new ApiException('Promo ini sudah kamu klaim.');
        }
    }

    // ---------------------------------------------------------------- helper

    /**
     * Total Coins yang pernah diperoleh: check-in, transaksi, ulasan, dan promo, dikurangi Coins
     * yang ditarik kembali karena pesanan dibatalkan. Penukaran (redeem) tidak mengurangi.
     */
    private function lifetime(User $user): int
    {
        $earned = (int) CoinEntry::where('user_id', $user->id)->whereIn('kind', ['checkin', 'transaction', 'review', 'promo'])->sum('amount');
        $clawed = (int) CoinEntry::where('user_id', $user->id)->where('kind', 'refund')->where('amount', '<', 0)->sum('amount');

        return max(0, $earned + $clawed);
    }

    private function monthlyId($d): string
    {
        return 'monthly-'.$d->format('Y-m');
    }

    /** Promo bulan ini dulu, lalu promo sekali klaim. */
    private function promos(User $user): array
    {
        $claimed = CoinPromoClaim::where('user_id', $user->id)->pluck('promo_id')->all();
        $now = now();
        $mid = $this->monthlyId($now);
        [$mTitle, $mDesc, $mCoins] = config('cleandrive.monthly_promos')[$now->month - 1];

        $out = [[
            'id' => $mid,
            'title' => $mTitle,
            'desc' => $mDesc,
            'coins' => $mCoins,
            'claimed' => in_array($mid, $claimed, true),
            'monthly' => true,
            'ends_at' => Presenter::dt($now->copy()->endOfMonth()),
            'locked_reason' => null,
        ]];

        foreach (config('cleandrive.promos') as $id => [$title, $desc, $coins]) {
            $done = in_array($id, $claimed, true);
            $out[] = [
                'id' => $id,
                'title' => $title,
                'desc' => $desc,
                'coins' => $coins,
                'claimed' => $done,
                'monthly' => false,
                'ends_at' => null,
                'locked_reason' => $done ? null : $this->promoLock($user, $id),
            ];
        }

        return $out;
    }

    /** Alasan promo belum bisa diklaim (null = boleh). */
    private function promoLock(User $user, string $id): ?string
    {
        return match ($id) {
            'profile' => trim((string) $user->phone) === '' ? 'Isi No. HP di Edit Profil dulu' : null,
            'first' => $this->hasPaid($user) ? null : 'Selesaikan satu pembayaran dulu',
            default => null,
        };
    }

    private function hasPaid(User $user): bool
    {
        return Booking::where('user_id', $user->id)->where('pay_status', 'paid')->get()
            ->contains(fn (Booking $b) => $b->total() > 0);
    }
}

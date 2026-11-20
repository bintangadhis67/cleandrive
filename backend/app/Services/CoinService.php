<?php

namespace App\Services;

use App\Models\CoinEntry;
use App\Models\User;

class CoinService
{
    /** Catat perubahan Coins. amount positif = dapat, negatif = dipakai/ditarik. */
    public static function add(User|int $user, string $kind, string $title, int $amount, string $note = '', ?int $bookingId = null): CoinEntry
    {
        return CoinEntry::create([
            'user_id' => $user instanceof User ? $user->id : $user,
            'kind' => $kind,
            'title' => $title,
            'note' => $note,
            'amount' => $amount,
            'booking_id' => $bookingId,
        ]);
    }

    /** Saldo = jumlah seluruh catatan Coins. */
    public static function balance(User|int $user): int
    {
        $id = $user instanceof User ? $user->id : $user;

        return (int) CoinEntry::where('user_id', $id)->sum('amount');
    }

    /** Coins maksimal yang boleh ditukar pada satu pembayaran (kelipatan coin_step). Sama dengan maxRedeemCoins di Flutter. */
    public static function maxRedeem(int $total, int $balance): int
    {
        $byCap = intdiv(intdiv($total * (int) config('cleandrive.coin_redeem_cap_pct'), 100), (int) config('cleandrive.coin_value'));
        $c = max(0, min($balance, $byCap));
        $step = (int) config('cleandrive.coin_step');

        return intdiv($c, $step) * $step;
    }

    /** Tingkat pembayaran: [label, coins]. */
    public static function band(int $paid): array
    {
        $coins = config('cleandrive.band_coins');
        if ($paid >= (int) config('cleandrive.band_high')) {
            return ['Tertinggi', $coins['high']];
        }
        if ($paid >= (int) config('cleandrive.band_mid')) {
            return ['Menengah', $coins['mid']];
        }

        return ['Terendah', $coins['low']];
    }

    /** Coins dari satu pembayaran: toko = +5 tiap Rp 10.000; cuci/oli = sesuai tingkat; Rp 0 = tanpa Coins. */
    public static function forPayment(bool $shop, int $paid): int
    {
        if ($paid <= 0) {
            return 0;
        }
        if ($shop) {
            return intdiv($paid, (int) config('cleandrive.shop_coin_step_rp')) * (int) config('cleandrive.shop_coin_reward');
        }

        return self::band($paid)[1];
    }
}

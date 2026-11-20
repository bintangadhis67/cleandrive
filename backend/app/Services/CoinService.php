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

    public static function balance(User|int $user): int
    {
        $id = $user instanceof User ? $user->id : $user;

        return (int) CoinEntry::where('user_id', $id)->sum('amount');
    }
}

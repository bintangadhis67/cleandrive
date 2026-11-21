<?php

namespace App\Services;

use App\Models\Booking;
use App\Models\User;
use App\Models\WashPackage;
use App\Support\PackText;

class ReminderService
{
    /**
     * Pengingat otomatis: pesanan berbayar (bukan toko) yang jadwalnya kurang dari 1 jam lagi.
     * Dibuat saat pengguna membuka daftar notifikasi (sama dengan _genReminders di Flutter), sekali per pesanan.
     */
    public static function generate(User $user): void
    {
        if ($user->isAdmin()) {
            return;
        }

        $now = now();
        $shop = WashPackage::where('kind', 'shop')->pluck('name')->all();
        $kinds = PackText::kinds();

        $due = Booking::where('user_id', $user->id)
            ->where('cancelled', false)
            ->where('status', '<', 3)
            ->where('pay_status', 'paid')
            ->whereNotIn('package', $shop)
            ->whereNull('reminded_at')
            ->whereBetween('slot', [$now, $now->copy()->addMinutes(60)])
            ->get();

        foreach ($due as $b) {
            $b->update(['reminded_at' => $now]);
            NotifyService::send(
                $user->id,
                'reminder',
                'Jadwalmu sebentar lagi',
                PackText::title($b->package, $kinds[$b->package] ?? 'wash')." • {$b->plate} pukul ".$b->slot->format('H:i').'. Tunjukkan tiket QR ke petugas saat tiba.',
                'order:'.$b->id,
            );
        }
    }
}

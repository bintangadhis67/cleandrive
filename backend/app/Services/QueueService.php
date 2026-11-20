<?php

namespace App\Services;

use App\Models\Booking;
use App\Models\WashPackage;

class QueueService
{
    /**
     * Posisi antrean semua pesanan aktif (belum dibatalkan, belum selesai, bukan pembelian toko):
     * urut jadwal, lalu urutan pesanan. Hasil: [booking_id => posisi], posisi 1 = paling depan.
     * Sama dengan MockRepository._decorate di Flutter.
     */
    public static function positions(): array
    {
        $shop = WashPackage::where('kind', 'shop')->pluck('name')->all();

        $ids = Booking::where('cancelled', false)
            ->where('status', '<', 3)
            ->whereNotIn('package', $shop)
            ->orderBy('slot')
            ->orderBy('id')
            ->pluck('id');

        $pos = [];
        $i = 0;
        foreach ($ids as $id) {
            $pos[$id] = ++$i;
        }

        return $pos;
    }
}

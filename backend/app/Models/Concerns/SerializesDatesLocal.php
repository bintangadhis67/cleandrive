<?php

namespace App\Models\Concerns;

use Carbon\Carbon;
use DateTimeInterface;

/**
 * Tanggal di JSON dikirim sebagai waktu lokal tanpa "Z", mis. 2026-11-20T08:00:00.
 * Tanpa ini Laravel mengirim UTC (…Z) dan Flutter menampilkan jam slot bergeser 7 jam.
 * Dibaca Flutter lewat DateTime.parse (tanpa zona waktu = waktu lokal perangkat, WIB).
 */
trait SerializesDatesLocal
{
    protected function serializeDate(DateTimeInterface $date): string
    {
        return Carbon::instance($date)
            ->setTimezone(config('app.timezone'))
            ->format('Y-m-d\TH:i:s');
    }
}

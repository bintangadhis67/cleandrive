<?php

namespace App\Support;

use App\Models\WashPackage;

/** Teks status per jenis layanan (wash | oil | shop), sama dengan WashPackage.statusNames / headlines di Flutter. */
class PackText
{
    public static function statusNames(string $kind): array
    {
        return match ($kind) {
            'oil' => ['Menunggu', 'Ganti Oli', 'Finishing', 'Selesai'],
            'shop' => ['Belum Dibayar', 'Dibeli', 'Dibeli', 'Dibeli'],
            default => ['Menunggu', 'Dicuci', 'Finishing', 'Selesai'],
        };
    }

    public static function headlines(string $kind): array
    {
        return match ($kind) {
            'oil' => ['Kendaraanmu menunggu giliran', 'Oli kendaraanmu sedang diganti!', 'Hampir selesai, tahap finishing!', 'Ganti oli selesai, siap diambil!'],
            'shop' => ['Menunggu pembayaran', 'Pembelian berhasil!', 'Pembelian berhasil!', 'Pembelian berhasil, terima kasih!'],
            default => ['Kendaraanmu menunggu giliran', 'Kendaraanmu sedang dicuci!', 'Hampir selesai, tahap finishing!', 'Cucian selesai, siap diambil!'],
        };
    }

    /** "Express Wash" untuk cuci, nama apa adanya untuk layanan lain. */
    public static function title(string $name, string $kind): string
    {
        return $kind === 'wash' ? "{$name} Wash" : $name;
    }

    /** Nama paket -> jenis, mis. ['Express' => 'wash', 'Pembelian Toko' => 'shop']. */
    public static function kinds(): array
    {
        return WashPackage::pluck('kind', 'name')->all();
    }
}

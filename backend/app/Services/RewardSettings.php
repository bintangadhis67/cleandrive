<?php

namespace App\Services;

use App\Exceptions\ApiException;
use Illuminate\Support\Facades\DB;

/**
 * Nilai reward Coins yang bisa diatur admin. Nilai awal ada di config/cleandrive.php; pengaturan admin
 * disimpan di tabel settings dan ditimpakan ke config() pada setiap permintaan API (lihat ForceJsonResponse),
 * sehingga seluruh kode yang memakai config('cleandrive.*') otomatis membaca nilai terbaru.
 */
class RewardSettings
{
    private const KEY = 'rewards';

    /** Kunci yang boleh diatur admin. */
    public const FIELDS = [
        'coin_value', 'coin_step', 'coin_redeem_cap_pct', 'checkin_rewards',
        'review_coins', 'review_comment_bonus', 'band_mid', 'band_high', 'band_coins',
        'shop_coin_step_rp', 'shop_coin_reward',
    ];

    /** Nilai yang berlaku sekarang: nilai awal dari config, ditimpa pengaturan admin. */
    public static function current(): array
    {
        $base = [];
        foreach (self::FIELDS as $k) {
            $base[$k] = config("cleandrive.{$k}");
        }

        return array_replace($base, self::stored());
    }

    /** Timpakan pengaturan admin ke config(). Aman dipanggil walau tabel settings belum ada. */
    public static function apply(): void
    {
        $stored = self::stored();
        if ($stored) {
            config(['cleandrive' => array_replace(config('cleandrive'), $stored)]);
        }
    }

    /** Validasi dan simpan pengaturan reward. Hasil: nilai yang berlaku setelah disimpan. */
    public static function save(array $in): array
    {
        $int = function (string $key, string $label, int $min, int $max) use ($in): int {
            $v = $in[$key] ?? null;
            if (! is_numeric($v) || (int) $v != $v || (int) $v < $min || (int) $v > $max) {
                throw new ApiException("{$label} harus berupa angka bulat antara {$min} dan {$max}.");
            }

            return (int) $v;
        };

        $checkIn = $in['checkin_rewards'] ?? null;
        if (! is_array($checkIn) || count($checkIn) !== 7) {
            throw new ApiException('Check-in harian harus berisi 7 angka (hari ke-1 sampai ke-7).');
        }
        $checkIn = array_values($checkIn);
        foreach ($checkIn as $i => $v) {
            if (! is_numeric($v) || (int) $v != $v || (int) $v < 0 || (int) $v > 10000) {
                throw new ApiException('Coins check-in hari ke-'.($i + 1).' harus berupa angka bulat antara 0 dan 10000.');
            }
            $checkIn[$i] = (int) $v;
        }

        $bands = $in['band_coins'] ?? null;
        if (! is_array($bands)) {
            throw new ApiException('Coins tingkat transaksi wajib diisi.');
        }
        $bandInt = function (string $k, string $label) use ($bands): int {
            $v = $bands[$k] ?? null;
            if (! is_numeric($v) || (int) $v != $v || (int) $v < 0 || (int) $v > 100000) {
                throw new ApiException("Coins tingkat {$label} harus berupa angka bulat antara 0 dan 100000.");
            }

            return (int) $v;
        };

        $data = [
            'coin_value' => $int('coin_value', 'Nilai 1 Coin (Rp)', 1, 100000),
            'coin_step' => $int('coin_step', 'Kelipatan penukaran Coins', 1, 10000),
            'coin_redeem_cap_pct' => $int('coin_redeem_cap_pct', 'Batas potongan (%)', 1, 100),
            'checkin_rewards' => $checkIn,
            'review_coins' => $int('review_coins', 'Coins ulasan', 0, 10000),
            'review_comment_bonus' => $int('review_comment_bonus', 'Bonus komentar ulasan', 0, 10000),
            'band_mid' => $int('band_mid', 'Batas tingkat menengah (Rp)', 1000, 100000000),
            'band_high' => $int('band_high', 'Batas tingkat tertinggi (Rp)', 1000, 100000000),
            'band_coins' => [
                'low' => $bandInt('low', 'terendah'),
                'mid' => $bandInt('mid', 'menengah'),
                'high' => $bandInt('high', 'tertinggi'),
            ],
            'shop_coin_step_rp' => $int('shop_coin_step_rp', 'Kelipatan belanja Toko (Rp)', 1000, 100000000),
            'shop_coin_reward' => $int('shop_coin_reward', 'Coins belanja Toko', 0, 10000),
        ];
        if ($data['band_high'] <= $data['band_mid']) {
            throw new ApiException('Batas tingkat tertinggi harus lebih besar dari batas tingkat menengah.');
        }

        DB::table('settings')->updateOrInsert(
            ['key' => self::KEY],
            ['value' => json_encode($data), 'created_at' => now(), 'updated_at' => now()],
        );

        return self::current();
    }

    private static function stored(): array
    {
        try {
            $raw = DB::table('settings')->where('key', self::KEY)->value('value');
        } catch (\Throwable) {
            return []; // tabel belum dibuat (migrate belum dijalankan)
        }
        $data = $raw ? json_decode($raw, true) : null;

        return is_array($data) ? array_intersect_key($data, array_flip(self::FIELDS)) : [];
    }
}

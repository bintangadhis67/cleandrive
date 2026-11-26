<?php

namespace Database\Seeders;

use App\Models\Booking;
use App\Models\CoinEntry;
use App\Models\Payment;
use App\Models\Review;
use App\Models\User;
use App\Models\Vehicle;
use App\Models\WashPackage;
use App\Services\CoinService;
use Illuminate\Database\Seeder;

/**
 * Data demo untuk presentasi: kendaraan, beberapa pesanan dalam berbagai status, ulasan, dan riwayat Coins
 * untuk akun budi@mail.com. Dipanggil dari DatabaseSeeder, jadi `php artisan migrate:fresh --seed` selalu
 * menghasilkan tampilan yang siap dipamerkan. Tanggal dibuat relatif terhadap hari ini.
 */
class DemoSeeder extends Seeder
{
    public function run(): void
    {
        $budi = User::where('email', 'budi@mail.com')->first();
        if (! $budi) {
            return;
        }

        // ---- garasi ----
        $car = Vehicle::firstOrCreate(
            ['user_id' => $budi->id, 'plate' => 'L 1234 AB'],
            ['type' => 'mobil', 'brand' => 'Toyota', 'model' => 'Avanza', 'year' => 2020, 'color' => 'Putih'],
        );
        $bike = Vehicle::firstOrCreate(
            ['user_id' => $budi->id, 'plate' => 'L 5678 CD'],
            ['type' => 'motor', 'brand' => 'Honda', 'model' => 'Vario 125', 'year' => 2022, 'color' => 'Hitam'],
        );

        // [kendaraan, paket, hari relatif, jam, status, dibayar, ulasan [rating, komentar]|null, dibatalkan]
        $rows = [
            [$car, 'Reguler', -6, 10, 3, true, [5, 'Hasilnya bersih dan cepat, petugasnya ramah.'], false],
            [$bike, 'Express', -3, 14, 3, true, [4, 'Antrean lancar, harga sesuai.'], false],
            [$car, 'Detailing', 0, 9, 1, true, null, false],   // sedang diproses hari ini
            [$bike, 'Reguler', 1, 11, 0, true, null, false],   // sudah dibayar, menunggu giliran
            [$car, 'Express', 2, 15, 0, false, null, false],   // belum dibayar
            [$bike, 'Express', -1, 13, 0, false, null, true],  // dibatalkan
        ];

        $n = 0;
        foreach ($rows as [$v, $pack, $day, $hour, $status, $paid, $review, $cancelled]) {
            $n++;
            $wp = WashPackage::where('name', $pack)->first();
            if (! $wp) {
                continue;
            }
            $price = $wp->priceFor($v->type);
            $slot = now()->addDays($day)->setTime($hour, 0, 0);
            $code = sprintf('CD-D%03d-%s', $n, str_replace(' ', '', $v->plate));
            if (Booking::where('code', $code)->exists()) {
                continue;
            }

            $b = Booking::create([
                'user_id' => $budi->id,
                'code' => $code,
                'plate' => $v->plate,
                'vehicle' => $v->type,
                'package' => $pack,
                'slot' => $slot,
                'est_finish' => (clone $slot)->addMinutes((int) $wp->minutes),
                'price' => $price,
                'status' => $status,
                'verified' => $status >= 1,
                'verified_at' => $status >= 1 ? $slot : null,
                'cancelled' => $cancelled,
                'cancelled_at' => $cancelled ? now()->subDay() : null,
                'pay_status' => $paid ? 'paid' : 'unpaid',
            ]);

            if ($paid) {
                $trx = sprintf('TRX-DEMO-%03d', $n);
                $earn = CoinService::forPayment(false, $price);
                Payment::create([
                    'trx' => $trx,
                    'booking_id' => $b->id,
                    'user_id' => $budi->id,
                    'method' => $n % 2 ? 'qris' : 'gopay',
                    'amount' => $price,
                    'status' => 'paid',
                    'expires_at' => $slot,
                    'sandbox' => true,
                    'coins_earned' => $earn,
                    'paid_at' => (clone $slot)->subHours(2),
                ]);
                $b->update(['trx' => $trx, 'pay_method' => $n % 2 ? 'qris' : 'gopay', 'coins_earned' => $earn]);
                CoinService::add($budi, 'transaction', "Transaksi {$code}", $earn, 'Pembayaran demo', $b->id);
            }

            if ($review) {
                Review::create([
                    'booking_id' => $b->id,
                    'user_id' => $budi->id,
                    'rating' => $review[0],
                    'comment' => $review[1],
                ]);
                CoinService::add($budi, 'review', "Ulasan {$code}", (int) config('cleandrive.review_coins') + (int) config('cleandrive.review_comment_bonus'), '', $b->id);
            }
        }

        // ---- Coins tambahan: bonus selamat datang (hanya sekali) ----
        if (! CoinEntry::where('user_id', $budi->id)->where('kind', 'promo')->exists()) {
            CoinService::add($budi, 'promo', 'Bonus Selamat Datang', 50, '');
        }
    }
}

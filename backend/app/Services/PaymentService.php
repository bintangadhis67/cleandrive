<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\Booking;
use App\Models\Payment;
use App\Models\Product;
use App\Models\User;
use App\Models\WashPackage;
use App\Support\Presenter;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * Pembayaran (sandbox / simulasi), sama dengan startPayment, confirmPayment, simulateQrisPaid di MockRepository.
 * Total dihitung server. Coins baru dipotong, stok baru berkurang, dan Coins hadiah baru diberikan saat pembayaran BERHASIL.
 */
class PaymentService
{
    public const METHODS = [
        'qris' => 'QRIS',
        'gopay' => 'GoPay',
        'ovo' => 'OVO',
        'dana' => 'DANA',
        'shopeepay' => 'ShopeePay',
        'livin' => "Livin' by Mandiri",
    ];

    public function start(User $actor, int|string $bookingId, string $method, int $coins): Payment
    {
        $own = $this->ownBooking($actor, $bookingId);

        if (! isset(self::METHODS[$method])) {
            throw new ApiException('Metode pembayaran tidak valid.');
        }
        if ($coins < 0) {
            throw new ApiException('Jumlah Coins tidak valid.');
        }

        return DB::transaction(function () use ($own, $method, $coins) {
            $b = Booking::lockForUpdate()->findOrFail($own->id);
            if ($b->cancelled) {
                throw new ApiException('Pesanan sudah dibatalkan.');
            }
            if ($b->pay_status === 'paid') {
                throw new ApiException('Pesanan ini sudah dibayar.');
            }

            // Total dihitung server: harga - voucher - diskon membership - Coins (bila dipakai).
            $total = $b->total();
            $discount = 0;
            if ($coins > 0) {
                $step = (int) config('cleandrive.coin_step');
                $max = CoinService::maxRedeem($total, CoinService::balance($b->user_id));
                if ($coins % $step !== 0) {
                    throw new ApiException("Coins ditukar dalam kelipatan {$step}.");
                }
                if ($coins > $max) {
                    throw new ApiException("Coins melebihi batas penukaran ({$max} Coins).");
                }
                $discount = $coins * (int) config('cleandrive.coin_value');
            }
            $amount = $total - $discount;
            $isQris = $method === 'qris';

            $p = Payment::create([
                'trx' => 'TMP-'.Str::uuid(), // diganti segera setelah id diketahui
                'booking_id' => $b->id,
                'user_id' => $b->user_id,
                'method' => $method,
                'amount' => $amount,
                'coins_used' => $coins,
                'coin_discount' => $discount,
                'status' => 'pending',
                'expires_at' => now()->addMinutes((int) config('cleandrive.payment_expiry_minutes')),
                'balance' => $isQris ? null : (int) config("cleandrive.wallet_balances.{$method}"),
                'sandbox' => (bool) config('cleandrive.sandbox'),
            ]);
            $p->trx = 'TRX-'.now()->format('ymd').'-'.str_pad((string) $p->id, 3, '0', STR_PAD_LEFT);
            $p->qr_string = $isQris ? "CLEANDRIVE-QRIS|{$p->trx}|{$amount}|{$b->code}" : null;
            $p->save();

            return $p;
        });
    }

    public function find(User $actor, string $id): Payment
    {
        $p = Payment::find($id);
        if (! $p || (! $actor->isAdmin() && (int) $p->user_id !== (int) $actor->id)) {
            throw new ApiException('Transaksi tidak ditemukan.', 404);
        }

        return $this->expireIfNeeded($p);
    }

    /** Konfirmasi e-wallet / bank. */
    public function confirm(User $actor, string $id): Payment
    {
        $p = $this->find($actor, $id);
        if ($p->method === 'qris') {
            throw new ApiException('Pembayaran QRIS dilakukan dengan scan QR.');
        }
        if ($p->status === 'paid') {
            return $p;
        }
        if ($p->status === 'expired') {
            throw new ApiException('Waktu pembayaran sudah habis.');
        }
        if (($p->balance ?? 0) < $p->amount) {
            throw new ApiException('Saldo '.self::METHODS[$p->method].' tidak cukup.');
        }

        return $this->markPaid($p);
    }

    /** Hanya mode sandbox: anggap QR sudah discan dan dibayar. */
    public function simulateQris(User $actor, string $id): Payment
    {
        if (! config('cleandrive.sandbox')) {
            throw new ApiException('Simulasi pembayaran hanya tersedia di mode sandbox.', 403);
        }
        $p = $this->find($actor, $id);
        if ($p->status === 'paid') {
            return $p;
        }
        if ($p->status === 'expired') {
            throw new ApiException('QR sudah kedaluwarsa. Buat QR baru.');
        }

        return $this->markPaid($p);
    }

    // ---------------------------------------------------------------- inti

    /** Tandai lunas, kurangi stok, potong Coins yang dipakai, lalu beri Coins transaksi. */
    private function markPaid(Payment $payment): Payment
    {
        return DB::transaction(function () use ($payment) {
            $p = Payment::lockForUpdate()->findOrFail($payment->id);
            if ($p->status === 'paid') {
                return $p; // sudah diproses (mis. dobel klik)
            }

            $b = Booking::with('items')->lockForUpdate()->findOrFail($p->booking_id);
            if ($b->cancelled) {
                throw new ApiException('Pesanan sudah dibatalkan.');
            }
            if ($b->pay_status === 'paid') {
                throw new ApiException('Pesanan ini sudah dibayar.');
            }

            $owner = (int) $b->user_id;
            if ($p->coins_used > CoinService::balance($owner)) {
                throw new ApiException('Coins kamu tidak mencukupi lagi. Ulangi pembayaran tanpa Coins.');
            }

            // Stok: dicek lagi saat dibayar, karena bisa saja habis dibeli orang lain sejak pesanan dibuat.
            $products = Product::whereIn('id', $b->items->pluck('product_id')->all())->lockForUpdate()->get()->keyBy('id');
            foreach ($b->items as $item) {
                $prod = $products[$item->product_id];
                if ($item->qty > $prod->stock) {
                    throw new ApiException($prod->stock <= 0
                        ? "Maaf, {$prod->name} baru saja habis."
                        : "Maaf, stok {$prod->name} tinggal {$prod->stock}.");
                }
            }
            foreach ($b->items as $item) {
                $products[$item->product_id]->decrement('stock', $item->qty);
            }

            $isShop = WashPackage::where('name', $b->package)->value('kind') === 'shop';

            $p->status = 'paid';
            $p->paid_at = now();

            $b->pay_status = 'paid';
            $b->pay_method = $p->method;
            $b->trx = $p->trx;
            if ($isShop) {
                // Beli langsung: begitu dibayar, pembelian selesai (tanpa antrean/proses).
                $b->status = 3;
                $b->verified = true;
                $b->verified_at = now();
                $b->est_finish = now();
            }
            if ($p->coins_used > 0) {
                $b->coins_used = $p->coins_used;
                $b->coin_discount = $p->coin_discount;
                CoinService::add($owner, 'redeem', 'Tukar Coins', -$p->coins_used, $b->code, $b->id);
            }

            // Coins hadiah dihitung dari jumlah yang benar-benar dibayar (setelah potongan Coins).
            $paid = $b->total();
            $earn = CoinService::forPayment($isShop, $paid);
            if ($earn > 0) {
                $note = $isShop
                    ? 'Belanja '.Presenter::rp($paid).' (+'.config('cleandrive.shop_coin_reward').' tiap '.Presenter::rp((int) config('cleandrive.shop_coin_step_rp')).')'
                    : 'Tingkat '.CoinService::band($paid)[0].' • '.Presenter::rp($paid);
                CoinService::add($owner, 'transaction', "Transaksi {$b->code}", $earn, $note, $b->id);
            }
            $b->coins_earned = $earn;
            $p->coins_earned = $earn;

            $b->save();
            $p->save();

            // Percobaan bayar lain untuk pesanan ini tidak boleh dipakai lagi.
            Payment::where('booking_id', $b->id)->where('id', '!=', $p->id)->where('status', 'pending')
                ->update(['status' => 'expired']);

            NotifyService::send(
                $owner,
                'payment',
                $isShop ? 'Pembelian berhasil' : 'Pembayaran berhasil',
                "{$b->code} • ".Presenter::rp($paid).' via '.self::METHODS[$p->method].'.'.($earn > 0 ? " Kamu dapat +{$earn} Coins." : ''),
                'order:'.$b->id,
                false,
            );

            return $p->fresh();
        });
    }

    private function expireIfNeeded(Payment $p): Payment
    {
        if ($p->status === 'pending' && now()->gt($p->expires_at)) {
            $p->status = 'expired';
            $p->save();
        }

        return $p;
    }

    private function ownBooking(User $actor, int|string $id): Booking
    {
        $b = Booking::find($id);
        if (! $b) {
            throw new ApiException('Pesanan tidak ditemukan.', 404);
        }
        if (! $actor->isAdmin() && (int) $b->user_id !== (int) $actor->id) {
            throw new ApiException('Bukan pesananmu.', 403);
        }

        return $b;
    }
}

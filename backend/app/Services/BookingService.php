<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\Booking;
use App\Models\BookingItem;
use App\Models\Product;
use App\Models\Review;
use App\Models\User;
use App\Models\Voucher;
use App\Models\VoucherClaim;
use App\Models\WashPackage;
use App\Support\Presenter;
use Carbon\Carbon;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * Aturan pesanan. Semua perhitungan (harga, voucher, membership, kapasitas slot, stok) dilakukan di server,
 * persis seperti MockRepository.createBooking / cancelBooking / submitReview di Flutter.
 */
class BookingService
{
    private const TIER_NAMES = ['', 'Bronze', 'Silver', 'Gold', 'Platinum'];

    public function create(User $user, array $in): Booking
    {
        $vehicle = (string) ($in['vehicle'] ?? '');
        if (! in_array($vehicle, ['motor', 'mobil'], true)) {
            throw new ApiException('Jenis kendaraan tidak valid.');
        }

        $pack = WashPackage::where('name', (string) ($in['package'] ?? ''))->where('is_active', true)->first();
        if (! $pack) {
            throw new ApiException('Paket layanan tidak ditemukan.');
        }

        $isShop = $pack->kind === 'shop';
        $isOil = $pack->kind === 'oil';
        $plate = trim((string) ($in['plate'] ?? ''));
        $voucherCode = trim((string) ($in['voucher_code'] ?? ''));
        $useFree = filter_var($in['use_free_wash'] ?? false, FILTER_VALIDATE_BOOLEAN);
        $lines = $this->lines($in['items'] ?? []);
        $now = now()->setMicroseconds(0);
        $vehicleLabel = ucfirst($vehicle);
        $slot = $now; // pembelian toko: waktu sekarang

        if ($isShop) {
            if (! $lines) {
                throw new ApiException('Keranjang masih kosong.');
            }
        } else {
            if ($plate === '') {
                throw new ApiException('Plat nomor wajib diisi.');
            }
            if (mb_strlen($plate) > 20) {
                throw new ApiException('Plat nomor terlalu panjang.');
            }
            $slot = $this->parseSlot($in['slot'] ?? null);
            if ($slot->lt($now)) {
                throw new ApiException('Jam tersebut sudah lewat. Pilih jam lain.');
            }
        }

        $products = Product::whereIn('id', array_map('strval', array_keys($lines)))
            ->where('is_active', true)->get()->keyBy('id');
        foreach (array_keys($lines) as $pid) {
            if (! $products->has((string) $pid)) {
                throw new ApiException('Produk tidak ditemukan.');
            }
        }

        if ($isOil) {
            if (! $lines) {
                throw new ApiException('Pilih oli dari toko CleanDrive. Oli dari luar tidak diperbolehkan.');
            }
            if (count($lines) > 1) {
                throw new ApiException('Pilih satu jenis oli saja.');
            }
            foreach ($products as $p) {
                if ($p->category !== 'oli' || ! $p->fits($vehicle)) {
                    throw new ApiException("Oli {$p->name} tidak cocok untuk {$vehicleLabel}.");
                }
            }
        } elseif (! $isShop && $lines) {
            throw new ApiException('Produk hanya bisa dibeli lewat Toko atau jasa ganti oli.');
        }

        foreach ($lines as $pid => $qty) {
            $p = $products[(string) $pid];
            if ($p->stock <= 0) {
                throw new ApiException("{$p->name} sudah habis.");
            }
            if ($qty > $p->stock) {
                throw new ApiException("Stok {$p->name} tinggal {$p->stock}.");
            }
        }

        return DB::transaction(function () use ($user, $pack, $isShop, $plate, $voucherCode, $useFree, $lines, $now, $slot, $vehicle, $products) {
            // ---- kapasitas slot (dikunci supaya dua orang tidak merebut slot terakhir bersamaan) ----
            $ahead = 0;
            if (! $isShop) {
                $shopNames = WashPackage::where('kind', 'shop')->pluck('name')->all();
                $taken = Booking::where('cancelled', false)
                    ->whereNotIn('package', $shopNames)
                    ->where('slot', $slot)
                    ->lockForUpdate()
                    ->count();
                if ($taken >= (int) config('cleandrive.max_per_slot')) {
                    throw new ApiException('Slot jam '.$slot->format('H:i').' sudah penuh.');
                }
                $ahead = $taken;
            }

            // ---- cuci gratis membership ----
            $mem = MembershipService::active($user, true);
            if ($useFree) {
                if ($voucherCode !== '') {
                    throw new ApiException('Cuci gratis membership tidak bisa digabung dengan voucher.');
                }
                if (! $mem) {
                    throw new ApiException('Kamu belum punya membership aktif.');
                }
                $block = MembershipService::freeWashBlock($mem, $pack, $vehicle, $slot);
                if ($block !== null) {
                    throw new ApiException($block);
                }
            }

            // ---- harga ----
            $servicePrice = $pack->priceFor($vehicle);
            $itemsTotal = 0;
            foreach ($lines as $pid => $qty) {
                $itemsTotal += $products[(string) $pid]->price * $qty;
            }
            $price = $servicePrice + $itemsTotal;

            // ---- voucher ----
            $discount = 0;
            $claim = null;
            $voucher = null;
            if ($voucherCode !== '') {
                $voucher = Voucher::where('code', $voucherCode)->where('is_active', true)->first();
                if (! $voucher) {
                    throw new ApiException('Voucher tidak ditemukan.');
                }
                if (MembershipService::rank($user) < $voucher->min_tier) {
                    $tier = self::TIER_NAMES[$voucher->min_tier] ?? '';
                    throw new ApiException("Voucher ini khusus member {$tier}. Beli membership untuk membukanya.");
                }
                $claim = VoucherService::claim($user, $voucher, true);
                if (! $claim) {
                    throw new ApiException('Voucher belum diklaim.');
                }
                if ($claim->used) {
                    throw new ApiException('Voucher sudah pernah dipakai.');
                }
                if (VoucherService::validUntil($voucher, $claim)->isPast()) {
                    throw new ApiException('Voucher sudah kedaluwarsa.');
                }
                if ($price < $voucher->min_transaction) {
                    throw new ApiException('Minimal transaksi voucher '.Presenter::rp($voucher->min_transaction).'.');
                }
                $discount = $voucher->discountFor($price);
            }

            // ---- diskon / cuci gratis membership ----
            $plan = $mem ? MembershipService::plan($mem->tier) : null;
            $tierName = $mem ? MembershipService::label($mem->tier) : '';
            $memberDiscount = 0;
            $memberLabel = null;
            $freeWash = false;
            $payStatus = 'unpaid';
            $trx = null;
            $freeWeekKey = null;

            if ($useFree && $mem) {
                // Cuci gratis: total Rp 0, otomatis lunas, tanpa Coins.
                $freeWash = true;
                $memberDiscount = $price;
                $memberLabel = "Cuci Gratis {$tierName}";
                $payStatus = 'paid';
                $seq = Booking::where('free_wash', true)->whereDate('created_at', $now->toDateString())->count() + 1;
                $trx = 'FREE-'.$now->format('ymd').'-'.str_pad((string) $seq, 3, '0', STR_PAD_LEFT);
                $freeWeekKey = MembershipService::weekKey($slot);
            } elseif (! $isShop && $mem && $plan) {
                // Diskon membership hanya untuk jasa layanan (bukan produk toko).
                $memberDiscount = min(intdiv($servicePrice * $plan->discount_pct, 100), $price - $discount);
                $memberLabel = "{$tierName} {$plan->discount_pct}%";
            }

            // ---- benefit kunjungan Gold/Platinum: hanya untuk cuci, 1 kunjungan per hari ----
            $perks = [];
            if ($pack->kind === 'wash' && $mem && $plan && ! $slot->gt($mem->end_date)) {
                $planPerks = MembershipService::visitPerks($plan);
                if ($planPerks && ! $this->perkUsedOn($user, $slot)) {
                    $perks = $planPerks;
                }
            }

            // ---- simpan ----
            $b = Booking::create([
                'user_id' => $user->id,
                'code' => 'TMP-'.Str::uuid(), // diganti segera setelah id diketahui
                'plate' => $isShop ? '-' : mb_strtoupper($plate),
                'vehicle' => $vehicle,
                'package' => $pack->name,
                'slot' => $slot,
                'est_finish' => $slot->copy()->addMinutes($pack->minutes + $ahead * (int) config('cleandrive.queue_extra_minutes')),
                'price' => $price,
                'discount' => $discount,
                'member_discount' => $memberDiscount,
                'member_label' => $memberLabel,
                'voucher_code' => $voucher?->code,
                'free_wash' => $freeWash,
                'free_week_key' => $freeWeekKey,
                'perks' => $perks ?: null,
                'pay_status' => $payStatus,
                'trx' => $trx,
            ]);
            $clean = $isShop ? 'TOKO' : mb_strtoupper(str_replace(' ', '', $plate));
            $b->code = 'CD-'.str_pad((string) $b->id, 4, '0', STR_PAD_LEFT).'-'.$clean;
            $b->save();

            foreach ($lines as $pid => $qty) {
                BookingItem::create([
                    'booking_id' => $b->id,
                    'product_id' => (string) $pid,
                    'qty' => $qty,
                    'price' => $products[(string) $pid]->price, // harga satuan saat dipesan
                ]);
            }

            if ($freeWash && $mem) {
                $weeks = $mem->free_weeks ?? [];
                $weeks[] = $freeWeekKey;
                $mem->free_used = $mem->free_used + 1;
                $mem->free_weeks = array_values(array_unique($weeks));
                $mem->save();
            }

            if ($claim) {
                $claim->update(['used' => true, 'used_booking_id' => $b->id, 'used_at' => now()]);
            }

            $itemCount = array_sum($lines);
            NotifyService::send(
                $user->id,
                'order',
                $isShop ? 'Pembelian dibuat' : ($freeWash ? 'Cuci gratis dipakai' : 'Pesanan dibuat'),
                $isShop
                    ? "{$b->code} • {$itemCount} item. Selesaikan pembayaran untuk menyelesaikan pembelian."
                    : ($freeWash
                        ? "{$b->code} • {$this->title($pack)}. Jatah cuci gratis membership terpakai, tidak perlu membayar."
                        : "{$b->code} • {$this->title($pack)}. Selesaikan pembayaran agar pesanan diproses."),
                'order:'.$b->id,
                false,
            );

            return $b->fresh(['items', 'review', 'user']);
        });
    }

    public function cancel(Booking $booking): Booking
    {
        return DB::transaction(function () use ($booking) {
            $b = Booking::with('items')->lockForUpdate()->findOrFail($booking->id);

            if ($b->cancelled) {
                throw new ApiException('Pesanan sudah dibatalkan.');
            }
            if ($b->status !== 0 || $b->verified) {
                throw new ApiException('Pesanan yang sudah diproses tidak bisa dibatalkan.');
            }

            $owner = (int) $b->user_id;
            $wasPaid = $b->pay_status === 'paid' && ! $b->free_wash;
            $b->cancelled = true;
            $b->cancelled_at = now();

            if ($b->free_wash) {
                // Jatah cuci gratis dikembalikan, hanya bila langganannya masih periode yang sama.
                $m = \App\Models\Membership::where('user_id', $owner)->lockForUpdate()->first();
                if ($m && $m->start_date && $b->created_at && $b->created_at->gte($m->start_date)) {
                    $m->free_used = max(0, $m->free_used - 1);
                    $m->free_weeks = array_values(array_diff($m->free_weeks ?? [], [$b->free_week_key]));
                    $m->save();
                }
                $b->pay_status = 'unpaid';
            }

            if ($wasPaid) {
                foreach ($b->items as $item) {
                    Product::whereKey($item->product_id)->increment('stock', $item->qty); // stok dikembalikan
                }
                $b->pay_status = 'refunded';

                if ($b->coins_used > 0) {
                    CoinService::add($owner, 'refund', 'Coins dikembalikan', $b->coins_used, $b->code, $b->id);
                }
                if ($b->coins_earned > 0) {
                    $back = min($b->coins_earned, max(0, CoinService::balance($owner)));
                    if ($back > 0) {
                        CoinService::add($owner, 'refund', 'Coins pesanan dibatalkan', -$back, $b->code, $b->id);
                    }
                }
            }

            // Voucher kembali tersedia (selama periodenya masih berjalan).
            VoucherClaim::where('used_booking_id', $b->id)
                ->update(['used' => false, 'used_booking_id' => null, 'used_at' => null]);

            $b->save();

            NotifyService::send(
                $owner,
                'order',
                'Pesanan dibatalkan',
                $b->free_wash
                    ? "{$b->code} dibatalkan. Jatah cuci gratis membership kamu dikembalikan."
                    : ($wasPaid
                        ? "{$b->code} dibatalkan. Pembayaran dikembalikan dan Coins pesanan ini ditarik."
                        : "{$b->code} dibatalkan."),
                'order:'.$b->id,
                false,
            );

            return $b->fresh(['items', 'review', 'user']);
        });
    }

    public function review(Booking $b, int $rating, string $comment): Booking
    {
        if ($b->cancelled || $b->status !== 3) {
            throw new ApiException('Ulasan hanya untuk pesanan yang sudah selesai.');
        }
        if ($b->review()->exists()) {
            throw new ApiException('Pesanan ini sudah diulas.');
        }
        if ($rating < 1 || $rating > 5) {
            throw new ApiException('Rating harus 1 sampai 5.');
        }
        if (mb_strlen($comment) > 200) {
            throw new ApiException('Ulasan maksimal 200 karakter.');
        }

        try {
            return DB::transaction(function () use ($b, $rating, $comment) {
                $text = trim($comment);
                Review::create(['booking_id' => $b->id, 'user_id' => $b->user_id, 'rating' => $rating, 'comment' => $text]);

                $coins = (int) config('cleandrive.review_coins') + ($text !== '' ? (int) config('cleandrive.review_comment_bonus') : 0);
                CoinService::add($b->user_id, 'review', "Ulasan {$b->code}", $coins, $text !== '' ? 'Ulasan dengan komentar' : 'Rating', $b->id);
                NotifyService::send($b->user_id, 'points', 'Terima kasih atas ulasanmu', "Kamu dapat +{$coins} Coins.", 'loyalty', false);

                return $b->fresh(['items', 'review', 'user']);
            });
        } catch (UniqueConstraintViolationException) {
            throw new ApiException('Pesanan ini sudah diulas.');
        }
    }

    // ---------------------------------------------------------------- helper

    /** [product_id => qty], baris dengan produk sama digabung. */
    private function lines(mixed $raw): array
    {
        $out = [];
        foreach ((array) $raw as $row) {
            if (! is_array($row)) {
                throw new ApiException('Format produk tidak valid.');
            }
            $pid = trim((string) ($row['product_id'] ?? ''));
            $qty = (int) ($row['qty'] ?? 0);
            if ($pid === '' || $qty < 1) {
                throw new ApiException('Jumlah produk tidak valid.');
            }
            $out[$pid] = ($out[$pid] ?? 0) + $qty;
            if ($out[$pid] > 99) {
                throw new ApiException('Jumlah produk maksimal 99.');
            }
        }

        return $out;
    }

    private function parseSlot(mixed $raw): Carbon
    {
        $s = trim((string) $raw);
        if ($s === '') {
            throw new ApiException('Pilih jadwal terlebih dahulu.');
        }
        try {
            $slot = Carbon::parse($s)->setTimezone(config('app.timezone'));
        } catch (\Throwable) {
            throw new ApiException('Jadwal tidak valid.');
        }
        if ($slot->minute !== 0 || $slot->second !== 0) {
            throw new ApiException('Jadwal tidak valid.');
        }
        $open = (int) config('cleandrive.open_hour');
        $close = (int) config('cleandrive.close_hour');
        if ($slot->hour < $open || $slot->hour > $close) {
            throw new ApiException(sprintf('Jam operasional %02d.00 - %02d.00 WIB.', $open, $close));
        }

        return $slot;
    }

    /** Sudah ada kunjungan lain di hari yang sama yang mendapat benefit makanan/minuman/VIP? */
    private function perkUsedOn(User $user, Carbon $slot): bool
    {
        return Booking::where('user_id', $user->id)
            ->where('cancelled', false)
            ->whereDate('slot', $slot->toDateString())
            ->get()
            ->contains(fn (Booking $o) => ! empty($o->perks));
    }

    /** "Express Wash" untuk cuci, nama apa adanya untuk layanan lain (WashPackage.title di Flutter). */
    private function title(WashPackage $p): string
    {
        return $p->kind === 'wash' ? "{$p->name} Wash" : $p->name;
    }
}

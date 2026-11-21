<?php

namespace App\Support;

use App\Models\Booking;
use App\Models\CoinEntry;
use App\Models\Membership;
use App\Models\MembershipTransaction;
use App\Models\Payment;
use App\Models\Product;
use App\Models\User;
use Carbon\CarbonInterface;

/**
 * Mengubah model menjadi array JSON dengan nama kunci yang dibaca model Flutter (snake_case).
 */
class Presenter
{
    /** Waktu lokal tanpa "Z", mis. 2026-11-20T08:00:00 (dibaca DateTime.parse di Flutter sebagai waktu lokal). */
    public static function dt(?CarbonInterface $d): ?string
    {
        return $d?->copy()->setTimezone(config('app.timezone'))->format('Y-m-d\TH:i:s');
    }

    /** "Rp 75.000" */
    public static function rp(int $n): string
    {
        return 'Rp '.number_format($n, 0, ',', '.');
    }

    /** Dibaca SessionUser.fromJson di Flutter: name, email, phone, role. */
    public static function user(User $u): array
    {
        return [
            'id' => $u->id,
            'name' => $u->name,
            'email' => $u->email,
            'phone' => $u->phone ?? '',
            'role' => $u->role,
        ];
    }

    public static function product(Product $p): array
    {
        return [
            'id' => $p->id,
            'name' => $p->name,
            'description' => $p->description,
            'details' => $p->details,
            'price' => (int) $p->price,
            'category' => $p->category,
            'image' => $p->image,
            'stock' => (int) $p->stock,
            'vehicles' => $p->vehicles ?? [],
        ];
    }

    /** Dibaca Booking.fromJson di Flutter. $queue = posisi antrean (0 bila tidak mengantre). */
    public static function booking(Booking $b, int $queue = 0): array
    {
        $b->loadMissing(['items', 'review', 'user']);

        return [
            'id' => $b->id,
            'code' => $b->code,
            'plate' => $b->plate,
            'owner' => $b->user?->name ?? '',
            'vehicle' => $b->vehicle,
            'package' => $b->package,
            'slot' => self::dt($b->slot),
            'est_finish' => self::dt($b->est_finish),
            'price' => (int) $b->price,
            'discount' => (int) $b->discount,
            'member_discount' => (int) $b->member_discount,
            'member_label' => $b->member_label,
            'voucher_code' => $b->voucher_code,
            'free_wash' => (bool) $b->free_wash,
            'perks' => $b->perks ?? [],
            'items' => $b->items->map(fn ($i) => ['product_id' => $i->product_id, 'qty' => (int) $i->qty])->values()->all(),
            'coins_used' => (int) $b->coins_used,
            'coin_discount' => (int) $b->coin_discount,
            'coins_earned' => (int) $b->coins_earned,
            'status' => (int) $b->status,
            'verified' => (bool) $b->verified,
            'cancelled' => (bool) $b->cancelled,
            'pay_status' => $b->pay_status,
            'pay_method' => $b->pay_method,
            'trx' => $b->trx,
            'review' => $b->review ? [
                'rating' => (int) $b->review->rating,
                'comment' => $b->review->comment,
                'created_at' => self::dt($b->review->created_at),
            ] : null,
            'queue_position' => $queue,
        ];
    }

    /** Dibaca Payment.fromJson di Flutter. */
    public static function payment(Payment $p): array
    {
        return [
            'id' => $p->id,
            'trx' => $p->trx,
            'booking_id' => $p->booking_id,
            'method' => $p->method,
            'amount' => (int) $p->amount,
            'coins_used' => (int) $p->coins_used,
            'coin_discount' => (int) $p->coin_discount,
            'status' => $p->status,
            'expires_at' => self::dt($p->expires_at),
            'qr_string' => $p->qr_string,
            'balance' => $p->balance === null ? null : (int) $p->balance,
            'sandbox' => (bool) $p->sandbox,
            'coins_earned' => (int) $p->coins_earned,
        ];
    }

    /** Dibaca CoinEntry.fromJson di Flutter. */
    public static function coinEntry(CoinEntry $e): array
    {
        return [
            'id' => $e->id,
            'kind' => $e->kind,
            'title' => $e->title,
            'note' => $e->note ?? '',
            'amount' => (int) $e->amount,
            'created_at' => self::dt($e->created_at),
        ];
    }

    /** Langganan pengguna. status "active" yang masa berlakunya sudah lewat dikirim sebagai "expired". */
    public static function membership(Membership $m): array
    {
        $status = $m->status === 'active' && $m->end_date && $m->end_date->isPast() ? 'expired' : $m->status;

        return [
            'id' => $m->id,
            'tier' => $m->tier,
            'status' => $status,
            'start_date' => self::dt($m->start_date),
            'end_date' => self::dt($m->end_date),
            'cancel_at_end' => (bool) $m->cancel_at_end,
            'free_total' => (int) $m->free_total,
            'free_used' => (int) $m->free_used,
            'free_weeks' => array_values($m->free_weeks ?? []),
        ];
    }

    /** Riwayat pembelian membership. */
    public static function membershipTx(MembershipTransaction $t): array
    {
        return [
            'id' => $t->id,
            'trx' => $t->trx,
            'tier' => $t->tier,
            'amount' => (int) $t->amount,
            'method' => $t->method,
            'renewal' => (bool) $t->renewal,
            'refund' => (bool) $t->refund,
            'created_at' => self::dt($t->created_at),
        ];
    }
}

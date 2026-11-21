<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\Booking;
use App\Models\Membership;
use App\Models\MembershipOrder;
use App\Models\MembershipTransaction;
use App\Models\User;
use App\Support\Presenter;
use Carbon\CarbonInterface;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * Pembelian, perpanjangan, dan pembatalan membership (sandbox). Sama dengan startMembershipPurchase,
 * _activateMembership, confirmMembershipPayment, simulateMembershipQris, cancelMembershipOrder,
 * dan cancelMembership di MockRepository. Harga selalu diambil dari paket di server.
 */
class MembershipPurchaseService
{
    private const TIERS = ['bronze', 'silver', 'gold', 'platinum'];
    private const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

    /** {current, pending, history} (MembershipInfo di Flutter). */
    public function info(User $user): array
    {
        $m = Membership::where('user_id', $user->id)->first();
        $pending = MembershipOrder::where('user_id', $user->id)->where('status', 'pending')
            ->where('expires_at', '>', now())->orderByDesc('id')->first();
        $history = MembershipTransaction::where('user_id', $user->id)->orderByDesc('created_at')->orderByDesc('id')->get();

        return [
            'current' => $m ? Presenter::membership($m) : null,
            'pending' => $pending ? Presenter::membershipOrder($pending) : null,
            'history' => $history->map(fn (MembershipTransaction $t) => Presenter::membershipTx($t))->values()->all(),
        ];
    }

    public function start(User $user, string $tier, string $method): MembershipOrder
    {
        if (! in_array($tier, self::TIERS, true)) {
            throw new ApiException('Paket membership tidak valid.');
        }
        if (! isset(PaymentService::METHODS[$method])) {
            throw new ApiException('Metode pembayaran tidak valid.');
        }
        $plan = MembershipService::plan($tier);
        if (! $plan || ! $plan->is_active) {
            throw new ApiException('Paket membership tidak tersedia.');
        }

        return DB::transaction(function () use ($user, $tier, $method, $plan) {
            User::lockForUpdate()->find($user->id);

            $cur = MembershipService::active($user);
            $renewal = $cur !== null && $cur->tier === $tier;

            // Satu pesanan menunggu pembayaran per pengguna: yang lama dibatalkan.
            MembershipOrder::where('user_id', $user->id)->where('status', 'pending')->update(['status' => 'cancelled']);

            $isQris = $method === 'qris';
            $o = MembershipOrder::create([
                'trx' => 'TMP-'.Str::uuid(), // diganti segera setelah id diketahui
                'user_id' => $user->id,
                'tier' => $tier,
                'amount' => $plan->price, // harga dari paket (server), tidak bisa diubah dari layar
                'method' => $method,
                'renewal' => $renewal,
                'status' => 'pending',
                'expires_at' => now()->addMinutes((int) config('cleandrive.payment_expiry_minutes')),
                'balance' => $isQris ? null : (int) config("cleandrive.wallet_balances.{$method}"),
                'sandbox' => (bool) config('cleandrive.sandbox'),
            ]);
            $o->trx = 'MBR-'.now()->format('ymd').'-'.str_pad((string) $o->id, 3, '0', STR_PAD_LEFT);
            $o->qr_string = $isQris ? "CLEANDRIVE-QRIS|{$o->trx}|{$plan->price}|MEMBERSHIP-".strtoupper($tier) : null;
            $o->save();

            return $o;
        });
    }

    public function find(User $user, string $id): MembershipOrder
    {
        $o = MembershipOrder::find($id);
        if (! $o) {
            throw new ApiException('Pesanan membership tidak ditemukan.', 404);
        }
        if ((int) $o->user_id !== (int) $user->id) {
            throw new ApiException('Bukan pesananmu.', 403);
        }
        if ($o->status === 'pending' && now()->gt($o->expires_at)) {
            $o->status = 'expired';
            $o->save();
        }

        return $o;
    }

    /** Konfirmasi e-wallet / bank. */
    public function confirm(User $user, string $id): MembershipOrder
    {
        $o = $this->find($user, $id);
        if ($o->method === 'qris') {
            throw new ApiException('Pembayaran QRIS dilakukan dengan scan QR.');
        }
        if ($o->status === 'paid') {
            return $o;
        }
        if ($o->status === 'cancelled') {
            throw new ApiException('Pesanan membership sudah dibatalkan.');
        }
        if ($o->status === 'expired') {
            throw new ApiException('Waktu pembayaran sudah habis.');
        }
        if (($o->balance ?? 0) < $o->amount) {
            throw new ApiException('Saldo '.PaymentService::METHODS[$o->method].' tidak cukup.');
        }

        return $this->activate($o);
    }

    /** Hanya mode sandbox: anggap QR sudah dibayar. */
    public function simulateQris(User $user, string $id): MembershipOrder
    {
        if (! config('cleandrive.sandbox')) {
            throw new ApiException('Simulasi pembayaran hanya tersedia di mode sandbox.', 403);
        }
        $o = $this->find($user, $id);
        if ($o->status === 'paid') {
            return $o;
        }
        if ($o->status === 'cancelled') {
            throw new ApiException('Pesanan membership sudah dibatalkan.');
        }
        if ($o->status === 'expired') {
            throw new ApiException('QR sudah kedaluwarsa. Buat QR baru.');
        }

        return $this->activate($o);
    }

    public function cancelOrder(User $user, string $id): void
    {
        $o = $this->find($user, $id);
        if ($o->status === 'paid') {
            throw new ApiException('Pesanan sudah dibayar dan tidak bisa dibatalkan.');
        }
        $o->status = 'cancelled';
        $o->save();
    }

    /**
     * Batalkan langganan aktif: membership langsung hilang dan seluruh pembayaran periode ini
     * (pembelian + perpanjangan) dikembalikan. Mengembalikan nominal refund (Rp).
     */
    public function cancel(User $user): int
    {
        return DB::transaction(function () use ($user) {
            $m = MembershipService::active($user, true);
            if (! $m) {
                throw new ApiException('Tidak ada membership aktif untuk dibatalkan.');
            }

            $paid = MembershipTransaction::where('user_id', $user->id)->where('refund', false)
                ->where('created_at', '>=', $m->start_date)->orderBy('id')->get();
            $refund = (int) $paid->sum('amount');
            $method = $paid->last()?->method ?? 'qris';

            // Pesanan cuci gratis yang belum diproses ikut dibatalkan, karena benefitnya sudah hilang.
            Booking::where('user_id', $user->id)->where('free_wash', true)->where('cancelled', false)->where('status', 0)
                ->update(['cancelled' => true, 'cancelled_at' => now(), 'pay_status' => 'unpaid']);

            $tier = $m->tier;
            $m->delete(); // status membership langsung hilang
            MembershipOrder::where('user_id', $user->id)->where('status', 'pending')->update(['status' => 'cancelled']);

            $t = MembershipTransaction::create([
                'trx' => 'TMP-'.Str::uuid(),
                'user_id' => $user->id,
                'tier' => $tier,
                'amount' => $refund,
                'method' => $method,
                'renewal' => false,
                'refund' => true,
            ]);
            $t->trx = 'RFD-'.now()->format('ymd').'-'.str_pad((string) $t->id, 3, '0', STR_PAD_LEFT);
            $t->save();

            NotifyService::send(
                $user->id,
                'membership',
                'Langganan dibatalkan',
                'Membership '.MembershipService::label($tier).' dihentikan. Dana '.Presenter::rp($refund).' dikembalikan ke '.PaymentService::METHODS[$method].'.',
                'membership',
                false,
            );

            return $refund;
        });
    }

    // ---------------------------------------------------------------- inti

    /** Aktifkan atau perpanjang membership setelah pembayaran berhasil. */
    private function activate(MembershipOrder $order): MembershipOrder
    {
        return DB::transaction(function () use ($order) {
            $o = MembershipOrder::lockForUpdate()->findOrFail($order->id);
            if ($o->status === 'paid') {
                return $o;
            }
            if ($o->status !== 'pending') {
                throw new ApiException('Pesanan membership sudah tidak berlaku.');
            }

            $plan = MembershipService::plan($o->tier);
            $now = now()->setMicroseconds(0);
            $cur = MembershipService::active($o->user_id, true);

            if ($cur && $cur->tier === $o->tier) {
                // Perpanjang: masa aktif +1 bulan dari tanggal berakhir saat ini, jatah cuci gratis bertambah,
                // dan status batal langganan dicabut. Jatah tetap maksimal 1x per minggu.
                $cur->end_date = $cur->end_date->copy()->addDays($plan->duration_days);
                $cur->free_total = $cur->free_total + $plan->free_wash_quota;
                $cur->cancel_at_end = false;
                $cur->save();
                $end = $cur->end_date;
            } else {
                // Beli baru / ganti paket / beli setelah kedaluwarsa: periode baru dengan jatah cuci gratis baru.
                $m = Membership::updateOrCreate(['user_id' => $o->user_id], [
                    'tier' => $o->tier,
                    'status' => 'active',
                    'start_date' => $now,
                    'end_date' => $now->copy()->addDays($plan->duration_days),
                    'cancel_at_end' => false,
                    'free_total' => $plan->free_wash_quota,
                    'free_used' => 0,
                    'free_weeks' => [],
                ]);
                $end = $m->end_date;
            }

            $o->status = 'paid';
            $o->paid_at = $now;
            $o->save();

            MembershipTransaction::create([
                'trx' => $o->trx,
                'user_id' => $o->user_id,
                'tier' => $o->tier,
                'amount' => $o->amount,
                'method' => $o->method,
                'renewal' => $o->renewal,
                'refund' => false,
                'created_at' => $now,
            ]);

            NotifyService::send(
                $o->user_id,
                'membership',
                $o->renewal ? 'Membership diperpanjang' : 'Membership '.MembershipService::label($o->tier).' aktif',
                'Berlaku hingga '.$this->idDate($end).'.',
                'membership',
                false,
            );

            return $o->fresh();
        });
    }

    /** "5 Des 2026" */
    private function idDate(CarbonInterface $d): string
    {
        return $d->day.' '.self::MONTHS[$d->month - 1].' '.$d->year;
    }
}

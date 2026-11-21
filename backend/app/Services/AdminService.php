<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\Booking;
use App\Models\CoinEntry;
use App\Models\Membership;
use App\Models\MembershipTransaction;
use App\Models\Review;
use App\Models\User;
use App\Models\WashPackage;
use App\Support\PackText;
use App\Support\Presenter;
use Illuminate\Support\Facades\DB;

/** Fitur panel admin, sama dengan verify, advance, summary, allReviews, adminOverview di MockRepository. */
class AdminService
{
    private const WITH = ['items', 'review', 'user'];

    /** Verifikasi tiket lewat kode (scan QR / ketik kode). */
    public function verify(string $code): Booking
    {
        $b = Booking::with(self::WITH)->where('code', mb_strtoupper(trim($code)))->first();
        if (! $b) {
            throw new ApiException('Kode tidak ditemukan', 404);
        }
        if ($b->cancelled) {
            throw new ApiException("Tiket {$b->code} sudah dibatalkan.");
        }
        if ($b->pay_status !== 'paid') {
            throw new ApiException("Tiket {$b->code} belum dibayar.");
        }

        $b->update(['verified' => true, 'verified_at' => now()]);
        NotifyService::send($b->user_id, 'order', 'Tiket terverifikasi', "{$b->code} sudah diverifikasi petugas.", 'order:'.$b->id);

        return $b->fresh(self::WITH);
    }

    /** Naikkan status satu tahap: menunggu -> proses -> finishing -> selesai. */
    public function advance(string $id): Booking
    {
        return DB::transaction(function () use ($id) {
            $b = Booking::with(self::WITH)->lockForUpdate()->find($id);
            if (! $b) {
                throw new ApiException('Pesanan tidak ditemukan.', 404);
            }
            if ($b->cancelled) {
                throw new ApiException('Pesanan sudah dibatalkan.');
            }
            if ($b->pay_status !== 'paid') {
                throw new ApiException('Pesanan belum dibayar.');
            }
            if ($b->status >= 3) {
                return $b;
            }

            $b->status = $b->status + 1;
            $b->verified = true;
            if ($b->status === 3) {
                $b->est_finish = now();
            }
            $b->save();

            $kind = WashPackage::where('name', $b->package)->value('kind') ?? 'wash';
            NotifyService::send(
                $b->user_id,
                'order',
                PackText::headlines($kind)[$b->status],
                "{$b->code} • ".PackText::title($b->package, $kind).': '.PackText::statusNames($kind)[$b->status].'.',
                'order:'.$b->id,
            );

            return $b->fresh(self::WITH);
        });
    }

    /** {total, done, revenue, by_package, rating}. Pesanan dibatalkan tidak dihitung. */
    public function summary(): array
    {
        $valid = fn () => Booking::where('cancelled', false);

        $byPackage = WashPackage::orderBy('id')->pluck('name')->mapWithKeys(fn ($n) => [$n => 0])->all();
        foreach ($valid()->selectRaw('package, COUNT(*) AS c')->groupBy('package')->get() as $r) {
            $byPackage[$r->package] = (int) $r->c;
        }

        return [
            'total' => $valid()->count(),
            'done' => $valid()->where('status', 3)->count(),
            'revenue' => (int) $valid()->where('status', 3)->where('pay_status', 'paid')
                ->sum(DB::raw('price - discount - member_discount - coin_discount')),
            'by_package' => (object) $byPackage,
            'rating' => [
                'avg' => round((float) Review::avg('rating'), 2),
                'count' => Review::count(),
            ],
        ];
    }

    /** Pesanan yang sudah diulas, ulasan terbaru di atas. */
    public function reviews()
    {
        return Booking::with(self::WITH)->whereHas('review')->get()
            ->sortByDesc(fn (Booking $b) => $b->review->created_at->getTimestamp())
            ->values();
    }

    /** Ringkasan lintas pelanggan: pelanggan, Coins, membership, dan aktivitas terbaru. */
    public function overview(): array
    {
        $kinds = PackText::kinds();
        $customers = User::where('role', '!=', 'admin')->orderBy('id')->get();
        $ids = $customers->pluck('id')->all();

        $bookings = Booking::where('cancelled', false)->whereIn('user_id', $ids)
            ->get(['id', 'user_id', 'price', 'discount', 'member_discount', 'coin_discount', 'pay_status'])
            ->groupBy('user_id');
        $balances = CoinEntry::whereIn('user_id', $ids)->selectRaw('user_id, SUM(amount) AS bal')->groupBy('user_id')->pluck('bal', 'user_id');
        $memberships = Membership::whereIn('user_id', $ids)->get()->keyBy('user_id');

        $customerRows = $customers->map(function (User $u) use ($bookings, $balances, $memberships) {
            $mine = $bookings->get($u->id, collect());

            return [
                'name' => $u->name,
                'email' => $u->email,
                'phone' => $u->phone ?? '',
                'joined_at' => Presenter::dt($u->created_at),
                'orders' => $mine->count(),
                'spent' => (int) $mine->where('pay_status', 'paid')->sum(fn (Booking $b) => $b->total()),
                'coins' => (int) ($balances[$u->id] ?? 0),
                'membership' => $memberships->has($u->id) ? Presenter::membership($memberships[$u->id]) : null,
            ];
        })->values()->all();

        $redeem = fn () => CoinEntry::whereIn('user_id', $ids)->where('kind', 'redeem');
        $stats = [
            'circulating' => (int) $balances->sum(),
            'checkins_today' => $customers->filter(fn (User $u) => $u->last_check_in && $u->last_check_in->isToday())->count(),
            'redeem_count' => $redeem()->count(),
            'redeemed_coins' => -((int) $redeem()->sum('amount')),
        ];

        // Daftar panjang dibatasi 200 baris terbaru.
        $entries = CoinEntry::with('user:id,name')->whereIn('user_id', $ids)
            ->orderByDesc('created_at')->orderByDesc('id')->limit(200)->get();
        $memberTx = MembershipTransaction::with('user:id,name')
            ->orderByDesc('created_at')->orderByDesc('id')->limit(200)->get();
        $recent = Booking::with('user:id,name')->orderByDesc('id')->limit(200)->get();

        $acts = [];
        foreach ($customers as $u) {
            $acts[] = ['kind' => 'customer', 'title' => 'Pelanggan baru terdaftar', 'subtitle' => $u->name, 'at' => $u->created_at];
        }
        foreach ($entries as $e) {
            if ($e->kind === 'checkin') {
                $acts[] = ['kind' => 'checkin', 'title' => 'Check-in harian', 'subtitle' => "+{$e->amount} Coins oleh {$e->user?->name}", 'at' => $e->created_at];
            }
        }
        foreach ($recent as $b) {
            $title = PackText::title($b->package, $kinds[$b->package] ?? 'wash');
            $acts[] = ['kind' => 'order', 'title' => "Pesanan #{$b->code}", 'subtitle' => "{$title} oleh {$b->user?->name}", 'at' => $b->created_at];
            if ($b->status >= 3 && ! $b->cancelled) {
                $acts[] = ['kind' => 'done', 'title' => "Pesanan #{$b->code}", 'subtitle' => 'Telah selesai dan dibayar', 'at' => $b->est_finish];
            }
            if ($b->verified_at) {
                $acts[] = ['kind' => 'verified', 'title' => "Tiket #{$b->code}", 'subtitle' => 'Berhasil diverifikasi', 'at' => $b->verified_at];
            }
            if ($b->cancelled_at) {
                $acts[] = ['kind' => 'cancelled', 'title' => "Pesanan #{$b->code}", 'subtitle' => 'Dibatalkan oleh pelanggan', 'at' => $b->cancelled_at];
            }
        }
        $activities = collect($acts)
            ->sortByDesc(fn ($a) => $a['at']->getTimestamp())
            ->take(40)
            ->map(fn ($a) => [...$a, 'at' => Presenter::dt($a['at'])])
            ->values()->all();

        return [
            'customers' => $customerRows,
            'coins' => $stats,
            'coin_rows' => $entries->map(fn (CoinEntry $e) => ['customer' => $e->user?->name ?? '', 'entry' => Presenter::coinEntry($e)])->values()->all(),
            'member_tx' => $memberTx->map(fn (MembershipTransaction $t) => ['customer' => $t->user?->name ?? '', 'tx' => Presenter::membershipTx($t)])->values()->all(),
            'activities' => $activities,
        ];
    }
}

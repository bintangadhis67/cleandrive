<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\ApiException;
use App\Models\Booking;
use App\Models\WashPackage;
use App\Services\BookingService;
use App\Services\QueueService;
use App\Support\Presenter;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BookingController extends ApiController
{
    public function __construct(private BookingService $bookings)
    {
    }

    /** Konsumen: pesanan milik sendiri. Admin: semua pesanan. */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $q = Booking::with(['items', 'review', 'user'])->orderByDesc('id');
        if (! $user->isAdmin()) {
            $q->where('user_id', $user->id);
        }
        $pos = QueueService::positions();

        return response()->json(
            $q->get()->map(fn (Booking $b) => Presenter::booking($b, $pos[$b->id] ?? 0))->values()
        );
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $b = $this->findFor($request, $id);

        return response()->json(Presenter::booking($b, QueueService::positions()[$b->id] ?? 0));
    }

    /** GET bookings/slots?date=2026-11-22  ->  {"8": 1, "9": 3}  (jam -> jumlah booking, tanpa pembelian toko) */
    public function slots(Request $request): JsonResponse
    {
        try {
            $day = Carbon::createFromFormat('Y-m-d', (string) $request->query('date'))->startOfDay();
        } catch (\Throwable) {
            return $this->fail('Tanggal tidak valid.');
        }

        $shop = WashPackage::where('kind', 'shop')->pluck('name')->all();
        $rows = Booking::where('cancelled', false)
            ->whereNotIn('package', $shop)
            ->whereBetween('slot', [$day->copy(), $day->copy()->endOfDay()])
            ->get(['slot']);

        $counts = [];
        foreach ($rows as $r) {
            $h = (int) $r->slot->format('G');
            $counts[$h] = ($counts[$h] ?? 0) + 1;
        }

        return response()->json((object) $counts); // (object) supaya kosong tetap {} dan bukan []
    }

    public function store(Request $request): JsonResponse
    {
        $b = $this->bookings->create($request->user(), $request->all());

        return response()->json(Presenter::booking($b, QueueService::positions()[$b->id] ?? 0), 201);
    }

    public function cancel(Request $request, string $id): JsonResponse
    {
        $b = $this->bookings->cancel($this->findFor($request, $id));

        return response()->json(Presenter::booking($b, QueueService::positions()[$b->id] ?? 0));
    }

    public function review(Request $request, string $id): JsonResponse
    {
        $b = $this->bookings->review(
            $this->findFor($request, $id),
            (int) $request->input('rating'),
            (string) $request->input('comment', ''),
        );

        return response()->json(Presenter::booking($b, QueueService::positions()[$b->id] ?? 0));
    }

    /** Pesanan milik sendiri (admin boleh semua). */
    private function findFor(Request $request, string $id): Booking
    {
        $b = Booking::with(['items', 'review', 'user'])->find($id);
        if (! $b) {
            throw new ApiException('Pesanan tidak ditemukan.', 404);
        }
        $u = $request->user();
        if (! $u->isAdmin() && (int) $b->user_id !== (int) $u->id) {
            throw new ApiException('Bukan pesananmu.', 403);
        }

        return $b;
    }
}

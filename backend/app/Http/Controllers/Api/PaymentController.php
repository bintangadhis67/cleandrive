<?php

namespace App\Http\Controllers\Api;

use App\Services\PaymentService;
use App\Support\Presenter;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PaymentController extends ApiController
{
    public function __construct(private PaymentService $payments)
    {
    }

    /** POST payments {booking_id, method, coins} -> Payment (status pending) */
    public function store(Request $request): JsonResponse
    {
        $p = $this->payments->start(
            $request->user(),
            (string) $request->input('booking_id'),
            (string) $request->input('method'),
            (int) $request->input('coins', 0),
        );

        return response()->json(Presenter::payment($p), 201);
    }

    public function show(Request $request, string $id): JsonResponse
    {
        return response()->json(Presenter::payment($this->payments->find($request->user(), $id)));
    }

    /** Konfirmasi e-wallet / bank. */
    public function confirm(Request $request, string $id): JsonResponse
    {
        return response()->json(Presenter::payment($this->payments->confirm($request->user(), $id)));
    }

    /** Hanya sandbox: anggap QR sudah dibayar. */
    public function simulateQris(Request $request, string $id): JsonResponse
    {
        return response()->json(Presenter::payment($this->payments->simulateQris($request->user(), $id)));
    }
}

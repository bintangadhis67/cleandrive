<?php

namespace App\Http\Controllers\Api;

use App\Services\MembershipPurchaseService;
use App\Support\Presenter;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MembershipController extends ApiController
{
    public function __construct(private MembershipPurchaseService $memberships)
    {
    }

    /** {current, pending, history} */
    public function show(Request $request): JsonResponse
    {
        return response()->json($this->memberships->info($request->user()));
    }

    /** POST membership/purchase {tier, method} -> MembershipOrder (pending) */
    public function purchase(Request $request): JsonResponse
    {
        $o = $this->memberships->start($request->user(), (string) $request->input('tier'), (string) $request->input('method'));

        return response()->json(Presenter::membershipOrder($o), 201);
    }

    public function order(Request $request, string $id): JsonResponse
    {
        return response()->json(Presenter::membershipOrder($this->memberships->find($request->user(), $id)));
    }

    public function confirm(Request $request, string $id): JsonResponse
    {
        return response()->json(Presenter::membershipOrder($this->memberships->confirm($request->user(), $id)));
    }

    public function simulateQris(Request $request, string $id): JsonResponse
    {
        return response()->json(Presenter::membershipOrder($this->memberships->simulateQris($request->user(), $id)));
    }

    public function cancelOrder(Request $request, string $id): JsonResponse
    {
        $this->memberships->cancelOrder($request->user(), $id);

        return response()->json(['message' => 'OK']);
    }

    /** Batalkan langganan aktif. Hasil: {"refund": 599000} */
    public function cancel(Request $request): JsonResponse
    {
        return response()->json(['refund' => $this->memberships->cancel($request->user())]);
    }
}

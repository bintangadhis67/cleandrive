<?php

namespace App\Http\Controllers\Api;

use App\Services\LoyaltyService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LoyaltyController extends ApiController
{
    public function __construct(private LoyaltyService $loyalty)
    {
    }

    public function show(Request $request): JsonResponse
    {
        return response()->json($this->loyalty->info($request->user()));
    }

    /** {"coins": 3, "streak": 1, "title": "Check-in hari ke-1"} */
    public function checkIn(Request $request): JsonResponse
    {
        return response()->json($this->loyalty->checkIn($request->user()));
    }

    public function claimPromo(Request $request, string $id): JsonResponse
    {
        return response()->json($this->loyalty->claimPromo($request->user(), $id));
    }
}

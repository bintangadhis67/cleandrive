<?php

namespace App\Http\Controllers\Api;

use App\Models\Booking;
use App\Services\AdminService;
use App\Services\QueueService;
use App\Support\Presenter;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/** Semua route di sini dilindungi middleware EnsureAdmin. */
class AdminController extends ApiController
{
    public function __construct(private AdminService $admin)
    {
    }

    public function verify(Request $request): JsonResponse
    {
        return $this->booking($this->admin->verify((string) $request->input('code')));
    }

    public function advance(string $id): JsonResponse
    {
        return $this->booking($this->admin->advance($id));
    }

    public function summary(): JsonResponse
    {
        return response()->json($this->admin->summary());
    }

    public function reviews(): JsonResponse
    {
        $pos = QueueService::positions();

        return response()->json(
            $this->admin->reviews()->map(fn (Booking $b) => Presenter::booking($b, $pos[$b->id] ?? 0))->values()
        );
    }

    public function overview(): JsonResponse
    {
        return response()->json($this->admin->overview());
    }

    private function booking(Booking $b): JsonResponse
    {
        return response()->json(Presenter::booking($b, QueueService::positions()[$b->id] ?? 0));
    }
}

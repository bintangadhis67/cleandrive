<?php

namespace App\Http\Controllers\Api;

use App\Models\AppNotification;
use App\Services\ReminderService;
use App\Support\Presenter;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends ApiController
{
    /** Terbaru di atas. Pengingat jadwal dibuat otomatis saat daftar dibuka. */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        ReminderService::generate($user);

        $list = AppNotification::where('user_id', $user->id)
            ->orderByDesc('created_at')->orderByDesc('id')->limit(200)->get();

        return response()->json($list->map(fn (AppNotification $n) => Presenter::notification($n))->values());
    }

    public function read(Request $request, string $id): JsonResponse
    {
        AppNotification::where('user_id', $request->user()->id)->where('id', $id)->update(['is_read' => true]);

        return response()->json(['message' => 'OK']);
    }

    public function readAll(Request $request): JsonResponse
    {
        AppNotification::where('user_id', $request->user()->id)->where('is_read', false)->update(['is_read' => true]);

        return response()->json(['message' => 'OK']);
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        AppNotification::where('user_id', $request->user()->id)->where('id', $id)->delete();

        return response()->json(['message' => 'OK']);
    }
}

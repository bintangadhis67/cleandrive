<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BookingController;
use App\Http\Controllers\Api\CatalogController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Middleware\ForceJsonResponse;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API CleanDrive (prefix otomatis /api)
|--------------------------------------------------------------------------
| Tiap tahap pengerjaan menambah endpoint di sini, mengikuti method di lib/data/repository.dart.
*/

Route::middleware(ForceJsonResponse::class)->group(function () {
    Route::get('health', fn () => ['status' => 'ok', 'time' => now()->format('Y-m-d\TH:i:s')]);

    // Dipanggil middleware auth saat token tidak valid. Tanpa route bernama "login" Laravel membalas
    // error 500 "Route [login] not defined"; dengan ini balasannya 401 JSON, yang dibaca Flutter sebagai sesi habis.
    Route::get('login', fn () => response()->json(['message' => 'Unauthenticated.'], 401))->name('login');

    // ---- tanpa login ----
    Route::post('auth/register', [AuthController::class, 'register'])->middleware('throttle:10,1');
    Route::post('auth/login', [AuthController::class, 'login'])->middleware('throttle:10,1');

    // ---- wajib login (Authorization: Bearer <token>) ----
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('auth/logout', [AuthController::class, 'logout']);
        Route::get('me', [AuthController::class, 'me']);
        Route::put('me', [AuthController::class, 'updateProfile']);
        Route::put('me/password', [AuthController::class, 'changePassword']);

        Route::get('products', [CatalogController::class, 'products']);
        Route::get('stocks', [CatalogController::class, 'stocks']);
        Route::get('ratings/summary', [CatalogController::class, 'ratingSummary']);

        // ---- pesanan ----
        Route::get('bookings', [BookingController::class, 'index']);
        Route::get('bookings/slots', [BookingController::class, 'slots']); // harus di atas bookings/{id}
        Route::post('bookings', [BookingController::class, 'store']);
        Route::get('bookings/{id}', [BookingController::class, 'show'])->whereNumber('id');
        Route::post('bookings/{id}/cancel', [BookingController::class, 'cancel'])->whereNumber('id');
        Route::post('bookings/{id}/review', [BookingController::class, 'review'])->whereNumber('id');

        // ---- pembayaran (sandbox) ----
        Route::post('payments', [PaymentController::class, 'store']);
        Route::get('payments/{id}', [PaymentController::class, 'show'])->whereNumber('id');
        Route::post('payments/{id}/confirm', [PaymentController::class, 'confirm'])->whereNumber('id');
        Route::post('payments/{id}/simulate-qris', [PaymentController::class, 'simulateQris'])->whereNumber('id');
    });
});

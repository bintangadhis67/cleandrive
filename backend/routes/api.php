<?php

use App\Http\Controllers\Api\AdminCatalogController;
use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BookingController;
use App\Http\Controllers\Api\CatalogController;
use App\Http\Controllers\Api\GarageController;
use App\Http\Controllers\Api\LoyaltyController;
use App\Http\Controllers\Api\MediaController;
use App\Http\Controllers\Api\MembershipController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\VoucherController;
use App\Http\Middleware\EnsureAdmin;
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
    // Foto produk (terbuka untuk umum, nama file dibatasi oleh pola di bawah).
    Route::get('media/{path}', [MediaController::class, 'show'])->where('path', 'products/[A-Za-z0-9_-]+\.(?:png|jpg|jpeg|webp)');
    Route::post('auth/register', [AuthController::class, 'register'])->middleware('throttle:10,1');
    Route::post('auth/login', [AuthController::class, 'login'])->middleware('throttle:10,1');

    // ---- wajib login (Authorization: Bearer <token>) ----
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('auth/logout', [AuthController::class, 'logout']);
        Route::get('me', [AuthController::class, 'me']);
        Route::put('me', [AuthController::class, 'updateProfile']);
        Route::put('me/password', [AuthController::class, 'changePassword']);

        Route::get('products', [CatalogController::class, 'products']);
        Route::get('catalog', [CatalogController::class, 'catalog']);
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

        // ---- voucher ----
        Route::get('vouchers', [VoucherController::class, 'index']);
        Route::get('vouchers/quota', [VoucherController::class, 'quota']); // harus di atas vouchers/{id}
        Route::post('vouchers/{id}/claim', [VoucherController::class, 'claim'])->whereNumber('id');

        // ---- Coins ----
        Route::get('loyalty', [LoyaltyController::class, 'show']);
        Route::post('loyalty/check-in', [LoyaltyController::class, 'checkIn']);
        Route::post('loyalty/promos/{id}/claim', [LoyaltyController::class, 'claimPromo'])->where('id', '[A-Za-z0-9\-]+');

        // ---- membership (sandbox) ----
        Route::get('membership', [MembershipController::class, 'show']);
        Route::post('membership/purchase', [MembershipController::class, 'purchase'])->middleware('throttle:20,1');
        Route::post('membership/cancel', [MembershipController::class, 'cancel']);
        Route::get('membership/orders/{id}', [MembershipController::class, 'order'])->whereNumber('id');
        Route::post('membership/orders/{id}/confirm', [MembershipController::class, 'confirm'])->whereNumber('id');
        Route::post('membership/orders/{id}/simulate-qris', [MembershipController::class, 'simulateQris'])->whereNumber('id');
        Route::delete('membership/orders/{id}', [MembershipController::class, 'cancelOrder'])->whereNumber('id');

        // ---- garasi kendaraan ----
        Route::get('garage', [GarageController::class, 'index']);
        Route::post('garage', [GarageController::class, 'store']);
        Route::put('garage/{id}', [GarageController::class, 'update'])->whereNumber('id');
        Route::delete('garage/{id}', [GarageController::class, 'destroy'])->whereNumber('id');

        // ---- notifikasi ----
        Route::get('notifications', [NotificationController::class, 'index']);
        Route::post('notifications/read-all', [NotificationController::class, 'readAll']);
        Route::post('notifications/{id}/read', [NotificationController::class, 'read'])->whereNumber('id');
        Route::delete('notifications/{id}', [NotificationController::class, 'destroy'])->whereNumber('id');

        // ---- admin (khusus role admin) ----
        Route::middleware(EnsureAdmin::class)->prefix('admin')->group(function () {
            Route::post('verify', [AdminController::class, 'verify']);
            Route::post('bookings/{id}/advance', [AdminController::class, 'advance'])->whereNumber('id');
            Route::get('summary', [AdminController::class, 'summary']);
            Route::get('reviews', [AdminController::class, 'reviews']);
            Route::get('overview', [AdminController::class, 'overview']);

            // Katalog: foto produk dikirim sebagai file (multipart). Ubah memakai POST karena PHP tidak membaca file dari PUT.
            Route::post('products', [AdminCatalogController::class, 'store']);
            Route::post('products/{id}', [AdminCatalogController::class, 'update'])->where('id', '[A-Za-z0-9]+');
            Route::delete('products/{id}', [AdminCatalogController::class, 'destroy'])->where('id', '[A-Za-z0-9]+');
        });
    });
});

<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CatalogController;
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
    });
});

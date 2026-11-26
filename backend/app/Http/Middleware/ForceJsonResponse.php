<?php

namespace App\Http\Middleware;

use App\Services\RewardSettings;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Semua route API selalu dijawab JSON (termasuk error 401/404), walau klien lupa mengirim header Accept.
 * Sekaligus menimpakan pengaturan reward buatan admin (tabel settings) ke config('cleandrive').
 */
class ForceJsonResponse
{
    public function handle(Request $request, Closure $next): Response
    {
        $request->headers->set('Accept', 'application/json');
        RewardSettings::apply();

        return $next($request);
    }
}

<?php

namespace App\Exceptions;

use Illuminate\Http\JsonResponse;
use RuntimeException;

/**
 * Kesalahan yang pesannya boleh ditampilkan ke pengguna (Flutter: ApiException).
 * Cukup `throw new ApiException('Slot jam 10:00 sudah penuh.')`, Laravel otomatis membalas {"message": "..."}.
 */
class ApiException extends RuntimeException
{
    public function __construct(string $message, private int $status = 422)
    {
        parent::__construct($message);
    }

    /** Kosong = tidak dicatat sebagai error di storage/logs (ini kesalahan input biasa, bukan bug). */
    public function report(): void
    {
    }

    public function render($request): JsonResponse
    {
        return response()->json(['message' => $this->getMessage()], $this->status);
    }
}

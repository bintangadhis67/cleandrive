<?php

namespace App\Services;

use App\Models\AppNotification;

class NotifyService
{
    /** type: order | payment | points | voucher | membership | promo | reminder */
    public static function send(int $userId, string $type, string $title, string $body, ?string $target = null, bool $push = true): AppNotification
    {
        return AppNotification::create([
            'user_id' => $userId,
            'type' => $type,
            'title' => $title,
            'body' => $body,
            'target' => $target,
            'push' => $push,
        ]);
    }
}

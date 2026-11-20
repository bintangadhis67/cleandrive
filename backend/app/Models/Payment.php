<?php

namespace App\Models;

use App\Models\Concerns\SerializesDatesLocal;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Payment extends Model
{
    use SerializesDatesLocal;

    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'expires_at' => 'datetime',
            'paid_at' => 'datetime',
            'sandbox' => 'boolean',
            'amount' => 'integer',
            'coins_used' => 'integer',
            'coin_discount' => 'integer',
            'coins_earned' => 'integer',
            'balance' => 'integer',
        ];
    }

    public function booking(): BelongsTo
    {
        return $this->belongsTo(Booking::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}

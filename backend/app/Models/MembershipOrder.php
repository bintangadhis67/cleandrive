<?php

namespace App\Models;

use App\Models\Concerns\SerializesDatesLocal;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MembershipOrder extends Model
{
    use SerializesDatesLocal;

    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'expires_at' => 'datetime',
            'paid_at' => 'datetime',
            'renewal' => 'boolean',
            'sandbox' => 'boolean',
            'amount' => 'integer',
            'balance' => 'integer',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}

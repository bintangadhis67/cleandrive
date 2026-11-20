<?php

namespace App\Models;

use App\Models\Concerns\SerializesDatesLocal;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Membership extends Model
{
    use SerializesDatesLocal;

    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'start_date' => 'datetime',
            'end_date' => 'datetime',
            'cancel_at_end' => 'boolean',
            'free_weeks' => 'array',
            'free_total' => 'integer',
            'free_used' => 'integer',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function isActive(): bool
    {
        return $this->status === 'active' && $this->end_date !== null && $this->end_date->isFuture();
    }
}

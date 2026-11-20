<?php

namespace App\Models;

use App\Models\Concerns\SerializesDatesLocal;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Booking extends Model
{
    use SerializesDatesLocal;

    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'slot' => 'datetime',
            'est_finish' => 'datetime',
            'verified_at' => 'datetime',
            'cancelled_at' => 'datetime',
            'perks' => 'array',
            'free_wash' => 'boolean',
            'verified' => 'boolean',
            'cancelled' => 'boolean',
            'price' => 'integer',
            'discount' => 'integer',
            'member_discount' => 'integer',
            'coins_used' => 'integer',
            'coin_discount' => 'integer',
            'coins_earned' => 'integer',
            'status' => 'integer',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function items(): HasMany
    {
        return $this->hasMany(BookingItem::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class);
    }

    public function review(): HasOne
    {
        return $this->hasOne(Review::class);
    }

    /** Total yang harus dibayar. */
    public function total(): int
    {
        return $this->price - $this->discount - $this->member_discount - $this->coin_discount;
    }
}

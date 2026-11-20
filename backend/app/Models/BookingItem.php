<?php

namespace App\Models;

use App\Models\Concerns\SerializesDatesLocal;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BookingItem extends Model
{
    use SerializesDatesLocal;

    protected $guarded = [];

    protected function casts(): array
    {
        return ['qty' => 'integer', 'price' => 'integer'];
    }

    public function booking(): BelongsTo
    {
        return $this->belongsTo(Booking::class);
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }
}

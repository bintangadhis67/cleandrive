<?php

namespace App\Models;

use App\Models\Concerns\SerializesDatesLocal;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CoinPromoClaim extends Model
{
    use SerializesDatesLocal;

    protected $guarded = [];

    protected function casts(): array
    {
        return ['coins' => 'integer'];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}

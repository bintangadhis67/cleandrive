<?php

namespace App\Models;

use App\Models\Concerns\SerializesDatesLocal;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Voucher extends Model
{
    use SerializesDatesLocal;

    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'terms' => 'array',
            'weekly' => 'boolean',
            'is_active' => 'boolean',
            'amount' => 'integer',
            'percent' => 'integer',
            'max_discount' => 'integer',
            'min_transaction' => 'integer',
            'valid_days' => 'integer',
            'min_tier' => 'integer',
        ];
    }

    public function claims(): HasMany
    {
        return $this->hasMany(VoucherClaim::class);
    }

    /** Potongan untuk harga tertentu (sama dengan Voucher.discountFor di Flutter). */
    public function discountFor(int $price): int
    {
        if ($price < $this->min_transaction) {
            return 0;
        }
        if ($this->amount > 0) {
            return min($this->amount, $price);
        }
        $d = intdiv($price * $this->percent, 100);
        if ($this->max_discount > 0 && $d > $this->max_discount) {
            $d = $this->max_discount;
        }
        return $d;
    }
}

<?php

namespace App\Models;

use App\Models\Concerns\SerializesDatesLocal;
use Illuminate\Database\Eloquent\Model;

class MembershipPlan extends Model
{
    use SerializesDatesLocal;

    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'benefits' => 'array',
            'free_vehicles' => 'array',
            'popular' => 'boolean',
            'snack' => 'boolean',
            'vip' => 'boolean',
            'massage' => 'boolean',
            'is_active' => 'boolean',
            'price' => 'integer',
            'duration_days' => 'integer',
            'discount_pct' => 'integer',
            'free_wash_quota' => 'integer',
        ];
    }

    /** Peringkat voucher: bronze 1, silver 2, gold 3, platinum 4. */
    public static function rankOf(string $tier): int
    {
        $i = array_search($tier, ['bronze', 'silver', 'gold', 'platinum'], true);
        return $i === false ? 0 : $i + 1;
    }
}

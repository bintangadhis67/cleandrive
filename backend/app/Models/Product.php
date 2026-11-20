<?php

namespace App\Models;

use App\Models\Concerns\SerializesDatesLocal;
use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    use SerializesDatesLocal;

    public $incrementing = false;
    protected $keyType = 'string';
    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'price' => 'integer',
            'stock' => 'integer',
            'vehicles' => 'array',
            'is_active' => 'boolean',
        ];
    }

    /** Cocok untuk kendaraan ini? (kosong = semua) */
    public function fits(string $vehicle): bool
    {
        $v = $this->vehicles ?? [];
        return empty($v) || in_array($vehicle, $v, true);
    }
}

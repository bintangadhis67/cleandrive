<?php

namespace App\Models;

use App\Models\Concerns\SerializesDatesLocal;
use Illuminate\Database\Eloquent\Model;

class WashPackage extends Model
{
    use SerializesDatesLocal;

    protected $guarded = [];

    protected function casts(): array
    {
        return [
            'base_price' => 'integer',
            'minutes' => 'integer',
            'prices' => 'array',
            'is_active' => 'boolean',
        ];
    }

    /** Harga jasa untuk jenis kendaraan: harga khusus bila ada, selain itu harga dasar x faktor (motor 1, mobil 2). */
    public function priceFor(string $vehicle): int
    {
        $special = $this->prices[$vehicle] ?? null;
        if ($special !== null) {
            return (int) $special;
        }
        return (int) round($this->base_price * ($vehicle === 'mobil' ? 2.0 : 1.0));
    }
}

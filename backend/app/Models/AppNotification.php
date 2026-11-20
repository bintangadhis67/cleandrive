<?php

namespace App\Models;

use App\Models\Concerns\SerializesDatesLocal;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AppNotification extends Model
{
    use SerializesDatesLocal;

    protected $guarded = [];

    protected function casts(): array
    {
        return ['push' => 'boolean', 'is_read' => 'boolean'];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}

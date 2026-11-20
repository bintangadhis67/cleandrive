<?php

namespace App\Support;

use App\Models\Product;
use App\Models\User;

/**
 * Mengubah model menjadi array JSON dengan nama kunci yang dibaca model Flutter (snake_case).
 */
class Presenter
{
    /** Dibaca SessionUser.fromJson di Flutter: name, email, phone, role. */
    public static function user(User $u): array
    {
        return [
            'id' => $u->id,
            'name' => $u->name,
            'email' => $u->email,
            'phone' => $u->phone ?? '',
            'role' => $u->role,
        ];
    }

    public static function product(Product $p): array
    {
        return [
            'id' => $p->id,
            'name' => $p->name,
            'description' => $p->description,
            'details' => $p->details,
            'price' => (int) $p->price,
            'category' => $p->category,
            'image' => $p->image,
            'stock' => (int) $p->stock,
            'vehicles' => $p->vehicles ?? [],
        ];
    }
}

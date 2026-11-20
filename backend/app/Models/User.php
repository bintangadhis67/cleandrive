<?php

namespace App\Models;

use App\Models\Concerns\SerializesDatesLocal;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, SerializesDatesLocal;

    protected $fillable = [
        'name', 'email', 'phone', 'role', 'password', 'last_check_in', 'streak',
    ];

    protected $hidden = [
        'password', 'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'last_check_in' => 'datetime',
            'streak' => 'integer',
        ];
    }

    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }

    public function vehicles(): HasMany
    {
        return $this->hasMany(Vehicle::class);
    }

    public function bookings(): HasMany
    {
        return $this->hasMany(Booking::class);
    }

    public function coinEntries(): HasMany
    {
        return $this->hasMany(CoinEntry::class);
    }

    public function membership(): HasOne
    {
        return $this->hasOne(Membership::class);
    }

    public function appNotifications(): HasMany
    {
        return $this->hasMany(AppNotification::class);
    }

    /** Saldo Coins = jumlah seluruh catatan (positif dan negatif). */
    public function coinBalance(): int
    {
        return (int) $this->coinEntries()->sum('amount');
    }
}

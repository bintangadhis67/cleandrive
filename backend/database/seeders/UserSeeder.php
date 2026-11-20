<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;

class UserSeeder extends Seeder
{
    /** Akun demo, sama dengan MockRepository di Flutter. */
    public function run(): void
    {
        User::updateOrCreate(
            ['email' => 'admin@cleandrive.com'],
            ['name' => 'Admin CleanDrive', 'phone' => '', 'role' => 'admin', 'password' => 'admin123'],
        );

        User::updateOrCreate(
            ['email' => 'budi@mail.com'],
            ['name' => 'Budi Santoso', 'phone' => '081200000002', 'role' => 'customer', 'password' => '123456'],
        );
    }
}

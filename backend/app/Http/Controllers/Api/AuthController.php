<?php

namespace App\Http\Controllers\Api;

use App\Models\AppNotification;
use App\Models\User;
use App\Support\Presenter;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends ApiController
{
    /** Sama dengan validator di lib/screens/auth/auth.dart. */
    private const PHONE_RULE = '/^(\+62|62|0)8[0-9]{7,12}$/';

    public function register(Request $request): JsonResponse
    {
        $name = trim((string) $request->input('name'));
        $email = strtolower(trim((string) $request->input('email')));
        $phone = trim((string) $request->input('phone'));
        $password = (string) $request->input('password');

        if ($name === '') {
            return $this->fail('Nama wajib diisi.');
        }
        if (! filter_var($email, FILTER_VALIDATE_EMAIL) || ! str_contains($email, '.')) {
            return $this->fail('Format email tidak valid.');
        }
        if (! preg_match(self::PHONE_RULE, $phone)) {
            return $this->fail('Nomor HP tidak valid.');
        }
        if (strlen($password) < 6) {
            return $this->fail('Password minimal 6 karakter.');
        }
        if (User::where('email', $email)->exists()) {
            return $this->fail('Email sudah terdaftar. Gunakan email lain atau masuk.');
        }

        $user = User::create([
            'name' => $name,
            'email' => $email,
            'phone' => $phone,
            'role' => 'customer',
            'password' => $password, // di-hash otomatis oleh cast "hashed"
        ]);

        AppNotification::create([
            'user_id' => $user->id,
            'type' => 'promo',
            'title' => 'Selamat datang di CleanDrive!',
            'body' => 'Klaim Bonus Selamat Datang dan mulai check-in harian untuk kumpulkan Coins.',
            'target' => 'loyalty',
            'push' => false,
        ]);

        return response()->json([
            'token' => $user->createToken('flutter')->plainTextToken,
            'user' => Presenter::user($user),
        ], 201);
    }

    public function login(Request $request): JsonResponse
    {
        $email = strtolower(trim((string) $request->input('email')));
        $password = (string) $request->input('password');

        $user = User::where('email', $email)->first();
        if (! $user || ! Hash::check($password, $user->password)) {
            return $this->fail('Email atau password salah');
        }

        return response()->json([
            'token' => $user->createToken('flutter')->plainTextToken,
            'user' => Presenter::user($user),
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Berhasil keluar']);
    }

    /** Dipakai Flutter untuk memulihkan sesi saat aplikasi dibuka (Repository.restore). */
    public function me(Request $request): JsonResponse
    {
        return response()->json(Presenter::user($request->user()));
    }

    public function updateProfile(Request $request): JsonResponse
    {
        $name = trim((string) $request->input('name'));
        $phone = trim((string) $request->input('phone'));

        if ($name === '') {
            return $this->fail('Nama wajib diisi.');
        }
        if ($phone !== '' && ! preg_match(self::PHONE_RULE, $phone)) {
            return $this->fail('Nomor HP tidak valid.');
        }

        $user = $request->user();
        $user->update(['name' => $name, 'phone' => $phone]);

        return response()->json(Presenter::user($user->fresh()));
    }

    public function changePassword(Request $request): JsonResponse
    {
        $old = (string) $request->input('old_password');
        $new = (string) $request->input('new_password');
        $user = $request->user();

        if (! Hash::check($old, $user->password)) {
            return $this->fail('Password lama salah');
        }
        if (strlen($new) < 6) {
            return $this->fail('Password baru minimal 6 karakter.');
        }

        $user->update(['password' => $new]);

        // Perangkat lain harus login ulang; perangkat ini tetap masuk.
        $user->tokens()->where('id', '!=', $user->currentAccessToken()->id)->delete();

        return response()->json(['message' => 'Password berhasil diubah']);
    }
}

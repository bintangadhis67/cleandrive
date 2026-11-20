<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('voucher_claims', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('voucher_id')->constrained()->cascadeOnDelete();
            // Voucher mingguan: kunci minggu (tanggal Senin, mis. 20261116). Voucher sekali-per-akun: string kosong.
            // Dibuat default '' (bukan NULL) supaya unique index bekerja untuk voucher sekali-per-akun.
            $table->string('week_key', 8)->default('');
            $table->boolean('used')->default(false);
            $table->foreignId('used_booking_id')->nullable()->constrained('bookings')->nullOnDelete();
            $table->dateTime('used_at')->nullable();
            $table->timestamps(); // created_at = waktu klaim (dipakai untuk kuota klaim harian)

            $table->unique(['user_id', 'voucher_id', 'week_key']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('voucher_claims');
    }
};

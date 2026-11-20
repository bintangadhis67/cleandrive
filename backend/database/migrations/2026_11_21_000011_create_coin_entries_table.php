<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('coin_entries', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('kind', 20); // checkin | transaction | review | promo | redeem | refund
            $table->string('title', 120);
            $table->string('note', 255)->default('');
            $table->integer('amount'); // positif = dapat, negatif = dipakai/ditarik kembali
            $table->foreignId('booking_id')->nullable()->constrained()->nullOnDelete();
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('coin_entries');
    }
};

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->string('trx', 40)->unique();
            $table->foreignId('booking_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('method', 20);                 // qris | gopay | ovo | dana | shopeepay | livin
            $table->unsignedInteger('amount');            // total yang dibayar (setelah Coins)
            $table->unsignedInteger('coins_used')->default(0);
            $table->unsignedInteger('coin_discount')->default(0);
            $table->string('status', 12)->default('pending'); // pending | paid | expired
            $table->dateTime('expires_at');
            $table->text('qr_string')->nullable();
            $table->unsignedInteger('balance')->nullable(); // saldo simulasi e-wallet (sandbox)
            $table->boolean('sandbox')->default(true);
            $table->unsignedInteger('coins_earned')->default(0);
            $table->dateTime('paid_at')->nullable();
            $table->timestamps();

            $table->index(['status', 'expires_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};

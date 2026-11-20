<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('coin_promo_claims', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('promo_id', 40); // welcome | profile | first | monthly-2026-11
            $table->unsignedInteger('coins');
            $table->timestamps();

            $table->unique(['user_id', 'promo_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('coin_promo_claims');
    }
};

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('vouchers', function (Blueprint $table) {
            $table->id();
            $table->string('code', 40)->unique();
            $table->string('title', 100);
            $table->unsignedInteger('amount')->default(0);          // potongan tetap (Rp), 0 bila persen
            $table->unsignedTinyInteger('percent')->default(0);     // potongan persen, 0 bila tetap
            $table->unsignedInteger('max_discount')->default(0);    // batas potongan persen, 0 = tanpa batas
            $table->unsignedInteger('min_transaction')->default(0);
            $table->unsignedSmallInteger('valid_days')->default(30);
            $table->json('terms')->nullable();
            $table->unsignedTinyInteger('min_tier')->default(0);    // 0 semua, 1 Bronze, 2 Silver, 3 Gold, 4 Platinum
            $table->boolean('weekly')->default(false);              // true = diperbarui tiap Senin
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('vouchers');
    }
};

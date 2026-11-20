<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('membership_plans', function (Blueprint $table) {
            $table->id();
            $table->string('tier', 10)->unique(); // bronze | silver | gold | platinum
            $table->unsignedInteger('price');
            $table->unsignedSmallInteger('duration_days')->default(30);
            $table->unsignedTinyInteger('discount_pct')->default(0);
            $table->string('priority', 60)->default('');
            $table->json('benefits')->nullable();
            $table->string('promo', 120)->default('');
            $table->boolean('popular')->default(false);
            $table->string('free_package', 30)->default('');  // Express | Reguler | Detailing | ''
            $table->unsignedSmallInteger('free_wash_quota')->default(0);
            $table->json('free_vehicles')->nullable();         // ["motor","mobil"]
            $table->boolean('snack')->default(false);
            $table->boolean('vip')->default(false);
            $table->boolean('massage')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('membership_plans');
    }
};

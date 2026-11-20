<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('memberships', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete(); // satu per pengguna
            $table->string('tier', 10);
            $table->string('status', 12)->default('active'); // active | expired | cancelled
            $table->dateTime('start_date')->nullable();
            $table->dateTime('end_date')->nullable();
            $table->boolean('cancel_at_end')->default(false);
            $table->unsignedSmallInteger('free_total')->default(0);
            $table->unsignedSmallInteger('free_used')->default(0);
            $table->json('free_weeks')->nullable(); // kunci minggu yang jatah cuci gratisnya terpakai
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('memberships');
    }
};

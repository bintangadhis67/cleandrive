<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('vehicles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('type', 10); // motor | mobil
            $table->string('brand', 60);
            $table->string('model', 60);
            $table->unsignedSmallInteger('year');
            $table->string('color', 40)->default('');
            $table->string('plate', 20);
            $table->timestamps();

            $table->index(['user_id', 'plate']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('vehicles');
    }
};

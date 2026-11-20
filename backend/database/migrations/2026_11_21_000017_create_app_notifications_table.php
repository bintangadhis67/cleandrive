<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Nama "app_notifications" supaya tidak bentrok dengan tabel "notifications" bawaan Laravel.
        Schema::create('app_notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('type', 20); // order | payment | points | voucher | membership | promo | reminder
            $table->string('title', 150);
            $table->string('body', 500)->default('');
            $table->string('target', 60)->nullable(); // order:<id> | vouchers | loyalty | membership | shop
            $table->boolean('push')->default(true);
            $table->boolean('is_read')->default(false); // di JSON dikirim sebagai "read"
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('app_notifications');
    }
};

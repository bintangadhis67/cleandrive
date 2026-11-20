<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('membership_orders', function (Blueprint $table) {
            $table->id();
            $table->string('trx', 40)->unique();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('tier', 10);
            $table->unsignedInteger('amount');
            $table->string('method', 20);
            $table->boolean('renewal')->default(false);
            $table->string('status', 12)->default('pending'); // pending | paid | expired | cancelled
            $table->dateTime('expires_at');
            $table->text('qr_string')->nullable();
            $table->unsignedInteger('balance')->nullable();
            $table->boolean('sandbox')->default(true);
            $table->dateTime('paid_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('membership_orders');
    }
};

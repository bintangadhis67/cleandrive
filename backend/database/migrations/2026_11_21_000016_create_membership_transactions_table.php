<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('membership_transactions', function (Blueprint $table) {
            $table->id();
            $table->string('trx', 40);
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('tier', 10);
            $table->unsignedInteger('amount');
            $table->string('method', 20);
            $table->boolean('renewal')->default(false);
            $table->boolean('refund')->default(false); // true = pengembalian dana karena langganan dibatalkan
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('membership_transactions');
    }
};

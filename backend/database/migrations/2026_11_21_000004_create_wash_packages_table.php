<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('wash_packages', function (Blueprint $table) {
            $table->id();
            $table->string('name', 40)->unique(); // Express | Reguler | Detailing | Ganti Oli | Pembelian Toko
            $table->string('description', 255)->default('');
            $table->string('kind', 10)->default('wash'); // wash | oil | shop
            $table->unsignedInteger('base_price')->default(0);
            $table->unsignedSmallInteger('minutes')->default(30);
            $table->json('prices')->nullable(); // harga khusus per kendaraan, mis. {"motor":100000,"mobil":250000}
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('wash_packages');
    }
};

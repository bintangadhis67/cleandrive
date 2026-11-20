<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('products', function (Blueprint $table) {
            // ID teks (mk1, mn3, ol1, ...) harus sama dengan ID di lib/models/catalog.dart,
            // karena Booking.fromJson di Flutter mencari produk lewat ID ini.
            $table->string('id', 20)->primary();
            $table->string('name', 120);
            $table->string('description', 255)->default('');
            $table->text('details')->nullable();
            $table->unsignedInteger('price');
            $table->string('category', 20); // makanan | minuman | oli
            $table->string('image', 255)->default('');
            $table->unsignedInteger('stock')->default(0);
            $table->json('vehicles')->nullable(); // khusus oli: ["motor"] / ["mobil"], kosong = semua
            $table->unsignedSmallInteger('sort')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->index('category');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('products');
    }
};

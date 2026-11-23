<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Gambar produk disimpan di tabel terpisah supaya daftar produk (tabel products) tetap ringan
        // dan tidak ikut membaca isi gambar setiap kali dimuat.
        Schema::create('product_images', function (Blueprint $table) {
            $table->string('product_id', 20)->primary();
            $table->string('mime', 40);                  // image/webp, image/png, image/jpeg
            $table->string('hash', 32);                  // md5 isi gambar: dipakai sebagai ETag dan penanda versi
            $table->unsignedInteger('size');             // ukuran dalam byte
            $table->timestamps();

            $table->foreign('product_id')->references('id')->on('products')->cascadeOnDelete();
        });

        // Isi gambar (biner) langsung di MySQL. MEDIUMBLOB menampung sampai 16 MB per gambar.
        DB::statement('ALTER TABLE product_images ADD data MEDIUMBLOB NOT NULL AFTER mime');
    }

    public function down(): void
    {
        Schema::dropIfExists('product_images');
    }
};

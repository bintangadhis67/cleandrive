<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('bookings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('code', 60)->unique();          // CD-0001-L1234AB
            $table->string('plate', 20)->default('-');     // '-' untuk pembelian toko
            $table->string('vehicle', 10)->default('mobil'); // motor | mobil
            $table->string('package', 40);                 // nama paket (wash_packages.name)
            $table->dateTime('slot');
            $table->dateTime('est_finish');

            // Harga jasa + produk, sebelum potongan. Total = price - discount - member_discount - coin_discount.
            $table->unsignedInteger('price')->default(0);
            $table->unsignedInteger('discount')->default(0);          // potongan voucher
            $table->unsignedInteger('member_discount')->default(0);   // potongan membership
            $table->string('member_label', 40)->nullable();           // mis. "Gold 20%"
            $table->string('voucher_code', 40)->nullable();
            $table->boolean('free_wash')->default(false);             // pakai jatah cuci gratis membership
            $table->string('free_week_key', 8)->nullable();           // minggu yang jatahnya terpakai
            $table->json('perks')->nullable();                        // benefit membership kunjungan ini
            $table->unsignedInteger('coins_used')->default(0);
            $table->unsignedInteger('coin_discount')->default(0);
            $table->unsignedInteger('coins_earned')->default(0);

            $table->unsignedTinyInteger('status')->default(0);        // 0 menunggu, 1 proses, 2 finishing, 3 selesai
            $table->boolean('verified')->default(false);
            $table->dateTime('verified_at')->nullable();
            $table->boolean('cancelled')->default(false);
            $table->dateTime('cancelled_at')->nullable();
            $table->string('pay_status', 12)->default('unpaid');      // unpaid | paid | refunded
            $table->string('pay_method', 20)->nullable();
            $table->string('trx', 40)->nullable();
            $table->timestamps();

            $table->index('slot');
            $table->index(['user_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('bookings');
    }
};

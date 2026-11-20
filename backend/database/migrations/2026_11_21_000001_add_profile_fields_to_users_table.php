<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('phone', 20)->default('')->after('email');
            $table->string('role', 20)->default('customer')->after('phone'); // customer | admin
            $table->dateTime('last_check_in')->nullable()->after('role');
            $table->unsignedInteger('streak')->default(0)->after('last_check_in');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['phone', 'role', 'last_check_in', 'streak']);
        });
    }
};

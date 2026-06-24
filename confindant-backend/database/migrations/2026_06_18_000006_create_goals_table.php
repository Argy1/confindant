<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('goals', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->decimal('target_amount', 20, 4);
            $table->decimal('current_amount', 20, 4)->default(0);
            $table->string('target_date_label');
            $table->string('linked_wallet');
            $table->jsonb('contributions')->nullable();
            $table->boolean('auto_topup_enabled')->default(false);
            $table->decimal('auto_topup_percent', 5, 2)->default(0);
            $table->timestamps();

            $table->index('user_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('goals');
    }
};

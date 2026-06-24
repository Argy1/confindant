<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('recurring_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('wallet_id')->constrained()->cascadeOnDelete();
            $table->string('type');
            $table->string('source')->nullable();
            $table->string('category')->nullable();
            $table->decimal('amount', 20, 4);
            $table->string('merchant_name')->nullable();
            $table->text('notes')->nullable();
            $table->boolean('is_verified')->default(true);
            $table->jsonb('tags')->nullable();
            $table->string('frequency'); // daily|weekly|monthly
            $table->integer('interval')->default(1);
            $table->timestamp('start_date');
            $table->timestamp('next_run_at')->nullable();
            $table->timestamp('last_run_at')->nullable();
            $table->timestamp('end_date')->nullable();
            $table->boolean('active')->default(true);
            $table->integer('total_runs')->default(0);
            $table->string('last_error_code')->nullable();
            $table->text('last_error_message')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'active', 'next_run_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('recurring_transactions');
    }
};

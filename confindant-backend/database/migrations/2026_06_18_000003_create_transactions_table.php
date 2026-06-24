<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('wallet_id')->constrained()->cascadeOnDelete();
            $table->string('type'); // income | expense
            $table->string('source')->nullable();
            $table->string('category')->nullable();
            $table->decimal('total_amount', 20, 4)->default(0);
            $table->decimal('tax_amount', 20, 4)->nullable();
            $table->decimal('service_amount', 20, 4)->nullable();
            $table->string('need_want')->nullable(); // needs|wants|mixed|unknown
            $table->timestamp('date');
            $table->string('merchant_name')->nullable();
            $table->text('receipt_image_url')->nullable();
            $table->text('notes')->nullable();
            $table->boolean('is_verified')->default(false);
            $table->jsonb('items')->nullable();
            $table->string('ocr_status')->default('none');
            $table->decimal('ocr_confidence', 5, 4)->nullable();
            $table->jsonb('ocr_raw')->nullable();
            $table->boolean('is_internal_transfer')->default(false);
            $table->string('transfer_group_id')->nullable();
            $table->jsonb('tags')->nullable();
            $table->string('ai_category')->nullable();
            $table->decimal('ai_confidence', 5, 4)->nullable();
            $table->boolean('ai_suggested')->default(false);
            $table->string('ai_provider')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'wallet_id', 'date', 'created_at', 'type', 'is_internal_transfer']);
            $table->index(['user_id', 'ai_category', 'date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('transactions');
    }
};

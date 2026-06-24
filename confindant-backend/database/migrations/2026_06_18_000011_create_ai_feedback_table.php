<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ai_feedback', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->unsignedBigInteger('transaction_id')->nullable();
            $table->jsonb('input_context')->nullable();
            $table->string('suggested_category')->nullable();
            $table->string('final_category')->nullable();
            $table->boolean('accepted')->default(false);
            $table->decimal('confidence', 5, 4)->nullable();
            $table->string('provider')->nullable();
            $table->timestamp('created_at_client')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
            $table->index(['transaction_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_feedback');
    }
};

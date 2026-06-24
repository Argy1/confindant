<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ai_finance_query_history', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->text('query');
            $table->text('answer')->nullable();
            $table->text('insight')->nullable();
            $table->string('locale')->default('id');
            $table->jsonb('period')->nullable();
            $table->jsonb('suggested_actions')->nullable();
            $table->jsonb('metrics')->nullable();
            $table->string('provider')->nullable();
            $table->boolean('fallback')->default(false);
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_finance_query_history');
    }
};

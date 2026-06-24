<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('receipt_ocr_feedback', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->unsignedBigInteger('ocr_job_id')->nullable();
            $table->unsignedBigInteger('transaction_id')->nullable();
            $table->boolean('accepted')->default(false);
            $table->string('source_mode')->nullable();
            $table->jsonb('changed_fields')->nullable();
            $table->integer('edited_field_count')->default(0);
            $table->jsonb('field_confidence')->nullable();
            $table->jsonb('meta')->nullable();
            $table->timestamp('created_at_client')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
            $table->index(['ocr_job_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('receipt_ocr_feedback');
    }
};

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('receipt_ocr_jobs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('status')->default('pending'); // pending|processing|success|failed
            $table->decimal('confidence', 5, 4)->nullable();
            $table->string('error_code')->nullable();
            $table->text('error_message')->nullable();
            $table->text('receipt_image_url')->nullable();
            $table->jsonb('raw')->nullable();
            $table->jsonb('extracted')->nullable();
            $table->timestamp('queued_at')->nullable();
            $table->timestamp('started_at')->nullable();
            $table->timestamp('finished_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
            $table->index(['status', 'updated_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('receipt_ocr_jobs');
    }
};

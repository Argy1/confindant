<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('journal_entries', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->constrained()->cascadeOnDelete();
            $table->foreignId('accounting_period_id')->nullable()->constrained()->nullOnDelete();
            $table->string('entry_number')->nullable(); // JU-2025-0001
            $table->date('date');
            $table->text('description');
            $table->string('reference')->nullable(); // no. bukti / invoice
            $table->string('category')->nullable(); // kategori asli dari Excel (honor, gaji, dll)
            $table->string('classification')->nullable(); // klasifikasi tambahan
            // draft = belum posting, posted = sudah masuk buku besar, void = dibatalkan
            $table->string('status')->default('posted');
            // source: manual | import | recurring | depreciation | transaction
            $table->string('source')->default('manual');
            $table->decimal('total_amount', 20, 4)->default(0); // total debit (= total kredit)
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('posted_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('posted_at')->nullable();
            $table->timestamps();

            $table->index(['organization_id', 'date']);
            $table->index(['organization_id', 'status']);
            $table->index(['organization_id', 'category']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('journal_entries');
    }
};

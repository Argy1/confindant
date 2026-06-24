<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Piutang (receivable) & Hutang (payable). type membedakan keduanya.
        Schema::create('receivables_payables', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->constrained()->cascadeOnDelete();
            $table->string('type'); // receivable | payable
            $table->string('party_name'); // nama anggota / cabang / vendor
            $table->string('category')->nullable(); // Iuran APSR, Iuran ERS, Hutang Pajak, dll
            $table->foreignId('account_id')->nullable()->constrained('accounts')->nullOnDelete();
            $table->string('description')->nullable();
            $table->decimal('original_amount', 20, 4);
            $table->decimal('settled_amount', 20, 4)->default(0);
            $table->decimal('outstanding_amount', 20, 4);
            $table->date('issued_date');
            $table->date('due_date')->nullable();
            // open | partial | settled | written_off
            $table->string('status')->default('open');
            $table->string('period_label')->nullable(); // 2024-2025, 2026, dll (untuk iuran multi-tahun)
            $table->timestamps();

            $table->index(['organization_id', 'type', 'status']);
        });

        // Pelunasan / pembayaran terhadap piutang/hutang
        Schema::create('settlements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('receivable_payable_id')->constrained('receivables_payables')->cascadeOnDelete();
            $table->foreignId('journal_entry_id')->nullable()->constrained()->nullOnDelete();
            $table->date('date');
            $table->decimal('amount', 20, 4);
            $table->string('notes')->nullable();
            $table->timestamps();

            $table->index(['receivable_payable_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('settlements');
        Schema::dropIfExists('receivables_payables');
    }
};

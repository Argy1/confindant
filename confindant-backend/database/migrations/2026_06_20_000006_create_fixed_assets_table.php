<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('fixed_assets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->constrained()->cascadeOnDelete();
            $table->string('name'); // Jenis Aktiva
            $table->string('group')->nullable(); // PERLENGKAPAN | BANGUNAN | TANAH
            $table->date('acquisition_date'); // Bulan/Tahun Perolehan
            $table->decimal('acquisition_cost', 20, 4); // Harga Perolehan
            $table->decimal('depreciation_rate', 6, 4)->default(0); // Tarif, e.g. 0.25 / 0.05
            $table->string('method')->default('straight_line'); // Garis Lurus
            $table->decimal('salvage_value', 20, 4)->default(0);
            // accounts that auto-journaling will hit
            $table->foreignId('asset_account_id')->nullable()->constrained('accounts')->nullOnDelete();
            $table->foreignId('accumulated_depreciation_account_id')->nullable()->constrained('accounts')->nullOnDelete();
            $table->foreignId('depreciation_expense_account_id')->nullable()->constrained('accounts')->nullOnDelete();
            // running figures
            $table->decimal('accumulated_depreciation', 20, 4)->default(0);
            $table->decimal('book_value', 20, 4)->default(0);
            $table->boolean('is_active')->default(true);
            $table->string('notes')->nullable();
            $table->timestamps();

            $table->index(['organization_id', 'group']);
        });

        Schema::create('asset_depreciations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('fixed_asset_id')->constrained()->cascadeOnDelete();
            $table->foreignId('accounting_period_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('journal_entry_id')->nullable()->constrained()->nullOnDelete();
            $table->integer('year');
            $table->decimal('amount', 20, 4); // Penyusutan per periode
            $table->decimal('accumulated_after', 20, 4); // Akumulasi setelah periode ini
            $table->decimal('book_value_after', 20, 4); // Nilai Buku Akhir
            $table->timestamps();

            $table->index(['fixed_asset_id', 'year']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('asset_depreciations');
        Schema::dropIfExists('fixed_assets');
    }
};

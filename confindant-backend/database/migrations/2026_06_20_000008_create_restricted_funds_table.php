<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Dana Titipan Cabang & Dana Titipan Kegiatan Ilmiah (restricted / earmarked funds)
        Schema::create('restricted_funds', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->constrained()->cascadeOnDelete();
            $table->string('name'); // "Dana Titipan Cabang - Jakarta", dll
            $table->string('fund_type')->nullable(); // titipan_cabang | titipan_kegiatan | shu
            $table->foreignId('account_id')->nullable()->constrained('accounts')->nullOnDelete();
            $table->decimal('balance', 20, 4)->default(0);
            $table->string('status')->default('active'); // active | closed
            $table->string('notes')->nullable();
            $table->timestamps();

            $table->index(['organization_id', 'fund_type']);
        });

        Schema::create('restricted_fund_movements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('restricted_fund_id')->constrained()->cascadeOnDelete();
            $table->foreignId('journal_entry_id')->nullable()->constrained()->nullOnDelete();
            $table->date('date');
            $table->string('direction'); // in | out
            $table->decimal('amount', 20, 4);
            $table->decimal('balance_after', 20, 4);
            $table->string('description')->nullable();
            $table->timestamps();

            $table->index(['restricted_fund_id', 'date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('restricted_fund_movements');
        Schema::dropIfExists('restricted_funds');
    }
};

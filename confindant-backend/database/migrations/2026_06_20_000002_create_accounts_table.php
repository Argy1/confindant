<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('accounts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->constrained()->cascadeOnDelete();
            $table->string('code'); // e.g. 1-100 Kas dan Setara Kas
            $table->string('name');
            // asset | liability | net_asset | revenue | expense
            $table->string('type');
            // sub-grouping for reports: current_asset, fixed_asset, current_liability,
            // restricted_fund, operating_revenue, program_expense, admin_expense, other_expense, etc.
            $table->string('subtype')->nullable();
            // debit | credit -> the side that increases this account
            $table->string('normal_balance');
            $table->foreignId('parent_id')->nullable()->constrained('accounts')->nullOnDelete();
            // contra account flag (e.g. Akumulasi Penyusutan reduces an asset)
            $table->boolean('is_contra')->default(false);
            // opening balance for the very first period
            $table->decimal('opening_balance', 20, 4)->default(0);
            $table->boolean('is_active')->default(true);
            $table->integer('sort_order')->default(0);
            $table->text('description')->nullable();
            $table->timestamps();

            $table->unique(['organization_id', 'code']);
            $table->index(['organization_id', 'type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('accounts');
    }
};

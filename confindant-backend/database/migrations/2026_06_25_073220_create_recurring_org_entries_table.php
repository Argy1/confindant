<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('recurring_org_entries', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('organization_id');
            $table->unsignedBigInteger('debit_account_id');
            $table->unsignedBigInteger('credit_account_id');
            $table->string('description');
            $table->string('category')->nullable();
            $table->decimal('amount', 18, 2);
            $table->string('frequency'); // daily, weekly, monthly
            $table->unsignedSmallInteger('interval')->default(1);
            $table->date('start_date');
            $table->timestamp('next_run_at')->nullable();
            $table->timestamp('last_run_at')->nullable();
            $table->date('end_date')->nullable();
            $table->boolean('active')->default(true);
            $table->unsignedInteger('total_runs')->default(0);
            $table->unsignedBigInteger('created_by');
            $table->timestamps();

            $table->foreign('organization_id')->references('id')->on('organizations')->cascadeOnDelete();
            $table->foreign('debit_account_id')->references('id')->on('accounts');
            $table->foreign('credit_account_id')->references('id')->on('accounts');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('recurring_org_entries');
    }
};

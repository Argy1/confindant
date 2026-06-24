<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('organizations', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('slug')->unique();
            $table->string('legal_name')->nullable();
            $table->string('bank_account')->nullable();
            $table->string('currency')->default('IDR');
            $table->string('fiscal_year_start')->default('01-01'); // MM-DD
            $table->jsonb('settings')->nullable();
            $table->timestamps();
        });

        // Link users to organizations with a role
        Schema::create('organization_user', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            // bendahara = full input+posting, auditor = read+review, viewer = read only, admin = manage org
            $table->string('role')->default('viewer');
            $table->timestamps();

            $table->unique(['organization_id', 'user_id']);
            $table->index(['user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('organization_user');
        Schema::dropIfExists('organizations');
    }
};

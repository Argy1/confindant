<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\WalletController;
use App\Http\Controllers\Api\BudgetController;
use App\Http\Controllers\Api\TransactionController;

Route::prefix('v1')->group(function () {
    
    // ==========================================
    // 1. PUBLIC ROUTES (Bisa diakses tanpa login)
    // ==========================================
    Route::post('/register', [UserController::class, 'register']);
    Route::post('/login', [UserController::class, 'login']);

    // ==========================================
    // 2. PROTECTED ROUTES (Wajib bawa Token API)
    // ==========================================
    Route::middleware('auth:sanctum')->group(function () {
        
        // Ambil data user yang sedang login
        Route::get('/user', function (Request $request) {
            return $request->user();
        });
        Route::post('/logout', [UserController::class, 'logout']);

        // Wallets Endpoint
        Route::apiResource('wallets', WalletController::class);

        // Budgets Endpoint
        Route::apiResource('budgets', BudgetController::class);

        // Transactions Endpoint
        Route::apiResource('transactions', TransactionController::class);
        
        // Akses-akses API oleh backend
        Route::get('/users', [UserController::class, 'index']);
    });
});
<?php

use App\Http\Controllers\Api\AnalyticsController;
use App\Http\Controllers\Api\BudgetController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\GoalController;
use App\Http\Controllers\Api\HabitController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\TransactionController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\WalletController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::get('/health', function () {
        return response()->json([
            'success' => true,
            'message' => 'Confindant backend is healthy',
            'data' => [
                'status' => 'ok',
                'time' => now()->toIso8601String(),
                'app_env' => app()->environment(),
            ],
        ]);
    });

    Route::post('/register', [UserController::class, 'register']);
    Route::post('/login', [UserController::class, 'login']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/user', [UserController::class, 'me']);
        Route::post('/logout', [UserController::class, 'logout']);
        Route::get('/users', [UserController::class, 'index']);

        Route::post('/wallets/recalculate-balances', [WalletController::class, 'recalculateBalances']);
        Route::apiResource('wallets', WalletController::class);
        Route::apiResource('budgets', BudgetController::class);
        Route::post('/transactions/scan-upload', [TransactionController::class, 'scanUpload']);
        Route::post('/transactions/scan-ocr', [TransactionController::class, 'submitOcr']);
        Route::get('/transactions/scan-ocr/{id}', [TransactionController::class, 'getOcr']);
        Route::post('/transactions/scan-ocr/{id}/commit', [TransactionController::class, 'commitOcr']);
        Route::post('/transactions/scan-ocr/{id}/feedback', [TransactionController::class, 'submitOcrFeedback']);
        Route::apiResource('transactions', TransactionController::class);

        Route::get('/dashboard', [DashboardController::class, 'index']);
        Route::get('/analytics', [AnalyticsController::class, 'index']);

        Route::get('/goals', [GoalController::class, 'index']);
        Route::post('/goals', [GoalController::class, 'store']);
        Route::patch('/goals/{id}', [GoalController::class, 'update']);
        Route::delete('/goals/{id}', [GoalController::class, 'destroy']);
        Route::post('/goals/{id}/contributions', [GoalController::class, 'addContribution']);

        Route::get('/habits', [HabitController::class, 'index']);
        Route::post('/habits', [HabitController::class, 'store']);
        Route::post('/habits/{id}/increment', [HabitController::class, 'increment']);
        Route::post('/habits/{id}/reset', [HabitController::class, 'reset']);

        Route::get('/profile', [ProfileController::class, 'show']);
        Route::patch('/profile', [ProfileController::class, 'update']);
        Route::post('/profile/avatar', [ProfileController::class, 'updateAvatar']);
        Route::patch('/profile/notification-settings', [ProfileController::class, 'updateNotificationSettings']);

        Route::get('/notifications', [NotificationController::class, 'index']);
        Route::post('/notifications', [NotificationController::class, 'store']);
        Route::post('/notifications/{id}/mark-read', [NotificationController::class, 'markRead']);
    });
});

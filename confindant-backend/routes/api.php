<?php

use App\Http\Controllers\Api\AccountController;
use App\Http\Controllers\Api\AccountingImportController;
use App\Http\Controllers\Api\AnalyticsController;
use App\Http\Controllers\Api\AiController;
use App\Http\Controllers\Api\BudgetController;
use App\Http\Controllers\Api\ContentController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\FixedAssetController;
use App\Http\Controllers\Api\GoalController;
use App\Http\Controllers\Api\HabitController;
use App\Http\Controllers\Api\JournalController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\OrgBudgetController;
use App\Http\Controllers\Api\OrganizationController;
use App\Http\Controllers\Api\OrganizationInvitationController;
use App\Http\Controllers\Api\OrganizationMemberController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\ReceivablePayableController;
use App\Http\Controllers\Api\RecurringOrgEntryController;
use App\Http\Controllers\Api\RekeningHarianController;
use App\Http\Controllers\Api\RecurringTransactionController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\ReportPdfController;
use App\Http\Controllers\Api\RestrictedFundController;
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

    Route::middleware('throttle:auth-api')->group(function () {
        Route::post('/register', [UserController::class, 'register']);
        Route::post('/login', [UserController::class, 'login']);
    });

    // Public invitation info (no auth required)
    Route::get('/org-invite/{token}', [OrganizationInvitationController::class, 'info']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/user', [UserController::class, 'me']);
        Route::post('/logout', [UserController::class, 'logout']);
        Route::get('/users', [UserController::class, 'index']);

        Route::apiResource('wallets', WalletController::class);
        Route::post('/wallets/transfer', [WalletController::class, 'transfer']);
        Route::apiResource('budgets', BudgetController::class);
        Route::apiResource('transactions', TransactionController::class);
        Route::apiResource('recurring-transactions', RecurringTransactionController::class);
        Route::post('/transactions/scan-upload', [TransactionController::class, 'scanUpload'])->middleware('throttle:scan-upload');
        Route::post('/transactions/scan-ocr', [TransactionController::class, 'submitOcr'])->middleware('throttle:scan-upload');
        Route::get('/transactions/scan-ocr/{id}', [TransactionController::class, 'getOcr'])->middleware('throttle:ocr-poll');
        Route::post('/transactions/scan-ocr/{id}/commit', [TransactionController::class, 'commitOcr']);
        Route::post('/transactions/scan-ocr/{id}/feedback', [TransactionController::class, 'submitOcrFeedback']);
        Route::post('/ai/transactions/categorize', [AiController::class, 'categorizeTransaction'])->middleware('throttle:ai-inference');
        Route::post('/ai/transactions/feedback', [AiController::class, 'feedbackTransactionCategory'])->middleware('throttle:ai-inference');
        Route::post('/ai/transactions/parse-input', [AiController::class, 'parseTransactionInput'])->middleware('throttle:ai-inference');
        Route::get('/ai/cashflow-forecast', [AiController::class, 'cashflowForecast'])->middleware('throttle:ai-inference');
        Route::get('/ai/budget-recommendations', [AiController::class, 'budgetRecommendations'])->middleware('throttle:ai-inference');
        Route::get('/ai/budget-simulation', [AiController::class, 'budgetSimulation'])->middleware('throttle:ai-inference');
        Route::get('/ai/ocr-metrics', [AiController::class, 'ocrMetrics'])->middleware('throttle:ai-inference');
        Route::post('/ai/finance-query', [AiController::class, 'financeQuery'])->middleware('throttle:ai-inference');
        Route::get('/ai/finance-query/history', [AiController::class, 'financeQueryHistory'])->middleware('throttle:ai-inference');
        Route::delete('/ai/finance-query/history', [AiController::class, 'clearFinanceQueryHistory'])->middleware('throttle:ai-inference');
        Route::patch('/ai/finance-query/history/{id}', [AiController::class, 'renameFinanceQueryHistoryItem'])->middleware('throttle:ai-inference');
        Route::delete('/ai/finance-query/history/{id}', [AiController::class, 'deleteFinanceQueryHistoryItem'])->middleware('throttle:ai-inference');

        Route::get('/dashboard', [DashboardController::class, 'index']);
        Route::get('/analytics', [AnalyticsController::class, 'index']);

        Route::get('/goals', [GoalController::class, 'index']);
        Route::post('/goals', [GoalController::class, 'store']);
        Route::patch('/goals/{id}', [GoalController::class, 'update']);
        Route::delete('/goals/{id}', [GoalController::class, 'destroy']);
        Route::post('/goals/{id}/contributions', [GoalController::class, 'addContribution']);

        Route::get('/habits', [HabitController::class, 'index']);
        Route::post('/habits', [HabitController::class, 'store']);
        Route::patch('/habits/{id}', [HabitController::class, 'update']);
        Route::post('/habits/{id}/increment', [HabitController::class, 'increment']);
        Route::post('/habits/{id}/reset', [HabitController::class, 'reset']);

        Route::get('/profile', [ProfileController::class, 'show']);
        Route::patch('/profile', [ProfileController::class, 'update']);
        Route::patch('/profile/change-password', [ProfileController::class, 'changePassword']);
        Route::post('/profile/avatar', [ProfileController::class, 'updateAvatar']);
        Route::patch('/profile/notification-settings', [ProfileController::class, 'updateNotificationSettings']);
        Route::get('/legal/privacy', [ContentController::class, 'privacy']);
        Route::get('/legal/terms', [ContentController::class, 'terms']);
        Route::get('/support/channels', [ContentController::class, 'supportChannels']);

        Route::get('/notifications', [NotificationController::class, 'index']);
        Route::post('/notifications', [NotificationController::class, 'store']);
        Route::post('/notifications/{id}/mark-read', [NotificationController::class, 'markRead']);

        // ============= ACCOUNTING (Organisasi / PDPI) =============
        // Organisasi milik user (untuk context switcher)
        Route::get('/me/organizations', [OrganizationController::class, 'index']);

        // Dashboard organisasi
        Route::get('/accounting/dashboard', [ReportController::class, 'dashboard']);

        // Chart of Accounts
        Route::get('/accounting/accounts', [AccountController::class, 'index']);
        Route::post('/accounting/accounts', [AccountController::class, 'store']);
        Route::patch('/accounting/accounts/{id}', [AccountController::class, 'update']);

        // Rekening Harian (simplified cash-book input → auto double-entry)
        Route::get('/accounting/rekening-harian/categories', [RekeningHarianController::class, 'categories']);
        Route::get('/accounting/rekening-harian', [RekeningHarianController::class, 'index']);
        Route::post('/accounting/rekening-harian', [RekeningHarianController::class, 'store']);
        Route::delete('/accounting/rekening-harian/{id}', [RekeningHarianController::class, 'destroy']);

        // Jurnal Umum (double-entry)
        Route::get('/accounting/journal', [JournalController::class, 'index']);
        Route::post('/accounting/journal', [JournalController::class, 'store']);
        Route::get('/accounting/journal/{id}', [JournalController::class, 'show']);
        Route::post('/accounting/journal/{id}/void', [JournalController::class, 'void']);

        // Laporan Keuangan
        Route::get('/accounting/reports/balance-sheet', [ReportController::class, 'balanceSheet']);
        Route::get('/accounting/reports/activities', [ReportController::class, 'statementOfActivities']);
        Route::get('/accounting/reports/trial-balance', [ReportController::class, 'trialBalance']);
        Route::get('/accounting/reports/ledger/{accountId}', [ReportController::class, 'generalLedger']);

        // Export PDF Laporan (Sprint 3)
        Route::get('/accounting/reports/balance-sheet/pdf', [ReportPdfController::class, 'balanceSheet']);
        Route::get('/accounting/reports/activities/pdf', [ReportPdfController::class, 'activities']);
        Route::get('/accounting/reports/trial-balance/pdf', [ReportPdfController::class, 'trialBalance']);

        // Aktiva Tetap & Penyusutan (Fase C)
        Route::get('/accounting/fixed-assets', [FixedAssetController::class, 'index']);
        Route::post('/accounting/fixed-assets', [FixedAssetController::class, 'store']);
        Route::get('/accounting/fixed-assets/{id}', [FixedAssetController::class, 'show']);
        Route::delete('/accounting/fixed-assets/{id}', [FixedAssetController::class, 'destroy']);
        Route::post('/accounting/fixed-assets/run-depreciation', [FixedAssetController::class, 'runDepreciation']);

        // Piutang & Hutang (Fase D)
        Route::get('/accounting/receivables-payables', [ReceivablePayableController::class, 'index']);
        Route::post('/accounting/receivables-payables', [ReceivablePayableController::class, 'store']);
        Route::get('/accounting/receivables-payables/{id}', [ReceivablePayableController::class, 'show']);
        Route::post('/accounting/receivables-payables/{id}/settle', [ReceivablePayableController::class, 'settle']);

        // Dana Titipan / Restricted Funds (Fase D)
        Route::get('/accounting/restricted-funds', [RestrictedFundController::class, 'index']);
        Route::post('/accounting/restricted-funds', [RestrictedFundController::class, 'store']);
        Route::get('/accounting/restricted-funds/{id}', [RestrictedFundController::class, 'show']);
        Route::post('/accounting/restricted-funds/{id}/move', [RestrictedFundController::class, 'move']);

        // Import Excel (Fase E)
        Route::post('/accounting/import/harian', [AccountingImportController::class, 'importHarian'])
            ->middleware('throttle:scan-upload');

        // AI Chat untuk Org (Sprint 1)
        Route::post('/accounting/ai/finance-query', [AiController::class, 'orgFinanceQuery'])->middleware('throttle:ai-inference');
        Route::get('/accounting/ai/finance-query/history', [AiController::class, 'orgFinanceQueryHistory'])->middleware('throttle:ai-inference');
        Route::delete('/accounting/ai/finance-query/history', [AiController::class, 'clearOrgFinanceQueryHistory'])->middleware('throttle:ai-inference');

        // Scan Struk untuk Org — commit OCR ke jurnal (Sprint 1)
        Route::post('/accounting/scan-ocr/{id}/commit', [JournalController::class, 'commitFromOcr']);

        // Recurring Jurnal Org (Sprint 2)
        Route::get('/accounting/recurring', [RecurringOrgEntryController::class, 'index']);
        Route::post('/accounting/recurring', [RecurringOrgEntryController::class, 'store']);
        Route::patch('/accounting/recurring/{id}', [RecurringOrgEntryController::class, 'update']);
        Route::delete('/accounting/recurring/{id}', [RecurringOrgEntryController::class, 'destroy']);
        Route::post('/accounting/recurring/{id}/run', [RecurringOrgEntryController::class, 'run']);

        // Manajemen Anggota (Sprint 5)
        Route::get('/accounting/members', [OrganizationMemberController::class, 'index']);
        Route::post('/accounting/members/invite', [OrganizationInvitationController::class, 'invite']);
        Route::get('/accounting/members/invitations', [OrganizationInvitationController::class, 'index']);
        Route::delete('/accounting/members/invitations/{token}', [OrganizationInvitationController::class, 'cancel']);
        Route::patch('/accounting/members/{userId}', [OrganizationMemberController::class, 'update']);
        Route::delete('/accounting/members/{userId}', [OrganizationMemberController::class, 'destroy']);
        Route::post('/org-invite/{token}/accept', [OrganizationInvitationController::class, 'accept']);

        // Budget vs Realisasi (Sprint 4)
        Route::get('/accounting/budget', [OrgBudgetController::class, 'index']);
        Route::post('/accounting/budget', [OrgBudgetController::class, 'store']);
        Route::patch('/accounting/budget/{id}', [OrgBudgetController::class, 'update']);
        Route::delete('/accounting/budget/{id}', [OrgBudgetController::class, 'destroy']);
        Route::get('/accounting/budget/compare', [OrgBudgetController::class, 'compare']);
    });
});

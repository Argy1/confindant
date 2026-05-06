<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\Budget;
use App\Models\Transaction;
use App\Models\Wallet;
use App\Services\AiFinanceInsightService;
use Carbon\Carbon;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    use ApiResponse;

    public function index(Request $request, AiFinanceInsightService $insightService)
    {
        $userId = (string) $request->user()->_id;

        $wallets = Wallet::where('user_id', $userId)->get();
        $budgets = Budget::where('user_id', $userId)->get();
        $transactions = Transaction::where('user_id', $userId)->orderBy('date', 'desc')->get();
        $financialTransactions = $transactions->filter(fn ($trx) => !($trx->is_internal_transfer ?? false));

        $balance = $wallets->sum('balance');
        $income = $financialTransactions->where('type', 'income')->sum('total_amount');
        $expense = $financialTransactions->where('type', 'expense')->sum('total_amount');

        $recent = $transactions->take(8)->values()->map(function ($trx) {
            $date = $trx->date ? Carbon::parse($trx->date) : now();
            $title = $trx->merchant_name
                ?: ($trx->type === 'income'
                    ? ((string) ($trx->source ?: $trx->category ?: 'Income'))
                    : ucfirst((string) ($trx->category ?: 'Transaction')));
            return [
                'id' => (string) $trx->_id,
                'wallet_id' => (string) $trx->wallet_id,
                'title' => $title,
                'subtitle' => $date->format('d M Y, H:i'),
                'amount' => (float) $trx->total_amount,
                'is_expense' => $trx->type === 'expense',
                'type' => (string) $trx->type,
                'source' => $trx->source ? (string) $trx->source : null,
                'category' => $trx->category ? (string) $trx->category : null,
                'notes' => $trx->notes ? (string) $trx->notes : null,
                'tags' => is_array($trx->tags) ? array_values($trx->tags) : [],
            ];
        });

        $budgetUsage = $budgets->map(function ($budget) use ($financialTransactions) {
            $used = $financialTransactions
                ->where('type', 'expense')
                ->where('category', $budget->category)
                ->sum('total_amount');

            return [
                'id' => (string) $budget->_id,
                'category' => (string) $budget->category,
                'used' => (float) $used,
                'limit' => (float) $budget->limit_amount,
            ];
        });
        $forecast7d = $insightService->cashflowForecast($userId, 7);
        $forecast30d = $insightService->cashflowForecast($userId, 30);

        return $this->ok([
            'summary' => [
                'balance' => (float) $balance,
                'income' => (float) $income,
                'expense' => (float) $expense,
                'last_updated_label' => 'Updated just now',
            ],
            'cashflow_forecast' => [
                'next_7_days' => $forecast7d,
                'next_30_days' => $forecast30d,
            ],
            'quick_actions' => [
                ['type' => 'scan', 'label' => 'Scan'],
                ['type' => 'addExpense', 'label' => 'Tambah Pengeluaran'],
                ['type' => 'addIncome', 'label' => 'Tambah Pemasukan'],
                ['type' => 'addWallet', 'label' => 'Add Wallet'],
            ],
            'budget_items' => $budgetUsage,
            'recent_transactions' => $recent,
            'insight_text' => $budgetUsage->isEmpty()
                ? 'Belum ada data budget untuk ditampilkan.'
                : 'Pantau kategori dengan penggunaan tertinggi agar pengeluaran tetap terkendali.',
        ], 'Dashboard berhasil diambil');
    }
}

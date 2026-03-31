<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\Budget;
use App\Models\Transaction;
use App\Models\Wallet;
use Carbon\Carbon;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    use ApiResponse;

    public function index(Request $request)
    {
        $userId = (string) $request->user()->_id;

        $wallets = Wallet::where('user_id', $userId)->get();
        $budgets = Budget::where('user_id', $userId)->get();
        $transactions = Transaction::where('user_id', $userId)->orderBy('date', 'desc')->get();

        $walletBalance = (float) $wallets->sum('balance');
        $income = $transactions->where('type', 'income')->sum('total_amount');
        $expense = $transactions->where('type', 'expense')->sum('total_amount');
        $computedNet = (float) $income - (float) $expense;
        $balance = abs($walletBalance) < 0.00001 && abs($computedNet) > 0.00001
            ? $computedNet
            : $walletBalance;

        $recent = $transactions->take(8)->values()->map(function ($trx) {
            $date = $trx->date ? Carbon::parse($trx->date) : now();
            return [
                'id' => (string) $trx->_id,
                'title' => $trx->merchant_name ?: ucfirst((string) ($trx->category ?: 'Transaction')),
                'subtitle' => $date->format('d M Y, H:i'),
                'amount' => (float) $trx->total_amount,
                'is_expense' => $trx->type === 'expense',
            ];
        });

        $budgetUsage = $budgets->map(function ($budget) use ($transactions) {
            $used = $transactions
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

        return $this->ok([
            'summary' => [
                'balance' => (float) $balance,
                'income' => (float) $income,
                'expense' => (float) $expense,
                'last_updated_label' => 'Updated just now',
            ],
            'quick_actions' => [
                ['type' => 'scan', 'label' => 'Scan'],
                ['type' => 'addExpense', 'label' => 'Add Expense'],
                ['type' => 'addIncome', 'label' => 'Add Income'],
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

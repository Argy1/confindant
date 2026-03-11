<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\Budget;
use App\Models\Transaction;
use Carbon\Carbon;
use Illuminate\Http\Request;

class AnalyticsController extends Controller
{
    use ApiResponse;

    public function index(Request $request)
    {
        $period = $request->query('period', 'monthly');
        $userId = (string) $request->user()->_id;

        $transactions = Transaction::where('user_id', $userId)->orderBy('date', 'asc')->get();
        $budgets = Budget::where('user_id', $userId)->get();

        $income = $transactions->where('type', 'income')->sum('total_amount');
        $expense = $transactions->where('type', 'expense')->sum('total_amount');

        $expensesOnly = $transactions->where('type', 'expense');

        $breakdown = $expensesOnly->groupBy(fn ($t) => (string) ($t->category ?: 'Other'))
            ->map(fn ($items, $label) => [
                'label' => $label,
                'amount' => (float) $items->sum('total_amount'),
            ])
            ->values();

        $trend = $expensesOnly
            ->groupBy(function ($t) use ($period) {
                $d = $t->date ? Carbon::parse($t->date) : now();
                return $period === 'weekly' ? $d->format('D') : $d->format('M');
            })
            ->map(fn ($items, $label) => [
                'label' => $label,
                'amount' => (float) $items->sum('total_amount'),
            ])
            ->values();

        $budgetProgress = $budgets->map(function ($budget) use ($expensesOnly) {
            $used = $expensesOnly->where('category', $budget->category)->sum('total_amount');
            return [
                'category' => (string) $budget->category,
                'used' => (float) $used,
                'limit' => (float) $budget->limit_amount,
            ];
        })->values();

        return $this->ok([
            'summary' => [
                'total_income' => (float) $income,
                'total_expense' => (float) $expense,
                'net_saving' => (float) ($income - $expense),
            ],
            'category_breakdown' => $breakdown,
            'trend_points' => $trend,
            'budget_progress' => $budgetProgress,
            'insight_text' => $breakdown->isEmpty()
                ? 'Belum ada data transaksi untuk dianalisis.'
                : 'Kategori dengan pengeluaran tertinggi perlu dipantau untuk menghindari over budget.',
        ], 'Analytics berhasil diambil');
    }
}

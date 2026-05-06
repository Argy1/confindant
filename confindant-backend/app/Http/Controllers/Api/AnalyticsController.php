<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\Budget;
use App\Models\Transaction;
use App\Services\AiFinanceInsightService;
use Carbon\Carbon;
use Illuminate\Http\Request;

class AnalyticsController extends Controller
{
    use ApiResponse;

    public function index(Request $request, AiFinanceInsightService $insightService)
    {
        $validated = $request->validate([
            'period' => 'nullable|in:weekly,monthly',
            'from_date' => 'nullable|date',
            'to_date' => 'nullable|date',
            'wallet_id' => 'nullable|string',
            'category' => 'nullable|string|max:255',
        ]);

        $period = $validated['period'] ?? 'monthly';
        $userId = (string) $request->user()->_id;
        $fromDate = isset($validated['from_date']) ? Carbon::parse($validated['from_date'])->startOfDay() : null;
        $toDate = isset($validated['to_date']) ? Carbon::parse($validated['to_date'])->endOfDay() : null;
        $walletId = $validated['wallet_id'] ?? null;
        $categoryFilter = $validated['category'] ?? null;
        if ($categoryFilter === 'All Categories') {
            $categoryFilter = null;
        }

        $transactions = Transaction::where('user_id', $userId)->orderBy('date', 'asc')->get();
        $budgets = Budget::where('user_id', $userId)->get();
        $filtered = $transactions->filter(function ($transaction) use ($fromDate, $toDate, $walletId, $categoryFilter) {
            if ($transaction->is_internal_transfer ?? false) {
                return false;
            }

            if ($walletId && (string) $transaction->wallet_id !== $walletId) {
                return false;
            }

            if ($categoryFilter && (string) ($transaction->category ?: '') !== $categoryFilter) {
                return false;
            }

            if ($fromDate || $toDate) {
                $date = $transaction->date ? Carbon::parse($transaction->date) : null;
                if (!$date) {
                    return false;
                }

                if ($fromDate && $date->lt($fromDate)) {
                    return false;
                }
                if ($toDate && $date->gt($toDate)) {
                    return false;
                }
            }

            return true;
        })->values();

        [$effectiveFrom, $effectiveTo] = $this->resolveEffectiveWindow(
            $filtered,
            $period,
            $fromDate,
            $toDate
        );
        $windowDays = max(1, $effectiveFrom->diffInDays($effectiveTo) + 1);
        $previousFrom = $effectiveFrom->copy()->subDays($windowDays);
        $previousTo = $effectiveFrom->copy()->subSecond();
        $previousWindow = $transactions->filter(function ($transaction) use ($previousFrom, $previousTo, $walletId, $categoryFilter) {
            if ($transaction->is_internal_transfer ?? false) {
                return false;
            }

            if ($walletId && (string) $transaction->wallet_id !== $walletId) {
                return false;
            }
            if ($categoryFilter && (string) ($transaction->category ?: '') !== $categoryFilter) {
                return false;
            }

            $date = $transaction->date ? Carbon::parse($transaction->date) : null;
            if (!$date) {
                return false;
            }

            return $date->betweenIncluded($previousFrom, $previousTo);
        })->values();

        $income = $filtered->where('type', 'income')->sum('total_amount');
        $expense = $filtered->where('type', 'expense')->sum('total_amount');
        $previousExpense = $previousWindow->where('type', 'expense')->sum('total_amount');

        $expensesOnly = $filtered->where('type', 'expense');
        $incomeOnly = $filtered->where('type', 'income');

        $breakdown = $expensesOnly->groupBy(fn ($t) => (string) ($t->category ?: 'Other'))
            ->map(fn ($items, $label) => [
                'label' => $label,
                'amount' => (float) $items->sum('total_amount'),
            ])
            ->values();

        $incomeBreakdown = $incomeOnly->groupBy(fn ($t) => (string) ($t->source ?: $t->category ?: 'Other'))
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

        $incomeTrend = $incomeOnly
            ->groupBy(function ($t) use ($period) {
                $d = $t->date ? Carbon::parse($t->date) : now();
                return $period === 'weekly' ? $d->format('D') : $d->format('M');
            })
            ->map(fn ($items, $label) => [
                'label' => $label,
                'amount' => (float) $items->sum('total_amount'),
            ])
            ->values();

        $netFlowTrend = $filtered
            ->groupBy(function ($t) use ($period) {
                $d = $t->date ? Carbon::parse($t->date) : now();
                return $period === 'weekly' ? $d->format('D') : $d->format('M');
            })
            ->map(function ($items, $label) {
                $incomeValue = (float) $items->where('type', 'income')->sum('total_amount');
                $expenseValue = (float) $items->where('type', 'expense')->sum('total_amount');
                return [
                    'label' => $label,
                    'income' => $incomeValue,
                    'expense' => $expenseValue,
                    'amount' => $incomeValue - $expenseValue,
                ];
            })
            ->values();

        $budgetProgress = $budgets->map(function ($budget) use ($expensesOnly) {
            $used = $expensesOnly->where('category', $budget->category)->sum('total_amount');
            return [
                'category' => (string) $budget->category,
                'used' => (float) $used,
                'limit' => (float) $budget->limit_amount,
            ];
        })->values();

        $deltaPercent = $previousExpense > 0
            ? (((float) $expense - (float) $previousExpense) / (float) $previousExpense) * 100
            : ((float) $expense > 0 ? 100.0 : 0.0);
        $topCategory = $breakdown->sortByDesc('amount')->first();
        $anomalyCategory = $topCategory['label'] ?? 'None';
        $currentTopAmount = (float) ($topCategory['amount'] ?? 0);
        $previousTopAmount = (float) $previousWindow
            ->where('type', 'expense')
            ->where('category', $anomalyCategory)
            ->sum('total_amount');
        $anomalySpike = $previousTopAmount > 0
            ? (($currentTopAmount - $previousTopAmount) / $previousTopAmount) * 100
            : ($currentTopAmount > 0 ? 100.0 : 0.0);

        $comparisonMode = $period === 'weekly' ? 'weekOverWeek' : 'monthOverMonth';
        $budgetRecommendations = $insightService->budgetRecommendations(
            $userId,
            $fromDate,
            $toDate,
            $walletId
        );

        return $this->ok([
            'summary' => [
                'total_income' => (float) $income,
                'total_expense' => (float) $expense,
                'net_saving' => (float) ($income - $expense),
            ],
            'category_breakdown' => $breakdown,
            'income_breakdown' => $incomeBreakdown,
            'trend_points' => $trend,
            'income_trend_points' => $incomeTrend,
            'net_flow_trend' => $netFlowTrend,
            'budget_progress' => $budgetProgress,
            'budget_recommendations' => $budgetRecommendations,
            'comparison' => [
                'mode' => $comparisonMode,
                'current_value' => (float) $expense,
                'previous_value' => (float) $previousExpense,
                'delta_percent' => round((float) $deltaPercent, 2),
            ],
            'anomaly' => [
                'category' => (string) $anomalyCategory,
                'spike_percent' => round((float) $anomalySpike, 2),
                'message' => $anomalyCategory === 'None'
                    ? 'Belum ada pola pengeluaran untuk dianalisis.'
                    : $anomalyCategory.' spending changed '.round((float) $anomalySpike, 2).'% versus previous period.',
            ],
            'insight_text' => $breakdown->isEmpty()
                ? 'Belum ada data transaksi untuk dianalisis.'
                : 'Kategori dengan pengeluaran tertinggi perlu dipantau untuk menghindari over budget.',
        ], 'Analytics berhasil diambil');
    }

    private function resolveEffectiveWindow($transactions, string $period, ?Carbon $fromDate, ?Carbon $toDate): array
    {
        if ($fromDate && $toDate) {
            return [$fromDate->copy(), $toDate->copy()];
        }

        if ($transactions->isNotEmpty()) {
            $dates = $transactions
                ->map(fn ($transaction) => $transaction->date ? Carbon::parse($transaction->date) : null)
                ->filter();
            if ($dates->isNotEmpty()) {
                return [$dates->min()->copy()->startOfDay(), $dates->max()->copy()->endOfDay()];
            }
        }

        if ($period === 'weekly') {
            return [now()->startOfWeek(), now()->endOfWeek()];
        }

        return [now()->startOfMonth(), now()->endOfMonth()];
    }
}

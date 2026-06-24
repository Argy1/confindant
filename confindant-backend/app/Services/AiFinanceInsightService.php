<?php

namespace App\Services;

use App\Models\Budget;
use App\Models\Transaction;
use App\Models\Wallet;
use Carbon\Carbon;

class AiFinanceInsightService
{
    public function cashflowForecast(string $userId, int $days = 30, ?string $walletId = null): array
    {
        $horizonDays = max(1, min($days, 90));
        $historyDays = max(30, $horizonDays * 2);
        $historyStart = now()->copy()->subDays($historyDays)->startOfDay();

        $walletQuery = Wallet::where('user_id', $userId);
        if ($walletId) {
            $walletQuery->where('id', $walletId);
        }
        $currentBalance = (float) $walletQuery->get()->sum('balance');

        $query = Transaction::where('user_id', $userId)
            ->where('is_internal_transfer', '!=', true)
            ->where('date', '>=', $historyStart)
            ->orderBy('date', 'asc');

        if ($walletId) {
            $query->where('wallet_id', $walletId);
        }

        $transactions = $query->get();
        $historyIncome = (float) $transactions->where('type', 'income')->sum('total_amount');
        $historyExpense = (float) $transactions->where('type', 'expense')->sum('total_amount');
        $netDaily = ($historyIncome - $historyExpense) / max(1, $historyDays);

        $predictedIncome = ($historyIncome / max(1, $historyDays)) * $horizonDays;
        $predictedExpense = ($historyExpense / max(1, $historyDays)) * $horizonDays;
        $predictedNet = $predictedIncome - $predictedExpense;
        $predictedBalance = $currentBalance + $predictedNet;
        $negativeRisk = $this->computeNegativeRisk(
            $currentBalance,
            $netDaily,
            $horizonDays
        );

        $activeDays = $transactions
            ->map(fn ($item) => $item->date ? Carbon::parse($item->date)->toDateString() : null)
            ->filter()
            ->unique()
            ->count();

        $coverage = $activeDays / max(1, min($historyDays, 45));
        $confidence = (float) max(0.35, min(0.95, 0.35 + ($coverage * 0.6)));

        return [
            'horizon_days' => $horizonDays,
            'base_balance' => round($currentBalance, 2),
            'predicted_income' => round($predictedIncome, 2),
            'predicted_expense' => round($predictedExpense, 2),
            'predicted_net' => round($predictedNet, 2),
            'predicted_balance' => round($predictedBalance, 2),
            'avg_daily_net' => round($netDaily, 2),
            'will_go_negative' => $negativeRisk['will_go_negative'],
            'negative_on_date' => $negativeRisk['negative_on_date'],
            'days_to_negative' => $negativeRisk['days_to_negative'],
            'confidence' => round($confidence, 2),
            'provider' => 'heuristic',
            'generated_at' => now()->toIso8601String(),
        ];
    }

    private function computeNegativeRisk(float $baseBalance, float $netDaily, int $horizonDays): array
    {
        if ($baseBalance < 0) {
            return [
                'will_go_negative' => true,
                'negative_on_date' => now()->toDateString(),
                'days_to_negative' => 0,
            ];
        }

        if ($netDaily >= 0 || $horizonDays <= 0) {
            return [
                'will_go_negative' => false,
                'negative_on_date' => null,
                'days_to_negative' => null,
            ];
        }

        $daysUntilNegative = (int) ceil($baseBalance / abs($netDaily));
        if ($daysUntilNegative > $horizonDays) {
            return [
                'will_go_negative' => false,
                'negative_on_date' => null,
                'days_to_negative' => null,
            ];
        }

        return [
            'will_go_negative' => true,
            'negative_on_date' => now()->copy()->addDays($daysUntilNegative)->toDateString(),
            'days_to_negative' => $daysUntilNegative,
        ];
    }

    public function budgetRecommendations(
        string $userId,
        ?Carbon $fromDate = null,
        ?Carbon $toDate = null,
        ?string $walletId = null
    ): array {
        $from = $fromDate ? $fromDate->copy()->startOfDay() : now()->copy()->startOfMonth();
        $to = $toDate ? $toDate->copy()->endOfDay() : now()->copy()->endOfMonth();

        $budgets = Budget::where('user_id', $userId)->get();
        if ($budgets->isEmpty()) {
            return [];
        }

        $expenseQuery = Transaction::where('user_id', $userId)
            ->where('type', 'expense')
            ->where('is_internal_transfer', '!=', true);

        if ($walletId) {
            $expenseQuery->where('wallet_id', $walletId);
        }

        $allExpenses = $expenseQuery->get();

        $periodExpenses = $allExpenses->filter(function ($item) use ($from, $to) {
            if (!$item->date) {
                return false;
            }
            $date = Carbon::parse($item->date);
            return $date->betweenIncluded($from, $to);
        });

        $threeMonthsAgo = now()->copy()->subMonths(3)->startOfMonth();
        $recentExpenses = $allExpenses->filter(function ($item) use ($threeMonthsAgo, $to) {
            if (!$item->date) {
                return false;
            }
            $date = Carbon::parse($item->date);
            return $date->betweenIncluded($threeMonthsAgo, $to);
        });

        $result = $budgets->map(function ($budget) use ($periodExpenses, $recentExpenses) {
            $category = (string) ($budget->category ?? 'Other');
            $limit = (float) ($budget->limit_amount ?? 0);
            $used = (float) $periodExpenses->where('category', $category)->sum('total_amount');
            $avgMonthly = (float) $recentExpenses->where('category', $category)->sum('total_amount') / 3.0;

            $baseline = max($avgMonthly * 1.1, $used * 1.15);
            $recommended = max($limit, $baseline);
            $simulation = $this->simulateBudgetAdjustmentFromValues($limit, $used, -10.0);

            $usageRatio = $limit > 0 ? ($used / $limit) : 0;
            $priority = $usageRatio >= 0.9 ? 'high' : ($usageRatio >= 0.7 ? 'medium' : 'low');
            $reason = $priority === 'high'
                ? 'Penggunaan kategori hampir/lebih dari limit. Pertimbangkan menaikkan anggaran.'
                : ($priority === 'medium'
                    ? 'Penggunaan kategori cukup tinggi. Pantau agar tidak over budget.'
                    : 'Limit saat ini masih aman berdasarkan pola terakhir.');

            return [
                'category' => $category,
                'current_limit' => round($limit, 2),
                'used' => round($used, 2),
                'avg_monthly_expense' => round($avgMonthly, 2),
                'recommended_limit' => round($recommended, 2),
                'delta' => round($recommended - $limit, 2),
                'priority' => $priority,
                'reason' => $reason,
                'simulation_if_reduce_10_percent' => $simulation,
            ];
        })->sortByDesc(function ($item) {
            $priorityOrder = ['high' => 3, 'medium' => 2, 'low' => 1];
            return ($priorityOrder[$item['priority']] ?? 0) * 1000000000 + (int) round($item['delta']);
        })->values();

        return $result->all();
    }

    public function simulateBudgetAdjustment(
        string $userId,
        string $category,
        float $changePercent,
        ?Carbon $fromDate = null,
        ?Carbon $toDate = null,
        ?string $walletId = null
    ): array {
        $from = $fromDate ? $fromDate->copy()->startOfDay() : now()->copy()->startOfMonth();
        $to = $toDate ? $toDate->copy()->endOfDay() : now()->copy()->endOfMonth();

        $budget = Budget::where('user_id', $userId)
            ->where('category', $category)
            ->first();
        if (!$budget) {
            return [
                'category' => $category,
                'error' => 'budget_not_found',
                'message' => 'Budget kategori tidak ditemukan',
            ];
        }

        $expenseQuery = Transaction::where('user_id', $userId)
            ->where('type', 'expense')
            ->where('is_internal_transfer', '!=', true)
            ->where('category', $category);
        if ($walletId) {
            $expenseQuery->where('wallet_id', $walletId);
        }

        $used = (float) $expenseQuery->get()->filter(function ($item) use ($from, $to) {
            if (!$item->date) {
                return false;
            }
            $date = Carbon::parse($item->date);
            return $date->betweenIncluded($from, $to);
        })->sum('total_amount');

        return [
            'category' => $category,
            ...$this->simulateBudgetAdjustmentFromValues((float) ($budget->limit_amount ?? 0), $used, $changePercent),
        ];
    }

    private function simulateBudgetAdjustmentFromValues(float $currentLimit, float $used, float $changePercent): array
    {
        $normalizedChangePercent = max(-50.0, min(50.0, $changePercent));
        $simulatedLimit = max(0.0, $currentLimit * (1 + ($normalizedChangePercent / 100)));

        $overspendCurrent = max(0.0, $used - $currentLimit);
        $overspendSimulated = max(0.0, $used - $simulatedLimit);
        $overspendDelta = $overspendSimulated - $overspendCurrent;

        $estimatedSavingImpact = -1 * $overspendDelta;

        return [
            'change_percent' => round($normalizedChangePercent, 2),
            'current_limit' => round($currentLimit, 2),
            'simulated_limit' => round($simulatedLimit, 2),
            'current_used' => round($used, 2),
            'estimated_saving_impact' => round($estimatedSavingImpact, 2),
            'estimated_overspend_delta' => round($overspendDelta, 2),
        ];
    }
}

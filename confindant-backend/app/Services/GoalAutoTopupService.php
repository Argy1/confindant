<?php

namespace App\Services;

use App\Models\Goal;
use App\Models\Transaction;

class GoalAutoTopupService
{
    /**
     * Apply auto-topup contributions to all enabled goals after an income transaction.
     *
     * @return array<int, array<string, mixed>>
     */
    public function applyForIncomeTransaction(Transaction $transaction): array
    {
        if ((string) $transaction->type !== 'income' || ($transaction->is_internal_transfer ?? false)) {
            return [];
        }

        $amount = (float) $transaction->total_amount;
        if ($amount <= 0) {
            return [];
        }

        $goals = Goal::where('user_id', (string) $transaction->user_id)
            ->where('auto_topup_enabled', true)
            ->where('auto_topup_percent', '>', 0)
            ->get();

        $applied = [];
        foreach ($goals as $goal) {
            $percent = max(0, min(100, (float) ($goal->auto_topup_percent ?? 0)));
            if ($percent <= 0) {
                continue;
            }

            $proposedAmount = round($amount * ($percent / 100), 2);
            if ($proposedAmount <= 0) {
                continue;
            }

            $currentAmount = (float) ($goal->current_amount ?? 0);
            $targetAmount = (float) ($goal->target_amount ?? 0);
            $remaining = $targetAmount > 0 ? max(0, $targetAmount - $currentAmount) : $proposedAmount;
            $appliedAmount = $targetAmount > 0 ? min($proposedAmount, $remaining) : $proposedAmount;

            if ($appliedAmount <= 0) {
                continue;
            }

            $contributions = is_array($goal->contributions) ? $goal->contributions : [];
            array_unshift($contributions, [
                'date_label' => now()->format('M d'),
                'amount' => $appliedAmount,
                'note' => 'Auto top-up from income transaction',
                'meta' => [
                    'mode' => 'auto_topup',
                    'transaction_id' => (string) $transaction->_id,
                    'source' => $transaction->source ? (string) $transaction->source : null,
                ],
            ]);

            $goal->update([
                'current_amount' => $currentAmount + $appliedAmount,
                'contributions' => $contributions,
            ]);

            $applied[] = [
                'goal_id' => (string) $goal->_id,
                'goal_name' => (string) ($goal->name ?? 'Goal'),
                'amount' => $appliedAmount,
                'percent' => $percent,
            ];
        }

        return $applied;
    }
}

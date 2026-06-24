<?php

namespace App\Services;

use App\Models\Budget;
use App\Models\ProfileSetting;
use App\Models\Transaction;
use App\Models\UserNotification;
use Carbon\Carbon;

class BudgetAlertService
{
    /**
     * Check budget utilization for the given category and emit notifications at 70% / 90%.
     */
    public function checkAndNotify(string $userId, ?string $category): void
    {
        $normalizedCategory = trim((string) $category);
        if ($normalizedCategory === '') {
            return;
        }

        $profile = ProfileSetting::where('user_id', $userId)->first();
        $notificationSettings = (array) (($profile?->notification_settings) ?? []);
        $budgetAlertsEnabled = (bool) (($notificationSettings['budget_alerts'] ?? true) === true);
        if (!$budgetAlertsEnabled) {
            return;
        }

        $budgets = Budget::where('user_id', $userId)
            ->where('category', $normalizedCategory)
            ->get();
        if ($budgets->isEmpty()) {
            return;
        }

        $used = (float) Transaction::where('user_id', $userId)
            ->where('type', 'expense')
            ->where('category', $normalizedCategory)
            ->where(function ($q) {
                $q->whereNull('is_internal_transfer')
                    ->orWhere('is_internal_transfer', false);
            })
            ->sum('total_amount');

        foreach ($budgets as $budget) {
            $limit = (float) $budget->limit_amount;
            if ($limit <= 0) {
                continue;
            }

            $percent = ($used / $limit) * 100;
            $thresholds = [70.0, 90.0];
            $custom = (float) ($budget->alert_threshold ?? 0);
            if ($custom > 0 && !in_array($custom, $thresholds, true)) {
                $thresholds[] = $custom;
            }

            foreach ($thresholds as $threshold) {
                if ($percent < $threshold) {
                    continue;
                }

                $eventKey = sprintf(
                    'budget:%s:%s:%s',
                    (string) $budget->id,
                    (string) $budget->period_month,
                    rtrim(rtrim(number_format($threshold, 2, '.', ''), '0'), '.')
                );

                $exists = UserNotification::where('user_id', $userId)
                    ->where('event_key', $eventKey)
                    ->exists();
                if ($exists) {
                    continue;
                }

                UserNotification::create([
                    'user_id' => $userId,
                    'title' => 'Budget Alert',
                    'subtitle' => sprintf(
                        'Kategori %s sudah mencapai %.0f%% dari limit (Rp %.0f / Rp %.0f).',
                        $normalizedCategory,
                        $percent,
                        $used,
                        $limit
                    ),
                    'time_label' => 'just now',
                    'read' => false,
                    'event_key' => $eventKey,
                ]);
            }
        }
    }
}

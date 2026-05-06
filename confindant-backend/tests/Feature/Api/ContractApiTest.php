<?php

namespace Tests\Feature\Api;

use Laravel\Sanctum\Sanctum;
use Tests\Feature\Api\Concerns\ApiAuthHelpers;
use Tests\TestCase;

class ContractApiTest extends TestCase
{
    use ApiAuthHelpers;

    public function test_dashboard_analytics_and_profile_contract_shape(): void
    {
        [$user] = $this->createUserWithToken(
            username: 'contract-user',
            email: 'contract@example.com'
        );
        Sanctum::actingAs($user);

        $this
            ->getJson('/api/v1/dashboard')
            ->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'summary' => ['balance', 'income', 'expense', 'last_updated_label'],
                    'cashflow_forecast' => [
                        'next_7_days' => [
                            'horizon_days',
                            'base_balance',
                            'predicted_income',
                            'predicted_expense',
                            'predicted_net',
                            'predicted_balance',
                            'avg_daily_net',
                            'will_go_negative',
                            'negative_on_date',
                            'days_to_negative',
                            'confidence',
                            'provider',
                            'generated_at',
                        ],
                        'next_30_days' => [
                            'horizon_days',
                            'base_balance',
                            'predicted_income',
                            'predicted_expense',
                            'predicted_net',
                            'predicted_balance',
                            'avg_daily_net',
                            'will_go_negative',
                            'negative_on_date',
                            'days_to_negative',
                            'confidence',
                            'provider',
                            'generated_at',
                        ],
                    ],
                    'quick_actions',
                    'budget_items',
                    'recent_transactions',
                    'insight_text',
                ],
                'meta',
            ]);

        $this
            ->getJson('/api/v1/analytics?period=weekly')
            ->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'summary' => ['total_income', 'total_expense', 'net_saving'],
                    'category_breakdown',
                    'income_breakdown',
                    'trend_points',
                    'income_trend_points',
                    'net_flow_trend',
                    'budget_progress',
                    'budget_recommendations',
                    'comparison' => ['mode', 'current_value', 'previous_value', 'delta_percent'],
                    'anomaly' => ['category', 'spike_percent', 'message'],
                    'insight_text',
                ],
                'meta',
            ]);

        $this
            ->postJson('/api/v1/ai/transactions/parse-input', [
                'transcript' => 'Tambah pemasukan 500000 dari freelance',
                'locale' => 'id',
            ])
            ->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'type',
                    'amount',
                    'category',
                    'source',
                    'merchant_name',
                    'notes',
                    'date',
                    'confidence',
                    'provider',
                    'fallback',
                ],
                'meta',
            ]);

        $this
            ->getJson('/api/v1/ai/cashflow-forecast?days=30')
            ->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'horizon_days',
                    'base_balance',
                    'predicted_income',
                    'predicted_expense',
                    'predicted_net',
                    'predicted_balance',
                    'avg_daily_net',
                    'will_go_negative',
                    'negative_on_date',
                    'days_to_negative',
                    'confidence',
                    'provider',
                    'generated_at',
                ],
                'meta',
            ]);

        $this
            ->getJson('/api/v1/ai/budget-recommendations')
            ->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'message',
                'data',
                'meta',
            ]);

        $this
            ->getJson('/api/v1/ai/budget-simulation?category=Food&change_percent=-10')
            ->assertStatus(404);

        $this
            ->getJson('/api/v1/ai/ocr-metrics?days=30')
            ->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'window_days',
                    'jobs' => [
                        'total',
                        'success',
                        'failed',
                        'pending_or_processing',
                        'success_rate_percent',
                        'avg_confidence',
                    ],
                    'feedback' => [
                        'total',
                        'accepted',
                        'acceptance_rate_percent',
                    ],
                    'top_changed_fields',
                    'error_code_breakdown',
                ],
                'meta',
            ]);

        $this
            ->postJson('/api/v1/ai/finance-query', [
                'query' => 'bulan ini paling boros di mana?',
                'locale' => 'id',
            ])
            ->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'history_id',
                    'query',
                    'period' => ['label', 'from', 'to'],
                    'answer',
                    'insight',
                    'suggested_actions',
                    'metrics',
                    'provider',
                    'fallback',
                ],
                'meta',
            ]);

        $this
            ->getJson('/api/v1/ai/finance-query/history?limit=10')
            ->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'message',
                'data',
                'meta',
            ]);

        $this
            ->getJson('/api/v1/profile')
            ->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'profile' => [
                        'id',
                        'user_id',
                        'full_name',
                        'username',
                        'email',
                        'notification_settings',
                        'faq_items',
                        'about_info',
                    ],
                    'notifications',
                ],
                'meta',
            ]);

        $dashboardOne = $this->getJson('/api/v1/dashboard')->assertStatus(200)->json();
        $dashboardTwo = $this->getJson('/api/v1/dashboard')->assertStatus(200)->json();
        $this->assertSame(
            $this->snapshotShape($dashboardOne),
            $this->snapshotShape($dashboardTwo)
        );

        $analyticsOne = $this->getJson('/api/v1/analytics?period=weekly')->assertStatus(200)->json();
        $analyticsTwo = $this->getJson('/api/v1/analytics?period=weekly')->assertStatus(200)->json();
        $this->assertSame(
            $this->snapshotShape($analyticsOne),
            $this->snapshotShape($analyticsTwo)
        );

        $profileOne = $this->getJson('/api/v1/profile')->assertStatus(200)->json();
        $profileTwo = $this->getJson('/api/v1/profile')->assertStatus(200)->json();
        $this->assertSame(
            $this->snapshotShape($profileOne),
            $this->snapshotShape($profileTwo)
        );

        $forecastOne = $this->getJson('/api/v1/ai/cashflow-forecast?days=30')->assertStatus(200)->json();
        $forecastTwo = $this->getJson('/api/v1/ai/cashflow-forecast?days=30')->assertStatus(200)->json();
        $this->assertSame(
            $this->snapshotShape($forecastOne),
            $this->snapshotShape($forecastTwo)
        );

        $recommendationOne = $this->getJson('/api/v1/ai/budget-recommendations')->assertStatus(200)->json();
        $recommendationTwo = $this->getJson('/api/v1/ai/budget-recommendations')->assertStatus(200)->json();
        $this->assertSame(
            $this->snapshotShape($recommendationOne),
            $this->snapshotShape($recommendationTwo)
        );

        $ocrMetricsOne = $this->getJson('/api/v1/ai/ocr-metrics?days=30')->assertStatus(200)->json();
        $ocrMetricsTwo = $this->getJson('/api/v1/ai/ocr-metrics?days=30')->assertStatus(200)->json();
        $this->assertSame(
            $this->snapshotShape($ocrMetricsOne),
            $this->snapshotShape($ocrMetricsTwo)
        );
    }

    private function snapshotShape(mixed $value): mixed
    {
        if (is_array($value)) {
            $isList = array_is_list($value);
            if ($isList) {
                if ($value === []) {
                    return ['type' => 'list', 'item' => 'empty'];
                }

                return [
                    'type' => 'list',
                    'item' => $this->snapshotShape($value[0]),
                ];
            }

            ksort($value);
            $out = [];
            foreach ($value as $key => $item) {
                $out[$key] = $this->snapshotShape($item);
            }

            return $out;
        }

        return gettype($value);
    }
}

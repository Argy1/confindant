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
                    'trend_points',
                    'budget_progress',
                    'insight_text',
                ],
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

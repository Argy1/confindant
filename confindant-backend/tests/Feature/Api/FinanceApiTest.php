<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Http\UploadedFile;
use Laravel\Sanctum\Sanctum;
use Tests\Feature\Api\Concerns\ApiAuthHelpers;
use Tests\TestCase;

class FinanceApiTest extends TestCase
{
    use ApiAuthHelpers;

    public function test_wallet_budget_transaction_dashboard_and_analytics(): void
    {
        [$user] = $this->createUserWithToken(
            username: 'finance-user',
            email: 'finance@example.com'
        );
        Sanctum::actingAs($user);

        $wallet = $this
            ->postJson('/api/v1/wallets', [
                'wallet_name' => 'Main Wallet',
                'balance' => 1000000,
            ])
            ->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => ['id', 'wallet_name', 'balance', 'user_id'],
                'meta',
            ])
            ->json('data');

        $income = $this
            ->postJson('/api/v1/transactions', [
                'wallet_id' => $wallet['_id'] ?? $wallet['id'],
                'type' => 'income',
                'source' => 'Salary',
                'category' => 'Salary',
                'total_amount' => 2500000,
                'date' => now()->toIso8601String(),
                'merchant_name' => 'Payroll',
                'notes' => 'Monthly salary',
                'tags' => ['kerja', 'urgent'],
                'is_verified' => true,
                'items' => [],
            ])
            ->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.source', 'Salary')
            ->assertJsonPath('data.tags.0', 'kerja')
            ->assertJsonPath('data.ai_provider', 'manual')
            ->json('data');

        $aiSuggestion = $this
            ->postJson('/api/v1/ai/transactions/categorize', [
                'type' => 'expense',
                'merchant_name' => 'Coffee Shop',
                'notes' => 'Morning coffee',
                'total_amount' => 35000,
            ])
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->json('data');
        $this->assertNotEmpty($aiSuggestion['category'] ?? null);

        $this
            ->postJson('/api/v1/ai/transactions/parse-input', [
                'transcript' => 'Tambah pemasukan gaji 2500000 hari ini',
                'locale' => 'id',
            ])
            ->assertStatus(200)
            ->assertJsonPath('success', true)
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
            ->postJson('/api/v1/ai/transactions/feedback', [
                'suggested_category' => $aiSuggestion['category'] ?? 'Food',
                'final_category' => 'Food',
                'accepted' => true,
                'confidence' => 0.8,
                'provider' => 'gemini',
                'input_context' => [
                    'merchant_name' => 'Coffee Shop',
                    'notes' => 'Morning coffee',
                ],
            ])
            ->assertStatus(201)
            ->assertJsonPath('success', true);

        $budget = $this
            ->postJson('/api/v1/budgets', [
                'category' => 'Food',
                'limit_amount' => 500000,
                'period_month' => '03-2026',
                'alert_threshold' => 80,
            ])
            ->assertStatus(201)
            ->assertJsonPath('success', true)
            ->json('data');

        $recurring = $this
            ->postJson('/api/v1/recurring-transactions', [
                'wallet_id' => $wallet['_id'] ?? $wallet['id'],
                'type' => 'income',
                'source' => 'Recurring Salary',
                'category' => 'Salary',
                'amount' => 100000,
                'frequency' => 'daily',
                'interval' => 1,
                'start_date' => now()->subDays(2)->toIso8601String(),
                'next_run_at' => now()->subMinute()->toIso8601String(),
                'active' => true,
            ])
            ->assertStatus(201)
            ->assertJsonPath('success', true)
            ->json('data');

        $this->artisan('recurring:process')
            ->assertExitCode(0);

        $this
            ->getJson('/api/v1/recurring-transactions')
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.0.id', $recurring['id'] ?? $recurring['_id']);

        $expense = $this
            ->postJson('/api/v1/transactions', [
                'wallet_id' => $wallet['_id'] ?? $wallet['id'],
                'type' => 'expense',
                'category' => 'Food',
                'total_amount' => 125000,
                'date' => now()->toIso8601String(),
                'merchant_name' => 'Cafe',
                'notes' => 'Lunch',
                'is_verified' => true,
                'items' => [],
            ])
            ->assertStatus(201)
            ->assertJsonPath('success', true)
            ->json('data');

        $walletState = $this
            ->getJson('/api/v1/wallets/'.($wallet['id'] ?? $wallet['_id']))
            ->assertStatus(200)
            ->json('data');
        $this->assertEquals(3475000.0, (float) ($walletState['balance'] ?? 0));

        $this
            ->postJson('/api/v1/transactions', [
                'wallet_id' => $wallet['_id'] ?? $wallet['id'],
                'type' => 'expense',
                'category' => 'Over Limit',
                'total_amount' => 99999999,
                'date' => now()->toIso8601String(),
                'merchant_name' => 'Store',
                'notes' => 'Should fail',
            ])
            ->assertStatus(422);

        $this
            ->patchJson('/api/v1/wallets/'.($wallet['id'] ?? $wallet['_id']), [
                'wallet_name' => 'Updated Wallet',
            ])
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.wallet_name', 'Updated Wallet');

        $this
            ->patchJson('/api/v1/budgets/'.($budget['id'] ?? $budget['_id']), [
                'category' => 'Food & Drinks',
                'limit_amount' => 750000,
            ])
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.category', 'Food & Drinks');

        $this
            ->patchJson('/api/v1/transactions/'.($expense['id'] ?? $expense['_id']), [
                'merchant_name' => 'Cafe Updated',
                'total_amount' => 130000,
                'source' => 'Food Spending',
            ])
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.merchant_name', 'Cafe Updated')
            ->assertJsonPath('data.source', 'Food Spending');

        $this
            ->getJson('/api/v1/dashboard')
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.summary.income', 2600000)
            ->assertJsonPath('data.summary.expense', 130000)
            ->assertJsonStructure([
                'data' => [
                    'cashflow_forecast' => [
                        'next_7_days' => ['horizon_days', 'predicted_balance', 'confidence', 'provider'],
                        'next_30_days' => ['horizon_days', 'predicted_balance', 'confidence', 'provider'],
                    ],
                ],
            ]);

        $this
            ->getJson('/api/v1/analytics?period=monthly')
            ->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'summary',
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
            ])
            ->assertJsonPath('success', true);

        $this
            ->getJson('/api/v1/ai/cashflow-forecast?days=30')
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.horizon_days', 30)
            ->assertJsonStructure([
                'data' => ['predicted_balance', 'predicted_income', 'predicted_expense', 'confidence'],
            ]);

        $this
            ->getJson('/api/v1/ai/budget-recommendations')
            ->assertStatus(200)
            ->assertJsonPath('success', true);

        $this
            ->getJson('/api/v1/ai/budget-simulation?category=Food%20%26%20Drinks&change_percent=-10')
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.category', 'Food & Drinks')
            ->assertJsonPath('data.change_percent', -10);

        $financeQuery = $this
            ->postJson('/api/v1/ai/finance-query', [
                'query' => 'bulan ini paling boros di mana?',
                'locale' => 'id',
            ])
            ->assertStatus(200)
            ->assertJsonPath('success', true)
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
                    'metrics' => ['transaction_count', 'total_income', 'total_expense', 'net_flow'],
                    'provider',
                    'fallback',
                ],
                'meta',
            ])
            ->json('data');

        $historyId = (string) ($financeQuery['history_id'] ?? '');
        $this->assertNotSame('', $historyId);

        $this
            ->getJson('/api/v1/ai/finance-query/history?limit=10')
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    ['id', 'query', 'answer', 'provider', 'fallback', 'created_at'],
                ],
                'meta',
            ]);

        $this
            ->deleteJson('/api/v1/ai/finance-query/history')
            ->assertStatus(200)
            ->assertJsonPath('success', true);

        $this
            ->patchJson('/api/v1/ai/finance-query/history/'.$historyId, [
                'query' => 'query rename test',
            ])
            ->assertStatus(404);

        $secondQuery = $this
            ->postJson('/api/v1/ai/finance-query', [
                'query' => 'cashflow 30 hari terakhir bagaimana?',
                'locale' => 'id',
            ])
            ->assertStatus(200)
            ->json('data');
        $secondHistoryId = (string) ($secondQuery['history_id'] ?? '');
        $this->assertNotSame('', $secondHistoryId);

        $this
            ->patchJson('/api/v1/ai/finance-query/history/'.$secondHistoryId, [
                'query' => 'query sudah diubah',
            ])
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.query', 'query sudah diubah');

        $this
            ->deleteJson('/api/v1/ai/finance-query/history/'.$secondHistoryId)
            ->assertStatus(200)
            ->assertJsonPath('success', true);

        $this
            ->getJson('/api/v1/ai/finance-query/history?limit=10')
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonCount(0, 'data');

        $walletTwo = $this
            ->postJson('/api/v1/wallets', [
                'wallet_name' => 'Travel Wallet',
                'balance' => 250000,
            ])
            ->assertStatus(201)
            ->json('data');

        $this
            ->postJson('/api/v1/wallets/transfer', [
                'from_wallet_id' => $wallet['id'] ?? $wallet['_id'],
                'to_wallet_id' => $walletTwo['id'] ?? $walletTwo['_id'],
                'amount' => 100000,
                'notes' => 'Move to travel wallet',
            ])
            ->assertStatus(201)
            ->assertJsonPath('success', true);

        $walletListAfterTransfer = $this
            ->getJson('/api/v1/wallets')
            ->assertStatus(200)
            ->json('data');
        $mainId = (string) ($wallet['id'] ?? $wallet['_id']);
        $travelId = (string) ($walletTwo['id'] ?? $walletTwo['_id']);
        $mainAfterTransfer = collect($walletListAfterTransfer)
            ->first(fn ($item) => (string) ($item['id'] ?? $item['_id'] ?? '') === $mainId);
        $travelAfterTransfer = collect($walletListAfterTransfer)
            ->first(fn ($item) => (string) ($item['id'] ?? $item['_id'] ?? '') === $travelId);
        $this->assertNotNull($mainAfterTransfer);
        $this->assertNotNull($travelAfterTransfer);
        $this->assertEquals(3370000.0, (float) ($mainAfterTransfer['balance'] ?? 0));
        $this->assertEquals(350000.0, (float) ($travelAfterTransfer['balance'] ?? 0));

        $this
            ->getJson('/api/v1/dashboard')
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.summary.income', 2600000)
            ->assertJsonPath('data.summary.expense', 130000);

        $this
            ->postJson('/api/v1/transactions', [
                'wallet_id' => $walletTwo['id'] ?? $walletTwo['_id'],
                'type' => 'expense',
                'category' => 'Transport',
                'total_amount' => 70000,
                'date' => now()->toIso8601String(),
                'merchant_name' => 'Taxi',
                'notes' => 'Ride',
                'is_verified' => true,
                'items' => [],
            ])
            ->assertStatus(201);

        $this
            ->postJson('/api/v1/transactions', [
                'wallet_id' => $wallet['id'] ?? $wallet['_id'],
                'type' => 'expense',
                'category' => 'Food & Drinks',
                'total_amount' => 560000,
                'date' => now()->toIso8601String(),
                'merchant_name' => 'Big Dinner',
                'notes' => 'Trigger budget alert',
                'is_verified' => true,
                'items' => [],
            ])
            ->assertStatus(201);

        $notifications = $this
            ->getJson('/api/v1/notifications')
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'success',
                'message',
                'data',
                'meta',
            ])
            ->json('data');

        $titles = collect($notifications)->pluck('title')->filter()->values()->all();
        $this->assertContains('Transfer Wallet Berhasil', $titles);
        $this->assertContains('Budget Alert', $titles);

        $this
            ->getJson('/api/v1/analytics?period=monthly&wallet_id='.($walletTwo['id'] ?? $walletTwo['_id']).'&category=Transport')
            ->assertStatus(200)
            ->assertJsonPath('success', true);

        $this
            ->getJson('/api/v1/transactions?type=income')
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.0.type', 'income');

        $this
            ->getJson('/api/v1/transactions?tag=kerja&q=payroll')
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.0.type', 'income')
            ->assertJsonPath('data.0.tags.0', 'kerja');

        $this
            ->postJson('/api/v1/goals', [
                'name' => 'Emergency Fund',
                'target_amount' => 1000000,
                'target_date_label' => 'Dec 2026',
                'linked_wallet' => 'Main Wallet',
                'auto_topup_enabled' => true,
                'auto_topup_percent' => 10,
            ])
            ->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.name', 'Emergency Fund')
            ->assertJsonPath('data.auto_topup_enabled', true)
            ->assertJsonPath('data.auto_topup_percent', 10);

        $this
            ->postJson('/api/v1/transactions', [
                'wallet_id' => $wallet['_id'] ?? $wallet['id'],
                'type' => 'income',
                'source' => 'Freelance',
                'category' => 'Freelance',
                'total_amount' => 500000,
                'date' => now()->toIso8601String(),
                'merchant_name' => 'Client Transfer',
                'notes' => 'Should trigger goal auto-topup',
                'is_verified' => true,
                'items' => [],
            ])
            ->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('meta.auto_topup_applied.0.amount', 50000);

        $goal = $this->getJson('/api/v1/goals')->assertStatus(200)->json('data.0');
        $this->assertEquals(50000.0, (float) ($goal['current_amount'] ?? 0));
        $this
            ->patchJson('/api/v1/goals/'.($goal['id'] ?? $goal['_id']), [
                'name' => 'Emergency Fund Plus',
            ])
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.name', 'Emergency Fund Plus');

        $habit = $this
            ->postJson('/api/v1/habits', [
                'title' => 'No Coffee',
                'description' => 'Skip buying coffee outside',
                'target_count' => 3,
                'frequency' => 'weekly',
                'active' => true,
            ])
            ->assertStatus(201)
            ->json('data');

        $this
            ->patchJson('/api/v1/habits/'.($habit['id'] ?? $habit['_id']), [
                'active' => false,
            ])
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.active', false);

        $this
            ->getJson('/api/v1/habits')
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'success',
                'message',
                'data',
                'meta' => ['streak' => ['current_streak', 'longest_streak', 'last_updated_label', 'badge_title']],
            ]);

        $this
            ->postJson('/api/v1/transactions/scan-upload', [
                'wallet_id' => $wallet['id'] ?? $wallet['_id'],
                'type' => 'expense',
                'category' => 'Food',
                'total_amount' => 99000,
                'date' => now()->toIso8601String(),
                'merchant_name' => 'Mini Market',
                'notes' => 'From upload',
                'is_verified' => true,
                'items' => [],
                'receipt_image' => UploadedFile::fake()->image('receipt.jpg'),
            ])
            ->assertStatus(201)
            ->assertJsonPath('success', true);

        $this
            ->postJson('/api/v1/transactions/scan-upload', [
                'wallet_id' => $wallet['id'] ?? $wallet['_id'],
                'type' => 'expense',
                'category' => 'Food',
                'total_amount' => 99000,
                'date' => now()->toIso8601String(),
                'merchant_name' => 'Mini Market',
                'notes' => 'invalid upload',
                'is_verified' => true,
                'items' => [],
                'receipt_image' => UploadedFile::fake()->create('receipt.pdf', 10, 'application/pdf'),
            ])
            ->assertStatus(422);

        $this
            ->postJson('/api/v1/transactions/scan-upload', [
                'wallet_id' => $wallet['id'] ?? $wallet['_id'],
                'type' => 'expense',
                'category' => 'Food',
                'total_amount' => 99000,
                'date' => now()->toIso8601String(),
                'merchant_name' => 'Mini Market',
                'notes' => 'invalid payload',
                'is_verified' => true,
                'items' => 'invalid-items',
            ])
            ->assertStatus(422);

        $this
            ->postJson('/api/v1/transactions/scan-upload', [
                'wallet_id' => $wallet['id'] ?? $wallet['_id'],
                'type' => 'expense',
                'category' => 'Food',
                'total_amount' => 99000,
                'date' => now()->toIso8601String(),
                'merchant_name' => 'Mini Market',
                'notes' => 'oversize upload',
                'is_verified' => true,
                'items' => [],
                'receipt_image' => UploadedFile::fake()->image('oversize.jpg')->size(7000),
            ])
            ->assertStatus(422);

        $other = User::create([
            'username' => 'other-user',
            'email' => 'other@example.com',
            'password' => bcrypt('secret123'),
        ]);
        Sanctum::actingAs($other);
        $this
            ->getJson('/api/v1/wallets/'.($wallet['id'] ?? $wallet['_id']))
            ->assertStatus(404);
        $this
            ->patchJson('/api/v1/budgets/'.($budget['id'] ?? $budget['_id']), ['limit_amount' => 1])
            ->assertStatus(404);
        $this
            ->deleteJson('/api/v1/transactions/'.($expense['id'] ?? $expense['_id']))
            ->assertStatus(404);
        $this
            ->patchJson('/api/v1/habits/'.($habit['id'] ?? $habit['_id']), ['active' => true])
            ->assertStatus(404);

        Sanctum::actingAs($user);
        $this
            ->deleteJson('/api/v1/transactions/'.($expense['id'] ?? $expense['_id']))
            ->assertStatus(200)
            ->assertJsonPath('success', true);
        $this
            ->deleteJson('/api/v1/transactions/'.($income['id'] ?? $income['_id']))
            ->assertStatus(200)
            ->assertJsonPath('success', true);
        $this
            ->deleteJson('/api/v1/budgets/'.($budget['id'] ?? $budget['_id']))
            ->assertStatus(200)
            ->assertJsonPath('success', true);
        $this
            ->deleteJson('/api/v1/recurring-transactions/'.($recurring['id'] ?? $recurring['_id']))
            ->assertStatus(200)
            ->assertJsonPath('success', true);
        $this
            ->deleteJson('/api/v1/wallets/'.($wallet['id'] ?? $wallet['_id']))
            ->assertStatus(200)
            ->assertJsonPath('success', true);
        $this
            ->deleteJson('/api/v1/wallets/'.($walletTwo['id'] ?? $walletTwo['_id']))
            ->assertStatus(200)
            ->assertJsonPath('success', true);
    }
}

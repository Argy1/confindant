<?php

namespace Tests\Feature\Api;

use Illuminate\Http\UploadedFile;
use Laravel\Sanctum\Sanctum;
use App\Models\User;
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

        $transaction = $this
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

        $this
            ->patchJson('/api/v1/wallets/'.($wallet['id'] ?? $wallet['_id']), [
                'wallet_name' => 'Updated Wallet',
                'balance' => 2000000,
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
            ->patchJson('/api/v1/transactions/'.($transaction['id'] ?? $transaction['_id']), [
                'merchant_name' => 'Cafe Updated',
                'total_amount' => 130000,
            ])
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.merchant_name', 'Cafe Updated');

        $this
            ->getJson('/api/v1/dashboard')
            ->assertStatus(200)
            ->assertJsonPath('success', true);

        $this
            ->getJson('/api/v1/analytics?period=monthly')
            ->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'summary',
                    'category_breakdown',
                    'trend_points',
                    'budget_progress',
                    'insight_text',
                ],
                'meta',
            ])
            ->assertJsonPath('success', true);

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
            ->deleteJson('/api/v1/transactions/'.($transaction['id'] ?? $transaction['_id']))
            ->assertStatus(404);

        Sanctum::actingAs($user);
        $this
            ->deleteJson('/api/v1/transactions/'.($transaction['id'] ?? $transaction['_id']))
            ->assertStatus(200)
            ->assertJsonPath('success', true);
        $this
            ->deleteJson('/api/v1/budgets/'.($budget['id'] ?? $budget['_id']))
            ->assertStatus(200)
            ->assertJsonPath('success', true);
        $this
            ->deleteJson('/api/v1/wallets/'.($wallet['id'] ?? $wallet['_id']))
            ->assertStatus(200)
            ->assertJsonPath('success', true);
    }
}

<?php

namespace Tests\Feature\Api;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Laravel\Sanctum\Sanctum;
use Tests\Feature\Api\Concerns\ApiAuthHelpers;
use Tests\TestCase;

class RateLimitApiTest extends TestCase
{
    use ApiAuthHelpers;
    use RefreshDatabase;

    public function test_ai_inference_endpoint_is_rate_limited(): void
    {
        [$user] = $this->createUserWithToken(
            username: 'limit-user',
            email: 'limit@example.com'
        );
        Sanctum::actingAs($user);

        for ($i = 0; $i < 20; $i++) {
            $this
                ->postJson('/api/v1/ai/transactions/categorize', [
                    'type' => 'expense',
                    'merchant_name' => 'Coffee Shop '.$i,
                    'notes' => 'rate limit check',
                    'total_amount' => 10000,
                ])
                ->assertStatus(200)
                ->assertJsonPath('success', true);
        }

        $this
            ->postJson('/api/v1/ai/transactions/categorize', [
                'type' => 'expense',
                'merchant_name' => 'Should throttle',
                'notes' => 'rate limit check',
                'total_amount' => 12000,
            ])
            ->assertStatus(429);
    }

    public function test_ocr_polling_endpoint_is_rate_limited(): void
    {
        [$user] = $this->createUserWithToken(
            username: 'ocr-limit-user',
            email: 'ocr-limit@example.com'
        );
        Sanctum::actingAs($user);

        $job = $this
            ->postJson('/api/v1/transactions/scan-ocr', [
                'receipt_image' => UploadedFile::fake()->image('receipt.jpg'),
            ])
            ->assertStatus(202)
            ->assertJsonPath('success', true)
            ->json('data');
        $jobId = (string) ($job['id'] ?? $job['_id'] ?? '');
        $this->assertNotSame('', $jobId);

        for ($i = 0; $i < 30; $i++) {
            $this
                ->getJson('/api/v1/transactions/scan-ocr/'.$jobId)
                ->assertStatus(200)
                ->assertJsonPath('success', true);
        }

        $this
            ->getJson('/api/v1/transactions/scan-ocr/'.$jobId)
            ->assertStatus(429);
    }
}


<?php

namespace Tests\Feature\Api;

use App\Jobs\ProcessReceiptOcrJob;
use App\Models\ReceiptOcrJob;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Queue;
use Laravel\Sanctum\Sanctum;
use Tests\Feature\Api\Concerns\ApiAuthHelpers;
use Tests\TestCase;

class ProfileAndContentApiTest extends TestCase
{
    use ApiAuthHelpers;
    use RefreshDatabase;

    public function test_change_password_legal_support_and_ocr_flow(): void
    {
        [$user] = $this->createUserWithToken(
            username: 'profile-user',
            email: 'profile@example.com'
        );
        Sanctum::actingAs($user);

        $this
            ->patchJson('/api/v1/profile/change-password', [
                'current_password' => 'secret123',
                'new_password' => 'NewSecret123!',
                'new_password_confirmation' => 'NewSecret123!',
            ])
            ->assertStatus(200)
            ->assertJsonPath('success', true);

        $this
            ->getJson('/api/v1/legal/privacy')
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => ['title', 'content', 'version', 'effective_date'],
                'meta',
            ]);

        $this
            ->getJson('/api/v1/legal/terms')
            ->assertStatus(200)
            ->assertJsonPath('success', true);

        $this
            ->getJson('/api/v1/support/channels')
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => ['email', 'whatsapp', 'report_hint'],
                'meta',
            ]);

        $wallet = $this
            ->postJson('/api/v1/wallets', [
                'wallet_name' => 'OCR Wallet',
                'balance' => 500000,
            ])
            ->assertStatus(201)
            ->json('data');

        $ocrJob = $this
            ->postJson('/api/v1/transactions/scan-ocr', [
                'receipt_image' => UploadedFile::fake()->image('ocr.jpg'),
            ])
            ->assertStatus(202)
            ->assertJsonPath('success', true)
            ->json('data');

        $jobId = $ocrJob['id'] ?? $ocrJob['_id'];
        $this
            ->getJson('/api/v1/transactions/scan-ocr/'.$jobId)
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => ['id', 'status', 'confidence', 'error_code', 'error_message', 'extracted', 'updated_at'],
                'meta',
            ]);

        $this
            ->postJson('/api/v1/transactions/scan-ocr/'.$jobId.'/commit', [
                'wallet_id' => $wallet['id'] ?? $wallet['_id'],
                'type' => 'expense',
                'category' => 'Food',
                'total_amount' => 10000,
                'tax_amount' => 1000,
                'service_amount' => 500,
                'need_want' => 'needs',
                'date' => now()->toIso8601String(),
                'merchant_name' => 'OCR Merchant',
                'notes' => 'Committed OCR',
                'items' => [],
            ])
            ->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => ['id', 'ocr_status', 'ocr_confidence', 'tax_amount', 'service_amount', 'need_want'],
                'meta',
            ])
            ->assertJsonPath('data.need_want', 'needs');

        $this
            ->postJson('/api/v1/transactions/scan-ocr/'.$jobId.'/feedback', [
                'accepted' => false,
                'source_mode' => 'ocr_commit',
                'changed_fields' => ['total_amount', 'category'],
                'edited_field_count' => 2,
                'field_confidence' => [
                    'merchant_name' => 0.8,
                    'total_amount' => 0.5,
                ],
            ])
            ->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.ocr_job_id', (string) $jobId)
            ->assertJsonPath('data.edited_field_count', 2);

        $this
            ->getJson('/api/v1/ai/ocr-metrics?days=30')
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.jobs.total', 1)
            ->assertJsonPath('data.feedback.total', 1);
    }

    public function test_scan_ocr_submit_returns_pending_when_queued_and_commit_is_blocked(): void
    {
        [$user] = $this->createUserWithToken(
            username: 'ocr-pending-user',
            email: 'ocr-pending@example.com'
        );
        Sanctum::actingAs($user);
        Queue::fake();

        $submitted = $this
            ->postJson('/api/v1/transactions/scan-ocr', [
                'receipt_image' => UploadedFile::fake()->image('ocr_pending.jpg'),
            ])
            ->assertStatus(202)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.status', 'pending')
            ->json('data');

        Queue::assertPushed(ProcessReceiptOcrJob::class);

        $jobId = $submitted['id'] ?? $submitted['_id'];
        $this
            ->getJson('/api/v1/transactions/scan-ocr/'.$jobId)
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.status', 'pending');

        $wallet = $this
            ->postJson('/api/v1/wallets', [
                'wallet_name' => 'Pending OCR Wallet',
                'balance' => 200000,
            ])
            ->assertStatus(201)
            ->json('data');

        $this
            ->postJson('/api/v1/transactions/scan-ocr/'.$jobId.'/commit', [
                'wallet_id' => $wallet['id'] ?? $wallet['_id'],
                'type' => 'expense',
                'category' => 'Food',
                'total_amount' => 10000,
                'date' => now()->toIso8601String(),
                'merchant_name' => 'Not Ready',
                'items' => [],
            ])
            ->assertStatus(422)
            ->assertJsonPath('success', false);

        $this->assertNotNull(
            ReceiptOcrJob::where('id', $jobId)->first(),
            'OCR job should exist in database'
        );
    }
}

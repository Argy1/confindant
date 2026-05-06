<?php

namespace App\Jobs;

use App\Models\ReceiptOcrJob;
use App\Services\ReceiptOcrService;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Log;

class ProcessReceiptOcrJob implements ShouldQueue
{
    use Dispatchable, Queueable, InteractsWithQueue;

    public int $tries = 3;

    public int $timeout = 120;

    public array $backoff = [5, 15, 30];

    public function __construct(public string $ocrJobId)
    {
    }

    public function handle(ReceiptOcrService $ocrService): void
    {
        $job = ReceiptOcrJob::find($this->ocrJobId);
        if (!$job) {
            return;
        }

        if (in_array((string) $job->status, ['success', 'failed'], true)) {
            return;
        }

        $startedAt = $job->started_at ?? now();
        $job->update([
            'status' => 'processing',
            'started_at' => $startedAt,
            'finished_at' => null,
        ]);

        Log::info('ocr_job_processing', [
            'job_id' => (string) $job->_id,
            'user_id' => (string) $job->user_id,
            'attempt' => $this->attempts(),
            'status' => 'processing',
        ]);

        try {
            $result = $ocrService->extract((string) $job->receipt_image_url);
            $extracted = is_array($result['extracted'] ?? null) ? $result['extracted'] : [];
            $confidence = is_numeric($result['confidence'] ?? null) ? (float) $result['confidence'] : 0.78;
            $raw = $this->compactRaw($result['raw'] ?? $result);
            $finishedAt = now();
            $durationMs = (int) round($startedAt->diffInMilliseconds($finishedAt));

            $job->update([
                'status' => 'success',
                'confidence' => $confidence,
                'extracted' => $extracted,
                'raw' => $raw,
                'error_code' => null,
                'error_message' => null,
                'finished_at' => $finishedAt,
            ]);

            Log::info('ocr_job_success', [
                'job_id' => (string) $job->_id,
                'user_id' => (string) $job->user_id,
                'status' => 'success',
                'confidence' => $confidence,
                'duration_ms' => $durationMs,
            ]);
        } catch (\Throwable $e) {
            $errorCode = $this->classifyOcrErrorCode($e->getMessage());
            $job->update([
                'status' => 'processing',
                'error_code' => $errorCode,
                'error_message' => $this->compactErrorMessage($e->getMessage()),
                'confidence' => 0,
                'raw' => $this->compactRaw([
                    'provider' => 'gemini',
                    'attempt' => $this->attempts(),
                    'error' => $e->getMessage(),
                ]),
            ]);

            Log::warning('ocr_job_retrying', [
                'job_id' => (string) $job->_id,
                'user_id' => (string) $job->user_id,
                'attempt' => $this->attempts(),
                'max_attempts' => $this->tries,
                'error_code' => $errorCode,
                'message' => $this->compactErrorMessage($e->getMessage()),
            ]);

            throw $e;
        }
    }

    public function failed(\Throwable $exception): void
    {
        $job = ReceiptOcrJob::find($this->ocrJobId);
        if (!$job) {
            return;
        }

        $errorCode = $this->classifyOcrErrorCode($exception->getMessage());
        $finishedAt = now();
        $startedAt = $job->started_at ?? $finishedAt;
        $durationMs = (int) round($startedAt->diffInMilliseconds($finishedAt));

        $job->update([
            'status' => 'failed',
            'confidence' => 0,
            'error_code' => $errorCode,
            'error_message' => $this->compactErrorMessage($exception->getMessage()),
            'finished_at' => $finishedAt,
            'raw' => $this->compactRaw([
                'provider' => 'gemini',
                'attempt' => $this->attempts(),
                'error' => $exception->getMessage(),
            ]),
        ]);

        Log::error('ocr_job_failed', [
            'job_id' => (string) $job->_id,
            'user_id' => (string) $job->user_id,
            'status' => 'failed',
            'attempt' => $this->attempts(),
            'error_code' => $errorCode,
            'duration_ms' => $durationMs,
            'message' => $this->compactErrorMessage($exception->getMessage()),
        ]);
    }

    private function classifyOcrErrorCode(string $message): string
    {
        $normalized = strtolower($message);

        if (str_contains($normalized, 'resource_exhausted') || str_contains($normalized, '429')) {
            return 'quota_exhausted';
        }
        if (str_contains($normalized, 'api-key') || str_contains($normalized, 'unauthorized') || str_contains($normalized, '403')) {
            return 'auth_failed';
        }
        if (str_contains($normalized, 'timeout')) {
            return 'timeout';
        }
        if (str_contains($normalized, 'json parse')) {
            return 'invalid_response';
        }

        return 'provider_error';
    }

    private function compactRaw(mixed $raw): array
    {
        $encoded = json_encode($raw, JSON_UNESCAPED_UNICODE);
        if (!is_string($encoded)) {
            return ['truncated' => true, 'preview' => 'raw-unserializable'];
        }
        if (strlen($encoded) <= 12000 && is_array($raw)) {
            return $raw;
        }

        return [
            'truncated' => true,
            'preview' => substr($encoded, 0, 12000),
        ];
    }

    private function compactErrorMessage(string $message): string
    {
        $trimmed = trim($message);
        if ($trimmed === '') {
            return 'Unknown OCR provider error';
        }
        if (strlen($trimmed) <= 300) {
            return $trimmed;
        }

        return substr($trimmed, 0, 300).'...';
    }
}

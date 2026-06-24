<?php

namespace App\Http\Controllers\Api;

use App\Jobs\ProcessReceiptOcrJob;
use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\ReceiptOcrFeedback;
use App\Models\ReceiptOcrJob;
use App\Models\Transaction;
use App\Models\Wallet;
use App\Services\AiCategorizationService;
use App\Services\BudgetAlertService;
use App\Services\GoalAutoTopupService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;

class TransactionController extends Controller
{
    use ApiResponse;

    public function index(Request $request)
    {
        $validated = $request->validate([
            'type' => 'nullable|in:income,expense,all',
            'wallet_id' => 'nullable|string',
            'from_date' => 'nullable|date',
            'to_date' => 'nullable|date',
            'tag' => 'nullable|string|max:64',
            'q' => 'nullable|string|max:255',
            'per_page' => 'nullable|integer|min:1|max:100',
            'page' => 'nullable|integer|min:1',
        ]);

        $perPage = max(1, min((int) $request->query('per_page', 20), 100));
        $page = max(1, (int) $request->query('page', 1));

        $query = Transaction::where('user_id', (string) $request->user()->id)
            ->orderBy('date', 'desc')
            ->orderBy('created_at', 'desc');

        $type = $validated['type'] ?? 'all';
        if ($type !== 'all') {
            $query->where('type', $type);
        }

        if (!empty($validated['wallet_id'])) {
            $query->where('wallet_id', $validated['wallet_id']);
        }

        if (!empty($validated['from_date'])) {
            $query->where('date', '>=', Carbon::parse($validated['from_date'])->startOfDay());
        }

        if (!empty($validated['to_date'])) {
            $query->where('date', '<=', Carbon::parse($validated['to_date'])->endOfDay());
        }

        $transactions = $query->get();

        $tag = trim((string) ($validated['tag'] ?? ''));
        if ($tag !== '') {
            $transactions = $transactions->filter(function ($transaction) use ($tag) {
                $tags = is_array($transaction->tags) ? $transaction->tags : [];
                return in_array($tag, array_map(fn ($item) => (string) $item, $tags), true);
            })->values();
        }

        $search = trim((string) ($validated['q'] ?? ''));
        if ($search !== '') {
            $normalizedSearch = mb_strtolower($search);
            $transactions = $transactions->filter(function ($transaction) use ($normalizedSearch) {
                $tags = is_array($transaction->tags) ? $transaction->tags : [];
                $haystacks = array_filter([
                    $transaction->merchant_name ? (string) $transaction->merchant_name : null,
                    $transaction->category ? (string) $transaction->category : null,
                    $transaction->source ? (string) $transaction->source : null,
                    $transaction->notes ? (string) $transaction->notes : null,
                    implode(' ', array_map(fn ($tag) => (string) $tag, $tags)),
                ]);

                foreach ($haystacks as $text) {
                    if (mb_stripos($text, $normalizedSearch) !== false) {
                        return true;
                    }
                }

                return false;
            })->values();
        }

        $total = $transactions->count();
        $transactions = $transactions
            ->slice(($page - 1) * $perPage, $perPage)
            ->values();

        return $this->ok($transactions, 'Daftar transaksi berhasil diambil', [
            'page' => $page,
            'per_page' => $perPage,
            'total' => $total,
            'has_more' => ($page * $perPage) < $total,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'wallet_id' => 'required|string',
            'type' => 'required|in:income,expense',
            'source' => 'nullable|string|max:255',
            'category' => 'nullable|string|max:255',
            'total_amount' => 'required|numeric|min:0',
            'tax_amount' => 'nullable|numeric|min:0',
            'service_amount' => 'nullable|numeric|min:0',
            'need_want' => 'nullable|in:needs,wants,mixed,unknown',
            'date' => 'required|date',
            'merchant_name' => 'nullable|string|max:255',
            'receipt_image_url' => 'nullable|string|max:2048',
            'notes' => 'nullable|string',
            'is_verified' => 'nullable|boolean',
            'items' => 'nullable|array',
            'tags' => 'nullable|array',
            'tags.*' => 'string|max:64',
            'is_internal_transfer' => 'nullable|boolean',
            'transfer_group_id' => 'nullable|string|max:128',
        ]);

        $userId = (string) $request->user()->id;
        $wallet = $this->findOwnedWallet($userId, (string) $validated['wallet_id']);
        if (!$wallet) {
            return $this->fail('Wallet tidak ditemukan', [], 404);
        }

        $source = $validated['source'] ?? ($validated['type'] === 'income' ? 'Other' : null);
        $signedAmount = $this->signedAmount((string) $validated['type'], (float) $validated['total_amount']);
        $newBalance = (float) $wallet->balance + $signedAmount;
        if ($newBalance < 0) {
            return $this->fail('Saldo wallet tidak mencukupi untuk expense ini', [], 422);
        }

        $transaction = Transaction::create([
            ...$validated,
            'source' => $source,
            'is_verified' => $validated['is_verified'] ?? false,
            'user_id' => $userId,
            'ocr_status' => 'none',
            'ocr_confidence' => null,
            'ocr_raw' => null,
            'tags' => $this->normalizeTags($validated['tags'] ?? []),
            'ai_category' => null,
            'ai_confidence' => null,
            'ai_suggested' => false,
            'ai_provider' => null,
            'is_internal_transfer' => $validated['is_internal_transfer'] ?? false,
            'transfer_group_id' => $validated['transfer_group_id'] ?? null,
        ]);
        $this->applyAiCategory($transaction, $validated);
        $wallet->update(['balance' => $newBalance]);
        $this->triggerBudgetAlert($userId, $transaction->category, $transaction->type, (bool) $transaction->is_internal_transfer);
        $autoTopupApplied = $this->triggerGoalAutoTopup($transaction);

        return $this->ok($transaction, 'Transaksi berhasil disimpan', [
            'auto_topup_applied' => $autoTopupApplied,
        ], 201);
    }

    public function show(Request $request, string $id)
    {
        $transaction = Transaction::where('id', $id)
            ->where('user_id', (string) $request->user()->id)
            ->first();

        if (!$transaction) {
            return $this->fail('Transaksi tidak ditemukan', [], 404);
        }

        return $this->ok($transaction, 'Detail transaksi berhasil diambil');
    }

    public function update(Request $request, string $id)
    {
        $transaction = Transaction::where('id', $id)
            ->where('user_id', (string) $request->user()->id)
            ->first();

        if (!$transaction) {
            return $this->fail('Transaksi tidak ditemukan', [], 404);
        }

        $validated = $request->validate([
            'wallet_id' => 'sometimes|required|string',
            'type' => 'sometimes|required|in:income,expense',
            'source' => 'nullable|string|max:255',
            'category' => 'nullable|string|max:255',
            'total_amount' => 'sometimes|required|numeric|min:0',
            'tax_amount' => 'nullable|numeric|min:0',
            'service_amount' => 'nullable|numeric|min:0',
            'need_want' => 'nullable|in:needs,wants,mixed,unknown',
            'date' => 'sometimes|required|date',
            'merchant_name' => 'nullable|string|max:255',
            'receipt_image_url' => 'nullable|string|max:2048',
            'notes' => 'nullable|string',
            'is_verified' => 'nullable|boolean',
            'items' => 'nullable|array',
            'tags' => 'nullable|array',
            'tags.*' => 'string|max:64',
            'is_internal_transfer' => 'nullable|boolean',
            'transfer_group_id' => 'nullable|string|max:128',
        ]);

        $userId = (string) $request->user()->id;
        $oldWallet = $this->findOwnedWallet($userId, (string) $transaction->wallet_id);
        if (!$oldWallet) {
            return $this->fail('Wallet transaksi tidak ditemukan', [], 404);
        }

        $newWalletId = (string) ($validated['wallet_id'] ?? $transaction->wallet_id);
        $newWallet = $this->findOwnedWallet($userId, $newWalletId);
        if (!$newWallet) {
            return $this->fail('Wallet tujuan tidak ditemukan', [], 404);
        }

        $oldType = (string) $transaction->type;
        $newType = (string) ($validated['type'] ?? $transaction->type);
        $oldAmount = (float) $transaction->total_amount;
        $newAmount = (float) ($validated['total_amount'] ?? $transaction->total_amount);
        $oldSigned = $this->signedAmount($oldType, $oldAmount);
        $newSigned = $this->signedAmount($newType, $newAmount);

        if ((string) $oldWallet->id === (string) $newWallet->id) {
            $finalBalance = (float) $oldWallet->balance - $oldSigned + $newSigned;
            if ($finalBalance < 0) {
                return $this->fail('Saldo wallet tidak mencukupi untuk perubahan transaksi ini', [], 422);
            }
            $oldWallet->update(['balance' => $finalBalance]);
        } else {
            $oldFinal = (float) $oldWallet->balance - $oldSigned;
            $newFinal = (float) $newWallet->balance + $newSigned;
            if ($oldFinal < 0 || $newFinal < 0) {
                return $this->fail('Saldo wallet tidak mencukupi untuk perubahan transaksi ini', [], 422);
            }
            $oldWallet->update(['balance' => $oldFinal]);
            $newWallet->update(['balance' => $newFinal]);
        }

        if ($newType === 'income' && !array_key_exists('source', $validated)) {
            $validated['source'] = $transaction->source ?: 'Other';
        }
        if ($newType === 'expense' && !array_key_exists('source', $validated)) {
            $validated['source'] = null;
        }
        if (array_key_exists('tags', $validated)) {
            $validated['tags'] = $this->normalizeTags($validated['tags'] ?? []);
        }

        $oldCategory = (string) ($transaction->category ?? '');
        $oldTypeBeforeUpdate = (string) ($transaction->type ?? '');
        $oldInternalTransfer = (bool) ($transaction->is_internal_transfer ?? false);

        $transaction->update($validated);
        $this->applyAiCategory($transaction, $validated);
        $transaction->refresh();
        $this->triggerBudgetAlert($userId, $oldCategory, $oldTypeBeforeUpdate, $oldInternalTransfer);
        $this->triggerBudgetAlert($userId, $transaction->category, $transaction->type, (bool) $transaction->is_internal_transfer);

        return $this->ok($transaction, 'Transaksi berhasil diperbarui');
    }

    public function destroy(Request $request, string $id)
    {
        $transaction = Transaction::where('id', $id)
            ->where('user_id', (string) $request->user()->id)
            ->first();

        if (!$transaction) {
            return $this->fail('Transaksi tidak ditemukan', [], 404);
        }

        $wallet = $this->findOwnedWallet((string) $request->user()->id, (string) $transaction->wallet_id);
        if (!$wallet) {
            return $this->fail('Wallet transaksi tidak ditemukan', [], 404);
        }

        $rollbackAmount = -1 * $this->signedAmount((string) $transaction->type, (float) $transaction->total_amount);
        $newBalance = (float) $wallet->balance + $rollbackAmount;
        if ($newBalance < 0) {
            return $this->fail('Saldo wallet tidak valid untuk menghapus transaksi ini', [], 422);
        }

        $wallet->update(['balance' => $newBalance]);
        $this->triggerBudgetAlert(
            (string) $request->user()->id,
            $transaction->category,
            $transaction->type,
            (bool) $transaction->is_internal_transfer
        );
        $transaction->delete();

        return $this->ok(null, 'Transaksi berhasil dihapus');
    }

    public function scanUpload(Request $request)
    {
        $validated = $request->validate([
            'wallet_id' => 'required|string',
            'type' => 'required|in:income,expense',
            'source' => 'nullable|string|max:255',
            'category' => 'nullable|string|max:255',
            'total_amount' => 'required|numeric|min:0',
            'tax_amount' => 'nullable|numeric|min:0',
            'service_amount' => 'nullable|numeric|min:0',
            'need_want' => 'nullable|in:needs,wants,mixed,unknown',
            'date' => 'required|date',
            'merchant_name' => 'nullable|string|max:255',
            'notes' => 'nullable|string',
            'is_verified' => 'nullable|boolean',
            'items' => 'nullable|array',
            'receipt_image' => 'nullable|file|image|max:5120',
            'tags' => 'nullable|array',
            'tags.*' => 'string|max:64',
            'is_internal_transfer' => 'nullable|boolean',
            'transfer_group_id' => 'nullable|string|max:128',
        ]);

        $userId = (string) $request->user()->id;
        $wallet = $this->findOwnedWallet($userId, (string) $validated['wallet_id']);
        if (!$wallet) {
            return $this->fail('Wallet tidak ditemukan', [], 404);
        }

        $source = $validated['source'] ?? ($validated['type'] === 'income' ? 'Other' : null);
        $signedAmount = $this->signedAmount((string) $validated['type'], (float) $validated['total_amount']);
        $newBalance = (float) $wallet->balance + $signedAmount;
        if ($newBalance < 0) {
            return $this->fail('Saldo wallet tidak mencukupi untuk expense ini', [], 422);
        }

        $receiptImageUrl = null;
        if ($request->hasFile('receipt_image')) {
            $path = $request->file('receipt_image')->store('receipts', 'public');
            $receiptImageUrl = Storage::disk('public')->url($path);
        }

        $transaction = Transaction::create([
            ...$validated,
            'source' => $source,
            'receipt_image_url' => $receiptImageUrl,
            'is_verified' => $validated['is_verified'] ?? true,
            'user_id' => $userId,
            'ocr_status' => 'none',
            'ocr_confidence' => null,
            'ocr_raw' => null,
            'tags' => $this->normalizeTags($validated['tags'] ?? []),
            'ai_category' => null,
            'ai_confidence' => null,
            'ai_suggested' => false,
            'ai_provider' => null,
            'is_internal_transfer' => $validated['is_internal_transfer'] ?? false,
            'transfer_group_id' => $validated['transfer_group_id'] ?? null,
        ]);
        $this->applyAiCategory($transaction, $validated);
        $wallet->update(['balance' => $newBalance]);
        $this->triggerBudgetAlert($userId, $transaction->category, $transaction->type, (bool) $transaction->is_internal_transfer);
        $autoTopupApplied = $this->triggerGoalAutoTopup($transaction);

        return $this->ok($transaction, 'Receipt berhasil diupload dan transaksi disimpan', [
            'auto_topup_applied' => $autoTopupApplied,
        ], 201);
    }

    public function submitOcr(Request $request)
    {
        $validated = $request->validate([
            'receipt_image' => 'required|file|image|max:5120',
        ]);

        $path = $validated['receipt_image']->store('receipts', 'public');
        $receiptImageUrl = Storage::disk('public')->url($path);

        $ocrJob = ReceiptOcrJob::create([
            'user_id' => (string) $request->user()->id,
            'status' => 'pending',
            'confidence' => 0,
            'error_code' => null,
            'error_message' => null,
            'receipt_image_url' => $receiptImageUrl,
            'raw' => null,
            'extracted' => null,
            'queued_at' => now(),
            'started_at' => null,
            'finished_at' => null,
        ]);

        $dispatchMode = 'queue';
        try {
            ProcessReceiptOcrJob::dispatch((string) $ocrJob->id);
        } catch (\Throwable $dispatchError) {
            Log::warning('ocr_job_queue_dispatch_failed_fallback_sync', [
                'job_id' => (string) $ocrJob->id,
                'user_id' => (string) $request->user()->id,
                'error' => $dispatchError->getMessage(),
            ]);

            $dispatchMode = 'sync_fallback';
            try {
                ProcessReceiptOcrJob::dispatchSync((string) $ocrJob->id);
            } catch (\Throwable $syncError) {
                $ocrJob->update([
                    'status' => 'failed',
                    'confidence' => 0,
                    'error_code' => 'provider_error',
                    'error_message' => $this->compactErrorMessage($syncError->getMessage()),
                    'finished_at' => now(),
                    'raw' => [
                        'truncated' => true,
                        'preview' => substr((string) $syncError->getMessage(), 0, 1000),
                    ],
                ]);
            }
        }

        Log::info('ocr_job_queued', [
            'job_id' => (string) $ocrJob->id,
            'user_id' => (string) $request->user()->id,
            'status' => 'pending',
            'dispatch_mode' => $dispatchMode,
        ]);

        return $this->ok(
            $ocrJob->fresh(),
            $dispatchMode === 'queue'
                ? 'OCR job submitted'
                : 'OCR diproses dengan fallback mode',
            ['dispatch_mode' => $dispatchMode],
            202
        );
    }

    public function getOcr(Request $request, string $id)
    {
        $ocrJob = ReceiptOcrJob::where('id', $id)
            ->where('user_id', (string) $request->user()->id)
            ->first();

        if (!$ocrJob) {
            return $this->fail('OCR job tidak ditemukan', [], 404);
        }

        return $this->ok($ocrJob, 'OCR job detail berhasil diambil');
    }

    public function commitOcr(Request $request, string $id)
    {
        $ocrJob = ReceiptOcrJob::where('id', $id)
            ->where('user_id', (string) $request->user()->id)
            ->first();

        if (!$ocrJob) {
            return $this->fail('OCR job tidak ditemukan', [], 404);
        }

        if ($ocrJob->status !== 'success') {
            return $this->fail('OCR job belum siap untuk commit', [], 422);
        }

        $validated = $request->validate([
            'wallet_id' => 'required|string',
            'type' => 'required|in:income,expense',
            'source' => 'nullable|string|max:255',
            'category' => 'nullable|string|max:255',
            'total_amount' => 'required|numeric|min:0',
            'tax_amount' => 'nullable|numeric|min:0',
            'service_amount' => 'nullable|numeric|min:0',
            'need_want' => 'nullable|in:needs,wants,mixed,unknown',
            'date' => 'required|date',
            'merchant_name' => 'nullable|string|max:255',
            'notes' => 'nullable|string',
            'is_verified' => 'nullable|boolean',
            'items' => 'nullable|array',
            'tags' => 'nullable|array',
            'tags.*' => 'string|max:64',
            'is_internal_transfer' => 'nullable|boolean',
            'transfer_group_id' => 'nullable|string|max:128',
            'transactions' => 'nullable|array|min:1|max:50',
            'transactions.*.wallet_id' => 'nullable|string',
            'transactions.*.type' => 'required_with:transactions|in:income,expense',
            'transactions.*.source' => 'nullable|string|max:255',
            'transactions.*.category' => 'nullable|string|max:255',
            'transactions.*.total_amount' => 'required_with:transactions|numeric|min:0',
            'transactions.*.tax_amount' => 'nullable|numeric|min:0',
            'transactions.*.service_amount' => 'nullable|numeric|min:0',
            'transactions.*.need_want' => 'nullable|in:needs,wants,mixed,unknown',
            'transactions.*.date' => 'required_with:transactions|date',
            'transactions.*.merchant_name' => 'nullable|string|max:255',
            'transactions.*.notes' => 'nullable|string',
            'transactions.*.is_verified' => 'nullable|boolean',
            'transactions.*.items' => 'nullable|array',
            'transactions.*.tags' => 'nullable|array',
            'transactions.*.tags.*' => 'string|max:64',
            'transactions.*.is_internal_transfer' => 'nullable|boolean',
            'transactions.*.transfer_group_id' => 'nullable|string|max:128',
        ]);

        $userId = (string) $request->user()->id;

        if (!empty($validated['transactions']) && is_array($validated['transactions'])) {
            $createdTransactions = [];
            $autoTopupAppliedAll = [];
            foreach ($validated['transactions'] as $entry) {
                $payload = array_merge(
                    [
                        'wallet_id' => $entry['wallet_id'] ?? $validated['wallet_id'],
                        'type' => $entry['type'] ?? $validated['type'],
                        'source' => $entry['source'] ?? null,
                        'category' => $entry['category'] ?? null,
                        'total_amount' => $entry['total_amount'] ?? 0,
                        'tax_amount' => $entry['tax_amount'] ?? 0,
                        'service_amount' => $entry['service_amount'] ?? 0,
                        'need_want' => $entry['need_want'] ?? 'unknown',
                        'date' => $entry['date'] ?? now()->toIso8601String(),
                        'merchant_name' => $entry['merchant_name'] ?? null,
                        'notes' => $entry['notes'] ?? null,
                        'is_verified' => $entry['is_verified'] ?? true,
                        'items' => $entry['items'] ?? [],
                        'tags' => $entry['tags'] ?? [],
                        'is_internal_transfer' => $entry['is_internal_transfer'] ?? false,
                        'transfer_group_id' => $entry['transfer_group_id'] ?? null,
                    ],
                    ['transactions' => null]
                );
                [$tx, $autoTopupApplied] = $this->createTransactionFromOcrPayload(
                    $userId,
                    $payload,
                    $ocrJob
                );
                $createdTransactions[] = $tx;
                $autoTopupAppliedAll[] = $autoTopupApplied;
            }

            return $this->ok([
                'transactions' => $createdTransactions,
                'count' => count($createdTransactions),
            ], 'OCR result committed ke multi transaksi', [
                'auto_topup_applied' => $autoTopupAppliedAll,
            ], 201);
        }

        [$transaction, $autoTopupApplied] = $this->createTransactionFromOcrPayload(
            $userId,
            $validated,
            $ocrJob
        );

        return $this->ok($transaction, 'OCR result committed ke transaksi', [
            'auto_topup_applied' => $autoTopupApplied,
        ], 201);
    }

    public function submitOcrFeedback(Request $request, string $id)
    {
        $ocrJob = ReceiptOcrJob::where('id', $id)
            ->where('user_id', (string) $request->user()->id)
            ->first();

        if (!$ocrJob) {
            return $this->fail('OCR job tidak ditemukan', [], 404);
        }

        $validated = $request->validate([
            'transaction_id' => 'nullable|string',
            'accepted' => 'required|boolean',
            'source_mode' => 'required|string|max:64',
            'changed_fields' => 'nullable|array',
            'changed_fields.*' => 'string|max:64',
            'edited_field_count' => 'nullable|integer|min:0|max:50',
            'field_confidence' => 'nullable|array',
            'meta' => 'nullable|array',
            'created_at_client' => 'nullable|date',
        ]);

        $feedback = ReceiptOcrFeedback::create([
            'user_id' => (string) $request->user()->id,
            'ocr_job_id' => (string) $ocrJob->id,
            'transaction_id' => $validated['transaction_id'] ?? null,
            'accepted' => (bool) $validated['accepted'],
            'source_mode' => (string) $validated['source_mode'],
            'changed_fields' => array_values(array_unique($validated['changed_fields'] ?? [])),
            'edited_field_count' => (int) ($validated['edited_field_count'] ?? count($validated['changed_fields'] ?? [])),
            'field_confidence' => $validated['field_confidence'] ?? null,
            'meta' => $validated['meta'] ?? null,
            'created_at_client' => $validated['created_at_client'] ?? null,
        ]);

        return $this->ok($feedback, 'OCR feedback berhasil disimpan', [], 201);
    }

    private function findOwnedWallet(string $userId, string $walletId): ?Wallet
    {
        return Wallet::where('id', $walletId)
            ->where('user_id', $userId)
            ->first();
    }

    private function signedAmount(string $type, float $amount): float
    {
        return $type === 'income' ? $amount : (-1 * $amount);
    }

    private function triggerBudgetAlert(string $userId, ?string $category, ?string $type, bool $isInternalTransfer): void
    {
        if ($isInternalTransfer || $type !== 'expense') {
            return;
        }

        app(BudgetAlertService::class)->checkAndNotify($userId, $category);
    }

    private function triggerGoalAutoTopup(Transaction $transaction): array
    {
        return app(GoalAutoTopupService::class)->applyForIncomeTransaction($transaction);
    }

    private function applyAiCategory(Transaction $transaction, array $payload): void
    {
        $category = trim((string) ($transaction->category ?? ''));
        if ($category !== '') {
            $transaction->update([
                'category' => $category,
                'ai_category' => $category,
                'ai_confidence' => 1.0,
                'ai_suggested' => false,
                'ai_provider' => 'manual',
            ]);
            return;
        }

        $result = app(AiCategorizationService::class)->categorize([
            'type' => (string) ($transaction->type ?? ($payload['type'] ?? 'expense')),
            'merchant_name' => (string) ($transaction->merchant_name ?? ($payload['merchant_name'] ?? '')),
            'source' => (string) ($transaction->source ?? ($payload['source'] ?? '')),
            'notes' => (string) ($transaction->notes ?? ($payload['notes'] ?? '')),
            'total_amount' => (float) ($transaction->total_amount ?? ($payload['total_amount'] ?? 0)),
        ]);

        $transaction->update([
            'category' => (string) $result['category'],
            'ai_category' => (string) $result['category'],
            'ai_confidence' => (float) ($result['confidence'] ?? 0),
            'ai_suggested' => true,
            'ai_provider' => (string) ($result['provider'] ?? 'unknown'),
        ]);
    }

    private function compactErrorMessage(string $message): string
    {
        $trimmed = trim($message);
        if ($trimmed === '') {
            return 'Unknown OCR processing error';
        }
        if (strlen($trimmed) <= 300) {
            return $trimmed;
        }

        return substr($trimmed, 0, 300).'...';
    }

    private function createTransactionFromOcrPayload(string $userId, array $payload, ReceiptOcrJob $ocrJob): array
    {
        $wallet = $this->findOwnedWallet($userId, (string) $payload['wallet_id']);
        if (!$wallet) {
            abort(response()->json([
                'success' => false,
                'message' => 'Wallet tidak ditemukan',
                'data' => null,
                'meta' => [],
                'errors' => [],
            ], 404));
        }

        $source = $payload['source'] ?? ($payload['type'] === 'income' ? 'Other' : null);
        $signedAmount = $this->signedAmount((string) $payload['type'], (float) $payload['total_amount']);
        $newBalance = (float) $wallet->balance + $signedAmount;
        if ($newBalance < 0) {
            abort(response()->json([
                'success' => false,
                'message' => 'Saldo wallet tidak mencukupi untuk expense ini',
                'data' => null,
                'meta' => [],
                'errors' => [],
            ], 422));
        }

        $transaction = Transaction::create([
            ...$payload,
            'source' => $source,
            'receipt_image_url' => $ocrJob->receipt_image_url,
            'is_verified' => $payload['is_verified'] ?? true,
            'user_id' => $userId,
            'ocr_status' => $ocrJob->status,
            'ocr_confidence' => $ocrJob->confidence,
            'ocr_raw' => $ocrJob->raw,
            'tags' => $this->normalizeTags($payload['tags'] ?? []),
            'ai_category' => null,
            'ai_confidence' => null,
            'ai_suggested' => false,
            'ai_provider' => null,
            'is_internal_transfer' => $payload['is_internal_transfer'] ?? false,
            'transfer_group_id' => $payload['transfer_group_id'] ?? null,
        ]);
        $this->applyAiCategory($transaction, $payload);
        $wallet->update(['balance' => $newBalance]);
        $this->triggerBudgetAlert($userId, $transaction->category, $transaction->type, (bool) $transaction->is_internal_transfer);
        $autoTopupApplied = $this->triggerGoalAutoTopup($transaction);

        return [$transaction, $autoTopupApplied];
    }

    /**
     * @param array<int, mixed> $tags
     * @return array<int, string>
     */
    private function normalizeTags(array $tags): array
    {
        $normalized = [];
        foreach ($tags as $tag) {
            $value = trim((string) $tag);
            if ($value === '') {
                continue;
            }
            $normalized[] = mb_strtolower($value);
        }

        return array_values(array_unique($normalized));
    }
}

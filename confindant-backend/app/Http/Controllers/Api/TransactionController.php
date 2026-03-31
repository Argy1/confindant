<?php

namespace App\Http\Controllers\Api;

use App\Jobs\ProcessReceiptOcrJob;
use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\ReceiptOcrFeedback;
use App\Models\ReceiptOcrJob;
use App\Models\Transaction;
use App\Models\Wallet;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class TransactionController extends Controller
{
    use ApiResponse;

    public function index(Request $request)
    {
        $transactions = Transaction::where('user_id', (string) $request->user()->_id)
            ->orderBy('date', 'desc')
            ->get();

        return $this->ok($transactions, 'Daftar transaksi berhasil diambil');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'wallet_id' => 'required|string',
            'type' => 'required|in:income,expense',
            'category' => 'nullable|string|max:255',
            'total_amount' => 'required|numeric|min:0',
            'date' => 'required|date',
            'merchant_name' => 'nullable|string|max:255',
            'receipt_image_url' => 'nullable|string|max:2048',
            'notes' => 'nullable|string',
            'is_verified' => 'nullable|boolean',
            'items' => 'nullable|array',
        ]);
        $userId = (string) $request->user()->_id;
        $wallet = $this->findOwnedWallet($userId, (string) $validated['wallet_id']);
        if (!$wallet) {
            return $this->fail('Wallet tidak ditemukan', [], 404);
        }

        $signedAmount = $this->signedAmount((string) $validated['type'], (float) $validated['total_amount']);
        $newBalance = (float) $wallet->balance + $signedAmount;
        if ($newBalance < 0) {
            return $this->fail('Saldo wallet tidak mencukupi untuk expense ini', [], 422);
        }

        $transaction = Transaction::create([
            ...$validated,
            'is_verified' => $validated['is_verified'] ?? false,
            'user_id' => $userId,
        ]);
        $wallet->update(['balance' => (float) $newBalance]);

        return $this->ok($transaction, 'Transaksi berhasil disimpan', [], 201);
    }

    public function show(Request $request, string $id)
    {
        $transaction = Transaction::where('_id', $id)
            ->where('user_id', (string) $request->user()->_id)
            ->first();

        if (!$transaction) {
            return $this->fail('Transaksi tidak ditemukan', [], 404);
        }

        return $this->ok($transaction, 'Detail transaksi berhasil diambil');
    }

    public function update(Request $request, string $id)
    {
        $transaction = Transaction::where('_id', $id)
            ->where('user_id', (string) $request->user()->_id)
            ->first();

        if (!$transaction) {
            return $this->fail('Transaksi tidak ditemukan', [], 404);
        }

        $validated = $request->validate([
            'wallet_id' => 'sometimes|required|string',
            'type' => 'sometimes|required|in:income,expense',
            'category' => 'nullable|string|max:255',
            'total_amount' => 'sometimes|required|numeric|min:0',
            'date' => 'sometimes|required|date',
            'merchant_name' => 'nullable|string|max:255',
            'receipt_image_url' => 'nullable|string|max:2048',
            'notes' => 'nullable|string',
            'is_verified' => 'nullable|boolean',
            'items' => 'nullable|array',
        ]);

        $userId = (string) $request->user()->_id;
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

        if ((string) $oldWallet->_id === (string) $newWallet->_id) {
            $finalBalance = (float) $oldWallet->balance - $oldSigned + $newSigned;
            if ($finalBalance < 0) {
                return $this->fail('Saldo wallet tidak mencukupi untuk perubahan transaksi ini', [], 422);
            }
            $oldWallet->update(['balance' => (float) $finalBalance]);
        } else {
            $oldFinal = (float) $oldWallet->balance - $oldSigned;
            $newFinal = (float) $newWallet->balance + $newSigned;
            if ($oldFinal < 0 || $newFinal < 0) {
                return $this->fail('Saldo wallet tidak mencukupi untuk perubahan transaksi ini', [], 422);
            }
            $oldWallet->update(['balance' => (float) $oldFinal]);
            $newWallet->update(['balance' => (float) $newFinal]);
        }

        $transaction->update($validated);

        return $this->ok($transaction->fresh(), 'Transaksi berhasil diperbarui');
    }

    public function destroy(Request $request, string $id)
    {
        $transaction = Transaction::where('_id', $id)
            ->where('user_id', (string) $request->user()->_id)
            ->first();

        if (!$transaction) {
            return $this->fail('Transaksi tidak ditemukan', [], 404);
        }
        $wallet = $this->findOwnedWallet((string) $request->user()->_id, (string) $transaction->wallet_id);
        if (!$wallet) {
            return $this->fail('Wallet transaksi tidak ditemukan', [], 404);
        }

        $rollbackAmount = -1 * $this->signedAmount((string) $transaction->type, (float) $transaction->total_amount);
        $newBalance = (float) $wallet->balance + $rollbackAmount;
        if ($newBalance < 0) {
            return $this->fail('Saldo wallet tidak valid untuk menghapus transaksi ini', [], 422);
        }

        $wallet->update(['balance' => (float) $newBalance]);
        $transaction->delete();

        return $this->ok(null, 'Transaksi berhasil dihapus');
    }

    public function scanUpload(Request $request)
    {
        $validated = $request->validate([
            'wallet_id' => 'required|string',
            'type' => 'required|in:income,expense',
            'category' => 'nullable|string|max:255',
            'total_amount' => 'required|numeric|min:0',
            'date' => 'required|date',
            'merchant_name' => 'nullable|string|max:255',
            'notes' => 'nullable|string',
            'is_verified' => 'nullable|boolean',
            'items' => 'nullable|array',
            'receipt_image' => 'nullable|file|image|max:5120',
        ]);
        $userId = (string) $request->user()->_id;
        $wallet = $this->findOwnedWallet($userId, (string) $validated['wallet_id']);
        if (!$wallet) {
            return $this->fail('Wallet tidak ditemukan', [], 404);
        }

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
            'receipt_image_url' => $receiptImageUrl,
            'is_verified' => $validated['is_verified'] ?? true,
            'user_id' => $userId,
        ]);
        $wallet->update(['balance' => (float) $newBalance]);

        return $this->ok($transaction, 'Receipt berhasil diupload dan transaksi disimpan', [], 201);
    }

    public function submitOcr(Request $request)
    {
        $validated = $request->validate([
            'receipt_image' => 'required|file|image|max:5120',
        ]);

        $path = $validated['receipt_image']->store('receipts', 'public');
        $receiptImageUrl = Storage::disk('public')->url($path);

        $ocrJob = ReceiptOcrJob::create([
            'user_id' => (string) $request->user()->_id,
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

        try {
            // Railway free tier: run sync so user does not need queue worker setup.
            ProcessReceiptOcrJob::dispatchSync((string) $ocrJob->_id);
        } catch (\Throwable $e) {
            Log::error('ocr_job_dispatch_sync_failed', [
                'job_id' => (string) $ocrJob->_id,
                'user_id' => (string) $request->user()->_id,
                'message' => $e->getMessage(),
            ]);
            $ocrJob->update([
                'status' => 'failed',
                'confidence' => 0,
                'error_code' => 'provider_error',
                'error_message' => $this->compactErrorMessage($e->getMessage()),
                'finished_at' => now(),
                'raw' => [
                    'truncated' => true,
                    'preview' => substr((string) $e->getMessage(), 0, 1000),
                ],
            ]);
        }

        return $this->ok($ocrJob->fresh(), 'OCR job submitted', [], 202);
    }

    public function getOcr(Request $request, string $id)
    {
        $ocrJob = ReceiptOcrJob::where('_id', $id)
            ->where('user_id', (string) $request->user()->_id)
            ->first();

        if (!$ocrJob) {
            return $this->fail('OCR job tidak ditemukan', [], 404);
        }

        return $this->ok($ocrJob, 'OCR job detail berhasil diambil');
    }

    public function commitOcr(Request $request, string $id)
    {
        $ocrJob = ReceiptOcrJob::where('_id', $id)
            ->where('user_id', (string) $request->user()->_id)
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
            'category' => 'nullable|string|max:255',
            'source' => 'nullable|string|max:255',
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
        ]);

        $userId = (string) $request->user()->_id;
        if (!empty($validated['transactions']) && is_array($validated['transactions'])) {
            $createdTransactions = [];
            foreach ($validated['transactions'] as $entry) {
                $payload = [
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
                ];

                $createdTransactions[] = $this->commitSingleOcrPayload(
                    $userId,
                    $payload,
                    $ocrJob
                );
            }

            return $this->ok([
                'transactions' => $createdTransactions,
                'count' => count($createdTransactions),
            ], 'OCR result committed ke multi transaksi', [], 201);
        }

        $transaction = $this->commitSingleOcrPayload($userId, $validated, $ocrJob);
        return $this->ok($transaction, 'OCR result committed ke transaksi', [], 201);
    }

    public function submitOcrFeedback(Request $request, string $id)
    {
        $ocrJob = ReceiptOcrJob::where('_id', $id)
            ->where('user_id', (string) $request->user()->_id)
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
            'user_id' => (string) $request->user()->_id,
            'ocr_job_id' => (string) $ocrJob->_id,
            'transaction_id' => $validated['transaction_id'] ?? null,
            'accepted' => (bool) $validated['accepted'],
            'source_mode' => (string) $validated['source_mode'],
            'changed_fields' => $validated['changed_fields'] ?? [],
            'edited_field_count' => (int) ($validated['edited_field_count'] ?? count($validated['changed_fields'] ?? [])),
            'field_confidence' => $validated['field_confidence'] ?? null,
            'meta' => $validated['meta'] ?? null,
            'created_at_client' => $validated['created_at_client'] ?? null,
        ]);

        return $this->ok($feedback, 'OCR feedback berhasil disimpan', [], 201);
    }

    private function findOwnedWallet(string $userId, string $walletId): ?Wallet
    {
        return Wallet::where('_id', $walletId)
            ->where('user_id', $userId)
            ->first();
    }

    private function signedAmount(string $type, float $amount): float
    {
        return $type === 'income' ? $amount : (-1 * $amount);
    }

    private function commitSingleOcrPayload(string $userId, array $payload, ReceiptOcrJob $ocrJob): Transaction
    {
        $wallet = $this->findOwnedWallet($userId, (string) $payload['wallet_id']);
        if (!$wallet) {
            abort(response()->json([
                'success' => false,
                'message' => 'Wallet tidak ditemukan',
                'data' => null,
                'errors' => (object) [],
            ], 404));
        }

        $source = $payload['source'] ?? (($payload['type'] ?? 'expense') === 'income' ? 'Other' : null);
        $signedAmount = $this->signedAmount((string) ($payload['type'] ?? 'expense'), (float) ($payload['total_amount'] ?? 0));
        $newBalance = (float) $wallet->balance + $signedAmount;
        if ($newBalance < 0) {
            abort(response()->json([
                'success' => false,
                'message' => 'Saldo wallet tidak mencukupi untuk expense ini',
                'data' => null,
                'errors' => (object) [],
            ], 422));
        }

        $transaction = Transaction::create([
            ...$payload,
            'source' => $source,
            'receipt_image_url' => $ocrJob->receipt_image_url,
            'is_verified' => $payload['is_verified'] ?? true,
            'user_id' => $userId,
            'tags' => $this->normalizeTags($payload['tags'] ?? []),
        ]);
        $wallet->update(['balance' => (float) $newBalance]);

        return $transaction;
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
}

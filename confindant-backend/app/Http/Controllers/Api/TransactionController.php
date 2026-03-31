<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\Transaction;
use App\Models\Wallet;
use Illuminate\Http\Request;
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
        $wallet->increment('balance', $signedAmount);

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
            $oldWallet->increment('balance', $newSigned - $oldSigned);
        } else {
            $oldFinal = (float) $oldWallet->balance - $oldSigned;
            $newFinal = (float) $newWallet->balance + $newSigned;
            if ($oldFinal < 0 || $newFinal < 0) {
                return $this->fail('Saldo wallet tidak mencukupi untuk perubahan transaksi ini', [], 422);
            }
            $oldWallet->increment('balance', -1 * $oldSigned);
            $newWallet->increment('balance', $newSigned);
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

        $wallet->increment('balance', $rollbackAmount);
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
        $wallet->increment('balance', $signedAmount);

        return $this->ok($transaction, 'Receipt berhasil diupload dan transaksi disimpan', [], 201);
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
}

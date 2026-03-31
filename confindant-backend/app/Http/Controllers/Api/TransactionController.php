<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\Transaction;
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

        $transaction = Transaction::create([
            ...$validated,
            'is_verified' => $validated['is_verified'] ?? false,
            'user_id' => (string) $request->user()->_id,
        ]);

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

        $receiptImageUrl = null;
        if ($request->hasFile('receipt_image')) {
            $path = $request->file('receipt_image')->store('receipts', 'public');
            $receiptImageUrl = Storage::disk('public')->url($path);
        }

        $transaction = Transaction::create([
            ...$validated,
            'receipt_image_url' => $receiptImageUrl,
            'is_verified' => $validated['is_verified'] ?? true,
            'user_id' => (string) $request->user()->_id,
        ]);

        return $this->ok($transaction, 'Receipt berhasil diupload dan transaksi disimpan', [], 201);
    }
}

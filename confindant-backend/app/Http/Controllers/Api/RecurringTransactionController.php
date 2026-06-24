<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\RecurringTransaction;
use App\Models\Wallet;
use Carbon\Carbon;
use Illuminate\Http\Request;

class RecurringTransactionController extends Controller
{
    use ApiResponse;

    public function index(Request $request)
    {
        $items = RecurringTransaction::where('user_id', (string) $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return $this->ok($items, 'Daftar recurring transaction berhasil diambil');
    }

    public function store(Request $request)
    {
        $validated = $this->validatePayload($request);
        $userId = (string) $request->user()->id;

        if (!$this->findOwnedWallet($userId, (string) $validated['wallet_id'])) {
            return $this->fail('Wallet tidak ditemukan', [], 404);
        }

        $startDate = Carbon::parse($validated['start_date'])->startOfDay();
        $nextRun = isset($validated['next_run_at'])
            ? Carbon::parse($validated['next_run_at'])
            : $startDate;

        $item = RecurringTransaction::create([
            'user_id' => $userId,
            'wallet_id' => (string) $validated['wallet_id'],
            'type' => (string) $validated['type'],
            'source' => $validated['source'] ?? ($validated['type'] === 'income' ? 'Other' : null),
            'category' => $validated['category'] ?? 'General',
            'amount' => (float) $validated['amount'],
            'merchant_name' => $validated['merchant_name'] ?? null,
            'notes' => $validated['notes'] ?? null,
            'is_verified' => (bool) ($validated['is_verified'] ?? true),
            'tags' => $this->normalizeTags($validated['tags'] ?? []),
            'frequency' => (string) $validated['frequency'],
            'interval' => (int) ($validated['interval'] ?? 1),
            'start_date' => $startDate,
            'next_run_at' => $nextRun,
            'last_run_at' => null,
            'end_date' => isset($validated['end_date']) ? Carbon::parse($validated['end_date'])->endOfDay() : null,
            'active' => (bool) ($validated['active'] ?? true),
            'total_runs' => 0,
            'last_error_code' => null,
            'last_error_message' => null,
        ]);

        return $this->ok($item, 'Recurring transaction berhasil dibuat', [], 201);
    }

    public function show(Request $request, string $id)
    {
        $item = RecurringTransaction::where('id', $id)
            ->where('user_id', (string) $request->user()->id)
            ->first();

        if (!$item) {
            return $this->fail('Recurring transaction tidak ditemukan', [], 404);
        }

        return $this->ok($item, 'Detail recurring transaction berhasil diambil');
    }

    public function update(Request $request, string $id)
    {
        $item = RecurringTransaction::where('id', $id)
            ->where('user_id', (string) $request->user()->id)
            ->first();

        if (!$item) {
            return $this->fail('Recurring transaction tidak ditemukan', [], 404);
        }

        $validated = $this->validatePayload($request, true);
        $userId = (string) $request->user()->id;

        if (isset($validated['wallet_id']) && !$this->findOwnedWallet($userId, (string) $validated['wallet_id'])) {
            return $this->fail('Wallet tidak ditemukan', [], 404);
        }

        if (isset($validated['start_date'])) {
            $validated['start_date'] = Carbon::parse($validated['start_date'])->startOfDay();
        }
        if (isset($validated['next_run_at'])) {
            $validated['next_run_at'] = Carbon::parse($validated['next_run_at']);
        }
        if (array_key_exists('end_date', $validated)) {
            $validated['end_date'] = $validated['end_date'] ? Carbon::parse((string) $validated['end_date'])->endOfDay() : null;
        }
        if (isset($validated['amount'])) {
            $validated['amount'] = (float) $validated['amount'];
        }
        if (array_key_exists('tags', $validated)) {
            $validated['tags'] = $this->normalizeTags($validated['tags'] ?? []);
        }
        if (isset($validated['interval'])) {
            $validated['interval'] = (int) $validated['interval'];
        }

        $item->update($validated);

        return $this->ok($item->fresh(), 'Recurring transaction berhasil diperbarui');
    }

    public function destroy(Request $request, string $id)
    {
        $item = RecurringTransaction::where('id', $id)
            ->where('user_id', (string) $request->user()->id)
            ->first();

        if (!$item) {
            return $this->fail('Recurring transaction tidak ditemukan', [], 404);
        }

        $item->delete();

        return $this->ok(null, 'Recurring transaction berhasil dihapus');
    }

    private function validatePayload(Request $request, bool $partial = false): array
    {
        $required = $partial ? 'sometimes|required' : 'required';
        return $request->validate([
            'wallet_id' => $required.'|string',
            'type' => $required.'|in:income,expense',
            'source' => 'nullable|string|max:255',
            'category' => 'nullable|string|max:255',
            'amount' => $required.'|numeric|min:0.01',
            'merchant_name' => 'nullable|string|max:255',
            'notes' => 'nullable|string',
            'is_verified' => 'nullable|boolean',
            'tags' => 'nullable|array',
            'tags.*' => 'string|max:64',
            'frequency' => $required.'|in:daily,weekly,monthly',
            'interval' => 'nullable|integer|min:1|max:90',
            'start_date' => $required.'|date',
            'next_run_at' => 'nullable|date',
            'end_date' => 'nullable|date',
            'active' => 'nullable|boolean',
        ]);
    }

    private function findOwnedWallet(string $userId, string $walletId): ?Wallet
    {
        return Wallet::where('id', $walletId)
            ->where('user_id', $userId)
            ->first();
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

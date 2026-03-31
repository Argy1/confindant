<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\Transaction;
use App\Models\Wallet;
use Illuminate\Http\Request;

class WalletController extends Controller
{
    use ApiResponse;

    public function index(Request $request)
    {
        $wallets = Wallet::where('user_id', (string) $request->user()->_id)
            ->orderBy('created_at', 'desc')
            ->get();

        return $this->ok($wallets, 'Daftar wallet berhasil diambil');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'wallet_name' => 'required|string|max:255',
            'balance' => 'required|numeric',
            'wallet_color' => 'nullable|string|max:32',
        ]);

        $wallet = Wallet::create([
            ...$validated,
            'user_id' => (string) $request->user()->_id,
        ]);

        return $this->ok($wallet, 'Wallet berhasil dibuat', [], 201);
    }

    public function show(Request $request, string $id)
    {
        $wallet = Wallet::where('_id', $id)
            ->where('user_id', (string) $request->user()->_id)
            ->first();

        if (!$wallet) {
            return $this->fail('Wallet tidak ditemukan', [], 404);
        }

        return $this->ok($wallet, 'Detail wallet berhasil diambil');
    }

    public function update(Request $request, string $id)
    {
        $wallet = Wallet::where('_id', $id)
            ->where('user_id', (string) $request->user()->_id)
            ->first();

        if (!$wallet) {
            return $this->fail('Wallet tidak ditemukan', [], 404);
        }

        $validated = $request->validate([
            'wallet_name' => 'sometimes|required|string|max:255',
            'balance' => 'sometimes|required|numeric',
            'wallet_color' => 'nullable|string|max:32',
        ]);

        $wallet->update($validated);

        return $this->ok($wallet->fresh(), 'Wallet berhasil diperbarui');
    }

    public function destroy(Request $request, string $id)
    {
        $wallet = Wallet::where('_id', $id)
            ->where('user_id', (string) $request->user()->_id)
            ->first();

        if (!$wallet) {
            return $this->fail('Wallet tidak ditemukan', [], 404);
        }

        $wallet->delete();

        return $this->ok(null, 'Wallet berhasil dihapus');
    }

    public function recalculateBalances(Request $request)
    {
        $userId = (string) $request->user()->_id;
        $wallets = Wallet::where('user_id', $userId)->get();

        $updated = [];
        foreach ($wallets as $wallet) {
            $transactions = Transaction::where('user_id', $userId)
                ->where('wallet_id', (string) $wallet->_id)
                ->get();

            $calculatedBalance = $transactions->reduce(function ($carry, $trx) {
                $amount = (float) ($trx->total_amount ?? 0);
                $type = (string) ($trx->type ?? 'expense');
                return $carry + ($type === 'income' ? $amount : (-1 * $amount));
            }, 0.0);

            $wallet->update(['balance' => (float) $calculatedBalance]);

            $updated[] = [
                'wallet_id' => (string) $wallet->_id,
                'wallet_name' => (string) ($wallet->wallet_name ?? 'Wallet'),
                'balance' => (float) $calculatedBalance,
                'transaction_count' => $transactions->count(),
            ];
        }

        return $this->ok([
            'wallets' => $updated,
            'wallet_count' => count($updated),
            'total_balance' => array_reduce(
                $updated,
                fn ($sum, $item) => $sum + (float) ($item['balance'] ?? 0),
                0.0
            ),
        ], 'Saldo wallet berhasil direkalkulasi');
    }
}

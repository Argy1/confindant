<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Controller;
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
}

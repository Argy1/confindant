<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\Transaction;
use App\Models\UserNotification;
use App\Models\Wallet;
use Illuminate\Support\Str;
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

    public function transfer(Request $request)
    {
        $validated = $request->validate([
            'from_wallet_id' => 'required|string',
            'to_wallet_id' => 'required|string|different:from_wallet_id',
            'amount' => 'required|numeric|min:0.01',
            'notes' => 'nullable|string|max:500',
            'date' => 'nullable|date',
        ]);

        $userId = (string) $request->user()->_id;
        $from = Wallet::where('_id', (string) $validated['from_wallet_id'])
            ->where('user_id', $userId)
            ->first();
        $to = Wallet::where('_id', (string) $validated['to_wallet_id'])
            ->where('user_id', $userId)
            ->first();

        if (!$from || !$to) {
            return $this->fail('Wallet sumber/tujuan tidak ditemukan', [], 404);
        }

        $amount = (float) $validated['amount'];
        if ((float) $from->balance < $amount) {
            return $this->fail('Saldo wallet sumber tidak mencukupi', [], 422);
        }

        $transferDate = isset($validated['date']) ? (string) $validated['date'] : now()->toIso8601String();
        $notes = trim((string) ($validated['notes'] ?? 'Internal wallet transfer'));
        $groupId = 'trf_'.Str::uuid()->toString();

        $from->update(['balance' => (float) $from->balance - $amount]);
        $to->update(['balance' => (float) $to->balance + $amount]);

        $outgoing = Transaction::create([
            'user_id' => $userId,
            'wallet_id' => (string) $from->_id,
            'type' => 'expense',
            'source' => null,
            'category' => 'Transfer Out',
            'total_amount' => $amount,
            'date' => $transferDate,
            'merchant_name' => 'Wallet Transfer',
            'receipt_image_url' => null,
            'notes' => $notes,
            'is_verified' => true,
            'items' => [],
            'ocr_status' => 'none',
            'ocr_confidence' => null,
            'ocr_raw' => null,
            'is_internal_transfer' => true,
            'transfer_group_id' => $groupId,
        ]);

        $incoming = Transaction::create([
            'user_id' => $userId,
            'wallet_id' => (string) $to->_id,
            'type' => 'income',
            'source' => 'Transfer In',
            'category' => 'Transfer In',
            'total_amount' => $amount,
            'date' => $transferDate,
            'merchant_name' => 'Wallet Transfer',
            'receipt_image_url' => null,
            'notes' => $notes,
            'is_verified' => true,
            'items' => [],
            'ocr_status' => 'none',
            'ocr_confidence' => null,
            'ocr_raw' => null,
            'is_internal_transfer' => true,
            'transfer_group_id' => $groupId,
        ]);

        UserNotification::create([
            'user_id' => $userId,
            'title' => 'Transfer Wallet Berhasil',
            'subtitle' => sprintf(
                'Rp %.0f dipindahkan dari %s ke %s.',
                $amount,
                (string) $from->wallet_name,
                (string) $to->wallet_name
            ),
            'time_label' => 'just now',
            'read' => false,
            'event_key' => 'wallet_transfer:'.$groupId,
        ]);

        return $this->ok([
            'transfer_group_id' => $groupId,
            'from_wallet' => $from->fresh(),
            'to_wallet' => $to->fresh(),
            'outgoing_transaction' => $outgoing,
            'incoming_transaction' => $incoming,
        ], 'Transfer antar wallet berhasil diproses', [], 201);
    }
}

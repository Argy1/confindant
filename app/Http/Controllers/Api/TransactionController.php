<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use Illuminate\Http\Request;

class TransactionController extends Controller
{
    // GET: Tampilkan semua transaksi
    public function index()
    {
        // Ambil semua transaksi, urutkan dari yang terbaru
        $transactions = Transaction::orderBy('date', 'desc')->get();

        return response()->json([
            'success' => true,
            'message' => 'Daftar Transaksi Berhasil Diambil',
            'data'    => $transactions
        ], 200);
    }

    // POST: Simpan transaksi baru
    public function store(Request $request)
    {
        // 1. Validasi input
        $validatedData = $request->validate([
            'user_id' => 'required|string',
            'wallet_id' => 'required|string',
            'type' => 'required|in:income,expense',
            'total_amount' => 'required|numeric',
            'date' => 'required|date',
            'merchant_name' => 'nullable|string',
            'notes' => 'nullable|string',
            'is_verified' => 'boolean',
            'items' => 'nullable|array', // Validasi items sebagai array
        ]);

        // 2. Simpan ke MongoDB
        $transaction = Transaction::create($validatedData);

        // 3. Kembalikan response JSON
        return response()->json([
            'success' => true,
            'message' => 'Transaksi Berhasil Disimpan',
            'data'    => $transaction
        ], 201);
    }
}
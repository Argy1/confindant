<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Wallet;
use Illuminate\Http\Request;

class WalletController extends Controller
{
    // GET: Menampilkan daftar semua wallet
    public function index()
    {
        // Nantinya di sini bisa difilter berdasarkan user yang sedang login: 
        // Wallet::where('user_id', auth()->id())->get();
        $wallets = Wallet::all();

        return response()->json([
            'success' => true,
            'message' => 'Daftar Wallet Berhasil Diambil',
            'data'    => $wallets
        ], 200);
    }

    // POST: Membuat wallet baru
    public function store(Request $request)
    {
        // Validasi input
        $validatedData = $request->validate([
            'user_id'     => 'required|string', // Pastikan format id valid
            'wallet_name' => 'required|string|max:255',
            'balance'     => 'required|numeric',
        ]);

        // Simpan ke database
        $wallet = Wallet::create($validatedData);

        return response()->json([
            'success' => true,
            'message' => 'Wallet Berhasil Dibuat',
            'data'    => $wallet
        ], 201);
    }

    // GET: Menampilkan detail 1 wallet spesifik (Opsional tapi penting)
    public function show($id)
    {
        $wallet = Wallet::find($id);

        if (!$wallet) {
            return response()->json([
                'success' => false,
                'message' => 'Wallet tidak ditemukan'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data'    => $wallet
        ], 200);
    }
}
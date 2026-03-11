<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Budget;
use Illuminate\Http\Request;

class BudgetController extends Controller
{
    // GET: Menampilkan daftar budget
    public function index()
    {
        // Mengurutkan dari yang terbaru dibuat
        $budgets = Budget::orderBy('created_at', 'desc')->get();

        return response()->json([
            'success' => true,
            'message' => 'Daftar Budget Berhasil Diambil',
            'data'    => $budgets
        ], 200);
    }

    // POST: Membuat budget baru
    public function store(Request $request)
    {
        // Validasi input
        $validatedData = $request->validate([
            'user_id'      => 'required|string',
            'category'     => 'required|string|max:255',
            'limit_amount' => 'required|numeric',
            'period_month' => 'required|integer|min:1', // Pastikan bulan berupa angka bulat (contoh: 1, 3, 6)
        ]);

        // Simpan ke database
        $budget = Budget::create($validatedData);

        return response()->json([
            'success' => true,
            'message' => 'Budget Berhasil Dibuat',
            'data'    => $budget
        ], 201);
    }

    // GET: Menampilkan detail 1 budget
    public function show($id)
    {
        $budget = Budget::find($id);

        if (!$budget) {
            return response()->json([
                'success' => false,
                'message' => 'Budget tidak ditemukan'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data'    => $budget
        ], 200);
    }
}
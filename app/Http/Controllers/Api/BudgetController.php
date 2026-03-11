<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\Budget;
use Illuminate\Http\Request;

class BudgetController extends Controller
{
    use ApiResponse;

    public function index(Request $request)
    {
        $budgets = Budget::where('user_id', (string) $request->user()->_id)
            ->orderBy('created_at', 'desc')
            ->get();

        return $this->ok($budgets, 'Daftar budget berhasil diambil');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'category' => 'required|string|max:255',
            'limit_amount' => 'required|numeric|min:0',
            'period_month' => 'required|string|max:32',
            'alert_threshold' => 'nullable|numeric|min:1|max:100',
        ]);

        $budget = Budget::create([
            ...$validated,
            'alert_threshold' => $validated['alert_threshold'] ?? 80,
            'user_id' => (string) $request->user()->_id,
        ]);

        return $this->ok($budget, 'Budget berhasil dibuat', [], 201);
    }

    public function show(Request $request, string $id)
    {
        $budget = Budget::where('_id', $id)
            ->where('user_id', (string) $request->user()->_id)
            ->first();

        if (!$budget) {
            return $this->fail('Budget tidak ditemukan', [], 404);
        }

        return $this->ok($budget, 'Detail budget berhasil diambil');
    }

    public function update(Request $request, string $id)
    {
        $budget = Budget::where('_id', $id)
            ->where('user_id', (string) $request->user()->_id)
            ->first();

        if (!$budget) {
            return $this->fail('Budget tidak ditemukan', [], 404);
        }

        $validated = $request->validate([
            'category' => 'sometimes|required|string|max:255',
            'limit_amount' => 'sometimes|required|numeric|min:0',
            'period_month' => 'sometimes|required|string|max:32',
            'alert_threshold' => 'nullable|numeric|min:1|max:100',
        ]);

        $budget->update($validated);

        return $this->ok($budget->fresh(), 'Budget berhasil diperbarui');
    }

    public function destroy(Request $request, string $id)
    {
        $budget = Budget::where('_id', $id)
            ->where('user_id', (string) $request->user()->_id)
            ->first();

        if (!$budget) {
            return $this->fail('Budget tidak ditemukan', [], 404);
        }

        $budget->delete();

        return $this->ok(null, 'Budget berhasil dihapus');
    }
}

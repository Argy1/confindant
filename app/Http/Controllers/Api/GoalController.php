<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\Goal;
use Illuminate\Http\Request;

class GoalController extends Controller
{
    use ApiResponse;

    public function index(Request $request)
    {
        $goals = Goal::where('user_id', (string) $request->user()->_id)
            ->orderBy('created_at', 'desc')
            ->get();

        return $this->ok($goals, 'Daftar goals berhasil diambil');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'target_amount' => 'required|numeric|min:0',
            'target_date_label' => 'required|string|max:64',
            'linked_wallet' => 'required|string|max:255',
        ]);

        $goal = Goal::create([
            ...$validated,
            'user_id' => (string) $request->user()->_id,
            'current_amount' => 0,
            'contributions' => [],
        ]);

        return $this->ok($goal, 'Goal berhasil dibuat', [], 201);
    }

    public function update(Request $request, string $id)
    {
        $goal = Goal::where('_id', $id)
            ->where('user_id', (string) $request->user()->_id)
            ->first();

        if (!$goal) {
            return $this->fail('Goal tidak ditemukan', [], 404);
        }

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'target_amount' => 'sometimes|required|numeric|min:0',
            'target_date_label' => 'sometimes|required|string|max:64',
            'linked_wallet' => 'sometimes|required|string|max:255',
        ]);

        $goal->update($validated);

        return $this->ok($goal->fresh(), 'Goal berhasil diperbarui');
    }

    public function destroy(Request $request, string $id)
    {
        $goal = Goal::where('_id', $id)
            ->where('user_id', (string) $request->user()->_id)
            ->first();

        if (!$goal) {
            return $this->fail('Goal tidak ditemukan', [], 404);
        }

        $goal->delete();

        return $this->ok(null, 'Goal berhasil dihapus');
    }

    public function addContribution(Request $request, string $id)
    {
        $goal = Goal::where('_id', $id)
            ->where('user_id', (string) $request->user()->_id)
            ->first();

        if (!$goal) {
            return $this->fail('Goal tidak ditemukan', [], 404);
        }

        $validated = $request->validate([
            'amount' => 'required|numeric|min:1',
            'note' => 'nullable|string|max:255',
            'date_label' => 'nullable|string|max:64',
        ]);

        $contributions = is_array($goal->contributions) ? $goal->contributions : [];
        array_unshift($contributions, [
            'date_label' => $validated['date_label'] ?? now()->format('M d'),
            'amount' => (float) $validated['amount'],
            'note' => $validated['note'] ?? null,
        ]);

        $goal->update([
            'current_amount' => (float) $goal->current_amount + (float) $validated['amount'],
            'contributions' => $contributions,
        ]);

        return $this->ok($goal->fresh(), 'Kontribusi berhasil ditambahkan');
    }
}

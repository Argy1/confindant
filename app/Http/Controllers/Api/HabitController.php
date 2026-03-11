<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\Habit;
use Illuminate\Http\Request;

class HabitController extends Controller
{
    use ApiResponse;

    public function index(Request $request)
    {
        $habits = Habit::where('user_id', (string) $request->user()->_id)
            ->orderBy('created_at', 'desc')
            ->get();

        return $this->ok($habits, 'Daftar habit berhasil diambil');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'required|string|max:500',
            'target_count' => 'required|integer|min:1',
            'frequency' => 'required|in:daily,weekly',
            'active' => 'nullable|boolean',
        ]);

        $habit = Habit::create([
            ...$validated,
            'current_count' => 0,
            'active' => $validated['active'] ?? true,
            'user_id' => (string) $request->user()->_id,
        ]);

        return $this->ok($habit, 'Habit berhasil dibuat', [], 201);
    }

    public function increment(Request $request, string $id)
    {
        $habit = Habit::where('_id', $id)
            ->where('user_id', (string) $request->user()->_id)
            ->first();

        if (!$habit) {
            return $this->fail('Habit tidak ditemukan', [], 404);
        }

        $habit->update(['current_count' => ((int) $habit->current_count) + 1]);

        return $this->ok($habit->fresh(), 'Progress habit bertambah');
    }

    public function reset(Request $request, string $id)
    {
        $habit = Habit::where('_id', $id)
            ->where('user_id', (string) $request->user()->_id)
            ->first();

        if (!$habit) {
            return $this->fail('Habit tidak ditemukan', [], 404);
        }

        $habit->update(['current_count' => 0]);

        return $this->ok($habit->fresh(), 'Progress habit direset');
    }
}

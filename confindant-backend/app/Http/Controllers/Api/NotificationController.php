<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\UserNotification;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    use ApiResponse;

    public function index(Request $request)
    {
        $perPage = max(1, min((int) $request->query('per_page', 20), 100));
        $page = max(1, (int) $request->query('page', 1));

        $query = UserNotification::where('user_id', (string) $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->orderBy('id', 'desc');

        $total = $query->count();
        $notifications = $query
            ->skip(($page - 1) * $perPage)
            ->take($perPage)
            ->get();

        return $this->ok($notifications, 'Notifikasi berhasil diambil', [
            'page' => $page,
            'per_page' => $perPage,
            'total' => $total,
            'has_more' => ($page * $perPage) < $total,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'subtitle' => 'required|string|max:500',
            'time_label' => 'nullable|string|max:64',
            'read' => 'nullable|boolean',
        ]);

        $notification = UserNotification::create([
            ...$validated,
            'time_label' => $validated['time_label'] ?? 'just now',
            'read' => $validated['read'] ?? false,
            'user_id' => (string) $request->user()->id,
        ]);

        return $this->ok($notification, 'Notifikasi berhasil dibuat', [], 201);
    }

    public function markRead(Request $request, string $id)
    {
        $notification = UserNotification::where('id', $id)
            ->where('user_id', (string) $request->user()->id)
            ->first();

        if (!$notification) {
            return $this->fail('Notifikasi tidak ditemukan', [], 404);
        }

        $notification->update(['read' => true]);

        return $this->ok($notification->fresh(), 'Notifikasi ditandai sudah dibaca');
    }
}

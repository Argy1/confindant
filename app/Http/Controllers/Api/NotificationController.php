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
        $notifications = UserNotification::where('user_id', (string) $request->user()->_id)
            ->orderBy('created_at', 'desc')
            ->get();

        return $this->ok($notifications, 'Notifikasi berhasil diambil');
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
            'user_id' => (string) $request->user()->_id,
        ]);

        return $this->ok($notification, 'Notifikasi berhasil dibuat', [], 201);
    }

    public function markRead(Request $request, string $id)
    {
        $notification = UserNotification::where('_id', $id)
            ->where('user_id', (string) $request->user()->_id)
            ->first();

        if (!$notification) {
            return $this->fail('Notifikasi tidak ditemukan', [], 404);
        }

        $notification->update(['read' => true]);

        return $this->ok($notification->fresh(), 'Notifikasi ditandai sudah dibaca');
    }
}

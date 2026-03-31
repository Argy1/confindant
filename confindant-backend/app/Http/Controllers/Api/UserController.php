<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\Goal;
use App\Models\Habit;
use App\Models\ProfileSetting;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class UserController extends Controller
{
    use ApiResponse;

    public function register(Request $request)
    {
        $incomingName = trim((string) ($request->input('username') ?? $request->input('name') ?? ''));
        $request->merge(['username' => $incomingName]);

        $validated = $request->validate([
            'username' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users,email',
            'password' => 'required|string|min:6',
        ]);

        $user = User::create([
            'username' => $validated['username'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
        ]);

        $userId = (string) $user->_id;

        if (!ProfileSetting::where('user_id', $userId)->exists()) {
            ProfileSetting::create([
                'user_id' => $userId,
                'full_name' => $user->username,
                'username' => $user->username,
                'email' => $user->email,
                'phone' => '',
                'currency' => 'IDR (Rp)',
                'avatar_path' => 'assets/avatars/profile_kennedy.jpg',
                'notification_settings' => [
                    'push_enabled' => true,
                    'email_enabled' => true,
                    'transaction_alerts' => true,
                    'budget_alerts' => true,
                    'weekly_report' => false,
                ],
                'faq_items' => [
                    [
                        'question' => 'Bagaimana cara menambahkan transaksi?',
                        'answer' => 'Buka halaman Home lalu gunakan Quick Action Add Expense/Add Income atau Scan.',
                        'expanded' => false,
                    ],
                ],
                'about_info' => [
                    'app_name' => 'Confindant',
                    'version' => '1.0.0',
                    'build' => '100',
                    'description' => 'Confindant membantu kamu melacak pemasukan, pengeluaran, dan budget harian.',
                ],
            ]);
        }

        if (!Goal::where('user_id', $userId)->where('name', 'Emergency Fund')->exists()) {
            Goal::create([
                'user_id' => $userId,
                'name' => 'Emergency Fund',
                'target_amount' => 10000000,
                'current_amount' => 0,
                'target_date_label' => 'Dec 2026',
                'linked_wallet' => 'Main Wallet',
                'contributions' => [],
            ]);
        }

        if (!Habit::where('user_id', $userId)->where('title', 'Daily Expense Log')->exists()) {
            Habit::create([
                'user_id' => $userId,
                'title' => 'Daily Expense Log',
                'description' => 'Log all expenses every day.',
                'target_count' => 7,
                'current_count' => 0,
                'frequency' => 'weekly',
                'active' => true,
            ]);
        }

        $plainTextToken = $user->createToken('auth_token')->plainTextToken;
        $token = str_contains($plainTextToken, '|')
            ? explode('|', $plainTextToken, 2)[1]
            : $plainTextToken;

        return $this->ok([
            'user' => $user,
            'access_token' => $token,
            'token_type' => 'Bearer',
        ], 'Register berhasil', [], 201);
    }

    public function login(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|string|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', $validated['email'])->first();

        if (!$user || !Hash::check($validated['password'], $user->password)) {
            return $this->fail('Email atau password salah', [], 401);
        }

        $plainTextToken = $user->createToken('auth_token')->plainTextToken;
        $token = str_contains($plainTextToken, '|')
            ? explode('|', $plainTextToken, 2)[1]
            : $plainTextToken;

        return $this->ok([
            'user' => $user,
            'access_token' => $token,
            'token_type' => 'Bearer',
        ], 'Login berhasil');
    }

    public function me(Request $request)
    {
        return $this->ok($request->user(), 'User aktif berhasil diambil');
    }

    public function logout(Request $request)
    {
        $request->user()?->currentAccessToken()?->delete();
        return $this->ok(null, 'Logout berhasil');
    }

    public function index(Request $request)
    {
        return $this->ok([$request->user()], 'Daftar user berhasil diambil');
    }
}

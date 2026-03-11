<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\ProfileSetting;
use App\Models\UserNotification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ProfileController extends Controller
{
    use ApiResponse;

    public function show(Request $request)
    {
        $profile = $this->resolveProfile($request);

        return $this->ok([
            'profile' => $profile,
            'notifications' => UserNotification::where('user_id', (string) $request->user()->_id)
                ->orderBy('created_at', 'desc')
                ->limit(10)
                ->get(),
        ], 'Profile berhasil diambil');
    }

    public function update(Request $request)
    {
        $profile = $this->resolveProfile($request);

        $validated = $request->validate([
            'full_name' => 'sometimes|required|string|max:255',
            'username' => 'sometimes|required|string|max:255',
            'email' => 'sometimes|required|string|email|max:255',
            'phone' => 'nullable|string|max:50',
            'currency' => 'nullable|string|max:64',
            'avatar_path' => 'nullable|string|max:2048',
        ]);

        $profile->update($validated);

        return $this->ok($profile->fresh(), 'Profile berhasil diperbarui');
    }

    public function updateAvatar(Request $request)
    {
        $profile = $this->resolveProfile($request);

        $validated = $request->validate([
            'avatar' => 'required|image|max:5120',
        ]);

        $avatar = $validated['avatar'];
        $storedPath = $avatar->store('avatars', 'public');

        // Optional: remove old uploaded avatar to avoid orphan files.
        $oldPath = (string) ($profile->avatar_path ?? '');
        if (str_contains($oldPath, '/storage/avatars/')) {
            $relativeOld = ltrim(parse_url($oldPath, PHP_URL_PATH) ?? '', '/');
            if (str_starts_with($relativeOld, 'storage/')) {
                $relativeOld = substr($relativeOld, strlen('storage/'));
            }
            if ($relativeOld !== '') {
                Storage::disk('public')->delete($relativeOld);
            }
        }

        $avatarUrl = rtrim($request->getSchemeAndHttpHost(), '/') . '/storage/' . $storedPath;
        $profile->update(['avatar_path' => $avatarUrl]);

        return $this->ok($profile->fresh(), 'Foto profil berhasil diperbarui');
    }

    public function updateNotificationSettings(Request $request)
    {
        $profile = $this->resolveProfile($request);

        $validated = $request->validate([
            'push_enabled' => 'required|boolean',
            'email_enabled' => 'required|boolean',
            'transaction_alerts' => 'required|boolean',
            'budget_alerts' => 'required|boolean',
            'weekly_report' => 'required|boolean',
        ]);

        $profile->update(['notification_settings' => $validated]);

        return $this->ok($profile->fresh(), 'Pengaturan notifikasi diperbarui');
    }

    private function resolveProfile(Request $request): ProfileSetting
    {
        return ProfileSetting::firstOrCreate(
            ['user_id' => (string) $request->user()->_id],
            [
                'full_name' => $request->user()->username,
                'username' => $request->user()->username,
                'email' => $request->user()->email,
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
                    [
                        'question' => 'Bagaimana cara set budget kategori?',
                        'answer' => 'Masuk ke Wallet, pilih Manage Category Limits, lalu atur nominal limit.',
                        'expanded' => false,
                    ],
                ],
                'about_info' => [
                    'app_name' => 'Confindant',
                    'version' => '1.0.0',
                    'build' => '100',
                    'description' => 'Confindant membantu kamu melacak pemasukan, pengeluaran, dan budget harian dengan tampilan yang bersih.',
                ],
            ]
        );
    }
}

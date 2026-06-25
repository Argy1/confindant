<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Api\Concerns\ResolvesOrganization;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class OrganizationMemberController extends Controller
{
    use ApiResponse;
    use ResolvesOrganization;

    public function index(Request $request)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }

        $members = $org->users()
            ->select('users.id', 'users.username', 'users.email', 'users.profile_picture')
            ->orderByRaw("CASE organization_user.role WHEN 'admin' THEN 0 WHEN 'bendahara' THEN 1 WHEN 'auditor' THEN 2 ELSE 3 END")
            ->orderBy('users.username')
            ->get()
            ->map(fn ($user) => [
                'id'        => $user->id,
                'name'      => $user->username,
                'email'     => $user->email,
                'avatar'    => $user->profile_picture,
                'role'      => $user->pivot->role,
                'joined_at' => $user->pivot->created_at,
            ]);

        return $this->ok($members, 'Daftar anggota berhasil diambil');
    }

    public function update(Request $request, int $userId)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }
        if ($this->organizationRole($request, $org) !== 'admin') {
            return $this->fail('Hanya admin yang dapat mengubah role anggota', [], 403);
        }

        $validated = $request->validate([
            'role' => 'required|in:admin,bendahara,auditor,viewer',
        ]);

        $member = $org->users()->where('users.id', $userId)->first();
        if (!$member) {
            return $this->fail('Anggota tidak ditemukan', [], 404);
        }

        // Guard: prevent sole admin from demoting themselves
        if ($userId === $request->user()->id && $validated['role'] !== 'admin') {
            $adminCount = $org->users()->wherePivot('role', 'admin')->count();
            if ($adminCount <= 1) {
                return $this->fail('Tidak bisa mengubah role: Anda satu-satunya admin', [], 422);
            }
        }

        $org->users()->updateExistingPivot($userId, ['role' => $validated['role']]);

        return $this->ok([
            'id'    => $member->id,
            'name'  => $member->username,
            'email' => $member->email,
            'role'  => $validated['role'],
        ], 'Role anggota diperbarui');
    }

    public function destroy(Request $request, int $userId)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }
        if ($this->organizationRole($request, $org) !== 'admin') {
            return $this->fail('Hanya admin yang dapat menghapus anggota', [], 403);
        }

        if ($userId === $request->user()->id) {
            return $this->fail('Tidak bisa menghapus diri sendiri dari organisasi', [], 422);
        }

        $member = $org->users()->where('users.id', $userId)->first();
        if (!$member) {
            return $this->fail('Anggota tidak ditemukan', [], 404);
        }

        $org->users()->detach($userId);

        return $this->ok(null, 'Anggota berhasil dihapus dari organisasi');
    }
}

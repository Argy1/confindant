<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Api\Concerns\ResolvesOrganization;
use App\Http\Controllers\Controller;
use App\Models\OrganizationInvitation;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;

class OrganizationInvitationController extends Controller
{
    use ApiResponse;
    use ResolvesOrganization;

    public function index(Request $request)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }
        if (!$this->canWriteAccounting($this->organizationRole($request, $org))) {
            return $this->fail('Tidak memiliki akses', [], 403);
        }

        $invitations = OrganizationInvitation::where('organization_id', $org->id)
            ->whereNull('accepted_at')
            ->where('expires_at', '>', now())
            ->with('inviter:id,username')
            ->orderByDesc('created_at')
            ->get()
            ->map(fn ($inv) => [
                'token'      => $inv->token,
                'email'      => $inv->email,
                'role'       => $inv->role,
                'invited_by' => ['id' => $inv->inviter->id, 'name' => $inv->inviter->username],
                'expires_at' => $inv->expires_at,
                'created_at' => $inv->created_at,
            ]);

        return $this->ok($invitations, 'Daftar undangan berhasil diambil');
    }

    public function invite(Request $request)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }
        if ($this->organizationRole($request, $org) !== 'admin') {
            return $this->fail('Hanya admin yang dapat mengundang anggota', [], 403);
        }

        $validated = $request->validate([
            'email' => 'required|email',
            'role'  => 'required|in:admin,bendahara,auditor,viewer',
        ]);

        $existingMember = $org->users()->where('users.email', $validated['email'])->first();
        if ($existingMember) {
            return $this->fail('Email ini sudah menjadi anggota organisasi', [], 422);
        }

        // Revoke any existing pending invite for this email
        OrganizationInvitation::where('organization_id', $org->id)
            ->where('email', $validated['email'])
            ->whereNull('accepted_at')
            ->delete();

        $token      = Str::uuid()->toString();
        $expiresAt  = now()->addHours(48);
        $inviteUrl  = rtrim(config('app.frontend_url', config('app.url')), '/') . '/invite/' . $token;

        $invitation = OrganizationInvitation::create([
            'organization_id' => $org->id,
            'email'           => $validated['email'],
            'role'            => $validated['role'],
            'token'           => $token,
            'invited_by'      => $request->user()->id,
            'expires_at'      => $expiresAt,
        ]);

        // Send email if mail is configured — silently skip if not
        try {
            Mail::raw(
                "Anda diundang bergabung ke {$org->name} sebagai {$validated['role']}.\n\n" .
                "Klik link berikut untuk menerima undangan:\n{$inviteUrl}\n\n" .
                "Link berlaku hingga {$expiresAt->toDateTimeString()}.",
                fn ($msg) => $msg->to($validated['email'])
                    ->subject("Undangan bergabung ke {$org->name} — Confindant")
            );
        } catch (\Throwable) {
            // Email not configured
        }

        return $this->ok([
            'token'      => $invitation->token,
            'email'      => $invitation->email,
            'role'       => $invitation->role,
            'expires_at' => $invitation->expires_at,
            'invite_url' => $inviteUrl,
        ], 'Undangan berhasil dibuat', [], 201);
    }

    public function cancel(Request $request, string $token)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }
        if ($this->organizationRole($request, $org) !== 'admin') {
            return $this->fail('Hanya admin yang dapat membatalkan undangan', [], 403);
        }

        $invitation = OrganizationInvitation::where('token', $token)
            ->where('organization_id', $org->id)
            ->first();

        if (!$invitation) {
            return $this->fail('Undangan tidak ditemukan', [], 404);
        }

        $invitation->delete();

        return $this->ok(null, 'Undangan dibatalkan');
    }

    /** Public endpoint — no auth required */
    public function info(string $token)
    {
        $invitation = OrganizationInvitation::where('token', $token)
            ->whereNull('accepted_at')
            ->where('expires_at', '>', now())
            ->with([
                'organization:id,name,slug',
                'inviter:id,username',
            ])
            ->first();

        if (!$invitation) {
            return response()->json([
                'success' => false,
                'message' => 'Undangan tidak valid atau sudah kadaluarsa',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data'    => [
                'organization' => [
                    'id'   => $invitation->organization->id,
                    'name' => $invitation->organization->name,
                    'slug' => $invitation->organization->slug,
                ],
                'role'       => $invitation->role,
                'invited_by' => ['name' => $invitation->inviter->username],
                'expires_at' => $invitation->expires_at,
            ],
        ]);
    }

    public function accept(Request $request, string $token)
    {
        $invitation = OrganizationInvitation::where('token', $token)
            ->whereNull('accepted_at')
            ->where('expires_at', '>', now())
            ->with('organization')
            ->first();

        if (!$invitation) {
            return $this->fail('Undangan tidak valid atau sudah kadaluarsa', [], 404);
        }

        $user          = $request->user();
        $alreadyMember = $invitation->organization->users()
            ->where('users.id', $user->id)
            ->exists();

        if ($alreadyMember) {
            return $this->fail('Anda sudah menjadi anggota organisasi ini', [], 422);
        }

        $invitation->organization->users()->attach($user->id, ['role' => $invitation->role]);

        $invitation->update([
            'accepted_at' => now(),
            'accepted_by' => $user->id,
        ]);

        return $this->ok([
            'organization' => [
                'id'   => (string) $invitation->organization->id,
                'name' => $invitation->organization->name,
                'slug' => $invitation->organization->slug,
            ],
            'role' => $invitation->role,
        ], "Selamat datang di {$invitation->organization->name}!");
    }
}

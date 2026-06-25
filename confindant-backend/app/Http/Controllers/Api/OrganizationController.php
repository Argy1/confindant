<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class OrganizationController extends Controller
{
    use ApiResponse;

    /**
     * List organizations the current user belongs to, with their role.
     */
    public function index(Request $request)
    {
        $orgs = $request->user()
            ->organizations()
            ->orderBy('organizations.name')
            ->get()
            ->map(fn ($org) => [
                'id' => (string) $org->id,
                'name' => $org->name,
                'slug' => $org->slug,
                'legal_name' => $org->legal_name,
                'currency' => $org->currency,
                'role' => $org->pivot->role,
            ]);

        return $this->ok($orgs, 'Daftar organisasi berhasil diambil');
    }
}

<?php

namespace App\Http\Controllers\Api\Concerns;

use App\Models\Organization;
use Illuminate\Http\Request;

trait ResolvesOrganization
{
    /**
     * Resolve the organization for the current request.
     *
     * Single-org mode (PDPI): if the user belongs to exactly one org, use it.
     * Otherwise honor an explicit organization_id and verify membership.
     */
    protected function resolveOrganization(Request $request): ?Organization
    {
        $user = $request->user();
        if (!$user) {
            return null;
        }

        $explicitId = $request->input('organization_id') ?? $request->query('organization_id');

        $query = $user->organizations();
        if ($explicitId) {
            return $query->where('organizations.id', (int) $explicitId)->first();
        }

        return $query->orderBy('organizations.id')->first();
    }

    /**
     * The current user's role within the given organization.
     */
    protected function organizationRole(Request $request, Organization $organization): ?string
    {
        $pivot = $request->user()
            ?->organizations()
            ->where('organizations.id', $organization->id)
            ->first()?->pivot;

        return $pivot?->role;
    }

    /**
     * Roles allowed to create/post financial entries.
     */
    protected function canWriteAccounting(?string $role): bool
    {
        return in_array($role, ['admin', 'bendahara'], true);
    }
}

<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Api\Concerns\ResolvesOrganization;
use App\Http\Controllers\Controller;
use App\Models\Account;
use Illuminate\Http\Request;

class AccountController extends Controller
{
    use ApiResponse;
    use ResolvesOrganization;

    public function index(Request $request)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }

        $accounts = Account::where('organization_id', $org->id)
            ->orderBy('sort_order')
            ->orderBy('code')
            ->get();

        return $this->ok($accounts, 'Daftar akun berhasil diambil', [
            'organization' => ['id' => $org->id, 'name' => $org->name],
        ]);
    }

    public function store(Request $request)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }
        if (!$this->canWriteAccounting($this->organizationRole($request, $org))) {
            return $this->fail('Anda tidak memiliki akses untuk membuat akun', [], 403);
        }

        $validated = $request->validate([
            'code' => 'required|string|max:32',
            'name' => 'required|string|max:255',
            'type' => 'required|in:asset,liability,net_asset,revenue,expense',
            'subtype' => 'nullable|string|max:64',
            'parent_id' => 'nullable|integer',
            'is_contra' => 'nullable|boolean',
            'opening_balance' => 'nullable|numeric',
            'description' => 'nullable|string',
        ]);

        $exists = Account::where('organization_id', $org->id)
            ->where('code', $validated['code'])
            ->exists();
        if ($exists) {
            return $this->fail('Kode akun sudah dipakai', [], 422);
        }

        $account = Account::create([
            ...$validated,
            'organization_id' => $org->id,
            'normal_balance' => Account::normalBalanceForType($validated['type']),
            'is_contra' => $validated['is_contra'] ?? false,
            'opening_balance' => $validated['opening_balance'] ?? 0,
            'is_active' => true,
        ]);

        return $this->ok($account, 'Akun berhasil dibuat', [], 201);
    }

    public function update(Request $request, int $id)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }
        if (!$this->canWriteAccounting($this->organizationRole($request, $org))) {
            return $this->fail('Anda tidak memiliki akses untuk mengubah akun', [], 403);
        }

        $account = Account::where('organization_id', $org->id)->where('id', $id)->first();
        if (!$account) {
            return $this->fail('Akun tidak ditemukan', [], 404);
        }

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'subtype' => 'nullable|string|max:64',
            'is_active' => 'sometimes|boolean',
            'opening_balance' => 'sometimes|numeric',
            'description' => 'nullable|string',
        ]);

        $account->update($validated);

        return $this->ok($account->fresh(), 'Akun berhasil diperbarui');
    }
}

<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Api\Concerns\ResolvesOrganization;
use App\Http\Controllers\Controller;
use App\Models\Account;
use App\Models\RestrictedFund;
use App\Services\Accounting\RestrictedFundService;
use Illuminate\Http\Request;
use InvalidArgumentException;

class RestrictedFundController extends Controller
{
    use ApiResponse;
    use ResolvesOrganization;

    public function __construct(private readonly RestrictedFundService $service)
    {
    }

    public function index(Request $request)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }

        $funds = RestrictedFund::where('organization_id', $org->id)
            ->orderBy('name')
            ->get();

        return $this->ok($funds, 'Daftar dana titipan berhasil diambil', [
            'total_balance' => round((float) $funds->sum('balance'), 2),
        ]);
    }

    public function show(Request $request, int $id)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }

        $fund = RestrictedFund::with(['movements' => fn ($q) => $q->orderBy('date', 'desc')])
            ->where('organization_id', $org->id)
            ->where('id', $id)
            ->first();
        if (!$fund) {
            return $this->fail('Dana titipan tidak ditemukan', [], 404);
        }

        return $this->ok($fund, 'Detail dana titipan berhasil diambil');
    }

    public function store(Request $request)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }
        if (!$this->canWriteAccounting($this->organizationRole($request, $org))) {
            return $this->fail('Anda tidak memiliki akses', [], 403);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'fund_type' => 'nullable|string|in:titipan_cabang,titipan_kegiatan,shu',
            'account_id' => 'required|integer',
            'notes' => 'nullable|string|max:500',
        ]);

        if (!Account::where('organization_id', $org->id)->where('id', $validated['account_id'])->exists()) {
            return $this->fail('Akun tidak valid', [], 422);
        }

        $fund = RestrictedFund::create([
            ...$validated,
            'organization_id' => $org->id,
            'balance' => 0,
            'status' => 'active',
        ]);

        return $this->ok($fund, 'Dana titipan berhasil dibuat', [], 201);
    }

    public function move(Request $request, int $id)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }
        if (!$this->canWriteAccounting($this->organizationRole($request, $org))) {
            return $this->fail('Anda tidak memiliki akses', [], 403);
        }

        $fund = RestrictedFund::where('organization_id', $org->id)->where('id', $id)->first();
        if (!$fund) {
            return $this->fail('Dana titipan tidak ditemukan', [], 404);
        }

        $validated = $request->validate([
            'direction' => 'required|in:in,out',
            'amount' => 'required|numeric|min:0.01',
            'cash_account_id' => 'required|integer',
            'date' => 'required|date',
            'description' => 'nullable|string|max:255',
        ]);

        if (!Account::where('organization_id', $org->id)->where('id', $validated['cash_account_id'])->exists()) {
            return $this->fail('Akun kas tidak valid', [], 422);
        }

        try {
            $movement = $this->service->recordMovement(
                $fund,
                $validated['direction'],
                (float) $validated['amount'],
                (int) $validated['cash_account_id'],
                $validated['date'],
                $validated['description'] ?? null,
                $request->user()->id
            );
        } catch (InvalidArgumentException $e) {
            return $this->fail($e->getMessage(), [], 422);
        }

        return $this->ok([
            'movement' => $movement,
            'fund' => $fund->fresh(),
        ], 'Pergerakan dana titipan berhasil dicatat', [], 201);
    }
}

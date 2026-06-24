<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Api\Concerns\ResolvesOrganization;
use App\Http\Controllers\Controller;
use App\Models\Account;
use App\Models\ReceivablePayable;
use App\Services\Accounting\ReceivablePayableService;
use Illuminate\Http\Request;
use InvalidArgumentException;

class ReceivablePayableController extends Controller
{
    use ApiResponse;
    use ResolvesOrganization;

    public function __construct(private readonly ReceivablePayableService $service)
    {
    }

    public function index(Request $request)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }

        $validated = $request->validate([
            'type' => 'nullable|in:receivable,payable',
            'status' => 'nullable|in:open,partial,settled,written_off',
        ]);

        $query = ReceivablePayable::where('organization_id', $org->id)
            ->orderBy('issued_date', 'desc');
        if (!empty($validated['type'])) {
            $query->where('type', $validated['type']);
        }
        if (!empty($validated['status'])) {
            $query->where('status', $validated['status']);
        }

        $items = $query->get();

        return $this->ok($items, 'Daftar piutang/hutang berhasil diambil', [
            'total_outstanding' => round((float) $items->sum('outstanding_amount'), 2),
        ]);
    }

    public function show(Request $request, int $id)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }

        $item = ReceivablePayable::with('settlements')
            ->where('organization_id', $org->id)
            ->where('id', $id)
            ->first();
        if (!$item) {
            return $this->fail('Data tidak ditemukan', [], 404);
        }

        return $this->ok($item, 'Detail piutang/hutang berhasil diambil');
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
            'type' => 'required|in:receivable,payable',
            'party_name' => 'required|string|max:255',
            'category' => 'nullable|string|max:128',
            'account_id' => 'required|integer',
            'counter_account_id' => 'nullable|integer',
            'description' => 'nullable|string|max:500',
            'original_amount' => 'required|numeric|min:0.01',
            'issued_date' => 'required|date',
            'due_date' => 'nullable|date',
            'period_label' => 'nullable|string|max:64',
        ]);

        if (!$this->accountBelongs($org->id, $validated['account_id'])) {
            return $this->fail('Akun kontrol tidak valid', [], 422);
        }
        if (!empty($validated['counter_account_id']) && !$this->accountBelongs($org->id, $validated['counter_account_id'])) {
            return $this->fail('Akun lawan tidak valid', [], 422);
        }

        try {
            $item = $this->service->create([
                ...$validated,
                'organization_id' => $org->id,
                'created_by' => $request->user()->id,
            ]);
        } catch (InvalidArgumentException $e) {
            return $this->fail($e->getMessage(), [], 422);
        }

        return $this->ok($item, 'Piutang/Hutang berhasil dibuat', [], 201);
    }

    public function settle(Request $request, int $id)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }
        if (!$this->canWriteAccounting($this->organizationRole($request, $org))) {
            return $this->fail('Anda tidak memiliki akses', [], 403);
        }

        $item = ReceivablePayable::where('organization_id', $org->id)->where('id', $id)->first();
        if (!$item) {
            return $this->fail('Data tidak ditemukan', [], 404);
        }

        $validated = $request->validate([
            'amount' => 'required|numeric|min:0.01',
            'cash_account_id' => 'required|integer',
            'date' => 'required|date',
            'notes' => 'nullable|string|max:255',
        ]);

        if (!$this->accountBelongs($org->id, $validated['cash_account_id'])) {
            return $this->fail('Akun kas tidak valid', [], 422);
        }

        try {
            $settlement = $this->service->settle(
                $item,
                (float) $validated['amount'],
                (int) $validated['cash_account_id'],
                $validated['date'],
                $validated['notes'] ?? null,
                $request->user()->id
            );
        } catch (InvalidArgumentException $e) {
            return $this->fail($e->getMessage(), [], 422);
        }

        return $this->ok([
            'settlement' => $settlement,
            'item' => $item->fresh(),
        ], 'Pelunasan berhasil dicatat', [], 201);
    }

    private function accountBelongs(int $organizationId, int $accountId): bool
    {
        return Account::where('organization_id', $organizationId)->where('id', $accountId)->exists();
    }
}

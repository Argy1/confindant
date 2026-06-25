<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Api\Concerns\ResolvesOrganization;
use App\Http\Controllers\Controller;
use App\Models\OrgBudget;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OrgBudgetController extends Controller
{
    use ApiResponse;
    use ResolvesOrganization;

    public function index(Request $request)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }

        $year = (int) $request->query('fiscal_year', (int) date('Y'));

        $items = OrgBudget::with(['account'])
            ->where('organization_id', $org->id)
            ->where('fiscal_year', $year)
            ->orderBy('category')
            ->orderBy('name')
            ->get();

        return $this->ok($items, 'Daftar anggaran berhasil diambil');
    }

    public function store(Request $request)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }
        if (!$this->canWriteAccounting($this->organizationRole($request, $org))) {
            return $this->fail('Tidak memiliki akses', [], 403);
        }

        $validated = $request->validate([
            'name'           => 'required|string|max:255',
            'fiscal_year'    => 'required|integer|min:2000|max:2100',
            'category'       => 'nullable|string|max:50',
            'account_id'     => 'nullable|integer|exists:accounts,id',
            'amount_planned' => 'required|numeric|min:0',
            'notes'          => 'nullable|string',
        ]);

        $budget = OrgBudget::create([
            ...$validated,
            'organization_id' => $org->id,
            'created_by'      => $request->user()->id,
        ]);

        return $this->ok($budget->load('account'), 'Anggaran dibuat', [], 201);
    }

    public function update(Request $request, int $id)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }
        if (!$this->canWriteAccounting($this->organizationRole($request, $org))) {
            return $this->fail('Tidak memiliki akses', [], 403);
        }

        $budget = OrgBudget::where('id', $id)->where('organization_id', $org->id)->first();
        if (!$budget) {
            return $this->fail('Anggaran tidak ditemukan', [], 404);
        }

        $validated = $request->validate([
            'name'           => 'sometimes|string|max:255',
            'category'       => 'sometimes|nullable|string|max:50',
            'account_id'     => 'sometimes|nullable|integer|exists:accounts,id',
            'amount_planned' => 'sometimes|numeric|min:0',
            'notes'          => 'sometimes|nullable|string',
        ]);

        $budget->update($validated);

        return $this->ok($budget->fresh('account'), 'Anggaran diperbarui');
    }

    public function destroy(Request $request, int $id)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }
        if (!$this->canWriteAccounting($this->organizationRole($request, $org))) {
            return $this->fail('Tidak memiliki akses', [], 403);
        }

        $budget = OrgBudget::where('id', $id)->where('organization_id', $org->id)->first();
        if (!$budget) {
            return $this->fail('Anggaran tidak ditemukan', [], 404);
        }

        $budget->delete();

        return $this->ok(null, 'Anggaran dihapus');
    }

    public function compare(Request $request)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }

        $year = (int) $request->query('fiscal_year', (int) date('Y'));

        $budgets = OrgBudget::with(['account'])
            ->where('organization_id', $org->id)
            ->where('fiscal_year', $year)
            ->orderBy('category')
            ->orderBy('name')
            ->get();

        $accountIds = $budgets->pluck('account_id')->filter()->unique()->values();

        $actuals = collect();
        if ($accountIds->isNotEmpty()) {
            $actuals = DB::table('journal_lines')
                ->join('journal_entries', 'journal_lines.journal_entry_id', '=', 'journal_entries.id')
                ->where('journal_entries.organization_id', $org->id)
                ->where('journal_entries.status', 'posted')
                ->whereBetween('journal_entries.date', [
                    Carbon::create($year, 1, 1)->startOfDay(),
                    Carbon::create($year, 12, 31)->endOfDay(),
                ])
                ->whereIn('journal_lines.account_id', $accountIds)
                ->groupBy('journal_lines.account_id')
                ->select(
                    'journal_lines.account_id',
                    DB::raw('SUM(journal_lines.debit) as total_debit'),
                    DB::raw('SUM(journal_lines.credit) as total_credit'),
                )
                ->get()
                ->keyBy('account_id');
        }

        $normalDebitTypes = ['asset', 'expense'];

        $items = $budgets->map(function (OrgBudget $budget) use ($actuals, $normalDebitTypes) {
            $actual = 0.0;

            if ($budget->account_id && $actuals->has($budget->account_id)) {
                $row  = $actuals->get($budget->account_id);
                $type = $budget->account?->type ?? 'expense';

                $actual = in_array($type, $normalDebitTypes)
                    ? ((float) $row->total_debit - (float) $row->total_credit)
                    : ((float) $row->total_credit - (float) $row->total_debit);

                $actual = max(0.0, $actual);
            }

            $planned    = (float) $budget->amount_planned;
            $percentage = $planned > 0 ? round(($actual / $planned) * 100, 1) : 0.0;
            $variance   = $planned - $actual;

            return [
                'id'             => $budget->id,
                'name'           => $budget->name,
                'category'       => $budget->category,
                'account'        => $budget->account ? [
                    'id'   => $budget->account->id,
                    'code' => $budget->account->code,
                    'name' => $budget->account->name,
                    'type' => $budget->account->type,
                ] : null,
                'amount_planned' => $planned,
                'amount_actual'  => $actual,
                'percentage'     => $percentage,
                'variance'       => $variance,
                'notes'          => $budget->notes,
            ];
        });

        $totalPlanned = $items->sum('amount_planned');
        $totalActual  = $items->sum('amount_actual');

        return $this->ok([
            'fiscal_year' => $year,
            'items'       => $items->values(),
            'totals'      => [
                'total_planned'      => $totalPlanned,
                'total_actual'       => $totalActual,
                'total_variance'     => $totalPlanned - $totalActual,
                'overall_percentage' => $totalPlanned > 0
                    ? round(($totalActual / $totalPlanned) * 100, 1)
                    : 0.0,
            ],
        ], 'Perbandingan anggaran berhasil diambil');
    }
}

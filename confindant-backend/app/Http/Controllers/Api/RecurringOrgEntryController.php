<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Api\Concerns\ResolvesOrganization;
use App\Http\Controllers\Controller;
use App\Models\RecurringOrgEntry;
use App\Services\Accounting\AccountingService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use InvalidArgumentException;

class RecurringOrgEntryController extends Controller
{
    use ApiResponse;
    use ResolvesOrganization;

    public function __construct(private readonly AccountingService $accounting)
    {
    }

    public function index(Request $request)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }

        $items = RecurringOrgEntry::with(['debitAccount', 'creditAccount'])
            ->where('organization_id', $org->id)
            ->orderBy('next_run_at')
            ->get();

        return $this->ok($items, 'Daftar recurring berhasil diambil');
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

        $validated = $this->validatePayload($request);

        $startDate = Carbon::parse($validated['start_date'])->startOfDay();
        $nextRun   = $startDate->copy();

        $item = RecurringOrgEntry::create([
            'organization_id'   => $org->id,
            'debit_account_id'  => (int) $validated['debit_account_id'],
            'credit_account_id' => (int) $validated['credit_account_id'],
            'description'       => (string) $validated['description'],
            'category'          => $validated['category'] ?? null,
            'amount'            => (float) $validated['amount'],
            'frequency'         => (string) $validated['frequency'],
            'interval'          => (int) ($validated['interval'] ?? 1),
            'start_date'        => $startDate,
            'next_run_at'       => $nextRun,
            'end_date'          => isset($validated['end_date']) ? Carbon::parse($validated['end_date'])->endOfDay() : null,
            'active'            => (bool) ($validated['active'] ?? true),
            'total_runs'        => 0,
            'created_by'        => $request->user()->id,
        ]);

        return $this->ok($item->load(['debitAccount', 'creditAccount']), 'Recurring dibuat', [], 201);
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

        $item = RecurringOrgEntry::where('id', $id)->where('organization_id', $org->id)->first();
        if (!$item) {
            return $this->fail('Recurring tidak ditemukan', [], 404);
        }

        $validated = $this->validatePayload($request, true);

        if (isset($validated['start_date'])) {
            $validated['start_date'] = Carbon::parse($validated['start_date'])->startOfDay();
        }
        if (array_key_exists('end_date', $validated)) {
            $validated['end_date'] = $validated['end_date']
                ? Carbon::parse((string) $validated['end_date'])->endOfDay()
                : null;
        }
        if (isset($validated['amount'])) {
            $validated['amount'] = (float) $validated['amount'];
        }
        if (isset($validated['interval'])) {
            $validated['interval'] = (int) $validated['interval'];
        }
        if (isset($validated['debit_account_id'])) {
            $validated['debit_account_id'] = (int) $validated['debit_account_id'];
        }
        if (isset($validated['credit_account_id'])) {
            $validated['credit_account_id'] = (int) $validated['credit_account_id'];
        }

        $item->update($validated);

        return $this->ok($item->fresh(['debitAccount', 'creditAccount']), 'Recurring diperbarui');
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

        $item = RecurringOrgEntry::where('id', $id)->where('organization_id', $org->id)->first();
        if (!$item) {
            return $this->fail('Recurring tidak ditemukan', [], 404);
        }

        $item->delete();

        return $this->ok(null, 'Recurring dihapus');
    }

    public function run(Request $request, int $id)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }
        if (!$this->canWriteAccounting($this->organizationRole($request, $org))) {
            return $this->fail('Tidak memiliki akses', [], 403);
        }

        $item = RecurringOrgEntry::where('id', $id)->where('organization_id', $org->id)->first();
        if (!$item || !$item->active) {
            return $this->fail('Recurring tidak ditemukan atau tidak aktif', [], 404);
        }

        try {
            $entry = $this->accounting->createEntry([
                'organization_id' => $org->id,
                'date'            => now()->toDateString(),
                'description'     => $item->description,
                'category'        => $item->category,
                'source'          => 'recurring',
                'created_by'      => $request->user()->id,
                'posted_by'       => $request->user()->id,
            ], [
                [
                    'account_id' => $item->debit_account_id,
                    'debit'      => $item->amount,
                    'credit'     => 0,
                    'memo'       => "Recurring: {$item->description}",
                ],
                [
                    'account_id' => $item->credit_account_id,
                    'debit'      => 0,
                    'credit'     => $item->amount,
                    'memo'       => "Recurring: {$item->description}",
                ],
            ]);
        } catch (InvalidArgumentException $e) {
            return $this->fail($e->getMessage(), [], 422);
        }

        // Advance next_run_at
        $next = $this->advanceNextRun($item);
        $item->update([
            'last_run_at' => now(),
            'next_run_at' => $next,
            'total_runs'  => $item->total_runs + 1,
        ]);

        return $this->ok([
            'journal_entry' => $entry,
            'recurring'     => $item->fresh(['debitAccount', 'creditAccount']),
        ], 'Jurnal recurring berhasil dibuat');
    }

    private function advanceNextRun(RecurringOrgEntry $item): Carbon
    {
        $base = $item->next_run_at ? Carbon::parse($item->next_run_at) : now();
        return match ($item->frequency) {
            'daily'   => $base->addDays($item->interval),
            'weekly'  => $base->addWeeks($item->interval),
            default   => $base->addMonths($item->interval),
        };
    }

    private function validatePayload(Request $request, bool $partial = false): array
    {
        $req = $partial ? 'sometimes|required' : 'required';
        return $request->validate([
            'debit_account_id'  => $req . '|integer',
            'credit_account_id' => $req . '|integer',
            'description'       => $req . '|string|max:500',
            'category'          => 'nullable|string|max:64',
            'amount'            => $req . '|numeric|min:0.01',
            'frequency'         => $req . '|in:daily,weekly,monthly',
            'interval'          => 'nullable|integer|min:1|max:90',
            'start_date'        => $req . '|date',
            'end_date'          => 'nullable|date',
            'active'            => 'nullable|boolean',
        ]);
    }
}

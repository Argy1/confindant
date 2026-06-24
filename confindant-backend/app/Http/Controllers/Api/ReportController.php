<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Api\Concerns\ResolvesOrganization;
use App\Http\Controllers\Controller;
use App\Models\Account;
use App\Services\Accounting\FinancialReportService;
use Carbon\Carbon;
use Illuminate\Http\Request;

class ReportController extends Controller
{
    use ApiResponse;
    use ResolvesOrganization;

    public function __construct(private readonly FinancialReportService $reports)
    {
    }

    public function balanceSheet(Request $request)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }

        $validated = $request->validate(['as_of' => 'nullable|date']);
        $asOf = isset($validated['as_of'])
            ? Carbon::parse($validated['as_of'])
            : now();

        $report = $this->reports->balanceSheet($org->id, $asOf);

        return $this->ok($report, 'Laporan neraca berhasil dibuat', [
            'organization' => ['id' => $org->id, 'name' => $org->name],
        ]);
    }

    public function statementOfActivities(Request $request)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }

        $validated = $request->validate([
            'from_date' => 'nullable|date',
            'to_date' => 'nullable|date',
            'year' => 'nullable|integer|min:2000|max:2100',
        ]);

        if (!empty($validated['year'])) {
            $from = Carbon::create((int) $validated['year'], 1, 1)->startOfDay();
            $to = Carbon::create((int) $validated['year'], 12, 31)->endOfDay();
        } else {
            $from = isset($validated['from_date'])
                ? Carbon::parse($validated['from_date'])->startOfDay()
                : now()->startOfYear();
            $to = isset($validated['to_date'])
                ? Carbon::parse($validated['to_date'])->endOfDay()
                : now()->endOfYear();
        }

        $report = $this->reports->statementOfActivities($org->id, $from, $to);

        return $this->ok($report, 'Laporan aktivitas berhasil dibuat', [
            'organization' => ['id' => $org->id, 'name' => $org->name],
        ]);
    }

    public function generalLedger(Request $request, int $accountId)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }

        $account = Account::where('organization_id', $org->id)->where('id', $accountId)->first();
        if (!$account) {
            return $this->fail('Akun tidak ditemukan', [], 404);
        }

        $validated = $request->validate([
            'from_date' => 'nullable|date',
            'to_date' => 'nullable|date',
        ]);
        $from = isset($validated['from_date'])
            ? Carbon::parse($validated['from_date'])->startOfDay()
            : now()->startOfYear();
        $to = isset($validated['to_date'])
            ? Carbon::parse($validated['to_date'])->endOfDay()
            : now()->endOfYear();

        $report = $this->reports->generalLedger($account, $from, $to);

        return $this->ok($report, 'Buku besar berhasil dibuat');
    }

    public function trialBalance(Request $request)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }

        $validated = $request->validate(['as_of' => 'nullable|date']);
        $asOf = isset($validated['as_of'])
            ? Carbon::parse($validated['as_of'])
            : now();

        $report = $this->reports->trialBalance($org->id, $asOf);

        return $this->ok($report, 'Neraca saldo berhasil dibuat');
    }
}

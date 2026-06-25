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

    /**
     * Aggregated figures for the organization dashboard.
     */
    public function dashboard(Request $request)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }

        $validated = $request->validate(['year' => 'nullable|integer|min:2000|max:2100']);
        $year = (int) ($validated['year'] ?? now()->year);
        $from = Carbon::create($year, 1, 1)->startOfDay();
        $to = Carbon::create($year, 12, 31)->endOfDay();

        $balanceSheet = $this->reports->balanceSheet($org->id, $to);
        $activities = $this->reports->statementOfActivities($org->id, $from, $to);

        // Monthly income vs expense trend for the year.
        $trend = $this->reports->monthlyActivityTrend($org->id, $year);

        // Top expense & revenue accounts.
        $topExpense = collect($activities['expense']['accounts'] ?? [])
            ->sortByDesc('amount')->take(5)->values()->all();
        $topRevenue = collect($activities['revenue']['accounts'] ?? [])
            ->sortByDesc('amount')->take(5)->values()->all();

        return $this->ok([
            'year' => $year,
            'summary' => [
                'total_assets' => $balanceSheet['totals']['total_assets'],
                'total_liabilities' => $balanceSheet['totals']['total_liabilities'],
                'total_net_assets' => $balanceSheet['totals']['total_net_assets'],
                'cash' => $this->cashBalance($balanceSheet),
                'total_revenue' => $activities['totals']['total_revenue'],
                'total_expense' => $activities['totals']['total_expense'],
                'change_in_net_assets' => $activities['totals']['change_in_net_assets'],
            ],
            'is_balanced' => $balanceSheet['is_balanced'],
            'monthly_trend' => $trend,
            'top_expense_accounts' => $topExpense,
            'top_revenue_accounts' => $topRevenue,
        ], 'Dashboard organisasi berhasil diambil', [
            'organization' => ['id' => $org->id, 'name' => $org->name],
        ]);
    }

    private function cashBalance(array $balanceSheet): float
    {
        foreach ($balanceSheet['assets']['accounts'] ?? [] as $acc) {
            if (($acc['code'] ?? '') === '1-1000') {
                return (float) $acc['amount'];
            }
        }
        return 0.0;
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

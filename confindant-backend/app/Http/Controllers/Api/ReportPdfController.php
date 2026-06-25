<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ResolvesOrganization;
use App\Http\Controllers\Controller;
use App\Services\Accounting\FinancialReportService;
use Barryvdh\DomPDF\Facade\Pdf;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

class ReportPdfController extends Controller
{
    use ResolvesOrganization;

    public function __construct(private readonly FinancialReportService $reports)
    {
    }

    public function balanceSheet(Request $request): Response
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            abort(404, 'Organisasi tidak ditemukan');
        }

        $validated = $request->validate(['as_of' => 'nullable|date']);
        $asOf = isset($validated['as_of']) ? Carbon::parse($validated['as_of']) : now();

        $data = $this->reports->balanceSheet($org->id, $asOf);

        $pdf = Pdf::loadView('reports.balance-sheet', [
            'orgName'     => $org->name,
            'asOf'        => $asOf->toDateString(),
            'assets'      => $data['assets'],
            'liabilities' => $data['liabilities'],
            'netAssets'   => $data['net_assets'],
            'totals'      => $data['totals'],
            'isBalanced'  => $data['is_balanced'],
            'difference'  => $data['difference'],
        ])->setPaper('a4', 'portrait');

        $filename = 'neraca-' . $org->slug . '-' . $asOf->format('Y') . '.pdf';

        return $pdf->download($filename);
    }

    public function activities(Request $request): Response
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            abort(404, 'Organisasi tidak ditemukan');
        }

        $validated = $request->validate([
            'from_date' => 'nullable|date',
            'to_date'   => 'nullable|date',
            'year'      => 'nullable|integer|min:2000|max:2100',
        ]);

        if (!empty($validated['year'])) {
            $from = Carbon::create((int) $validated['year'], 1, 1)->startOfDay();
            $to   = Carbon::create((int) $validated['year'], 12, 31)->endOfDay();
        } else {
            $from = isset($validated['from_date'])
                ? Carbon::parse($validated['from_date'])->startOfDay()
                : now()->startOfYear();
            $to = isset($validated['to_date'])
                ? Carbon::parse($validated['to_date'])->endOfDay()
                : now()->endOfYear();
        }

        $data = $this->reports->statementOfActivities($org->id, $from, $to);

        $pdf = Pdf::loadView('reports.activities', [
            'orgName' => $org->name,
            'from'    => $from->toDateString(),
            'to'      => $to->toDateString(),
            'revenue' => $data['revenue'],
            'expense' => $data['expense'],
            'totals'  => $data['totals'],
        ])->setPaper('a4', 'portrait');

        $year     = $from->year;
        $filename = 'laporan-aktivitas-' . $org->slug . '-' . $year . '.pdf';

        return $pdf->download($filename);
    }

    public function trialBalance(Request $request): Response
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            abort(404, 'Organisasi tidak ditemukan');
        }

        $validated = $request->validate(['as_of' => 'nullable|date']);
        $asOf = isset($validated['as_of']) ? Carbon::parse($validated['as_of']) : now();

        $data = $this->reports->trialBalance($org->id, $asOf);

        $totalDebit  = collect($data['accounts'] ?? [])->sum('debit');
        $totalCredit = collect($data['accounts'] ?? [])->sum('credit');

        $pdf = Pdf::loadView('reports.trial-balance', [
            'orgName'     => $org->name,
            'asOf'        => $asOf->toDateString(),
            'accounts'    => $data['accounts'] ?? [],
            'totalDebit'  => $totalDebit,
            'totalCredit' => $totalCredit,
            'isBalanced'  => abs($totalDebit - $totalCredit) < 0.01,
        ])->setPaper('a4', 'portrait');

        $filename = 'neraca-saldo-' . $org->slug . '-' . $asOf->format('Y') . '.pdf';

        return $pdf->download($filename);
    }
}

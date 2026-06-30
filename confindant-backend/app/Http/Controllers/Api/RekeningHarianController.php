<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ApiResponse;
use App\Http\Controllers\Api\Concerns\ResolvesOrganization;
use App\Http\Controllers\Controller;
use App\Models\Account;
use App\Models\JournalEntry;
use App\Models\JournalLine;
use App\Services\Accounting\AccountingService;
use App\Services\Accounting\ExcelImportService;
use Illuminate\Http\Request;
use InvalidArgumentException;

/**
 * Simplified "Rekening Harian" cash-book interface.
 *
 * Each entry is stored as a regular double-entry journal (source='harian')
 * against the Kas account (1-1000). The counter account is resolved
 * automatically from the kategori using ExcelImportService::categoryAccountMap().
 */
class RekeningHarianController extends Controller
{
    use ApiResponse;
    use ResolvesOrganization;

    public function __construct(
        private readonly AccountingService $accounting,
        private readonly ExcelImportService $importService,
    ) {}

    // -------------------------------------------------------------------------
    // GET /accounting/rekening-harian
    // -------------------------------------------------------------------------

    public function index(Request $request)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }

        $validated = $request->validate([
            'from_date' => 'nullable|date',
            'to_date'   => 'nullable|date',
            'per_page'  => 'nullable|integer|min:1|max:500',
            'page'      => 'nullable|integer|min:1',
        ]);

        $kasAccount = Account::where('organization_id', $org->id)
            ->where('code', '1-1000')
            ->first();

        if (!$kasAccount) {
            return $this->ok([], 'Akun Kas belum tersedia', [
                'opening_balance' => 0,
                'running_balance' => 0,
                'total' => 0,
            ]);
        }

        $perPage = (int) ($validated['per_page'] ?? 50);
        $page    = (int) ($validated['page'] ?? 1);

        // Opening balance: sum of kas lines before from_date (if filtered)
        $openingBalance = 0.0;
        if (!empty($validated['from_date'])) {
            $openingBalance = (float) JournalLine::where('account_id', $kasAccount->id)
                ->whereHas('entry', fn($q) => $q
                    ->where('organization_id', $org->id)
                    ->where('status', 'posted')
                    ->whereDate('date', '<', $validated['from_date'])
                )
                ->selectRaw('COALESCE(SUM(debit),0) - COALESCE(SUM(credit),0) as net')
                ->value('net');
        }

        // All entries touching Kas, oldest-first for running balance computation
        $baseQuery = JournalEntry::where('organization_id', $org->id)
            ->where('status', 'posted')
            ->whereHas('lines', fn($q) => $q->where('account_id', $kasAccount->id))
            ->orderBy('date', 'asc')
            ->orderBy('id', 'asc');

        if (!empty($validated['from_date'])) {
            $baseQuery->whereDate('date', '>=', $validated['from_date']);
        }
        if (!empty($validated['to_date'])) {
            $baseQuery->whereDate('date', '<=', $validated['to_date']);
        }

        $total = $baseQuery->count();

        // We need ALL entries to compute running balances correctly,
        // then slice the requested page.
        $allEntries = $baseQuery->with(['lines' => fn($q) => $q->where('account_id', $kasAccount->id)])->get();

        $balance = $openingBalance;
        $rows    = [];
        foreach ($allEntries as $entry) {
            $kasLine = $entry->lines->first();
            if (!$kasLine) continue;

            $pemasukan   = (float) $kasLine->debit;
            $pengeluaran = (float) $kasLine->credit;
            $balance    += $pemasukan - $pengeluaran;

            $rows[] = [
                'id'           => $entry->id,
                'date'         => $entry->date instanceof \Carbon\Carbon
                    ? $entry->date->toDateString()
                    : (string) $entry->date,
                'uraian'       => $entry->description,
                'pemasukan'    => $pemasukan > 0 ? round($pemasukan, 2) : null,
                'pengeluaran'  => $pengeluaran > 0 ? round($pengeluaran, 2) : null,
                'saldo'        => round($balance, 2),
                'kategori'     => $entry->category,
                'keterangan'   => $entry->reference,
                'klasifikasi'  => $entry->classification,
                'source'       => $entry->source,
            ];
        }

        $runningBalance = $balance;

        // Return newest-first for display, sliced to the requested page
        $rows    = array_reverse($rows);
        $sliced  = array_slice($rows, ($page - 1) * $perPage, $perPage);

        return $this->ok($sliced, 'Rekening harian berhasil diambil', [
            'page'            => $page,
            'per_page'        => $perPage,
            'total'           => $total,
            'has_more'        => ($page * $perPage) < $total,
            'opening_balance' => round($openingBalance, 2),
            'running_balance' => round($runningBalance, 2),
        ]);
    }

    // -------------------------------------------------------------------------
    // POST /accounting/rekening-harian
    // -------------------------------------------------------------------------

    public function store(Request $request)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }
        if (!$this->canWriteAccounting($this->organizationRole($request, $org))) {
            return $this->fail('Anda tidak memiliki akses untuk menambah entri', [], 403);
        }

        $validated = $request->validate([
            'date'         => 'required|date',
            'uraian'       => 'required|string|max:1000',
            'pemasukan'    => 'nullable|numeric|min:0',
            'pengeluaran'  => 'nullable|numeric|min:0',
            'kategori'     => 'nullable|string|max:64',
            'keterangan'   => 'nullable|string|max:255',
            'klasifikasi'  => 'nullable|string|max:64',
        ]);

        $pemasukan   = (float) ($validated['pemasukan'] ?? 0);
        $pengeluaran = (float) ($validated['pengeluaran'] ?? 0);

        if ($pemasukan <= 0 && $pengeluaran <= 0) {
            return $this->fail('Pemasukan atau pengeluaran harus diisi', [], 422);
        }
        if ($pemasukan > 0 && $pengeluaran > 0) {
            return $this->fail('Hanya isi salah satu: pemasukan atau pengeluaran', [], 422);
        }

        $kasAccount = Account::where('organization_id', $org->id)
            ->where('code', '1-1000')
            ->first();
        if (!$kasAccount) {
            return $this->fail('Akun Kas (1-1000) belum tersedia. Tambahkan di Bagan Akun terlebih dahulu.', [], 422);
        }

        $isIncome = $pemasukan > 0;
        $amount   = $isIncome ? $pemasukan : $pengeluaran;
        $kategori = strtolower(trim($validated['kategori'] ?? ''));

        $map          = $this->importService->categoryAccountMap();
        $counterCode  = $map[$kategori] ?? null;
        $fallback     = $isIncome ? '4-9000' : '5-9000';
        $counterCode  = $counterCode ?? $fallback;

        $counterAccount = Account::where('organization_id', $org->id)
            ->where('code', $counterCode)
            ->first();
        if (!$counterAccount) {
            return $this->fail(
                "Akun untuk kategori '{$kategori}' (kode {$counterCode}) belum tersedia di Bagan Akun.",
                [],
                422
            );
        }

        $lines = $isIncome
            ? [
                ['account_id' => $kasAccount->id,     'debit' => $amount, 'credit' => 0],
                ['account_id' => $counterAccount->id,  'debit' => 0,       'credit' => $amount],
            ]
            : [
                ['account_id' => $counterAccount->id,  'debit' => $amount, 'credit' => 0],
                ['account_id' => $kasAccount->id,      'debit' => 0,       'credit' => $amount],
            ];

        try {
            $entry = $this->accounting->createEntry([
                'organization_id' => $org->id,
                'date'            => $validated['date'],
                'description'     => $validated['uraian'],
                'category'        => $kategori ?: null,
                'classification'  => $validated['klasifikasi'] ?? null,
                'reference'       => $validated['keterangan'] ?? null,
                'source'          => 'harian',
                'created_by'      => $request->user()->id,
                'posted_by'       => $request->user()->id,
            ], $lines);
        } catch (InvalidArgumentException $e) {
            return $this->fail($e->getMessage(), [], 422);
        }

        return $this->ok($entry->load('lines.account'), 'Entri berhasil ditambahkan', [], 201);
    }

    // -------------------------------------------------------------------------
    // DELETE /accounting/rekening-harian/{id}  (void the entry)
    // -------------------------------------------------------------------------

    public function destroy(Request $request, int $id)
    {
        $org = $this->resolveOrganization($request);
        if (!$org) {
            return $this->fail('Organisasi tidak ditemukan', [], 404);
        }
        if (!$this->canWriteAccounting($this->organizationRole($request, $org))) {
            return $this->fail('Anda tidak memiliki akses untuk menghapus entri', [], 403);
        }

        $entry = JournalEntry::where('organization_id', $org->id)
            ->where('id', $id)
            ->first();
        if (!$entry) {
            return $this->fail('Entri tidak ditemukan', [], 404);
        }
        if ($entry->status === 'void') {
            return $this->fail('Entri sudah dibatalkan sebelumnya', [], 422);
        }

        $this->accounting->voidEntry($entry, $request->user()->id);

        return $this->ok(null, 'Entri berhasil dibatalkan');
    }

    // -------------------------------------------------------------------------
    // GET /accounting/rekening-harian/categories
    // -------------------------------------------------------------------------

    public function categories(Request $request)
    {
        $map = $this->importService->categoryAccountMap();

        $income  = [];
        $expense = [];
        $other   = [];

        foreach ($map as $label => $code) {
            if (str_starts_with($code, '4-')) {
                $income[] = $label;
            } elseif (str_starts_with($code, '5-')) {
                $expense[] = $label;
            } else {
                $other[] = $label;
            }
        }

        return $this->ok(
            compact('income', 'expense', 'other'),
            'Daftar kategori berhasil diambil'
        );
    }
}

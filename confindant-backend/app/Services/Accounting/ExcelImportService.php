<?php

namespace App\Services\Accounting;

use App\Models\Account;
use App\Models\Organization;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use PhpOffice\PhpSpreadsheet\IOFactory;
use PhpOffice\PhpSpreadsheet\Shared\Date as ExcelDate;

/**
 * Imports the PDPI "HARIAN" journal sheet into double-entry journal entries.
 *
 * The HARIAN sheet is single-entry (Pemasukan/Pengeluaran columns against a
 * running cash balance). We convert each row into a balanced entry against the
 * Kas account, mapping the row's "Kategori" to the proper revenue/expense
 * account via {@see categoryAccountMap()}.
 *
 * Sheet columns (1-indexed):
 *   A Tanggal | B Uraian | C Pemasukan(D) | D Pengeluaran(K) |
 *   E Saldo | F Keterangan | G Kategori | H Klasifikasi
 */
class ExcelImportService
{
    public function __construct(private readonly AccountingService $accounting)
    {
    }

    /**
     * Maps lowercased "Kategori" values from the HARIAN sheet to account codes.
     * Income categories pair with Kas-debit; expense categories with Kas-credit.
     */
    public function categoryAccountMap(): array
    {
        return [
            // --- Pendapatan (revenue) ---
            'ers' => '4-1200',
            'apsr 1' => '4-1100',
            'apsr 2' => '4-1100',
            'iuran anggota' => '4-1000',
            'iuran ers 2026' => '4-1200',
            'donasi kegiatan' => '4-2000',
            'shu wcbip' => '4-3000',
            'shu poti' => '4-3100',
            'pemasukan lain' => '4-9000',
            'pendapatan lain' => '4-9000',

            // --- Beban (expense) ---
            'honor' => '5-1100',
            'transport & akom' => '5-1000',
            'transport akom' => '5-1000',
            'transport' => '5-1000',
            'gaji' => '5-2000',
            'thr' => '5-2100',
            'webinar' => '5-1400',
            'seminar' => '5-1300',
            'workshop' => '5-1500',
            'buku' => '5-1200',
            'pajak' => '5-3300',
            'admin' => '5-3200',
            'sekre lain' => '5-2200',
            'pembelian perlengkapan kantor' => '5-2300',
            'perlengkapan' => '5-2300',
            'kegiatan lain' => '5-1900',
            'pengeluaran lain' => '5-9000',
            'pembangunan rumah' => '5-3400',
            'biaya apsr 2' => '5-1600',
            'biaya apsr pp' => '5-1600',
            'biaya ers' => '5-1700',
            'refund ers' => '5-9000',
            'refund apsr 1' => '5-9000',
            'refund apsr 2' => '5-9000',
            'biaya shu' => '5-9000',
            'mutasi-shu perbronki' => '4-3200',

            // --- Balance-sheet movements (control accounts) ---
            'piutang' => '1-1100',
            'piutang lain' => '1-1200',
            'dana titipan cabang' => '2-1400',
            'biaya titipan cabang' => '2-1400',
            'dana titipan kegiatan ilmiah' => '2-1500',
            'biaya titipan kegiatan ilmiah' => '2-1500',
            'hutang kegiatan' => '2-1000',
        ];
    }

    /**
     * Parse and import the HARIAN sheet. Returns a summary; can run in dry-run
     * mode to preview without writing.
     *
     * @return array{imported:int, skipped:int, unmapped:array<string,int>, total_debit:float, total_credit:float, dry_run:bool}
     */
    public function importHarian(
        Organization $org,
        string $filePath,
        string $sheetName = 'HARIAN 2025',
        bool $dryRun = false,
        ?int $userId = null
    ): array {
        $spreadsheet = IOFactory::load($filePath);
        $sheet = $spreadsheet->getSheetByName($sheetName) ?? $spreadsheet->getActiveSheet();

        $kasId = $this->accountId($org->id, '1-1000');
        $uncategorizedRevenue = $this->accountId($org->id, '4-9000');
        $uncategorizedExpense = $this->accountId($org->id, '5-9000');
        $map = $this->categoryAccountMap();

        $imported = 0;
        $skipped = 0;
        $unmapped = [];
        $totalDebit = 0.0;
        $totalCredit = 0.0;

        $rows = $sheet->toArray(null, true, true, true); // assoc by column letter

        $apply = function () use (
            $rows, $org, $kasId, $map, $uncategorizedRevenue, $uncategorizedExpense,
            $userId, &$imported, &$skipped, &$unmapped, &$totalDebit, &$totalCredit
        ) {
            foreach ($rows as $row) {
                $rawDate = $row['A'] ?? null;
                $uraian = trim((string) ($row['B'] ?? ''));
                $pemasukan = $this->toNumber($row['C'] ?? 0);
                $pengeluaran = $this->toNumber($row['D'] ?? 0);
                $kategori = strtolower(trim((string) ($row['G'] ?? '')));

                $date = $this->parseDate($rawDate);
                if (!$date || ($pemasukan <= 0 && $pengeluaran <= 0) || $uraian === '') {
                    $skipped++;
                    continue;
                }

                $isIncome = $pemasukan > 0;
                $amount = $isIncome ? $pemasukan : $pengeluaran;

                $counterCode = $map[$kategori] ?? null;
                if (!$counterCode) {
                    $unmapped[$kategori ?: '(kosong)'] = ($unmapped[$kategori ?: '(kosong)'] ?? 0) + 1;
                    $counterId = $isIncome ? $uncategorizedRevenue : $uncategorizedExpense;
                } else {
                    $counterId = $this->accountId($org->id, $counterCode);
                }

                $lines = $isIncome
                    ? [
                        ['account_id' => $kasId, 'debit' => $amount],
                        ['account_id' => $counterId, 'credit' => $amount],
                    ]
                    : [
                        ['account_id' => $counterId, 'debit' => $amount],
                        ['account_id' => $kasId, 'credit' => $amount],
                    ];

                $this->accounting->createEntry([
                    'organization_id' => $org->id,
                    'date' => $date,
                    'description' => $uraian,
                    'category' => $kategori ?: null,
                    'classification' => trim((string) ($row['H'] ?? '')) ?: null,
                    'reference' => trim((string) ($row['F'] ?? '')) ?: null,
                    'source' => 'import',
                    'created_by' => $userId,
                    'posted_by' => $userId,
                ], $lines);

                $imported++;
                $totalDebit += $amount;
                $totalCredit += $amount;
            }
        };

        if ($dryRun) {
            // Count without persisting: re-run the loop logic but skip createEntry.
            foreach ($rows as $row) {
                $date = $this->parseDate($row['A'] ?? null);
                $pemasukan = $this->toNumber($row['C'] ?? 0);
                $pengeluaran = $this->toNumber($row['D'] ?? 0);
                $uraian = trim((string) ($row['B'] ?? ''));
                $kategori = strtolower(trim((string) ($row['G'] ?? '')));
                if (!$date || ($pemasukan <= 0 && $pengeluaran <= 0) || $uraian === '') {
                    $skipped++;
                    continue;
                }
                if (!isset($this->categoryAccountMap()[$kategori])) {
                    $unmapped[$kategori ?: '(kosong)'] = ($unmapped[$kategori ?: '(kosong)'] ?? 0) + 1;
                }
                $imported++;
                $amount = $pemasukan > 0 ? $pemasukan : $pengeluaran;
                $totalDebit += $amount;
                $totalCredit += $amount;
            }
        } else {
            DB::transaction($apply);
        }

        return [
            'imported' => $imported,
            'skipped' => $skipped,
            'unmapped' => $unmapped,
            'total_debit' => round($totalDebit, 2),
            'total_credit' => round($totalCredit, 2),
            'dry_run' => $dryRun,
        ];
    }

    private function accountId(int $organizationId, string $code): ?int
    {
        return Account::where('organization_id', $organizationId)->where('code', $code)->value('id');
    }

    private function toNumber(mixed $value): float
    {
        if (is_numeric($value)) {
            return (float) $value;
        }
        $clean = preg_replace('/[^0-9.\-]/', '', (string) $value);
        return is_numeric($clean) ? (float) $clean : 0.0;
    }

    private function parseDate(mixed $value): ?Carbon
    {
        if ($value === null || $value === '') {
            return null;
        }
        // Excel serial date number
        if (is_numeric($value)) {
            try {
                return Carbon::instance(ExcelDate::excelToDateTimeObject((float) $value));
            } catch (\Throwable) {
                return null;
            }
        }
        try {
            return Carbon::parse((string) $value);
        } catch (\Throwable) {
            return null;
        }
    }
}

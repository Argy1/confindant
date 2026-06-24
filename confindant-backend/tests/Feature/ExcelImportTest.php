<?php

namespace Tests\Feature;

use App\Models\JournalEntry;
use App\Models\Organization;
use App\Services\Accounting\ExcelImportService;
use App\Services\Accounting\FinancialReportService;
use Carbon\Carbon;
use Database\Seeders\PdpiChartOfAccountsSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;
use Tests\TestCase;

class ExcelImportTest extends TestCase
{
    use RefreshDatabase;

    private Organization $org;
    private string $tmpFile;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(PdpiChartOfAccountsSeeder::class);
        $this->org = Organization::where('slug', 'pdpi')->firstOrFail();
        $this->tmpFile = $this->makeHarianFixture();
    }

    protected function tearDown(): void
    {
        if (isset($this->tmpFile) && file_exists($this->tmpFile)) {
            @unlink($this->tmpFile);
        }
        parent::tearDown();
    }

    /**
     * Build a small HARIAN-format xlsx mirroring the PDPI sheet layout.
     */
    private function makeHarianFixture(): string
    {
        $spreadsheet = new Spreadsheet();
        $sheet = $spreadsheet->getActiveSheet();
        $sheet->setTitle('HARIAN 2025');

        // Header rows (mirip file asli: judul di atas, header kolom di baris 5)
        $sheet->setCellValue('A1', 'JURNAL UMUM');
        $sheet->fromArray(
            ['Tanggal', 'Uraian', 'Pemasukan', 'Pengeluaran', 'Saldo', 'Keterangan', 'Kategori', 'Klasifikasi'],
            null,
            'A5'
        );

        // Data rows (real PDPI-style transactions)
        $rows = [
            ['2025-01-01', 'Pemasukan Iuran ERS dr. Aria', 550000, 0, 0, '', 'ERS', ''],
            ['2025-01-03', 'Donasi PT AstraZeneca', 20000000, 0, 0, '074-INV', 'donasi kegiatan', ''],
            ['2025-01-03', 'Biaya Gaji Aris', 0, 7000000, 0, '', 'gaji', ''],
            ['2025-01-03', 'Biaya Fee Sambutan PP', 0, 2000000, 0, '', 'honor', ''],
            ['2025-01-03', 'Biaya Admin Bank', 0, 2900, 0, '', 'admin', ''],
            ['2025-01-05', 'Transaksi kategori tak dikenal', 0, 150000, 0, '', 'kategori_aneh', ''],
        ];
        $sheet->fromArray($rows, null, 'A6');

        $tmp = tempnam(sys_get_temp_dir(), 'harian_').'.xlsx';
        (new Xlsx($spreadsheet))->save($tmp);

        return $tmp;
    }

    public function test_dry_run_previews_without_writing(): void
    {
        $service = app(ExcelImportService::class);
        $result = $service->importHarian($this->org, $this->tmpFile, 'HARIAN 2025', dryRun: true);

        $this->assertSame(6, $result['imported']);
        $this->assertTrue($result['dry_run']);
        $this->assertSame(0, JournalEntry::where('organization_id', $this->org->id)->count());
        // The unknown category should be flagged
        $this->assertArrayHasKey('kategori_aneh', $result['unmapped']);
    }

    public function test_import_creates_balanced_journal_entries(): void
    {
        $service = app(ExcelImportService::class);
        $result = $service->importHarian($this->org, $this->tmpFile, 'HARIAN 2025', dryRun: false);

        $this->assertSame(6, $result['imported']);
        $this->assertEquals($result['total_debit'], $result['total_credit']);

        // 6 journal entries created
        $this->assertSame(6, JournalEntry::where('organization_id', $this->org->id)->count());

        // Ledger must be balanced after import
        $tb = app(FinancialReportService::class)->trialBalance($this->org->id, Carbon::parse('2025-12-31'));
        $this->assertTrue($tb['is_balanced']);

        // Statement of activities: revenue 20.550.000, expense 9.152.900
        $report = app(FinancialReportService::class)->statementOfActivities(
            $this->org->id,
            Carbon::parse('2025-01-01'),
            Carbon::parse('2025-12-31')
        );
        $this->assertEquals(20550000, $report['totals']['total_revenue']);
        // 7.000.000 + 2.000.000 + 2.900 + 150.000 (unknown -> Pengeluaran Lain)
        $this->assertEquals(9152900, $report['totals']['total_expense']);
    }
}

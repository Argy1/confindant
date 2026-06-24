<?php

namespace Tests\Feature;

use App\Models\Account;
use App\Models\Organization;
use App\Services\Accounting\AccountingService;
use App\Services\Accounting\FinancialReportService;
use Carbon\Carbon;
use Database\Seeders\PdpiChartOfAccountsSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use InvalidArgumentException;
use Tests\TestCase;

class PdpiAccountingTest extends TestCase
{
    use RefreshDatabase;

    private Organization $org;
    private AccountingService $accounting;
    private FinancialReportService $reports;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(PdpiChartOfAccountsSeeder::class);
        $this->org = Organization::where('slug', 'pdpi')->firstOrFail();
        $this->accounting = app(AccountingService::class);
        $this->reports = app(FinancialReportService::class);
    }

    private function account(string $code): Account
    {
        return Account::where('organization_id', $this->org->id)
            ->where('code', $code)
            ->firstOrFail();
    }

    public function test_chart_of_accounts_is_seeded(): void
    {
        $count = Account::where('organization_id', $this->org->id)->count();
        $this->assertGreaterThanOrEqual(40, $count, 'Chart of accounts harus punya >= 40 akun');

        // Normal balances sanity check
        $this->assertSame('debit', $this->account('1-1000')->normal_balance); // Kas (asset)
        $this->assertSame('credit', $this->account('2-1000')->normal_balance); // Hutang (liability)
        $this->assertSame('credit', $this->account('4-2000')->normal_balance); // Donasi (revenue)
        $this->assertSame('debit', $this->account('5-1100')->normal_balance); // Honor (expense)
    }

    public function test_balanced_journal_entry_posts_successfully(): void
    {
        // Real PDPI transaction: Pemasukan Iuran ERS Rp 550.000 masuk ke Kas
        $entry = $this->accounting->createEntry([
            'organization_id' => $this->org->id,
            'date' => '2025-01-01',
            'description' => 'Pemasukan Dana dari dr. Aria Purnama, Sp.P - ERS',
            'category' => 'ERS',
        ], [
            ['account_id' => $this->account('1-1000')->id, 'debit' => 550000], // Kas naik
            ['account_id' => $this->account('4-1200')->id, 'credit' => 550000], // Pendapatan Iuran ERS
        ]);

        $this->assertSame('posted', $entry->status);
        $this->assertEquals(550000, $entry->total_amount);
        $this->assertCount(2, $entry->lines);
        $this->assertNotNull($entry->entry_number);
    }

    public function test_unbalanced_journal_is_rejected(): void
    {
        $this->expectException(InvalidArgumentException::class);
        $this->expectExceptionMessage('tidak seimbang');

        $this->accounting->createEntry([
            'organization_id' => $this->org->id,
            'date' => '2025-01-01',
            'description' => 'Jurnal tidak seimbang',
        ], [
            ['account_id' => $this->account('1-1000')->id, 'debit' => 550000],
            ['account_id' => $this->account('4-1200')->id, 'credit' => 500000], // sengaja beda
        ]);
    }

    public function test_balance_sheet_is_balanced_after_multiple_entries(): void
    {
        // Opening: set Kas opening balance to match PDPI awal tahun
        $kas = $this->account('1-1000');
        $kas->update(['opening_balance' => 705926775.71]);
        // Aset bersih awal sebagai penyeimbang opening
        $this->account('3-1000')->update(['opening_balance' => 705926775.71]);

        // Beberapa transaksi nyata PDPI Januari 2025
        $entries = [
            // Iuran ERS masuk
            [['1-1000', 550000, 0], ['4-1200', 0, 550000], 'Iuran ERS'],
            // Donasi AstraZeneca
            [['1-1000', 20000000, 0], ['4-2000', 0, 20000000], 'Donasi AstraZeneca'],
            // Biaya Gaji
            [['5-2000', 7000000, 0], ['1-1000', 0, 7000000], 'Gaji Aris'],
            // Biaya Honor
            [['5-1100', 2000000, 0], ['1-1000', 0, 2000000], 'Fee Sambutan PP'],
            // Biaya Admin Bank
            [['5-3200', 2900, 0], ['1-1000', 0, 2900], 'Admin Bank'],
        ];

        foreach ($entries as [$debitLine, $creditLine, $desc]) {
            $this->accounting->createEntry([
                'organization_id' => $this->org->id,
                'date' => '2025-01-03',
                'description' => $desc,
            ], [
                ['account_id' => $this->account($debitLine[0])->id, 'debit' => $debitLine[1], 'credit' => $debitLine[2]],
                ['account_id' => $this->account($creditLine[0])->id, 'debit' => $creditLine[1], 'credit' => $creditLine[2]],
            ]);
        }

        $asOf = Carbon::parse('2025-12-31');
        $balanceSheet = $this->reports->balanceSheet($this->org->id, $asOf);

        $this->assertTrue(
            $balanceSheet['is_balanced'],
            'Neraca harus seimbang. Selisih: '.$balanceSheet['difference']
        );

        // Verifikasi nilai Kas: 705.926.775,71 + 550k + 20jt - 7jt - 2jt - 2.900
        $expectedKas = 705926775.71 + 550000 + 20000000 - 7000000 - 2000000 - 2900;
        $this->assertEqualsWithDelta($expectedKas, $balanceSheet['totals']['total_assets'], 0.01);
    }

    public function test_statement_of_activities_computes_change_in_net_assets(): void
    {
        // Pendapatan total 20.550.000, Beban total 9.002.900
        $this->accounting->createEntry([
            'organization_id' => $this->org->id, 'date' => '2025-01-03', 'description' => 'Iuran',
        ], [
            ['account_id' => $this->account('1-1000')->id, 'debit' => 550000],
            ['account_id' => $this->account('4-1200')->id, 'credit' => 550000],
        ]);
        $this->accounting->createEntry([
            'organization_id' => $this->org->id, 'date' => '2025-01-03', 'description' => 'Donasi',
        ], [
            ['account_id' => $this->account('1-1000')->id, 'debit' => 20000000],
            ['account_id' => $this->account('4-2000')->id, 'credit' => 20000000],
        ]);
        $this->accounting->createEntry([
            'organization_id' => $this->org->id, 'date' => '2025-01-03', 'description' => 'Gaji',
        ], [
            ['account_id' => $this->account('5-2000')->id, 'debit' => 9000000],
            ['account_id' => $this->account('1-1000')->id, 'credit' => 9000000],
        ]);

        $from = Carbon::parse('2025-01-01');
        $to = Carbon::parse('2025-12-31');
        $report = $this->reports->statementOfActivities($this->org->id, $from, $to);

        $this->assertEquals(20550000, $report['totals']['total_revenue']);
        $this->assertEquals(9000000, $report['totals']['total_expense']);
        $this->assertEquals(11550000, $report['totals']['change_in_net_assets']);
    }

    public function test_trial_balance_is_balanced(): void
    {
        $this->accounting->createEntry([
            'organization_id' => $this->org->id, 'date' => '2025-02-06', 'description' => 'Iuran APSR',
        ], [
            ['account_id' => $this->account('1-1000')->id, 'debit' => 500000],
            ['account_id' => $this->account('4-1100')->id, 'credit' => 500000],
        ]);

        $tb = $this->reports->trialBalance($this->org->id, Carbon::parse('2025-12-31'));
        $this->assertTrue($tb['is_balanced'], 'Neraca saldo harus seimbang');
        $this->assertEquals($tb['total_debit'], $tb['total_credit']);
    }

    public function test_void_entry_creates_reversal(): void
    {
        $entry = $this->accounting->createEntry([
            'organization_id' => $this->org->id, 'date' => '2025-01-03', 'description' => 'Transaksi salah',
        ], [
            ['account_id' => $this->account('1-1000')->id, 'debit' => 1000000],
            ['account_id' => $this->account('4-9000')->id, 'credit' => 1000000],
        ]);

        $this->accounting->voidEntry($entry);
        $entry->refresh();

        $this->assertSame('void', $entry->status);

        // Setelah void, saldo Kas dari transaksi ini harus netral (0)
        $kas = $this->account('1-1000');
        $balance = $this->accounting->accountBalance($kas, Carbon::parse('2025-12-31'));
        $this->assertEqualsWithDelta(0, $balance, 0.01);
    }
}

<?php

namespace Tests\Feature;

use App\Models\Account;
use App\Models\FixedAsset;
use App\Models\Organization;
use App\Models\ReceivablePayable;
use App\Models\RestrictedFund;
use App\Services\Accounting\DepreciationService;
use App\Services\Accounting\FinancialReportService;
use App\Services\Accounting\ReceivablePayableService;
use App\Services\Accounting\RestrictedFundService;
use Carbon\Carbon;
use Database\Seeders\PdpiChartOfAccountsSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AccountingPhaseCDTest extends TestCase
{
    use RefreshDatabase;

    private Organization $org;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(PdpiChartOfAccountsSeeder::class);
        $this->org = Organization::where('slug', 'pdpi')->firstOrFail();
    }

    private function account(string $code): Account
    {
        return Account::where('organization_id', $this->org->id)->where('code', $code)->firstOrFail();
    }

    // ---------------- Fase C: Penyusutan ----------------

    public function test_straight_line_depreciation_posts_and_updates_book_value(): void
    {
        // Laptop Rp 11.650.000, tarif 25%, perolehan 2025-03-19 (10 bulan di 2025)
        $asset = FixedAsset::create([
            'organization_id' => $this->org->id,
            'name' => 'Laptop',
            'group' => 'PERLENGKAPAN',
            'acquisition_date' => '2025-03-19',
            'acquisition_cost' => 11650000,
            'depreciation_rate' => 0.25,
            'method' => 'straight_line',
            'salvage_value' => 0,
            'asset_account_id' => $this->account('1-2200')->id,
            'accumulated_depreciation_account_id' => $this->account('1-2250')->id,
            'depreciation_expense_account_id' => $this->account('5-3100')->id,
            'accumulated_depreciation' => 0,
            'book_value' => 11650000,
            'is_active' => true,
        ]);

        $service = app(DepreciationService::class);
        $record = $service->runForAsset($asset, 2025);

        // Annual = 11.650.000 * 0.25 = 2.912.500; pro-rated 10/12 = 2.427.083,33
        $this->assertEqualsWithDelta(2427083.33, (float) $record->amount, 1);

        $asset->refresh();
        $this->assertEqualsWithDelta(2427083.33, $asset->accumulated_depreciation, 1);
        $this->assertEqualsWithDelta(11650000 - 2427083.33, $asset->book_value, 1);

        // Idempotent: running again returns existing, no double posting
        $again = $service->runForAsset($asset, 2025);
        $this->assertSame($record->id, $again->id);
    }

    public function test_depreciation_keeps_ledger_balanced(): void
    {
        $asset = FixedAsset::create([
            'organization_id' => $this->org->id,
            'name' => 'AC',
            'group' => 'PERLENGKAPAN',
            'acquisition_date' => '2025-01-01',
            'acquisition_cost' => 12000000,
            'depreciation_rate' => 0.25,
            'method' => 'straight_line',
            'salvage_value' => 0,
            'asset_account_id' => $this->account('1-2200')->id,
            'accumulated_depreciation_account_id' => $this->account('1-2250')->id,
            'depreciation_expense_account_id' => $this->account('5-3100')->id,
            'accumulated_depreciation' => 0,
            'book_value' => 12000000,
            'is_active' => true,
        ]);

        app(DepreciationService::class)->runForAsset($asset, 2025);

        $tb = app(FinancialReportService::class)->trialBalance($this->org->id, Carbon::parse('2025-12-31'));
        $this->assertTrue($tb['is_balanced']);
    }

    // ---------------- Fase D: Piutang/Hutang ----------------

    public function test_receivable_create_and_settle(): void
    {
        $service = app(ReceivablePayableService::class);

        // Piutang Iuran ERS Rp 550.000 (belum dibayar)
        $piutang = $service->create([
            'organization_id' => $this->org->id,
            'type' => ReceivablePayable::TYPE_RECEIVABLE,
            'party_name' => 'dr. Aria Purnama',
            'category' => 'Iuran ERS',
            'account_id' => $this->account('1-1100')->id, // Piutang Kegiatan
            'counter_account_id' => $this->account('4-1200')->id, // Pendapatan ERS
            'original_amount' => 550000,
            'issued_date' => '2025-01-01',
        ]);

        $this->assertEquals(550000, $piutang->outstanding_amount);
        $this->assertSame('open', $piutang->status);

        // Pelunasan penuh
        $service->settle(
            $piutang,
            550000,
            $this->account('1-1000')->id, // Kas
            '2025-02-06'
        );
        $piutang->refresh();

        $this->assertEquals(0, $piutang->outstanding_amount);
        $this->assertSame('settled', $piutang->status);

        $tb = app(FinancialReportService::class)->trialBalance($this->org->id, Carbon::parse('2025-12-31'));
        $this->assertTrue($tb['is_balanced']);
    }

    public function test_partial_settlement_marks_partial_status(): void
    {
        $service = app(ReceivablePayableService::class);
        $piutang = $service->create([
            'organization_id' => $this->org->id,
            'type' => ReceivablePayable::TYPE_RECEIVABLE,
            'party_name' => 'Cabang X',
            'account_id' => $this->account('1-1100')->id,
            'counter_account_id' => $this->account('4-1000')->id,
            'original_amount' => 1000000,
            'issued_date' => '2025-01-01',
        ]);

        $service->settle($piutang, 400000, $this->account('1-1000')->id, '2025-03-01');
        $piutang->refresh();

        $this->assertEquals(600000, $piutang->outstanding_amount);
        $this->assertSame('partial', $piutang->status);
    }

    // ---------------- Fase D: Dana Titipan ----------------

    public function test_restricted_fund_in_and_out(): void
    {
        $fund = RestrictedFund::create([
            'organization_id' => $this->org->id,
            'name' => 'Dana Titipan Cabang - Jakarta',
            'fund_type' => 'titipan_cabang',
            'account_id' => $this->account('2-1400')->id,
            'balance' => 0,
            'status' => 'active',
        ]);

        $service = app(RestrictedFundService::class);

        // Dana masuk 10jt
        $service->recordMovement($fund, 'in', 10000000, $this->account('1-1000')->id, '2025-01-10');
        $fund->refresh();
        $this->assertEquals(10000000, $fund->balance);

        // Dana keluar 4jt
        $service->recordMovement($fund, 'out', 4000000, $this->account('1-1000')->id, '2025-02-15');
        $fund->refresh();
        $this->assertEquals(6000000, $fund->balance);

        $tb = app(FinancialReportService::class)->trialBalance($this->org->id, Carbon::parse('2025-12-31'));
        $this->assertTrue($tb['is_balanced']);
    }

    public function test_restricted_fund_cannot_overdraw(): void
    {
        $fund = RestrictedFund::create([
            'organization_id' => $this->org->id,
            'name' => 'Dana Kecil',
            'fund_type' => 'titipan_cabang',
            'account_id' => $this->account('2-1400')->id,
            'balance' => 0,
            'status' => 'active',
        ]);

        $service = app(RestrictedFundService::class);
        $service->recordMovement($fund, 'in', 1000000, $this->account('1-1000')->id, '2025-01-10');

        $this->expectException(\InvalidArgumentException::class);
        $service->recordMovement($fund, 'out', 5000000, $this->account('1-1000')->id, '2025-01-11');
    }
}

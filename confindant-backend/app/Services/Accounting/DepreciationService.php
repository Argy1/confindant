<?php

namespace App\Services\Accounting;

use App\Models\AccountingPeriod;
use App\Models\AssetDepreciation;
use App\Models\FixedAsset;
use App\Models\JournalEntry;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

/**
 * Straight-line depreciation for fixed assets, mirroring the PDPI
 * "Daftar Aktiva Tetap dan Penyusutan" sheet.
 *
 *   Penyusutan per tahun = Harga Perolehan x Tarif
 *   (Peralatan: 25% / 4 tahun, Bangunan: 5% / 20 tahun)
 *
 * Running a period's depreciation posts a journal entry:
 *   Debit  Biaya Penyusutan ...      (expense)
 *     Kredit Akumulasi Penyusutan ... (contra-asset)
 */
class DepreciationService
{
    public function __construct(private readonly AccountingService $accounting)
    {
    }

    /**
     * Annual straight-line depreciation amount for an asset, capped so the
     * book value never drops below the salvage value.
     */
    public function annualAmount(FixedAsset $asset): float
    {
        $base = (float) $asset->acquisition_cost - (float) $asset->salvage_value;
        if ($base <= 0) {
            return 0.0;
        }

        $annual = (float) $asset->acquisition_cost * (float) $asset->depreciation_rate;

        // Don't depreciate below the remaining depreciable base.
        $remaining = $base - (float) $asset->accumulated_depreciation;

        return max(0.0, round(min($annual, $remaining), 4));
    }

    /**
     * Pro-rated depreciation for the acquisition year (by months in service).
     */
    public function amountForYear(FixedAsset $asset, int $year): float
    {
        $acquired = Carbon::parse($asset->acquisition_date);
        if ($year < $acquired->year) {
            return 0.0;
        }

        $annual = $this->annualAmount($asset);
        if ($annual <= 0) {
            return 0.0;
        }

        if ($year === $acquired->year) {
            // Months in service during acquisition year (inclusive of acquisition month).
            $monthsInService = 13 - $acquired->month;
            return round($annual * ($monthsInService / 12), 4);
        }

        return $annual;
    }

    /**
     * Run depreciation for one asset for a given year and post the journal entry.
     * Idempotent: returns the existing record if already run for that year.
     */
    public function runForAsset(FixedAsset $asset, int $year, ?int $userId = null): AssetDepreciation
    {
        $existing = AssetDepreciation::where('fixed_asset_id', $asset->id)
            ->where('year', $year)
            ->first();
        if ($existing) {
            return $existing;
        }

        $amount = $this->amountForYear($asset, $year);
        if ($amount <= 0) {
            throw new InvalidArgumentException(
                "Tidak ada penyusutan untuk aset '{$asset->name}' di tahun {$year} (mungkin sudah disusutkan penuh)."
            );
        }

        if (!$asset->depreciation_expense_account_id || !$asset->accumulated_depreciation_account_id) {
            throw new InvalidArgumentException(
                "Aset '{$asset->name}' belum punya akun beban/akumulasi penyusutan."
            );
        }

        return DB::transaction(function () use ($asset, $year, $amount, $userId) {
            $period = AccountingPeriod::where('organization_id', $asset->organization_id)
                ->where('year', $year)
                ->first();

            $entry = $this->accounting->createEntry([
                'organization_id' => $asset->organization_id,
                'date' => Carbon::create($year, 12, 31),
                'description' => "Penyusutan {$asset->name} tahun {$year}",
                'category' => 'penyusutan',
                'source' => 'depreciation',
                'created_by' => $userId,
                'posted_by' => $userId,
            ], [
                ['account_id' => $asset->depreciation_expense_account_id, 'debit' => $amount],
                ['account_id' => $asset->accumulated_depreciation_account_id, 'credit' => $amount],
            ]);

            $accumulatedAfter = (float) $asset->accumulated_depreciation + $amount;
            $bookValueAfter = (float) $asset->acquisition_cost - $accumulatedAfter;

            $record = AssetDepreciation::create([
                'fixed_asset_id' => $asset->id,
                'accounting_period_id' => $period?->id,
                'journal_entry_id' => $entry->id,
                'year' => $year,
                'amount' => $amount,
                'accumulated_after' => $accumulatedAfter,
                'book_value_after' => $bookValueAfter,
            ]);

            $asset->update([
                'accumulated_depreciation' => $accumulatedAfter,
                'book_value' => $bookValueAfter,
            ]);

            return $record;
        });
    }

    /**
     * Run depreciation for all active assets of an organization for a year.
     *
     * @return array{posted:int, skipped:int, total_amount:float}
     */
    public function runForOrganization(int $organizationId, int $year, ?int $userId = null): array
    {
        $assets = FixedAsset::where('organization_id', $organizationId)
            ->where('is_active', true)
            ->get();

        $posted = 0;
        $skipped = 0;
        $totalAmount = 0.0;

        foreach ($assets as $asset) {
            try {
                $record = $this->runForAsset($asset, $year, $userId);
                if ($record->wasRecentlyCreated) {
                    $posted++;
                    $totalAmount += (float) $record->amount;
                } else {
                    $skipped++;
                }
            } catch (InvalidArgumentException) {
                $skipped++;
            }
        }

        return [
            'posted' => $posted,
            'skipped' => $skipped,
            'total_amount' => round($totalAmount, 2),
        ];
    }
}

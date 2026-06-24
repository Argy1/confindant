<?php

namespace App\Services\Accounting;

use App\Models\RestrictedFund;
use App\Models\RestrictedFundMovement;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

/**
 * Manages Dana Titipan (restricted/earmarked funds) such as
 * "Dana Titipan Cabang" and "Dana Titipan Kegiatan Ilmiah".
 *
 * These are liabilities: the organization holds money on behalf of others.
 *
 *   Dana masuk (in):  Debit Kas              / Kredit Dana Titipan (liability)
 *   Dana keluar (out): Debit Dana Titipan     / Kredit Kas
 */
class RestrictedFundService
{
    public function __construct(private readonly AccountingService $accounting)
    {
    }

    /**
     * Record a movement (in/out) and post the journal entry, updating the
     * running fund balance.
     */
    public function recordMovement(
        RestrictedFund $fund,
        string $direction,
        float $amount,
        int $cashAccountId,
        string $date,
        ?string $description = null,
        ?int $userId = null
    ): RestrictedFundMovement {
        if (!in_array($direction, ['in', 'out'], true)) {
            throw new InvalidArgumentException('Direction harus in atau out.');
        }
        $amount = round($amount, 4);
        if ($amount <= 0) {
            throw new InvalidArgumentException('Jumlah harus lebih dari 0.');
        }
        if (!$fund->account_id) {
            throw new InvalidArgumentException('Dana titipan belum terhubung ke akun.');
        }
        if ($direction === 'out' && $amount > (float) $fund->balance + 0.0001) {
            throw new InvalidArgumentException('Saldo dana titipan tidak mencukupi.');
        }

        return DB::transaction(function () use ($fund, $direction, $amount, $cashAccountId, $date, $description, $userId) {
            $lines = $direction === 'in'
                ? [
                    ['account_id' => $cashAccountId, 'debit' => $amount],   // Kas masuk
                    ['account_id' => $fund->account_id, 'credit' => $amount], // Dana titipan naik
                ]
                : [
                    ['account_id' => $fund->account_id, 'debit' => $amount], // Dana titipan turun
                    ['account_id' => $cashAccountId, 'credit' => $amount],   // Kas keluar
                ];

            $entry = $this->accounting->createEntry([
                'organization_id' => $fund->organization_id,
                'date' => $date,
                'description' => $description
                    ?? (($direction === 'in' ? 'Penerimaan' : 'Penyaluran').' '.$fund->name),
                'category' => $fund->fund_type,
                'source' => 'manual',
                'created_by' => $userId,
                'posted_by' => $userId,
            ], $lines);

            $balanceAfter = $direction === 'in'
                ? (float) $fund->balance + $amount
                : (float) $fund->balance - $amount;

            $movement = RestrictedFundMovement::create([
                'restricted_fund_id' => $fund->id,
                'journal_entry_id' => $entry->id,
                'date' => $date,
                'direction' => $direction,
                'amount' => $amount,
                'balance_after' => $balanceAfter,
                'description' => $description,
            ]);

            $fund->update(['balance' => $balanceAfter]);

            return $movement;
        });
    }
}

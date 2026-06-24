<?php

namespace App\Services\Accounting;

use App\Models\Account;
use App\Models\ReceivablePayable;
use App\Models\Settlement;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

/**
 * Manages Piutang (receivables) and Hutang (payables) with auto-journaling.
 *
 * Receivable (e.g. Iuran Anggota belum dibayar):
 *   create:    Debit Piutang        / Kredit Pendapatan
 *   settle:    Debit Kas            / Kredit Piutang
 *
 * Payable (e.g. Hutang Iuran APSR ke pusat):
 *   create:    Debit Beban/Aset     / Kredit Hutang
 *   settle:    Debit Hutang         / Kredit Kas
 */
class ReceivablePayableService
{
    public function __construct(private readonly AccountingService $accounting)
    {
    }

    /**
     * Create a receivable or payable. Optionally posts the opening journal entry
     * when a counter account (revenue/expense) is supplied.
     *
     * @param array{
     *   organization_id:int, type:string, party_name:string, category?:string|null,
     *   account_id:int, original_amount:float, issued_date:string, due_date?:string|null,
     *   period_label?:string|null, description?:string|null,
     *   counter_account_id?:int|null, cash_account_id?:int|null, created_by?:int|null
     * } $data
     */
    public function create(array $data): ReceivablePayable
    {
        $type = $data['type'];
        if (!in_array($type, [ReceivablePayable::TYPE_RECEIVABLE, ReceivablePayable::TYPE_PAYABLE], true)) {
            throw new InvalidArgumentException('Tipe harus receivable atau payable.');
        }

        $amount = round((float) $data['original_amount'], 4);
        if ($amount <= 0) {
            throw new InvalidArgumentException('Jumlah harus lebih dari 0.');
        }

        return DB::transaction(function () use ($data, $type, $amount) {
            $record = ReceivablePayable::create([
                'organization_id' => $data['organization_id'],
                'type' => $type,
                'party_name' => $data['party_name'],
                'category' => $data['category'] ?? null,
                'account_id' => $data['account_id'],
                'description' => $data['description'] ?? null,
                'original_amount' => $amount,
                'settled_amount' => 0,
                'outstanding_amount' => $amount,
                'issued_date' => $data['issued_date'],
                'due_date' => $data['due_date'] ?? null,
                'status' => 'open',
                'period_label' => $data['period_label'] ?? null,
            ]);

            // Post opening journal if a counter account is provided.
            if (!empty($data['counter_account_id'])) {
                $controlAccount = $data['account_id'];
                $counter = $data['counter_account_id'];

                $lines = $type === ReceivablePayable::TYPE_RECEIVABLE
                    ? [
                        ['account_id' => $controlAccount, 'debit' => $amount],   // Piutang naik
                        ['account_id' => $counter, 'credit' => $amount],         // Pendapatan
                    ]
                    : [
                        ['account_id' => $counter, 'debit' => $amount],          // Beban/Aset
                        ['account_id' => $controlAccount, 'credit' => $amount],  // Hutang naik
                    ];

                $this->accounting->createEntry([
                    'organization_id' => $data['organization_id'],
                    'date' => $data['issued_date'],
                    'description' => ($type === ReceivablePayable::TYPE_RECEIVABLE ? 'Piutang' : 'Hutang')
                        .' '.$data['party_name'].(isset($data['category']) ? ' - '.$data['category'] : ''),
                    'category' => $data['category'] ?? null,
                    'source' => 'manual',
                    'created_by' => $data['created_by'] ?? null,
                    'posted_by' => $data['created_by'] ?? null,
                ], $lines);
            }

            return $record;
        });
    }

    /**
     * Record a (partial) settlement against a receivable/payable and post the
     * cash journal entry.
     */
    public function settle(
        ReceivablePayable $item,
        float $amount,
        int $cashAccountId,
        string $date,
        ?string $notes = null,
        ?int $userId = null
    ): Settlement {
        $amount = round($amount, 4);
        if ($amount <= 0) {
            throw new InvalidArgumentException('Jumlah pelunasan harus lebih dari 0.');
        }
        if ($amount > (float) $item->outstanding_amount + 0.0001) {
            throw new InvalidArgumentException('Jumlah pelunasan melebihi sisa outstanding.');
        }

        return DB::transaction(function () use ($item, $amount, $cashAccountId, $date, $notes, $userId) {
            $lines = $item->type === ReceivablePayable::TYPE_RECEIVABLE
                ? [
                    ['account_id' => $cashAccountId, 'debit' => $amount],     // Kas masuk
                    ['account_id' => $item->account_id, 'credit' => $amount], // Piutang turun
                ]
                : [
                    ['account_id' => $item->account_id, 'debit' => $amount],  // Hutang turun
                    ['account_id' => $cashAccountId, 'credit' => $amount],    // Kas keluar
                ];

            $entry = $this->accounting->createEntry([
                'organization_id' => $item->organization_id,
                'date' => $date,
                'description' => 'Pelunasan '.($item->type === ReceivablePayable::TYPE_RECEIVABLE ? 'piutang' : 'hutang')
                    .' '.$item->party_name,
                'category' => $item->category,
                'source' => 'manual',
                'created_by' => $userId,
                'posted_by' => $userId,
            ], $lines);

            $settlement = Settlement::create([
                'receivable_payable_id' => $item->id,
                'journal_entry_id' => $entry->id,
                'date' => $date,
                'amount' => $amount,
                'notes' => $notes,
            ]);

            $settled = (float) $item->settled_amount + $amount;
            $outstanding = max(0, (float) $item->original_amount - $settled);
            $item->update([
                'settled_amount' => $settled,
                'outstanding_amount' => $outstanding,
                'status' => $outstanding <= 0.0001 ? 'settled' : 'partial',
            ]);

            return $settlement;
        });
    }
}

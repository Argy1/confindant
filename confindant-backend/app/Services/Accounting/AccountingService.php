<?php

namespace App\Services\Accounting;

use App\Models\Account;
use App\Models\AccountingPeriod;
use App\Models\JournalEntry;
use App\Models\JournalLine;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

/**
 * Core double-entry bookkeeping engine.
 *
 * Every financial event is recorded as a balanced journal entry: the sum of
 * debits must equal the sum of credits. This service is the single gateway for
 * creating, posting, and voiding entries so that the ledger always stays
 * balanced and reports can be derived purely from journal_lines.
 */
class AccountingService
{
    /**
     * Smallest currency unit difference tolerated when comparing debit vs credit.
     * Amounts are stored with 4 decimals; rounding noise below 0.01 is acceptable.
     */
    private const BALANCE_TOLERANCE = 0.0001;

    /**
     * Create and post a balanced journal entry.
     *
     * @param array{
     *   organization_id:int,
     *   date:string|\DateTimeInterface,
     *   description:string,
     *   reference?:string|null,
     *   category?:string|null,
     *   classification?:string|null,
     *   source?:string,
     *   created_by?:int|null,
     *   posted_by?:int|null,
     *   status?:string
     * } $header
     * @param array<int, array{account_id:int, debit?:float, credit?:float, memo?:string|null}> $lines
     */
    public function createEntry(array $header, array $lines): JournalEntry
    {
        $organizationId = (int) ($header['organization_id'] ?? 0);
        if ($organizationId <= 0) {
            throw new InvalidArgumentException('organization_id wajib diisi untuk jurnal.');
        }

        $normalizedLines = $this->normalizeAndValidateLines($organizationId, $lines);
        $date = Carbon::parse($header['date'] ?? now())->startOfDay();
        $totalDebit = array_sum(array_column($normalizedLines, 'debit'));

        $period = $this->resolvePeriod($organizationId, $date);
        if ($period && !$period->isOpen()) {
            throw new InvalidArgumentException(
                "Periode {$period->year} sudah ditutup. Jurnal tidak dapat ditambahkan."
            );
        }

        return DB::transaction(function () use ($header, $normalizedLines, $organizationId, $date, $totalDebit, $period) {
            $status = $header['status'] ?? 'posted';

            $entry = JournalEntry::create([
                'organization_id' => $organizationId,
                'accounting_period_id' => $period?->id,
                'entry_number' => $this->nextEntryNumber($organizationId, $date),
                'date' => $date,
                'description' => (string) ($header['description'] ?? ''),
                'reference' => $header['reference'] ?? null,
                'category' => $header['category'] ?? null,
                'classification' => $header['classification'] ?? null,
                'status' => $status,
                'source' => $header['source'] ?? 'manual',
                'total_amount' => $totalDebit,
                'created_by' => $header['created_by'] ?? null,
                'posted_by' => $status === 'posted' ? ($header['posted_by'] ?? $header['created_by'] ?? null) : null,
                'posted_at' => $status === 'posted' ? now() : null,
            ]);

            foreach ($normalizedLines as $line) {
                JournalLine::create([
                    'journal_entry_id' => $entry->id,
                    'account_id' => $line['account_id'],
                    'organization_id' => $organizationId,
                    'date' => $date,
                    'debit' => $line['debit'],
                    'credit' => $line['credit'],
                    'memo' => $line['memo'],
                ]);
            }

            return $entry->load('lines.account');
        });
    }

    /**
     * Void an entry by reversing it (keeps an audit trail rather than deleting).
     */
    public function voidEntry(JournalEntry $entry, ?int $userId = null): JournalEntry
    {
        if ($entry->status === 'void') {
            return $entry;
        }

        $reversalLines = $entry->lines->map(fn (JournalLine $line) => [
            'account_id' => $line->account_id,
            'debit' => (float) $line->credit,
            'credit' => (float) $line->debit,
            'memo' => 'Pembalik untuk jurnal #'.$entry->id,
        ])->all();

        return DB::transaction(function () use ($entry, $reversalLines, $userId) {
            $this->createEntry([
                'organization_id' => $entry->organization_id,
                'date' => now(),
                'description' => 'VOID: '.$entry->description,
                'reference' => $entry->reference,
                'category' => $entry->category,
                'source' => 'void',
                'created_by' => $userId,
                'posted_by' => $userId,
            ], $reversalLines);

            $entry->update(['status' => 'void']);

            return $entry->fresh('lines');
        });
    }

    /**
     * Compute the balance of a single account up to (and including) $asOf.
     * Returns the signed balance respecting the account's normal balance.
     */
    public function accountBalance(Account $account, ?Carbon $asOf = null, ?Carbon $from = null): float
    {
        $query = JournalLine::query()
            ->where('account_id', $account->id)
            ->whereHas('journalEntry', fn ($q) => $q->where('status', 'posted'));

        if ($from) {
            $query->where('date', '>=', $from->copy()->startOfDay());
        }
        if ($asOf) {
            $query->where('date', '<=', $asOf->copy()->endOfDay());
        }

        $debitSum = (float) (clone $query)->sum('debit');
        $creditSum = (float) (clone $query)->sum('credit');

        $opening = $from ? 0.0 : (float) $account->opening_balance;

        return $opening + $account->signedBalance($debitSum, $creditSum);
    }

    /**
     * Validate lines: every line targets a real account belonging to the org,
     * has exactly one of debit/credit, and the entry is balanced.
     *
     * @return array<int, array{account_id:int, debit:float, credit:float, memo:string|null}>
     */
    private function normalizeAndValidateLines(int $organizationId, array $lines): array
    {
        if (count($lines) < 2) {
            throw new InvalidArgumentException('Jurnal harus punya minimal 2 baris (debit & kredit).');
        }

        $accountIds = array_values(array_unique(array_map(
            fn ($l) => (int) ($l['account_id'] ?? 0),
            $lines
        )));
        $accounts = Account::where('organization_id', $organizationId)
            ->whereIn('id', $accountIds)
            ->pluck('id')
            ->all();
        $validIds = array_flip($accounts);

        $normalized = [];
        $totalDebit = 0.0;
        $totalCredit = 0.0;

        foreach ($lines as $i => $line) {
            $accountId = (int) ($line['account_id'] ?? 0);
            if (!isset($validIds[$accountId])) {
                throw new InvalidArgumentException("Baris #{$i}: akun tidak valid atau bukan milik organisasi ini.");
            }

            $debit = round((float) ($line['debit'] ?? 0), 4);
            $credit = round((float) ($line['credit'] ?? 0), 4);

            if ($debit < 0 || $credit < 0) {
                throw new InvalidArgumentException("Baris #{$i}: nilai debit/kredit tidak boleh negatif.");
            }
            if ($debit > 0 && $credit > 0) {
                throw new InvalidArgumentException("Baris #{$i}: satu baris hanya boleh debit ATAU kredit, bukan keduanya.");
            }
            if ($debit === 0.0 && $credit === 0.0) {
                continue; // skip empty line
            }

            $normalized[] = [
                'account_id' => $accountId,
                'debit' => $debit,
                'credit' => $credit,
                'memo' => $line['memo'] ?? null,
            ];
            $totalDebit += $debit;
            $totalCredit += $credit;
        }

        if (count($normalized) < 2) {
            throw new InvalidArgumentException('Jurnal harus punya minimal 2 baris bernilai.');
        }

        if (abs($totalDebit - $totalCredit) > self::BALANCE_TOLERANCE) {
            throw new InvalidArgumentException(sprintf(
                'Jurnal tidak seimbang: total debit (%.2f) != total kredit (%.2f).',
                $totalDebit,
                $totalCredit
            ));
        }

        return $normalized;
    }

    private function resolvePeriod(int $organizationId, Carbon $date): ?AccountingPeriod
    {
        return AccountingPeriod::where('organization_id', $organizationId)
            ->where('year', $date->year)
            ->first();
    }

    private function nextEntryNumber(int $organizationId, Carbon $date): string
    {
        $year = $date->year;
        $count = JournalEntry::where('organization_id', $organizationId)
            ->whereYear('date', $year)
            ->count();

        return sprintf('JU-%d-%04d', $year, $count + 1);
    }
}

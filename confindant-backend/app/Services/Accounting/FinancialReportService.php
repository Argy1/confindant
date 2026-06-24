<?php

namespace App\Services\Accounting;

use App\Models\Account;
use App\Models\JournalLine;
use Carbon\Carbon;
use Illuminate\Support\Collection;

/**
 * Derives formal financial statements purely from the general ledger
 * (journal_lines of posted entries). Nothing is precomputed/stored, so the
 * reports are always consistent with the underlying journal.
 *
 * Produces:
 *  - Neraca (Balance Sheet): Aset = Kewajiban + Aset Bersih
 *  - Laporan Aktivitas (Statement of Activities / nonprofit income statement)
 *  - Buku Besar (General Ledger) per account
 *  - Jurnal Umum (General Journal) listing
 *  - Trial Balance (Neraca Saldo) untuk verifikasi keseimbangan
 */
class FinancialReportService
{
    /**
     * Balance sheet as of a given date.
     *
     * @return array<string, mixed>
     */
    public function balanceSheet(int $organizationId, Carbon $asOf): array
    {
        $accounts = $this->orgAccounts($organizationId);
        $balances = $this->balancesAsOf($organizationId, $asOf);

        // Net income (change in net assets) up to asOf flows into net assets.
        $changeInNetAssets = $this->changeInNetAssets($accounts, $balances);

        $assets = $this->groupSection($accounts, $balances, Account::TYPE_ASSET);
        $liabilities = $this->groupSection($accounts, $balances, Account::TYPE_LIABILITY);

        // Net assets = recorded net_asset accounts + current-year change.
        $netAssetAccounts = $this->groupSection($accounts, $balances, Account::TYPE_NET_ASSET);
        $netAssetsTotal = $netAssetAccounts['total'] + $changeInNetAssets;

        $totalAssets = $assets['total'];
        $totalLiabilities = $liabilities['total'];
        $totalLiabilitiesAndNetAssets = $totalLiabilities + $netAssetsTotal;

        return [
            'as_of' => $asOf->toDateString(),
            'assets' => $assets,
            'liabilities' => $liabilities,
            'net_assets' => [
                'accounts' => $netAssetAccounts['accounts'],
                'recorded_total' => $netAssetAccounts['total'],
                'change_in_net_assets' => round($changeInNetAssets, 2),
                'total' => round($netAssetsTotal, 2),
            ],
            'totals' => [
                'total_assets' => round($totalAssets, 2),
                'total_liabilities' => round($totalLiabilities, 2),
                'total_net_assets' => round($netAssetsTotal, 2),
                'total_liabilities_and_net_assets' => round($totalLiabilitiesAndNetAssets, 2),
            ],
            'is_balanced' => abs($totalAssets - $totalLiabilitiesAndNetAssets) < 0.01,
            'difference' => round($totalAssets - $totalLiabilitiesAndNetAssets, 2),
        ];
    }

    /**
     * Statement of Activities for a date range.
     *
     * @return array<string, mixed>
     */
    public function statementOfActivities(int $organizationId, Carbon $from, Carbon $to): array
    {
        $accounts = $this->orgAccounts($organizationId);
        $movements = $this->movementsBetween($organizationId, $from, $to);

        $revenue = $this->activitySection($accounts, $movements, Account::TYPE_REVENUE);
        $expense = $this->activitySection($accounts, $movements, Account::TYPE_EXPENSE);

        $totalRevenue = $revenue['total'];
        $totalExpense = $expense['total'];
        $change = $totalRevenue - $totalExpense;

        return [
            'period' => [
                'from' => $from->toDateString(),
                'to' => $to->toDateString(),
            ],
            'revenue' => $revenue,
            'expense' => $expense,
            'totals' => [
                'total_revenue' => round($totalRevenue, 2),
                'total_expense' => round($totalExpense, 2),
                'change_in_net_assets' => round($change, 2),
            ],
        ];
    }

    /**
     * General ledger detail for a single account.
     *
     * @return array<string, mixed>
     */
    public function generalLedger(Account $account, Carbon $from, Carbon $to): array
    {
        $openingDebit = (float) JournalLine::where('account_id', $account->id)
            ->whereHas('journalEntry', fn ($q) => $q->where('status', 'posted'))
            ->where('date', '<', $from->copy()->startOfDay())
            ->sum('debit');
        $openingCredit = (float) JournalLine::where('account_id', $account->id)
            ->whereHas('journalEntry', fn ($q) => $q->where('status', 'posted'))
            ->where('date', '<', $from->copy()->startOfDay())
            ->sum('credit');

        $opening = (float) $account->opening_balance
            + $account->signedBalance($openingDebit, $openingCredit);

        $lines = JournalLine::with('journalEntry')
            ->where('account_id', $account->id)
            ->whereHas('journalEntry', fn ($q) => $q->where('status', 'posted'))
            ->whereBetween('date', [$from->copy()->startOfDay(), $to->copy()->endOfDay()])
            ->orderBy('date')
            ->orderBy('id')
            ->get();

        $running = $opening;
        $rows = $lines->map(function (JournalLine $line) use (&$running, $account) {
            $delta = $account->normal_balance === 'debit'
                ? $line->debit - $line->credit
                : $line->credit - $line->debit;
            $running += $delta;

            return [
                'date' => $line->date->toDateString(),
                'entry_number' => $line->journalEntry->entry_number,
                'description' => $line->journalEntry->description,
                'debit' => round((float) $line->debit, 2),
                'credit' => round((float) $line->credit, 2),
                'balance' => round($running, 2),
            ];
        })->all();

        return [
            'account' => [
                'id' => $account->id,
                'code' => $account->code,
                'name' => $account->name,
                'type' => $account->type,
                'normal_balance' => $account->normal_balance,
            ],
            'opening_balance' => round($opening, 2),
            'closing_balance' => round($running, 2),
            'lines' => $rows,
        ];
    }

    /**
     * Trial balance — list every account with debit/credit totals. The grand
     * totals must match, proving the ledger is internally balanced.
     *
     * @return array<string, mixed>
     */
    public function trialBalance(int $organizationId, Carbon $asOf): array
    {
        $accounts = $this->orgAccounts($organizationId);
        $totals = $this->rawTotalsAsOf($organizationId, $asOf);

        $rows = [];
        $grandDebit = 0.0;
        $grandCredit = 0.0;

        foreach ($accounts as $account) {
            $debit = (float) ($totals[$account->id]['debit'] ?? 0);
            $credit = (float) ($totals[$account->id]['credit'] ?? 0);
            $opening = (float) $account->opening_balance;

            // Fold opening balance into the correct side.
            if ($account->normal_balance === 'debit') {
                $debit += max($opening, 0);
                $credit += max(-$opening, 0);
            } else {
                $credit += max($opening, 0);
                $debit += max(-$opening, 0);
            }

            $net = $debit - $credit;
            if (abs($net) < 0.005 && $debit === 0.0 && $credit === 0.0) {
                continue;
            }

            $rows[] = [
                'code' => $account->code,
                'name' => $account->name,
                'type' => $account->type,
                'debit' => $net > 0 ? round($net, 2) : 0.0,
                'credit' => $net < 0 ? round(-$net, 2) : 0.0,
            ];
            if ($net > 0) {
                $grandDebit += $net;
            } else {
                $grandCredit += -$net;
            }
        }

        return [
            'as_of' => $asOf->toDateString(),
            'rows' => $rows,
            'total_debit' => round($grandDebit, 2),
            'total_credit' => round($grandCredit, 2),
            'is_balanced' => abs($grandDebit - $grandCredit) < 0.01,
        ];
    }

    // ----------------------------------------------------------------------
    // Internal helpers
    // ----------------------------------------------------------------------

    private function orgAccounts(int $organizationId): Collection
    {
        return Account::where('organization_id', $organizationId)
            ->orderBy('sort_order')
            ->orderBy('code')
            ->get();
    }

    /**
     * Signed balances as of a date, keyed by account_id, respecting normal balance
     * and contra flags.
     *
     * @return array<int, float>
     */
    private function balancesAsOf(int $organizationId, Carbon $asOf): array
    {
        $raw = $this->rawTotalsAsOf($organizationId, $asOf);
        $accounts = $this->orgAccounts($organizationId)->keyBy('id');

        $result = [];
        foreach ($accounts as $id => $account) {
            $debit = (float) ($raw[$id]['debit'] ?? 0);
            $credit = (float) ($raw[$id]['credit'] ?? 0);
            $result[$id] = (float) $account->opening_balance
                + $account->signedBalance($debit, $credit);
        }

        return $result;
    }

    /**
     * Raw debit/credit sums per account up to $asOf (posted entries only).
     *
     * @return array<int, array{debit:float, credit:float}>
     */
    private function rawTotalsAsOf(int $organizationId, Carbon $asOf): array
    {
        $rows = JournalLine::query()
            ->selectRaw('account_id, SUM(debit) as debit_sum, SUM(credit) as credit_sum')
            ->where('organization_id', $organizationId)
            ->where('date', '<=', $asOf->copy()->endOfDay())
            ->whereHas('journalEntry', fn ($q) => $q->where('status', 'posted'))
            ->groupBy('account_id')
            ->get();

        $out = [];
        foreach ($rows as $row) {
            $out[(int) $row->account_id] = [
                'debit' => (float) $row->debit_sum,
                'credit' => (float) $row->credit_sum,
            ];
        }

        return $out;
    }

    /**
     * Net movement (revenue/expense) within a date range, keyed by account_id.
     *
     * @return array<int, float>
     */
    private function movementsBetween(int $organizationId, Carbon $from, Carbon $to): array
    {
        $rows = JournalLine::query()
            ->selectRaw('account_id, SUM(debit) as debit_sum, SUM(credit) as credit_sum')
            ->where('organization_id', $organizationId)
            ->whereBetween('date', [$from->copy()->startOfDay(), $to->copy()->endOfDay()])
            ->whereHas('journalEntry', fn ($q) => $q->where('status', 'posted'))
            ->groupBy('account_id')
            ->get();

        $accounts = $this->orgAccounts($organizationId)->keyBy('id');
        $out = [];
        foreach ($rows as $row) {
            $id = (int) $row->account_id;
            $account = $accounts->get($id);
            if (!$account) {
                continue;
            }
            $out[$id] = $account->signedBalance((float) $row->debit_sum, (float) $row->credit_sum);
        }

        return $out;
    }

    /**
     * Build a balance-sheet section (asset/liability/net_asset) grouped by subtype.
     *
     * @return array{groups:array<int,mixed>, accounts:array<int,mixed>, total:float}
     */
    private function groupSection(Collection $accounts, array $balances, string $type): array
    {
        $filtered = $accounts->where('type', $type);
        $rows = [];
        $total = 0.0;

        foreach ($filtered as $account) {
            $balance = (float) ($balances[$account->id] ?? 0);
            if (abs($balance) < 0.005) {
                continue;
            }
            $rows[] = [
                'code' => $account->code,
                'name' => $account->name,
                'subtype' => $account->subtype,
                'amount' => round($balance, 2),
            ];
            $total += $balance;
        }

        return [
            'accounts' => $rows,
            'groups' => $this->subtypeGroups($rows),
            'total' => round($total, 2),
        ];
    }

    /**
     * Build an activity section (revenue/expense) for the income statement.
     *
     * @return array{groups:array<int,mixed>, accounts:array<int,mixed>, total:float}
     */
    private function activitySection(Collection $accounts, array $movements, string $type): array
    {
        $filtered = $accounts->where('type', $type);
        $rows = [];
        $total = 0.0;

        foreach ($filtered as $account) {
            $amount = (float) ($movements[$account->id] ?? 0);
            if (abs($amount) < 0.005) {
                continue;
            }
            $rows[] = [
                'code' => $account->code,
                'name' => $account->name,
                'subtype' => $account->subtype,
                'amount' => round($amount, 2),
            ];
            $total += $amount;
        }

        return [
            'accounts' => $rows,
            'groups' => $this->subtypeGroups($rows),
            'total' => round($total, 2),
        ];
    }

    /**
     * @param array<int, array<string, mixed>> $rows
     * @return array<int, array<string, mixed>>
     */
    private function subtypeGroups(array $rows): array
    {
        $groups = [];
        foreach ($rows as $row) {
            $key = $row['subtype'] ?? 'lain';
            if (!isset($groups[$key])) {
                $groups[$key] = ['subtype' => $key, 'accounts' => [], 'subtotal' => 0.0];
            }
            $groups[$key]['accounts'][] = $row;
            $groups[$key]['subtotal'] = round($groups[$key]['subtotal'] + $row['amount'], 2);
        }

        return array_values($groups);
    }

    /**
     * Change in net assets = total revenue - total expense across all time up to asOf.
     * (For the balance sheet, this captures retained surplus not yet closed to
     * a net-asset account.)
     */
    private function changeInNetAssets(Collection $accounts, array $balances): float
    {
        $revenue = 0.0;
        $expense = 0.0;
        foreach ($accounts as $account) {
            $bal = (float) ($balances[$account->id] ?? 0);
            if ($account->type === Account::TYPE_REVENUE) {
                $revenue += $bal;
            } elseif ($account->type === Account::TYPE_EXPENSE) {
                $expense += $bal;
            }
        }

        return $revenue - $expense;
    }
}

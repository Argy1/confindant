"use client";

import * as React from "react";
import { useQuery } from "@tanstack/react-query";
import { CheckCircle2, AlertTriangle } from "lucide-react";
import { Skeleton } from "@/components/ui/skeleton";
import { accountingApi } from "@/lib/api/accounting";
import { useActiveOrg } from "@/lib/hooks/use-active-org";
import { useAccountsMap } from "@/lib/hooks/use-accounts-map";
import { YearSelect } from "@/components/org/year-select";
import { ReportSection } from "@/components/org/report-section";
import { LedgerDialog } from "@/components/org/ledger-dialog";
import { formatCurrency, formatDate } from "@/lib/utils";

export default function BalanceSheetPage() {
  const { org, orgId } = useActiveOrg();
  const [year, setYear] = React.useState(new Date().getFullYear());
  const asOf = `${year}-12-31`;
  const from = `${year}-01-01`;

  const { codeToId } = useAccountsMap(orgId);
  const [ledger, setLedger] = React.useState<{ id: string; name: string } | null>(
    null,
  );

  const { data, isLoading } = useQuery({
    queryKey: ["balance-sheet", orgId, asOf],
    queryFn: () => accountingApi.balanceSheet(orgId!, asOf),
    enabled: !!orgId,
  });

  const handleAccount = (code: string, name: string) => {
    const id = codeToId.get(code);
    if (id) setLedger({ id, name });
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
            Laporan Neraca
          </h1>
          <p className="text-sm text-muted-foreground">
            {org?.name} · Per {formatDate(asOf)}
          </p>
        </div>
        <YearSelect value={year} onChange={setYear} />
      </div>

      {isLoading || !data ? (
        <div className="grid gap-6 lg:grid-cols-2">
          <Skeleton className="h-96 rounded-xl" />
          <Skeleton className="h-96 rounded-xl" />
        </div>
      ) : (
        <>
          {/* Balance status */}
          <div
            className={`flex items-center gap-2 rounded-lg border px-4 py-2.5 text-sm ${
              data.is_balanced
                ? "border-emerald-200 bg-emerald-50 text-emerald-800"
                : "border-amber-200 bg-amber-50 text-amber-800"
            }`}
          >
            {data.is_balanced ? (
              <CheckCircle2 className="h-4 w-4" />
            ) : (
              <AlertTriangle className="h-4 w-4" />
            )}
            {data.is_balanced
              ? "Neraca seimbang."
              : `Neraca tidak seimbang. Selisih ${formatCurrency(data.difference)}.`}
          </div>

          <div className="grid items-start gap-6 lg:grid-cols-2">
            {/* ASET */}
            <ReportSection
              title="Aset"
              groups={data.assets.groups}
              total={data.totals.total_assets}
              totalLabel="Total Aset"
              onAccountClick={handleAccount}
              accent="blue"
            />

            {/* KEWAJIBAN + ASET BERSIH */}
            <div className="space-y-6">
              <ReportSection
                title="Kewajiban"
                groups={data.liabilities.groups}
                total={data.totals.total_liabilities}
                totalLabel="Total Kewajiban"
                onAccountClick={handleAccount}
                accent="rose"
              />

              {/* Aset Bersih */}
              <div className="overflow-hidden rounded-xl border border-border bg-card">
                <div className="border-b border-border bg-muted/40 px-4 py-2.5">
                  <h3 className="font-display text-sm font-bold uppercase tracking-wide">
                    Aset Bersih
                  </h3>
                </div>
                <div className="divide-y divide-border/60">
                  {data.net_assets.accounts.map((acc) => (
                    <div
                      key={acc.code}
                      className="flex items-center justify-between px-4 py-2.5 text-sm"
                    >
                      <span className="flex items-center gap-2">
                        <span className="font-mono text-xs text-muted-foreground">
                          {acc.code}
                        </span>
                        {acc.name}
                      </span>
                      <span className="tabular-nums">
                        {formatCurrency(acc.amount)}
                      </span>
                    </div>
                  ))}
                  <div className="flex items-center justify-between px-4 py-2.5 text-sm">
                    <span>Kenaikan (Penurunan) Aset Bersih Tahun Berjalan</span>
                    <span className="tabular-nums">
                      {formatCurrency(data.net_assets.change_in_net_assets)}
                    </span>
                  </div>
                </div>
                <div className="flex items-center justify-between border-t-2 border-border px-4 py-3 text-blue-800">
                  <span className="text-sm font-bold uppercase">
                    Total Aset Bersih
                  </span>
                  <span className="font-display text-base font-bold tabular-nums">
                    {formatCurrency(data.totals.total_net_assets)}
                  </span>
                </div>
              </div>

              {/* Grand total check */}
              <div className="flex items-center justify-between rounded-xl bg-blue-900 px-4 py-3 text-white">
                <span className="text-sm font-bold uppercase">
                  Total Kewajiban & Aset Bersih
                </span>
                <span className="font-display text-base font-bold tabular-nums">
                  {formatCurrency(
                    data.totals.total_liabilities_and_net_assets,
                  )}
                </span>
              </div>
            </div>
          </div>
        </>
      )}

      {orgId && (
        <LedgerDialog
          orgId={orgId}
          accountId={ledger?.id ?? null}
          accountName={ledger?.name}
          from={from}
          to={asOf}
          open={!!ledger}
          onOpenChange={(o) => !o && setLedger(null)}
        />
      )}
    </div>
  );
}

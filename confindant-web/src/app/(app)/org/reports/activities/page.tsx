"use client";

import * as React from "react";
import { useQuery } from "@tanstack/react-query";
import { FileDown, Loader2 } from "lucide-react";
import { Skeleton } from "@/components/ui/skeleton";
import { Button } from "@/components/ui/button";
import { accountingApi } from "@/lib/api/accounting";
import { useActiveOrg } from "@/lib/hooks/use-active-org";
import { useAccountsMap } from "@/lib/hooks/use-accounts-map";
import { YearSelect } from "@/components/org/year-select";
import { ReportSection } from "@/components/org/report-section";
import { LedgerDialog } from "@/components/org/ledger-dialog";
import { formatCurrency } from "@/lib/utils";
import { toast } from "sonner";
import { getApiErrorMessage } from "@/lib/api/client";

export default function ActivitiesPage() {
  const { org, orgId } = useActiveOrg();
  const [year, setYear] = React.useState(new Date().getFullYear());
  const from = `${year}-01-01`;
  const to = `${year}-12-31`;
  const [downloading, setDownloading] = React.useState(false);

  const { codeToId } = useAccountsMap(orgId);
  const [ledger, setLedger] = React.useState<{ id: string; name: string } | null>(
    null,
  );

  async function handleDownloadPdf() {
    if (!orgId) return;
    setDownloading(true);
    try {
      await accountingApi.downloadReportPdf("activities", orgId, { year });
    } catch (err) {
      toast.error(getApiErrorMessage(err, "Gagal mengunduh PDF"));
    } finally {
      setDownloading(false);
    }
  }

  const { data, isLoading } = useQuery({
    queryKey: ["activities", orgId, year],
    queryFn: () => accountingApi.statementOfActivities(orgId!, { year }),
    enabled: !!orgId,
  });

  const handleAccount = (code: string, name: string) => {
    const id = codeToId.get(code);
    if (id) setLedger({ id, name });
  };

  const change = data?.totals.change_in_net_assets ?? 0;

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
            Laporan Aktivitas
          </h1>
          <p className="text-sm text-muted-foreground">
            {org?.name} · Periode {year}
          </p>
        </div>
        <div className="flex items-center gap-2">
          <YearSelect value={year} onChange={setYear} />
          <Button
            variant="outline"
            size="sm"
            onClick={handleDownloadPdf}
            disabled={downloading}
          >
            {downloading ? (
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
            ) : (
              <FileDown className="mr-2 h-4 w-4" />
            )}
            PDF
          </Button>
        </div>
      </div>

      {isLoading || !data ? (
        <div className="space-y-6">
          <Skeleton className="h-72 rounded-xl" />
          <Skeleton className="h-72 rounded-xl" />
        </div>
      ) : (
        <div className="mx-auto max-w-3xl space-y-6">
          <ReportSection
            title="Penerimaan / Pendapatan"
            groups={data.revenue.groups}
            total={data.totals.total_revenue}
            totalLabel="Total Penerimaan"
            onAccountClick={handleAccount}
            accent="emerald"
          />

          <ReportSection
            title="Beban"
            groups={data.expense.groups}
            total={data.totals.total_expense}
            totalLabel="Total Beban"
            onAccountClick={handleAccount}
            accent="rose"
          />

          {/* Net result */}
          <div
            className={`flex items-center justify-between rounded-xl px-5 py-4 text-white ${
              change >= 0 ? "bg-blue-900" : "bg-rose-700"
            }`}
          >
            <span className="text-sm font-bold uppercase">
              Kenaikan (Penurunan) Aset Bersih
            </span>
            <span className="font-display text-lg font-bold tabular-nums">
              {formatCurrency(change)}
            </span>
          </div>
        </div>
      )}

      {orgId && (
        <LedgerDialog
          orgId={orgId}
          accountId={ledger?.id ?? null}
          accountName={ledger?.name}
          from={from}
          to={to}
          open={!!ledger}
          onOpenChange={(o) => !o && setLedger(null)}
        />
      )}
    </div>
  );
}

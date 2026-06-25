"use client";

import * as React from "react";
import { useQuery } from "@tanstack/react-query";
import { CheckCircle2, AlertTriangle, FileDown, Loader2 } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { Button } from "@/components/ui/button";
import { accountingApi } from "@/lib/api/accounting";
import { useActiveOrg } from "@/lib/hooks/use-active-org";
import { YearSelect } from "@/components/org/year-select";
import { formatCurrency, formatDate } from "@/lib/utils";
import { toast } from "sonner";
import { getApiErrorMessage } from "@/lib/api/client";

export default function TrialBalancePage() {
  const { org, orgId } = useActiveOrg();
  const [year, setYear] = React.useState(new Date().getFullYear());
  const asOf = `${year}-12-31`;
  const [downloading, setDownloading] = React.useState(false);

  async function handleDownloadPdf() {
    if (!orgId) return;
    setDownloading(true);
    try {
      await accountingApi.downloadReportPdf("trial-balance", orgId, { as_of: asOf });
    } catch (err) {
      toast.error(getApiErrorMessage(err, "Gagal mengunduh PDF"));
    } finally {
      setDownloading(false);
    }
  }

  const { data, isLoading } = useQuery({
    queryKey: ["trial-balance", orgId, asOf],
    queryFn: () => accountingApi.trialBalance(orgId!, asOf),
    enabled: !!orgId,
  });

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
            Neraca Saldo
          </h1>
          <p className="text-sm text-muted-foreground">
            {org?.name} · Per {formatDate(asOf)}
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
        <Skeleton className="h-96 rounded-xl" />
      ) : (
        <>
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
              ? "Seimbang — total debit = total kredit."
              : "Tidak seimbang — periksa jurnal."}
          </div>

          <Card>
            <CardContent className="p-0">
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-border bg-muted/40 text-left text-xs uppercase tracking-wide text-muted-foreground">
                      <th className="px-4 py-3 font-semibold">Kode</th>
                      <th className="px-4 py-3 font-semibold">Nama Akun</th>
                      <th className="px-4 py-3 text-right font-semibold">Debit</th>
                      <th className="px-4 py-3 text-right font-semibold">Kredit</th>
                    </tr>
                  </thead>
                  <tbody>
                    {data.rows.map((row) => (
                      <tr
                        key={row.code}
                        className="border-b border-border/50 last:border-0 hover:bg-accent/30"
                      >
                        <td className="px-4 py-2.5 font-mono text-xs text-muted-foreground">
                          {row.code}
                        </td>
                        <td className="px-4 py-2.5">{row.name}</td>
                        <td className="px-4 py-2.5 text-right tabular-nums">
                          {row.debit > 0 ? formatCurrency(row.debit) : "-"}
                        </td>
                        <td className="px-4 py-2.5 text-right tabular-nums">
                          {row.credit > 0 ? formatCurrency(row.credit) : "-"}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                  <tfoot>
                    <tr className="border-t-2 border-border bg-muted/30 font-bold">
                      <td colSpan={2} className="px-4 py-3 text-right uppercase">
                        Total
                      </td>
                      <td className="px-4 py-3 text-right tabular-nums">
                        {formatCurrency(data.total_debit)}
                      </td>
                      <td className="px-4 py-3 text-right tabular-nums">
                        {formatCurrency(data.total_credit)}
                      </td>
                    </tr>
                  </tfoot>
                </table>
              </div>
            </CardContent>
          </Card>
        </>
      )}
    </div>
  );
}

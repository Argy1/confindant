"use client";

import { useQuery } from "@tanstack/react-query";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Skeleton } from "@/components/ui/skeleton";
import { accountingApi } from "@/lib/api/accounting";
import { formatCurrency, formatDate } from "@/lib/utils";

/**
 * Drill-down dialog showing an account's general ledger for the period.
 * Opened by clicking an account row in a report.
 */
export function LedgerDialog({
  orgId,
  accountId,
  accountName,
  from,
  to,
  open,
  onOpenChange,
}: {
  orgId: string;
  accountId: string | null;
  accountName?: string;
  from: string;
  to: string;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}) {
  const { data, isLoading } = useQuery({
    queryKey: ["ledger", orgId, accountId, from, to],
    queryFn: () =>
      accountingApi.generalLedger(orgId, accountId!, {
        from_date: from,
        to_date: to,
      }),
    enabled: open && !!accountId,
  });

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-3xl">
        <DialogHeader>
          <DialogTitle>
            Buku Besar — {data?.account.name ?? accountName ?? "Akun"}
          </DialogTitle>
        </DialogHeader>

        {isLoading ? (
          <div className="space-y-2">
            {Array.from({ length: 5 }).map((_, i) => (
              <Skeleton key={i} className="h-9 rounded" />
            ))}
          </div>
        ) : !data ? (
          <p className="py-8 text-center text-sm text-muted-foreground">
            Tidak ada data
          </p>
        ) : (
          <div className="max-h-[60vh] overflow-auto">
            <div className="mb-3 flex items-center justify-between rounded-lg bg-muted/50 px-3 py-2 text-sm">
              <span className="text-muted-foreground">Saldo Awal</span>
              <span className="font-semibold tabular-nums">
                {formatCurrency(data.opening_balance)}
              </span>
            </div>
            <table className="w-full text-sm">
              <thead className="sticky top-0 bg-card">
                <tr className="border-b border-border text-left text-xs text-muted-foreground">
                  <th className="py-2 pr-2 font-medium">Tanggal</th>
                  <th className="py-2 pr-2 font-medium">Uraian</th>
                  <th className="py-2 pr-2 text-right font-medium">Debit</th>
                  <th className="py-2 pr-2 text-right font-medium">Kredit</th>
                  <th className="py-2 text-right font-medium">Saldo</th>
                </tr>
              </thead>
              <tbody>
                {data.lines.length === 0 ? (
                  <tr>
                    <td
                      colSpan={5}
                      className="py-6 text-center text-muted-foreground"
                    >
                      Tidak ada transaksi pada periode ini
                    </td>
                  </tr>
                ) : (
                  data.lines.map((line, i) => (
                    <tr
                      key={i}
                      className="border-b border-border/50 last:border-0"
                    >
                      <td className="whitespace-nowrap py-2 pr-2 text-xs">
                        {formatDate(line.date)}
                      </td>
                      <td className="py-2 pr-2">
                        <span className="line-clamp-1">{line.description}</span>
                        {line.entry_number && (
                          <span className="font-mono text-[10px] text-muted-foreground">
                            {line.entry_number}
                          </span>
                        )}
                      </td>
                      <td className="py-2 pr-2 text-right tabular-nums">
                        {line.debit > 0 ? formatCurrency(line.debit) : "-"}
                      </td>
                      <td className="py-2 pr-2 text-right tabular-nums">
                        {line.credit > 0 ? formatCurrency(line.credit) : "-"}
                      </td>
                      <td className="py-2 text-right font-medium tabular-nums">
                        {formatCurrency(line.balance)}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
              <tfoot>
                <tr className="border-t-2 border-border font-bold">
                  <td colSpan={4} className="py-2.5 pr-2 text-right uppercase">
                    Saldo Akhir
                  </td>
                  <td className="py-2.5 text-right tabular-nums">
                    {formatCurrency(data.closing_balance)}
                  </td>
                </tr>
              </tfoot>
            </table>
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}

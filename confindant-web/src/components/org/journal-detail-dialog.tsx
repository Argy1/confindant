"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Ban } from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { accountingApi } from "@/lib/api/accounting";
import { getApiErrorMessage } from "@/lib/api/client";
import { formatCurrency, formatDate } from "@/lib/utils";

export function JournalDetailDialog({
  orgId,
  entryId,
  canWrite,
  open,
  onOpenChange,
}: {
  orgId: string;
  entryId: string | null;
  canWrite: boolean;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}) {
  const qc = useQueryClient();

  const { data, isLoading } = useQuery({
    queryKey: ["journal-detail", orgId, entryId],
    queryFn: () => accountingApi.journalShow(orgId, entryId!),
    enabled: open && !!entryId,
  });

  const voidMut = useMutation({
    mutationFn: () => accountingApi.journalVoid(orgId, entryId!),
    onSuccess: () => {
      toast.success("Jurnal dibatalkan (dibuat pembalik)");
      qc.invalidateQueries({ queryKey: ["journal", orgId] });
      qc.invalidateQueries({ queryKey: ["journal-detail", orgId, entryId] });
      qc.invalidateQueries({ queryKey: ["org-dashboard", orgId] });
      onOpenChange(false);
    },
    onError: (err) => toast.error(getApiErrorMessage(err)),
  });

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-lg">
        <DialogHeader>
          <DialogTitle>Detail Jurnal</DialogTitle>
        </DialogHeader>

        {isLoading || !data ? (
          <div className="space-y-2">
            {Array.from({ length: 4 }).map((_, i) => (
              <Skeleton key={i} className="h-9 rounded" />
            ))}
          </div>
        ) : (
          <div className="space-y-4">
            <div className="flex items-start justify-between gap-2">
              <div>
                <p className="font-semibold">{data.description}</p>
                <p className="text-xs text-muted-foreground">
                  {formatDate(data.date)} ·{" "}
                  <span className="font-mono">{data.entry_number}</span>
                </p>
              </div>
              <Badge
                variant={
                  data.status === "posted"
                    ? "success"
                    : data.status === "void"
                    ? "destructive"
                    : "info"
                }
              >
                {data.status === "posted"
                  ? "Diposting"
                  : data.status === "void"
                  ? "Dibatalkan"
                  : "Draft"}
              </Badge>
            </div>

            {data.reference && (
              <p className="text-sm text-muted-foreground">
                No. Bukti: {data.reference}
              </p>
            )}

            {/* Lines */}
            <div className="overflow-hidden rounded-lg border border-border">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border bg-muted/40 text-left text-xs text-muted-foreground">
                    <th className="px-3 py-2 font-medium">Akun</th>
                    <th className="px-3 py-2 text-right font-medium">Debit</th>
                    <th className="px-3 py-2 text-right font-medium">Kredit</th>
                  </tr>
                </thead>
                <tbody>
                  {data.lines.map((line) => (
                    <tr
                      key={line.id}
                      className="border-b border-border/50 last:border-0"
                    >
                      <td className="px-3 py-2">
                        <span className="font-mono text-xs text-muted-foreground">
                          {line.account?.code}
                        </span>{" "}
                        {line.account?.name}
                      </td>
                      <td className="px-3 py-2 text-right tabular-nums">
                        {line.debit > 0 ? formatCurrency(line.debit) : "-"}
                      </td>
                      <td className="px-3 py-2 text-right tabular-nums">
                        {line.credit > 0 ? formatCurrency(line.credit) : "-"}
                      </td>
                    </tr>
                  ))}
                </tbody>
                <tfoot>
                  <tr className="border-t border-border bg-muted/30 font-semibold">
                    <td className="px-3 py-2 text-right">Total</td>
                    <td className="px-3 py-2 text-right tabular-nums">
                      {formatCurrency(data.total_amount)}
                    </td>
                    <td className="px-3 py-2 text-right tabular-nums">
                      {formatCurrency(data.total_amount)}
                    </td>
                  </tr>
                </tfoot>
              </table>
            </div>

            {canWrite && data.status === "posted" && (
              <div className="flex justify-end">
                <Button
                  variant="outline"
                  className="text-destructive hover:bg-destructive/10 hover:text-destructive"
                  disabled={voidMut.isPending}
                  onClick={() => voidMut.mutate()}
                >
                  <Ban className="h-4 w-4" />
                  {voidMut.isPending ? "Membatalkan..." : "Batalkan Jurnal"}
                </Button>
              </div>
            )}
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}

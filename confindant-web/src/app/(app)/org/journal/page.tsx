"use client";

import * as React from "react";
import { useQuery } from "@tanstack/react-query";
import { Plus, Search } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { accountingApi } from "@/lib/api/accounting";
import { useActiveOrg } from "@/lib/hooks/use-active-org";
import { JournalFormDialog } from "@/components/org/journal-form-dialog";
import { JournalDetailDialog } from "@/components/org/journal-detail-dialog";
import { formatCurrency, formatDate } from "@/lib/utils";

export default function JournalPage() {
  const { org, orgId, canWrite } = useActiveOrg();
  const [formOpen, setFormOpen] = React.useState(false);
  const [detailId, setDetailId] = React.useState<string | null>(null);
  const [q, setQ] = React.useState("");

  const { data, isLoading } = useQuery({
    queryKey: ["journal", orgId],
    queryFn: () => accountingApi.journalList(orgId!, { per_page: 100 }),
    enabled: !!orgId,
  });

  const entries = data?.entries ?? [];
  const filtered = q.trim()
    ? entries.filter(
        (e) =>
          e.description.toLowerCase().includes(q.toLowerCase()) ||
          (e.entry_number ?? "").toLowerCase().includes(q.toLowerCase()),
      )
    : entries;

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
            Jurnal Umum
          </h1>
          <p className="text-sm text-muted-foreground">
            {org?.name} · {entries.length} jurnal
          </p>
        </div>
        {canWrite && (
          <Button variant="gradient" onClick={() => setFormOpen(true)}>
            <Plus className="h-4 w-4" /> Catat Transaksi
          </Button>
        )}
      </div>

      {/* Search */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <Input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Cari uraian atau nomor jurnal..."
          className="pl-9"
        />
      </div>

      {isLoading ? (
        <div className="space-y-2">
          {Array.from({ length: 6 }).map((_, i) => (
            <Skeleton key={i} className="h-16 rounded-xl" />
          ))}
        </div>
      ) : filtered.length === 0 ? (
        <Card>
          <CardContent className="grid place-items-center gap-3 py-14 text-center">
            <p className="font-semibold">Belum ada jurnal</p>
            <p className="max-w-xs text-sm text-muted-foreground">
              {q
                ? "Tidak ada jurnal yang cocok dengan pencarian."
                : "Mulai catat transaksi pertama organisasi."}
            </p>
            {canWrite && !q && (
              <Button variant="gradient" onClick={() => setFormOpen(true)}>
                <Plus className="h-4 w-4" /> Catat Transaksi
              </Button>
            )}
          </CardContent>
        </Card>
      ) : (
        <Card>
          <CardContent className="divide-y divide-border p-0">
            {filtered.map((e) => {
              const isVoid = e.status === "void";
              return (
                <button
                  key={e.id}
                  onClick={() => setDetailId(e.id)}
                  className="flex w-full items-center gap-3 p-4 text-left transition-colors hover:bg-accent/40"
                >
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2">
                      <p
                        className={`truncate font-medium ${
                          isVoid ? "text-muted-foreground line-through" : ""
                        }`}
                      >
                        {e.description}
                      </p>
                      {isVoid && (
                        <Badge variant="destructive" className="shrink-0">
                          Void
                        </Badge>
                      )}
                    </div>
                    <p className="truncate text-xs text-muted-foreground">
                      {formatDate(e.date)} ·{" "}
                      <span className="font-mono">{e.entry_number}</span>
                      {e.category ? ` · ${e.category}` : ""}
                    </p>
                  </div>
                  <p className="shrink-0 text-sm font-semibold tabular-nums">
                    {formatCurrency(e.total_amount)}
                  </p>
                </button>
              );
            })}
          </CardContent>
        </Card>
      )}

      {orgId && (
        <>
          <JournalFormDialog
            orgId={orgId}
            open={formOpen}
            onOpenChange={setFormOpen}
          />
          <JournalDetailDialog
            orgId={orgId}
            entryId={detailId}
            canWrite={canWrite}
            open={!!detailId}
            onOpenChange={(o) => !o && setDetailId(null)}
          />
        </>
      )}
    </div>
  );
}

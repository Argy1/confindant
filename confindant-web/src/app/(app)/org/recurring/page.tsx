"use client";

import * as React from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Play, Plus, Repeat, Trash2 } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { AccountSelect } from "@/components/org/account-select";
import { accountingApi } from "@/lib/api/accounting";
import { getApiErrorMessage } from "@/lib/api/client";
import { formatCurrency, formatDate } from "@/lib/utils";
import { useActiveOrg } from "@/lib/hooks/use-active-org";
import type { RecurringOrgEntry } from "@/lib/accounting-types";

const FREQ_LABEL = { daily: "Hari", weekly: "Minggu", monthly: "Bulan" } as const;

export default function OrgRecurringPage() {
  const { orgId, canWrite } = useActiveOrg();
  const qc = useQueryClient();
  const [open, setOpen] = React.useState(false);
  const [editing, setEditing] = React.useState<RecurringOrgEntry | null>(null);

  const { data, isLoading } = useQuery({
    queryKey: ["org-recurring", orgId],
    queryFn: () => accountingApi.recurringList(orgId!),
    enabled: !!orgId,
  });

  const runEntry = useMutation({
    mutationFn: (id: number) => accountingApi.recurringRun(orgId!, id),
    onSuccess: (res) => {
      toast.success("Jurnal recurring dibuat");
      qc.invalidateQueries({ queryKey: ["org-recurring", orgId] });
      qc.invalidateQueries({ queryKey: ["journal", orgId] });
      qc.invalidateQueries({ queryKey: ["org-dashboard", orgId] });
    },
    onError: (err) => toast.error(getApiErrorMessage(err)),
  });

  const items = data ?? [];
  const due = items.filter(
    (r) => r.active && r.next_run_at && new Date(r.next_run_at) <= new Date(),
  );

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
            Jurnal Berulang
          </h1>
          <p className="text-sm text-muted-foreground">
            Otomatisasi pencatatan jurnal rutin — gaji, sewa kantor, iuran.
          </p>
        </div>
        {canWrite && (
          <Button
            variant="gradient"
            onClick={() => {
              setEditing(null);
              setOpen(true);
            }}
          >
            <Plus className="h-4 w-4" /> Jurnal Berulang Baru
          </Button>
        )}
      </div>

      {due.length > 0 && (
        <div className="rounded-xl border border-amber-200 bg-amber-50 p-4 dark:border-amber-800 dark:bg-amber-950/30">
          <p className="text-sm font-semibold text-amber-800 dark:text-amber-300">
            {due.length} jurnal jatuh tempo hari ini
          </p>
          <p className="mt-0.5 text-xs text-amber-700 dark:text-amber-400">
            Klik tombol ▶ di samping entri untuk menjalankan.
          </p>
        </div>
      )}

      {isLoading ? (
        <div className="space-y-2">
          {Array.from({ length: 3 }).map((_, i) => (
            <Skeleton key={i} className="h-20 rounded-xl" />
          ))}
        </div>
      ) : items.length === 0 ? (
        <Card>
          <CardContent className="grid place-items-center gap-3 py-16 text-center">
            <div className="grid h-14 w-14 place-items-center rounded-full bg-info-bg text-blue-900">
              <Repeat className="h-6 w-6" />
            </div>
            <p className="font-semibold">Belum ada jurnal berulang</p>
            <p className="max-w-xs text-sm text-muted-foreground">
              Buat jadwal pencatatan otomatis untuk transaksi rutin organisasi.
            </p>
          </CardContent>
        </Card>
      ) : (
        <Card>
          <CardContent className="divide-y divide-border p-0">
            {items.map((r) => {
              const isDue = r.active && r.next_run_at && new Date(r.next_run_at) <= new Date();
              return (
                <div key={r.id} className="flex items-center gap-3 p-4">
                  <div
                    className={`grid h-10 w-10 shrink-0 place-items-center rounded-lg ${
                      r.active
                        ? "bg-blue-500/10 text-blue-600"
                        : "bg-muted text-muted-foreground"
                    }`}
                  >
                    <Repeat className="h-4 w-4" />
                  </div>
                  <button
                    className="min-w-0 flex-1 text-left"
                    onClick={() => {
                      setEditing(r);
                      setOpen(true);
                    }}
                  >
                    <div className="flex flex-wrap items-center gap-2">
                      <p className="truncate font-medium">{r.description}</p>
                      <Badge variant={r.active ? "success" : "secondary"}>
                        {r.active ? "Aktif" : "Pause"}
                      </Badge>
                      {isDue && (
                        <Badge variant="warning">Jatuh Tempo</Badge>
                      )}
                    </div>
                    <p className="mt-0.5 text-xs text-muted-foreground">
                      Setiap {r.interval > 1 ? `${r.interval} ` : ""}
                      {FREQ_LABEL[r.frequency]} ·{" "}
                      {r.next_run_at ? `Berikutnya: ${formatDate(r.next_run_at)}` : "—"} ·{" "}
                      {r.total_runs}× dijalankan
                    </p>
                    <p className="mt-0.5 text-xs text-muted-foreground">
                      D: {r.debit_account?.name ?? r.debit_account_id} /
                      K: {r.credit_account?.name ?? r.credit_account_id}
                    </p>
                  </button>
                  <p className="shrink-0 font-semibold">{formatCurrency(r.amount)}</p>
                  {canWrite && r.active && (
                    <Button
                      size="icon"
                      variant="ghost"
                      title="Jalankan sekarang"
                      loading={runEntry.isPending && runEntry.variables === r.id}
                      onClick={() => runEntry.mutate(r.id)}
                    >
                      <Play className="h-4 w-4 text-emerald-600" />
                    </Button>
                  )}
                </div>
              );
            })}
          </CardContent>
        </Card>
      )}

      <RecurringDialog
        open={open}
        onOpenChange={setOpen}
        orgId={orgId ?? ""}
        initial={editing}
        canWrite={canWrite}
        onDelete={async () => {
          if (!editing) return;
          if (!confirm("Hapus recurring ini?")) return;
          try {
            await accountingApi.recurringDelete(orgId!, editing.id);
            toast.success("Recurring dihapus");
            qc.invalidateQueries({ queryKey: ["org-recurring", orgId] });
            setOpen(false);
          } catch (err) {
            toast.error(getApiErrorMessage(err));
          }
        }}
      />
    </div>
  );
}

function RecurringDialog({
  open,
  onOpenChange,
  orgId,
  initial,
  canWrite,
  onDelete,
}: {
  open: boolean;
  onOpenChange: (o: boolean) => void;
  orgId: string;
  initial: RecurringOrgEntry | null;
  canWrite: boolean;
  onDelete: () => void;
}) {
  const isEdit = !!initial;
  const qc = useQueryClient();
  const today = new Date().toISOString().slice(0, 10);

  const { data: accounts } = useQuery({
    queryKey: ["org-accounts", orgId],
    queryFn: () => accountingApi.accounts(orgId),
    enabled: !!orgId,
  });

  const allAccounts = accounts ?? [];

  const [description, setDescription] = React.useState("");
  const [category, setCategory] = React.useState("");
  const [amount, setAmount] = React.useState("");
  const [frequency, setFrequency] = React.useState<"daily" | "weekly" | "monthly">("monthly");
  const [interval, setInterval] = React.useState("1");
  const [startDate, setStartDate] = React.useState(today);
  const [endDate, setEndDate] = React.useState("");
  const [active, setActive] = React.useState(true);
  const [debitId, setDebitId] = React.useState("");
  const [creditId, setCreditId] = React.useState("");

  React.useEffect(() => {
    if (open) {
      if (initial) {
        setDescription(initial.description);
        setCategory(initial.category ?? "");
        setAmount(String(initial.amount));
        setFrequency(initial.frequency);
        setInterval(String(initial.interval));
        setStartDate(initial.start_date.slice(0, 10));
        setEndDate(initial.end_date?.slice(0, 10) ?? "");
        setActive(initial.active);
        setDebitId(String(initial.debit_account_id));
        setCreditId(String(initial.credit_account_id));
      } else {
        setDescription("");
        setCategory("");
        setAmount("");
        setFrequency("monthly");
        setInterval("1");
        setStartDate(today);
        setEndDate("");
        setActive(true);
        setDebitId("");
        setCreditId("");
      }
    }
  }, [open, initial?.id]);

  const save = useMutation({
    mutationFn: () => {
      const payload = {
        debit_account_id: Number(debitId),
        credit_account_id: Number(creditId),
        description: description.trim(),
        category: category.trim() || null,
        amount: Number(amount),
        frequency,
        interval: Number(interval) || 1,
        start_date: startDate,
        end_date: endDate || null,
        active,
      };
      return isEdit && initial
        ? accountingApi.recurringUpdate(orgId, initial.id, payload)
        : accountingApi.recurringCreate(orgId, payload);
    },
    onSuccess: () => {
      toast.success(isEdit ? "Diperbarui" : "Jurnal berulang dibuat");
      qc.invalidateQueries({ queryKey: ["org-recurring", orgId] });
      onOpenChange(false);
    },
    onError: (err) => toast.error(getApiErrorMessage(err)),
  });

  const canSave =
    description.trim() &&
    Number(amount) > 0 &&
    debitId &&
    creditId &&
    debitId !== creditId &&
    startDate;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent size="md">
        <DialogHeader>
          <DialogTitle>{isEdit ? "Edit Jurnal Berulang" : "Jurnal Berulang Baru"}</DialogTitle>
          <DialogDescription>
            Jurnal akan dicatat secara berulang sesuai jadwal. Klik ▶ untuk menjalankan manual.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          <div className="space-y-1.5">
            <Label>Uraian</Label>
            <Input
              placeholder="Mis. Gaji karyawan, Sewa kantor"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              disabled={!canWrite}
            />
          </div>

          <div className="grid gap-3 sm:grid-cols-2">
            <div className="space-y-1.5">
              <Label>Jumlah (Rp)</Label>
              <Input
                type="number"
                min="0"
                step="any"
                placeholder="0"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                disabled={!canWrite}
              />
            </div>
            <div className="space-y-1.5">
              <Label>Kategori (opsional)</Label>
              <Input
                placeholder="Mis. Beban Operasional"
                value={category}
                onChange={(e) => setCategory(e.target.value)}
                disabled={!canWrite}
              />
            </div>
          </div>

          <div className="space-y-1.5">
            <Label>Akun Debit</Label>
            <AccountSelect
              accounts={allAccounts}
              value={debitId}
              onChange={setDebitId}
              placeholder="Pilih akun debit"
            />
          </div>

          <div className="space-y-1.5">
            <Label>Akun Kredit</Label>
            <AccountSelect
              accounts={allAccounts}
              value={creditId}
              onChange={setCreditId}
              placeholder="Pilih akun kredit"
            />
          </div>

          {debitId && creditId && debitId === creditId && (
            <p className="text-xs text-destructive">Akun debit dan kredit tidak boleh sama.</p>
          )}

          <div className="grid gap-3 sm:grid-cols-3">
            <div className="space-y-1.5">
              <Label>Frekuensi</Label>
              <Select value={frequency} onValueChange={(v) => setFrequency(v as typeof frequency)} disabled={!canWrite}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="daily">Harian</SelectItem>
                  <SelectItem value="weekly">Mingguan</SelectItem>
                  <SelectItem value="monthly">Bulanan</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1.5">
              <Label>Interval</Label>
              <Input
                type="number"
                min={1}
                max={90}
                value={interval}
                onChange={(e) => setInterval(e.target.value)}
                disabled={!canWrite}
              />
            </div>
            <div className="space-y-1.5">
              <Label>Mulai</Label>
              <Input type="date" value={startDate} onChange={(e) => setStartDate(e.target.value)} disabled={!canWrite} />
            </div>
          </div>

          <div className="grid gap-3 sm:grid-cols-2">
            <div className="space-y-1.5">
              <Label>Berakhir (opsional)</Label>
              <Input type="date" value={endDate} onChange={(e) => setEndDate(e.target.value)} disabled={!canWrite} />
            </div>
            <div className="flex items-center justify-between rounded-lg border border-border p-3">
              <div>
                <p className="text-sm font-medium">Aktif</p>
                <p className="text-xs text-muted-foreground">Pause untuk berhenti sementara.</p>
              </div>
              <Switch checked={active} onCheckedChange={setActive} disabled={!canWrite} />
            </div>
          </div>
        </div>

        <DialogFooter className="gap-2">
          {isEdit && canWrite && (
            <Button
              type="button"
              variant="ghost"
              onClick={onDelete}
              className="text-destructive hover:text-destructive sm:mr-auto"
            >
              <Trash2 className="h-4 w-4" /> Hapus
            </Button>
          )}
          <Button type="button" variant="ghost" onClick={() => onOpenChange(false)}>
            Batal
          </Button>
          {canWrite && (
            <Button onClick={() => save.mutate()} disabled={!canSave} loading={save.isPending}>
              {isEdit ? "Simpan" : "Buat"}
            </Button>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

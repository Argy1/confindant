"use client";

import * as React from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Plus, Pencil, Trash2 } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { AccountSelect } from "@/components/org/account-select";
import { YearSelect } from "@/components/org/year-select";
import { accountingApi } from "@/lib/api/accounting";
import { useActiveOrg } from "@/lib/hooks/use-active-org";
import { formatCurrency } from "@/lib/utils";
import { toast } from "sonner";
import { getApiErrorMessage } from "@/lib/api/client";
import type { OrgBudget } from "@/lib/accounting-types";

type FormState = {
  name: string;
  category: string;
  account_id: string;
  amount_planned: string;
  notes: string;
};

const EMPTY_FORM: FormState = {
  name: "",
  category: "",
  account_id: "",
  amount_planned: "",
  notes: "",
};

function pctColor(pct: number) {
  if (pct > 100) return "bg-red-500";
  if (pct >= 80) return "bg-amber-400";
  return "bg-blue-500";
}

export default function BudgetPage() {
  const { org, orgId, canWrite } = useActiveOrg();
  const qc = useQueryClient();
  const [year, setYear] = React.useState(new Date().getFullYear());

  const [dialogOpen, setDialogOpen] = React.useState(false);
  const [editTarget, setEditTarget] = React.useState<OrgBudget | null>(null);
  const [deleteTarget, setDeleteTarget] = React.useState<OrgBudget | null>(null);
  const [form, setForm] = React.useState<FormState>(EMPTY_FORM);

  const { data: accounts = [] } = useQuery({
    queryKey: ["accounts", orgId],
    queryFn: () => accountingApi.accounts(orgId!),
    enabled: !!orgId,
  });

  const { data: compare, isLoading } = useQuery({
    queryKey: ["budget-compare", orgId, year],
    queryFn: () => accountingApi.budgetCompare(orgId!, year),
    enabled: !!orgId,
  });

  const invalidate = () => qc.invalidateQueries({ queryKey: ["budget-compare", orgId, year] });

  const createMut = useMutation({
    mutationFn: (f: FormState) =>
      accountingApi.budgetCreate(orgId!, {
        name: f.name,
        fiscal_year: year,
        category: f.category || null,
        account_id: f.account_id ? Number(f.account_id) : null,
        amount_planned: Number(f.amount_planned),
        notes: f.notes || null,
      }),
    onSuccess: () => {
      toast.success("Anggaran ditambahkan");
      setDialogOpen(false);
      invalidate();
    },
    onError: (err) => toast.error(getApiErrorMessage(err, "Gagal menyimpan anggaran")),
  });

  const updateMut = useMutation({
    mutationFn: (f: FormState) =>
      accountingApi.budgetUpdate(orgId!, editTarget!.id, {
        name: f.name,
        category: f.category || null,
        account_id: f.account_id ? Number(f.account_id) : null,
        amount_planned: Number(f.amount_planned),
        notes: f.notes || null,
      }),
    onSuccess: () => {
      toast.success("Anggaran diperbarui");
      setDialogOpen(false);
      invalidate();
    },
    onError: (err) => toast.error(getApiErrorMessage(err, "Gagal memperbarui anggaran")),
  });

  const deleteMut = useMutation({
    mutationFn: () => accountingApi.budgetDelete(orgId!, deleteTarget!.id),
    onSuccess: () => {
      toast.success("Anggaran dihapus");
      setDeleteTarget(null);
      invalidate();
    },
    onError: (err) => toast.error(getApiErrorMessage(err, "Gagal menghapus anggaran")),
  });

  function openCreate() {
    setEditTarget(null);
    setForm(EMPTY_FORM);
    setDialogOpen(true);
  }

  function openEdit(item: OrgBudget) {
    setEditTarget(item);
    setForm({
      name: item.name,
      category: item.category ?? "",
      account_id: item.account_id != null ? String(item.account_id) : "",
      amount_planned: String(item.amount_planned),
      notes: item.notes ?? "",
    });
    setDialogOpen(true);
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!form.name || !form.amount_planned) return;
    if (editTarget) {
      updateMut.mutate(form);
    } else {
      createMut.mutate(form);
    }
  }

  const totals = compare?.totals;
  const items = compare?.items ?? [];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
            Budget & Realisasi
          </h1>
          <p className="text-sm text-muted-foreground">
            {org?.name} · Tahun {year}
          </p>
        </div>
        <div className="flex items-center gap-2">
          <YearSelect value={year} onChange={setYear} />
          {canWrite && (
            <Button size="sm" onClick={openCreate}>
              <Plus className="mr-2 h-4 w-4" />
              Tambah
            </Button>
          )}
        </div>
      </div>

      {/* Summary cards */}
      {isLoading ? (
        <div className="grid gap-4 sm:grid-cols-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <Skeleton key={i} className="h-24 rounded-xl" />
          ))}
        </div>
      ) : totals ? (
        <div className="grid gap-4 sm:grid-cols-4">
          <Card>
            <CardContent className="p-4">
              <p className="text-xs text-muted-foreground">Total Anggaran</p>
              <p className="mt-1 font-display text-lg font-bold tabular-nums">
                {formatCurrency(totals.total_planned)}
              </p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4">
              <p className="text-xs text-muted-foreground">Total Realisasi</p>
              <p className="mt-1 font-display text-lg font-bold tabular-nums">
                {formatCurrency(totals.total_actual)}
              </p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4">
              <p className="text-xs text-muted-foreground">Sisa Anggaran</p>
              <p
                className={`mt-1 font-display text-lg font-bold tabular-nums ${
                  totals.total_variance >= 0 ? "text-emerald-600" : "text-red-600"
                }`}
              >
                {formatCurrency(totals.total_variance)}
              </p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4">
              <p className="text-xs text-muted-foreground">% Terpakai</p>
              <p
                className={`mt-1 font-display text-lg font-bold ${
                  totals.overall_percentage > 100
                    ? "text-red-600"
                    : totals.overall_percentage >= 80
                    ? "text-amber-600"
                    : "text-blue-700"
                }`}
              >
                {totals.overall_percentage}%
              </p>
            </CardContent>
          </Card>
        </div>
      ) : null}

      {/* Table */}
      {isLoading ? (
        <Skeleton className="h-64 rounded-xl" />
      ) : items.length === 0 ? (
        <Card>
          <CardContent className="flex flex-col items-center gap-3 py-16 text-center">
            <p className="text-muted-foreground text-sm">
              Belum ada anggaran untuk tahun {year}.
            </p>
            {canWrite && (
              <Button size="sm" variant="outline" onClick={openCreate}>
                <Plus className="mr-2 h-4 w-4" />
                Tambah Anggaran Pertama
              </Button>
            )}
          </CardContent>
        </Card>
      ) : (
        <Card>
          <CardContent className="p-0">
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border bg-muted/40 text-left text-xs uppercase tracking-wide text-muted-foreground">
                    <th className="px-4 py-3 font-semibold">Nama Program</th>
                    <th className="px-4 py-3 font-semibold">Akun</th>
                    <th className="px-4 py-3 text-right font-semibold">Anggaran</th>
                    <th className="px-4 py-3 text-right font-semibold">Realisasi</th>
                    <th className="px-4 py-3 font-semibold" style={{ minWidth: "120px" }}>
                      % Terpakai
                    </th>
                    <th className="px-4 py-3 text-right font-semibold">Sisa</th>
                    {canWrite && <th className="px-4 py-3" />}
                  </tr>
                </thead>
                <tbody>
                  {items.map((item) => (
                    <tr
                      key={item.id}
                      className="border-b border-border/50 last:border-0 hover:bg-accent/30"
                    >
                      <td className="px-4 py-3">
                        <div className="font-medium">{item.name}</div>
                        {item.category && (
                          <div className="text-xs text-muted-foreground capitalize">
                            {item.category}
                          </div>
                        )}
                      </td>
                      <td className="px-4 py-3 text-muted-foreground">
                        {item.account ? (
                          <span className="flex items-center gap-1.5">
                            <span className="font-mono text-xs">{item.account.code}</span>
                            <span className="truncate max-w-35">{item.account.name}</span>
                          </span>
                        ) : (
                          <span className="text-xs italic">—</span>
                        )}
                      </td>
                      <td className="px-4 py-3 text-right tabular-nums">
                        {formatCurrency(item.amount_planned)}
                      </td>
                      <td className="px-4 py-3 text-right tabular-nums">
                        {formatCurrency(item.amount_actual)}
                      </td>
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-2">
                          <div className="relative h-2 flex-1 overflow-hidden rounded-full bg-muted">
                            <div
                              className={`absolute inset-y-0 left-0 rounded-full ${pctColor(item.percentage)}`}
                              style={{ width: `${Math.min(item.percentage, 100)}%` }}
                            />
                          </div>
                          <span
                            className={`w-12 text-right text-xs font-medium tabular-nums ${
                              item.percentage > 100
                                ? "text-red-600"
                                : item.percentage >= 80
                                ? "text-amber-600"
                                : "text-muted-foreground"
                            }`}
                          >
                            {item.percentage}%
                          </span>
                        </div>
                      </td>
                      <td
                        className={`px-4 py-3 text-right tabular-nums font-medium ${
                          item.variance >= 0 ? "text-emerald-600" : "text-red-600"
                        }`}
                      >
                        {item.variance >= 0 ? "+" : ""}
                        {formatCurrency(item.variance)}
                      </td>
                      {canWrite && (
                        <td className="px-4 py-3">
                          <div className="flex items-center justify-end gap-1">
                            <Button
                              variant="ghost"
                              size="icon"
                              className="h-7 w-7"
                              onClick={() => {
                                const original = compare?.items.find((i) => i.id === item.id);
                                if (original) {
                                  openEdit({
                                    id: original.id,
                                    organization_id: 0,
                                    fiscal_year: year,
                                    name: original.name,
                                    category: original.category,
                                    account_id: original.account?.id ? Number(original.account.id) : null,
                                    account: original.account ?? undefined,
                                    amount_planned: original.amount_planned,
                                    notes: original.notes,
                                    created_by: null,
                                    created_at: "",
                                    updated_at: "",
                                  } as OrgBudget);
                                }
                              }}
                            >
                              <Pencil className="h-3.5 w-3.5" />
                            </Button>
                            <Button
                              variant="ghost"
                              size="icon"
                              className="h-7 w-7 text-destructive hover:text-destructive"
                              onClick={() =>
                                setDeleteTarget({
                                  id: item.id,
                                  name: item.name,
                                } as OrgBudget)
                              }
                            >
                              <Trash2 className="h-3.5 w-3.5" />
                            </Button>
                          </div>
                        </td>
                      )}
                    </tr>
                  ))}
                </tbody>
                <tfoot>
                  <tr className="border-t-2 border-border bg-muted/30 font-bold">
                    <td colSpan={2} className="px-4 py-3 text-right uppercase text-xs">
                      Total
                    </td>
                    <td className="px-4 py-3 text-right tabular-nums">
                      {formatCurrency(totals?.total_planned ?? 0)}
                    </td>
                    <td className="px-4 py-3 text-right tabular-nums">
                      {formatCurrency(totals?.total_actual ?? 0)}
                    </td>
                    <td className="px-4 py-3" />
                    <td
                      className={`px-4 py-3 text-right tabular-nums ${
                        (totals?.total_variance ?? 0) >= 0 ? "text-emerald-600" : "text-red-600"
                      }`}
                    >
                      {(totals?.total_variance ?? 0) >= 0 ? "+" : ""}
                      {formatCurrency(totals?.total_variance ?? 0)}
                    </td>
                    {canWrite && <td />}
                  </tr>
                </tfoot>
              </table>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Add / Edit Dialog */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>
              {editTarget ? "Edit Anggaran" : "Tambah Anggaran"}
            </DialogTitle>
          </DialogHeader>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-1.5">
              <Label htmlFor="bname">Nama Program / Pos Anggaran</Label>
              <Input
                id="bname"
                value={form.name}
                onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))}
                placeholder="cth. Program Pendidikan"
                required
              />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1.5">
                <Label>Kategori</Label>
                <Select
                  value={form.category}
                  onValueChange={(v) => setForm((f) => ({ ...f, category: v }))}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Pilih kategori" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="expense">Beban</SelectItem>
                    <SelectItem value="revenue">Pendapatan</SelectItem>
                    <SelectItem value="asset">Aset</SelectItem>
                    <SelectItem value="liability">Kewajiban</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-1.5">
                <Label htmlFor="bamount">Anggaran (Rp)</Label>
                <Input
                  id="bamount"
                  type="number"
                  min={0}
                  step="any"
                  value={form.amount_planned}
                  onChange={(e) => setForm((f) => ({ ...f, amount_planned: e.target.value }))}
                  placeholder="0"
                  required
                />
              </div>
            </div>

            <div className="space-y-1.5">
              <Label>Akun Terkait (opsional)</Label>
              <AccountSelect
                accounts={accounts}
                value={form.account_id}
                onChange={(v) => setForm((f) => ({ ...f, account_id: v }))}
                placeholder="Pilih akun untuk tracking otomatis"
              />
            </div>

            <div className="space-y-1.5">
              <Label htmlFor="bnotes">Catatan (opsional)</Label>
              <Textarea
                id="bnotes"
                value={form.notes}
                onChange={(e) => setForm((f) => ({ ...f, notes: e.target.value }))}
                rows={2}
                placeholder="Keterangan tambahan..."
              />
            </div>

            <DialogFooter>
              <Button
                type="button"
                variant="outline"
                onClick={() => setDialogOpen(false)}
              >
                Batal
              </Button>
              <Button
                type="submit"
                disabled={createMut.isPending || updateMut.isPending}
              >
                {editTarget ? "Simpan" : "Tambah"}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* Delete confirmation */}
      <Dialog open={!!deleteTarget} onOpenChange={(open: boolean) => !open && setDeleteTarget(null)}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>Hapus anggaran?</DialogTitle>
          </DialogHeader>
          <p className="text-sm text-muted-foreground">
            &quot;{deleteTarget?.name}&quot; akan dihapus permanen dan tidak bisa dikembalikan.
          </p>
          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => setDeleteTarget(null)}>
              Batal
            </Button>
            <Button
              variant="destructive"
              onClick={() => deleteMut.mutate()}
              disabled={deleteMut.isPending}
            >
              Hapus
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

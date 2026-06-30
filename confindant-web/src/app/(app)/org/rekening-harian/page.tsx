"use client";

import * as React from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Plus, Trash2, TrendingUp, TrendingDown, Wallet } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import {
  rekeningHarianApi,
  type RekeningHarianRow,
} from "@/lib/api/accounting";
import { useActiveOrg } from "@/lib/hooks/use-active-org";
import { formatCurrency, formatDate } from "@/lib/utils";
import { toast } from "sonner";

type FormState = {
  date: string;
  uraian: string;
  type: "pemasukan" | "pengeluaran";
  amount: string;
  kategori: string;
  keterangan: string;
  klasifikasi: string;
};

const emptyForm = (): FormState => ({
  date: new Date().toISOString().slice(0, 10),
  uraian: "",
  type: "pemasukan",
  amount: "",
  kategori: "",
  keterangan: "",
  klasifikasi: "",
});

export default function RekeningHarianPage() {
  const { org, orgId, canWrite } = useActiveOrg();
  const qc = useQueryClient();

  const [formOpen, setFormOpen] = React.useState(false);
  const [deleteId, setDeleteId] = React.useState<number | null>(null);
  const [form, setForm] = React.useState<FormState>(emptyForm);
  const [fromDate, setFromDate] = React.useState("");
  const [toDate, setToDate] = React.useState("");

  const { data, isLoading } = useQuery({
    queryKey: ["rekening-harian", orgId, fromDate, toDate],
    queryFn: () =>
      rekeningHarianApi.list(orgId!, {
        from_date: fromDate || undefined,
        to_date: toDate || undefined,
        per_page: 200,
      }),
    enabled: !!orgId,
  });

  const { data: cats } = useQuery({
    queryKey: ["rekening-harian-cats", orgId],
    queryFn: () => rekeningHarianApi.categories(orgId!),
    enabled: !!orgId,
  });

  const createMut = useMutation({
    mutationFn: (f: FormState) =>
      rekeningHarianApi.create(orgId!, {
        date: f.date,
        uraian: f.uraian,
        pemasukan: f.type === "pemasukan" ? parseFloat(f.amount) : undefined,
        pengeluaran: f.type === "pengeluaran" ? parseFloat(f.amount) : undefined,
        kategori: f.kategori || undefined,
        keterangan: f.keterangan || undefined,
        klasifikasi: f.klasifikasi || undefined,
      }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["rekening-harian", orgId] });
      setFormOpen(false);
      setForm(emptyForm());
      toast.success("Entri berhasil ditambahkan");
    },
    onError: (e: unknown) => {
      const msg = (e as { response?: { data?: { message?: string } } })
        ?.response?.data?.message;
      toast.error(msg ?? "Gagal menambahkan entri");
    },
  });

  const deleteMut = useMutation({
    mutationFn: (id: number) => rekeningHarianApi.remove(orgId!, id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["rekening-harian", orgId] });
      setDeleteId(null);
      toast.success("Entri berhasil dibatalkan");
    },
    onError: () => toast.error("Gagal membatalkan entri"),
  });

  const rows = data?.rows ?? [];
  const meta = data?.meta;

  const availableCategories =
    form.type === "pemasukan"
      ? (cats?.income ?? [])
      : (cats?.expense ?? []);

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!form.uraian.trim() || !form.amount || parseFloat(form.amount) <= 0) {
      toast.error("Uraian dan jumlah wajib diisi");
      return;
    }
    createMut.mutate(form);
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
            Rekening Harian
          </h1>
          <p className="text-sm text-muted-foreground">
            {org?.name} · Buku kas harian PDPI
          </p>
        </div>
        {canWrite && (
          <Button variant="gradient" onClick={() => setFormOpen(true)}>
            <Plus className="h-4 w-4" /> Tambah Entri
          </Button>
        )}
      </div>

      {/* Summary cards */}
      {meta && (
        <div className="grid gap-4 sm:grid-cols-3">
          <Card>
            <CardHeader className="pb-1">
              <CardTitle className="flex items-center gap-2 text-sm font-medium text-muted-foreground">
                <Wallet className="h-4 w-4" /> Saldo Awal
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-xl font-bold tabular-nums">
                {formatCurrency(meta.opening_balance)}
              </p>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="pb-1">
              <CardTitle className="flex items-center gap-2 text-sm font-medium text-muted-foreground">
                <TrendingUp className="h-4 w-4 text-emerald-500" /> Total Pemasukan
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-xl font-bold tabular-nums text-emerald-600">
                {formatCurrency(
                  rows.reduce((s, r) => s + (r.pemasukan ?? 0), 0),
                )}
              </p>
            </CardContent>
          </Card>
          <Card>
            <CardHeader className="pb-1">
              <CardTitle className="flex items-center gap-2 text-sm font-medium text-muted-foreground">
                <TrendingDown className="h-4 w-4 text-rose-500" /> Total Pengeluaran
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-xl font-bold tabular-nums text-rose-600">
                {formatCurrency(
                  rows.reduce((s, r) => s + (r.pengeluaran ?? 0), 0),
                )}
              </p>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Date filter */}
      <div className="flex flex-wrap items-end gap-3">
        <div className="space-y-1">
          <Label className="text-xs">Dari</Label>
          <Input
            type="date"
            value={fromDate}
            onChange={(e) => setFromDate(e.target.value)}
            className="w-40"
          />
        </div>
        <div className="space-y-1">
          <Label className="text-xs">Sampai</Label>
          <Input
            type="date"
            value={toDate}
            onChange={(e) => setToDate(e.target.value)}
            className="w-40"
          />
        </div>
        {(fromDate || toDate) && (
          <Button
            variant="ghost"
            size="sm"
            onClick={() => {
              setFromDate("");
              setToDate("");
            }}
          >
            Reset
          </Button>
        )}
      </div>

      {/* Table */}
      {isLoading ? (
        <div className="space-y-2">
          {Array.from({ length: 8 }).map((_, i) => (
            <Skeleton key={i} className="h-14 rounded-xl" />
          ))}
        </div>
      ) : rows.length === 0 ? (
        <Card>
          <CardContent className="grid place-items-center gap-3 py-14 text-center">
            <p className="font-semibold">Belum ada entri</p>
            <p className="max-w-xs text-sm text-muted-foreground">
              Mulai catat transaksi harian organisasi.
            </p>
            {canWrite && (
              <Button variant="gradient" onClick={() => setFormOpen(true)}>
                <Plus className="h-4 w-4" /> Tambah Entri
              </Button>
            )}
          </CardContent>
        </Card>
      ) : (
        <Card>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground">
                  <th className="px-4 py-3">Tanggal</th>
                  <th className="px-4 py-3">Uraian</th>
                  <th className="px-4 py-3">Kategori</th>
                  <th className="px-4 py-3 text-right">Pemasukan</th>
                  <th className="px-4 py-3 text-right">Pengeluaran</th>
                  <th className="px-4 py-3 text-right">Saldo</th>
                  {canWrite && <th className="px-4 py-3" />}
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {rows.map((row: RekeningHarianRow) => (
                  <tr
                    key={row.id}
                    className="transition-colors hover:bg-accent/30"
                  >
                    <td className="whitespace-nowrap px-4 py-3 text-muted-foreground">
                      {formatDate(row.date)}
                    </td>
                    <td className="px-4 py-3">
                      <p className="font-medium">{row.uraian}</p>
                      {row.keterangan && (
                        <p className="text-xs text-muted-foreground">
                          {row.keterangan}
                        </p>
                      )}
                    </td>
                    <td className="px-4 py-3">
                      {row.kategori ? (
                        <Badge variant="secondary" className="capitalize">
                          {row.kategori}
                        </Badge>
                      ) : (
                        <span className="text-muted-foreground">—</span>
                      )}
                    </td>
                    <td className="whitespace-nowrap px-4 py-3 text-right font-mono tabular-nums text-emerald-600">
                      {row.pemasukan != null
                        ? formatCurrency(row.pemasukan)
                        : "—"}
                    </td>
                    <td className="whitespace-nowrap px-4 py-3 text-right font-mono tabular-nums text-rose-600">
                      {row.pengeluaran != null
                        ? formatCurrency(row.pengeluaran)
                        : "—"}
                    </td>
                    <td className="whitespace-nowrap px-4 py-3 text-right font-mono font-semibold tabular-nums">
                      {formatCurrency(row.saldo)}
                    </td>
                    {canWrite && (
                      <td className="px-4 py-3">
                        <Button
                          size="icon"
                          variant="ghost"
                          className="h-7 w-7 text-muted-foreground hover:text-destructive"
                          onClick={() => setDeleteId(row.id)}
                          title="Batalkan entri"
                        >
                          <Trash2 className="h-3.5 w-3.5" />
                        </Button>
                      </td>
                    )}
                  </tr>
                ))}
              </tbody>
              {meta && (
                <tfoot>
                  <tr className="border-t-2 border-border font-semibold">
                    <td colSpan={3} className="px-4 py-3 text-muted-foreground">
                      Saldo Akhir
                    </td>
                    <td className="px-4 py-3 text-right font-mono tabular-nums text-emerald-600">
                      {formatCurrency(
                        rows.reduce((s, r) => s + (r.pemasukan ?? 0), 0),
                      )}
                    </td>
                    <td className="px-4 py-3 text-right font-mono tabular-nums text-rose-600">
                      {formatCurrency(
                        rows.reduce((s, r) => s + (r.pengeluaran ?? 0), 0),
                      )}
                    </td>
                    <td className="px-4 py-3 text-right font-mono tabular-nums">
                      {formatCurrency(meta.running_balance)}
                    </td>
                    {canWrite && <td />}
                  </tr>
                </tfoot>
              )}
            </table>
          </div>
        </Card>
      )}

      {/* Add entry dialog */}
      <Dialog open={formOpen} onOpenChange={setFormOpen}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>Tambah Entri Harian</DialogTitle>
          </DialogHeader>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-1">
              <Label>Tanggal</Label>
              <Input
                type="date"
                value={form.date}
                onChange={(e) => setForm((f) => ({ ...f, date: e.target.value }))}
                required
              />
            </div>
            <div className="space-y-1">
              <Label>Uraian</Label>
              <Input
                value={form.uraian}
                onChange={(e) =>
                  setForm((f) => ({ ...f, uraian: e.target.value }))
                }
                placeholder="Keterangan transaksi"
                required
              />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1">
                <Label>Jenis</Label>
                <Select
                  value={form.type}
                  onValueChange={(v) =>
                    setForm((f) => ({
                      ...f,
                      type: v as "pemasukan" | "pengeluaran",
                      kategori: "",
                    }))
                  }
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="pemasukan">Pemasukan</SelectItem>
                    <SelectItem value="pengeluaran">Pengeluaran</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-1">
                <Label>Jumlah (Rp)</Label>
                <Input
                  type="number"
                  min="0"
                  step="1"
                  value={form.amount}
                  onChange={(e) =>
                    setForm((f) => ({ ...f, amount: e.target.value }))
                  }
                  placeholder="0"
                  required
                />
              </div>
            </div>
            <div className="space-y-1">
              <Label>Kategori</Label>
              <Select
                value={form.kategori || "__none__"}
                onValueChange={(v) =>
                  setForm((f) => ({
                    ...f,
                    kategori: v === "__none__" ? "" : v,
                  }))
                }
              >
                <SelectTrigger>
                  <SelectValue placeholder="Pilih kategori (opsional)" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="__none__">— Tanpa kategori —</SelectItem>
                  {availableCategories.map((c) => (
                    <SelectItem key={c} value={c} className="capitalize">
                      {c}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1">
              <Label>Keterangan</Label>
              <Input
                value={form.keterangan}
                onChange={(e) =>
                  setForm((f) => ({ ...f, keterangan: e.target.value }))
                }
                placeholder="Referensi / catatan (opsional)"
              />
            </div>
            <DialogFooter>
              <Button
                type="button"
                variant="ghost"
                onClick={() => setFormOpen(false)}
              >
                Batal
              </Button>
              <Button
                type="submit"
                variant="gradient"
                disabled={createMut.isPending}
              >
                {createMut.isPending ? "Menyimpan..." : "Simpan"}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* Confirm void */}
      <AlertDialog
        open={deleteId !== null}
        onOpenChange={(o) => !o && setDeleteId(null)}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Batalkan entri?</AlertDialogTitle>
            <AlertDialogDescription>
              Entri akan di-void dan tidak bisa dikembalikan. Jurnal akuntansi
              terkait juga akan dibatalkan.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Kembali</AlertDialogCancel>
            <AlertDialogAction
              onClick={() => deleteId !== null && deleteMut.mutate(deleteId)}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              {deleteMut.isPending ? "Membatalkan..." : "Ya, batalkan"}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}

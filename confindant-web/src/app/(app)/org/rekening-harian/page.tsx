"use client";

import * as React from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  Plus,
  Trash2,
  TrendingUp,
  TrendingDown,
  Wallet,
  LayoutList,
  Tags,
} from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs";
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
  rekeningHarianApi,
  type RekeningHarianRow,
} from "@/lib/api/accounting";
import { useActiveOrg } from "@/lib/hooks/use-active-org";
import { formatCurrency, formatDate } from "@/lib/utils";
import { toast } from "sonner";

// ---- Types ----

type FormState = {
  date: string;
  uraian: string;
  type: "pemasukan" | "pengeluaran";
  amount: string;
  kategori: string;
  keterangan: string;
};

type KategoriRow = {
  kategori: string;
  pemasukan: number;
  pengeluaran: number;
  selisih: number;
  count: number;
};

// ---- Helpers ----

const emptyForm = (): FormState => ({
  date: new Date().toISOString().slice(0, 10),
  uraian: "",
  type: "pemasukan",
  amount: "",
  kategori: "",
  keterangan: "",
});

function buildKategoriSummary(rows: RekeningHarianRow[]): KategoriRow[] {
  const map = new Map<string, KategoriRow>();
  for (const row of rows) {
    const key = row.kategori ? row.kategori : "Tanpa Kategori";
    const prev = map.get(key) ?? {
      kategori: key,
      pemasukan: 0,
      pengeluaran: 0,
      selisih: 0,
      count: 0,
    };
    prev.pemasukan += row.pemasukan ?? 0;
    prev.pengeluaran += row.pengeluaran ?? 0;
    prev.selisih = prev.pemasukan - prev.pengeluaran;
    prev.count += 1;
    map.set(key, prev);
  }
  // Sort: categories with transactions first, largest volume on top
  return Array.from(map.values()).sort(
    (a, b) => b.pemasukan + b.pengeluaran - (a.pemasukan + a.pengeluaran),
  );
}

// ---- Page ----

export default function RekeningHarianPage() {
  const { org, orgId, canWrite } = useActiveOrg();
  const qc = useQueryClient();

  const [activeTab, setActiveTab] = React.useState("transaksi");
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
        per_page: 500,
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
  const kategoriRows = React.useMemo(() => buildKategoriSummary(rows), [rows]);

  const totalPemasukan = rows.reduce((s, r) => s + (r.pemasukan ?? 0), 0);
  const totalPengeluaran = rows.reduce((s, r) => s + (r.pengeluaran ?? 0), 0);

  const availableCategories =
    form.type === "pemasukan" ? (cats?.income ?? []) : (cats?.expense ?? []);

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
      {(meta || isLoading) && (
        <div className="grid gap-4 sm:grid-cols-3">
          {isLoading ? (
            Array.from({ length: 3 }).map((_, i) => (
              <Skeleton key={i} className="h-24 rounded-xl" />
            ))
          ) : (
            <>
              <Card>
                <CardHeader className="pb-1">
                  <CardTitle className="flex items-center gap-2 text-sm font-medium text-muted-foreground">
                    <Wallet className="h-4 w-4" /> Saldo Rekening
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-xl font-bold tabular-nums">
                    {formatCurrency(meta?.running_balance ?? 0)}
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
                    {formatCurrency(totalPemasukan)}
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
                    {formatCurrency(totalPengeluaran)}
                  </p>
                </CardContent>
              </Card>
            </>
          )}
        </div>
      )}

      {/* Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <div className="flex flex-wrap items-center justify-between gap-3">
          <TabsList>
            <TabsTrigger value="transaksi" className="gap-1.5">
              <LayoutList className="h-3.5 w-3.5" />
              Transaksi
            </TabsTrigger>
            <TabsTrigger value="per-kategori" className="gap-1.5">
              <Tags className="h-3.5 w-3.5" />
              Per Kategori
            </TabsTrigger>
          </TabsList>

          {/* Date filter — shared for both tabs */}
          <div className="flex flex-wrap items-end gap-3">
            <div className="space-y-1">
              <Label className="text-xs">Dari</Label>
              <Input
                type="date"
                value={fromDate}
                onChange={(e) => setFromDate(e.target.value)}
                className="w-36"
              />
            </div>
            <div className="space-y-1">
              <Label className="text-xs">Sampai</Label>
              <Input
                type="date"
                value={toDate}
                onChange={(e) => setToDate(e.target.value)}
                className="w-36"
              />
            </div>
            {(fromDate || toDate) && (
              <Button
                variant="ghost"
                size="sm"
                onClick={() => { setFromDate(""); setToDate(""); }}
              >
                Reset
              </Button>
            )}
          </div>
        </div>

        {/* ---- Tab: Transaksi ---- */}
        <TabsContent value="transaksi">
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
                          {row.pemasukan != null ? formatCurrency(row.pemasukan) : "—"}
                        </td>
                        <td className="whitespace-nowrap px-4 py-3 text-right font-mono tabular-nums text-rose-600">
                          {row.pengeluaran != null ? formatCurrency(row.pengeluaran) : "—"}
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
                  <tfoot>
                    <tr className="border-t-2 border-border bg-muted/30 font-semibold">
                      <td colSpan={3} className="px-4 py-3 text-muted-foreground">
                        Total · {rows.length} transaksi
                      </td>
                      <td className="px-4 py-3 text-right font-mono tabular-nums text-emerald-600">
                        {formatCurrency(totalPemasukan)}
                      </td>
                      <td className="px-4 py-3 text-right font-mono tabular-nums text-rose-600">
                        {formatCurrency(totalPengeluaran)}
                      </td>
                      <td className="px-4 py-3 text-right font-mono tabular-nums">
                        {meta ? formatCurrency(meta.running_balance) : "—"}
                      </td>
                      {canWrite && <td />}
                    </tr>
                  </tfoot>
                </table>
              </div>
            </Card>
          )}
        </TabsContent>

        {/* ---- Tab: Per Kategori ---- */}
        <TabsContent value="per-kategori">
          {isLoading ? (
            <div className="space-y-2">
              {Array.from({ length: 6 }).map((_, i) => (
                <Skeleton key={i} className="h-14 rounded-xl" />
              ))}
            </div>
          ) : kategoriRows.length === 0 ? (
            <Card>
              <CardContent className="grid place-items-center gap-3 py-14 text-center">
                <p className="font-semibold">Belum ada data</p>
                <p className="text-sm text-muted-foreground">
                  Tambahkan entri dengan kategori untuk melihat ringkasan ini.
                </p>
              </CardContent>
            </Card>
          ) : (
            <Card>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-border text-left text-xs font-semibold uppercase tracking-wide text-muted-foreground">
                      <th className="px-4 py-3">Kategori</th>
                      <th className="px-4 py-3 text-right">Transaksi</th>
                      <th className="px-4 py-3 text-right">Pemasukan</th>
                      <th className="px-4 py-3 text-right">Pengeluaran</th>
                      <th className="px-4 py-3 text-right">Selisih</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border">
                    {kategoriRows.map((kr) => (
                      <tr
                        key={kr.kategori}
                        className="transition-colors hover:bg-accent/30"
                      >
                        <td className="px-4 py-3">
                          <Badge
                            variant={
                              kr.kategori === "Tanpa Kategori"
                                ? "outline"
                                : "secondary"
                            }
                            className="capitalize"
                          >
                            {kr.kategori}
                          </Badge>
                          <span className="ml-2 text-xs text-muted-foreground">
                            {kr.count} transaksi
                          </span>
                        </td>
                        <td className="whitespace-nowrap px-4 py-3 text-right tabular-nums text-muted-foreground">
                          {kr.count}
                        </td>
                        <td className="whitespace-nowrap px-4 py-3 text-right font-mono tabular-nums text-emerald-600">
                          {kr.pemasukan > 0 ? formatCurrency(kr.pemasukan) : "—"}
                        </td>
                        <td className="whitespace-nowrap px-4 py-3 text-right font-mono tabular-nums text-rose-600">
                          {kr.pengeluaran > 0 ? formatCurrency(kr.pengeluaran) : "—"}
                        </td>
                        <td
                          className={`whitespace-nowrap px-4 py-3 text-right font-mono font-semibold tabular-nums ${
                            kr.selisih >= 0 ? "text-emerald-600" : "text-rose-600"
                          }`}
                        >
                          {kr.selisih >= 0 ? "+" : ""}
                          {formatCurrency(kr.selisih)}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                  <tfoot>
                    <tr className="border-t-2 border-border bg-muted/30 font-semibold">
                      <td className="px-4 py-3 text-muted-foreground">
                        Total · {kategoriRows.length} kategori
                      </td>
                      <td className="px-4 py-3 text-right tabular-nums text-muted-foreground">
                        {rows.length}
                      </td>
                      <td className="px-4 py-3 text-right font-mono tabular-nums text-emerald-600">
                        {formatCurrency(totalPemasukan)}
                      </td>
                      <td className="px-4 py-3 text-right font-mono tabular-nums text-rose-600">
                        {formatCurrency(totalPengeluaran)}
                      </td>
                      <td
                        className={`px-4 py-3 text-right font-mono tabular-nums ${
                          totalPemasukan - totalPengeluaran >= 0
                            ? "text-emerald-600"
                            : "text-rose-600"
                        }`}
                      >
                        {totalPemasukan - totalPengeluaran >= 0 ? "+" : ""}
                        {formatCurrency(totalPemasukan - totalPengeluaran)}
                      </td>
                    </tr>
                  </tfoot>
                </table>
              </div>
            </Card>
          )}
        </TabsContent>
      </Tabs>

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
      <Dialog
        open={deleteId !== null}
        onOpenChange={(open: boolean) => !open && setDeleteId(null)}
      >
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>Batalkan entri?</DialogTitle>
          </DialogHeader>
          <p className="text-sm text-muted-foreground">
            Entri akan di-void dan tidak bisa dikembalikan. Jurnal akuntansi
            terkait juga akan dibatalkan.
          </p>
          <DialogFooter className="gap-2">
            <Button variant="ghost" onClick={() => setDeleteId(null)}>
              Kembali
            </Button>
            <Button
              variant="destructive"
              disabled={deleteMut.isPending}
              onClick={() => deleteId !== null && deleteMut.mutate(deleteId)}
            >
              {deleteMut.isPending ? "Membatalkan..." : "Ya, batalkan"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

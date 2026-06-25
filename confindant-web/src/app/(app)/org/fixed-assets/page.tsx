"use client";

import * as React from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Plus, Play } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Dialog,
  DialogContent,
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
import { accountingApi } from "@/lib/api/accounting";
import { getApiErrorMessage } from "@/lib/api/client";
import { useActiveOrg } from "@/lib/hooks/use-active-org";
import { YearSelect } from "@/components/org/year-select";
import { formatCompactCurrency, formatCurrency, formatDate } from "@/lib/utils";

const GROUPS = [
  { value: "PERLENGKAPAN", label: "Perlengkapan / Peralatan (25%)" },
  { value: "BANGUNAN", label: "Bangunan (5%)" },
  { value: "TANAH", label: "Tanah (tanpa penyusutan)" },
];

export default function FixedAssetsPage() {
  const { org, orgId, canWrite } = useActiveOrg();
  const qc = useQueryClient();
  const [addOpen, setAddOpen] = React.useState(false);
  const [year, setYear] = React.useState(new Date().getFullYear());

  const { data, isLoading } = useQuery({
    queryKey: ["fixed-assets", orgId],
    queryFn: () => accountingApi.fixedAssets(orgId!),
    enabled: !!orgId,
  });

  const runDep = useMutation({
    mutationFn: () => accountingApi.runDepreciation(orgId!, year),
    onSuccess: (res) => {
      toast.success(
        `Penyusutan ${year}: ${res.posted} aset diposting (${formatCurrency(res.total_amount)})`,
      );
      qc.invalidateQueries({ queryKey: ["fixed-assets", orgId] });
      qc.invalidateQueries({ queryKey: ["org-dashboard", orgId] });
    },
    onError: (err) => toast.error(getApiErrorMessage(err)),
  });

  const assets = data?.assets ?? [];
  const summary = data?.summary;

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
            Aktiva Tetap
          </h1>
          <p className="text-sm text-muted-foreground">
            {org?.name} · {summary?.count ?? 0} aset
          </p>
        </div>
        {canWrite && (
          <div className="flex items-center gap-2">
            <YearSelect value={year} onChange={setYear} />
            <Button
              variant="outline"
              disabled={runDep.isPending}
              onClick={() => runDep.mutate()}
            >
              <Play className="h-4 w-4" />
              {runDep.isPending ? "Memproses..." : `Penyusutan ${year}`}
            </Button>
            <Button variant="gradient" onClick={() => setAddOpen(true)}>
              <Plus className="h-4 w-4" /> Tambah
            </Button>
          </div>
        )}
      </div>

      {/* Summary cards */}
      {summary && (
        <div className="grid grid-cols-3 gap-3">
          <SummaryCard label="Harga Perolehan" value={summary.total_acquisition_cost} />
          <SummaryCard
            label="Akm. Penyusutan"
            value={summary.total_accumulated_depreciation}
          />
          <SummaryCard label="Nilai Buku" value={summary.total_book_value} strong />
        </div>
      )}

      {isLoading ? (
        <Skeleton className="h-80 rounded-xl" />
      ) : assets.length === 0 ? (
        <Card>
          <CardContent className="grid place-items-center gap-3 py-14 text-center">
            <p className="font-semibold">Belum ada aset</p>
            <p className="max-w-xs text-sm text-muted-foreground">
              Tambahkan aktiva tetap untuk mulai melacak penyusutan.
            </p>
          </CardContent>
        </Card>
      ) : (
        <Card>
          <CardContent className="p-0">
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border bg-muted/40 text-left text-xs uppercase tracking-wide text-muted-foreground">
                    <th className="px-4 py-3 font-semibold">Nama</th>
                    <th className="px-4 py-3 font-semibold">Perolehan</th>
                    <th className="px-4 py-3 text-right font-semibold">Harga</th>
                    <th className="px-4 py-3 text-right font-semibold">Akm. Peny.</th>
                    <th className="px-4 py-3 text-right font-semibold">Nilai Buku</th>
                  </tr>
                </thead>
                <tbody>
                  {assets.map((a) => (
                    <tr
                      key={a.id}
                      className="border-b border-border/50 last:border-0 hover:bg-accent/20"
                    >
                      <td className="px-4 py-2.5">
                        <p className="font-medium">{a.name}</p>
                        <p className="text-xs text-muted-foreground">{a.group}</p>
                      </td>
                      <td className="px-4 py-2.5 text-xs">
                        {formatDate(a.acquisition_date)}
                      </td>
                      <td className="px-4 py-2.5 text-right tabular-nums">
                        {formatCurrency(a.acquisition_cost)}
                      </td>
                      <td className="px-4 py-2.5 text-right tabular-nums text-muted-foreground">
                        {formatCurrency(a.accumulated_depreciation)}
                      </td>
                      <td className="px-4 py-2.5 text-right font-medium tabular-nums">
                        {formatCurrency(a.book_value)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>
      )}

      {orgId && (
        <AddAssetDialog orgId={orgId} open={addOpen} onOpenChange={setAddOpen} />
      )}
    </div>
  );
}

function SummaryCard({
  label,
  value,
  strong,
}: {
  label: string;
  value: number;
  strong?: boolean;
}) {
  return (
    <Card>
      <CardContent className="p-4">
        <p className="text-xs text-muted-foreground">{label}</p>
        <p
          className={`mt-0.5 font-display tracking-tight ${
            strong ? "text-lg font-bold text-blue-800" : "text-base font-semibold"
          }`}
          title={formatCurrency(value)}
        >
          {formatCompactCurrency(value)}
        </p>
      </CardContent>
    </Card>
  );
}

function AddAssetDialog({
  orgId,
  open,
  onOpenChange,
}: {
  orgId: string;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}) {
  const qc = useQueryClient();
  const today = new Date().toISOString().slice(0, 10);
  const [name, setName] = React.useState("");
  const [group, setGroup] = React.useState("PERLENGKAPAN");
  const [date, setDate] = React.useState(today);
  const [cost, setCost] = React.useState("");

  React.useEffect(() => {
    if (open) {
      setName("");
      setGroup("PERLENGKAPAN");
      setDate(today);
      setCost("");
    }
  }, [open, today]);

  const mut = useMutation({
    mutationFn: () =>
      accountingApi.createFixedAsset(orgId, {
        name: name.trim(),
        group,
        acquisition_date: date,
        acquisition_cost: Number(cost),
      }),
    onSuccess: () => {
      toast.success("Aset ditambahkan");
      qc.invalidateQueries({ queryKey: ["fixed-assets", orgId] });
      onOpenChange(false);
    },
    onError: (err) => toast.error(getApiErrorMessage(err)),
  });

  const submit = () => {
    if (!name.trim()) return toast.error("Isi nama aset");
    if (!(Number(cost) > 0)) return toast.error("Harga perolehan harus > 0");
    mut.mutate();
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>Tambah Aktiva Tetap</DialogTitle>
        </DialogHeader>
        <div className="space-y-4">
          <div>
            <Label htmlFor="aname">Nama Aset</Label>
            <Input
              id="aname"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="mis. Laptop Dell"
            />
          </div>
          <div>
            <Label>Kelompok</Label>
            <Select value={group} onValueChange={setGroup}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {GROUPS.map((g) => (
                  <SelectItem key={g.value} value={g.value}>
                    {g.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <Label htmlFor="adate">Tgl Perolehan</Label>
              <Input
                id="adate"
                type="date"
                value={date}
                onChange={(e) => setDate(e.target.value)}
              />
            </div>
            <div>
              <Label htmlFor="acost">Harga Perolehan</Label>
              <Input
                id="acost"
                inputMode="numeric"
                value={cost}
                onChange={(e) => setCost(e.target.value.replace(/[^0-9.]/g, ""))}
                placeholder="0"
              />
            </div>
          </div>
          {Number(cost) > 0 && (
            <p className="text-xs text-muted-foreground">
              {formatCurrency(Number(cost))}
            </p>
          )}
          <div className="flex justify-end gap-2 pt-1">
            <Button variant="outline" onClick={() => onOpenChange(false)}>
              Batal
            </Button>
            <Button variant="gradient" disabled={mut.isPending} onClick={submit}>
              {mut.isPending ? "Menyimpan..." : "Simpan"}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}

"use client";

import * as React from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Upload, FileSpreadsheet, CheckCircle2, AlertTriangle, Eye } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { accountingApi } from "@/lib/api/accounting";
import { getApiErrorMessage } from "@/lib/api/client";
import { useActiveOrg } from "@/lib/hooks/use-active-org";
import { formatCurrency } from "@/lib/utils";

type ImportResult = Awaited<ReturnType<typeof accountingApi.importHarian>>;

export default function ImportPage() {
  const { org, orgId, canWrite } = useActiveOrg();
  const qc = useQueryClient();
  const [file, setFile] = React.useState<File | null>(null);
  const [sheetName, setSheetName] = React.useState("HARIAN 2025");
  const [preview, setPreview] = React.useState<ImportResult | null>(null);

  const dryRun = useMutation({
    mutationFn: () =>
      accountingApi.importHarian(orgId!, file!, {
        sheet_name: sheetName,
        dry_run: true,
      }),
    onSuccess: (res) => {
      setPreview(res);
      toast.success("Preview berhasil dibuat");
    },
    onError: (err) => toast.error(getApiErrorMessage(err)),
  });

  const doImport = useMutation({
    mutationFn: () =>
      accountingApi.importHarian(orgId!, file!, {
        sheet_name: sheetName,
        dry_run: false,
      }),
    onSuccess: (res) => {
      toast.success(`${res.imported} jurnal berhasil diimport`);
      setPreview(null);
      setFile(null);
      qc.invalidateQueries({ queryKey: ["journal", orgId] });
      qc.invalidateQueries({ queryKey: ["org-dashboard", orgId] });
      qc.invalidateQueries({ queryKey: ["balance-sheet", orgId] });
      qc.invalidateQueries({ queryKey: ["activities", orgId] });
    },
    onError: (err) => toast.error(getApiErrorMessage(err)),
  });

  const onPick = (e: React.ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0] ?? null;
    setFile(f);
    setPreview(null);
  };

  if (!canWrite) {
    return (
      <div className="space-y-6">
        <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
          Import Excel
        </h1>
        <Card>
          <CardContent className="py-12 text-center text-sm text-muted-foreground">
            Anda tidak memiliki akses untuk import data.
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
          Import Excel
        </h1>
        <p className="text-sm text-muted-foreground">
          {org?.name} · Import jurnal dari sheet HARIAN format PDPI
        </p>
      </div>

      {/* Upload box */}
      <Card>
        <CardContent className="space-y-4 p-5">
          <div>
            <Label htmlFor="sheet">Nama Sheet</Label>
            <Input
              id="sheet"
              value={sheetName}
              onChange={(e) => setSheetName(e.target.value)}
              placeholder="HARIAN 2025"
            />
          </div>

          <label className="flex cursor-pointer flex-col items-center gap-2 rounded-xl border-2 border-dashed border-border p-8 text-center transition-colors hover:border-blue-400 hover:bg-accent/30">
            <div className="grid h-12 w-12 place-items-center rounded-xl bg-blue-500/10 text-blue-700">
              <FileSpreadsheet className="h-6 w-6" />
            </div>
            {file ? (
              <p className="font-medium">{file.name}</p>
            ) : (
              <>
                <p className="font-medium">Pilih file Excel (.xlsx)</p>
                <p className="text-xs text-muted-foreground">
                  Format HARIAN PDPI: Tanggal, Uraian, Pemasukan, Pengeluaran, Kategori
                </p>
              </>
            )}
            <input
              type="file"
              accept=".xlsx,.xls"
              className="hidden"
              onChange={onPick}
            />
          </label>

          <div className="flex justify-end gap-2">
            <Button
              variant="outline"
              disabled={!file || dryRun.isPending}
              onClick={() => dryRun.mutate()}
            >
              <Eye className="h-4 w-4" />
              {dryRun.isPending ? "Memproses..." : "Preview (Dry-run)"}
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Preview result */}
      {preview && (
        <Card>
          <CardContent className="space-y-4 p-5">
            <div className="flex items-center gap-2">
              <Eye className="h-4 w-4 text-blue-700" />
              <h2 className="font-display text-base font-semibold">
                Hasil Preview
              </h2>
            </div>

            <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
              <Stat label="Akan diimport" value={String(preview.imported)} />
              <Stat label="Dilewati" value={String(preview.skipped)} />
              <Stat
                label="Total Debit"
                value={formatCurrency(preview.total_debit)}
                small
              />
              <Stat
                label="Total Kredit"
                value={formatCurrency(preview.total_credit)}
                small
              />
            </div>

            {/* Balance check */}
            <div
              className={`flex items-center gap-2 rounded-lg border px-3 py-2 text-sm ${
                preview.total_debit === preview.total_credit
                  ? "border-emerald-200 bg-emerald-50 text-emerald-800"
                  : "border-amber-200 bg-amber-50 text-amber-800"
              }`}
            >
              {preview.total_debit === preview.total_credit ? (
                <CheckCircle2 className="h-4 w-4" />
              ) : (
                <AlertTriangle className="h-4 w-4" />
              )}
              {preview.total_debit === preview.total_credit
                ? "Seimbang — semua transaksi akan menghasilkan jurnal seimbang."
                : "Tidak seimbang — periksa file."}
            </div>

            {/* Unmapped categories */}
            {Object.keys(preview.unmapped).length > 0 && (
              <div className="rounded-lg border border-amber-200 bg-amber-50/60 p-3">
                <p className="text-sm font-medium text-amber-800">
                  Kategori belum dipetakan ({Object.keys(preview.unmapped).length})
                </p>
                <p className="mb-2 text-xs text-amber-700">
                  Transaksi ini tetap diimport ke akun &quot;Lain&quot;.
                </p>
                <div className="flex flex-wrap gap-1.5">
                  {Object.entries(preview.unmapped).map(([cat, count]) => (
                    <span
                      key={cat}
                      className="rounded-full bg-amber-100 px-2 py-0.5 text-xs text-amber-800"
                    >
                      {cat} ({count})
                    </span>
                  ))}
                </div>
              </div>
            )}

            {/* Confirm import */}
            <div className="flex justify-end gap-2 border-t border-border pt-4">
              <Button variant="outline" onClick={() => setPreview(null)}>
                Batal
              </Button>
              <Button
                variant="gradient"
                disabled={doImport.isPending}
                onClick={() => doImport.mutate()}
              >
                <Upload className="h-4 w-4" />
                {doImport.isPending
                  ? "Mengimport..."
                  : `Import ${preview.imported} Jurnal`}
              </Button>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}

function Stat({
  label,
  value,
  small,
}: {
  label: string;
  value: string;
  small?: boolean;
}) {
  return (
    <div className="rounded-lg border border-border p-3">
      <p className="text-xs text-muted-foreground">{label}</p>
      <p
        className={`mt-0.5 font-bold tabular-nums ${
          small ? "text-sm" : "font-display text-xl"
        }`}
      >
        {value}
      </p>
    </div>
  );
}

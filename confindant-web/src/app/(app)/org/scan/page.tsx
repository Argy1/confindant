"use client";

import * as React from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Camera, Loader2, Upload, X } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { transactionsApi } from "@/lib/api/transactions";
import { accountingApi } from "@/lib/api/accounting";
import { getApiErrorMessage } from "@/lib/api/client";
import { AccountSelect } from "@/components/org/account-select";
import { useActiveOrg } from "@/lib/hooks/use-active-org";
import { formatCurrency } from "@/lib/utils";

type OcrJob = {
  id: string;
  status: "pending" | "processing" | "success" | "failed" | string;
  extracted?: {
    merchant_name?: string;
    total_amount?: number | string;
    date?: string;
    category?: string;
    type?: string;
  } | null;
};

export default function OrgScanPage() {
  const { orgId } = useActiveOrg();
  const qc = useQueryClient();

  const [file, setFile] = React.useState<File | null>(null);
  const [preview, setPreview] = React.useState<string | null>(null);
  const [job, setJob] = React.useState<OcrJob | null>(null);
  const [debitAccountId, setDebitAccountId] = React.useState("");
  const [creditAccountId, setCreditAccountId] = React.useState("");
  const [description, setDescription] = React.useState("");

  const { data: accounts } = useQuery({
    queryKey: ["org-accounts", orgId],
    queryFn: () => accountingApi.accounts(orgId!),
    enabled: !!orgId,
  });

  const upload = useMutation({
    mutationFn: (f: File) => transactionsApi.scanUpload(f),
    onSuccess: (j) => {
      setJob(j as unknown as OcrJob);
      toast.info("Struk diupload, sedang diproses…");
    },
    onError: (err) => toast.error(getApiErrorMessage(err, "Upload gagal")),
  });

  // Polling
  React.useEffect(() => {
    if (!job?.id) return;
    if (job.status === "success" || job.status === "failed") return;
    const interval = setInterval(async () => {
      try {
        const updated = await transactionsApi.scanOcrPoll(job.id);
        const u = updated as { status?: string };
        setJob(updated as unknown as OcrJob);
        if (u.status === "success" || u.status === "failed") {
          clearInterval(interval);
        }
      } catch {
        clearInterval(interval);
      }
    }, 2500);
    return () => clearInterval(interval);
  }, [job?.id, job?.status]);

  // Pre-fill description from merchant name
  React.useEffect(() => {
    if (job?.status === "success" && job.extracted?.merchant_name && !description) {
      setDescription(job.extracted.merchant_name);
    }
  }, [job?.status, job?.extracted?.merchant_name, description]);

  const commit = useMutation({
    mutationFn: () => {
      const extracted = job!.extracted ?? {};
      return accountingApi.scanOcrCommitToJournal(orgId!, job!.id, {
        debit_account_id: Number(debitAccountId),
        credit_account_id: Number(creditAccountId),
        amount: Number(extracted.total_amount) || 0,
        date: (extracted.date ?? new Date().toISOString()).slice(0, 10),
        description: description || extracted.merchant_name || "Transaksi dari scan struk",
      });
    },
    onSuccess: () => {
      toast.success("Jurnal berhasil dibuat dari struk");
      qc.invalidateQueries({ queryKey: ["journal", orgId] });
      qc.invalidateQueries({ queryKey: ["org-dashboard", orgId] });
      reset();
    },
    onError: (err) => toast.error(getApiErrorMessage(err, "Gagal membuat jurnal")),
  });

  const onPick = (e: React.ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0];
    if (!f) return;
    setFile(f);
    setPreview(URL.createObjectURL(f));
    setJob(null);
    setDescription("");
  };

  const reset = () => {
    setFile(null);
    setPreview(null);
    setJob(null);
    setDescription("");
    setDebitAccountId("");
    setCreditAccountId("");
  };

  const parsed = job?.extracted ?? null;
  const allAccounts = accounts ?? [];
  const canCommit =
    job?.status === "success" &&
    !!debitAccountId &&
    !!creditAccountId &&
    debitAccountId !== creditAccountId &&
    !commit.isPending;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
          Scan Struk
        </h1>
        <p className="text-sm text-muted-foreground">
          Foto nota/kwitansi → AI baca otomatis → pilih akun → jadi jurnal.
        </p>
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        {/* Upload */}
        <Card>
          <CardContent className="space-y-4 p-5">
            <div className="rounded-xl border-2 border-dashed border-border p-6 text-center">
              {!preview ? (
                <>
                  <div className="mx-auto grid h-14 w-14 place-items-center rounded-full bg-info-bg text-blue-900">
                    <Camera className="h-6 w-6" />
                  </div>
                  <p className="mt-3 font-semibold">Upload foto struk / nota</p>
                  <p className="text-xs text-muted-foreground">
                    JPG/PNG, maksimal 5MB
                  </p>
                  <div className="mt-4">
                    <label className="inline-flex cursor-pointer items-center gap-2 rounded-lg gradient-hero px-4 py-2 text-sm font-medium text-white shadow-sm hover:opacity-95">
                      <Upload className="h-4 w-4" /> Pilih Foto
                      <input
                        type="file"
                        accept="image/*"
                        capture="environment"
                        className="hidden"
                        onChange={onPick}
                      />
                    </label>
                  </div>
                </>
              ) : (
                <div className="relative">
                  <img
                    src={preview}
                    alt="Struk"
                    className="mx-auto max-h-72 rounded-lg object-contain"
                  />
                  <button
                    onClick={reset}
                    className="absolute right-2 top-2 grid h-8 w-8 place-items-center rounded-full bg-card text-muted-foreground shadow"
                    aria-label="Hapus"
                  >
                    <X className="h-4 w-4" />
                  </button>
                </div>
              )}
            </div>

            {file && !job && (
              <Button
                onClick={() => upload.mutate(file)}
                variant="gradient"
                className="w-full"
                loading={upload.isPending}
              >
                Mulai Proses OCR
              </Button>
            )}

            {job && (
              <div className="rounded-lg border border-border p-3 text-sm">
                <div className="flex items-center justify-between">
                  <span className="font-medium">Status OCR</span>
                  <Badge
                    variant={
                      job.status === "success"
                        ? "success"
                        : job.status === "failed"
                        ? "destructive"
                        : "info"
                    }
                  >
                    {job.status === "pending"
                      ? "Antrian"
                      : job.status === "processing"
                      ? "Memproses"
                      : job.status === "success"
                      ? "Selesai"
                      : "Gagal"}
                  </Badge>
                </div>
                {job.status !== "success" && job.status !== "failed" && (
                  <div className="mt-3 flex items-center gap-2 text-xs text-muted-foreground">
                    <Loader2 className="h-3 w-3 animate-spin" />
                    AI sedang membaca struk…
                  </div>
                )}
              </div>
            )}
          </CardContent>
        </Card>

        {/* Hasil + form jurnal */}
        <Card>
          <CardContent className="space-y-4 p-5">
            <h2 className="font-semibold">Hasil & Jurnal</h2>
            {!parsed ? (
              <p className="text-sm text-muted-foreground">
                Upload struk untuk melihat hasil ekstraksi AI di sini.
              </p>
            ) : (
              <>
                <div className="grid gap-3 rounded-lg bg-muted/40 p-3 sm:grid-cols-2">
                  <Field label="Merchant" value={parsed.merchant_name ?? "-"} />
                  <Field
                    label="Total"
                    value={parsed.total_amount ? formatCurrency(Number(parsed.total_amount)) : "-"}
                  />
                  <Field label="Tanggal" value={parsed.date?.slice(0, 10) ?? "-"} />
                  <Field label="Kategori" value={parsed.category ?? "-"} />
                </div>

                <div className="space-y-3 border-t border-border pt-3">
                  <div className="space-y-1.5">
                    <Label>Uraian Jurnal</Label>
                    <Input
                      placeholder="Mis. Pembelian ATK"
                      value={description}
                      onChange={(e) => setDescription(e.target.value)}
                    />
                  </div>

                  <div className="space-y-1.5">
                    <Label>Akun Debit</Label>
                    <AccountSelect
                      accounts={allAccounts}
                      value={debitAccountId}
                      onChange={setDebitAccountId}
                      placeholder="Pilih akun debit (beban/aset)"
                      types={["expense", "asset"]}
                    />
                  </div>

                  <div className="space-y-1.5">
                    <Label>Akun Kredit</Label>
                    <AccountSelect
                      accounts={allAccounts}
                      value={creditAccountId}
                      onChange={setCreditAccountId}
                      placeholder="Pilih akun kredit (kas/hutang)"
                      types={["asset", "liability"]}
                    />
                  </div>

                  {debitAccountId && creditAccountId && debitAccountId === creditAccountId && (
                    <p className="text-xs text-destructive">
                      Akun debit dan kredit tidak boleh sama.
                    </p>
                  )}

                  <Button
                    variant="gradient"
                    className="w-full"
                    onClick={() => commit.mutate()}
                    disabled={!canCommit}
                    loading={commit.isPending}
                  >
                    Buat Jurnal dari Struk
                  </Button>
                </div>
              </>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

function Field({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <p className="text-xs text-muted-foreground">{label}</p>
      <p className="font-medium">{value}</p>
    </div>
  );
}

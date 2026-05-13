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
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { transactionsApi } from "@/lib/api/transactions";
import { walletsApi } from "@/lib/api/wallets";
import { getApiErrorMessage } from "@/lib/api/client";
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
    items?: unknown[];
  } | null;
};

export default function ScanPage() {
  const qc = useQueryClient();
  const [file, setFile] = React.useState<File | null>(null);
  const [preview, setPreview] = React.useState<string | null>(null);
  const [job, setJob] = React.useState<OcrJob | null>(null);
  const [walletId, setWalletId] = React.useState("");
  const [category, setCategory] = React.useState("");
  const [notes, setNotes] = React.useState("");

  const { data: wallets } = useQuery({
    queryKey: ["wallets"],
    queryFn: walletsApi.list,
  });

  const selectedWalletId = walletId || wallets?.[0]?.id || "";

  const upload = useMutation({
    mutationFn: async (f: File) => transactionsApi.scanUpload(f),
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
        setJob(updated as unknown as OcrJob);
        if (
          (updated as { status?: string }).status === "success" ||
          (updated as { status?: string }).status === "failed"
        ) {
          clearInterval(interval);
        }
      } catch {
        clearInterval(interval);
      }
    }, 2500);
    return () => clearInterval(interval);
  }, [job?.id, job?.status]);

  const commit = useMutation({
    mutationFn: () => {
      const extracted = job!.extracted ?? {};
      return transactionsApi.scanOcrCommit(job!.id, {
        wallet_id: selectedWalletId,
        type: (extracted.type as "income" | "expense") || "expense",
        total_amount: Number(extracted.total_amount) || 0,
        date: extracted.date || new Date().toISOString().slice(0, 10),
        merchant_name: extracted.merchant_name || null,
        category: category || extracted.category || null,
        notes: notes || null,
      });
    },
    onSuccess: () => {
      toast.success("Transaksi berhasil dibuat dari struk");
      qc.invalidateQueries({ queryKey: ["transactions"] });
      qc.invalidateQueries({ queryKey: ["dashboard"] });
      qc.invalidateQueries({ queryKey: ["wallets"] });
      reset();
    },
    onError: (err) => toast.error(getApiErrorMessage(err, "Commit gagal")),
  });

  const onPick = (e: React.ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0];
    if (!f) return;
    setFile(f);
    setPreview(URL.createObjectURL(f));
    setJob(null);
  };

  const reset = () => {
    setFile(null);
    setPreview(null);
    setJob(null);
    setNotes("");
    setCategory("");
  };

  const parsed = (job as OcrJob | null)?.extracted ?? null;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
          Scan Struk
        </h1>
        <p className="text-sm text-muted-foreground">
          Foto struk → AI baca otomatis → konfirmasi & jadi transaksi.
        </p>
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <Card>
          <CardContent className="space-y-4 p-5">
            <div className="rounded-xl border-2 border-dashed border-border p-6 text-center">
              {!preview ? (
                <>
                  <div className="mx-auto grid h-14 w-14 place-items-center rounded-full bg-info-bg text-blue-900">
                    <Camera className="h-6 w-6" />
                  </div>
                  <p className="mt-3 font-semibold">Upload foto struk</p>
                  <p className="text-xs text-muted-foreground">
                    JPG/PNG, ukuran maksimal 5MB
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
                  <span className="font-medium">Status</span>
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

        <Card>
          <CardContent className="space-y-4 p-5">
            <h2 className="font-semibold">Hasil ekstraksi</h2>
            {!parsed ? (
              <p className="text-sm text-muted-foreground">
                Upload struk untuk melihat hasil ekstraksi AI di sini.
              </p>
            ) : (
              <>
                <div className="grid gap-3 sm:grid-cols-2">
                  <Field label="Merchant" value={parsed.merchant_name ?? "-"} />
                  <Field
                    label="Total"
                    value={
                      parsed.total_amount
                        ? formatCurrency(Number(parsed.total_amount))
                        : "-"
                    }
                  />
                  <Field label="Tanggal" value={parsed.date ?? "-"} />
                  <Field label="Kategori" value={parsed.category ?? "-"} />
                </div>

                <div className="space-y-3 border-t border-border pt-3">
                  <div className="space-y-1.5">
                    <Label>Wallet</Label>
                    <Select
                      value={selectedWalletId}
                      onValueChange={setWalletId}
                    >
                      <SelectTrigger>
                        <SelectValue placeholder="Pilih wallet" />
                      </SelectTrigger>
                      <SelectContent>
                        {(wallets ?? []).map((w) => (
                          <SelectItem key={w.id} value={w.id}>
                            {w.wallet_name}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-1.5">
                    <Label htmlFor="category">Kategori (override)</Label>
                    <Input
                      id="category"
                      placeholder="Mis. Food & Drink"
                      value={category}
                      onChange={(e) => setCategory(e.target.value)}
                    />
                  </div>
                  <div className="space-y-1.5">
                    <Label htmlFor="notes">Catatan</Label>
                    <Input
                      id="notes"
                      placeholder="Optional"
                      value={notes}
                      onChange={(e) => setNotes(e.target.value)}
                    />
                  </div>

                  <Button
                    variant="gradient"
                    className="w-full"
                    onClick={() => commit.mutate()}
                    disabled={
                      job?.status !== "success" ||
                      !selectedWalletId ||
                      commit.isPending
                    }
                    loading={commit.isPending}
                  >
                    Simpan sebagai Transaksi
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

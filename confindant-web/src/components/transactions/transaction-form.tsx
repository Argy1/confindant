"use client";

import * as React from "react";
import { useForm, Controller } from "react-hook-form";
import { zResolver } from "@/lib/zod-resolver";
import { z } from "zod";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Sparkles, Trash2 } from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
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
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Badge } from "@/components/ui/badge";
import { walletsApi } from "@/lib/api/wallets";
import { transactionsApi } from "@/lib/api/transactions";
import { aiApi } from "@/lib/api/ai";
import { getApiErrorMessage } from "@/lib/api/client";
import type { Transaction, TxType } from "@/lib/types";

const CATEGORY_OPTIONS = {
  expense: [
    "Food & Drink",
    "Groceries",
    "Transportation",
    "Bills",
    "Shopping",
    "Entertainment",
    "Health",
    "Education",
    "Travel",
    "Other",
  ],
  income: ["Salary", "Bonus", "Investment", "Gift", "Refund", "Other"],
};

const schema = z.object({
  type: z.enum(["income", "expense"]),
  wallet_id: z.string().min(1, "Pilih wallet"),
  total_amount: z.coerce
    .number({ message: "Jumlah harus angka" })
    .positive("Jumlah harus > 0"),
  category: z.string().optional().nullable(),
  source: z.string().optional().nullable(),
  merchant_name: z.string().optional().nullable(),
  date: z.string().min(1, "Tanggal wajib"),
  notes: z.string().optional().nullable(),
  tags: z.string().optional().nullable(),
});
type FormVals = z.infer<typeof schema>;

export function TransactionFormDialog({
  open,
  onOpenChange,
  initial,
  defaultType = "expense",
  defaultWalletId,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  initial?: Transaction | null;
  defaultType?: TxType;
  defaultWalletId?: string;
}) {
  const isEdit = !!initial;
  const qc = useQueryClient();

  const { data: wallets } = useQuery({
    queryKey: ["wallets"],
    queryFn: walletsApi.list,
  });

  const today = new Date().toISOString().slice(0, 10);

  const {
    register,
    handleSubmit,
    control,
    watch,
    setValue,
    reset,
    formState: { errors },
  } = useForm<FormVals>({
    resolver: zResolver(schema),
    defaultValues: {
      type: defaultType,
      wallet_id: defaultWalletId ?? "",
      total_amount: 0,
      category: null,
      source: null,
      merchant_name: null,
      date: today,
      notes: null,
      tags: null,
    },
  });

  React.useEffect(() => {
    if (open) {
      if (initial) {
        reset({
          type: initial.type,
          wallet_id: initial.wallet_id,
          total_amount: Number(initial.total_amount),
          category: initial.category ?? null,
          source: initial.source ?? null,
          merchant_name: initial.merchant_name ?? null,
          date: initial.date?.slice(0, 10) ?? today,
          notes: initial.notes ?? null,
          tags: initial.tags?.join(", ") ?? null,
        });
      } else {
        reset({
          type: defaultType,
          wallet_id: defaultWalletId ?? wallets?.[0]?.id ?? "",
          total_amount: 0,
          category: null,
          source: null,
          merchant_name: null,
          date: today,
          notes: null,
          tags: null,
        });
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, initial?.id, defaultType, defaultWalletId, wallets?.length]);

  const type = watch("type");
  const merchant = watch("merchant_name");
  const amount = watch("total_amount");

  const aiCategorize = useMutation({
    mutationFn: () =>
      aiApi.categorize({
        type,
        merchant_name: merchant || null,
        total_amount: Number(amount) || null,
      }),
    onSuccess: ({ result }) => {
      if (result.category) {
        setValue("category", result.category, { shouldDirty: true });
        toast.success(
          `Saran AI: ${result.category} (${Math.round(result.confidence * 100)}%)`,
        );
      }
    },
    onError: (err) =>
      toast.error(getApiErrorMessage(err, "AI categorize gagal")),
  });

  const save = useMutation({
    mutationFn: async (vals: FormVals) => {
      const payload = {
        wallet_id: vals.wallet_id,
        type: vals.type,
        total_amount: Number(vals.total_amount),
        category: vals.category || null,
        source: vals.source || null,
        merchant_name: vals.merchant_name || null,
        date: vals.date,
        notes: vals.notes || null,
        tags: vals.tags
          ? vals.tags
              .split(",")
              .map((t) => t.trim())
              .filter(Boolean)
          : [],
      };
      return isEdit && initial
        ? transactionsApi.update(initial.id, payload)
        : transactionsApi.create(payload);
    },
    onSuccess: () => {
      toast.success(isEdit ? "Transaksi diperbarui" : "Transaksi dibuat");
      qc.invalidateQueries({ queryKey: ["transactions"] });
      qc.invalidateQueries({ queryKey: ["wallets"] });
      qc.invalidateQueries({ queryKey: ["dashboard"] });
      qc.invalidateQueries({ queryKey: ["analytics"] });
      onOpenChange(false);
    },
    onError: (err) =>
      toast.error(getApiErrorMessage(err, "Gagal menyimpan transaksi")),
  });

  const remove = useMutation({
    mutationFn: () => transactionsApi.remove(initial!.id),
    onSuccess: () => {
      toast.success("Transaksi dihapus");
      qc.invalidateQueries({ queryKey: ["transactions"] });
      qc.invalidateQueries({ queryKey: ["wallets"] });
      qc.invalidateQueries({ queryKey: ["dashboard"] });
      qc.invalidateQueries({ queryKey: ["analytics"] });
      onOpenChange(false);
    },
    onError: (err) =>
      toast.error(getApiErrorMessage(err, "Gagal menghapus transaksi")),
  });

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent size="md">
        <DialogHeader>
          <DialogTitle>
            {isEdit ? "Edit Transaksi" : "Tambah Transaksi"}
          </DialogTitle>
          <DialogDescription>
            Catat pengeluaran atau pemasukan kamu. Wallet akan terupdate
            otomatis.
          </DialogDescription>
        </DialogHeader>

        <form
          onSubmit={handleSubmit((v) => save.mutate(v))}
          className="space-y-4"
        >
          {/* Type tabs */}
          <Controller
            control={control}
            name="type"
            render={({ field }) => (
              <Tabs
                value={field.value}
                onValueChange={(v) => field.onChange(v as TxType)}
              >
                <TabsList className="w-full">
                  <TabsTrigger value="expense" className="flex-1">
                    Pengeluaran
                  </TabsTrigger>
                  <TabsTrigger value="income" className="flex-1">
                    Pemasukan
                  </TabsTrigger>
                </TabsList>
              </Tabs>
            )}
          />

          <div className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-1.5">
              <Label htmlFor="wallet_id">Wallet</Label>
              <Controller
                control={control}
                name="wallet_id"
                render={({ field }) => (
                  <Select value={field.value} onValueChange={field.onChange}>
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
                )}
              />
              {errors.wallet_id && (
                <p className="text-xs text-destructive">
                  {errors.wallet_id.message}
                </p>
              )}
            </div>

            <div className="space-y-1.5">
              <Label htmlFor="total_amount">Jumlah (Rp)</Label>
              <Input
                id="total_amount"
                type="number"
                step="any"
                inputMode="decimal"
                placeholder="0"
                {...register("total_amount")}
              />
              {errors.total_amount && (
                <p className="text-xs text-destructive">
                  {errors.total_amount.message}
                </p>
              )}
            </div>
          </div>

          <div className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-1.5">
              <div className="flex items-center justify-between">
                <Label htmlFor="category">Kategori</Label>
                <button
                  type="button"
                  onClick={() => aiCategorize.mutate()}
                  disabled={aiCategorize.isPending}
                  className="inline-flex items-center gap-1 text-xs font-medium text-primary hover:underline disabled:opacity-50"
                >
                  <Sparkles className="h-3 w-3" />
                  {aiCategorize.isPending ? "Memikirkan..." : "Saran AI"}
                </button>
              </div>
              <Controller
                control={control}
                name="category"
                render={({ field }) => (
                  <Select
                    value={field.value ?? ""}
                    onValueChange={(v) => field.onChange(v || null)}
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="Pilih kategori" />
                    </SelectTrigger>
                    <SelectContent>
                      {CATEGORY_OPTIONS[type].map((c) => (
                        <SelectItem key={c} value={c}>
                          {c}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                )}
              />
            </div>

            <div className="space-y-1.5">
              <Label htmlFor="date">Tanggal</Label>
              <Input id="date" type="date" {...register("date")} />
              {errors.date && (
                <p className="text-xs text-destructive">{errors.date.message}</p>
              )}
            </div>
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="merchant_name">
              {type === "expense" ? "Merchant" : "Sumber"}
            </Label>
            <Input
              id="merchant_name"
              placeholder={
                type === "expense" ? "Mis. Indomaret" : "Mis. Kantor X"
              }
              {...register(type === "expense" ? "merchant_name" : "source")}
            />
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="tags">Tags</Label>
            <Input
              id="tags"
              placeholder="Pisahkan dengan koma, mis. coffee, work"
              {...register("tags")}
            />
            <p className="text-xs text-muted-foreground">
              Bisa pakai tag untuk mengelompokkan transaksi.
            </p>
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="notes">Catatan</Label>
            <Textarea
              id="notes"
              rows={3}
              placeholder="Detail tambahan (opsional)"
              {...register("notes")}
            />
          </div>

          {isEdit && initial?.is_internal_transfer ? (
            <div className="rounded-md border border-info-stroke bg-info-bg p-2 text-xs text-blue-900">
              <Badge variant="info">Transfer internal</Badge> Transaksi ini
              bagian dari transfer wallet.
            </div>
          ) : null}

          <DialogFooter className="gap-2">
            {isEdit && (
              <Button
                type="button"
                variant="ghost"
                onClick={() => {
                  if (confirm("Hapus transaksi ini?")) remove.mutate();
                }}
                className="text-destructive hover:text-destructive sm:mr-auto"
                loading={remove.isPending}
              >
                <Trash2 className="h-4 w-4" /> Hapus
              </Button>
            )}
            <Button
              type="button"
              variant="ghost"
              onClick={() => onOpenChange(false)}
            >
              Batal
            </Button>
            <Button type="submit" loading={save.isPending}>
              {isEdit ? "Simpan" : "Tambah"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

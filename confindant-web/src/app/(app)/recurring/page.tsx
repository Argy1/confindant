"use client";

import * as React from "react";
import { useForm } from "react-hook-form";
import { zResolver } from "@/lib/zod-resolver";
import { z } from "zod";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Plus, Repeat, Trash2 } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Skeleton } from "@/components/ui/skeleton";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
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
import { recurringApi } from "@/lib/api/recurring";
import { walletsApi } from "@/lib/api/wallets";
import { getApiErrorMessage } from "@/lib/api/client";
import { formatCurrency, formatDate } from "@/lib/utils";
import type { RecurringTransaction, TxType } from "@/lib/types";

const schema = z.object({
  wallet_id: z.string().min(1),
  type: z.enum(["income", "expense"]),
  amount: z.coerce.number().positive(),
  merchant_name: z.string().optional().nullable(),
  category: z.string().optional().nullable(),
  frequency: z.enum(["daily", "weekly", "monthly"]),
  interval: z.coerce.number().min(1).max(90),
  start_date: z.string().min(1),
  end_date: z.string().optional().nullable(),
  active: z.boolean(),
});
type FormVals = z.infer<typeof schema>;

export default function RecurringPage() {
  const qc = useQueryClient();
  const { data, isLoading } = useQuery({
    queryKey: ["recurring"],
    queryFn: recurringApi.list,
  });

  const [open, setOpen] = React.useState(false);
  const [editing, setEditing] = React.useState<RecurringTransaction | null>(null);

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
            Transaksi Berulang
          </h1>
          <p className="text-sm text-muted-foreground">
            Otomatisasi transaksi rutin seperti gaji, sewa, atau langganan.
          </p>
        </div>
        <Button
          variant="gradient"
          onClick={() => {
            setEditing(null);
            setOpen(true);
          }}
        >
          <Plus className="h-4 w-4" /> Recurring Baru
        </Button>
      </div>

      {isLoading ? (
        <div className="space-y-2">
          {Array.from({ length: 3 }).map((_, i) => (
            <Skeleton key={i} className="h-20 rounded-xl" />
          ))}
        </div>
      ) : (data ?? []).length === 0 ? (
        <Card>
          <CardContent className="grid place-items-center gap-3 py-16 text-center">
            <div className="grid h-14 w-14 place-items-center rounded-full bg-info-bg text-blue-900">
              <Repeat className="h-6 w-6" />
            </div>
            <p className="font-semibold">Belum ada recurring</p>
            <p className="max-w-xs text-sm text-muted-foreground">
              Buat transaksi berulang untuk gaji, sewa, atau pengeluaran rutin.
            </p>
          </CardContent>
        </Card>
      ) : (
        <Card>
          <CardContent className="divide-y divide-border p-0">
            {(data ?? []).map((r) => (
              <button
                key={r.id}
                onClick={() => {
                  setEditing(r);
                  setOpen(true);
                }}
                className="flex w-full items-center gap-3 p-4 text-left transition-colors hover:bg-accent/40"
              >
                <div
                  className={`grid h-10 w-10 shrink-0 place-items-center rounded-lg ${
                    r.type === "expense"
                      ? "bg-rose-500/10 text-rose-600"
                      : "bg-emerald-500/10 text-emerald-600"
                  }`}
                >
                  <Repeat className="h-4 w-4" />
                </div>
                <div className="min-w-0 flex-1">
                  <div className="flex flex-wrap items-center gap-2">
                    <p className="truncate font-medium">
                      {r.merchant_name || r.category || r.source || "Recurring"}
                    </p>
                    <Badge variant={r.active ? "success" : "secondary"}>
                      {r.active ? "Aktif" : "Pause"}
                    </Badge>
                  </div>
                  <p className="text-xs text-muted-foreground">
                    Setiap {r.interval > 1 ? `${r.interval} ` : ""}
                    {r.frequency === "daily"
                      ? "hari"
                      : r.frequency === "weekly"
                      ? "minggu"
                      : "bulan"}{" "}
                    · Berikutnya: {formatDate(r.next_run_at)}
                  </p>
                </div>
                <p
                  className={`shrink-0 font-semibold ${
                    r.type === "income" ? "text-emerald-600" : "text-foreground"
                  }`}
                >
                  {r.type === "expense" ? "-" : "+"}
                  {formatCurrency(r.amount)}
                </p>
              </button>
            ))}
          </CardContent>
        </Card>
      )}

      <RecurringDialog
        open={open}
        onOpenChange={setOpen}
        initial={editing}
        onDelete={async () => {
          if (!editing) return;
          if (!confirm("Hapus recurring ini?")) return;
          try {
            await recurringApi.remove(editing.id);
            toast.success("Recurring dihapus");
            qc.invalidateQueries({ queryKey: ["recurring"] });
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
  initial,
  onDelete,
}: {
  open: boolean;
  onOpenChange: (o: boolean) => void;
  initial: RecurringTransaction | null;
  onDelete: () => void;
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
    reset,
    setValue,
    watch,
    formState: { errors },
  } = useForm<FormVals>({
    resolver: zResolver(schema),
    defaultValues: {
      wallet_id: "",
      type: "expense",
      amount: 0,
      merchant_name: null,
      category: null,
      frequency: "monthly",
      interval: 1,
      start_date: today,
      end_date: null,
      active: true,
    },
  });

  React.useEffect(() => {
    if (open) {
      if (initial) {
        reset({
          wallet_id: initial.wallet_id,
          type: initial.type,
          amount: initial.amount,
          merchant_name: initial.merchant_name ?? null,
          category: initial.category ?? null,
          frequency: initial.frequency,
          interval: initial.interval ?? 1,
          start_date: initial.start_date.slice(0, 10),
          end_date: initial.end_date?.slice(0, 10) ?? null,
          active: initial.active,
        });
      } else {
        reset({
          wallet_id: wallets?.[0]?.id ?? "",
          type: "expense",
          amount: 0,
          merchant_name: null,
          category: null,
          frequency: "monthly",
          interval: 1,
          start_date: today,
          end_date: null,
          active: true,
        });
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, initial?.id, wallets?.length]);

  const save = useMutation({
    mutationFn: (vals: FormVals) =>
      isEdit && initial
        ? recurringApi.update(initial.id, vals as Partial<FormVals>)
        : recurringApi.create({
            ...vals,
            interval: Number(vals.interval),
            amount: Number(vals.amount),
          }),
    onSuccess: () => {
      toast.success(isEdit ? "Diperbarui" : "Dibuat");
      qc.invalidateQueries({ queryKey: ["recurring"] });
      onOpenChange(false);
    },
    onError: (err) => toast.error(getApiErrorMessage(err)),
  });

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent size="md">
        <DialogHeader>
          <DialogTitle>
            {isEdit ? "Edit Recurring" : "Recurring Baru"}
          </DialogTitle>
          <DialogDescription>
            Sistem akan otomatis membuat transaksi sesuai jadwal yang kamu set.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit((v) => save.mutate(v))} className="space-y-4">
          <Tabs
            value={watch("type")}
            onValueChange={(v) => setValue("type", v as TxType)}
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

          <div className="grid gap-3 sm:grid-cols-2">
            <div className="space-y-1.5">
              <Label>Wallet</Label>
              <Select
                value={watch("wallet_id")}
                onValueChange={(v) => setValue("wallet_id", v)}
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
              <Label htmlFor="amount">Jumlah (Rp)</Label>
              <Input
                id="amount"
                type="number"
                step="any"
                {...register("amount")}
              />
              {errors.amount && (
                <p className="text-xs text-destructive">{errors.amount.message}</p>
              )}
            </div>
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="merchant_name">Deskripsi</Label>
            <Input
              id="merchant_name"
              placeholder="Mis. Sewa apartemen"
              {...register("merchant_name")}
            />
          </div>

          <div className="grid gap-3 sm:grid-cols-3">
            <div className="space-y-1.5">
              <Label>Frekuensi</Label>
              <Select
                value={watch("frequency")}
                onValueChange={(v) => setValue("frequency", v as FormVals["frequency"])}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="daily">Harian</SelectItem>
                  <SelectItem value="weekly">Mingguan</SelectItem>
                  <SelectItem value="monthly">Bulanan</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="interval">Interval</Label>
              <Input
                id="interval"
                type="number"
                min={1}
                max={90}
                {...register("interval")}
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="start_date">Mulai</Label>
              <Input id="start_date" type="date" {...register("start_date")} />
            </div>
          </div>

          <div className="grid gap-3 sm:grid-cols-2">
            <div className="space-y-1.5">
              <Label htmlFor="end_date">Berakhir (opsional)</Label>
              <Input id="end_date" type="date" {...register("end_date")} />
            </div>
            <div className="flex items-center justify-between rounded-lg border border-border p-3">
              <div>
                <p className="text-sm font-medium">Aktif</p>
                <p className="text-xs text-muted-foreground">
                  Pause untuk berhenti sementara.
                </p>
              </div>
              <Switch
                checked={watch("active")}
                onCheckedChange={(c) => setValue("active", c)}
              />
            </div>
          </div>

          <DialogFooter className="gap-2">
            {isEdit && (
              <Button
                type="button"
                variant="ghost"
                onClick={onDelete}
                className="text-destructive hover:text-destructive sm:mr-auto"
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
              {isEdit ? "Simpan" : "Buat"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

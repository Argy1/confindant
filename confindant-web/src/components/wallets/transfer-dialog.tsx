"use client";

import * as React from "react";
import { useForm } from "react-hook-form";
import { zResolver } from "@/lib/zod-resolver";
import { z } from "zod";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { ArrowRight } from "lucide-react";
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
import { walletsApi } from "@/lib/api/wallets";
import { getApiErrorMessage } from "@/lib/api/client";

const schema = z
  .object({
    from_wallet_id: z.string().min(1, "Pilih wallet asal"),
    to_wallet_id: z.string().min(1, "Pilih wallet tujuan"),
    amount: z.coerce.number({ message: "Jumlah harus angka" }).positive(),
    notes: z.string().optional().nullable(),
    date: z.string().min(1),
  })
  .refine((d) => d.from_wallet_id !== d.to_wallet_id, {
    message: "Wallet asal & tujuan harus berbeda",
    path: ["to_wallet_id"],
  });
type FormVals = z.infer<typeof schema>;

export function TransferDialog({
  open,
  onOpenChange,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}) {
  const qc = useQueryClient();
  const today = new Date().toISOString().slice(0, 10);

  const { data: wallets } = useQuery({
    queryKey: ["wallets"],
    queryFn: walletsApi.list,
  });

  const {
    register,
    handleSubmit,
    reset,
    setValue,
    watch,
    formState: { errors },
  } = useForm<FormVals>({
    resolver: zResolver(schema),
    defaultValues: { from_wallet_id: "", to_wallet_id: "", amount: 0, notes: null, date: today },
  });

  React.useEffect(() => {
    if (open) reset({ from_wallet_id: "", to_wallet_id: "", amount: 0, notes: null, date: today });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open]);

  const transfer = useMutation({
    mutationFn: (vals: FormVals) =>
      walletsApi.transfer({
        from_wallet_id: vals.from_wallet_id,
        to_wallet_id: vals.to_wallet_id,
        amount: Number(vals.amount),
        notes: vals.notes || null,
        date: vals.date,
      }),
    onSuccess: () => {
      toast.success("Transfer berhasil");
      qc.invalidateQueries({ queryKey: ["wallets"] });
      qc.invalidateQueries({ queryKey: ["transactions"] });
      qc.invalidateQueries({ queryKey: ["dashboard"] });
      onOpenChange(false);
    },
    onError: (err) => toast.error(getApiErrorMessage(err, "Transfer gagal")),
  });

  const fromId = watch("from_wallet_id");

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Transfer antar Wallet</DialogTitle>
          <DialogDescription>
            Sistem akan otomatis mencatat sebagai pengeluaran di wallet asal dan
            pemasukan di wallet tujuan.
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit((v) => transfer.mutate(v))} className="space-y-4">
          <div className="space-y-1.5">
            <Label>Dari</Label>
            <Select
              value={watch("from_wallet_id")}
              onValueChange={(v) => setValue("from_wallet_id", v, { shouldValidate: true })}
            >
              <SelectTrigger>
                <SelectValue placeholder="Pilih wallet asal" />
              </SelectTrigger>
              <SelectContent>
                {(wallets ?? []).map((w) => (
                  <SelectItem key={w.id} value={w.id}>
                    {w.wallet_name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            {errors.from_wallet_id && (
              <p className="text-xs text-destructive">{errors.from_wallet_id.message}</p>
            )}
          </div>

          <div className="flex items-center justify-center text-muted-foreground">
            <ArrowRight className="h-4 w-4" />
          </div>

          <div className="space-y-1.5">
            <Label>Ke</Label>
            <Select
              value={watch("to_wallet_id")}
              onValueChange={(v) => setValue("to_wallet_id", v, { shouldValidate: true })}
            >
              <SelectTrigger>
                <SelectValue placeholder="Pilih wallet tujuan" />
              </SelectTrigger>
              <SelectContent>
                {(wallets ?? []).filter((w) => w.id !== fromId).map((w) => (
                  <SelectItem key={w.id} value={w.id}>
                    {w.wallet_name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            {errors.to_wallet_id && (
              <p className="text-xs text-destructive">{errors.to_wallet_id.message}</p>
            )}
          </div>

          <div className="grid gap-3 sm:grid-cols-2">
            <div className="space-y-1.5">
              <Label htmlFor="amount">Jumlah (Rp)</Label>
              <Input
                id="amount"
                type="number"
                step="any"
                inputMode="decimal"
                {...register("amount")}
              />
              {errors.amount && (
                <p className="text-xs text-destructive">{errors.amount.message}</p>
              )}
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="date">Tanggal</Label>
              <Input id="date" type="date" {...register("date")} />
            </div>
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="notes">Catatan (opsional)</Label>
            <Textarea id="notes" rows={2} {...register("notes")} />
          </div>

          <DialogFooter className="gap-2">
            <Button
              type="button"
              variant="ghost"
              onClick={() => onOpenChange(false)}
            >
              Batal
            </Button>
            <Button type="submit" loading={transfer.isPending}>
              Transfer
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

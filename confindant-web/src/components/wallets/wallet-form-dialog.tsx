"use client";

import * as React from "react";
import { useForm } from "react-hook-form";
import { zResolver } from "@/lib/zod-resolver";
import { z } from "zod";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Trash2 } from "lucide-react";
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
import { walletsApi } from "@/lib/api/wallets";
import { getApiErrorMessage } from "@/lib/api/client";
import type { Wallet } from "@/lib/types";

const COLORS = [
  "#0a2472",
  "#0e6ba8",
  "#16a34a",
  "#f59e0b",
  "#dc2626",
  "#7c3aed",
  "#0891b2",
  "#ea580c",
];

const schema = z.object({
  wallet_name: z.string().min(1, "Nama wallet wajib").max(64),
  balance: z.coerce.number({ message: "Saldo harus angka" }).min(0),
  wallet_color: z.string().nullable(),
});
type FormVals = z.infer<typeof schema>;

export function WalletFormDialog({
  open,
  onOpenChange,
  initial,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  initial?: Wallet | null;
}) {
  const isEdit = !!initial;
  const qc = useQueryClient();

  const {
    register,
    handleSubmit,
    setValue,
    watch,
    reset,
    formState: { errors },
  } = useForm<FormVals>({
    resolver: zResolver(schema),
    defaultValues: {
      wallet_name: "",
      balance: 0,
      wallet_color: COLORS[0],
    },
  });

  const colorVal = watch("wallet_color");

  React.useEffect(() => {
    if (open) {
      if (initial) {
        reset({
          wallet_name: initial.wallet_name,
          balance: Number(initial.balance),
          wallet_color: initial.wallet_color ?? COLORS[0],
        });
      } else {
        reset({ wallet_name: "", balance: 0, wallet_color: COLORS[0] });
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, initial?.id]);

  const save = useMutation({
    mutationFn: (vals: FormVals) =>
      isEdit && initial
        ? walletsApi.update(initial.id, vals)
        : walletsApi.create(vals),
    onSuccess: () => {
      toast.success(isEdit ? "Wallet diperbarui" : "Wallet dibuat");
      qc.invalidateQueries({ queryKey: ["wallets"] });
      qc.invalidateQueries({ queryKey: ["dashboard"] });
      onOpenChange(false);
    },
    onError: (err) =>
      toast.error(getApiErrorMessage(err, "Gagal menyimpan wallet")),
  });

  const remove = useMutation({
    mutationFn: () => walletsApi.remove(initial!.id),
    onSuccess: () => {
      toast.success("Wallet dihapus");
      qc.invalidateQueries({ queryKey: ["wallets"] });
      qc.invalidateQueries({ queryKey: ["dashboard"] });
      onOpenChange(false);
    },
    onError: (err) =>
      toast.error(getApiErrorMessage(err, "Gagal menghapus wallet")),
  });

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{isEdit ? "Edit Wallet" : "Wallet Baru"}</DialogTitle>
          <DialogDescription>
            Beri nama dan warna untuk memudahkan kamu mengenali wallet.
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit((v) => save.mutate(v))} className="space-y-4">
          <div className="space-y-1.5">
            <Label htmlFor="wallet_name">Nama Wallet</Label>
            <Input
              id="wallet_name"
              placeholder="Mis. BCA Tabungan"
              {...register("wallet_name")}
            />
            {errors.wallet_name && (
              <p className="text-xs text-destructive">{errors.wallet_name.message}</p>
            )}
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="balance">
              {isEdit ? "Saldo saat ini" : "Saldo Awal"} (Rp)
            </Label>
            <Input
              id="balance"
              type="number"
              step="any"
              inputMode="decimal"
              {...register("balance")}
            />
            {errors.balance && (
              <p className="text-xs text-destructive">{errors.balance.message}</p>
            )}
          </div>

          <div className="space-y-2">
            <Label>Warna</Label>
            <div className="flex flex-wrap gap-2">
              {COLORS.map((c) => (
                <button
                  type="button"
                  key={c}
                  onClick={() => setValue("wallet_color", c, { shouldDirty: true })}
                  className={`h-8 w-8 rounded-full ring-offset-2 transition-all ${
                    colorVal === c ? "ring-2 ring-blue-600" : ""
                  }`}
                  style={{ backgroundColor: c }}
                  aria-label={`Warna ${c}`}
                />
              ))}
            </div>
          </div>

          <DialogFooter className="gap-2">
            {isEdit && (
              <Button
                type="button"
                variant="ghost"
                onClick={() => {
                  if (
                    confirm(
                      "Hapus wallet ini? Transaksi terkait tetap ada tapi tidak akan terhubung.",
                    )
                  )
                    remove.mutate();
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

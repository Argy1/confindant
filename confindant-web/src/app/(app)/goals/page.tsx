"use client";

import * as React from "react";
import { useForm } from "react-hook-form";
import { zResolver } from "@/lib/zod-resolver";
import { z } from "zod";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Plus, Target, Trash2 } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import { Progress } from "@/components/ui/progress";
import { Skeleton } from "@/components/ui/skeleton";
import { Badge } from "@/components/ui/badge";
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
import { goalsApi } from "@/lib/api/goals";
import { walletsApi } from "@/lib/api/wallets";
import { getApiErrorMessage } from "@/lib/api/client";
import { formatCurrency } from "@/lib/utils";
import type { Goal } from "@/lib/types";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

const goalSchema = z.object({
  name: z.string().min(1).max(120),
  target_amount: z.coerce.number().positive(),
  target_date_label: z.string().min(1),
  linked_wallet: z.string().min(1),
  auto_topup_enabled: z.boolean(),
  auto_topup_percent: z.coerce.number().min(0).max(100).optional(),
});
type GoalForm = z.infer<typeof goalSchema>;

const contribSchema = z.object({
  amount: z.coerce.number().positive(),
  note: z.string().optional().nullable(),
});
type ContribForm = z.infer<typeof contribSchema>;

export default function GoalsPage() {
  const qc = useQueryClient();
  const { data: goals, isLoading } = useQuery({
    queryKey: ["goals"],
    queryFn: goalsApi.list,
  });
  const { data: wallets } = useQuery({
    queryKey: ["wallets"],
    queryFn: walletsApi.list,
  });

  const [open, setOpen] = React.useState(false);
  const [editing, setEditing] = React.useState<Goal | null>(null);
  const [contribFor, setContribFor] = React.useState<Goal | null>(null);

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
            Goals
          </h1>
          <p className="text-sm text-muted-foreground">
            Tetapkan target tabungan dan pantau progress kamu.
          </p>
        </div>
        <Button
          variant="gradient"
          onClick={() => {
            setEditing(null);
            setOpen(true);
          }}
        >
          <Plus className="h-4 w-4" /> Goal Baru
        </Button>
      </div>

      {isLoading ? (
        <div className="grid gap-4 sm:grid-cols-2">
          {Array.from({ length: 2 }).map((_, i) => (
            <Skeleton key={i} className="h-44 rounded-xl" />
          ))}
        </div>
      ) : (goals ?? []).length === 0 ? (
        <Card>
          <CardContent className="grid place-items-center gap-3 py-16 text-center">
            <div className="grid h-14 w-14 place-items-center rounded-full bg-info-bg text-blue-900">
              <Target className="h-6 w-6" />
            </div>
            <p className="font-semibold">Belum ada goal</p>
            <p className="max-w-xs text-sm text-muted-foreground">
              Buat target tabungan pertama kamu — misalnya dana darurat atau
              liburan.
            </p>
            <Button
              variant="gradient"
              onClick={() => {
                setEditing(null);
                setOpen(true);
              }}
            >
              <Plus className="h-4 w-4" /> Buat Goal
            </Button>
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2">
          {(goals ?? []).map((g) => {
            const pct =
              g.target_amount > 0
                ? Math.min(100, (g.current_amount / g.target_amount) * 100)
                : 0;
            return (
              <Card key={g.id} className="overflow-hidden">
                <CardContent className="space-y-3 p-5">
                  <div className="flex items-start justify-between">
                    <div>
                      <p className="font-semibold">{g.name}</p>
                      <p className="text-xs text-muted-foreground">
                        Target: {g.target_date_label} · {g.linked_wallet}
                      </p>
                    </div>
                    {g.auto_topup_enabled && (
                      <Badge variant="info">
                        Auto {Math.round(g.auto_topup_percent ?? 0)}%
                      </Badge>
                    )}
                  </div>
                  <div>
                    <Progress value={pct} indicatorClassName="bg-blue-600" />
                    <div className="mt-1.5 flex items-center justify-between text-xs">
                      <span className="text-muted-foreground">
                        {formatCurrency(g.current_amount)}
                      </span>
                      <span className="font-semibold">
                        {Math.round(pct)}% dari {formatCurrency(g.target_amount)}
                      </span>
                    </div>
                  </div>
                  <div className="flex flex-wrap gap-2">
                    <Button
                      size="sm"
                      onClick={() => setContribFor(g)}
                      variant="gradient"
                    >
                      + Kontribusi
                    </Button>
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => {
                        setEditing(g);
                        setOpen(true);
                      }}
                    >
                      Edit
                    </Button>
                  </div>
                  {g.contributions?.length > 0 && (
                    <div className="border-t border-border pt-3">
                      <p className="text-xs font-medium text-muted-foreground">
                        Riwayat kontribusi
                      </p>
                      <ul className="mt-2 space-y-1 text-xs">
                        {g.contributions.slice(0, 3).map((c, i) => (
                          <li
                            key={i}
                            className="flex items-center justify-between"
                          >
                            <span>{c.date_label}</span>
                            <span className="font-medium">
                              + {formatCurrency(c.amount)}
                            </span>
                          </li>
                        ))}
                      </ul>
                    </div>
                  )}
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}

      <GoalDialog
        open={open}
        onOpenChange={setOpen}
        initial={editing}
        wallets={(wallets ?? []).map((w) => w.wallet_name)}
        onDelete={async () => {
          if (!editing) return;
          if (!confirm("Hapus goal ini?")) return;
          try {
            await goalsApi.remove(editing.id);
            toast.success("Goal dihapus");
            qc.invalidateQueries({ queryKey: ["goals"] });
            setOpen(false);
          } catch (err) {
            toast.error(getApiErrorMessage(err));
          }
        }}
      />

      <ContributionDialog
        goal={contribFor}
        onClose={() => setContribFor(null)}
      />
    </div>
  );
}

function GoalDialog({
  open,
  onOpenChange,
  initial,
  wallets,
  onDelete,
}: {
  open: boolean;
  onOpenChange: (o: boolean) => void;
  initial: Goal | null;
  wallets: string[];
  onDelete: () => void;
}) {
  const isEdit = !!initial;
  const qc = useQueryClient();

  const {
    register,
    handleSubmit,
    reset,
    setValue,
    watch,
    formState: { errors },
  } = useForm<GoalForm>({
    resolver: zResolver(goalSchema),
    defaultValues: {
      name: "",
      target_amount: 0,
      target_date_label: "",
      linked_wallet: wallets[0] ?? "",
      auto_topup_enabled: false,
      auto_topup_percent: 0,
    },
  });

  React.useEffect(() => {
    if (open) {
      if (initial) {
        reset({
          name: initial.name,
          target_amount: initial.target_amount,
          target_date_label: initial.target_date_label,
          linked_wallet: initial.linked_wallet,
          auto_topup_enabled: initial.auto_topup_enabled,
          auto_topup_percent: initial.auto_topup_percent ?? 0,
        });
      } else {
        reset({
          name: "",
          target_amount: 0,
          target_date_label: "",
          linked_wallet: wallets[0] ?? "",
          auto_topup_enabled: false,
          auto_topup_percent: 0,
        });
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, initial?.id]);

  const save = useMutation({
    mutationFn: (vals: GoalForm) =>
      isEdit && initial
        ? goalsApi.update(initial.id, vals)
        : goalsApi.create(vals),
    onSuccess: () => {
      toast.success(isEdit ? "Goal diperbarui" : "Goal dibuat");
      qc.invalidateQueries({ queryKey: ["goals"] });
      onOpenChange(false);
    },
    onError: (err) => toast.error(getApiErrorMessage(err)),
  });

  const enabled = watch("auto_topup_enabled");

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{isEdit ? "Edit Goal" : "Goal Baru"}</DialogTitle>
          <DialogDescription>
            Buat target tabungan dengan opsi auto-topup dari pemasukan.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit((v) => save.mutate(v))} className="space-y-4">
          <div className="space-y-1.5">
            <Label htmlFor="name">Nama Goal</Label>
            <Input
              id="name"
              placeholder="Mis. Dana Darurat"
              {...register("name")}
            />
            {errors.name && (
              <p className="text-xs text-destructive">{errors.name.message}</p>
            )}
          </div>
          <div className="grid gap-3 sm:grid-cols-2">
            <div className="space-y-1.5">
              <Label htmlFor="target_amount">Target (Rp)</Label>
              <Input
                id="target_amount"
                type="number"
                step="any"
                {...register("target_amount")}
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="target_date_label">Target tanggal</Label>
              <Input
                id="target_date_label"
                placeholder="Mis. Dec 2026"
                {...register("target_date_label")}
              />
            </div>
          </div>
          <div className="space-y-1.5">
            <Label>Wallet terhubung</Label>
            <Select
              value={watch("linked_wallet")}
              onValueChange={(v) => setValue("linked_wallet", v)}
            >
              <SelectTrigger>
                <SelectValue placeholder="Pilih wallet" />
              </SelectTrigger>
              <SelectContent>
                {wallets.map((w) => (
                  <SelectItem key={w} value={w}>
                    {w}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="flex items-center justify-between rounded-lg border border-border p-3">
            <div>
              <p className="text-sm font-medium">Auto-topup dari pemasukan</p>
              <p className="text-xs text-muted-foreground">
                Otomatis sisihkan persentase dari setiap pemasukan.
              </p>
            </div>
            <Switch
              checked={enabled}
              onCheckedChange={(c) => setValue("auto_topup_enabled", c)}
            />
          </div>
          {enabled && (
            <div className="space-y-1.5">
              <Label htmlFor="auto_topup_percent">Persentase (%)</Label>
              <Input
                id="auto_topup_percent"
                type="number"
                step="any"
                {...register("auto_topup_percent")}
              />
            </div>
          )}
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

function ContributionDialog({
  goal,
  onClose,
}: {
  goal: Goal | null;
  onClose: () => void;
}) {
  const qc = useQueryClient();
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<ContribForm>({
    resolver: zResolver(contribSchema),
    defaultValues: { amount: 0, note: null },
  });

  React.useEffect(() => {
    if (goal) reset({ amount: 0, note: null });
  }, [goal, reset]);

  const contrib = useMutation({
    mutationFn: (v: ContribForm) =>
      goalsApi.contribute(goal!.id, { amount: Number(v.amount), note: v.note }),
    onSuccess: () => {
      toast.success("Kontribusi tercatat");
      qc.invalidateQueries({ queryKey: ["goals"] });
      onClose();
    },
    onError: (err) => toast.error(getApiErrorMessage(err)),
  });

  return (
    <Dialog open={!!goal} onOpenChange={(o) => !o && onClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Tambah Kontribusi</DialogTitle>
          <DialogDescription>
            Goal: <span className="font-medium">{goal?.name}</span>
          </DialogDescription>
        </DialogHeader>
        <form
          onSubmit={handleSubmit((v) => contrib.mutate(v))}
          className="space-y-4"
        >
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
          <div className="space-y-1.5">
            <Label htmlFor="note">Catatan (opsional)</Label>
            <Textarea id="note" rows={2} {...register("note")} />
          </div>
          <DialogFooter className="gap-2">
            <Button type="button" variant="ghost" onClick={onClose}>
              Batal
            </Button>
            <Button type="submit" loading={contrib.isPending}>
              Tambah
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

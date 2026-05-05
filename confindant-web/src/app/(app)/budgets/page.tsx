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
import { Skeleton } from "@/components/ui/skeleton";
import { Progress } from "@/components/ui/progress";
import { Badge } from "@/components/ui/badge";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { budgetsApi } from "@/lib/api/budgets";
import { dashboardApi } from "@/lib/api/dashboard";
import { getApiErrorMessage } from "@/lib/api/client";
import { formatCurrency } from "@/lib/utils";
import type { Budget } from "@/lib/types";

const schema = z.object({
  category: z.string().min(1).max(64),
  limit_amount: z.coerce.number().positive(),
  period_month: z.string().min(1),
  alert_threshold: z.coerce.number().min(1).max(100),
});
type FormVals = z.infer<typeof schema>;

export default function BudgetsPage() {
  const qc = useQueryClient();
  const { data: budgets, isLoading } = useQuery({
    queryKey: ["budgets"],
    queryFn: budgetsApi.list,
  });
  const { data: dashboard } = useQuery({
    queryKey: ["dashboard"],
    queryFn: dashboardApi.get,
  });

  const usedByCategory = React.useMemo(() => {
    const map = new Map<string, number>();
    for (const b of dashboard?.budget_items ?? []) {
      map.set(b.category, b.used);
    }
    return map;
  }, [dashboard?.budget_items]);

  const [open, setOpen] = React.useState(false);
  const [editing, setEditing] = React.useState<Budget | null>(null);

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
            Budget
          </h1>
          <p className="text-sm text-muted-foreground">
            Set batas pengeluaran per kategori per periode.
          </p>
        </div>
        <Button
          variant="gradient"
          onClick={() => {
            setEditing(null);
            setOpen(true);
          }}
        >
          <Plus className="h-4 w-4" /> Budget Baru
        </Button>
      </div>

      {isLoading ? (
        <div className="grid gap-4 sm:grid-cols-2">
          {Array.from({ length: 2 }).map((_, i) => (
            <Skeleton key={i} className="h-36 rounded-xl" />
          ))}
        </div>
      ) : (budgets ?? []).length === 0 ? (
        <Card>
          <CardContent className="grid place-items-center gap-3 py-16 text-center">
            <div className="grid h-14 w-14 place-items-center rounded-full bg-info-bg text-blue-900">
              <Target className="h-6 w-6" />
            </div>
            <p className="font-semibold">Belum ada budget</p>
            <p className="max-w-xs text-sm text-muted-foreground">
              Set budget per kategori untuk kontrol pengeluaran dan dapatkan
              alert.
            </p>
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2">
          {(budgets ?? []).map((b) => {
            const used = usedByCategory.get(b.category) ?? 0;
            const pct =
              b.limit_amount > 0
                ? Math.min(100, (used / b.limit_amount) * 100)
                : 0;
            const over = pct >= 100;
            const warn = pct >= (b.alert_threshold ?? 80) && !over;
            return (
              <Card key={b.id}>
                <CardContent className="space-y-3 p-5">
                  <div className="flex items-start justify-between">
                    <div>
                      <p className="font-semibold">{b.category}</p>
                      <p className="text-xs text-muted-foreground">
                        {b.period_month} · alert {b.alert_threshold ?? 80}%
                      </p>
                    </div>
                    <Badge
                      variant={over ? "destructive" : warn ? "warning" : "info"}
                    >
                      {Math.round(pct)}%
                    </Badge>
                  </div>
                  <Progress
                    value={pct}
                    indicatorClassName={
                      over ? "bg-destructive" : warn ? "bg-warning" : "bg-blue-600"
                    }
                  />
                  <div className="flex items-center justify-between text-xs">
                    <span className="text-muted-foreground">
                      {formatCurrency(used)}
                    </span>
                    <span className="font-medium">
                      {formatCurrency(b.limit_amount)}
                    </span>
                  </div>
                  <div className="flex justify-end gap-2 pt-1">
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => {
                        setEditing(b);
                        setOpen(true);
                      }}
                    >
                      Edit
                    </Button>
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}

      <BudgetDialog
        open={open}
        onOpenChange={setOpen}
        initial={editing}
        onDelete={async () => {
          if (!editing) return;
          if (!confirm("Hapus budget ini?")) return;
          try {
            await budgetsApi.remove(editing.id);
            toast.success("Budget dihapus");
            qc.invalidateQueries({ queryKey: ["budgets"] });
            setOpen(false);
          } catch (err) {
            toast.error(getApiErrorMessage(err));
          }
        }}
      />
    </div>
  );
}

function BudgetDialog({
  open,
  onOpenChange,
  initial,
  onDelete,
}: {
  open: boolean;
  onOpenChange: (o: boolean) => void;
  initial: Budget | null;
  onDelete: () => void;
}) {
  const isEdit = !!initial;
  const qc = useQueryClient();

  const monthLabel = React.useMemo(() => {
    const d = new Date();
    return d.toLocaleDateString("en-US", { month: "long", year: "numeric" });
  }, []);

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<FormVals>({
    resolver: zResolver(schema),
    defaultValues: {
      category: "",
      limit_amount: 0,
      period_month: monthLabel,
      alert_threshold: 80,
    },
  });

  React.useEffect(() => {
    if (open) {
      if (initial) {
        reset({
          category: initial.category,
          limit_amount: initial.limit_amount,
          period_month: initial.period_month,
          alert_threshold: initial.alert_threshold ?? 80,
        });
      } else {
        reset({
          category: "",
          limit_amount: 0,
          period_month: monthLabel,
          alert_threshold: 80,
        });
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, initial?.id]);

  const save = useMutation({
    mutationFn: (vals: FormVals) =>
      isEdit && initial
        ? budgetsApi.update(initial.id, vals)
        : budgetsApi.create(vals),
    onSuccess: () => {
      toast.success(isEdit ? "Budget diperbarui" : "Budget dibuat");
      qc.invalidateQueries({ queryKey: ["budgets"] });
      onOpenChange(false);
    },
    onError: (err) => toast.error(getApiErrorMessage(err)),
  });

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{isEdit ? "Edit Budget" : "Budget Baru"}</DialogTitle>
          <DialogDescription>
            Kamu akan diberi notifikasi saat pengeluaran mencapai threshold.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit((v) => save.mutate(v))} className="space-y-4">
          <div className="space-y-1.5">
            <Label htmlFor="category">Kategori</Label>
            <Input
              id="category"
              placeholder="Mis. Food & Drink"
              {...register("category")}
            />
            {errors.category && (
              <p className="text-xs text-destructive">{errors.category.message}</p>
            )}
          </div>
          <div className="grid gap-3 sm:grid-cols-2">
            <div className="space-y-1.5">
              <Label htmlFor="limit_amount">Batas (Rp)</Label>
              <Input
                id="limit_amount"
                type="number"
                step="any"
                {...register("limit_amount")}
              />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="alert_threshold">Alert at (%)</Label>
              <Input
                id="alert_threshold"
                type="number"
                min={1}
                max={100}
                {...register("alert_threshold")}
              />
            </div>
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="period_month">Periode</Label>
            <Input
              id="period_month"
              placeholder="Mis. March 2026"
              {...register("period_month")}
            />
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

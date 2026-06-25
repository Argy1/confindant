"use client";

import * as React from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { ArrowDownLeft, ArrowUpRight, Plus, Trash2, SlidersHorizontal, Wand2 } from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectLabel,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { accountingApi } from "@/lib/api/accounting";
import { getApiErrorMessage } from "@/lib/api/client";
import { useAccountsMap } from "@/lib/hooks/use-accounts-map";
import { cn, formatCurrency } from "@/lib/utils";
import type { Account, AccountType } from "@/lib/accounting-types";

type Mode = "simple" | "manual";
type SimpleDirection = "in" | "out";

const TYPE_LABEL: Record<AccountType, string> = {
  asset: "Aset",
  liability: "Kewajiban",
  net_asset: "Aset Bersih",
  revenue: "Pendapatan",
  expense: "Beban",
};

export function JournalFormDialog({
  orgId,
  open,
  onOpenChange,
}: {
  orgId: string;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}) {
  const qc = useQueryClient();
  const { accounts } = useAccountsMap(orgId);
  const [mode, setMode] = React.useState<Mode>("simple");

  const todayStr = React.useMemo(() => new Date().toISOString().slice(0, 10), []);

  // Shared
  const [date, setDate] = React.useState(todayStr);
  const [description, setDescription] = React.useState("");
  const [reference, setReference] = React.useState("");

  // Simple mode
  const [direction, setDirection] = React.useState<SimpleDirection>("out");
  const [cashAccountId, setCashAccountId] = React.useState("");
  const [categoryAccountId, setCategoryAccountId] = React.useState("");
  const [amount, setAmount] = React.useState("");

  // Manual mode
  type ManualLine = { account_id: string; debit: string; credit: string };
  const [lines, setLines] = React.useState<ManualLine[]>([
    { account_id: "", debit: "", credit: "" },
    { account_id: "", debit: "", credit: "" },
  ]);

  const reset = React.useCallback(() => {
    setDate(todayStr);
    setDescription("");
    setReference("");
    setDirection("out");
    setCashAccountId("");
    setCategoryAccountId("");
    setAmount("");
    setLines([
      { account_id: "", debit: "", credit: "" },
      { account_id: "", debit: "", credit: "" },
    ]);
    setMode("simple");
  }, [todayStr]);

  React.useEffect(() => {
    if (open) reset();
  }, [open, reset]);

  // Default cash account = first asset account with code 1-1000 (Kas).
  const cashAccounts = (accounts ?? []).filter((a) => a.type === "asset");
  React.useEffect(() => {
    if (!cashAccountId && cashAccounts.length > 0) {
      const kas = cashAccounts.find((a) => a.code === "1-1000") ?? cashAccounts[0];
      setCashAccountId(kas.id);
    }
  }, [cashAccounts, cashAccountId]);

  const createMut = useMutation({
    mutationFn: (payload: Parameters<typeof accountingApi.journalCreate>[1]) =>
      accountingApi.journalCreate(orgId, payload),
    onSuccess: () => {
      toast.success("Jurnal berhasil disimpan");
      qc.invalidateQueries({ queryKey: ["journal", orgId] });
      qc.invalidateQueries({ queryKey: ["org-dashboard", orgId] });
      qc.invalidateQueries({ queryKey: ["balance-sheet", orgId] });
      qc.invalidateQueries({ queryKey: ["activities", orgId] });
      qc.invalidateQueries({ queryKey: ["trial-balance", orgId] });
      onOpenChange(false);
    },
    onError: (err) => toast.error(getApiErrorMessage(err)),
  });

  // Category options for simple mode depend on direction.
  const categoryAccounts = (accounts ?? []).filter((a) =>
    direction === "in" ? a.type === "revenue" : a.type === "expense",
  );

  const submitSimple = () => {
    const amt = Number(amount);
    if (!description.trim()) return toast.error("Isi uraian transaksi");
    if (!cashAccountId) return toast.error("Pilih akun kas");
    if (!categoryAccountId) return toast.error("Pilih kategori");
    if (!Number.isFinite(amt) || amt <= 0) return toast.error("Nominal harus lebih dari 0");

    const payloadLines =
      direction === "in"
        ? [
            { account_id: cashAccountId, debit: amt },
            { account_id: categoryAccountId, credit: amt },
          ]
        : [
            { account_id: categoryAccountId, debit: amt },
            { account_id: cashAccountId, credit: amt },
          ];

    createMut.mutate({
      date,
      description: description.trim(),
      reference: reference.trim() || null,
      lines: payloadLines,
    });
  };

  // Manual mode totals
  const totalDebit = lines.reduce((s, l) => s + (Number(l.debit) || 0), 0);
  const totalCredit = lines.reduce((s, l) => s + (Number(l.credit) || 0), 0);
  const balanced = Math.abs(totalDebit - totalCredit) < 0.005 && totalDebit > 0;

  const submitManual = () => {
    if (!description.trim()) return toast.error("Isi uraian transaksi");
    const valid = lines.filter(
      (l) => l.account_id && (Number(l.debit) > 0 || Number(l.credit) > 0),
    );
    if (valid.length < 2) return toast.error("Minimal 2 baris dengan akun & nilai");
    if (!balanced) return toast.error("Total debit harus sama dengan total kredit");

    createMut.mutate({
      date,
      description: description.trim(),
      reference: reference.trim() || null,
      lines: valid.map((l) => ({
        account_id: l.account_id,
        debit: Number(l.debit) || 0,
        credit: Number(l.credit) || 0,
      })),
    });
  };

  const updateLine = (i: number, patch: Partial<ManualLine>) => {
    setLines((prev) => prev.map((l, idx) => (idx === i ? { ...l, ...patch } : l)));
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-lg">
        <DialogHeader>
          <DialogTitle>Catat Transaksi</DialogTitle>
        </DialogHeader>

        {/* Mode switch */}
        <div className="flex items-center justify-between rounded-lg border border-border bg-muted/40 p-1">
          <button
            onClick={() => setMode("simple")}
            className={cn(
              "flex flex-1 items-center justify-center gap-1.5 rounded-md py-1.5 text-sm font-medium transition-colors",
              mode === "simple" ? "bg-card shadow-sm" : "text-muted-foreground",
            )}
          >
            <Wand2 className="h-3.5 w-3.5" /> Sederhana
          </button>
          <button
            onClick={() => setMode("manual")}
            className={cn(
              "flex flex-1 items-center justify-center gap-1.5 rounded-md py-1.5 text-sm font-medium transition-colors",
              mode === "manual" ? "bg-card shadow-sm" : "text-muted-foreground",
            )}
          >
            <SlidersHorizontal className="h-3.5 w-3.5" /> Jurnal Manual
          </button>
        </div>

        <div className="max-h-[65vh] space-y-4 overflow-y-auto px-0.5">
          {/* Common fields */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <Label htmlFor="jdate">Tanggal</Label>
              <Input
                id="jdate"
                type="date"
                value={date}
                onChange={(e) => setDate(e.target.value)}
              />
            </div>
            <div>
              <Label htmlFor="jref">No. Bukti (opsional)</Label>
              <Input
                id="jref"
                value={reference}
                onChange={(e) => setReference(e.target.value)}
                placeholder="mis. INV-001"
              />
            </div>
          </div>
          <div>
            <Label htmlFor="jdesc">Uraian</Label>
            <Input
              id="jdesc"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="mis. Iuran ERS dr. Aria"
            />
          </div>

          {mode === "simple" ? (
            <SimpleFields
              direction={direction}
              setDirection={setDirection}
              cashAccounts={cashAccounts}
              cashAccountId={cashAccountId}
              setCashAccountId={setCashAccountId}
              categoryAccounts={categoryAccounts}
              categoryAccountId={categoryAccountId}
              setCategoryAccountId={setCategoryAccountId}
              amount={amount}
              setAmount={setAmount}
            />
          ) : (
            <ManualFields
              accounts={accounts ?? []}
              lines={lines}
              updateLine={updateLine}
              setLines={setLines}
              totalDebit={totalDebit}
              totalCredit={totalCredit}
              balanced={balanced}
            />
          )}
        </div>

        <div className="flex justify-end gap-2 pt-2">
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Batal
          </Button>
          <Button
            variant="gradient"
            disabled={createMut.isPending}
            onClick={mode === "simple" ? submitSimple : submitManual}
          >
            {createMut.isPending ? "Menyimpan..." : "Simpan Jurnal"}
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}

function SimpleFields({
  direction,
  setDirection,
  cashAccounts,
  cashAccountId,
  setCashAccountId,
  categoryAccounts,
  categoryAccountId,
  setCategoryAccountId,
  amount,
  setAmount,
}: {
  direction: SimpleDirection;
  setDirection: (d: SimpleDirection) => void;
  cashAccounts: Account[];
  cashAccountId: string;
  setCashAccountId: (id: string) => void;
  categoryAccounts: Account[];
  categoryAccountId: string;
  setCategoryAccountId: (id: string) => void;
  amount: string;
  setAmount: (v: string) => void;
}) {
  return (
    <div className="space-y-4">
      {/* Direction */}
      <div className="grid grid-cols-2 gap-3">
        <button
          onClick={() => {
            setDirection("in");
            setCategoryAccountId("");
          }}
          className={cn(
            "flex items-center gap-2 rounded-xl border p-3 transition-all",
            direction === "in"
              ? "border-emerald-500 bg-emerald-50 ring-1 ring-emerald-500"
              : "border-border hover:bg-accent/40",
          )}
        >
          <div className="grid h-9 w-9 place-items-center rounded-lg bg-emerald-500 text-white">
            <ArrowDownLeft className="h-4.5 w-4.5" />
          </div>
          <span className="text-sm font-semibold">Terima Uang</span>
        </button>
        <button
          onClick={() => {
            setDirection("out");
            setCategoryAccountId("");
          }}
          className={cn(
            "flex items-center gap-2 rounded-xl border p-3 transition-all",
            direction === "out"
              ? "border-rose-500 bg-rose-50 ring-1 ring-rose-500"
              : "border-border hover:bg-accent/40",
          )}
        >
          <div className="grid h-9 w-9 place-items-center rounded-lg bg-rose-500 text-white">
            <ArrowUpRight className="h-4.5 w-4.5" />
          </div>
          <span className="text-sm font-semibold">Keluar Uang</span>
        </button>
      </div>

      <div>
        <Label>{direction === "in" ? "Sumber / Kategori Pemasukan" : "Kategori Beban"}</Label>
        <Select value={categoryAccountId} onValueChange={setCategoryAccountId}>
          <SelectTrigger>
            <SelectValue placeholder="Pilih kategori" />
          </SelectTrigger>
          <SelectContent>
            {categoryAccounts.map((a) => (
              <SelectItem key={a.id} value={a.id}>
                {a.name}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div>
        <Label>{direction === "in" ? "Masuk ke" : "Dibayar dari"}</Label>
        <Select value={cashAccountId} onValueChange={setCashAccountId}>
          <SelectTrigger>
            <SelectValue placeholder="Pilih akun kas" />
          </SelectTrigger>
          <SelectContent>
            {cashAccounts.map((a) => (
              <SelectItem key={a.id} value={a.id}>
                {a.name}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div>
        <Label htmlFor="jamount">Nominal</Label>
        <Input
          id="jamount"
          inputMode="numeric"
          value={amount}
          onChange={(e) => setAmount(e.target.value.replace(/[^0-9.]/g, ""))}
          placeholder="0"
        />
        {Number(amount) > 0 && (
          <p className="mt-1 text-xs text-muted-foreground">
            {formatCurrency(Number(amount))}
          </p>
        )}
      </div>
    </div>
  );
}

function ManualFields({
  accounts,
  lines,
  updateLine,
  setLines,
  totalDebit,
  totalCredit,
  balanced,
}: {
  accounts: Account[];
  lines: { account_id: string; debit: string; credit: string }[];
  updateLine: (i: number, patch: Partial<{ account_id: string; debit: string; credit: string }>) => void;
  setLines: React.Dispatch<
    React.SetStateAction<{ account_id: string; debit: string; credit: string }[]>
  >;
  totalDebit: number;
  totalCredit: number;
  balanced: boolean;
}) {
  // Group accounts by type for the selector.
  const grouped = React.useMemo(() => {
    const map = new Map<AccountType, Account[]>();
    accounts.forEach((a) => {
      const arr = map.get(a.type) ?? [];
      arr.push(a);
      map.set(a.type, arr);
    });
    return map;
  }, [accounts]);

  return (
    <div className="space-y-2">
      <div className="grid grid-cols-[1fr_auto_auto_auto] items-center gap-2 px-1 text-xs font-medium text-muted-foreground">
        <span>Akun</span>
        <span className="w-24 text-right">Debit</span>
        <span className="w-24 text-right">Kredit</span>
        <span className="w-6" />
      </div>
      {lines.map((line, i) => (
        <div
          key={i}
          className="grid grid-cols-[1fr_auto_auto_auto] items-center gap-2"
        >
          <Select
            value={line.account_id}
            onValueChange={(v) => updateLine(i, { account_id: v })}
          >
            <SelectTrigger className="h-9">
              <SelectValue placeholder="Pilih akun" />
            </SelectTrigger>
            <SelectContent>
              {(["asset", "liability", "net_asset", "revenue", "expense"] as AccountType[]).map(
                (type) => {
                  const items = grouped.get(type);
                  if (!items || items.length === 0) return null;
                  return (
                    <SelectGroup key={type}>
                      <SelectLabel>{TYPE_LABEL[type]}</SelectLabel>
                      {items.map((a) => (
                        <SelectItem key={a.id} value={a.id}>
                          <span className="font-mono text-xs text-muted-foreground">
                            {a.code}
                          </span>{" "}
                          {a.name}
                        </SelectItem>
                      ))}
                    </SelectGroup>
                  );
                },
              )}
            </SelectContent>
          </Select>
          <Input
            className="h-9 w-24 text-right"
            inputMode="numeric"
            value={line.debit}
            onChange={(e) =>
              updateLine(i, {
                debit: e.target.value.replace(/[^0-9.]/g, ""),
                credit: "",
              })
            }
            placeholder="0"
          />
          <Input
            className="h-9 w-24 text-right"
            inputMode="numeric"
            value={line.credit}
            onChange={(e) =>
              updateLine(i, {
                credit: e.target.value.replace(/[^0-9.]/g, ""),
                debit: "",
              })
            }
            placeholder="0"
          />
          <button
            onClick={() =>
              setLines((prev) =>
                prev.length > 2 ? prev.filter((_, idx) => idx !== i) : prev,
              )
            }
            disabled={lines.length <= 2}
            className="grid h-9 w-6 place-items-center text-muted-foreground hover:text-destructive disabled:opacity-30"
            aria-label="Hapus baris"
          >
            <Trash2 className="h-4 w-4" />
          </button>
        </div>
      ))}

      <Button
        type="button"
        variant="outline"
        size="sm"
        className="w-full"
        onClick={() =>
          setLines((prev) => [...prev, { account_id: "", debit: "", credit: "" }])
        }
      >
        <Plus className="h-4 w-4" /> Tambah Baris
      </Button>

      {/* Balance indicator */}
      <div
        className={cn(
          "mt-2 flex items-center justify-between rounded-lg border px-3 py-2 text-sm",
          balanced
            ? "border-emerald-200 bg-emerald-50 text-emerald-800"
            : "border-amber-200 bg-amber-50 text-amber-800",
        )}
      >
        <span className="font-medium">
          {balanced ? "Seimbang ✓" : "Belum seimbang"}
        </span>
        <span className="tabular-nums">
          D {formatCurrency(totalDebit)} · K {formatCurrency(totalCredit)}
        </span>
      </div>
    </div>
  );
}

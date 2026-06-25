"use client";

import * as React from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Plus, HandCoins } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { Progress } from "@/components/ui/progress";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { accountingApi } from "@/lib/api/accounting";
import { getApiErrorMessage } from "@/lib/api/client";
import { useActiveOrg } from "@/lib/hooks/use-active-org";
import { useAccountsMap } from "@/lib/hooks/use-accounts-map";
import { AccountSelect } from "@/components/org/account-select";
import { cn, formatCurrency, formatDate } from "@/lib/utils";
import type { ReceivablePayable } from "@/lib/accounting-types";

type Tab = "receivable" | "payable";

const STATUS_LABEL: Record<string, string> = {
  open: "Belum dibayar",
  partial: "Sebagian",
  settled: "Lunas",
  written_off: "Dihapus",
};

export default function ReceivablesPayablesPage() {
  const { org, orgId, canWrite } = useActiveOrg();
  const [tab, setTab] = React.useState<Tab>("receivable");
  const [addOpen, setAddOpen] = React.useState(false);
  const [settleItem, setSettleItem] = React.useState<ReceivablePayable | null>(null);

  const { data, isLoading } = useQuery({
    queryKey: ["receivables-payables", orgId, tab],
    queryFn: () => accountingApi.receivablesPayables(orgId!, { type: tab }),
    enabled: !!orgId,
  });

  const items = data?.items ?? [];
  const totalOutstanding =
    (data?.meta as { total_outstanding?: number })?.total_outstanding ?? 0;

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
            Piutang & Hutang
          </h1>
          <p className="text-sm text-muted-foreground">{org?.name}</p>
        </div>
        {canWrite && (
          <Button variant="gradient" onClick={() => setAddOpen(true)}>
            <Plus className="h-4 w-4" /> Tambah
          </Button>
        )}
      </div>

      {/* Tabs */}
      <div className="flex items-center rounded-lg border border-border bg-card p-0.5">
        {(["receivable", "payable"] as Tab[]).map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={cn(
              "flex-1 rounded-md py-2 text-sm font-medium transition-colors",
              tab === t ? "bg-accent text-accent-foreground" : "text-muted-foreground",
            )}
          >
            {t === "receivable" ? "Piutang" : "Hutang"}
          </button>
        ))}
      </div>

      {/* Outstanding total */}
      <Card>
        <CardContent className="flex items-center gap-3 p-4">
          <div className="grid h-10 w-10 place-items-center rounded-lg bg-amber-500/10 text-amber-600">
            <HandCoins className="h-5 w-5" />
          </div>
          <div>
            <p className="text-xs text-muted-foreground">
              Total {tab === "receivable" ? "Piutang" : "Hutang"} Belum Selesai
            </p>
            <p className="font-display text-lg font-bold tabular-nums">
              {formatCurrency(totalOutstanding)}
            </p>
          </div>
        </CardContent>
      </Card>

      {isLoading ? (
        <Skeleton className="h-64 rounded-xl" />
      ) : items.length === 0 ? (
        <Card>
          <CardContent className="grid place-items-center gap-2 py-12 text-center">
            <p className="font-semibold">
              Belum ada {tab === "receivable" ? "piutang" : "hutang"}
            </p>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-3">
          {items.map((it) => {
            const pct =
              it.original_amount > 0
                ? (it.settled_amount / it.original_amount) * 100
                : 0;
            return (
              <Card key={it.id}>
                <CardContent className="p-4">
                  <div className="flex items-start justify-between gap-2">
                    <div className="min-w-0">
                      <p className="truncate font-medium">{it.party_name}</p>
                      <p className="text-xs text-muted-foreground">
                        {it.category ?? "—"} · {formatDate(it.issued_date)}
                        {it.period_label ? ` · ${it.period_label}` : ""}
                      </p>
                    </div>
                    <Badge
                      variant={
                        it.status === "settled"
                          ? "success"
                          : it.status === "partial"
                          ? "warning"
                          : "info"
                      }
                    >
                      {STATUS_LABEL[it.status] ?? it.status}
                    </Badge>
                  </div>

                  <div className="mt-3">
                    <Progress value={pct} indicatorClassName="bg-blue-600" />
                    <div className="mt-1.5 flex items-center justify-between text-xs">
                      <span className="text-muted-foreground">
                        Terbayar {formatCurrency(it.settled_amount)}
                      </span>
                      <span className="font-medium">
                        Sisa {formatCurrency(it.outstanding_amount)}
                      </span>
                    </div>
                  </div>

                  {canWrite && it.status !== "settled" && (
                    <div className="mt-3 flex justify-end">
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => setSettleItem(it)}
                      >
                        Catat Pelunasan
                      </Button>
                    </div>
                  )}
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}

      {orgId && (
        <>
          <AddDialog
            orgId={orgId}
            type={tab}
            open={addOpen}
            onOpenChange={setAddOpen}
          />
          <SettleDialog
            orgId={orgId}
            item={settleItem}
            open={!!settleItem}
            onOpenChange={(o) => !o && setSettleItem(null)}
          />
        </>
      )}
    </div>
  );
}

function AddDialog({
  orgId,
  type,
  open,
  onOpenChange,
}: {
  orgId: string;
  type: Tab;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}) {
  const qc = useQueryClient();
  const { accounts } = useAccountsMap(orgId);
  const today = new Date().toISOString().slice(0, 10);

  const [party, setParty] = React.useState("");
  const [category, setCategory] = React.useState("");
  const [accountId, setAccountId] = React.useState("");
  const [counterId, setCounterId] = React.useState("");
  const [amount, setAmount] = React.useState("");
  const [issued, setIssued] = React.useState(today);

  React.useEffect(() => {
    if (open) {
      setParty("");
      setCategory("");
      setAccountId("");
      setCounterId("");
      setAmount("");
      setIssued(today);
    }
  }, [open, today]);

  const mut = useMutation({
    mutationFn: () =>
      accountingApi.createReceivablePayable(orgId, {
        type,
        party_name: party.trim(),
        category: category.trim() || null,
        account_id: accountId,
        counter_account_id: counterId || null,
        original_amount: Number(amount),
        issued_date: issued,
      }),
    onSuccess: () => {
      toast.success(type === "receivable" ? "Piutang dibuat" : "Hutang dibuat");
      qc.invalidateQueries({ queryKey: ["receivables-payables", orgId] });
      onOpenChange(false);
    },
    onError: (err) => toast.error(getApiErrorMessage(err)),
  });

  const submit = () => {
    if (!party.trim()) return toast.error("Isi nama pihak");
    if (!accountId) return toast.error("Pilih akun kontrol");
    if (!(Number(amount) > 0)) return toast.error("Nominal harus > 0");
    mut.mutate();
  };

  // Account hint: receivable control = piutang (asset); payable control = hutang (liability)
  const controlTypes = type === "receivable" ? (["asset"] as const) : (["liability"] as const);
  const counterTypes =
    type === "receivable" ? (["revenue"] as const) : (["expense", "asset"] as const);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>
            Tambah {type === "receivable" ? "Piutang" : "Hutang"}
          </DialogTitle>
        </DialogHeader>
        <div className="space-y-4">
          <div>
            <Label htmlFor="party">
              {type === "receivable" ? "Dari (anggota/cabang)" : "Kepada (vendor/pihak)"}
            </Label>
            <Input
              id="party"
              value={party}
              onChange={(e) => setParty(e.target.value)}
              placeholder="mis. dr. Aria Purnama"
            />
          </div>
          <div>
            <Label htmlFor="cat">Kategori (opsional)</Label>
            <Input
              id="cat"
              value={category}
              onChange={(e) => setCategory(e.target.value)}
              placeholder="mis. Iuran ERS"
            />
          </div>
          <div>
            <Label>Akun {type === "receivable" ? "Piutang" : "Hutang"}</Label>
            <AccountSelect
              accounts={accounts ?? []}
              value={accountId}
              onChange={setAccountId}
              types={[...controlTypes]}
            />
          </div>
          <div>
            <Label>
              Akun Lawan ({type === "receivable" ? "Pendapatan" : "Beban"}) — opsional
            </Label>
            <AccountSelect
              accounts={accounts ?? []}
              value={counterId}
              onChange={setCounterId}
              types={[...counterTypes]}
              placeholder="Pilih agar otomatis dijurnal"
            />
            <p className="mt-1 text-xs text-muted-foreground">
              Jika dipilih, jurnal pembukaan dibuat otomatis.
            </p>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <Label htmlFor="amt">Nominal</Label>
              <Input
                id="amt"
                inputMode="numeric"
                value={amount}
                onChange={(e) => setAmount(e.target.value.replace(/[^0-9.]/g, ""))}
                placeholder="0"
              />
            </div>
            <div>
              <Label htmlFor="iss">Tanggal</Label>
              <Input
                id="iss"
                type="date"
                value={issued}
                onChange={(e) => setIssued(e.target.value)}
              />
            </div>
          </div>
          <div className="flex justify-end gap-2 pt-1">
            <Button variant="outline" onClick={() => onOpenChange(false)}>
              Batal
            </Button>
            <Button variant="gradient" disabled={mut.isPending} onClick={submit}>
              {mut.isPending ? "Menyimpan..." : "Simpan"}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}

function SettleDialog({
  orgId,
  item,
  open,
  onOpenChange,
}: {
  orgId: string;
  item: ReceivablePayable | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}) {
  const qc = useQueryClient();
  const { accounts } = useAccountsMap(orgId);
  const today = new Date().toISOString().slice(0, 10);
  const [amount, setAmount] = React.useState("");
  const [cashId, setCashId] = React.useState("");
  const [date, setDate] = React.useState(today);

  React.useEffect(() => {
    if (open && item) {
      setAmount(String(item.outstanding_amount));
      setDate(today);
      const kas =
        (accounts ?? []).find((a) => a.code === "1-1000") ??
        (accounts ?? []).find((a) => a.type === "asset");
      setCashId(kas?.id ?? "");
    }
  }, [open, item, accounts, today]);

  const mut = useMutation({
    mutationFn: () =>
      accountingApi.settleReceivablePayable(orgId, item!.id, {
        amount: Number(amount),
        cash_account_id: cashId,
        date,
      }),
    onSuccess: () => {
      toast.success("Pelunasan dicatat");
      qc.invalidateQueries({ queryKey: ["receivables-payables", orgId] });
      onOpenChange(false);
    },
    onError: (err) => toast.error(getApiErrorMessage(err)),
  });

  const submit = () => {
    if (!cashId) return toast.error("Pilih akun kas");
    if (!(Number(amount) > 0)) return toast.error("Nominal harus > 0");
    mut.mutate();
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-sm">
        <DialogHeader>
          <DialogTitle>Catat Pelunasan</DialogTitle>
        </DialogHeader>
        {item && (
          <div className="space-y-4">
            <div className="rounded-lg bg-muted/50 p-3 text-sm">
              <p className="font-medium">{item.party_name}</p>
              <p className="text-xs text-muted-foreground">
                Sisa: {formatCurrency(item.outstanding_amount)}
              </p>
            </div>
            <div>
              <Label htmlFor="samt">Jumlah Pelunasan</Label>
              <Input
                id="samt"
                inputMode="numeric"
                value={amount}
                onChange={(e) => setAmount(e.target.value.replace(/[^0-9.]/g, ""))}
              />
            </div>
            <div>
              <Label>Akun Kas</Label>
              <AccountSelect
                accounts={accounts ?? []}
                value={cashId}
                onChange={setCashId}
                types={["asset"]}
              />
            </div>
            <div>
              <Label htmlFor="sdate">Tanggal</Label>
              <Input
                id="sdate"
                type="date"
                value={date}
                onChange={(e) => setDate(e.target.value)}
              />
            </div>
            <div className="flex justify-end gap-2 pt-1">
              <Button variant="outline" onClick={() => onOpenChange(false)}>
                Batal
              </Button>
              <Button variant="gradient" disabled={mut.isPending} onClick={submit}>
                {mut.isPending ? "Menyimpan..." : "Catat"}
              </Button>
            </div>
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}

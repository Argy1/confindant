"use client";

import * as React from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Plus, PiggyBank, ArrowDownLeft, ArrowUpRight } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Dialog,
  DialogContent,
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
import { accountingApi } from "@/lib/api/accounting";
import { getApiErrorMessage } from "@/lib/api/client";
import { useActiveOrg } from "@/lib/hooks/use-active-org";
import { useAccountsMap } from "@/lib/hooks/use-accounts-map";
import { AccountSelect } from "@/components/org/account-select";
import { formatCurrency } from "@/lib/utils";
import type { RestrictedFund } from "@/lib/accounting-types";

const FUND_TYPES = [
  { value: "titipan_cabang", label: "Dana Titipan Cabang" },
  { value: "titipan_kegiatan", label: "Dana Titipan Kegiatan Ilmiah" },
  { value: "shu", label: "SHU" },
];

export default function RestrictedFundsPage() {
  const { org, orgId, canWrite } = useActiveOrg();
  const [addOpen, setAddOpen] = React.useState(false);
  const [moveFund, setMoveFund] = React.useState<RestrictedFund | null>(null);

  const { data, isLoading } = useQuery({
    queryKey: ["restricted-funds", orgId],
    queryFn: () => accountingApi.restrictedFunds(orgId!),
    enabled: !!orgId,
  });

  const funds = data?.funds ?? [];
  const totalBalance =
    (data?.meta as { total_balance?: number })?.total_balance ?? 0;

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
            Dana Titipan
          </h1>
          <p className="text-sm text-muted-foreground">{org?.name}</p>
        </div>
        {canWrite && (
          <Button variant="gradient" onClick={() => setAddOpen(true)}>
            <Plus className="h-4 w-4" /> Tambah Dana
          </Button>
        )}
      </div>

      <Card>
        <CardContent className="flex items-center gap-3 p-4">
          <div className="grid h-10 w-10 place-items-center rounded-lg bg-violet-500/10 text-violet-600">
            <PiggyBank className="h-5 w-5" />
          </div>
          <div>
            <p className="text-xs text-muted-foreground">Total Saldo Dana Titipan</p>
            <p className="font-display text-lg font-bold tabular-nums">
              {formatCurrency(totalBalance)}
            </p>
          </div>
        </CardContent>
      </Card>

      {isLoading ? (
        <Skeleton className="h-64 rounded-xl" />
      ) : funds.length === 0 ? (
        <Card>
          <CardContent className="grid place-items-center gap-2 py-12 text-center">
            <p className="font-semibold">Belum ada dana titipan</p>
            <p className="max-w-xs text-sm text-muted-foreground">
              Tambahkan dana titipan cabang atau kegiatan untuk mulai melacaknya.
            </p>
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-3 sm:grid-cols-2">
          {funds.map((f) => (
            <Card key={f.id}>
              <CardContent className="p-4">
                <p className="font-medium">{f.name}</p>
                <p className="text-xs text-muted-foreground">
                  {FUND_TYPES.find((t) => t.value === f.fund_type)?.label ??
                    f.fund_type ??
                    "—"}
                </p>
                <p className="mt-2 font-display text-xl font-bold tabular-nums">
                  {formatCurrency(f.balance)}
                </p>
                {canWrite && (
                  <div className="mt-3 flex gap-2">
                    <Button
                      size="sm"
                      variant="outline"
                      className="flex-1"
                      onClick={() => setMoveFund(f)}
                    >
                      Catat Pergerakan
                    </Button>
                  </div>
                )}
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {orgId && (
        <>
          <AddFundDialog orgId={orgId} open={addOpen} onOpenChange={setAddOpen} />
          <MoveDialog
            orgId={orgId}
            fund={moveFund}
            open={!!moveFund}
            onOpenChange={(o) => !o && setMoveFund(null)}
          />
        </>
      )}
    </div>
  );
}

function AddFundDialog({
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
  const [name, setName] = React.useState("");
  const [fundType, setFundType] = React.useState("titipan_cabang");
  const [accountId, setAccountId] = React.useState("");

  React.useEffect(() => {
    if (open) {
      setName("");
      setFundType("titipan_cabang");
      // Default to the Dana Titipan Cabang liability account.
      const acc =
        (accounts ?? []).find((a) => a.code === "2-1400") ??
        (accounts ?? []).find((a) => a.type === "liability");
      setAccountId(acc?.id ?? "");
    }
  }, [open, accounts]);

  const mut = useMutation({
    mutationFn: () =>
      accountingApi.createRestrictedFund(orgId, {
        name: name.trim(),
        fund_type: fundType,
        account_id: accountId,
      }),
    onSuccess: () => {
      toast.success("Dana titipan dibuat");
      qc.invalidateQueries({ queryKey: ["restricted-funds", orgId] });
      onOpenChange(false);
    },
    onError: (err) => toast.error(getApiErrorMessage(err)),
  });

  const submit = () => {
    if (!name.trim()) return toast.error("Isi nama dana");
    if (!accountId) return toast.error("Pilih akun kewajiban");
    mut.mutate();
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>Tambah Dana Titipan</DialogTitle>
        </DialogHeader>
        <div className="space-y-4">
          <div>
            <Label htmlFor="fname">Nama Dana</Label>
            <Input
              id="fname"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="mis. Dana Titipan Cabang Jakarta"
            />
          </div>
          <div>
            <Label>Jenis</Label>
            <Select value={fundType} onValueChange={setFundType}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {FUND_TYPES.map((t) => (
                  <SelectItem key={t.value} value={t.value}>
                    {t.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div>
            <Label>Akun Kewajiban</Label>
            <AccountSelect
              accounts={accounts ?? []}
              value={accountId}
              onChange={setAccountId}
              types={["liability"]}
            />
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

function MoveDialog({
  orgId,
  fund,
  open,
  onOpenChange,
}: {
  orgId: string;
  fund: RestrictedFund | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}) {
  const qc = useQueryClient();
  const { accounts } = useAccountsMap(orgId);
  const today = new Date().toISOString().slice(0, 10);
  const [direction, setDirection] = React.useState<"in" | "out">("in");
  const [amount, setAmount] = React.useState("");
  const [cashId, setCashId] = React.useState("");
  const [date, setDate] = React.useState(today);

  React.useEffect(() => {
    if (open) {
      setDirection("in");
      setAmount("");
      setDate(today);
      const kas =
        (accounts ?? []).find((a) => a.code === "1-1000") ??
        (accounts ?? []).find((a) => a.type === "asset");
      setCashId(kas?.id ?? "");
    }
  }, [open, accounts, today]);

  const mut = useMutation({
    mutationFn: () =>
      accountingApi.moveRestrictedFund(orgId, fund!.id, {
        direction,
        amount: Number(amount),
        cash_account_id: cashId,
        date,
      }),
    onSuccess: () => {
      toast.success("Pergerakan dicatat");
      qc.invalidateQueries({ queryKey: ["restricted-funds", orgId] });
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
          <DialogTitle>Pergerakan Dana</DialogTitle>
        </DialogHeader>
        {fund && (
          <div className="space-y-4">
            <div className="rounded-lg bg-muted/50 p-3 text-sm">
              <p className="font-medium">{fund.name}</p>
              <p className="text-xs text-muted-foreground">
                Saldo: {formatCurrency(fund.balance)}
              </p>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <button
                onClick={() => setDirection("in")}
                className={`flex items-center justify-center gap-1.5 rounded-lg border p-2.5 text-sm font-medium transition-all ${
                  direction === "in"
                    ? "border-emerald-500 bg-emerald-50 text-emerald-700"
                    : "border-border text-muted-foreground"
                }`}
              >
                <ArrowDownLeft className="h-4 w-4" /> Masuk
              </button>
              <button
                onClick={() => setDirection("out")}
                className={`flex items-center justify-center gap-1.5 rounded-lg border p-2.5 text-sm font-medium transition-all ${
                  direction === "out"
                    ? "border-rose-500 bg-rose-50 text-rose-700"
                    : "border-border text-muted-foreground"
                }`}
              >
                <ArrowUpRight className="h-4 w-4" /> Keluar
              </button>
            </div>
            <div>
              <Label htmlFor="mamt">Nominal</Label>
              <Input
                id="mamt"
                inputMode="numeric"
                value={amount}
                onChange={(e) => setAmount(e.target.value.replace(/[^0-9.]/g, ""))}
                placeholder="0"
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
              <Label htmlFor="mdate">Tanggal</Label>
              <Input
                id="mdate"
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

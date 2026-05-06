"use client";

import * as React from "react";
import { useQuery } from "@tanstack/react-query";
import {
  ArrowDownRight,
  ArrowUpRight,
  Filter,
  Plus,
  Search,
} from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { transactionsApi } from "@/lib/api/transactions";
import { walletsApi } from "@/lib/api/wallets";
import { formatCurrency, formatDate } from "@/lib/utils";
import { TransactionFormDialog } from "@/components/transactions/transaction-form";
import type { Transaction, TxType } from "@/lib/types";

export default function TransactionsPage() {
  const [type, setType] = React.useState<"all" | TxType>("all");
  const [walletId, setWalletId] = React.useState<string>("all");
  const [q, setQ] = React.useState("");
  const [debouncedQ, setDebouncedQ] = React.useState("");
  const [page, setPage] = React.useState(1);

  React.useEffect(() => {
    const t = setTimeout(() => setDebouncedQ(q), 300);
    return () => clearTimeout(t);
  }, [q]);

  const { data: wallets } = useQuery({
    queryKey: ["wallets"],
    queryFn: walletsApi.list,
  });

  const updateType = (value: string) => {
    setType(value as "all" | TxType);
    setPage(1);
  };

  const updateWalletId = (value: string) => {
    setWalletId(value);
    setPage(1);
  };

  const updateSearch = (event: React.ChangeEvent<HTMLInputElement>) => {
    setQ(event.target.value);
    setPage(1);
  };

  const params = React.useMemo(
    () => ({
      type: type === "all" ? undefined : type,
      wallet_id: walletId === "all" ? undefined : walletId,
      q: debouncedQ || undefined,
      page,
      per_page: 20,
    }),
    [type, walletId, debouncedQ, page],
  );

  const { data, isLoading, isFetching } = useQuery({
    queryKey: ["transactions", params],
    queryFn: () => transactionsApi.list(params),
    placeholderData: (prev) => prev,
  });

  const [open, setOpen] = React.useState(false);
  const [editing, setEditing] = React.useState<Transaction | null>(null);

  const openNew = () => {
    setEditing(null);
    setOpen(true);
  };
  const openEdit = (tx: Transaction) => {
    setEditing(tx);
    setOpen(true);
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
            Transaksi
          </h1>
          <p className="text-sm text-muted-foreground">
            Kelola semua pemasukan & pengeluaran kamu.
          </p>
        </div>
        <Button onClick={openNew} variant="gradient">
          <Plus className="h-4 w-4" /> Tambah
        </Button>
      </div>

      {/* Filters */}
      <Card>
        <CardContent className="space-y-3 p-4 sm:space-y-4">
          <div className="flex flex-wrap items-center gap-3">
            <Tabs value={type} onValueChange={updateType}>
              <TabsList>
                <TabsTrigger value="all">Semua</TabsTrigger>
                <TabsTrigger value="income">Pemasukan</TabsTrigger>
                <TabsTrigger value="expense">Pengeluaran</TabsTrigger>
              </TabsList>
            </Tabs>

            <div className="ml-auto flex flex-wrap items-center gap-2">
              <Select value={walletId} onValueChange={updateWalletId}>
                <SelectTrigger className="h-10 w-[160px]">
                  <Filter className="mr-1 h-4 w-4 opacity-60" />
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Semua wallet</SelectItem>
                  {(wallets ?? []).map((w) => (
                    <SelectItem key={w.id} value={w.id}>
                      {w.wallet_name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="relative">
            <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              placeholder="Cari merchant, kategori, tag, atau catatan…"
              value={q}
              onChange={updateSearch}
              className="pl-10"
            />
          </div>
        </CardContent>
      </Card>

      {/* List */}
      {isLoading ? (
        <div className="space-y-2">
          {Array.from({ length: 8 }).map((_, i) => (
            <Skeleton key={i} className="h-16 rounded-xl" />
          ))}
        </div>
      ) : (data?.data ?? []).length === 0 ? (
        <Card>
          <CardContent className="grid place-items-center gap-3 py-16 text-center">
            <div className="grid h-14 w-14 place-items-center rounded-full bg-info-bg text-blue-900">
              <Search className="h-6 w-6" />
            </div>
            <p className="font-semibold">Tidak ada transaksi</p>
            <p className="max-w-xs text-sm text-muted-foreground">
              Belum ada transaksi yang cocok dengan filter saat ini.
            </p>
            <Button onClick={openNew} variant="gradient">
              <Plus className="h-4 w-4" /> Tambah Transaksi
            </Button>
          </CardContent>
        </Card>
      ) : (
        <Card>
          <CardContent className="divide-y divide-border p-0">
            {data!.data.map((tx) => (
              <button
                key={tx.id}
                onClick={() => openEdit(tx)}
                className="flex w-full items-center gap-3 p-4 text-left transition-colors hover:bg-accent/40"
              >
                <div
                  className={`grid h-10 w-10 shrink-0 place-items-center rounded-lg ${
                    tx.type === "expense"
                      ? "bg-rose-500/10 text-rose-600"
                      : "bg-emerald-500/10 text-emerald-600"
                  }`}
                >
                  {tx.type === "expense" ? (
                    <ArrowDownRight className="h-4 w-4" />
                  ) : (
                    <ArrowUpRight className="h-4 w-4" />
                  )}
                </div>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2">
                    <p className="truncate font-medium">
                      {tx.merchant_name || tx.source || tx.category || "Tanpa nama"}
                    </p>
                    {tx.is_internal_transfer && (
                      <Badge variant="info" className="text-[10px]">
                        Transfer
                      </Badge>
                    )}
                  </div>
                  <div className="mt-0.5 flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
                    <span>{formatDate(tx.date)}</span>
                    {tx.category && <span>· {tx.category}</span>}
                    {(tx.tags ?? []).slice(0, 2).map((t) => (
                      <span
                        key={t}
                        className="rounded-full bg-muted px-2 py-0.5 text-[10px]"
                      >
                        #{t}
                      </span>
                    ))}
                  </div>
                </div>
                <p
                  className={`shrink-0 text-sm font-semibold sm:text-base ${
                    tx.type === "income" ? "text-emerald-600" : "text-foreground"
                  }`}
                >
                  {tx.type === "expense" ? "-" : "+"}
                  {formatCurrency(Math.abs(tx.total_amount))}
                </p>
              </button>
            ))}
          </CardContent>
        </Card>
      )}

      {/* Pagination */}
      {data && data.meta.total > data.meta.per_page && (
        <div className="flex items-center justify-between">
          <p className="text-sm text-muted-foreground">
            Halaman {data.meta.page}
          </p>
          <div className="flex gap-2">
            <Button
              variant="outline"
              size="sm"
              disabled={page <= 1 || isFetching}
              onClick={() => setPage((p) => Math.max(1, p - 1))}
            >
              Sebelumnya
            </Button>
            <Button
              variant="outline"
              size="sm"
              disabled={!data.meta.has_more || isFetching}
              onClick={() => setPage((p) => p + 1)}
            >
              Berikutnya
            </Button>
          </div>
        </div>
      )}

      <TransactionFormDialog
        open={open}
        onOpenChange={setOpen}
        initial={editing}
      />
    </div>
  );
}

"use client";

import * as React from "react";
import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import {
  ArrowDownRight,
  ArrowUpRight,
  Camera,
  Eye,
  EyeOff,
  Plus,
  Sparkles,
  Wallet as WalletIcon,
} from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { Progress } from "@/components/ui/progress";
import { Badge } from "@/components/ui/badge";
import { dashboardApi } from "@/lib/api/dashboard";
import { formatCurrency } from "@/lib/utils";
import { TransactionFormDialog } from "@/components/transactions/transaction-form";
import type { TxType } from "@/lib/types";

export default function HomePage() {
  const { data, isLoading } = useQuery({
    queryKey: ["dashboard"],
    queryFn: dashboardApi.get,
  });

  const [hideBalance, setHideBalance] = React.useState(false);
  const [txOpen, setTxOpen] = React.useState(false);
  const [defaultType, setDefaultType] = React.useState<TxType>("expense");

  const openTx = (type: TxType) => {
    setDefaultType(type);
    setTxOpen(true);
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
          Dashboard
        </h1>
        <p className="text-sm text-muted-foreground">
          Ringkasan keuangan kamu hari ini.
        </p>
      </div>

      {/* Hero balance card */}
      {isLoading ? (
        <Skeleton className="h-44 rounded-2xl" />
      ) : (
        <Card className="overflow-hidden border-0 shadow-lg">
          <div className="relative gradient-hero p-5 text-white sm:p-7">
            <div
              className="pointer-events-none absolute inset-0 opacity-30"
              style={{
                backgroundImage:
                  "radial-gradient(circle at 80% 20%, rgba(255,255,255,0.4), transparent 50%)",
              }}
            />
            <div className="relative">
              <div className="flex items-start justify-between gap-3">
                <div>
                  <p className="text-xs uppercase tracking-wider text-white/70">
                    Total Saldo
                  </p>
                  <p className="mt-1 font-display text-3xl font-bold sm:text-4xl">
                    {hideBalance
                      ? "Rp ••••••"
                      : formatCurrency(data?.summary.balance ?? 0)}
                  </p>
                  <p className="mt-1 text-xs text-white/60">
                    {data?.summary.last_updated_label ?? ""}
                  </p>
                </div>
                <button
                  onClick={() => setHideBalance((v) => !v)}
                  className="grid h-9 w-9 place-items-center rounded-lg bg-white/10 text-white transition-colors hover:bg-white/20"
                  aria-label={hideBalance ? "Tampilkan saldo" : "Sembunyikan saldo"}
                >
                  {hideBalance ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>

              <div className="mt-5 grid grid-cols-2 gap-3">
                <div className="rounded-xl bg-white/10 p-3 backdrop-blur sm:p-4">
                  <div className="flex items-center gap-1 text-xs text-white/70">
                    <ArrowUpRight className="h-3 w-3" /> Pemasukan
                  </div>
                  <p className="mt-1 text-base font-bold sm:text-xl">
                    {formatCurrency(data?.summary.income ?? 0)}
                  </p>
                </div>
                <div className="rounded-xl bg-white/10 p-3 backdrop-blur sm:p-4">
                  <div className="flex items-center gap-1 text-xs text-white/70">
                    <ArrowDownRight className="h-3 w-3" /> Pengeluaran
                  </div>
                  <p className="mt-1 text-base font-bold sm:text-xl">
                    {formatCurrency(data?.summary.expense ?? 0)}
                  </p>
                </div>
              </div>
            </div>
          </div>
        </Card>
      )}

      {/* AI insight */}
      {data?.insight_text && (
        <Card className="border-info-stroke bg-info-bg">
          <CardContent className="flex items-start gap-3 p-4 text-blue-900">
            <Sparkles className="mt-0.5 h-4 w-4 shrink-0" />
            <p className="text-sm">{data.insight_text}</p>
          </CardContent>
        </Card>
      )}

      {/* Quick actions */}
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
        <QuickActionButton
          icon={<ArrowDownRight className="h-5 w-5" />}
          label="Pengeluaran"
          color="from-rose-500 to-rose-600"
          onClick={() => openTx("expense")}
        />
        <QuickActionButton
          icon={<ArrowUpRight className="h-5 w-5" />}
          label="Pemasukan"
          color="from-emerald-500 to-emerald-600"
          onClick={() => openTx("income")}
        />
        <QuickActionButton
          icon={<Camera className="h-5 w-5" />}
          label="Scan Struk"
          color="from-blue-500 to-blue-700"
          href="/scan"
        />
        <QuickActionButton
          icon={<WalletIcon className="h-5 w-5" />}
          label="Wallets"
          color="from-violet-500 to-violet-700"
          href="/wallets"
        />
      </div>

      {/* Budget progress */}
      <section className="grid gap-6 lg:grid-cols-3">
        <div className="lg:col-span-2">
          <SectionHeader title="Recent Transactions" linkLabel="Lihat semua" linkHref="/transactions" />
          {isLoading ? (
            <div className="space-y-2">
              {Array.from({ length: 5 }).map((_, i) => (
                <Skeleton key={i} className="h-16 rounded-xl" />
              ))}
            </div>
          ) : (data?.recent_transactions ?? []).length === 0 ? (
            <EmptyState
              title="Belum ada transaksi"
              desc="Tambahkan transaksi pertama kamu untuk mulai melacak keuangan."
              action={
                <Button onClick={() => openTx("expense")} variant="gradient">
                  <Plus className="h-4 w-4" /> Tambah Transaksi
                </Button>
              }
            />
          ) : (
            <Card>
              <CardContent className="divide-y divide-border p-0">
                {(data?.recent_transactions ?? []).slice(0, 8).map((tx) => (
                  <div
                    key={tx.id}
                    className="flex items-center gap-3 p-4 transition-colors hover:bg-accent/40"
                  >
                    <div
                      className={`grid h-10 w-10 place-items-center rounded-lg ${
                        tx.is_expense
                          ? "bg-rose-500/10 text-rose-600"
                          : "bg-emerald-500/10 text-emerald-600"
                      }`}
                    >
                      {tx.is_expense ? (
                        <ArrowDownRight className="h-4 w-4" />
                      ) : (
                        <ArrowUpRight className="h-4 w-4" />
                      )}
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="truncate font-medium">{tx.title}</p>
                      <p className="truncate text-xs text-muted-foreground">
                        {tx.subtitle}
                      </p>
                    </div>
                    <p
                      className={`shrink-0 text-sm font-semibold sm:text-base ${
                        tx.is_expense ? "text-foreground" : "text-emerald-600"
                      }`}
                    >
                      {tx.is_expense ? "-" : "+"}
                      {formatCurrency(Math.abs(tx.amount))}
                    </p>
                  </div>
                ))}
              </CardContent>
            </Card>
          )}
        </div>

        <div>
          <SectionHeader
            title="Budget"
            linkLabel="Kelola"
            linkHref="/budgets"
          />
          {isLoading ? (
            <Skeleton className="h-44 rounded-xl" />
          ) : (data?.budget_items ?? []).length === 0 ? (
            <EmptyState
              title="Belum ada budget"
              desc="Set budget per kategori untuk kontrol pengeluaran."
              action={
                <Button asChild variant="outline">
                  <Link href="/budgets">
                    <Plus className="h-4 w-4" /> Tambah Budget
                  </Link>
                </Button>
              }
            />
          ) : (
            <Card>
              <CardContent className="space-y-4 p-5">
                {(data?.budget_items ?? []).slice(0, 5).map((b) => {
                  const pct = b.limit > 0 ? Math.min(100, (b.used / b.limit) * 100) : 0;
                  const over = pct >= 100;
                  const warn = pct >= 80 && !over;
                  return (
                    <div key={b.id}>
                      <div className="flex items-center justify-between">
                        <p className="text-sm font-medium">{b.category}</p>
                        <Badge
                          variant={over ? "destructive" : warn ? "warning" : "info"}
                        >
                          {Math.round(pct)}%
                        </Badge>
                      </div>
                      <Progress
                        value={pct}
                        className="mt-2"
                        indicatorClassName={
                          over
                            ? "bg-destructive"
                            : warn
                            ? "bg-warning"
                            : "bg-blue-600"
                        }
                      />
                      <div className="mt-1.5 flex items-center justify-between text-xs text-muted-foreground">
                        <span>{formatCurrency(b.used)}</span>
                        <span>{formatCurrency(b.limit)}</span>
                      </div>
                    </div>
                  );
                })}
              </CardContent>
            </Card>
          )}
        </div>
      </section>

      <TransactionFormDialog
        open={txOpen}
        onOpenChange={setTxOpen}
        defaultType={defaultType}
      />
    </div>
  );
}

function QuickActionButton({
  icon,
  label,
  color,
  onClick,
  href,
}: {
  icon: React.ReactNode;
  label: string;
  color: string;
  onClick?: () => void;
  href?: string;
}) {
  const inner = (
    <div className="group flex items-center gap-3 rounded-xl border border-border bg-card p-3 transition-all hover:-translate-y-0.5 hover:shadow-md sm:p-4">
      <div
        className={`grid h-10 w-10 shrink-0 place-items-center rounded-lg bg-linear-to-br ${color} text-white shadow-sm`}
      >
        {icon}
      </div>
      <span className="text-sm font-semibold">{label}</span>
    </div>
  );
  if (href)
    return (
      <Link href={href} className="text-left">
        {inner}
      </Link>
    );
  return (
    <button onClick={onClick} className="text-left">
      {inner}
    </button>
  );
}

function SectionHeader({
  title,
  linkLabel,
  linkHref,
}: {
  title: string;
  linkLabel?: string;
  linkHref?: string;
}) {
  return (
    <div className="mb-3 flex items-center justify-between">
      <h2 className="font-display text-lg font-semibold">{title}</h2>
      {linkLabel && linkHref && (
        <Link
          href={linkHref}
          className="text-sm font-medium text-primary hover:underline"
        >
          {linkLabel}
        </Link>
      )}
    </div>
  );
}

function EmptyState({
  title,
  desc,
  action,
}: {
  title: string;
  desc: string;
  action?: React.ReactNode;
}) {
  return (
    <Card>
      <CardContent className="grid place-items-center gap-3 py-10 text-center">
        <p className="font-semibold">{title}</p>
        <p className="max-w-xs text-sm text-muted-foreground">{desc}</p>
        {action}
      </CardContent>
    </Card>
  );
}


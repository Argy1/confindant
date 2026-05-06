"use client";

import * as React from "react";
import { useQuery } from "@tanstack/react-query";
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Legend,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { ArrowDown, ArrowUp, TrendingUp } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { analyticsApi } from "@/lib/api/dashboard";
import { walletsApi } from "@/lib/api/wallets";
import { formatCurrency, formatNumber } from "@/lib/utils";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

const PALETTE = [
  "#0a2472",
  "#0e6ba8",
  "#16a34a",
  "#f59e0b",
  "#dc2626",
  "#7c3aed",
  "#0891b2",
  "#ea580c",
  "#9333ea",
  "#059669",
];

export default function AnalyticsPage() {
  const [period, setPeriod] = React.useState<"weekly" | "monthly">("monthly");
  const [walletId, setWalletId] = React.useState("all");

  const { data: wallets } = useQuery({
    queryKey: ["wallets"],
    queryFn: walletsApi.list,
  });

  const params = React.useMemo(
    () => ({
      period,
      wallet_id: walletId === "all" ? undefined : walletId,
    }),
    [period, walletId],
  );

  const { data, isLoading } = useQuery({
    queryKey: ["analytics", params],
    queryFn: () => analyticsApi.get(params),
  });

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
            Analytics
          </h1>
          <p className="text-sm text-muted-foreground">
            Pahami pola pengeluaran kamu dengan visualisasi.
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <Tabs value={period} onValueChange={(v) => setPeriod(v as "weekly" | "monthly")}>
            <TabsList>
              <TabsTrigger value="weekly">Mingguan</TabsTrigger>
              <TabsTrigger value="monthly">Bulanan</TabsTrigger>
            </TabsList>
          </Tabs>
          <Select value={walletId} onValueChange={setWalletId}>
            <SelectTrigger className="h-10 w-[180px]">
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

      {/* Summary cards */}
      <div className="grid gap-3 sm:grid-cols-3">
        <SummaryCard
          label="Pemasukan"
          value={data?.income ?? 0}
          delta={data?.income_vs_previous?.percent_change}
          accent="emerald"
          loading={isLoading}
        />
        <SummaryCard
          label="Pengeluaran"
          value={data?.expense ?? 0}
          delta={data?.expense_vs_previous?.percent_change}
          accent="rose"
          loading={isLoading}
        />
        <SummaryCard
          label="Net Cashflow"
          value={data?.net_cashflow ?? 0}
          accent="blue"
          loading={isLoading}
        />
      </div>

      {/* Charts */}
      <div className="grid gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Tren Harian</CardTitle>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <Skeleton className="h-72 w-full" />
            ) : (data?.daily_breakdown ?? []).length === 0 ? (
              <Empty />
            ) : (
              <div className="h-72 w-full">
                <ResponsiveContainer>
                  <BarChart data={data!.daily_breakdown}>
                    <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
                    <XAxis dataKey="date" tick={{ fontSize: 11 }} />
                    <YAxis
                      tick={{ fontSize: 11 }}
                      tickFormatter={(v) => formatNumber(v / 1000) + "k"}
                    />
                    <Tooltip
                      formatter={(v) => formatCurrency(Number(v))}
                      contentStyle={{
                        borderRadius: 12,
                        border: "1px solid var(--border)",
                      }}
                    />
                    <Legend />
                    <Bar dataKey="income" name="Pemasukan" fill="#16a34a" radius={[4, 4, 0, 0]} />
                    <Bar dataKey="expense" name="Pengeluaran" fill="#dc2626" radius={[4, 4, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Pengeluaran per Kategori</CardTitle>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <Skeleton className="h-72 w-full" />
            ) : (data?.by_category ?? []).length === 0 ? (
              <Empty />
            ) : (
              <div className="grid h-72 grid-cols-1 sm:grid-cols-5">
                <div className="col-span-2 sm:col-span-3">
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie
                        data={data!.by_category}
                        dataKey="amount"
                        nameKey="category"
                        innerRadius={50}
                        outerRadius={90}
                        paddingAngle={2}
                      >
                        {data!.by_category.map((_, i) => (
                          <Cell key={i} fill={PALETTE[i % PALETTE.length]} />
                        ))}
                      </Pie>
                      <Tooltip
                        formatter={(v) => formatCurrency(Number(v))}
                        contentStyle={{
                          borderRadius: 12,
                          border: "1px solid var(--border)",
                        }}
                      />
                    </PieChart>
                  </ResponsiveContainer>
                </div>
                <div className="col-span-2 space-y-2 overflow-y-auto pr-1">
                  {data!.by_category.slice(0, 8).map((c, i) => (
                    <div key={c.category} className="flex items-center gap-2 text-xs">
                      <span
                        className="h-3 w-3 shrink-0 rounded-full"
                        style={{ background: PALETTE[i % PALETTE.length] }}
                      />
                      <span className="min-w-0 flex-1 truncate">{c.category}</span>
                      <span className="font-medium">{Math.round(c.percent)}%</span>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Budget performance */}
      {data?.budget_performance && data.budget_performance.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Performa Budget</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {data.budget_performance.map((b) => {
              const pct = b.budget > 0 ? Math.min(100, (b.spent / b.budget) * 100) : 0;
              return (
                <div key={b.category}>
                  <div className="mb-1 flex items-center justify-between">
                    <p className="font-medium">{b.category}</p>
                    <p className="text-sm text-muted-foreground">
                      {formatCurrency(b.spent)} / {formatCurrency(b.budget)}
                    </p>
                  </div>
                  <div className="h-2 overflow-hidden rounded-full bg-muted">
                    <div
                      className="h-full transition-all"
                      style={{
                        width: `${pct}%`,
                        background:
                          b.status === "exceeded"
                            ? "var(--danger)"
                            : b.status === "warning"
                            ? "var(--warning)"
                            : "var(--blue-600)",
                      }}
                    />
                  </div>
                </div>
              );
            })}
          </CardContent>
        </Card>
      )}
    </div>
  );
}

function SummaryCard({
  label,
  value,
  delta,
  accent,
  loading,
}: {
  label: string;
  value: number;
  delta?: number;
  accent: "emerald" | "rose" | "blue";
  loading?: boolean;
}) {
  if (loading) return <Skeleton className="h-24 rounded-xl" />;
  const accentMap = {
    emerald: "from-emerald-500 to-emerald-700",
    rose: "from-rose-500 to-rose-700",
    blue: "from-blue-700 to-blue-900",
  } as const;
  const positive = (delta ?? 0) >= 0;
  return (
    <Card>
      <CardContent className="p-5">
        <div className="flex items-center justify-between">
          <p className="text-xs uppercase tracking-wider text-muted-foreground">
            {label}
          </p>
          <span
            className={`grid h-8 w-8 place-items-center rounded-lg bg-linear-to-br ${accentMap[accent]} text-white`}
          >
            <TrendingUp className="h-4 w-4" />
          </span>
        </div>
        <p className="mt-2 font-display text-2xl font-bold">
          {formatCurrency(value)}
        </p>
        {delta !== undefined && (
          <p
            className={`mt-1 inline-flex items-center gap-1 text-xs ${
              positive ? "text-emerald-600" : "text-rose-600"
            }`}
          >
            {positive ? (
              <ArrowUp className="h-3 w-3" />
            ) : (
              <ArrowDown className="h-3 w-3" />
            )}
            {Math.abs(delta).toFixed(1)}% vs sebelumnya
          </p>
        )}
      </CardContent>
    </Card>
  );
}

function Empty() {
  return (
    <div className="grid h-72 place-items-center text-sm text-muted-foreground">
      Belum ada data untuk periode ini.
    </div>
  );
}

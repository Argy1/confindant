"use client";

import {
  Area,
  AreaChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import {
  Wallet,
  Landmark,
  Scale,
  TrendingUp,
  ArrowUpRight,
  ArrowDownRight,
} from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { formatCompactCurrency, formatCurrency } from "@/lib/utils";
import type { OrgDashboard } from "@/lib/accounting-types";

/**
 * Variant A: visual summary cards + trend chart. Consistent with the personal
 * home dashboard. Friendly, easy to digest.
 */
export function DashboardVariantCards({ data }: { data: OrgDashboard }) {
  const s = data.summary;
  const cards = [
    {
      label: "Total Aset",
      value: s.total_assets,
      icon: Landmark,
      color: "from-blue-500 to-blue-700",
    },
    {
      label: "Kas & Setara Kas",
      value: s.cash,
      icon: Wallet,
      color: "from-emerald-500 to-emerald-700",
    },
    {
      label: "Aset Bersih",
      value: s.total_net_assets,
      icon: Scale,
      color: "from-violet-500 to-violet-700",
    },
    {
      label: "Surplus Tahun Ini",
      value: s.change_in_net_assets,
      icon: TrendingUp,
      color: "from-amber-500 to-amber-600",
    },
  ];

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        {cards.map((c) => (
          <Card key={c.label} className="overflow-hidden">
            <CardContent className="p-4">
              <div
                className={`mb-3 grid h-10 w-10 place-items-center rounded-lg bg-linear-to-br ${c.color} text-white shadow-sm`}
              >
                <c.icon className="h-5 w-5" />
              </div>
              <p className="text-xs text-muted-foreground">{c.label}</p>
              <p
                className="mt-0.5 font-display text-lg font-bold tracking-tight sm:text-xl"
                title={formatCurrency(c.value)}
              >
                {formatCompactCurrency(c.value)}
              </p>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid gap-6 lg:grid-cols-3">
        {/* Trend chart */}
        <Card className="lg:col-span-2">
          <CardContent className="p-5">
            <div className="mb-4 flex items-center justify-between">
              <h2 className="font-display text-lg font-semibold">
                Tren Pemasukan vs Beban {data.year}
              </h2>
            </div>
            <div className="h-64 w-full">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={data.monthly_trend}>
                  <defs>
                    <linearGradient id="rev" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#10b981" stopOpacity={0.3} />
                      <stop offset="95%" stopColor="#10b981" stopOpacity={0} />
                    </linearGradient>
                    <linearGradient id="exp" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#f43f5e" stopOpacity={0.3} />
                      <stop offset="95%" stopColor="#f43f5e" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" vertical={false} />
                  <XAxis dataKey="label" tick={{ fontSize: 12 }} tickLine={false} axisLine={false} />
                  <YAxis
                    tick={{ fontSize: 11 }}
                    tickLine={false}
                    axisLine={false}
                    tickFormatter={(v) => formatCompactCurrency(v).replace("Rp ", "")}
                    width={50}
                  />
                  <Tooltip
                    formatter={(v) => formatCurrency(Number(v))}
                    labelStyle={{ fontWeight: 600 }}
                    contentStyle={{ borderRadius: 12, fontSize: 13 }}
                  />
                  <Area
                    type="monotone"
                    dataKey="revenue"
                    name="Pemasukan"
                    stroke="#10b981"
                    fill="url(#rev)"
                    strokeWidth={2}
                  />
                  <Area
                    type="monotone"
                    dataKey="expense"
                    name="Beban"
                    stroke="#f43f5e"
                    fill="url(#exp)"
                    strokeWidth={2}
                  />
                </AreaChart>
              </ResponsiveContainer>
            </div>
            <div className="mt-3 flex items-center gap-4 text-xs">
              <span className="flex items-center gap-1.5">
                <span className="h-2.5 w-2.5 rounded-full bg-emerald-500" /> Pemasukan
              </span>
              <span className="flex items-center gap-1.5">
                <span className="h-2.5 w-2.5 rounded-full bg-rose-500" /> Beban
              </span>
            </div>
          </CardContent>
        </Card>

        {/* Revenue vs expense summary */}
        <Card>
          <CardContent className="space-y-4 p-5">
            <h2 className="font-display text-lg font-semibold">Ringkasan {data.year}</h2>
            <div className="rounded-xl bg-emerald-500/10 p-4">
              <div className="flex items-center gap-1.5 text-xs text-emerald-700">
                <ArrowUpRight className="h-3.5 w-3.5" /> Total Pemasukan
              </div>
              <p className="mt-1 font-display text-xl font-bold text-emerald-700">
                {formatCurrency(s.total_revenue)}
              </p>
            </div>
            <div className="rounded-xl bg-rose-500/10 p-4">
              <div className="flex items-center gap-1.5 text-xs text-rose-700">
                <ArrowDownRight className="h-3.5 w-3.5" /> Total Beban
              </div>
              <p className="mt-1 font-display text-xl font-bold text-rose-700">
                {formatCurrency(s.total_expense)}
              </p>
            </div>
            <div className="rounded-xl border border-border p-4">
              <p className="text-xs text-muted-foreground">
                Kenaikan Aset Bersih
              </p>
              <p
                className={`mt-1 font-display text-xl font-bold ${
                  s.change_in_net_assets >= 0 ? "text-blue-700" : "text-rose-700"
                }`}
              >
                {formatCurrency(s.change_in_net_assets)}
              </p>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Top accounts */}
      <div className="grid gap-6 lg:grid-cols-2">
        <TopAccountsCard
          title="Beban Terbesar"
          accounts={data.top_expense_accounts}
          color="bg-rose-500"
        />
        <TopAccountsCard
          title="Pemasukan Terbesar"
          accounts={data.top_revenue_accounts}
          color="bg-emerald-500"
        />
      </div>
    </div>
  );
}

function TopAccountsCard({
  title,
  accounts,
  color,
}: {
  title: string;
  accounts: { code: string; name: string; amount: number }[];
  color: string;
}) {
  const max = Math.max(1, ...accounts.map((a) => a.amount));
  return (
    <Card>
      <CardContent className="p-5">
        <h2 className="mb-4 font-display text-lg font-semibold">{title}</h2>
        {accounts.length === 0 ? (
          <p className="py-6 text-center text-sm text-muted-foreground">
            Belum ada data
          </p>
        ) : (
          <div className="space-y-3">
            {accounts.map((a) => (
              <div key={a.code}>
                <div className="flex items-center justify-between text-sm">
                  <span className="truncate pr-2">{a.name}</span>
                  <span className="shrink-0 font-medium">
                    {formatCurrency(a.amount)}
                  </span>
                </div>
                <div className="mt-1.5 h-1.5 w-full overflow-hidden rounded-full bg-muted">
                  <div
                    className={`h-full rounded-full ${color}`}
                    style={{ width: `${(a.amount / max) * 100}%` }}
                  />
                </div>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}

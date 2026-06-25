"use client";

import Link from "next/link";
import { CheckCircle2, AlertTriangle } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { formatCurrency } from "@/lib/utils";
import type { OrgDashboard } from "@/lib/accounting-types";

/**
 * Variant B: dense, numbers-first layout like Accurate/Kledo. For treasurers
 * who want figures fast without much visual chrome.
 */
export function DashboardVariantDense({ data }: { data: OrgDashboard }) {
  const s = data.summary;

  const balanceRows = [
    { label: "Total Aset", value: s.total_assets, strong: true },
    { label: "Total Kewajiban", value: s.total_liabilities },
    { label: "Total Aset Bersih", value: s.total_net_assets, strong: true },
  ];

  const activityRows = [
    { label: "Total Pemasukan", value: s.total_revenue, tone: "pos" as const },
    { label: "Total Beban", value: s.total_expense, tone: "neg" as const },
    {
      label: "Kenaikan (Penurunan) Aset Bersih",
      value: s.change_in_net_assets,
      strong: true,
      tone: s.change_in_net_assets >= 0 ? ("pos" as const) : ("neg" as const),
    },
  ];

  return (
    <div className="space-y-5">
      {/* Balance status banner */}
      <div
        className={`flex items-center gap-2 rounded-lg border px-4 py-2.5 text-sm ${
          data.is_balanced
            ? "border-emerald-200 bg-emerald-50 text-emerald-800"
            : "border-amber-200 bg-amber-50 text-amber-800"
        }`}
      >
        {data.is_balanced ? (
          <CheckCircle2 className="h-4 w-4" />
        ) : (
          <AlertTriangle className="h-4 w-4" />
        )}
        {data.is_balanced
          ? "Pembukuan seimbang — Aset = Kewajiban + Aset Bersih."
          : "Perhatian: pembukuan belum seimbang. Periksa jurnal."}
      </div>

      <div className="grid gap-5 lg:grid-cols-2">
        {/* Neraca ringkas */}
        <Card>
          <CardContent className="p-0">
            <div className="flex items-center justify-between border-b border-border px-5 py-3">
              <h2 className="font-display text-base font-semibold">
                Posisi Keuangan
              </h2>
              <Link
                href="/org/reports/balance-sheet"
                className="text-xs font-medium text-primary hover:underline"
              >
                Lihat Neraca
              </Link>
            </div>
            <table className="w-full text-sm">
              <tbody>
                {balanceRows.map((r) => (
                  <tr
                    key={r.label}
                    className="border-b border-border/60 last:border-0"
                  >
                    <td className="px-5 py-3 text-muted-foreground">
                      {r.label}
                    </td>
                    <td
                      className={`px-5 py-3 text-right tabular-nums ${
                        r.strong ? "font-bold" : "font-medium"
                      }`}
                    >
                      {formatCurrency(r.value)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </CardContent>
        </Card>

        {/* Aktivitas ringkas */}
        <Card>
          <CardContent className="p-0">
            <div className="flex items-center justify-between border-b border-border px-5 py-3">
              <h2 className="font-display text-base font-semibold">
                Aktivitas {data.year}
              </h2>
              <Link
                href="/org/reports/activities"
                className="text-xs font-medium text-primary hover:underline"
              >
                Lihat Laporan
              </Link>
            </div>
            <table className="w-full text-sm">
              <tbody>
                {activityRows.map((r) => (
                  <tr
                    key={r.label}
                    className="border-b border-border/60 last:border-0"
                  >
                    <td className="px-5 py-3 text-muted-foreground">
                      {r.label}
                    </td>
                    <td
                      className={`px-5 py-3 text-right tabular-nums ${
                        r.strong ? "font-bold" : "font-medium"
                      } ${
                        r.tone === "pos"
                          ? "text-emerald-700"
                          : r.tone === "neg"
                          ? "text-rose-700"
                          : ""
                      }`}
                    >
                      {formatCurrency(r.value)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </CardContent>
        </Card>
      </div>

      {/* Top accounts side by side, dense table */}
      <div className="grid gap-5 lg:grid-cols-2">
        <DenseAccountTable title="Beban Terbesar" rows={data.top_expense_accounts} />
        <DenseAccountTable
          title="Pemasukan Terbesar"
          rows={data.top_revenue_accounts}
        />
      </div>
    </div>
  );
}

function DenseAccountTable({
  title,
  rows,
}: {
  title: string;
  rows: { code: string; name: string; amount: number }[];
}) {
  return (
    <Card>
      <CardContent className="p-0">
        <div className="border-b border-border px-5 py-3">
          <h2 className="font-display text-base font-semibold">{title}</h2>
        </div>
        {rows.length === 0 ? (
          <p className="px-5 py-6 text-center text-sm text-muted-foreground">
            Belum ada data
          </p>
        ) : (
          <table className="w-full text-sm">
            <tbody>
              {rows.map((r) => (
                <tr
                  key={r.code}
                  className="border-b border-border/60 last:border-0"
                >
                  <td className="px-5 py-2.5 font-mono text-xs text-muted-foreground">
                    {r.code}
                  </td>
                  <td className="py-2.5 pr-3">{r.name}</td>
                  <td className="px-5 py-2.5 text-right font-medium tabular-nums">
                    {formatCurrency(r.amount)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </CardContent>
    </Card>
  );
}

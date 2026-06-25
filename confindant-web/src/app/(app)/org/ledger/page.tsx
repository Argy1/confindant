"use client";

import * as React from "react";
import { useQuery } from "@tanstack/react-query";
import { Card, CardContent } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
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
import { useActiveOrg } from "@/lib/hooks/use-active-org";
import { useAccountsMap } from "@/lib/hooks/use-accounts-map";
import { YearSelect } from "@/components/org/year-select";
import { formatCurrency, formatDate } from "@/lib/utils";
import type { AccountType } from "@/lib/accounting-types";

const TYPE_LABEL: Record<AccountType, string> = {
  asset: "Aset",
  liability: "Kewajiban",
  net_asset: "Aset Bersih",
  revenue: "Pendapatan",
  expense: "Beban",
};

export default function LedgerPage() {
  const { org, orgId } = useActiveOrg();
  const { accounts } = useAccountsMap(orgId);
  const [year, setYear] = React.useState(new Date().getFullYear());
  const [accountId, setAccountId] = React.useState<string>("");

  const from = `${year}-01-01`;
  const to = `${year}-12-31`;

  // Default to Kas (1-1000) once accounts load.
  React.useEffect(() => {
    if (!accountId && accounts && accounts.length > 0) {
      const kas = accounts.find((a) => a.code === "1-1000") ?? accounts[0];
      setAccountId(kas.id);
    }
  }, [accounts, accountId]);

  const grouped = React.useMemo(() => {
    const map = new Map<AccountType, typeof accounts>();
    (accounts ?? []).forEach((a) => {
      const arr = map.get(a.type) ?? [];
      arr!.push(a);
      map.set(a.type, arr);
    });
    return map;
  }, [accounts]);

  const { data, isLoading } = useQuery({
    queryKey: ["ledger-page", orgId, accountId, from, to],
    queryFn: () =>
      accountingApi.generalLedger(orgId!, accountId, {
        from_date: from,
        to_date: to,
      }),
    enabled: !!orgId && !!accountId,
  });

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
            Buku Besar
          </h1>
          <p className="text-sm text-muted-foreground">{org?.name}</p>
        </div>
        <YearSelect value={year} onChange={setYear} />
      </div>

      {/* Account picker */}
      <Select value={accountId} onValueChange={setAccountId}>
        <SelectTrigger className="w-full sm:max-w-md">
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

      {isLoading || !data ? (
        <Skeleton className="h-96 rounded-xl" />
      ) : (
        <Card>
          <CardContent className="p-0">
            <div className="flex flex-wrap items-center justify-between gap-2 border-b border-border px-5 py-3">
              <div>
                <h2 className="font-display text-base font-semibold">
                  {data.account.name}
                </h2>
                <p className="font-mono text-xs text-muted-foreground">
                  {data.account.code} · Saldo normal{" "}
                  {data.account.normal_balance === "debit" ? "Debit" : "Kredit"}
                </p>
              </div>
              <div className="text-right">
                <p className="text-xs text-muted-foreground">Saldo Akhir</p>
                <p className="font-display text-base font-bold tabular-nums">
                  {formatCurrency(data.closing_balance)}
                </p>
              </div>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border text-left text-xs text-muted-foreground">
                    <th className="px-4 py-2 font-medium">Tanggal</th>
                    <th className="px-4 py-2 font-medium">Uraian</th>
                    <th className="px-4 py-2 text-right font-medium">Debit</th>
                    <th className="px-4 py-2 text-right font-medium">Kredit</th>
                    <th className="px-4 py-2 text-right font-medium">Saldo</th>
                  </tr>
                </thead>
                <tbody>
                  <tr className="border-b border-border/50 bg-muted/30">
                    <td colSpan={4} className="px-4 py-2 font-medium">
                      Saldo Awal
                    </td>
                    <td className="px-4 py-2 text-right font-medium tabular-nums">
                      {formatCurrency(data.opening_balance)}
                    </td>
                  </tr>
                  {data.lines.length === 0 ? (
                    <tr>
                      <td
                        colSpan={5}
                        className="px-4 py-8 text-center text-muted-foreground"
                      >
                        Tidak ada transaksi pada periode ini
                      </td>
                    </tr>
                  ) : (
                    data.lines.map((line, i) => (
                      <tr
                        key={i}
                        className="border-b border-border/50 last:border-0 hover:bg-accent/20"
                      >
                        <td className="whitespace-nowrap px-4 py-2 text-xs">
                          {formatDate(line.date)}
                        </td>
                        <td className="px-4 py-2">
                          <span className="line-clamp-1">{line.description}</span>
                          {line.entry_number && (
                            <span className="font-mono text-[10px] text-muted-foreground">
                              {line.entry_number}
                            </span>
                          )}
                        </td>
                        <td className="px-4 py-2 text-right tabular-nums">
                          {line.debit > 0 ? formatCurrency(line.debit) : "-"}
                        </td>
                        <td className="px-4 py-2 text-right tabular-nums">
                          {line.credit > 0 ? formatCurrency(line.credit) : "-"}
                        </td>
                        <td className="px-4 py-2 text-right font-medium tabular-nums">
                          {formatCurrency(line.balance)}
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
                <tfoot>
                  <tr className="border-t-2 border-border bg-muted/30 font-bold">
                    <td colSpan={4} className="px-4 py-3 text-right uppercase">
                      Saldo Akhir
                    </td>
                    <td className="px-4 py-3 text-right tabular-nums">
                      {formatCurrency(data.closing_balance)}
                    </td>
                  </tr>
                </tfoot>
              </table>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}

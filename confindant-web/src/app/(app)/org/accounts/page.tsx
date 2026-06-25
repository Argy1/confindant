"use client";

import * as React from "react";
import { useQuery } from "@tanstack/react-query";
import { Card, CardContent } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { Badge } from "@/components/ui/badge";
import { accountingApi } from "@/lib/api/accounting";
import { useActiveOrg } from "@/lib/hooks/use-active-org";
import type { Account, AccountType } from "@/lib/accounting-types";

const TYPE_LABEL: Record<AccountType, string> = {
  asset: "Aset",
  liability: "Kewajiban",
  net_asset: "Aset Bersih",
  revenue: "Pendapatan",
  expense: "Beban",
};

const TYPE_ORDER: AccountType[] = [
  "asset",
  "liability",
  "net_asset",
  "revenue",
  "expense",
];

export default function AccountsPage() {
  const { org, orgId } = useActiveOrg();

  const { data, isLoading } = useQuery({
    queryKey: ["accounts", orgId],
    queryFn: () => accountingApi.accounts(orgId!),
    enabled: !!orgId,
  });

  const grouped = React.useMemo(() => {
    const map = new Map<AccountType, Account[]>();
    (data ?? []).forEach((a) => {
      const arr = map.get(a.type) ?? [];
      arr.push(a);
      map.set(a.type, arr);
    });
    return map;
  }, [data]);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
          Bagan Akun
        </h1>
        <p className="text-sm text-muted-foreground">
          {org?.name} · {data?.length ?? 0} akun
        </p>
      </div>

      {isLoading ? (
        <Skeleton className="h-96 rounded-xl" />
      ) : (
        <div className="space-y-5">
          {TYPE_ORDER.map((type) => {
            const accounts = grouped.get(type);
            if (!accounts || accounts.length === 0) return null;
            return (
              <Card key={type}>
                <CardContent className="p-0">
                  <div className="flex items-center justify-between border-b border-border bg-muted/40 px-4 py-3">
                    <h2 className="font-display text-sm font-bold uppercase tracking-wide">
                      {TYPE_LABEL[type]}
                    </h2>
                    <Badge variant="info">{accounts.length}</Badge>
                  </div>
                  <table className="w-full text-sm">
                    <tbody>
                      {accounts.map((a) => (
                        <tr
                          key={a.id}
                          className="border-b border-border/50 last:border-0 hover:bg-accent/30"
                        >
                          <td className="w-24 px-4 py-2.5 font-mono text-xs text-muted-foreground">
                            {a.code}
                          </td>
                          <td className="py-2.5">
                            {a.name}
                            {a.is_contra && (
                              <span className="ml-2 text-xs text-muted-foreground">
                                (kontra)
                              </span>
                            )}
                          </td>
                          <td className="px-4 py-2.5 text-right text-xs uppercase text-muted-foreground">
                            {a.normal_balance === "debit" ? "D" : "K"}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}
    </div>
  );
}

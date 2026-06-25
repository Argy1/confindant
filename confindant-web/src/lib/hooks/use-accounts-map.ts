"use client";

import * as React from "react";
import { useQuery } from "@tanstack/react-query";
import { accountingApi } from "@/lib/api/accounting";

/**
 * Loads the org's chart of accounts and exposes a code -> id lookup, so report
 * rows (which carry only the account code) can drill into the ledger by id.
 */
export function useAccountsMap(orgId: string | null) {
  const { data: accounts } = useQuery({
    queryKey: ["accounts", orgId],
    queryFn: () => accountingApi.accounts(orgId!),
    enabled: !!orgId,
    staleTime: 300_000,
  });

  const codeToId = React.useMemo(() => {
    const map = new Map<string, string>();
    (accounts ?? []).forEach((a) => map.set(a.code, a.id));
    return map;
  }, [accounts]);

  return { accounts, codeToId };
}

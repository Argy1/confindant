"use client";

import * as React from "react";
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectLabel,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import type { Account, AccountType } from "@/lib/accounting-types";

const TYPE_LABEL: Record<AccountType, string> = {
  asset: "Aset",
  liability: "Kewajiban",
  net_asset: "Aset Bersih",
  revenue: "Pendapatan",
  expense: "Beban",
};

/**
 * Account picker grouped by account type. Optionally restrict to specific types.
 */
export function AccountSelect({
  accounts,
  value,
  onChange,
  placeholder = "Pilih akun",
  types,
}: {
  accounts: Account[];
  value: string;
  onChange: (id: string) => void;
  placeholder?: string;
  types?: AccountType[];
}) {
  const allowed = types ?? (["asset", "liability", "net_asset", "revenue", "expense"] as AccountType[]);

  const grouped = React.useMemo(() => {
    const map = new Map<AccountType, Account[]>();
    accounts.forEach((a) => {
      if (!allowed.includes(a.type)) return;
      const arr = map.get(a.type) ?? [];
      arr.push(a);
      map.set(a.type, arr);
    });
    return map;
  }, [accounts, allowed]);

  return (
    <Select value={value} onValueChange={onChange}>
      <SelectTrigger>
        <SelectValue placeholder={placeholder} />
      </SelectTrigger>
      <SelectContent>
        {allowed.map((type) => {
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
        })}
      </SelectContent>
    </Select>
  );
}

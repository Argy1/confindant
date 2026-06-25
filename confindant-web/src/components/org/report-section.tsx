"use client";

import * as React from "react";
import { ChevronDown, ChevronRight } from "lucide-react";
import { cn, formatCurrency } from "@/lib/utils";
import { subtypeLabel } from "@/lib/accounting-labels";
import type { ReportGroup } from "@/lib/accounting-types";

/**
 * Collapsible grouped report section (used by Neraca & Laporan Aktivitas).
 * Each account row is clickable to drill into its general ledger.
 */
export function ReportSection({
  title,
  groups,
  total,
  totalLabel,
  onAccountClick,
  accent = "blue",
}: {
  title: string;
  groups: ReportGroup[];
  total: number;
  totalLabel?: string;
  onAccountClick?: (code: string, name: string) => void;
  accent?: "blue" | "rose" | "emerald";
}) {
  const accentText =
    accent === "rose"
      ? "text-rose-700"
      : accent === "emerald"
      ? "text-emerald-700"
      : "text-blue-800";

  return (
    <div className="overflow-hidden rounded-xl border border-border bg-card">
      <div className="border-b border-border bg-muted/40 px-4 py-2.5">
        <h3 className="font-display text-sm font-bold uppercase tracking-wide">
          {title}
        </h3>
      </div>
      <div className="divide-y divide-border/60">
        {groups.length === 0 && (
          <p className="px-4 py-6 text-center text-sm text-muted-foreground">
            Belum ada data
          </p>
        )}
        {groups.map((group) => (
          <GroupRow
            key={group.subtype}
            group={group}
            onAccountClick={onAccountClick}
          />
        ))}
      </div>
      <div
        className={cn(
          "flex items-center justify-between border-t-2 border-border px-4 py-3",
          accentText,
        )}
      >
        <span className="text-sm font-bold uppercase">
          {totalLabel ?? `Total ${title}`}
        </span>
        <span className="font-display text-base font-bold tabular-nums">
          {formatCurrency(total)}
        </span>
      </div>
    </div>
  );
}

function GroupRow({
  group,
  onAccountClick,
}: {
  group: ReportGroup;
  onAccountClick?: (code: string, name: string) => void;
}) {
  const [open, setOpen] = React.useState(true);

  return (
    <div>
      <button
        onClick={() => setOpen((v) => !v)}
        className="flex w-full items-center justify-between px-4 py-2.5 text-left transition-colors hover:bg-accent/40"
      >
        <span className="flex items-center gap-1.5 text-sm font-semibold">
          {open ? (
            <ChevronDown className="h-4 w-4 text-muted-foreground" />
          ) : (
            <ChevronRight className="h-4 w-4 text-muted-foreground" />
          )}
          {subtypeLabel(group.subtype)}
        </span>
        <span className="text-sm font-semibold tabular-nums">
          {formatCurrency(group.subtotal)}
        </span>
      </button>
      {open && (
        <div className="bg-muted/20">
          {group.accounts.map((acc) => {
            const clickable = !!onAccountClick;
            return (
              <button
                key={acc.code}
                disabled={!clickable}
                onClick={() => onAccountClick?.(acc.code, acc.name)}
                className={cn(
                  "flex w-full items-center justify-between py-2 pl-11 pr-4 text-left text-sm transition-colors",
                  clickable && "hover:bg-accent/50 hover:underline",
                )}
              >
                <span className="flex items-center gap-2">
                  <span className="font-mono text-xs text-muted-foreground">
                    {acc.code}
                  </span>
                  <span>{acc.name}</span>
                </span>
                <span className="tabular-nums">{formatCurrency(acc.amount)}</span>
              </button>
            );
          })}
        </div>
      )}
    </div>
  );
}

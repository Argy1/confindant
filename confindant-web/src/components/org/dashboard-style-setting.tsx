"use client";

import { useQuery } from "@tanstack/react-query";
import { LayoutGrid, Table2, Check } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { organizationApi } from "@/lib/api/accounting";
import { useOrgStore, type DashboardVariant } from "@/store/org";
import { cn } from "@/lib/utils";

/**
 * Preference control for the organization dashboard style. Only shown when the
 * user belongs to at least one organization. The choice is persisted via the
 * org store (localStorage), so it sticks across sessions.
 */
export function DashboardStyleSetting() {
  const { dashboardVariant, setDashboardVariant } = useOrgStore();

  const { data: orgs } = useQuery({
    queryKey: ["my-organizations"],
    queryFn: organizationApi.list,
    staleTime: 300_000,
  });

  // Hide entirely for users without any organization.
  if (!orgs || orgs.length === 0) return null;

  const options: {
    value: DashboardVariant;
    label: string;
    desc: string;
    icon: typeof LayoutGrid;
  }[] = [
    {
      value: "cards",
      label: "Kartu",
      desc: "Visual: kartu ringkasan & grafik",
      icon: LayoutGrid,
    },
    {
      value: "dense",
      label: "Padat",
      desc: "Tabel angka rapi ala software akuntansi",
      icon: Table2,
    },
  ];

  return (
    <div>
      <h2 className="mb-2 px-1 text-xs font-semibold uppercase tracking-wider text-muted-foreground">
        Tampilan Organisasi
      </h2>
      <Card>
        <CardContent className="space-y-3 p-4">
          <div>
            <p className="font-medium">Gaya Dashboard</p>
            <p className="text-xs text-muted-foreground">
              Pilih tampilan dashboard keuangan organisasi.
            </p>
          </div>
          <div className="grid grid-cols-2 gap-3">
            {options.map((opt) => {
              const active = dashboardVariant === opt.value;
              return (
                <button
                  key={opt.value}
                  onClick={() => setDashboardVariant(opt.value)}
                  className={cn(
                    "relative flex flex-col items-start gap-2 rounded-xl border p-3 text-left transition-all",
                    active
                      ? "border-blue-600 bg-blue-50 ring-1 ring-blue-600"
                      : "border-border hover:border-blue-300 hover:bg-accent/40",
                  )}
                >
                  {active && (
                    <span className="absolute right-2 top-2 grid h-5 w-5 place-items-center rounded-full bg-blue-600 text-white">
                      <Check className="h-3 w-3" />
                    </span>
                  )}
                  <div
                    className={cn(
                      "grid h-9 w-9 place-items-center rounded-lg",
                      active
                        ? "bg-blue-600 text-white"
                        : "bg-muted text-muted-foreground",
                    )}
                  >
                    <opt.icon className="h-4.5 w-4.5" />
                  </div>
                  <div>
                    <p className="text-sm font-semibold">{opt.label}</p>
                    <p className="text-xs text-muted-foreground">{opt.desc}</p>
                  </div>
                </button>
              );
            })}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

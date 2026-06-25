"use client";

import * as React from "react";
import { useQuery } from "@tanstack/react-query";
import { Skeleton } from "@/components/ui/skeleton";
import { accountingApi } from "@/lib/api/accounting";
import { useActiveOrg } from "@/lib/hooks/use-active-org";
import { useOrgStore } from "@/store/org";
import { YearSelect } from "@/components/org/year-select";
import { DashboardVariantCards } from "@/components/org/dashboard-variant-cards";
import { DashboardVariantDense } from "@/components/org/dashboard-variant-dense";

export default function OrgDashboardPage() {
  const { org, orgId, isLoading: orgLoading } = useActiveOrg();
  const [year, setYear] = React.useState(new Date().getFullYear());
  const variant = useOrgStore((s) => s.dashboardVariant);

  const { data, isLoading } = useQuery({
    queryKey: ["org-dashboard", orgId, year],
    queryFn: () => accountingApi.dashboard(orgId!, year),
    enabled: !!orgId,
  });

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
            Dashboard Keuangan
          </h1>
          <p className="text-sm text-muted-foreground">
            {org?.name ?? "Organisasi"} · Tahun {year}
          </p>
        </div>
        <YearSelect value={year} onChange={setYear} />
      </div>

      {orgLoading || isLoading || !data ? (
        <DashboardSkeleton />
      ) : variant === "dense" ? (
        <DashboardVariantDense data={data} />
      ) : (
        <DashboardVariantCards data={data} />
      )}
    </div>
  );
}

function DashboardSkeleton() {
  return (
    <div className="space-y-6">
      <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        {Array.from({ length: 4 }).map((_, i) => (
          <Skeleton key={i} className="h-28 rounded-xl" />
        ))}
      </div>
      <div className="grid gap-6 lg:grid-cols-3">
        <Skeleton className="h-80 rounded-xl lg:col-span-2" />
        <Skeleton className="h-80 rounded-xl" />
      </div>
    </div>
  );
}

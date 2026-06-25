"use client";

import * as React from "react";
import { useQuery } from "@tanstack/react-query";
import { organizationApi } from "@/lib/api/accounting";
import { useOrgStore } from "@/store/org";
import type { Organization } from "@/lib/accounting-types";

type ActiveOrgResult = {
  org: Organization | null;
  orgId: string | null;
  isLoading: boolean;
  canWrite: boolean;
};

/**
 * Resolves the currently-active organization from the org store + the user's
 * organization list. Falls back to the first org when none is selected yet.
 */
export function useActiveOrg(): ActiveOrgResult {
  const { activeOrgId, setActiveOrg } = useOrgStore();

  const { data: orgs, isLoading } = useQuery({
    queryKey: ["my-organizations"],
    queryFn: organizationApi.list,
    staleTime: 300_000,
  });

  const org = React.useMemo(() => {
    if (!orgs || orgs.length === 0) return null;
    return orgs.find((o) => o.id === activeOrgId) ?? orgs[0];
  }, [orgs, activeOrgId]);

  React.useEffect(() => {
    if (org && org.id !== activeOrgId) {
      setActiveOrg(org.id);
    }
  }, [org, activeOrgId, setActiveOrg]);

  const canWrite = org ? ["admin", "bendahara"].includes(org.role) : false;

  return { org, orgId: org?.id ?? null, isLoading, canWrite };
}

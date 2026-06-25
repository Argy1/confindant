"use client";

import * as React from "react";
import { useRouter } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { Building2, Check, ChevronsUpDown, User as UserIcon } from "lucide-react";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { organizationApi } from "@/lib/api/accounting";
import { useOrgStore } from "@/store/org";
import { cn } from "@/lib/utils";

const ROLE_LABEL: Record<string, string> = {
  admin: "Admin",
  bendahara: "Bendahara",
  auditor: "Auditor",
  viewer: "Viewer",
};

/**
 * Workspace context switcher shown in the header. Lets the user move between
 * the Personal app and any organization they belong to (e.g. PDPI).
 */
export function WorkspaceSwitcher() {
  const router = useRouter();
  const { mode, activeOrgId, switchToOrg, switchToPersonal, setActiveOrg } =
    useOrgStore();

  const { data: orgs } = useQuery({
    queryKey: ["my-organizations"],
    queryFn: organizationApi.list,
    staleTime: 300_000,
  });

  const activeOrg = React.useMemo(
    () => (orgs ?? []).find((o) => o.id === activeOrgId) ?? null,
    [orgs, activeOrgId],
  );

  // If we're in org mode but have no active org yet, default to the first one.
  React.useEffect(() => {
    if (mode === "org" && !activeOrgId && orgs && orgs.length > 0) {
      setActiveOrg(orgs[0].id);
    }
  }, [mode, activeOrgId, orgs, setActiveOrg]);

  const handlePersonal = () => {
    switchToPersonal();
    router.push("/home");
  };

  const handleOrg = (orgId: string) => {
    switchToOrg(orgId);
    router.push("/org/dashboard");
  };

  const isOrg = mode === "org" && activeOrg;
  const label = isOrg ? activeOrg!.name : "Personal";
  const sublabel = isOrg
    ? ROLE_LABEL[activeOrg!.role] ?? activeOrg!.role
    : "Keuangan Pribadi";

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <button
          className="flex items-center gap-2 rounded-lg border border-border bg-card px-2.5 py-1.5 text-left transition-colors hover:bg-accent"
          aria-label="Ganti workspace"
        >
          <div
            className={cn(
              "grid h-8 w-8 shrink-0 place-items-center rounded-md text-white",
              isOrg ? "bg-blue-700" : "bg-violet-600",
            )}
          >
            {isOrg ? (
              <Building2 className="h-4 w-4" />
            ) : (
              <UserIcon className="h-4 w-4" />
            )}
          </div>
          <div className="hidden min-w-0 sm:block">
            <p className="truncate text-sm font-semibold leading-tight">
              {label}
            </p>
            <p className="truncate text-[11px] text-muted-foreground leading-tight">
              {sublabel}
            </p>
          </div>
          <ChevronsUpDown className="h-4 w-4 shrink-0 text-muted-foreground" />
        </button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="start" className="w-64">
        <DropdownMenuLabel>Workspace</DropdownMenuLabel>
        <DropdownMenuItem onSelect={handlePersonal}>
          <div className="grid h-7 w-7 place-items-center rounded-md bg-violet-600 text-white">
            <UserIcon className="h-3.5 w-3.5" />
          </div>
          <span className="flex-1">Personal</span>
          {mode === "personal" && <Check className="h-4 w-4 text-blue-700" />}
        </DropdownMenuItem>

        {orgs && orgs.length > 0 && (
          <>
            <DropdownMenuSeparator />
            <DropdownMenuLabel>Organisasi</DropdownMenuLabel>
            {orgs.map((org) => (
              <DropdownMenuItem
                key={org.id}
                onSelect={() => handleOrg(org.id)}
              >
                <div className="grid h-7 w-7 place-items-center rounded-md bg-blue-700 text-white">
                  <Building2 className="h-3.5 w-3.5" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="truncate text-sm">{org.name}</p>
                  <p className="truncate text-[11px] text-muted-foreground">
                    {ROLE_LABEL[org.role] ?? org.role}
                  </p>
                </div>
                {mode === "org" && activeOrgId === org.id && (
                  <Check className="h-4 w-4 text-blue-700" />
                )}
              </DropdownMenuItem>
            ))}
          </>
        )}
      </DropdownMenuContent>
    </DropdownMenu>
  );
}

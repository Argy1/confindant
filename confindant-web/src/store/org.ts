"use client";

import { create } from "zustand";
import { persist, createJSONStorage } from "zustand/middleware";

/**
 * Workspace mode: "personal" shows the original personal-finance app,
 * "org" shows the organization accounting module for the active organization.
 */
export type WorkspaceMode = "personal" | "org";

/** Visual style of the organization dashboard. */
export type DashboardVariant = "cards" | "dense";

type OrgState = {
  mode: WorkspaceMode;
  activeOrgId: string | null;
  dashboardVariant: DashboardVariant;
  hydrated: boolean;
  setMode: (mode: WorkspaceMode) => void;
  setActiveOrg: (orgId: string | null) => void;
  switchToOrg: (orgId: string) => void;
  switchToPersonal: () => void;
  setDashboardVariant: (variant: DashboardVariant) => void;
  setHydrated: () => void;
};

export const useOrgStore = create<OrgState>()(
  persist(
    (set) => ({
      mode: "personal",
      activeOrgId: null,
      dashboardVariant: "cards",
      hydrated: false,
      setMode: (mode) => set({ mode }),
      setActiveOrg: (orgId) => set({ activeOrgId: orgId }),
      switchToOrg: (orgId) => set({ mode: "org", activeOrgId: orgId }),
      switchToPersonal: () => set({ mode: "personal" }),
      setDashboardVariant: (variant) => set({ dashboardVariant: variant }),
      setHydrated: () => set({ hydrated: true }),
    }),
    {
      name: "confindant-workspace",
      storage: createJSONStorage(() =>
        typeof window === "undefined"
          ? (undefined as unknown as Storage)
          : window.localStorage,
      ),
      partialize: (s) => ({
        mode: s.mode,
        activeOrgId: s.activeOrgId,
        dashboardVariant: s.dashboardVariant,
      }),
      onRehydrateStorage: () => (state) => {
        state?.setHydrated();
      },
    },
  ),
);

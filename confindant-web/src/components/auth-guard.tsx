"use client";

import * as React from "react";
import { useRouter } from "next/navigation";
import { useAuthStore } from "@/store/auth";

export function AuthGuard({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const { token, hydrated } = useAuthStore();

  React.useEffect(() => {
    if (hydrated && !token) {
      router.replace("/login");
    }
  }, [hydrated, token, router]);

  if (!hydrated) {
    return (
      <div className="grid min-h-screen place-items-center bg-background">
        <div className="flex items-center gap-3 text-muted-foreground">
          <span className="h-5 w-5 animate-spin rounded-full border-2 border-primary border-t-transparent" />
          <span>Memuat sesi…</span>
        </div>
      </div>
    );
  }

  if (!token) return null;

  return <>{children}</>;
}

export function GuestGuard({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const { token, hydrated } = useAuthStore();

  React.useEffect(() => {
    if (hydrated && token) {
      router.replace("/home");
    }
  }, [hydrated, token, router]);

  if (!hydrated) return null;
  if (token) return null;
  return <>{children}</>;
}

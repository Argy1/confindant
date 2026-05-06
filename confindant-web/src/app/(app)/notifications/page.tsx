"use client";

import * as React from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Bell, CheckCircle2 } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { Button } from "@/components/ui/button";
import { notificationsApi } from "@/lib/api/profile";
import { cn } from "@/lib/utils";

export default function NotificationsPage() {
  const qc = useQueryClient();
  const { data, isLoading } = useQuery({
    queryKey: ["notifications", "list"],
    queryFn: () => notificationsApi.list({ per_page: 50 }),
  });

  const markRead = useMutation({
    mutationFn: (id: string) => notificationsApi.markRead(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["notifications"] });
    },
  });

  const unreadList = (data ?? []).filter((n) => !n.read);

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
            Notifikasi
          </h1>
          <p className="text-sm text-muted-foreground">
            Update aktivitas keuangan dan alert budget kamu.
          </p>
        </div>
        {unreadList.length > 0 && (
          <Button
            variant="outline"
            onClick={() => {
              for (const n of unreadList) markRead.mutate(n.id);
            }}
          >
            <CheckCircle2 className="h-4 w-4" /> Tandai semua dibaca
          </Button>
        )}
      </div>

      {isLoading ? (
        <div className="space-y-2">
          {Array.from({ length: 5 }).map((_, i) => (
            <Skeleton key={i} className="h-16 rounded-xl" />
          ))}
        </div>
      ) : (data ?? []).length === 0 ? (
        <Card>
          <CardContent className="grid place-items-center gap-3 py-16 text-center">
            <div className="grid h-14 w-14 place-items-center rounded-full bg-info-bg text-blue-900">
              <Bell className="h-6 w-6" />
            </div>
            <p className="font-semibold">Belum ada notifikasi</p>
            <p className="max-w-xs text-sm text-muted-foreground">
              Notifikasi akan muncul di sini ketika ada aktivitas penting.
            </p>
          </CardContent>
        </Card>
      ) : (
        <Card>
          <CardContent className="divide-y divide-border p-0">
            {(data ?? []).map((n) => (
              <button
                key={n.id}
                onClick={() => !n.read && markRead.mutate(n.id)}
                className={cn(
                  "flex w-full items-start gap-3 p-4 text-left transition-colors hover:bg-accent/40",
                  !n.read && "bg-info-bg/50",
                )}
              >
                <div
                  className={cn(
                    "mt-0.5 h-2 w-2 shrink-0 rounded-full",
                    n.read ? "bg-muted" : "bg-blue-600",
                  )}
                />
                <div className="min-w-0 flex-1">
                  <p className={cn("font-medium", !n.read && "text-blue-900")}>
                    {n.title}
                  </p>
                  <p className="text-sm text-muted-foreground">{n.subtitle}</p>
                  <p className="mt-0.5 text-xs text-muted-foreground">
                    {n.time_label}
                  </p>
                </div>
              </button>
            ))}
          </CardContent>
        </Card>
      )}
    </div>
  );
}

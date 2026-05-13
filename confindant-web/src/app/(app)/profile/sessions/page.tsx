"use client";

import * as React from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import {
  Monitor,
  Smartphone,
  Tablet,
  Loader2,
  ShieldOff,
  CheckCircle2,
} from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { sessionsApi } from "@/lib/api/sessions";
import type { UserSession } from "@/lib/api/sessions";
import { getApiErrorMessage } from "@/lib/api/client";

function DeviceIcon({ type }: { type: string }) {
  if (type === "mobile") return <Smartphone className="h-5 w-5" />;
  if (type === "tablet") return <Tablet className="h-5 w-5" />;
  return <Monitor className="h-5 w-5" />;
}

function timeAgo(dateStr: string): string {
  const diff = Math.floor((Date.now() - new Date(dateStr).getTime()) / 1000);
  if (diff < 60) return "Baru saja";
  if (diff < 3600) return `${Math.floor(diff / 60)} menit lalu`;
  if (diff < 86400) return `${Math.floor(diff / 3600)} jam lalu`;
  if (diff < 604800) return `${Math.floor(diff / 86400)} hari lalu`;
  return new Date(dateStr).toLocaleDateString("id-ID", {
    day: "numeric",
    month: "short",
    year: "numeric",
  });
}

export default function SessionsPage() {
  const qc = useQueryClient();

  const { data: sessions, isLoading } = useQuery({
    queryKey: ["sessions"],
    queryFn: sessionsApi.list,
    refetchInterval: 30_000,
  });

  const revoke = useMutation({
    mutationFn: (id: string) => sessionsApi.revoke(id),
    onSuccess: () => {
      toast.success("Sesi berhasil diakhiri");
      qc.invalidateQueries({ queryKey: ["sessions"] });
    },
    onError: (err) => toast.error(getApiErrorMessage(err, "Gagal mengakhiri sesi")),
  });

  const revokeAll = useMutation({
    mutationFn: () => sessionsApi.revokeAll(),
    onSuccess: () => {
      toast.success("Semua sesi lain berhasil diakhiri");
      qc.invalidateQueries({ queryKey: ["sessions"] });
    },
    onError: (err) => toast.error(getApiErrorMessage(err, "Gagal mengakhiri sesi")),
  });

  const activeSessions = (sessions ?? []).filter((s) => s.is_active);
  const inactiveSessions = (sessions ?? []).filter((s) => !s.is_active);
  const otherActive = activeSessions.filter((s) => !s.is_current);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
          Sesi Aktif
        </h1>
        <p className="text-sm text-muted-foreground">
          Kelola semua perangkat yang sedang login ke akun kamu.
        </p>
      </div>

      {isLoading ? (
        <div className="space-y-3">
          {[1, 2, 3].map((i) => (
            <Skeleton key={i} className="h-24 rounded-xl" />
          ))}
        </div>
      ) : (
        <>
          {/* Active sessions */}
          <div>
            <h2 className="mb-3 text-sm font-semibold uppercase tracking-wider text-muted-foreground">
              Sedang Login ({activeSessions.length})
            </h2>
            <div className="space-y-3">
              {activeSessions.map((s) => (
                <SessionCard
                  key={s.id}
                  session={s}
                  onRevoke={() => revoke.mutate(s.id)}
                  isRevoking={revoke.isPending}
                />
              ))}
            </div>
          </div>

          {/* Revoke all button */}
          {otherActive.length > 1 && (
            <Button
              variant="outline"
              className="w-full text-destructive hover:bg-destructive/10 hover:text-destructive"
              onClick={() => {
                if (confirm("Akhiri semua sesi selain perangkat ini?"))
                  revokeAll.mutate();
              }}
              disabled={revokeAll.isPending}
            >
              {revokeAll.isPending ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <ShieldOff className="h-4 w-4" />
              )}
              Akhiri Semua Sesi Lain
            </Button>
          )}

          {/* Inactive sessions */}
          {inactiveSessions.length > 0 && (
            <div>
              <h2 className="mb-3 text-sm font-semibold uppercase tracking-wider text-muted-foreground">
                Riwayat Sesi ({inactiveSessions.length})
              </h2>
              <div className="space-y-3">
                {inactiveSessions.slice(0, 10).map((s) => (
                  <SessionCard key={s.id} session={s} />
                ))}
              </div>
            </div>
          )}
        </>
      )}
    </div>
  );
}

function SessionCard({
  session,
  onRevoke,
  isRevoking,
}: {
  session: UserSession;
  onRevoke?: () => void;
  isRevoking?: boolean;
}) {
  return (
    <Card
      className={
        session.is_current
          ? "border-blue-900/30 bg-info-bg/40"
          : ""
      }
    >
      <CardContent className="flex items-center gap-4 p-4">
        <div
          className={`grid h-11 w-11 shrink-0 place-items-center rounded-xl ${
            session.is_active
              ? "bg-info-bg text-blue-900"
              : "bg-muted text-muted-foreground"
          }`}
        >
          <DeviceIcon type={session.device_type} />
        </div>

        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <p className="font-medium">{session.device_name}</p>
            {session.is_current && (
              <Badge variant="success" className="text-[10px]">
                <CheckCircle2 className="mr-1 h-3 w-3" /> Perangkat ini
              </Badge>
            )}
            {!session.is_active && (
              <Badge variant="secondary" className="text-[10px]">
                Sudah logout
              </Badge>
            )}
          </div>
          <p className="mt-0.5 text-xs text-muted-foreground">
            {session.ip_address} · {session.platform}
          </p>
          <p className="text-xs text-muted-foreground">
            {session.is_active
              ? `Aktif ${timeAgo(session.last_active_at)}`
              : `Logout ${session.logged_out_at ? timeAgo(session.logged_out_at) : "-"}`}
            {" · "}Login {timeAgo(session.logged_in_at)}
          </p>
        </div>

        {session.is_active && !session.is_current && onRevoke && (
          <Button
            variant="ghost"
            size="sm"
            className="shrink-0 text-destructive hover:bg-destructive/10 hover:text-destructive"
            onClick={onRevoke}
            disabled={isRevoking}
          >
            {isRevoking ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              "Akhiri"
            )}
          </Button>
        )}
      </CardContent>
    </Card>
  );
}

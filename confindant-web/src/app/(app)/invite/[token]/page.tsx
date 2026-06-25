"use client";

import * as React from "react";
import { useParams, useRouter } from "next/navigation";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Loader2, CheckCircle2, AlertTriangle } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { organizationApi } from "@/lib/api/accounting";
import { useOrgStore } from "@/store/org";
import { toast } from "sonner";
import { getApiErrorMessage } from "@/lib/api/client";

const ROLE_LABEL: Record<string, string> = {
  admin: "Admin",
  bendahara: "Bendahara",
  auditor: "Auditor",
  viewer: "Viewer",
};

export default function InvitePage() {
  const { token } = useParams<{ token: string }>();
  const router = useRouter();
  const qc = useQueryClient();
  const setMode = useOrgStore((s) => s.setMode);

  const infoQuery = useQuery({
    queryKey: ["invite-info", token],
    queryFn: () => organizationApi.inviteInfo(token),
    retry: false,
  });

  const acceptMut = useMutation({
    mutationFn: () => organizationApi.inviteAccept(token),
    onSuccess: (data) => {
      toast.success(`Selamat datang di ${data.organization.name}!`);
      // Refresh organizations list and switch to org mode
      qc.invalidateQueries({ queryKey: ["organizations"] });
      setMode("org");
      router.push("/org/dashboard");
    },
    onError: (err) => toast.error(getApiErrorMessage(err, "Gagal menerima undangan")),
  });

  if (infoQuery.isLoading) {
    return (
      <div className="mx-auto max-w-md space-y-4 py-12">
        <Skeleton className="h-48 rounded-2xl" />
      </div>
    );
  }

  if (infoQuery.isError || !infoQuery.data) {
    return (
      <div className="mx-auto max-w-md py-12">
        <Card>
          <CardContent className="flex flex-col items-center gap-4 py-12 text-center">
            <AlertTriangle className="h-10 w-10 text-amber-500" />
            <div>
              <p className="font-semibold">Undangan tidak valid</p>
              <p className="mt-1 text-sm text-muted-foreground">
                Link undangan sudah kadaluarsa atau tidak ditemukan.
              </p>
            </div>
            <Button variant="outline" onClick={() => router.push("/home")}>
              Kembali ke Home
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  const info = infoQuery.data;

  return (
    <div className="mx-auto max-w-md py-12">
      <Card>
        <CardContent className="space-y-6 py-8">
          <div className="text-center">
            <div className="mx-auto mb-4 grid h-16 w-16 place-items-center rounded-2xl bg-blue-100 text-3xl">
              🏛️
            </div>
            <h1 className="font-display text-xl font-bold">
              Undangan Bergabung
            </h1>
            <p className="mt-1 text-sm text-muted-foreground">
              <strong>{info.invited_by.name}</strong> mengundang Anda bergabung ke
            </p>
          </div>

          <div className="rounded-xl border border-border bg-muted/40 p-4 text-center">
            <p className="font-display text-lg font-bold">{info.organization.name}</p>
            <p className="mt-1 text-sm text-muted-foreground">
              sebagai{" "}
              <span className="font-semibold text-foreground">
                {ROLE_LABEL[info.role] ?? info.role}
              </span>
            </p>
          </div>

          <p className="text-center text-xs text-muted-foreground">
            Link berlaku hingga{" "}
            {new Date(info.expires_at).toLocaleString("id-ID", {
              dateStyle: "long",
              timeStyle: "short",
            })}
          </p>

          {acceptMut.isSuccess ? (
            <div className="flex flex-col items-center gap-3">
              <CheckCircle2 className="h-8 w-8 text-emerald-600" />
              <p className="text-sm font-medium text-emerald-700">
                Undangan diterima! Mengalihkan...
              </p>
            </div>
          ) : (
            <div className="flex flex-col gap-2">
              <Button
                className="w-full"
                onClick={() => acceptMut.mutate()}
                disabled={acceptMut.isPending}
              >
                {acceptMut.isPending && (
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                )}
                Terima Undangan
              </Button>
              <Button
                variant="ghost"
                className="w-full"
                onClick={() => router.push("/home")}
              >
                Tolak
              </Button>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

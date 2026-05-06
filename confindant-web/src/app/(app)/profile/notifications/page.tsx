"use client";

import * as React from "react";
import Link from "next/link";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { ArrowLeft } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Switch } from "@/components/ui/switch";
import { Skeleton } from "@/components/ui/skeleton";
import { profileApi, type NotificationSettingsInput } from "@/lib/api/profile";
import { getApiErrorMessage } from "@/lib/api/client";

const FIELDS: Array<{
  key: keyof NotificationSettingsInput;
  label: string;
  desc: string;
}> = [
  {
    key: "push_enabled",
    label: "Push Notifications",
    desc: "Notifikasi langsung dari perangkat",
  },
  {
    key: "email_enabled",
    label: "Email",
    desc: "Ringkasan dan alert via email",
  },
  {
    key: "transaction_alerts",
    label: "Alert Transaksi",
    desc: "Pemberitahuan transaksi baru",
  },
  {
    key: "budget_alerts",
    label: "Alert Budget",
    desc: "Saat pengeluaran mendekati batas",
  },
  {
    key: "weekly_report",
    label: "Laporan Mingguan",
    desc: "Ringkasan keuangan setiap minggu",
  },
];

export default function NotificationSettingsPage() {
  const qc = useQueryClient();
  const { data, isLoading } = useQuery({
    queryKey: ["profile"],
    queryFn: profileApi.get,
  });

  const settings = data?.profile.notification_settings;

  const save = useMutation({
    mutationFn: (input: NotificationSettingsInput) =>
      profileApi.updateNotificationSettings(input),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["profile"] });
    },
    onError: (err) => toast.error(getApiErrorMessage(err)),
  });

  const toggle = (key: keyof NotificationSettingsInput, value: boolean) => {
    if (!settings) return;
    const next = { ...settings, [key]: value };
    save.mutate(next);
  };

  return (
    <div className="space-y-6">
      <Link
        href="/profile"
        className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground"
      >
        <ArrowLeft className="h-4 w-4" /> Kembali ke Profil
      </Link>
      <div>
        <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
          Notifikasi
        </h1>
        <p className="text-sm text-muted-foreground">
          Atur alert apa saja yang ingin kamu terima.
        </p>
      </div>

      <Card>
        <CardContent className="divide-y divide-border p-0">
          {isLoading
            ? Array.from({ length: 5 }).map((_, i) => (
                <Skeleton key={i} className="m-4 h-10" />
              ))
            : FIELDS.map((f) => (
                <div
                  key={f.key}
                  className="flex items-center justify-between gap-4 p-4"
                >
                  <div>
                    <p className="font-medium">{f.label}</p>
                    <p className="text-xs text-muted-foreground">{f.desc}</p>
                  </div>
                  <Switch
                    checked={settings?.[f.key] ?? false}
                    onCheckedChange={(c) => toggle(f.key, c)}
                  />
                </div>
              ))}
        </CardContent>
      </Card>
    </div>
  );
}

"use client";

import * as React from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import {
  Bell,
  ChevronRight,
  HelpCircle,
  Lock,
  LogOut,
  MessageSquareText,
  Monitor,
  Shield,
  Sparkles,
  User as UserIcon,
  Upload,
} from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { profileApi } from "@/lib/api/profile";
import { authApi } from "@/lib/api/auth";
import { useAuthStore } from "@/store/auth";
import { initials } from "@/lib/utils";
import { getApiErrorMessage } from "@/lib/api/client";

export default function ProfilePage() {
  const router = useRouter();
  const qc = useQueryClient();
  const { user, logout } = useAuthStore();

  const { data, isLoading } = useQuery({
    queryKey: ["profile"],
    queryFn: profileApi.get,
  });

  const fullName = data?.profile.full_name || user?.username || "User";

  const uploadAvatar = useMutation({
    mutationFn: (f: File) => profileApi.uploadAvatar(f),
    onSuccess: () => {
      toast.success("Foto profil diperbarui");
      qc.invalidateQueries({ queryKey: ["profile"] });
    },
    onError: (err) => toast.error(getApiErrorMessage(err)),
  });

  const onPickAvatar = (e: React.ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0];
    if (f) uploadAvatar.mutate(f);
  };

  const handleLogout = async () => {
    try {
      await authApi.logout();
    } catch {}
    logout();
    router.replace("/login");
  };

  const sections = [
    {
      title: "Pengaturan Akun",
      items: [
        {
          href: "/profile/personal",
          label: "Personal Info",
          desc: "Nama, email, telepon",
          icon: UserIcon,
        },
        {
          href: "/profile/notifications",
          label: "Notifikasi",
          desc: "Pengaturan alert",
          icon: Bell,
        },
        {
          href: "/profile/password",
          label: "Ganti Password",
          desc: "Keamanan akun",
          icon: Lock,
        },
        {
          href: "/profile/sessions",
          label: "Sesi Aktif",
          desc: "Kelola perangkat yang login",
          icon: Monitor,
        },
      ],
    },
    {
      title: "AI & Bantuan",
      items: [
        {
          href: "/finance-chat",
          label: "AI Finance Chat",
          desc: "Tanya keuangan kamu",
          icon: MessageSquareText,
        },
        {
          href: "/profile/ocr-health",
          label: "AI OCR Health",
          desc: "Statistik akurasi OCR",
          icon: Sparkles,
        },
        {
          href: "/profile/help",
          label: "Help Center",
          desc: "FAQ dan dukungan",
          icon: HelpCircle,
        },
      ],
    },
    {
      title: "Legal",
      items: [
        {
          href: "/profile/privacy",
          label: "Privacy Policy",
          desc: "Kebijakan privasi",
          icon: Shield,
        },
        {
          href: "/profile/terms",
          label: "Terms of Service",
          desc: "Syarat & ketentuan",
          icon: Shield,
        },
      ],
    },
  ];

  return (
    <div className="space-y-6">
      <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
        Profil
      </h1>

      {/* Profile header */}
      {isLoading ? (
        <Skeleton className="h-32 rounded-xl" />
      ) : (
        <Card className="overflow-hidden">
          <div className="gradient-hero p-6 text-white">
            <div className="flex items-center gap-4">
              <div className="relative">
                <Avatar className="h-16 w-16 ring-2 ring-white/30">
                  {data?.profile.avatar_path && (
                    <AvatarImage
                      src={data.profile.avatar_path}
                      alt={fullName}
                    />
                  )}
                  <AvatarFallback className="bg-white/20 text-white">
                    {initials(fullName)}
                  </AvatarFallback>
                </Avatar>
                <label className="absolute -bottom-1 -right-1 grid h-7 w-7 cursor-pointer place-items-center rounded-full bg-white text-blue-900 shadow ring-2 ring-blue-900">
                  <Upload className="h-3.5 w-3.5" />
                  <input
                    type="file"
                    accept="image/*"
                    className="hidden"
                    onChange={onPickAvatar}
                  />
                </label>
              </div>
              <div className="min-w-0 flex-1">
                <p className="font-display text-xl font-semibold">{fullName}</p>
                <p className="truncate text-sm text-white/80">
                  {data?.profile.email || user?.email}
                </p>
                {data?.profile.currency && (
                  <p className="mt-1 inline-block rounded-full bg-white/15 px-2 py-0.5 text-xs">
                    {data.profile.currency}
                  </p>
                )}
              </div>
            </div>
          </div>
        </Card>
      )}

      {/* Sections */}
      {sections.map((sec) => (
        <div key={sec.title}>
          <h2 className="mb-2 px-1 text-xs font-semibold uppercase tracking-wider text-muted-foreground">
            {sec.title}
          </h2>
          <Card>
            <CardContent className="divide-y divide-border p-0">
              {sec.items.map((it) => (
                <Link
                  key={it.href}
                  href={it.href}
                  className="flex items-center gap-3 p-4 transition-colors hover:bg-accent/40"
                >
                  <div className="grid h-10 w-10 shrink-0 place-items-center rounded-lg bg-info-bg text-blue-900">
                    <it.icon className="h-4 w-4" />
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="font-medium">{it.label}</p>
                    <p className="text-xs text-muted-foreground">{it.desc}</p>
                  </div>
                  <ChevronRight className="h-4 w-4 text-muted-foreground" />
                </Link>
              ))}
            </CardContent>
          </Card>
        </div>
      ))}

      <Button
        variant="outline"
        className="w-full text-destructive hover:bg-destructive/10 hover:text-destructive"
        onClick={handleLogout}
      >
        <LogOut className="h-4 w-4" /> Keluar
      </Button>

      {data?.profile.about_info && (
        <p className="text-center text-xs text-muted-foreground">
          {data.profile.about_info.app_name} v{data.profile.about_info.version}{" "}
          (build {data.profile.about_info.build})
        </p>
      )}
    </div>
  );
}

"use client";

import * as React from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { Bell, LogOut, Menu, Settings, UserCircle } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { useAuthStore } from "@/store/auth";
import { authApi } from "@/lib/api/auth";
import { profileApi, notificationsApi } from "@/lib/api/profile";
import { greeting, initials } from "@/lib/utils";

export function Topbar({ onMenu }: { onMenu: () => void }) {
  const router = useRouter();
  const { user, logout } = useAuthStore();

  const { data: profile } = useQuery({
    queryKey: ["profile"],
    queryFn: profileApi.get,
    staleTime: 60_000,
  });

  const { data: notifs } = useQuery({
    queryKey: ["notifications", "count"],
    queryFn: () => notificationsApi.list({ per_page: 10 }),
    staleTime: 20_000,
    refetchInterval: 60_000,
  });

  const unread = (notifs ?? []).filter((n) => !n.read).length;
  const fullName = profile?.profile.full_name || user?.username || "User";
  const avatar = profile?.profile.avatar_path;

  const handleLogout = async () => {
    try {
      await authApi.logout();
    } catch {}
    logout();
    router.replace("/login");
  };

  return (
    <header className="sticky top-0 z-30 flex h-16 items-center gap-3 border-b border-border bg-card/85 px-4 backdrop-blur-md sm:px-6">
      <Button
        variant="ghost"
        size="icon"
        onClick={onMenu}
        className="lg:hidden"
        aria-label="Buka menu"
      >
        <Menu className="h-5 w-5" />
      </Button>

      <div className="flex-1 min-w-0">
        <p className="text-xs text-muted-foreground sm:text-sm">
          {greeting()},
        </p>
        <p className="truncate font-display text-base font-semibold sm:text-lg">
          {fullName} 👋
        </p>
      </div>

      <Link
        href="/notifications"
        className="relative grid h-10 w-10 place-items-center rounded-lg text-muted-foreground hover:bg-accent hover:text-foreground"
        aria-label="Notifikasi"
      >
        <Bell className="h-5 w-5" />
        {unread > 0 && (
          <span className="absolute right-1.5 top-1.5 grid h-4 min-w-4 place-items-center rounded-full bg-destructive px-1 text-[10px] font-bold text-white">
            {unread > 9 ? "9+" : unread}
          </span>
        )}
      </Link>

      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <button
            className="flex items-center gap-2 rounded-lg p-1 hover:bg-accent"
            aria-label="Profile menu"
          >
            <Avatar className="h-9 w-9">
              {avatar ? <AvatarImage src={avatar} alt={fullName} /> : null}
              <AvatarFallback>{initials(fullName)}</AvatarFallback>
            </Avatar>
          </button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end" className="w-56">
          <DropdownMenuLabel>{fullName}</DropdownMenuLabel>
          <p className="px-3 pb-2 text-xs text-muted-foreground truncate">
            {user?.email}
          </p>
          <DropdownMenuSeparator />
          <DropdownMenuItem asChild>
            <Link href="/profile">
              <UserCircle className="h-4 w-4" /> Profil
            </Link>
          </DropdownMenuItem>
          <DropdownMenuItem asChild>
            <Link href="/profile/notifications">
              <Settings className="h-4 w-4" /> Pengaturan
            </Link>
          </DropdownMenuItem>
          <DropdownMenuSeparator />
          <DropdownMenuItem
            onSelect={(e) => {
              e.preventDefault();
              void handleLogout();
            }}
            className="text-destructive focus:text-destructive"
          >
            <LogOut className="h-4 w-4" /> Logout
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    </header>
  );
}

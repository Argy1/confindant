"use client";

import * as React from "react";
import Link from "next/link";
import Image from "next/image";
import { usePathname } from "next/navigation";
import {
  LayoutDashboard,
  ArrowLeftRight,
  Wallet as WalletIcon,
  PieChart,
  Target,
  Repeat,
  Camera,
  MessageSquareText,
  User as UserIcon,
  X,
  Bell,
} from "lucide-react";
import { cn } from "@/lib/utils";

export type NavItem = {
  href: string;
  label: string;
  icon: React.ComponentType<{ className?: string }>;
};

export const navItems: NavItem[] = [
  { href: "/home", label: "Home", icon: LayoutDashboard },
  { href: "/transactions", label: "Transaksi", icon: ArrowLeftRight },
  { href: "/wallets", label: "Wallets", icon: WalletIcon },
  { href: "/analytics", label: "Analytics", icon: PieChart },
  { href: "/goals", label: "Goals", icon: Target },
  { href: "/recurring", label: "Recurring", icon: Repeat },
  { href: "/scan", label: "Scan Struk", icon: Camera },
  { href: "/finance-chat", label: "AI Chat", icon: MessageSquareText },
  { href: "/notifications", label: "Notifikasi", icon: Bell },
  { href: "/profile", label: "Profil", icon: UserIcon },
];

export function SidebarContent({ onNavigate }: { onNavigate?: () => void }) {
  const pathname = usePathname();
  return (
    <div className="flex h-full flex-col">
      <div className="flex items-center gap-2 px-5 pb-4 pt-5">
        <Image
          src="/logo.png"
          alt="Confindant"
          width={36}
          height={36}
          className="rounded-xl"
          priority
        />
        <span className="font-display text-lg font-bold tracking-tight">
          Confindant
        </span>
      </div>
      <nav className="flex-1 space-y-1 overflow-y-auto px-3">
        {navItems.map((item) => {
          const active =
            pathname === item.href || pathname.startsWith(item.href + "/");
          return (
            <Link
              key={item.href}
              href={item.href}
              onClick={onNavigate}
              className={cn(
                "group flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors",
                active
                  ? "bg-accent text-accent-foreground"
                  : "text-muted-foreground hover:bg-accent/60 hover:text-foreground",
              )}
            >
              <item.icon
                className={cn(
                  "h-4.5 w-4.5 transition-colors",
                  active ? "text-blue-900" : "text-muted-foreground group-hover:text-foreground",
                )}
              />
              <span>{item.label}</span>
            </Link>
          );
        })}
      </nav>
      <div className="px-3 pb-4 pt-2">
        <div className="rounded-xl border border-info-stroke bg-info-bg p-3 text-xs text-blue-900">
          <p className="font-semibold">💡 Tip</p>
          <p className="mt-1 text-blue-900/80">
            Pakai <strong>Scan Struk</strong> untuk catat transaksi otomatis lewat foto.
          </p>
        </div>
      </div>
    </div>
  );
}

export function MobileSidebar({
  open,
  onClose,
}: {
  open: boolean;
  onClose: () => void;
}) {
  React.useEffect(() => {
    if (open) {
      document.body.style.overflow = "hidden";
      return () => {
        document.body.style.overflow = "";
      };
    }
  }, [open]);

  return (
    <>
      {open && (
        <div
          className="fixed inset-0 z-40 bg-navy-900/55 backdrop-blur-sm lg:hidden"
          onClick={onClose}
        />
      )}
      <aside
        className={cn(
          "fixed inset-y-0 left-0 z-50 w-72 max-w-[85vw] border-r border-border bg-card shadow-2xl transition-transform duration-300 lg:hidden",
          open ? "translate-x-0" : "-translate-x-full",
        )}
        aria-hidden={!open}
      >
        <button
          onClick={onClose}
          className="absolute right-3 top-3 grid h-8 w-8 place-items-center rounded-md text-muted-foreground hover:bg-accent"
          aria-label="Tutup menu"
        >
          <X className="h-4 w-4" />
        </button>
        <SidebarContent onNavigate={onClose} />
      </aside>
    </>
  );
}

export function DesktopSidebar() {
  return (
    <aside className="sticky top-0 hidden h-screen w-64 shrink-0 border-r border-border bg-card lg:block">
      <SidebarContent />
    </aside>
  );
}

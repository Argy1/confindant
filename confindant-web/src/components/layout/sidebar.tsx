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
  BookOpen,
  BookText,
  ListTree,
  Scale,
  FileSpreadsheet,
  Landmark,
  HandCoins,
  PiggyBank,
  Upload,
  Sparkles,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { useOrgStore } from "@/store/org";

export type NavItem = {
  href: string;
  label: string;
  icon: React.ComponentType<{ className?: string }>;
};

export type NavGroup = {
  heading?: string;
  items: NavItem[];
};

export const personalNav: NavGroup[] = [
  {
    items: [
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
    ],
  },
];

export const orgNav: NavGroup[] = [
  {
    items: [{ href: "/org/dashboard", label: "Dashboard", icon: LayoutDashboard }],
  },
  {
    heading: "Pembukuan",
    items: [
      { href: "/org/journal", label: "Jurnal Umum", icon: BookText },
      { href: "/org/ledger", label: "Buku Besar", icon: BookOpen },
      { href: "/org/accounts", label: "Bagan Akun", icon: ListTree },
    ],
  },
  {
    heading: "Laporan",
    items: [
      { href: "/org/reports/balance-sheet", label: "Neraca", icon: Scale },
      { href: "/org/reports/activities", label: "Laporan Aktivitas", icon: FileSpreadsheet },
      { href: "/org/reports/trial-balance", label: "Neraca Saldo", icon: ListTree },
    ],
  },
  {
    heading: "Lainnya",
    items: [
      { href: "/org/fixed-assets", label: "Aktiva Tetap", icon: Landmark },
      { href: "/org/receivables-payables", label: "Piutang & Hutang", icon: HandCoins },
      { href: "/org/restricted-funds", label: "Dana Titipan", icon: PiggyBank },
      { href: "/org/import", label: "Import Excel", icon: Upload },
    ],
  },
  {
    heading: "AI & Tools",
    items: [
      { href: "/org/ai-chat", label: "AI Konsultan", icon: Sparkles },
      { href: "/org/scan", label: "Scan Struk", icon: Camera },
      { href: "/org/recurring", label: "Jurnal Berulang", icon: Repeat },
    ],
  },
];

// Back-compat export used by bottom-nav (personal mode quick nav).
export const navItems: NavItem[] = personalNav[0].items;

export function SidebarContent({ onNavigate }: { onNavigate?: () => void }) {
  const pathname = usePathname();
  const mode = useOrgStore((s) => s.mode);
  const groups = mode === "org" ? orgNav : personalNav;

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
      <nav className="flex-1 space-y-4 overflow-y-auto px-3">
        {groups.map((group, gi) => (
          <div key={gi} className="space-y-1">
            {group.heading && (
              <p className="px-3 pt-1 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground/70">
                {group.heading}
              </p>
            )}
            {group.items.map((item) => {
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
                      active
                        ? "text-blue-900"
                        : "text-muted-foreground group-hover:text-foreground",
                    )}
                  />
                  <span>{item.label}</span>
                </Link>
              );
            })}
          </div>
        ))}
      </nav>
      <div className="px-3 pb-4 pt-2">
        {mode === "org" ? (
          <div className="rounded-xl border border-info-stroke bg-info-bg p-3 text-xs text-blue-900">
            <p className="font-semibold">🏛️ Mode Organisasi</p>
            <p className="mt-1 text-blue-900/80">
              Pembukuan double-entry. Gunakan <strong>Import Excel</strong> untuk
              memuat data historis.
            </p>
          </div>
        ) : (
          <div className="rounded-xl border border-info-stroke bg-info-bg p-3 text-xs text-blue-900">
            <p className="font-semibold">💡 Tip</p>
            <p className="mt-1 text-blue-900/80">
              Pakai <strong>Scan Struk</strong> untuk catat transaksi otomatis lewat foto.
            </p>
          </div>
        )}
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

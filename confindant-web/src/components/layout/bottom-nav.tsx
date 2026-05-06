"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  LayoutDashboard,
  ArrowLeftRight,
  Camera,
  PieChart,
  User as UserIcon,
} from "lucide-react";
import { cn } from "@/lib/utils";

const items = [
  { href: "/home", label: "Home", icon: LayoutDashboard },
  { href: "/transactions", label: "Transaksi", icon: ArrowLeftRight },
  { href: "/scan", label: "Scan", icon: Camera, primary: true },
  { href: "/analytics", label: "Analytics", icon: PieChart },
  { href: "/profile", label: "Profil", icon: UserIcon },
];

export function BottomNav() {
  const pathname = usePathname();
  return (
    <nav className="sticky bottom-0 z-20 border-t border-border bg-card/95 backdrop-blur lg:hidden">
      <ul
        className="grid grid-cols-5 px-2 py-1.5"
        style={{ paddingBottom: "max(env(safe-area-inset-bottom), 0.375rem)" }}
      >
        {items.map((item) => {
          const active =
            pathname === item.href || pathname.startsWith(item.href + "/");
          if (item.primary) {
            return (
              <li key={item.href} className="relative">
                <Link
                  href={item.href}
                  className="absolute -top-6 left-1/2 grid h-14 w-14 -translate-x-1/2 place-items-center rounded-full gradient-hero text-white shadow-xl ring-4 ring-card"
                  aria-label={item.label}
                >
                  <item.icon className="h-6 w-6" />
                </Link>
                <span className="block h-0">&nbsp;</span>
              </li>
            );
          }
          return (
            <li key={item.href}>
              <Link
                href={item.href}
                className={cn(
                  "flex flex-col items-center gap-0.5 rounded-md py-2 text-[11px] transition-colors",
                  active
                    ? "text-blue-900"
                    : "text-muted-foreground hover:text-foreground",
                )}
              >
                <item.icon className="h-5 w-5" />
                {item.label}
              </Link>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}

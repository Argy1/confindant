import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatCurrency(
  value: number | string | null | undefined,
  options?: { withSymbol?: boolean; locale?: string },
): string {
  const num =
    typeof value === "string" ? Number(value) : (value ?? 0);
  if (!Number.isFinite(num)) return "Rp 0";
  const { withSymbol = true, locale = "id-ID" } = options ?? {};
  const formatted = new Intl.NumberFormat(locale, {
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(num);
  return withSymbol ? `Rp ${formatted}` : formatted;
}

export function formatNumber(value: number | string | null | undefined): string {
  const num = typeof value === "string" ? Number(value) : (value ?? 0);
  if (!Number.isFinite(num)) return "0";
  return new Intl.NumberFormat("id-ID").format(num);
}

/**
 * Compact currency for dashboard cards: Rp 7,29 M / Rp 550 jt / Rp 12 rb.
 */
export function formatCompactCurrency(
  value: number | string | null | undefined,
): string {
  const num = typeof value === "string" ? Number(value) : (value ?? 0);
  if (!Number.isFinite(num)) return "Rp 0";
  const abs = Math.abs(num);
  const sign = num < 0 ? "-" : "";
  if (abs >= 1_000_000_000)
    return `${sign}Rp ${(abs / 1_000_000_000).toFixed(2)} M`;
  if (abs >= 1_000_000) return `${sign}Rp ${(abs / 1_000_000).toFixed(1)} jt`;
  if (abs >= 1_000) return `${sign}Rp ${(abs / 1_000).toFixed(0)} rb`;
  return `${sign}Rp ${abs.toFixed(0)}`;
}

export function formatDate(
  iso: string | Date | null | undefined,
  opts?: Intl.DateTimeFormatOptions,
): string {
  if (!iso) return "-";
  try {
    const d = typeof iso === "string" ? new Date(iso) : iso;
    return new Intl.DateTimeFormat("id-ID", {
      day: "2-digit",
      month: "short",
      year: "numeric",
      ...opts,
    }).format(d);
  } catch {
    return "-";
  }
}

export function formatDateTime(iso: string | Date | null | undefined): string {
  if (!iso) return "-";
  try {
    const d = typeof iso === "string" ? new Date(iso) : iso;
    return new Intl.DateTimeFormat("id-ID", {
      day: "2-digit",
      month: "short",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    }).format(d);
  } catch {
    return "-";
  }
}

export function relativeTime(iso: string | Date | null | undefined): string {
  if (!iso) return "";
  const d = typeof iso === "string" ? new Date(iso) : iso;
  const diff = Date.now() - d.getTime();
  const sec = Math.round(diff / 1000);
  const min = Math.round(sec / 60);
  const hr = Math.round(min / 60);
  const day = Math.round(hr / 24);
  if (sec < 60) return "baru saja";
  if (min < 60) return `${min} menit lalu`;
  if (hr < 24) return `${hr} jam lalu`;
  if (day < 30) return `${day} hari lalu`;
  return formatDate(d);
}

export function greeting(date = new Date()): string {
  const h = date.getHours();
  if (h < 11) return "Selamat pagi";
  if (h < 15) return "Selamat siang";
  if (h < 18) return "Selamat sore";
  return "Selamat malam";
}

export function initials(name: string | undefined | null): string {
  if (!name) return "U";
  return name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((p) => p[0]?.toUpperCase() ?? "")
    .join("") || "U";
}

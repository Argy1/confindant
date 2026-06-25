// Indonesian labels for account subtypes used in report grouping.

export const SUBTYPE_LABELS: Record<string, string> = {
  current_asset: "Aset Lancar",
  fixed_asset: "Aset Tidak Lancar",
  current_liability: "Kewajiban Lancar",
  restricted_fund: "Dana Titipan",
  unrestricted: "Tanpa Pembatasan",
  restricted: "Dengan Pembatasan",
  operating_revenue: "Pendapatan Operasi",
  other_revenue: "Pendapatan Lain",
  program_expense: "Beban Kegiatan",
  admin_expense: "Beban Kesekretariatan",
  other_expense: "Beban Lain-Lain",
  lain: "Lainnya",
};

export function subtypeLabel(subtype?: string | null): string {
  if (!subtype) return "Lainnya";
  return SUBTYPE_LABELS[subtype] ?? subtype;
}

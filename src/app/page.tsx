"use client";

import * as React from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  ArrowRight,
  BarChart3,
  Camera,
  CheckCircle2,
  Coffee,
  PiggyBank,
  ShieldCheck,
  ShoppingBag,
  Sparkles,
  TrendingUp,
  Wallet,
} from "lucide-react";
import { useAuthStore } from "@/store/auth";

const HERO_GRADIENT =
  "linear-gradient(135deg, #000314 0%, #0a2472 50%, #0e6ba8 100%)";
const BRAND_GRADIENT = "linear-gradient(135deg, #0a2472 0%, #0e6ba8 100%)";
const CARD_HEAD_GRADIENT =
  "linear-gradient(135deg, #000314 0%, #0a2472 60%, #114b9c 100%)";

export default function LandingPage() {
  const router = useRouter();
  const { token, hydrated } = useAuthStore();

  React.useEffect(() => {
    if (hydrated && token) router.replace("/home");
  }, [hydrated, token, router]);

  return (
    <main className="min-h-screen overflow-x-hidden bg-white text-slate-900">
      {/* Header */}
      <header className="sticky top-0 z-50 border-b border-slate-200/70 bg-white/80 backdrop-blur-xl">
        <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
          <Link href="/" className="flex items-center gap-2.5">
            <div
              className="grid h-9 w-9 place-items-center rounded-xl shadow-md shadow-blue-900/20"
              style={{ background: BRAND_GRADIENT }}
            >
              <Wallet className="h-5 w-5 text-white" />
            </div>
            <span
              className="font-display text-xl font-bold tracking-tight"
              style={{ fontFamily: "var(--font-display)" }}
            >
              Confindant
            </span>
          </Link>
          <div className="flex items-center gap-2">
            <Link
              href="/login"
              className="hidden rounded-lg px-4 py-2 text-sm font-medium text-slate-700 transition-colors hover:bg-slate-100 sm:inline-flex"
            >
              Masuk
            </Link>
            <Link
              href="/register"
              className="inline-flex items-center gap-2 rounded-lg px-4 py-2 text-sm font-semibold text-white shadow-lg shadow-blue-900/20 transition-all hover:shadow-xl hover:shadow-blue-900/30 active:translate-y-px"
              style={{ background: BRAND_GRADIENT }}
            >
              Mulai Gratis <ArrowRight className="h-4 w-4" />
            </Link>
          </div>
        </div>
      </header>

      {/* Hero */}
      <section
        className="relative overflow-hidden text-white"
        style={{ background: HERO_GRADIENT }}
      >
        {/* Decorative orbs */}
        <div
          className="pointer-events-none absolute -right-24 -top-24 h-112 w-md rounded-full blur-3xl"
          style={{
            background:
              "radial-gradient(circle, rgba(43,135,200,0.45), transparent 70%)",
          }}
        />
        <div
          className="pointer-events-none absolute -bottom-32 -left-24 h-112 w-md rounded-full blur-3xl"
          style={{
            background:
              "radial-gradient(circle, rgba(14,107,168,0.35), transparent 70%)",
          }}
        />
        {/* Grid pattern */}
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0 opacity-[0.06]"
          style={{
            backgroundImage:
              "linear-gradient(white 1px, transparent 1px), linear-gradient(90deg, white 1px, transparent 1px)",
            backgroundSize: "44px 44px",
          }}
        />

        <div className="relative mx-auto max-w-7xl px-4 py-20 sm:px-6 sm:py-24 lg:px-8 lg:py-32">
          <div className="grid items-center gap-12 lg:grid-cols-2">
            <div>
              <div className="inline-flex items-center gap-1.5 rounded-full border border-white/25 bg-white/10 px-3 py-1.5 text-xs font-medium text-white/95 backdrop-blur">
                <Sparkles className="h-3.5 w-3.5 text-blue-300" />
                Powered by Gemini AI
              </div>
              <h1
                className="mt-5 font-bold leading-[1.05] tracking-tight"
                style={{
                  fontFamily: "var(--font-display)",
                  fontSize: "clamp(2.5rem, 5.5vw, 4.5rem)",
                  letterSpacing: "-0.02em",
                }}
              >
                Kelola Keuangan,
                <br />
                <span
                  style={{
                    background:
                      "linear-gradient(90deg, #ffffff 0%, #a6e1fa 100%)",
                    WebkitBackgroundClip: "text",
                    WebkitTextFillColor: "transparent",
                    backgroundClip: "text",
                  }}
                >
                  Lebih Cerdas.
                </span>
              </h1>
              <p className="mt-5 max-w-xl text-base text-white/80 sm:text-lg">
                Confindant bantu kamu lacak setiap pengeluaran, scan struk
                otomatis, kelola budget per kategori, dan dapatkan insight
                personal — semua di satu tempat.
              </p>
              <div className="mt-8 flex flex-wrap gap-3">
                <Link
                  href="/register"
                  className="inline-flex h-12 items-center gap-2 rounded-xl bg-white px-6 text-base font-semibold text-slate-900 shadow-2xl shadow-black/20 transition-all hover:bg-white/95 hover:shadow-xl active:translate-y-px"
                >
                  Buat Akun Gratis <ArrowRight className="h-4 w-4" />
                </Link>
                <Link
                  href="/login"
                  className="inline-flex h-12 items-center gap-2 rounded-xl border border-white/25 bg-white/5 px-6 text-base font-medium text-white backdrop-blur transition-colors hover:bg-white/15"
                >
                  Sudah Punya Akun
                </Link>
              </div>
              <div className="mt-10 flex flex-wrap gap-x-6 gap-y-3 text-sm text-white/75">
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="h-4 w-4 text-blue-300" />
                  Token-based auth
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="h-4 w-4 text-blue-300" />
                  Gemini AI categorization
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="h-4 w-4 text-blue-300" />
                  OCR receipt scanner
                </div>
              </div>
            </div>

            {/* Hero card preview */}
            <div className="relative">
              <div
                className="absolute -inset-8 z-0 rounded-4xl blur-3xl"
                style={{
                  background:
                    "radial-gradient(circle at 50% 50%, rgba(255,255,255,0.18), transparent 70%)",
                }}
              />
              <div
                className="relative rotate-1 rounded-2xl border border-white/15 bg-white"
                style={{
                  boxShadow:
                    "0 30px 80px -20px rgba(0,0,0,0.6), 0 8px 30px -10px rgba(0,0,0,0.3)",
                }}
              >
                <div
                  className="rounded-t-2xl p-6 text-white"
                  style={{ background: CARD_HEAD_GRADIENT }}
                >
                  <div className="flex items-center justify-between">
                    <p className="text-[11px] font-medium uppercase tracking-[0.18em] text-white/60">
                      Total Saldo
                    </p>
                    <span className="rounded-full border border-emerald-300/30 bg-emerald-400/10 px-2 py-0.5 text-[10px] font-semibold text-emerald-300">
                      ↑ 12.4%
                    </span>
                  </div>
                  <p
                    className="mt-1 font-bold tracking-tight"
                    style={{
                      fontFamily: "var(--font-display)",
                      fontSize: "clamp(1.75rem, 4vw, 2.5rem)",
                    }}
                  >
                    Rp 24.580.000
                  </p>
                  <div className="mt-4 grid grid-cols-2 gap-3 text-xs">
                    <div className="rounded-lg bg-white/10 p-3 backdrop-blur">
                      <p className="text-white/65">Pemasukan</p>
                      <p className="mt-0.5 text-base font-semibold text-emerald-300">
                        + Rp 8.2M
                      </p>
                    </div>
                    <div className="rounded-lg bg-white/10 p-3 backdrop-blur">
                      <p className="text-white/65">Pengeluaran</p>
                      <p className="mt-0.5 text-base font-semibold text-amber-300">
                        − Rp 3.6M
                      </p>
                    </div>
                  </div>
                </div>
                <div className="space-y-1 p-3">
                  {previewTx.map((tx) => (
                    <div
                      key={tx.label}
                      className="flex items-center gap-3 rounded-lg p-2.5 transition-colors hover:bg-slate-50"
                    >
                      <div
                        className="grid h-9 w-9 shrink-0 place-items-center rounded-lg"
                        style={{
                          background: tx.bg,
                          color: tx.fg,
                        }}
                      >
                        <tx.icon className="h-4 w-4" />
                      </div>
                      <div className="min-w-0 flex-1">
                        <p className="truncate text-sm font-medium text-slate-900">
                          {tx.label}
                        </p>
                        <p className="text-xs text-slate-500">{tx.cat}</p>
                      </div>
                      <p
                        className={`shrink-0 text-sm font-semibold tabular-nums ${
                          tx.amt > 0 ? "text-emerald-600" : "text-slate-900"
                        }`}
                      >
                        {tx.amt > 0 ? "+" : ""}
                        {new Intl.NumberFormat("id-ID").format(tx.amt)}
                      </p>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Trust strip */}
      <section className="border-y border-slate-200 bg-white">
        <div className="mx-auto grid max-w-7xl gap-y-6 px-4 py-10 sm:grid-cols-3 sm:px-6 lg:px-8">
          {stats.map((s) => (
            <div key={s.label} className="text-center">
              <p
                className="font-bold tracking-tight text-slate-900"
                style={{
                  fontFamily: "var(--font-display)",
                  fontSize: "clamp(1.75rem, 3vw, 2.25rem)",
                }}
              >
                {s.value}
              </p>
              <p className="mt-1 text-sm text-slate-600">{s.label}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Features */}
      <section className="mx-auto max-w-7xl px-4 py-20 sm:px-6 sm:py-24 lg:px-8">
        <div className="mx-auto max-w-2xl text-center">
          <div className="inline-flex items-center gap-1.5 rounded-full border border-blue-200 bg-blue-50 px-3 py-1 text-xs font-semibold uppercase tracking-wider text-blue-900">
            Semua yang kamu butuhkan
          </div>
          <h2
            className="mt-4 font-bold tracking-tight text-slate-900"
            style={{
              fontFamily: "var(--font-display)",
              fontSize: "clamp(1.875rem, 3.5vw, 3rem)",
              letterSpacing: "-0.02em",
            }}
          >
            Fitur lengkap untuk personal finance
          </h2>
          <p className="mt-4 text-base text-slate-600 sm:text-lg">
            Web companion untuk Confindant mobile — semua fitur, di layar yang
            lebih luas.
          </p>
        </div>

        <div className="mt-14 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {features.map((f) => (
            <div
              key={f.title}
              className="group relative overflow-hidden rounded-2xl border border-slate-200 bg-white p-6 transition-all duration-300 hover:-translate-y-1 hover:border-blue-300 hover:shadow-2xl hover:shadow-blue-900/10"
            >
              <div
                aria-hidden
                className="pointer-events-none absolute -right-16 -top-16 h-40 w-40 rounded-full opacity-0 blur-2xl transition-opacity duration-500 group-hover:opacity-100"
                style={{
                  background:
                    "radial-gradient(circle, rgba(14,107,168,0.25), transparent)",
                }}
              />
              <div
                className="relative grid h-12 w-12 place-items-center rounded-xl text-white shadow-lg"
                style={{ background: f.gradient }}
              >
                <f.icon className="h-6 w-6" />
              </div>
              <h3
                className="relative mt-5 font-semibold text-slate-900"
                style={{
                  fontFamily: "var(--font-display)",
                  fontSize: "1.125rem",
                }}
              >
                {f.title}
              </h3>
              <p className="relative mt-2 text-sm leading-relaxed text-slate-600">
                {f.desc}
              </p>
            </div>
          ))}
        </div>
      </section>

      {/* How it works */}
      <section className="bg-slate-50 py-20 sm:py-24">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="mx-auto max-w-2xl text-center">
            <div className="inline-flex items-center gap-1.5 rounded-full border border-slate-300 bg-white px-3 py-1 text-xs font-semibold uppercase tracking-wider text-slate-700">
              Cara kerja
            </div>
            <h2
              className="mt-4 font-bold tracking-tight text-slate-900"
              style={{
                fontFamily: "var(--font-display)",
                fontSize: "clamp(1.875rem, 3.5vw, 2.5rem)",
                letterSpacing: "-0.02em",
              }}
            >
              Tiga langkah, semua otomatis
            </h2>
          </div>

          <div className="mx-auto mt-14 grid max-w-5xl gap-6 sm:grid-cols-3">
            {steps.map((s, i) => (
              <div
                key={s.title}
                className="relative rounded-2xl border border-slate-200 bg-white p-6 shadow-sm"
              >
                <div
                  className="grid h-11 w-11 place-items-center rounded-xl font-bold text-white shadow-md shadow-blue-900/20"
                  style={{
                    background: BRAND_GRADIENT,
                    fontFamily: "var(--font-display)",
                    fontSize: "1.125rem",
                  }}
                >
                  {i + 1}
                </div>
                <h3
                  className="mt-4 font-semibold text-slate-900"
                  style={{
                    fontFamily: "var(--font-display)",
                    fontSize: "1.125rem",
                  }}
                >
                  {s.title}
                </h3>
                <p className="mt-2 text-sm leading-relaxed text-slate-600">
                  {s.desc}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="mx-auto max-w-7xl px-4 py-20 sm:px-6 sm:py-24 lg:px-8">
        <div
          className="relative overflow-hidden rounded-4xl px-6 py-16 text-center text-white sm:px-12 sm:py-20"
          style={{ background: HERO_GRADIENT }}
        >
          <div
            aria-hidden
            className="pointer-events-none absolute -right-32 -top-32 h-72 w-72 rounded-full blur-3xl"
            style={{
              background:
                "radial-gradient(circle, rgba(43,135,200,0.55), transparent 70%)",
            }}
          />
          <div
            aria-hidden
            className="pointer-events-none absolute -bottom-32 -left-32 h-72 w-72 rounded-full blur-3xl"
            style={{
              background:
                "radial-gradient(circle, rgba(14,107,168,0.4), transparent 70%)",
            }}
          />
          <div className="relative">
            <h2
              className="font-bold tracking-tight"
              style={{
                fontFamily: "var(--font-display)",
                fontSize: "clamp(1.875rem, 4vw, 3rem)",
                letterSpacing: "-0.02em",
              }}
            >
              Siap kelola uang lebih baik?
            </h2>
            <p className="mx-auto mt-4 max-w-md text-base text-white/80">
              Gratis, tidak ada kartu kredit. Mulai sekarang dalam 30 detik.
            </p>
            <div className="mt-8 flex justify-center">
              <Link
                href="/register"
                className="inline-flex h-12 items-center gap-2 rounded-xl bg-white px-7 text-base font-semibold text-slate-900 shadow-2xl shadow-black/30 transition-all hover:bg-white/95 active:translate-y-px"
              >
                Buat Akun Sekarang <ArrowRight className="h-4 w-4" />
              </Link>
            </div>
          </div>
        </div>
      </section>

      <footer className="border-t border-slate-200 bg-white">
        <div className="mx-auto flex max-w-7xl flex-col gap-3 px-4 py-8 text-sm text-slate-500 sm:flex-row sm:items-center sm:justify-between sm:px-6 lg:px-8">
          <div className="flex items-center gap-2">
            <div
              className="grid h-7 w-7 place-items-center rounded-lg"
              style={{ background: BRAND_GRADIENT }}
            >
              <Wallet className="h-3.5 w-3.5 text-white" />
            </div>
            <p>© {new Date().getFullYear()} Confindant. All rights reserved.</p>
          </div>
          <p className="text-xs">
            Backend Laravel · Frontend Next.js · Mobile Flutter
          </p>
        </div>
      </footer>
    </main>
  );
}

const previewTx = [
  {
    label: "Starbucks Coffee",
    cat: "Food & Drink",
    amt: -45000,
    icon: Coffee,
    bg: "#fef3c7",
    fg: "#b45309",
  },
  {
    label: "Gaji Bulanan",
    cat: "Income",
    amt: 8200000,
    icon: TrendingUp,
    bg: "#d1fae5",
    fg: "#047857",
  },
  {
    label: "Indomaret",
    cat: "Groceries",
    amt: -127500,
    icon: ShoppingBag,
    bg: "#dbeafe",
    fg: "#1e40af",
  },
];

const stats = [
  { value: "12+", label: "Modul fitur lengkap" },
  { value: "AI", label: "OCR & kategorisasi otomatis" },
  { value: "Rp 0", label: "Gratis tanpa kartu kredit" },
];

const features = [
  {
    icon: Wallet,
    title: "Multi-wallet",
    desc: "Kelola banyak dompet, transfer antar wallet, dan pantau saldo real-time di satu tempat.",
    gradient: "linear-gradient(135deg, #0a2472 0%, #0e6ba8 100%)",
  },
  {
    icon: Camera,
    title: "Scan Struk OCR",
    desc: "Foto struk → otomatis dibaca AI dan jadi transaksi tervalidasi tanpa input manual.",
    gradient: "linear-gradient(135deg, #0e6ba8 0%, #2b87c8 100%)",
  },
  {
    icon: BarChart3,
    title: "Analytics Pintar",
    desc: "Insight pengeluaran berdasarkan kategori, tag, dan periode dengan chart interaktif.",
    gradient: "linear-gradient(135deg, #114b9c 0%, #0e6ba8 100%)",
  },
  {
    icon: PiggyBank,
    title: "Goals & Budget",
    desc: "Target tabungan dengan auto-topup dan budget per kategori dengan alert threshold.",
    gradient: "linear-gradient(135deg, #0a2472 0%, #114b9c 100%)",
  },
  {
    icon: Sparkles,
    title: "AI Finance Chat",
    desc: "Tanya keuangan kamu dalam bahasa natural, jawaban langsung dari data transaksimu.",
    gradient: "linear-gradient(135deg, #0e6ba8 0%, #2b87c8 100%)",
  },
  {
    icon: ShieldCheck,
    title: "Aman & Privat",
    desc: "Token-based auth, terenkripsi end-to-end, dan tidak ada data yang dijual ke pihak ketiga.",
    gradient: "linear-gradient(135deg, #000314 0%, #0a2472 100%)",
  },
];

const steps = [
  {
    title: "Hubungkan & atur dompet",
    desc: "Tambah wallet kamu — cash, bank, e-wallet — dan set saldo awal dalam beberapa detik.",
  },
  {
    title: "Catat atau scan struk",
    desc: "Tambah transaksi manual atau cukup foto struk untuk auto-fill via OCR + AI.",
  },
  {
    title: "Pantau dengan AI",
    desc: "Lihat insight, budget, dan tanya finance chat untuk advice instan kapan saja.",
  },
];

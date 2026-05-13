"use client";

import * as React from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import Image from "next/image";
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

/* ─── Brand colours (exact palette) ─────────────────────────────────── */
const NAVY    = "#000314";
const BLUE900  = "#0a2472";
const BLUE700  = "#114b9c";
const BLUE600  = "#0e6ba8";
const BLUE500  = "#2b87c8";

export default function LandingPage() {
  const router = useRouter();
  const { token, hydrated } = useAuthStore();

  React.useEffect(() => {
    if (hydrated && token) router.replace("/home");
  }, [hydrated, token, router]);

  return (
    <main
      style={{ backgroundColor: NAVY, color: "#ffffff" }}
      className="min-h-screen overflow-x-hidden"
    >
      {/* ── Header ──────────────────────────────────────────────────── */}
      <header
        className="sticky top-0 z-50 backdrop-blur-xl"
        style={{
          backgroundColor: "rgba(0,3,20,0.85)",
          borderBottom: `1px solid rgba(255,255,255,0.08)`,
        }}
      >
        <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
          <Link href="/" className="flex items-center gap-2.5">
            <Image
              src="/logo.png"
              alt="Confindant"
              width={36}
              height={36}
              className="rounded-xl"
              style={{ boxShadow: `0 4px 14px rgba(14,107,168,0.45)` }}
              priority
            />
            <span
              className="text-xl font-bold tracking-tight text-white"
              style={{ fontFamily: "var(--font-display)" }}
            >
              Confindant
            </span>
          </Link>

          <div className="flex items-center gap-2">
            <Link
              href="/login"
              className="hidden rounded-lg px-4 py-2 text-sm font-medium text-white/70 transition-colors hover:bg-white/10 hover:text-white sm:inline-flex"
            >
              Masuk
            </Link>
            <Link
              href="/register"
              className="inline-flex items-center gap-2 rounded-xl px-5 py-2.5 text-sm font-semibold text-white transition-all hover:opacity-90 active:translate-y-px"
              style={{
                backgroundImage: `linear-gradient(135deg, ${BLUE700}, ${BLUE500})`,
                boxShadow: `0 4px 20px rgba(43,135,200,0.35)`,
              }}
            >
              Mulai Gratis <ArrowRight className="h-4 w-4" />
            </Link>
          </div>
        </div>
      </header>

      {/* ── Hero ────────────────────────────────────────────────────── */}
      <section
        className="relative overflow-hidden"
        style={{
          backgroundImage: `linear-gradient(135deg, ${NAVY} 0%, ${BLUE900} 55%, ${BLUE600} 100%)`,
        }}
      >
        {/* Glow orbs */}
        <div
          aria-hidden
          className="pointer-events-none absolute right-0 top-0 h-[40rem] w-[40rem] -translate-y-1/2 translate-x-1/3 rounded-full"
          style={{
            background: `radial-gradient(circle, rgba(43,135,200,0.35) 0%, transparent 70%)`,
          }}
        />
        <div
          aria-hidden
          className="pointer-events-none absolute bottom-0 left-0 h-[32rem] w-[32rem] translate-y-1/2 -translate-x-1/3 rounded-full"
          style={{
            background: `radial-gradient(circle, rgba(14,107,168,0.3) 0%, transparent 70%)`,
          }}
        />
        {/* Subtle grid */}
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0"
          style={{
            backgroundImage: `linear-gradient(rgba(255,255,255,0.04) 1px, transparent 1px),
              linear-gradient(90deg, rgba(255,255,255,0.04) 1px, transparent 1px)`,
            backgroundSize: "44px 44px",
          }}
        />

        <div className="relative mx-auto max-w-7xl px-4 py-20 sm:px-6 sm:py-28 lg:px-8 lg:py-36">
          <div className="grid items-center gap-14 lg:grid-cols-2">
            {/* Left — copy */}
            <div>
              <div
                className="mb-5 inline-flex items-center gap-2 rounded-full px-3.5 py-1.5 text-xs font-semibold text-white"
                style={{
                  backgroundColor: "rgba(43,135,200,0.18)",
                  border: "1px solid rgba(43,135,200,0.35)",
                }}
              >
                <Sparkles className="h-3.5 w-3.5" style={{ color: BLUE500 }} />
                Powered by Gemini AI
              </div>

              <h1
                className="font-bold leading-tight tracking-tight text-white"
                style={{
                  fontFamily: "var(--font-display)",
                  fontSize: "clamp(2.4rem, 5.5vw, 4.25rem)",
                  letterSpacing: "-0.025em",
                }}
              >
                Kelola Keuangan,
                <br />
                <span
                  style={{
                    backgroundImage: `linear-gradient(90deg, #ffffff 0%, #a6e1fa 100%)`,
                    WebkitBackgroundClip: "text",
                    WebkitTextFillColor: "transparent",
                    backgroundClip: "text",
                  }}
                >
                  Lebih Cerdas.
                </span>
              </h1>

              <p className="mt-5 max-w-lg text-base leading-relaxed text-white/70 sm:text-lg">
                Lacak pengeluaran, scan struk otomatis, kelola budget per
                kategori, dan dapatkan insight personal — semua di satu
                tempat.
              </p>

              <div className="mt-8 flex flex-wrap gap-3">
                <Link
                  href="/register"
                  className="inline-flex h-12 items-center gap-2 rounded-xl px-7 text-base font-semibold text-slate-900 transition-all hover:opacity-95 active:translate-y-px"
                  style={{
                    backgroundColor: "#ffffff",
                    boxShadow: "0 8px 32px rgba(0,0,0,0.3)",
                  }}
                >
                  Buat Akun Gratis <ArrowRight className="h-4 w-4" />
                </Link>
                <Link
                  href="/login"
                  className="inline-flex h-12 items-center gap-2 rounded-xl border px-7 text-base font-medium text-white transition-colors hover:bg-white/10"
                  style={{ borderColor: "rgba(255,255,255,0.25)" }}
                >
                  Masuk Sekarang
                </Link>
              </div>

              <div className="mt-10 flex flex-wrap gap-x-6 gap-y-2.5 text-sm text-white/60">
                {["Token-based auth", "Gemini AI categorization", "OCR receipt scanner"].map((t) => (
                  <span key={t} className="flex items-center gap-2">
                    <CheckCircle2 className="h-4 w-4 shrink-0" style={{ color: BLUE500 }} />
                    {t}
                  </span>
                ))}
              </div>
            </div>

            {/* Right — dashboard card */}
            <div className="relative">
              <div
                aria-hidden
                className="absolute inset-0 rounded-3xl blur-3xl"
                style={{
                  background: `radial-gradient(circle at 50% 50%, rgba(43,135,200,0.25), transparent 70%)`,
                  transform: "scale(1.15)",
                }}
              />
              <div
                className="relative rotate-1 overflow-hidden rounded-2xl"
                style={{
                  backgroundColor: "rgba(255,255,255,0.04)",
                  border: "1px solid rgba(255,255,255,0.12)",
                  boxShadow: "0 30px 80px -15px rgba(0,0,0,0.7)",
                  backdropFilter: "blur(8px)",
                }}
              >
                {/* Card header */}
                <div
                  className="p-6"
                  style={{
                    backgroundImage: `linear-gradient(135deg, ${NAVY} 0%, ${BLUE900} 55%, ${BLUE700} 100%)`,
                  }}
                >
                  <div className="flex items-center justify-between">
                    <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-white/50">
                      Total Saldo
                    </p>
                    <span
                      className="rounded-full px-2.5 py-0.5 text-[10px] font-bold text-emerald-300"
                      style={{
                        backgroundColor: "rgba(52,211,153,0.15)",
                        border: "1px solid rgba(52,211,153,0.25)",
                      }}
                    >
                      ↑ 12.4%
                    </span>
                  </div>
                  <p
                    className="mt-2 font-bold text-white"
                    style={{
                      fontFamily: "var(--font-display)",
                      fontSize: "clamp(1.75rem, 3.5vw, 2.5rem)",
                      letterSpacing: "-0.02em",
                    }}
                  >
                    Rp 24.580.000
                  </p>
                  <div className="mt-4 grid grid-cols-2 gap-3 text-xs">
                    {[
                      { label: "Pemasukan", val: "+ Rp 8.2M", color: "#6ee7b7" },
                      { label: "Pengeluaran", val: "− Rp 3.6M", color: "#fcd34d" },
                    ].map((s) => (
                      <div
                        key={s.label}
                        className="rounded-xl p-3"
                        style={{ backgroundColor: "rgba(255,255,255,0.09)" }}
                      >
                        <p className="text-white/55">{s.label}</p>
                        <p
                          className="mt-0.5 text-base font-semibold"
                          style={{ color: s.color }}
                        >
                          {s.val}
                        </p>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Transaction list */}
                <div
                  className="space-y-1 p-3"
                  style={{ backgroundColor: "rgba(255,255,255,0.97)" }}
                >
                  {previewTx.map((tx) => (
                    <div
                      key={tx.label}
                      className="flex items-center gap-3 rounded-xl px-3 py-2.5 transition-colors hover:bg-slate-50"
                    >
                      <div
                        className="grid h-9 w-9 shrink-0 place-items-center rounded-lg"
                        style={{ backgroundColor: tx.bg }}
                      >
                        <tx.icon className="h-4 w-4" style={{ color: tx.fg }} />
                      </div>
                      <div className="min-w-0 flex-1">
                        <p className="truncate text-sm font-semibold text-slate-800">
                          {tx.label}
                        </p>
                        <p className="text-xs text-slate-500">{tx.cat}</p>
                      </div>
                      <p
                        className="shrink-0 text-sm font-bold tabular-nums"
                        style={{ color: tx.amt > 0 ? "#059669" : "#1e293b" }}
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

      {/* ── Stats strip ─────────────────────────────────────────────── */}
      <section
        style={{
          backgroundColor: BLUE900,
          borderTop: "1px solid rgba(255,255,255,0.08)",
          borderBottom: "1px solid rgba(255,255,255,0.08)",
        }}
      >
        <div className="mx-auto grid max-w-7xl gap-y-8 px-4 py-10 sm:grid-cols-3 sm:px-6 lg:px-8">
          {stats.map((s) => (
            <div key={s.label} className="text-center">
              <p
                className="font-bold text-white"
                style={{
                  fontFamily: "var(--font-display)",
                  fontSize: "clamp(2rem, 3vw, 2.75rem)",
                  letterSpacing: "-0.02em",
                }}
              >
                {s.value}
              </p>
              <p className="mt-1 text-sm text-white/60">{s.label}</p>
            </div>
          ))}
        </div>
      </section>

      {/* ── Features ─────────────────────────────────────────────────── */}
      <section
        className="mx-auto max-w-7xl px-4 py-20 sm:px-6 sm:py-28 lg:px-8"
      >
        <div className="mx-auto max-w-2xl text-center">
          <div
            className="mb-4 inline-flex items-center gap-1.5 rounded-full px-3.5 py-1 text-xs font-semibold uppercase tracking-wider text-white"
            style={{
              backgroundColor: "rgba(43,135,200,0.18)",
              border: `1px solid rgba(43,135,200,0.35)`,
            }}
          >
            Semua yang kamu butuhkan
          </div>
          <h2
            className="font-bold tracking-tight text-white"
            style={{
              fontFamily: "var(--font-display)",
              fontSize: "clamp(1.875rem, 3.5vw, 3rem)",
              letterSpacing: "-0.025em",
            }}
          >
            Fitur lengkap untuk personal finance
          </h2>
          <p className="mt-4 text-base text-white/60 sm:text-lg">
            Web companion untuk Confindant mobile — semua fitur, di layar
            yang lebih luas.
          </p>
        </div>

        <div className="mt-14 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {features.map((f) => (
            <div
              key={f.title}
              className="group relative overflow-hidden rounded-2xl p-6 transition-all duration-300 hover:-translate-y-1"
              style={{
                backgroundColor: "rgba(255,255,255,0.05)",
                border: "1px solid rgba(255,255,255,0.1)",
              }}
            >
              {/* Hover glow */}
              <div
                aria-hidden
                className="pointer-events-none absolute -right-12 -top-12 h-40 w-40 rounded-full opacity-0 blur-2xl transition-opacity duration-500 group-hover:opacity-100"
                style={{
                  background: `radial-gradient(circle, ${BLUE500}66, transparent)`,
                }}
              />
              <div
                className="relative grid h-12 w-12 place-items-center rounded-xl text-white"
                style={{
                  backgroundImage: f.gradient,
                  boxShadow: `0 4px 16px rgba(14,107,168,0.4)`,
                }}
              >
                <f.icon className="h-6 w-6" />
              </div>
              <h3
                className="relative mt-5 font-semibold text-white"
                style={{
                  fontFamily: "var(--font-display)",
                  fontSize: "1.125rem",
                }}
              >
                {f.title}
              </h3>
              <p className="relative mt-2 text-sm leading-relaxed text-white/60">
                {f.desc}
              </p>
            </div>
          ))}
        </div>
      </section>

      {/* ── How it works ─────────────────────────────────────────────── */}
      <section
        className="py-20 sm:py-24"
        style={{ backgroundColor: BLUE900 }}
      >
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="mx-auto max-w-2xl text-center">
            <div
              className="mb-4 inline-flex items-center gap-1.5 rounded-full px-3.5 py-1 text-xs font-semibold uppercase tracking-wider text-white"
              style={{
                backgroundColor: "rgba(255,255,255,0.08)",
                border: "1px solid rgba(255,255,255,0.15)",
              }}
            >
              Cara kerja
            </div>
            <h2
              className="font-bold tracking-tight text-white"
              style={{
                fontFamily: "var(--font-display)",
                fontSize: "clamp(1.875rem, 3.5vw, 2.5rem)",
                letterSpacing: "-0.025em",
              }}
            >
              Tiga langkah, semua otomatis
            </h2>
          </div>

          <div className="mx-auto mt-14 grid max-w-5xl gap-6 sm:grid-cols-3">
            {steps.map((s, i) => (
              <div
                key={s.title}
                className="relative rounded-2xl p-6"
                style={{
                  backgroundColor: "rgba(255,255,255,0.06)",
                  border: "1px solid rgba(255,255,255,0.1)",
                }}
              >
                <div
                  className="grid h-11 w-11 place-items-center rounded-xl font-bold text-white"
                  style={{
                    backgroundImage: `linear-gradient(135deg, ${BLUE700}, ${BLUE500})`,
                    fontFamily: "var(--font-display)",
                    fontSize: "1.125rem",
                    boxShadow: `0 4px 14px rgba(43,135,200,0.35)`,
                  }}
                >
                  {i + 1}
                </div>
                <h3
                  className="mt-4 font-semibold text-white"
                  style={{
                    fontFamily: "var(--font-display)",
                    fontSize: "1.0625rem",
                  }}
                >
                  {s.title}
                </h3>
                <p className="mt-2 text-sm leading-relaxed text-white/60">
                  {s.desc}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── CTA ─────────────────────────────────────────────────────── */}
      <section className="mx-auto max-w-7xl px-4 py-20 sm:px-6 sm:py-24 lg:px-8">
        <div
          className="relative overflow-hidden rounded-3xl px-6 py-16 text-center text-white sm:px-12 sm:py-20"
          style={{
            backgroundImage: `linear-gradient(135deg, ${NAVY} 0%, ${BLUE900} 55%, ${BLUE600} 100%)`,
            border: "1px solid rgba(255,255,255,0.1)",
            boxShadow: `0 20px 80px rgba(10,36,114,0.5)`,
          }}
        >
          <div
            aria-hidden
            className="pointer-events-none absolute right-0 top-0 h-72 w-72 -translate-y-1/3 translate-x-1/3 rounded-full blur-3xl"
            style={{
              background: `radial-gradient(circle, rgba(43,135,200,0.5), transparent 70%)`,
            }}
          />
          <div className="relative">
            <h2
              className="font-bold tracking-tight text-white"
              style={{
                fontFamily: "var(--font-display)",
                fontSize: "clamp(1.875rem, 4vw, 3rem)",
                letterSpacing: "-0.025em",
              }}
            >
              Siap kelola uang lebih baik?
            </h2>
            <p className="mx-auto mt-4 max-w-md text-base text-white/70">
              Gratis, tidak ada kartu kredit. Mulai sekarang dalam 30 detik.
            </p>
            <div className="mt-8 flex justify-center">
              <Link
                href="/register"
                className="inline-flex h-12 items-center gap-2 rounded-xl bg-white px-7 text-base font-bold text-slate-900 transition-all hover:bg-white/95 active:translate-y-px"
                style={{ boxShadow: "0 8px 32px rgba(0,0,0,0.3)" }}
              >
                Buat Akun Sekarang <ArrowRight className="h-4 w-4" />
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* ── Footer ──────────────────────────────────────────────────── */}
      <footer
        style={{
          backgroundColor: NAVY,
          borderTop: "1px solid rgba(255,255,255,0.08)",
        }}
      >
        <div className="mx-auto flex max-w-7xl flex-col gap-3 px-4 py-8 text-sm sm:flex-row sm:items-center sm:justify-between sm:px-6 lg:px-8">
          <div className="flex items-center gap-2 text-white/60">
            <div
              className="grid h-7 w-7 place-items-center rounded-lg"
              style={{ backgroundImage: `linear-gradient(135deg, ${BLUE900}, ${BLUE600})` }}
            >
              <Wallet className="h-3.5 w-3.5 text-white" />
            </div>
            <p>© {new Date().getFullYear()} Confindant. All rights reserved.</p>
          </div>
          <p className="text-xs text-white/40">
            Backend Laravel · Frontend Next.js · Mobile Flutter
          </p>
        </div>
      </footer>
    </main>
  );
}

/* ─── Data ─────────────────────────────────────────────────────────── */
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
    gradient: `linear-gradient(135deg, #0a2472, #0e6ba8)`,
  },
  {
    icon: Camera,
    title: "Scan Struk OCR",
    desc: "Foto struk → otomatis dibaca AI dan jadi transaksi tervalidasi tanpa input manual.",
    gradient: `linear-gradient(135deg, #0e6ba8, #2b87c8)`,
  },
  {
    icon: BarChart3,
    title: "Analytics Pintar",
    desc: "Insight pengeluaran berdasarkan kategori, tag, dan periode dengan chart interaktif.",
    gradient: `linear-gradient(135deg, #114b9c, #0e6ba8)`,
  },
  {
    icon: PiggyBank,
    title: "Goals & Budget",
    desc: "Target tabungan dengan auto-topup dan budget per kategori dengan alert threshold.",
    gradient: `linear-gradient(135deg, #0a2472, #114b9c)`,
  },
  {
    icon: Sparkles,
    title: "AI Finance Chat",
    desc: "Tanya keuangan kamu dalam bahasa natural, jawaban langsung dari data transaksimu.",
    gradient: `linear-gradient(135deg, #0e6ba8, #2b87c8)`,
  },
  {
    icon: ShieldCheck,
    title: "Aman & Privat",
    desc: "Token-based auth, terenkripsi end-to-end, data tidak dijual ke pihak ketiga.",
    gradient: `linear-gradient(135deg, #000314, #0a2472)`,
  },
];

const steps = [
  {
    title: "Hubungkan & atur dompet",
    desc: "Tambah wallet — cash, bank, e-wallet — dan set saldo awal dalam beberapa detik.",
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

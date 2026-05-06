"use client";

import * as React from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  ArrowRight,
  BarChart3,
  Camera,
  PiggyBank,
  ShieldCheck,
  Sparkles,
  Wallet,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { useAuthStore } from "@/store/auth";

export default function LandingPage() {
  const router = useRouter();
  const { token, hydrated } = useAuthStore();

  React.useEffect(() => {
    if (hydrated && token) router.replace("/home");
  }, [hydrated, token, router]);

  const features = [
    {
      icon: Wallet,
      title: "Multi-wallet",
      desc: "Kelola banyak dompet, transfer antar wallet, dan pantau saldo real-time.",
    },
    {
      icon: Camera,
      title: "Scan Struk OCR",
      desc: "Foto struk → otomatis dibaca AI dan jadi transaksi tervalidasi.",
    },
    {
      icon: BarChart3,
      title: "Analytics Pintar",
      desc: "Insight pengeluaran berdasarkan kategori, tag, dan periode.",
    },
    {
      icon: PiggyBank,
      title: "Goals & Budget",
      desc: "Target tabungan dengan auto-topup dan budget per kategori.",
    },
    {
      icon: Sparkles,
      title: "AI Finance Chat",
      desc: "Tanya keuangan kamu dalam bahasa natural, jawaban langsung dari data.",
    },
    {
      icon: ShieldCheck,
      title: "Aman & Privat",
      desc: "Token-based auth, terenkripsi, dan tidak ada data yang dijual.",
    },
  ];

  return (
    <main className="min-h-screen bg-background">
      <header className="sticky top-0 z-30 border-b border-border/50 bg-background/80 backdrop-blur-md">
        <div className="container mx-auto flex h-16 items-center justify-between px-4 sm:px-6 lg:px-8">
          <Link href="/" className="flex items-center gap-2">
            <div className="grid h-9 w-9 place-items-center rounded-xl gradient-hero">
              <Wallet className="h-5 w-5 text-white" />
            </div>
            <span className="font-display text-xl font-bold tracking-tight">
              Confindant
            </span>
          </Link>
          <div className="flex items-center gap-2">
            <Button variant="ghost" asChild className="hidden sm:inline-flex">
              <Link href="/login">Masuk</Link>
            </Button>
            <Button asChild variant="gradient">
              <Link href="/register">
                Mulai Gratis <ArrowRight className="h-4 w-4" />
              </Link>
            </Button>
          </div>
        </div>
      </header>

      {/* Hero */}
      <section className="relative overflow-hidden gradient-hero">
        <div
          className="pointer-events-none absolute inset-0 opacity-40"
          style={{
            backgroundImage:
              "radial-gradient(closest-side, rgba(255,255,255,0.25), transparent 70%)",
            backgroundSize: "60% 60%",
            backgroundPosition: "right top",
            backgroundRepeat: "no-repeat",
          }}
        />
        <div className="container mx-auto px-4 py-20 sm:px-6 sm:py-28 lg:px-8 lg:py-32">
          <div className="grid items-center gap-12 lg:grid-cols-2">
            <div className="text-white">
              <Badge
                variant="info"
                className="mb-5 border-white/30 bg-white/15 text-white backdrop-blur"
              >
                <Sparkles className="mr-1 h-3 w-3" /> Powered by AI
              </Badge>
              <h1 className="font-display text-4xl font-bold leading-tight tracking-tight sm:text-5xl lg:text-6xl">
                Kelola Keuangan, <br className="hidden sm:block" />
                Lebih <span className="text-blue-500">Cerdas</span>.
              </h1>
              <p className="mt-5 max-w-xl text-base text-white/80 sm:text-lg">
                Confindant bantu kamu lacak setiap pengeluaran, scan struk
                otomatis, kelola budget per kategori, dan dapatkan insight
                personal — semua di satu tempat.
              </p>
              <div className="mt-8 flex flex-wrap gap-3">
                <Button asChild size="lg" className="bg-white text-blue-900 hover:bg-white/90">
                  <Link href="/register">
                    Buat Akun Gratis <ArrowRight className="h-4 w-4" />
                  </Link>
                </Button>
                <Button
                  asChild
                  size="lg"
                  variant="ghost"
                  className="border border-white/30 bg-white/10 text-white hover:bg-white/20 hover:text-white"
                >
                  <Link href="/login">Sudah Punya Akun</Link>
                </Button>
              </div>
              <div className="mt-10 flex flex-wrap items-center gap-6 text-sm text-white/70">
                <div className="flex items-center gap-2">
                  <ShieldCheck className="h-4 w-4 text-blue-500" />
                  Token-based auth
                </div>
                <div className="flex items-center gap-2">
                  <Sparkles className="h-4 w-4 text-blue-500" />
                  Gemini AI categorization
                </div>
                <div className="flex items-center gap-2">
                  <Camera className="h-4 w-4 text-blue-500" />
                  OCR receipt scanner
                </div>
              </div>
            </div>

            {/* Hero card preview */}
            <div className="relative">
              <div className="absolute -inset-4 -z-10 rounded-3xl bg-white/5 blur-3xl" />
              <Card className="overflow-hidden border-white/10 bg-white/95 shadow-2xl backdrop-blur">
                <CardContent className="p-0">
                  <div className="gradient-hero p-6 text-white">
                    <p className="text-xs uppercase tracking-wider text-white/60">
                      Total Saldo
                    </p>
                    <p className="font-display text-3xl font-bold sm:text-4xl">
                      Rp 24.580.000
                    </p>
                    <div className="mt-4 grid grid-cols-2 gap-3 text-xs">
                      <div className="rounded-lg bg-white/10 p-3">
                        <p className="text-white/60">Pemasukan</p>
                        <p className="text-base font-semibold text-success">
                          + Rp 8.2M
                        </p>
                      </div>
                      <div className="rounded-lg bg-white/10 p-3">
                        <p className="text-white/60">Pengeluaran</p>
                        <p className="text-base font-semibold text-warning">
                          − Rp 3.6M
                        </p>
                      </div>
                    </div>
                  </div>
                  <div className="space-y-2 p-4">
                    {[
                      { label: "Starbucks Coffee", cat: "Food", amt: -45000 },
                      { label: "Gaji Bulanan", cat: "Income", amt: 8200000 },
                      { label: "Indomaret", cat: "Groceries", amt: -127500 },
                    ].map((tx) => (
                      <div
                        key={tx.label}
                        className="flex items-center justify-between rounded-lg p-2 hover:bg-muted"
                      >
                        <div>
                          <p className="text-sm font-medium">{tx.label}</p>
                          <p className="text-xs text-muted-foreground">
                            {tx.cat}
                          </p>
                        </div>
                        <p
                          className={`text-sm font-semibold ${
                            tx.amt > 0 ? "text-success" : "text-foreground"
                          }`}
                        >
                          {tx.amt > 0 ? "+" : ""}
                          {new Intl.NumberFormat("id-ID").format(tx.amt)}
                        </p>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            </div>
          </div>
        </div>
      </section>

      {/* Features */}
      <section className="container mx-auto px-4 py-16 sm:px-6 sm:py-24 lg:px-8">
        <div className="mx-auto max-w-2xl text-center">
          <Badge variant="info" className="mb-3">
            Semua yang kamu butuhkan
          </Badge>
          <h2 className="font-display text-3xl font-bold tracking-tight sm:text-4xl">
            Fitur lengkap untuk personal finance
          </h2>
          <p className="mt-3 text-muted-foreground">
            Web companion untuk Confindant mobile — semua fitur, di layar yang
            lebih luas.
          </p>
        </div>
        <div className="mt-12 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {features.map((f) => (
            <Card key={f.title} className="transition-all hover:-translate-y-1 hover:shadow-md">
              <CardContent className="p-6">
                <div className="grid h-11 w-11 place-items-center rounded-xl bg-info-bg text-blue-900">
                  <f.icon className="h-5 w-5" />
                </div>
                <h3 className="mt-4 font-semibold">{f.title}</h3>
                <p className="mt-1 text-sm text-muted-foreground">{f.desc}</p>
              </CardContent>
            </Card>
          ))}
        </div>
      </section>

      {/* CTA */}
      <section className="container mx-auto px-4 pb-20 sm:px-6 lg:px-8">
        <div className="overflow-hidden rounded-3xl gradient-hero p-8 text-center text-white sm:p-12">
          <h2 className="font-display text-2xl font-bold sm:text-3xl">
            Siap kelola uang lebih baik?
          </h2>
          <p className="mt-2 text-white/80">
            Gratis, tidak ada kartu kredit. Mulai sekarang dalam 30 detik.
          </p>
          <div className="mt-6 flex justify-center">
            <Button asChild size="lg" className="bg-white text-blue-900 hover:bg-white/90">
              <Link href="/register">
                Buat Akun Sekarang <ArrowRight className="h-4 w-4" />
              </Link>
            </Button>
          </div>
        </div>
      </section>

      <footer className="border-t border-border bg-card">
        <div className="container mx-auto flex flex-col gap-3 px-4 py-6 text-sm text-muted-foreground sm:flex-row sm:items-center sm:justify-between sm:px-6 lg:px-8">
          <p>© {new Date().getFullYear()} Confindant. All rights reserved.</p>
          <p className="text-xs">
            Made with care · Web port by Claude · Backend Laravel · Frontend
            Next.js
          </p>
        </div>
      </footer>
    </main>
  );
}

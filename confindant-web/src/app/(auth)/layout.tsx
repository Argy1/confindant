"use client";

import Link from "next/link";
import { Wallet } from "lucide-react";
import { GuestGuard } from "@/components/auth-guard";

export default function AuthLayout({ children }: { children: React.ReactNode }) {
  return (
    <GuestGuard>
      <div className="grid min-h-screen grid-cols-1 lg:grid-cols-2">
        {/* Brand pane */}
        <div className="relative hidden overflow-hidden gradient-hero lg:flex lg:flex-col lg:p-10">
          <div
            className="absolute inset-0 opacity-25"
            style={{
              backgroundImage:
                "radial-gradient(circle at 30% 30%, rgba(255,255,255,0.4), transparent 50%), radial-gradient(circle at 70% 80%, rgba(255,255,255,0.25), transparent 50%)",
            }}
          />
          <Link
            href="/"
            className="relative z-10 flex items-center gap-2 text-white"
          >
            <div className="grid h-9 w-9 place-items-center rounded-xl bg-white/15 backdrop-blur">
              <Wallet className="h-5 w-5" />
            </div>
            <span className="font-display text-xl font-bold">Confindant</span>
          </Link>

          <div className="relative z-10 mt-auto max-w-md text-white">
            <h2 className="font-display text-3xl font-bold leading-tight tracking-tight xl:text-4xl">
              Smart personal finance, dirancang untuk kamu.
            </h2>
            <p className="mt-3 text-white/80">
              Lacak transaksi, scan struk dengan AI, kelola budget dan goal —
              semua dalam satu app yang seamless antara mobile dan web.
            </p>
            <div className="mt-8 grid grid-cols-3 gap-3 text-center text-xs">
              <div className="rounded-xl bg-white/10 p-3 backdrop-blur">
                <p className="font-display text-2xl font-bold">13+</p>
                <p className="text-white/70">Modul fitur</p>
              </div>
              <div className="rounded-xl bg-white/10 p-3 backdrop-blur">
                <p className="font-display text-2xl font-bold">AI</p>
                <p className="text-white/70">Categorization</p>
              </div>
              <div className="rounded-xl bg-white/10 p-3 backdrop-blur">
                <p className="font-display text-2xl font-bold">OCR</p>
                <p className="text-white/70">Scan struk</p>
              </div>
            </div>
          </div>
        </div>

        {/* Form pane */}
        <div className="flex min-h-screen items-center justify-center bg-background px-4 py-10 sm:px-6">
          <div className="w-full max-w-md">
            <Link
              href="/"
              className="mb-6 flex items-center gap-2 lg:hidden"
            >
              <div className="grid h-9 w-9 place-items-center rounded-xl gradient-hero">
                <Wallet className="h-5 w-5 text-white" />
              </div>
              <span className="font-display text-xl font-bold">Confindant</span>
            </Link>
            {children}
          </div>
        </div>
      </div>
    </GuestGuard>
  );
}

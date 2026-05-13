import type { Metadata, Viewport } from "next";
import "@fontsource/inter/400.css";
import "@fontsource/inter/500.css";
import "@fontsource/inter/600.css";
import "@fontsource/inter/700.css";
import "./globals.css";
import { Providers } from "@/components/providers";

export const metadata: Metadata = {
  title: {
    default: "Confindant — Smart Personal Finance",
    template: "%s — Confindant",
  },
  description:
    "Lacak keuangan, kelola budget, scan struk dengan OCR, dan dapatkan insight AI. Companion web untuk Confindant mobile.",
  applicationName: "Confindant",
  authors: [{ name: "Confindant" }],
  keywords: [
    "personal finance",
    "budget",
    "expense tracker",
    "Confindant",
    "OCR receipt",
  ],
  icons: {
    icon: "/logo.png",
    apple: "/logo.png",
  },
  openGraph: {
    title: "Confindant",
    description:
      "Smart personal finance — wallets, budgets, AI insights, receipt OCR.",
    type: "website",
    images: [{ url: "/logo.png" }],
  },
};

export const viewport: Viewport = {
  themeColor: "#0a2472",
  width: "device-width",
  initialScale: 1,
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="id" className="h-full antialiased" suppressHydrationWarning>
      <body className="min-h-full bg-background text-foreground">
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}

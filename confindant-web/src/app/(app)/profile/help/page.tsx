"use client";

import * as React from "react";
import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, ChevronDown } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { profileApi } from "@/lib/api/profile";
import { cn } from "@/lib/utils";

export default function HelpCenterPage() {
  const [openIdx, setOpenIdx] = React.useState<number | null>(null);
  const { data, isLoading } = useQuery({
    queryKey: ["profile"],
    queryFn: profileApi.get,
  });

  const faqs = data?.profile.faq_items ?? [];

  return (
    <div className="space-y-6">
      <Link
        href="/profile"
        className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground"
      >
        <ArrowLeft className="h-4 w-4" /> Kembali ke Profil
      </Link>
      <div>
        <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
          Help Center
        </h1>
        <p className="text-sm text-muted-foreground">
          Pertanyaan yang sering diajukan dan dukungan.
        </p>
      </div>

      {isLoading ? (
        <div className="space-y-2">
          {Array.from({ length: 4 }).map((_, i) => (
            <Skeleton key={i} className="h-14 rounded-lg" />
          ))}
        </div>
      ) : faqs.length === 0 ? (
        <Card>
          <CardContent className="py-10 text-center text-sm text-muted-foreground">
            Belum ada FAQ tersedia.
          </CardContent>
        </Card>
      ) : (
        <Card>
          <CardContent className="divide-y divide-border p-0">
            {faqs.map((f, i) => {
              const open = openIdx === i;
              return (
                <div key={i}>
                  <button
                    onClick={() => setOpenIdx(open ? null : i)}
                    className="flex w-full items-center justify-between gap-3 p-4 text-left"
                  >
                    <p className="font-medium">{f.question}</p>
                    <ChevronDown
                      className={cn(
                        "h-4 w-4 shrink-0 text-muted-foreground transition-transform",
                        open && "rotate-180",
                      )}
                    />
                  </button>
                  {open && (
                    <div className="px-4 pb-4 text-sm text-muted-foreground">
                      {f.answer}
                    </div>
                  )}
                </div>
              );
            })}
          </CardContent>
        </Card>
      )}
    </div>
  );
}

"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { ArrowLeft } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { legalApi } from "@/lib/api/legal";

export default function PrivacyPage() {
  const { data, isLoading } = useQuery({
    queryKey: ["legal", "privacy"],
    queryFn: legalApi.privacy,
  });

  const html = data?.html || data?.body || data?.content || data?.markdown || "";

  return (
    <div className="space-y-6">
      <Link
        href="/profile"
        className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground"
      >
        <ArrowLeft className="h-4 w-4" /> Kembali ke Profil
      </Link>
      <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
        {data?.title || "Privacy Policy"}
      </h1>
      <Card>
        <CardContent className="p-5">
          {isLoading ? (
            <div className="space-y-2">
              {Array.from({ length: 8 }).map((_, i) => (
                <Skeleton key={i} className="h-4 w-full" />
              ))}
            </div>
          ) : (
            <article className="prose prose-sm max-w-none whitespace-pre-line">
              {html || "Konten belum tersedia."}
            </article>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

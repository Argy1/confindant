"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { ArrowLeft } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { aiApi } from "@/lib/api/ai";

export default function OcrHealthPage() {
  const { data, isLoading } = useQuery({
    queryKey: ["ai", "ocr-metrics"],
    queryFn: aiApi.ocrMetrics,
  });

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
          AI OCR Health
        </h1>
        <p className="text-sm text-muted-foreground">
          Statistik akurasi pembacaan struk dan saran perbaikan.
        </p>
      </div>

      <Card>
        <CardContent className="p-5">
          {isLoading ? (
            <Skeleton className="h-32" />
          ) : (
            <pre className="overflow-auto whitespace-pre-wrap rounded-lg bg-muted p-3 text-xs">
              {JSON.stringify(data, null, 2)}
            </pre>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

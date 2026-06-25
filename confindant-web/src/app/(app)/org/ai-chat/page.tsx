"use client";

import * as React from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Loader2, Send, Sparkles, Trash2 } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { aiApi } from "@/lib/api/ai";
import { getApiErrorMessage } from "@/lib/api/client";
import { relativeTime } from "@/lib/utils";
import { useActiveOrg } from "@/lib/hooks/use-active-org";

const SUGGESTIONS = [
  "Berapa total pendapatan bulan ini?",
  "Beban apa yang paling besar periode ini?",
  "Apakah organisasi surplus atau defisit?",
  "Tunjukkan ringkasan keuangan 30 hari terakhir.",
];

type Msg = { role: "user" | "assistant"; text: string; ts: number };

export default function OrgAiChatPage() {
  const { orgId } = useActiveOrg();
  const qc = useQueryClient();
  const [input, setInput] = React.useState("");
  const [messages, setMessages] = React.useState<Msg[]>([]);
  const scrollRef = React.useRef<HTMLDivElement>(null);

  const historyKey = ["org-ai-finance-history", orgId];

  const { data: history, isLoading } = useQuery({
    queryKey: historyKey,
    queryFn: () => aiApi.orgFinanceQueryHistory(orgId),
    enabled: !!orgId,
  });

  const ask = useMutation({
    mutationFn: (q: string) => aiApi.orgFinanceQuery(q, orgId),
    onSuccess: (res, q) => {
      setMessages((prev) => [
        ...prev,
        { role: "user", text: q, ts: Date.now() },
        {
          role: "assistant",
          text: (res as { answer?: string }).answer ?? "Saya tidak menemukan jawaban.",
          ts: Date.now(),
        },
      ]);
      qc.invalidateQueries({ queryKey: historyKey });
      setTimeout(() => {
        scrollRef.current?.scrollTo({ top: 999999, behavior: "smooth" });
      }, 50);
    },
    onError: (err) => toast.error(getApiErrorMessage(err)),
  });

  const onSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const q = input.trim();
    if (!q || ask.isPending) return;
    ask.mutate(q);
    setInput("");
  };

  const clearHistory = useMutation({
    mutationFn: () => aiApi.clearOrgFinanceQueryHistory(orgId),
    onSuccess: () => {
      toast.success("Riwayat dibersihkan");
      qc.invalidateQueries({ queryKey: historyKey });
    },
  });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
          AI Konsultan Keuangan
        </h1>
        <p className="text-sm text-muted-foreground">
          Tanya tentang keuangan organisasi — jawaban berdasarkan data jurnal nyata.
        </p>
      </div>

      <div className="grid gap-4 lg:grid-cols-3">
        <Card className="lg:col-span-2">
          <CardContent className="flex h-[70vh] flex-col p-0 sm:h-[600px]">
            <div
              ref={scrollRef}
              className="flex-1 space-y-3 overflow-y-auto p-4 sm:p-5"
            >
              {messages.length === 0 ? (
                <div className="grid h-full place-items-center px-4 text-center">
                  <div>
                    <div className="mx-auto grid h-14 w-14 place-items-center rounded-full bg-info-bg text-blue-900">
                      <Sparkles className="h-6 w-6" />
                    </div>
                    <p className="mt-3 font-semibold">
                      Tanya tentang keuangan organisasi
                    </p>
                    <p className="mt-1 text-sm text-muted-foreground">
                      Pilih saran di bawah atau ketik pertanyaan.
                    </p>
                    <div className="mt-4 grid gap-2 sm:grid-cols-2">
                      {SUGGESTIONS.map((s) => (
                        <button
                          key={s}
                          onClick={() => ask.mutate(s)}
                          className="rounded-lg border border-border bg-card px-3 py-2 text-left text-xs hover:bg-accent"
                        >
                          {s}
                        </button>
                      ))}
                    </div>
                  </div>
                </div>
              ) : (
                messages.map((m, i) => (
                  <div
                    key={i}
                    className={`flex ${m.role === "user" ? "justify-end" : "justify-start"}`}
                  >
                    <div
                      className={`max-w-[85%] rounded-2xl px-4 py-2.5 text-sm ${
                        m.role === "user"
                          ? "bg-primary text-primary-foreground"
                          : "bg-muted text-foreground"
                      }`}
                    >
                      {m.text}
                    </div>
                  </div>
                ))
              )}
              {ask.isPending && (
                <div className="flex justify-start">
                  <div className="flex items-center gap-2 rounded-2xl bg-muted px-4 py-2.5 text-sm">
                    <Loader2 className="h-3 w-3 animate-spin" /> Mengetik…
                  </div>
                </div>
              )}
            </div>

            <form
              onSubmit={onSubmit}
              className="flex items-center gap-2 border-t border-border p-3"
            >
              <Input
                value={input}
                onChange={(e) => setInput(e.target.value)}
                placeholder="Tanya tentang keuangan organisasi…"
                disabled={ask.isPending}
              />
              <Button type="submit" loading={ask.isPending} disabled={!input.trim()}>
                <Send className="h-4 w-4" />
              </Button>
            </form>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-5">
            <div className="flex items-center justify-between">
              <h2 className="font-semibold">Riwayat</h2>
              {(history ?? []).length > 0 && (
                <button
                  onClick={() => {
                    if (confirm("Hapus semua riwayat?")) clearHistory.mutate();
                  }}
                  className="inline-flex items-center gap-1 text-xs text-muted-foreground hover:text-destructive"
                >
                  <Trash2 className="h-3 w-3" /> Clear
                </button>
              )}
            </div>
            <div className="mt-3 max-h-[60vh] space-y-2 overflow-y-auto">
              {isLoading ? (
                Array.from({ length: 3 }).map((_, i) => (
                  <Skeleton key={i} className="h-12 w-full rounded-md" />
                ))
              ) : (history ?? []).length === 0 ? (
                <p className="text-xs text-muted-foreground">
                  Belum ada riwayat tanya jawab.
                </p>
              ) : (
                (history ?? []).map((h) => (
                  <button
                    key={h.id}
                    onClick={() => ask.mutate(h.query)}
                    className="block w-full rounded-md p-2 text-left text-xs hover:bg-accent"
                  >
                    <p className="line-clamp-2 font-medium">{h.query}</p>
                    <p className="text-muted-foreground">
                      {h.created_at ? relativeTime(h.created_at) : ""}
                    </p>
                  </button>
                ))
              )}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

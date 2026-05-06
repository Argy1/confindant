"use client";

import * as React from "react";
import { useQuery } from "@tanstack/react-query";
import { ArrowLeftRight, Plus, Wallet as WalletIcon } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { walletsApi } from "@/lib/api/wallets";
import { formatCurrency } from "@/lib/utils";
import { WalletFormDialog } from "@/components/wallets/wallet-form-dialog";
import { TransferDialog } from "@/components/wallets/transfer-dialog";
import type { Wallet } from "@/lib/types";

export default function WalletsPage() {
  const { data: wallets, isLoading } = useQuery({
    queryKey: ["wallets"],
    queryFn: walletsApi.list,
  });

  const [open, setOpen] = React.useState(false);
  const [transferOpen, setTransferOpen] = React.useState(false);
  const [editing, setEditing] = React.useState<Wallet | null>(null);

  const total = (wallets ?? []).reduce(
    (acc, w) => acc + Number(w.balance ?? 0),
    0,
  );

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
            Wallets
          </h1>
          <p className="text-sm text-muted-foreground">
            Kelola dompet kamu dan lakukan transfer antar wallet.
          </p>
        </div>
        <div className="flex gap-2">
          <Button
            variant="outline"
            onClick={() => setTransferOpen(true)}
            disabled={(wallets ?? []).length < 2}
          >
            <ArrowLeftRight className="h-4 w-4" /> Transfer
          </Button>
          <Button
            variant="gradient"
            onClick={() => {
              setEditing(null);
              setOpen(true);
            }}
          >
            <Plus className="h-4 w-4" /> Wallet Baru
          </Button>
        </div>
      </div>

      {/* Total */}
      <Card className="overflow-hidden border-0">
        <div className="gradient-hero p-6 text-white sm:p-8">
          <p className="text-xs uppercase tracking-wider text-white/70">
            Total saldo semua wallet
          </p>
          <p className="mt-1 font-display text-3xl font-bold sm:text-4xl">
            {formatCurrency(total)}
          </p>
          <p className="mt-1 text-xs text-white/60">
            {(wallets ?? []).length} wallet aktif
          </p>
        </div>
      </Card>

      {/* Grid */}
      {isLoading ? (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {Array.from({ length: 3 }).map((_, i) => (
            <Skeleton key={i} className="h-32 rounded-xl" />
          ))}
        </div>
      ) : (wallets ?? []).length === 0 ? (
        <Card>
          <CardContent className="grid place-items-center gap-3 py-16 text-center">
            <div className="grid h-14 w-14 place-items-center rounded-full bg-info-bg text-blue-900">
              <WalletIcon className="h-6 w-6" />
            </div>
            <p className="font-semibold">Belum ada wallet</p>
            <p className="max-w-xs text-sm text-muted-foreground">
              Tambahkan wallet pertama kamu untuk mulai mencatat transaksi.
            </p>
            <Button
              variant="gradient"
              onClick={() => {
                setEditing(null);
                setOpen(true);
              }}
            >
              <Plus className="h-4 w-4" /> Buat Wallet
            </Button>
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {(wallets ?? []).map((w) => (
            <button
              key={w.id}
              onClick={() => {
                setEditing(w);
                setOpen(true);
              }}
              className="group text-left"
            >
              <Card className="overflow-hidden transition-all hover:-translate-y-0.5 hover:shadow-md">
                <CardContent className="p-5">
                  <div className="flex items-center gap-3">
                    <div
                      className="grid h-11 w-11 place-items-center rounded-xl text-white shadow-sm"
                      style={{
                        background: w.wallet_color ?? "var(--blue-900)",
                      }}
                    >
                      <WalletIcon className="h-5 w-5" />
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="truncate font-medium">{w.wallet_name}</p>
                      <p className="text-xs text-muted-foreground">Wallet</p>
                    </div>
                  </div>
                  <p className="mt-4 font-display text-2xl font-bold">
                    {formatCurrency(w.balance)}
                  </p>
                </CardContent>
              </Card>
            </button>
          ))}
        </div>
      )}

      <WalletFormDialog
        open={open}
        onOpenChange={setOpen}
        initial={editing}
      />
      <TransferDialog open={transferOpen} onOpenChange={setTransferOpen} />
    </div>
  );
}

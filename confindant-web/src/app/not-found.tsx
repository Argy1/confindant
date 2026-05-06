import Link from "next/link";
import { Button } from "@/components/ui/button";

export default function NotFound() {
  return (
    <div className="grid min-h-screen place-items-center bg-background px-4">
      <div className="text-center">
        <p className="font-display text-7xl font-bold text-blue-900">404</p>
        <p className="mt-2 font-display text-2xl font-semibold">
          Halaman tidak ditemukan
        </p>
        <p className="mt-1 text-sm text-muted-foreground">
          Halaman yang kamu cari mungkin sudah dipindah atau dihapus.
        </p>
        <div className="mt-6 flex justify-center">
          <Button asChild variant="gradient">
            <Link href="/home">Kembali ke Home</Link>
          </Button>
        </div>
      </div>
    </div>
  );
}

"use client";

import * as React from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";
import { zResolver } from "@/lib/zod-resolver";
import { z } from "zod";
import { useMutation } from "@tanstack/react-query";
import { toast } from "sonner";
import { Eye, EyeOff, Mail, Lock, User } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { authApi } from "@/lib/api/auth";
import { getApiErrorMessage } from "@/lib/api/client";
import { useAuthStore } from "@/store/auth";

const schema = z.object({
  username: z
    .string()
    .min(3, "Username minimal 3 karakter")
    .max(64, "Username terlalu panjang"),
  email: z.string().email("Email tidak valid"),
  password: z.string().min(6, "Password minimal 6 karakter"),
});
type FormVals = z.infer<typeof schema>;

export default function RegisterPage() {
  const router = useRouter();
  const setSession = useAuthStore((s) => s.setSession);
  const [showPw, setShowPw] = React.useState(false);

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormVals>({ resolver: zResolver(schema) });

  const reg = useMutation({
    mutationFn: (vals: FormVals) =>
      authApi.register(vals.username, vals.email, vals.password),
    onSuccess: (data) => {
      setSession(data.access_token, data.user);
      toast.success(`Selamat datang, ${data.user.username}!`);
      router.replace("/home");
    },
    onError: (err) => {
      toast.error(getApiErrorMessage(err, "Pendaftaran gagal."));
    },
  });

  return (
    <div>
      <h1 className="font-display text-3xl font-bold tracking-tight">
        Buat akun baru
      </h1>
      <p className="mt-1 text-sm text-muted-foreground">
        Mulai kelola keuangan kamu dalam 30 detik.
      </p>

      <form
        onSubmit={handleSubmit((vals) => reg.mutate(vals))}
        className="mt-6 space-y-4"
        noValidate
      >
        <div className="space-y-1.5">
          <Label htmlFor="username">Username</Label>
          <div className="relative">
            <User className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              id="username"
              type="text"
              autoComplete="username"
              placeholder="Nama panggilan kamu"
              className="pl-10"
              {...register("username")}
            />
          </div>
          {errors.username && (
            <p className="text-xs text-destructive">{errors.username.message}</p>
          )}
        </div>

        <div className="space-y-1.5">
          <Label htmlFor="email">Email</Label>
          <div className="relative">
            <Mail className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              id="email"
              type="email"
              autoComplete="email"
              placeholder="kamu@email.com"
              className="pl-10"
              {...register("email")}
            />
          </div>
          {errors.email && (
            <p className="text-xs text-destructive">{errors.email.message}</p>
          )}
        </div>

        <div className="space-y-1.5">
          <Label htmlFor="password">Password</Label>
          <div className="relative">
            <Lock className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              id="password"
              type={showPw ? "text" : "password"}
              autoComplete="new-password"
              placeholder="Minimal 6 karakter"
              className="pl-10 pr-10"
              {...register("password")}
            />
            <button
              type="button"
              onClick={() => setShowPw((v) => !v)}
              className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
              aria-label={showPw ? "Sembunyikan password" : "Tampilkan password"}
            >
              {showPw ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
            </button>
          </div>
          {errors.password && (
            <p className="text-xs text-destructive">{errors.password.message}</p>
          )}
        </div>

        <Button
          type="submit"
          variant="gradient"
          size="lg"
          className="w-full"
          loading={reg.isPending}
        >
          Buat Akun
        </Button>
      </form>

      <p className="mt-6 text-center text-sm text-muted-foreground">
        Sudah punya akun?{" "}
        <Link href="/login" className="font-medium text-primary hover:underline">
          Masuk di sini
        </Link>
      </p>
    </div>
  );
}

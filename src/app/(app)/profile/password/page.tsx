"use client";

import * as React from "react";
import Link from "next/link";
import { useForm } from "react-hook-form";
import { zResolver } from "@/lib/zod-resolver";
import { z } from "zod";
import { useMutation } from "@tanstack/react-query";
import { toast } from "sonner";
import { ArrowLeft, Eye, EyeOff } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { profileApi } from "@/lib/api/profile";
import { getApiErrorMessage } from "@/lib/api/client";

const schema = z
  .object({
    current_password: z.string().min(1, "Masukkan password saat ini"),
    new_password: z.string().min(8, "Minimal 8 karakter"),
    new_password_confirmation: z.string().min(1),
  })
  .refine((d) => d.new_password === d.new_password_confirmation, {
    message: "Konfirmasi password tidak cocok",
    path: ["new_password_confirmation"],
  });
type FormVals = z.infer<typeof schema>;

export default function ChangePasswordPage() {
  const [show, setShow] = React.useState(false);

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<FormVals>({ resolver: zResolver(schema) });

  const save = useMutation({
    mutationFn: (vals: FormVals) => profileApi.changePassword(vals),
    onSuccess: () => {
      toast.success("Password berhasil diubah");
      reset();
    },
    onError: (err) => toast.error(getApiErrorMessage(err)),
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
          Ganti Password
        </h1>
        <p className="text-sm text-muted-foreground">
          Pilih password yang kuat dan tidak kamu pakai di tempat lain.
        </p>
      </div>

      <Card>
        <CardContent className="p-5">
          <form
            onSubmit={handleSubmit((v) => save.mutate(v))}
            className="space-y-4"
          >
            <div className="space-y-1.5">
              <Label htmlFor="current_password">Password saat ini</Label>
              <Input
                id="current_password"
                type={show ? "text" : "password"}
                {...register("current_password")}
              />
              {errors.current_password && (
                <p className="text-xs text-destructive">
                  {errors.current_password.message}
                </p>
              )}
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="new_password">Password baru</Label>
              <Input
                id="new_password"
                type={show ? "text" : "password"}
                {...register("new_password")}
              />
              {errors.new_password && (
                <p className="text-xs text-destructive">
                  {errors.new_password.message}
                </p>
              )}
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="new_password_confirmation">
                Konfirmasi password baru
              </Label>
              <Input
                id="new_password_confirmation"
                type={show ? "text" : "password"}
                {...register("new_password_confirmation")}
              />
              {errors.new_password_confirmation && (
                <p className="text-xs text-destructive">
                  {errors.new_password_confirmation.message}
                </p>
              )}
            </div>

            <button
              type="button"
              onClick={() => setShow((v) => !v)}
              className="inline-flex items-center gap-1 text-xs text-muted-foreground hover:text-foreground"
            >
              {show ? (
                <EyeOff className="h-3.5 w-3.5" />
              ) : (
                <Eye className="h-3.5 w-3.5" />
              )}
              {show ? "Sembunyikan" : "Tampilkan"} password
            </button>

            <div className="flex justify-end pt-2">
              <Button type="submit" loading={save.isPending}>
                Ubah Password
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}

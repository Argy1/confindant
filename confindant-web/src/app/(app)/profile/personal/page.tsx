"use client";

import * as React from "react";
import Link from "next/link";
import { useForm } from "react-hook-form";
import { zResolver } from "@/lib/zod-resolver";
import { z } from "zod";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { ArrowLeft } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import { profileApi } from "@/lib/api/profile";
import { getApiErrorMessage } from "@/lib/api/client";

const schema = z.object({
  full_name: z.string().min(1).max(120),
  username: z.string().min(3).max(64),
  email: z.string().email(),
  phone: z.string().optional().nullable(),
  currency: z.string().optional().nullable(),
});
type FormVals = z.infer<typeof schema>;

export default function PersonalInfoPage() {
  const qc = useQueryClient();
  const { data, isLoading } = useQuery({
    queryKey: ["profile"],
    queryFn: profileApi.get,
  });

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<FormVals>({ resolver: zResolver(schema) });

  React.useEffect(() => {
    if (data) {
      reset({
        full_name: data.profile.full_name,
        username: data.profile.username,
        email: data.profile.email,
        phone: data.profile.phone ?? "",
        currency: data.profile.currency ?? "IDR (Rp)",
      });
    }
  }, [data, reset]);

  const save = useMutation({
    mutationFn: (vals: FormVals) => profileApi.update(vals),
    onSuccess: () => {
      toast.success("Profil diperbarui");
      qc.invalidateQueries({ queryKey: ["profile"] });
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
          Personal Info
        </h1>
        <p className="text-sm text-muted-foreground">
          Update data pribadi dan preferensi mata uang.
        </p>
      </div>

      <Card>
        <CardContent className="p-5">
          {isLoading ? (
            <div className="space-y-3">
              {Array.from({ length: 4 }).map((_, i) => (
                <Skeleton key={i} className="h-11 w-full" />
              ))}
            </div>
          ) : (
            <form
              onSubmit={handleSubmit((v) => save.mutate(v))}
              className="space-y-4"
            >
              <div className="grid gap-4 sm:grid-cols-2">
                <div className="space-y-1.5">
                  <Label htmlFor="full_name">Nama Lengkap</Label>
                  <Input id="full_name" {...register("full_name")} />
                  {errors.full_name && (
                    <p className="text-xs text-destructive">
                      {errors.full_name.message}
                    </p>
                  )}
                </div>
                <div className="space-y-1.5">
                  <Label htmlFor="username">Username</Label>
                  <Input id="username" {...register("username")} />
                  {errors.username && (
                    <p className="text-xs text-destructive">
                      {errors.username.message}
                    </p>
                  )}
                </div>
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="email">Email</Label>
                <Input id="email" type="email" {...register("email")} />
                {errors.email && (
                  <p className="text-xs text-destructive">{errors.email.message}</p>
                )}
              </div>
              <div className="grid gap-4 sm:grid-cols-2">
                <div className="space-y-1.5">
                  <Label htmlFor="phone">No. Telepon</Label>
                  <Input
                    id="phone"
                    placeholder="+62 ..."
                    {...register("phone")}
                  />
                </div>
                <div className="space-y-1.5">
                  <Label htmlFor="currency">Mata Uang</Label>
                  <Input id="currency" {...register("currency")} />
                </div>
              </div>
              <div className="flex justify-end pt-2">
                <Button type="submit" loading={save.isPending}>
                  Simpan Perubahan
                </Button>
              </div>
            </form>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

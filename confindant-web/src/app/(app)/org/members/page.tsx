"use client";

import * as React from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { UserPlus, Trash2, Copy, Check, X } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { Badge } from "@/components/ui/badge";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { organizationApi } from "@/lib/api/accounting";
import { useActiveOrg } from "@/lib/hooks/use-active-org";
import { toast } from "sonner";
import { getApiErrorMessage } from "@/lib/api/client";
import type { OrgMember, OrgRole } from "@/lib/accounting-types";

const ROLE_LABEL: Record<OrgRole, string> = {
  admin: "Admin",
  bendahara: "Bendahara",
  auditor: "Auditor",
  viewer: "Viewer",
};

const ROLE_COLOR: Record<OrgRole, string> = {
  admin: "bg-purple-100 text-purple-700 border-purple-200",
  bendahara: "bg-blue-100 text-blue-700 border-blue-200",
  auditor: "bg-emerald-100 text-emerald-700 border-emerald-200",
  viewer: "bg-gray-100 text-gray-600 border-gray-200",
};

function RoleBadge({ role }: { role: OrgRole }) {
  return (
    <span
      className={`inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium ${ROLE_COLOR[role]}`}
    >
      {ROLE_LABEL[role]}
    </span>
  );
}

export default function MembersPage() {
  const { org, orgId } = useActiveOrg();
  const qc = useQueryClient();

  // Derive current user role from org context
  const currentRole = org?.role ?? "viewer";
  const isAdmin = currentRole === "admin";

  const [inviteOpen, setInviteOpen] = React.useState(false);
  const [inviteEmail, setInviteEmail] = React.useState("");
  const [inviteRole, setInviteRole] = React.useState<OrgRole>("viewer");
  const [inviteUrl, setInviteUrl] = React.useState<string | null>(null);
  const [copied, setCopied] = React.useState(false);

  const [removeTarget, setRemoveTarget] = React.useState<OrgMember | null>(null);

  const membersQuery = useQuery({
    queryKey: ["org-members", orgId],
    queryFn: () => organizationApi.memberList(orgId!),
    enabled: !!orgId,
  });

  const invitationsQuery = useQuery({
    queryKey: ["org-invitations", orgId],
    queryFn: () => organizationApi.invitationList(orgId!),
    enabled: !!orgId && isAdmin,
  });

  const updateRoleMut = useMutation({
    mutationFn: ({ userId, role }: { userId: number; role: OrgRole }) =>
      organizationApi.memberUpdateRole(orgId!, userId, role),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["org-members", orgId] });
      toast.success("Role anggota diperbarui");
    },
    onError: (err) => toast.error(getApiErrorMessage(err, "Gagal memperbarui role")),
  });

  const removeMut = useMutation({
    mutationFn: (userId: number) => organizationApi.memberRemove(orgId!, userId),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["org-members", orgId] });
      setRemoveTarget(null);
      toast.success("Anggota dihapus");
    },
    onError: (err) => toast.error(getApiErrorMessage(err, "Gagal menghapus anggota")),
  });

  const inviteMut = useMutation({
    mutationFn: () => organizationApi.inviteCreate(orgId!, inviteEmail, inviteRole),
    onSuccess: (data) => {
      qc.invalidateQueries({ queryKey: ["org-invitations", orgId] });
      setInviteUrl(data.invite_url);
      toast.success("Undangan berhasil dibuat");
    },
    onError: (err) => toast.error(getApiErrorMessage(err, "Gagal membuat undangan")),
  });

  const cancelInviteMut = useMutation({
    mutationFn: (token: string) => organizationApi.inviteCancel(orgId!, token),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["org-invitations", orgId] });
      toast.success("Undangan dibatalkan");
    },
    onError: (err) => toast.error(getApiErrorMessage(err, "Gagal membatalkan undangan")),
  });

  function handleInviteSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!inviteEmail) return;
    inviteMut.mutate();
  }

  async function copyInviteUrl() {
    if (!inviteUrl) return;
    await navigator.clipboard.writeText(inviteUrl);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }

  function openInviteDialog() {
    setInviteEmail("");
    setInviteRole("viewer");
    setInviteUrl(null);
    setInviteOpen(true);
  }

  const members = membersQuery.data ?? [];
  const invitations = invitationsQuery.data ?? [];

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
            Manajemen Anggota
          </h1>
          <p className="text-sm text-muted-foreground">{org?.name}</p>
        </div>
        {isAdmin && (
          <Button size="sm" onClick={openInviteDialog}>
            <UserPlus className="mr-2 h-4 w-4" />
            Undang Anggota
          </Button>
        )}
      </div>

      <Tabs defaultValue="members">
        <TabsList>
          <TabsTrigger value="members">
            Anggota ({members.length})
          </TabsTrigger>
          {isAdmin && (
            <TabsTrigger value="invitations">
              Undangan Tertunda ({invitations.length})
            </TabsTrigger>
          )}
        </TabsList>

        {/* ── Members tab ── */}
        <TabsContent value="members" className="mt-4">
          {membersQuery.isLoading ? (
            <div className="space-y-2">
              {Array.from({ length: 3 }).map((_, i) => (
                <Skeleton key={i} className="h-14 rounded-xl" />
              ))}
            </div>
          ) : (
            <Card>
              <CardContent className="p-0">
                <ul className="divide-y divide-border">
                  {members.map((member) => (
                    <li
                      key={member.id}
                      className="flex items-center justify-between gap-3 px-4 py-3"
                    >
                      <div className="flex items-center gap-3 min-w-0">
                        <div className="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-muted text-sm font-bold uppercase text-muted-foreground">
                          {member.name.charAt(0)}
                        </div>
                        <div className="min-w-0">
                          <p className="truncate text-sm font-medium">{member.name}</p>
                          <p className="truncate text-xs text-muted-foreground">
                            {member.email}
                          </p>
                        </div>
                      </div>

                      <div className="flex shrink-0 items-center gap-2">
                        {isAdmin ? (
                          <Select
                            value={member.role}
                            onValueChange={(v) =>
                              updateRoleMut.mutate({
                                userId: member.id,
                                role: v as OrgRole,
                              })
                            }
                          >
                            <SelectTrigger className="h-7 w-32 text-xs">
                              <SelectValue />
                            </SelectTrigger>
                            <SelectContent>
                              {(["admin", "bendahara", "auditor", "viewer"] as OrgRole[]).map(
                                (r) => (
                                  <SelectItem key={r} value={r}>
                                    {ROLE_LABEL[r]}
                                  </SelectItem>
                                ),
                              )}
                            </SelectContent>
                          </Select>
                        ) : (
                          <RoleBadge role={member.role} />
                        )}

                        {isAdmin && (
                          <Button
                            variant="ghost"
                            size="icon"
                            className="h-7 w-7 text-destructive hover:text-destructive"
                            onClick={() => setRemoveTarget(member)}
                          >
                            <Trash2 className="h-3.5 w-3.5" />
                          </Button>
                        )}
                      </div>
                    </li>
                  ))}
                </ul>
              </CardContent>
            </Card>
          )}
        </TabsContent>

        {/* ── Invitations tab ── */}
        {isAdmin && (
          <TabsContent value="invitations" className="mt-4">
            {invitationsQuery.isLoading ? (
              <Skeleton className="h-32 rounded-xl" />
            ) : invitations.length === 0 ? (
              <Card>
                <CardContent className="py-12 text-center text-sm text-muted-foreground">
                  Tidak ada undangan tertunda.
                </CardContent>
              </Card>
            ) : (
              <Card>
                <CardContent className="p-0">
                  <ul className="divide-y divide-border">
                    {invitations.map((inv) => (
                      <li
                        key={inv.token}
                        className="flex items-center justify-between gap-3 px-4 py-3"
                      >
                        <div className="min-w-0">
                          <p className="truncate text-sm font-medium">{inv.email}</p>
                          <p className="text-xs text-muted-foreground">
                            Diundang sebagai{" "}
                            <span className="font-medium">{ROLE_LABEL[inv.role]}</span>{" "}
                            · oleh {inv.invited_by.name}
                          </p>
                        </div>
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-7 w-7 shrink-0 text-destructive hover:text-destructive"
                          onClick={() => cancelInviteMut.mutate(inv.token)}
                          disabled={cancelInviteMut.isPending}
                        >
                          <X className="h-3.5 w-3.5" />
                        </Button>
                      </li>
                    ))}
                  </ul>
                </CardContent>
              </Card>
            )}
          </TabsContent>
        )}
      </Tabs>

      {/* ── Invite dialog ── */}
      <Dialog
        open={inviteOpen}
        onOpenChange={(open: boolean) => {
          if (!open) {
            setInviteOpen(false);
            setInviteUrl(null);
          }
        }}
      >
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>Undang Anggota</DialogTitle>
          </DialogHeader>

          {inviteUrl ? (
            <div className="space-y-4">
              <p className="text-sm text-muted-foreground">
                Undangan berhasil dibuat. Salin link berikut dan bagikan ke calon anggota.
              </p>
              <div className="flex items-center gap-2 rounded-lg border border-border bg-muted/40 px-3 py-2">
                <span className="flex-1 truncate font-mono text-xs">{inviteUrl}</span>
                <Button variant="ghost" size="icon" className="h-7 w-7 shrink-0" onClick={copyInviteUrl}>
                  {copied ? (
                    <Check className="h-3.5 w-3.5 text-emerald-600" />
                  ) : (
                    <Copy className="h-3.5 w-3.5" />
                  )}
                </Button>
              </div>
              <p className="text-xs text-muted-foreground">Link berlaku 48 jam.</p>
              <DialogFooter>
                <Button
                  onClick={() => {
                    setInviteOpen(false);
                    setInviteUrl(null);
                  }}
                >
                  Selesai
                </Button>
              </DialogFooter>
            </div>
          ) : (
            <form onSubmit={handleInviteSubmit} className="space-y-4">
              <div className="space-y-1.5">
                <Label htmlFor="inv-email">Email</Label>
                <Input
                  id="inv-email"
                  type="email"
                  value={inviteEmail}
                  onChange={(e) => setInviteEmail(e.target.value)}
                  placeholder="email@contoh.com"
                  required
                />
              </div>

              <div className="space-y-1.5">
                <Label>Role</Label>
                <Select
                  value={inviteRole}
                  onValueChange={(v) => setInviteRole(v as OrgRole)}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="admin">Admin — kelola org & anggota</SelectItem>
                    <SelectItem value="bendahara">Bendahara — input & posting jurnal</SelectItem>
                    <SelectItem value="auditor">Auditor — baca & review</SelectItem>
                    <SelectItem value="viewer">Viewer — hanya baca</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <DialogFooter>
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => setInviteOpen(false)}
                >
                  Batal
                </Button>
                <Button type="submit" disabled={inviteMut.isPending}>
                  Kirim Undangan
                </Button>
              </DialogFooter>
            </form>
          )}
        </DialogContent>
      </Dialog>

      {/* ── Remove confirmation dialog ── */}
      <Dialog
        open={!!removeTarget}
        onOpenChange={(open: boolean) => !open && setRemoveTarget(null)}
      >
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>Hapus anggota?</DialogTitle>
          </DialogHeader>
          <p className="text-sm text-muted-foreground">
            <strong>{removeTarget?.name}</strong> akan dikeluarkan dari organisasi. Mereka
            tidak bisa lagi mengakses data akuntansi.
          </p>
          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => setRemoveTarget(null)}>
              Batal
            </Button>
            <Button
              variant="destructive"
              onClick={() => removeTarget && removeMut.mutate(removeTarget.id)}
              disabled={removeMut.isPending}
            >
              Keluarkan
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

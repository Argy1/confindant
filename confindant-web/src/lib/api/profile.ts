import { api, unwrap } from "./client";
import type { ApiEnvelope, NotificationItem, ProfileData } from "@/lib/types";

export type ProfileUpdateInput = {
  full_name?: string;
  username?: string;
  email?: string;
  phone?: string | null;
  currency?: string | null;
  avatar_path?: string | null;
};

export type ChangePasswordInput = {
  current_password: string;
  new_password: string;
  new_password_confirmation: string;
};

export type NotificationSettingsInput = {
  push_enabled: boolean;
  email_enabled: boolean;
  transaction_alerts: boolean;
  budget_alerts: boolean;
  weekly_report: boolean;
};

export const profileApi = {
  async get() {
    const { data } = await api.get<ApiEnvelope<ProfileData>>("/profile");
    return unwrap(data);
  },
  async update(input: ProfileUpdateInput) {
    const { data } = await api.patch<ApiEnvelope<ProfileData["profile"]>>(
      "/profile",
      input,
    );
    return unwrap(data);
  },
  async uploadAvatar(file: File) {
    const form = new FormData();
    form.append("avatar", file);
    const { data } = await api.post<ApiEnvelope<ProfileData["profile"]>>(
      "/profile/avatar",
      form,
      { headers: { "Content-Type": "multipart/form-data" } },
    );
    return unwrap(data);
  },
  async changePassword(input: ChangePasswordInput) {
    const { data } = await api.patch<ApiEnvelope<null>>(
      "/profile/change-password",
      input,
    );
    return data;
  },
  async updateNotificationSettings(input: NotificationSettingsInput) {
    const { data } = await api.patch<ApiEnvelope<ProfileData["profile"]>>(
      "/profile/notification-settings",
      input,
    );
    return unwrap(data);
  },
};

export const notificationsApi = {
  async list(params: { page?: number; per_page?: number } = {}) {
    const { data } = await api.get<ApiEnvelope<NotificationItem[]>>(
      "/notifications",
      { params },
    );
    return unwrap(data);
  },
  async markRead(id: string) {
    const { data } = await api.post<ApiEnvelope<NotificationItem>>(
      `/notifications/${id}/mark-read`,
    );
    return unwrap(data);
  },
};

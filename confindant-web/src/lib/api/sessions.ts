import { api, unwrap } from "./client";
import type { ApiEnvelope } from "@/lib/types";

export type UserSession = {
  id: string;
  user_id: string;
  token_id: string;
  device_name: string;
  device_type: "mobile" | "tablet" | "desktop" | string;
  platform: string;
  ip_address: string;
  is_active: boolean;
  is_current: boolean;
  logged_in_at: string;
  last_active_at: string;
  logged_out_at?: string | null;
};

export const sessionsApi = {
  async list() {
    const { data } = await api.get<ApiEnvelope<UserSession[]>>("/sessions");
    return unwrap(data);
  },
  async revoke(id: string) {
    const { data } = await api.delete<ApiEnvelope<null>>(`/sessions/${id}`);
    return data;
  },
  async revokeAll() {
    const { data } = await api.delete<ApiEnvelope<null>>("/sessions/all");
    return data;
  },
};

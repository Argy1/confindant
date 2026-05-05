import { api, unwrap } from "./client";
import type { AnalyticsData, ApiEnvelope, DashboardData } from "@/lib/types";

export const dashboardApi = {
  async get() {
    const { data } = await api.get<ApiEnvelope<DashboardData>>("/dashboard");
    return unwrap(data);
  },
};

export type AnalyticsParams = {
  period?: "weekly" | "monthly";
  from_date?: string;
  to_date?: string;
  wallet_id?: string;
  category?: string;
};

export const analyticsApi = {
  async get(params: AnalyticsParams = {}) {
    const { data } = await api.get<ApiEnvelope<AnalyticsData>>("/analytics", {
      params,
    });
    return unwrap(data);
  },
};

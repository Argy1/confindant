import { api, unwrap } from "./client";
import type { AnalyticsData, AnalyticsRaw, ApiEnvelope, DashboardData } from "@/lib/types";

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

function normalizeAnalytics(raw: AnalyticsRaw): AnalyticsData {
  const totalExpense = raw.summary?.total_expense ?? 0;

  const by_category = (raw.category_breakdown ?? []).map((c) => ({
    category: c.label,
    amount: c.amount,
    percent: totalExpense > 0 ? (c.amount / totalExpense) * 100 : 0,
  }));

  const daily_breakdown = (raw.net_flow_trend ?? []).map((t) => ({
    date: t.label,
    income: t.income,
    expense: t.expense,
    net: t.amount,
  }));

  const budget_performance = (raw.budget_progress ?? []).map((b) => {
    const pct = b.limit > 0 ? b.used / b.limit : 0;
    const status: "on_track" | "warning" | "exceeded" =
      pct > 1 ? "exceeded" : pct > 0.8 ? "warning" : "on_track";
    return {
      category: b.category,
      budget: b.limit,
      spent: b.used,
      remaining: Math.max(0, b.limit - b.used),
      status,
    };
  });

  const deltaPercent = raw.comparison?.delta_percent ?? 0;
  const previousExpense = raw.comparison?.previous_value ?? 0;

  return {
    income: raw.summary?.total_income ?? 0,
    expense: totalExpense,
    net_cashflow: raw.summary?.net_saving ?? 0,
    expense_vs_previous:
      previousExpense > 0 || deltaPercent !== 0
        ? { amount: previousExpense, percent_change: deltaPercent }
        : undefined,
    by_category,
    daily_breakdown,
    budget_performance,
    insight_text: raw.insight_text,
    anomaly: raw.anomaly,
  };
}

export const analyticsApi = {
  async get(params: AnalyticsParams = {}) {
    const { data } = await api.get<ApiEnvelope<AnalyticsRaw>>("/analytics", {
      params,
    });
    return normalizeAnalytics(unwrap(data));
  },
};

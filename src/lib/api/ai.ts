import { api, unwrap } from "./client";
import type { ApiEnvelope } from "@/lib/types";

export type CategorizeInput = {
  type: "income" | "expense";
  merchant_name?: string | null;
  source?: string | null;
  notes?: string | null;
  total_amount?: number | null;
};

export type CategorizeResult = {
  category: string;
  confidence: number;
  suggested: boolean;
  provider: string;
};

export type FinanceQuery = {
  id: string;
  query: string;
  answer: string;
  label?: string | null;
  created_at?: string;
};

export const aiApi = {
  async categorize(input: CategorizeInput) {
    const { data } = await api.post<ApiEnvelope<CategorizeResult>>(
      "/ai/transactions/categorize",
      input,
    );
    return { result: unwrap(data), meta: data.meta };
  },
  async parseInput(userInput: string) {
    const { data } = await api.post<ApiEnvelope<Record<string, unknown>>>(
      "/ai/transactions/parse-input",
      { user_input: userInput },
    );
    return unwrap(data);
  },
  async cashflowForecast(params: { days?: number; wallet_id?: string } = {}) {
    const { data } = await api.get<ApiEnvelope<unknown>>(
      "/ai/cashflow-forecast",
      { params },
    );
    return unwrap(data);
  },
  async budgetRecommendations() {
    const { data } = await api.get<ApiEnvelope<unknown>>(
      "/ai/budget-recommendations",
    );
    return unwrap(data);
  },
  async ocrMetrics() {
    const { data } = await api.get<ApiEnvelope<unknown>>("/ai/ocr-metrics");
    return unwrap(data);
  },
  async financeQuery(query: string) {
    const { data } = await api.post<ApiEnvelope<{ answer: string; data?: unknown }>>(
      "/ai/finance-query",
      { query },
    );
    return unwrap(data);
  },
  async financeQueryHistory() {
    const { data } = await api.get<ApiEnvelope<FinanceQuery[]>>(
      "/ai/finance-query/history",
    );
    return unwrap(data);
  },
  async deleteFinanceQueryHistory() {
    const { data } = await api.delete<ApiEnvelope<null>>(
      "/ai/finance-query/history",
    );
    return data;
  },
  async deleteFinanceQuery(id: string) {
    const { data } = await api.delete<ApiEnvelope<null>>(
      `/ai/finance-query/history/${id}`,
    );
    return data;
  },
};

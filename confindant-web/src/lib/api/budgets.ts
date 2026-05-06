import { api, unwrap } from "./client";
import type { ApiEnvelope, Budget } from "@/lib/types";

export type BudgetInput = {
  category: string;
  limit_amount: number;
  period_month: string;
  alert_threshold?: number;
};

export const budgetsApi = {
  async list() {
    const { data } = await api.get<ApiEnvelope<Budget[]>>("/budgets");
    return unwrap(data);
  },
  async create(input: BudgetInput) {
    const { data } = await api.post<ApiEnvelope<Budget>>("/budgets", input);
    return unwrap(data);
  },
  async update(id: string, input: Partial<BudgetInput>) {
    const { data } = await api.patch<ApiEnvelope<Budget>>(
      `/budgets/${id}`,
      input,
    );
    return unwrap(data);
  },
  async remove(id: string) {
    const { data } = await api.delete<ApiEnvelope<null>>(`/budgets/${id}`);
    return data;
  },
};

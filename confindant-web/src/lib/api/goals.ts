import { api, unwrap } from "./client";
import type { ApiEnvelope, Goal } from "@/lib/types";

export type GoalInput = {
  name: string;
  target_amount: number;
  target_date_label: string;
  linked_wallet: string;
  auto_topup_enabled?: boolean;
  auto_topup_percent?: number;
};

export type GoalContributionInput = {
  amount: number;
  note?: string | null;
  date_label?: string | null;
};

export const goalsApi = {
  async list() {
    const { data } = await api.get<ApiEnvelope<Goal[]>>("/goals");
    return unwrap(data);
  },
  async create(input: GoalInput) {
    const { data } = await api.post<ApiEnvelope<Goal>>("/goals", input);
    return unwrap(data);
  },
  async update(id: string, input: Partial<GoalInput>) {
    const { data } = await api.patch<ApiEnvelope<Goal>>(`/goals/${id}`, input);
    return unwrap(data);
  },
  async remove(id: string) {
    const { data } = await api.delete<ApiEnvelope<null>>(`/goals/${id}`);
    return data;
  },
  async contribute(id: string, input: GoalContributionInput) {
    const { data } = await api.post<ApiEnvelope<Goal>>(
      `/goals/${id}/contributions`,
      input,
    );
    return unwrap(data);
  },
};

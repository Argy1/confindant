import { api, unwrap } from "./client";
import type { ApiEnvelope, RecurringTransaction, TxType } from "@/lib/types";

export type RecurringInput = {
  wallet_id: string;
  type: TxType;
  source?: string | null;
  category?: string | null;
  amount: number;
  merchant_name?: string | null;
  notes?: string | null;
  is_verified?: boolean;
  tags?: string[];
  frequency: "daily" | "weekly" | "monthly";
  interval?: number;
  start_date: string;
  next_run_at?: string | null;
  end_date?: string | null;
  active?: boolean;
};

export const recurringApi = {
  async list() {
    const { data } = await api.get<ApiEnvelope<RecurringTransaction[]>>(
      "/recurring-transactions",
    );
    return unwrap(data);
  },
  async create(input: RecurringInput) {
    const { data } = await api.post<ApiEnvelope<RecurringTransaction>>(
      "/recurring-transactions",
      input,
    );
    return unwrap(data);
  },
  async update(id: string, input: Partial<RecurringInput>) {
    const { data } = await api.patch<ApiEnvelope<RecurringTransaction>>(
      `/recurring-transactions/${id}`,
      input,
    );
    return unwrap(data);
  },
  async remove(id: string) {
    const { data } = await api.delete<ApiEnvelope<null>>(
      `/recurring-transactions/${id}`,
    );
    return data;
  },
};

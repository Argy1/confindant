import { api, unwrap } from "./client";
import type {
  ApiEnvelope,
  Paginated,
  Transaction,
  TxType,
  NeedWant,
} from "@/lib/types";

export type TransactionInput = {
  wallet_id: string;
  type: TxType;
  source?: string | null;
  category?: string | null;
  total_amount: number;
  tax_amount?: number | null;
  service_amount?: number | null;
  need_want?: NeedWant | null;
  date: string;
  merchant_name?: string | null;
  receipt_image_url?: string | null;
  notes?: string | null;
  is_verified?: boolean | null;
  items?: unknown[] | null;
  tags?: string[] | null;
  is_internal_transfer?: boolean | null;
  transfer_group_id?: string | null;
};

export type TransactionListParams = {
  type?: "income" | "expense" | "all";
  wallet_id?: string;
  from_date?: string;
  to_date?: string;
  tag?: string;
  q?: string;
  page?: number;
  per_page?: number;
};

export const transactionsApi = {
  async list(params: TransactionListParams = {}) {
    const { data } = await api.get<ApiEnvelope<Transaction[]>>("/transactions", {
      params,
    });
    const meta = (data.meta ?? {}) as Paginated<Transaction>["meta"];
    return {
      data: data.data,
      meta: {
        page: meta?.page ?? 1,
        per_page: meta?.per_page ?? 20,
        total: meta?.total ?? data.data.length,
        has_more: meta?.has_more ?? false,
      },
    };
  },
  async get(id: string) {
    const { data } = await api.get<ApiEnvelope<Transaction>>(
      `/transactions/${id}`,
    );
    return unwrap(data);
  },
  async create(input: TransactionInput) {
    const { data } = await api.post<ApiEnvelope<Transaction>>(
      "/transactions",
      input,
    );
    return unwrap(data);
  },
  async update(id: string, input: Partial<TransactionInput>) {
    const { data } = await api.patch<ApiEnvelope<Transaction>>(
      `/transactions/${id}`,
      input,
    );
    return unwrap(data);
  },
  async remove(id: string) {
    const { data } = await api.delete<ApiEnvelope<Transaction>>(
      `/transactions/${id}`,
    );
    return unwrap(data);
  },
  async scanUpload(file: File) {
    const form = new FormData();
    form.append("receipt_image", file);
    const { data } = await api.post<ApiEnvelope<{ id: string; status: string }>>(
      "/transactions/scan-ocr",
      form,
      { headers: { "Content-Type": "multipart/form-data" } },
    );
    return unwrap(data);
  },
  async scanOcrPoll(id: string) {
    const { data } = await api.get<ApiEnvelope<Record<string, unknown>>>(
      `/transactions/scan-ocr/${id}`,
    );
    return unwrap(data);
  },
  async scanOcrCommit(id: string, overrides: Partial<TransactionInput>) {
    const { data } = await api.post<ApiEnvelope<Transaction>>(
      `/transactions/scan-ocr/${id}/commit`,
      overrides,
    );
    return unwrap(data);
  },
};

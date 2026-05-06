import { api, unwrap } from "./client";
import type { ApiEnvelope, Wallet, WalletTransferResult } from "@/lib/types";

export type WalletInput = {
  wallet_name: string;
  balance: number;
  wallet_color?: string | null;
};

export type WalletTransferInput = {
  from_wallet_id: string;
  to_wallet_id: string;
  amount: number;
  notes?: string | null;
  date?: string | null;
};

export const walletsApi = {
  async list() {
    const { data } = await api.get<ApiEnvelope<Wallet[]>>("/wallets");
    return unwrap(data);
  },
  async get(id: string) {
    const { data } = await api.get<ApiEnvelope<Wallet>>(`/wallets/${id}`);
    return unwrap(data);
  },
  async create(input: WalletInput) {
    const { data } = await api.post<ApiEnvelope<Wallet>>("/wallets", input);
    return unwrap(data);
  },
  async update(id: string, input: Partial<WalletInput>) {
    const { data } = await api.patch<ApiEnvelope<Wallet>>(
      `/wallets/${id}`,
      input,
    );
    return unwrap(data);
  },
  async remove(id: string) {
    const { data } = await api.delete<ApiEnvelope<null>>(`/wallets/${id}`);
    return data;
  },
  async transfer(input: WalletTransferInput) {
    const { data } = await api.post<ApiEnvelope<WalletTransferResult>>(
      "/wallets/transfer",
      input,
    );
    return unwrap(data);
  },
};

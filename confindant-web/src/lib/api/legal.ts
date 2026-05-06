import { api, unwrap } from "./client";
import type { ApiEnvelope } from "@/lib/types";

export type LegalContent = {
  title?: string;
  body?: string;
  content?: string;
  html?: string;
  markdown?: string;
};

export const legalApi = {
  async privacy() {
    const { data } = await api.get<ApiEnvelope<LegalContent>>(
      "/legal/privacy",
    );
    return unwrap(data);
  },
  async terms() {
    const { data } = await api.get<ApiEnvelope<LegalContent>>("/legal/terms");
    return unwrap(data);
  },
  async support() {
    const { data } = await api.get<
      ApiEnvelope<{ type: string; label: string; value: string }[]>
    >("/support/channels");
    return unwrap(data);
  },
};

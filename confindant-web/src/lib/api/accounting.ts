import { api, unwrap } from "./client";
import type { ApiEnvelope } from "@/lib/types";
import type {
  Account,
  AssetSummary,
  BalanceSheet,
  BudgetCompare,
  FixedAsset,
  GeneralLedger,
  InviteInfo,
  JournalEntry,
  OrgBudget,
  OrgDashboard,
  OrgInvitation,
  OrgMember,
  Organization,
  OrgRole,
  ReceivablePayable,
  RecurringOrgEntry,
  RestrictedFund,
  RestrictedFundMovement,
  StatementOfActivities,
  TrialBalance,
} from "@/lib/accounting-types";

/**
 * All accounting endpoints accept an optional organization_id. The active org
 * is injected by the caller (from the org store) so the backend resolves the
 * right organization.
 */
function withOrg(orgId: string | null | undefined, params?: Record<string, unknown>) {
  return { params: { ...(orgId ? { organization_id: orgId } : {}), ...(params ?? {}) } };
}

export const organizationApi = {
  async list() {
    const { data } = await api.get<ApiEnvelope<Organization[]>>("/me/organizations");
    return unwrap(data);
  },

  async memberList(orgId: string) {
    const { data } = await api.get<ApiEnvelope<OrgMember[]>>(
      "/accounting/members",
      withOrg(orgId),
    );
    return unwrap(data);
  },

  async memberUpdateRole(orgId: string, userId: number, role: OrgRole) {
    const { data } = await api.patch<ApiEnvelope<OrgMember>>(
      `/accounting/members/${userId}`,
      { role },
      withOrg(orgId),
    );
    return unwrap(data);
  },

  async memberRemove(orgId: string, userId: number) {
    await api.delete(`/accounting/members/${userId}`, withOrg(orgId));
  },

  async invitationList(orgId: string) {
    const { data } = await api.get<ApiEnvelope<OrgInvitation[]>>(
      "/accounting/members/invitations",
      withOrg(orgId),
    );
    return unwrap(data);
  },

  async inviteCreate(orgId: string, email: string, role: OrgRole) {
    const { data } = await api.post<ApiEnvelope<{
      token: string;
      email: string;
      role: OrgRole;
      expires_at: string;
      invite_url: string;
    }>>("/accounting/members/invite", { organization_id: orgId, email, role });
    return unwrap(data);
  },

  async inviteCancel(orgId: string, token: string) {
    await api.delete(`/accounting/members/invitations/${token}`, withOrg(orgId));
  },

  async inviteInfo(token: string) {
    const { data } = await api.get<ApiEnvelope<InviteInfo>>(`/org-invite/${token}`);
    return unwrap(data);
  },

  async inviteAccept(token: string) {
    const { data } = await api.post<ApiEnvelope<{
      organization: { id: number; name: string; slug: string };
      role: OrgRole;
    }>>(`/org-invite/${token}/accept`, {});
    return unwrap(data);
  },
};

export const accountingApi = {
  async dashboard(orgId: string, year?: number) {
    const { data } = await api.get<ApiEnvelope<OrgDashboard>>(
      "/accounting/dashboard",
      withOrg(orgId, year ? { year } : undefined),
    );
    return unwrap(data);
  },

  async accounts(orgId: string) {
    const { data } = await api.get<ApiEnvelope<Account[]>>(
      "/accounting/accounts",
      withOrg(orgId),
    );
    return unwrap(data);
  },

  async balanceSheet(orgId: string, asOf?: string) {
    const { data } = await api.get<ApiEnvelope<BalanceSheet>>(
      "/accounting/reports/balance-sheet",
      withOrg(orgId, asOf ? { as_of: asOf } : undefined),
    );
    return unwrap(data);
  },

  async statementOfActivities(
    orgId: string,
    params: { year?: number; from_date?: string; to_date?: string } = {},
  ) {
    const { data } = await api.get<ApiEnvelope<StatementOfActivities>>(
      "/accounting/reports/activities",
      withOrg(orgId, params),
    );
    return unwrap(data);
  },

  async trialBalance(orgId: string, asOf?: string) {
    const { data } = await api.get<ApiEnvelope<TrialBalance>>(
      "/accounting/reports/trial-balance",
      withOrg(orgId, asOf ? { as_of: asOf } : undefined),
    );
    return unwrap(data);
  },

  async generalLedger(
    orgId: string,
    accountId: string,
    params: { from_date?: string; to_date?: string } = {},
  ) {
    const { data } = await api.get<ApiEnvelope<GeneralLedger>>(
      `/accounting/reports/ledger/${accountId}`,
      withOrg(orgId, params),
    );
    return unwrap(data);
  },

  async journalList(
    orgId: string,
    params: {
      from_date?: string;
      to_date?: string;
      status?: string;
      page?: number;
      per_page?: number;
    } = {},
  ) {
    const { data } = await api.get<ApiEnvelope<JournalEntry[]>>(
      "/accounting/journal",
      withOrg(orgId, params),
    );
    return { entries: unwrap(data), meta: data.meta };
  },

  async journalShow(orgId: string, id: string) {
    const { data } = await api.get<ApiEnvelope<JournalEntry>>(
      `/accounting/journal/${id}`,
      withOrg(orgId),
    );
    return unwrap(data);
  },

  async journalCreate(
    orgId: string,
    payload: {
      date: string;
      description: string;
      reference?: string | null;
      category?: string | null;
      classification?: string | null;
      lines: { account_id: string; debit?: number; credit?: number; memo?: string | null }[];
    },
  ) {
    const { data } = await api.post<ApiEnvelope<JournalEntry>>(
      "/accounting/journal",
      { organization_id: orgId, ...payload },
    );
    return unwrap(data);
  },

  async journalVoid(orgId: string, id: string) {
    const { data } = await api.post<ApiEnvelope<JournalEntry>>(
      `/accounting/journal/${id}/void`,
      { organization_id: orgId },
    );
    return unwrap(data);
  },

  // ---- Fixed Assets ----

  async fixedAssets(orgId: string) {
    const { data } = await api.get<ApiEnvelope<FixedAsset[]>>(
      "/accounting/fixed-assets",
      withOrg(orgId),
    );
    return { assets: unwrap(data), summary: data.meta as unknown as AssetSummary };
  },

  async createFixedAsset(
    orgId: string,
    payload: {
      name: string;
      group: string;
      acquisition_date: string;
      acquisition_cost: number;
      depreciation_rate?: number;
      salvage_value?: number;
      notes?: string | null;
    },
  ) {
    const { data } = await api.post<ApiEnvelope<FixedAsset>>(
      "/accounting/fixed-assets",
      { organization_id: orgId, ...payload },
    );
    return unwrap(data);
  },

  async runDepreciation(orgId: string, year: number) {
    const { data } = await api.post<
      ApiEnvelope<{ posted: number; skipped: number; total_amount: number }>
    >("/accounting/fixed-assets/run-depreciation", {
      organization_id: orgId,
      year,
    });
    return unwrap(data);
  },

  // ---- Receivables / Payables ----

  async receivablesPayables(
    orgId: string,
    params: { type?: string; status?: string } = {},
  ) {
    const { data } = await api.get<ApiEnvelope<ReceivablePayable[]>>(
      "/accounting/receivables-payables",
      withOrg(orgId, params),
    );
    return { items: unwrap(data), meta: data.meta };
  },

  async createReceivablePayable(
    orgId: string,
    payload: {
      type: "receivable" | "payable";
      party_name: string;
      category?: string | null;
      account_id: string;
      counter_account_id?: string | null;
      description?: string | null;
      original_amount: number;
      issued_date: string;
      due_date?: string | null;
      period_label?: string | null;
    },
  ) {
    const { data } = await api.post<ApiEnvelope<ReceivablePayable>>(
      "/accounting/receivables-payables",
      { organization_id: orgId, ...payload },
    );
    return unwrap(data);
  },

  async settleReceivablePayable(
    orgId: string,
    id: string,
    payload: {
      amount: number;
      cash_account_id: string;
      date: string;
      notes?: string | null;
    },
  ) {
    const { data } = await api.post<ApiEnvelope<unknown>>(
      `/accounting/receivables-payables/${id}/settle`,
      { organization_id: orgId, ...payload },
    );
    return unwrap(data);
  },

  // ---- Restricted Funds ----

  async restrictedFunds(orgId: string) {
    const { data } = await api.get<ApiEnvelope<RestrictedFund[]>>(
      "/accounting/restricted-funds",
      withOrg(orgId),
    );
    return { funds: unwrap(data), meta: data.meta };
  },

  async createRestrictedFund(
    orgId: string,
    payload: {
      name: string;
      fund_type?: string | null;
      account_id: string;
      notes?: string | null;
    },
  ) {
    const { data } = await api.post<ApiEnvelope<RestrictedFund>>(
      "/accounting/restricted-funds",
      { organization_id: orgId, ...payload },
    );
    return unwrap(data);
  },

  async moveRestrictedFund(
    orgId: string,
    id: string,
    payload: {
      direction: "in" | "out";
      amount: number;
      cash_account_id: string;
      date: string;
      description?: string | null;
    },
  ) {
    const { data } = await api.post<
      ApiEnvelope<{ movement: RestrictedFundMovement; fund: RestrictedFund }>
    >(`/accounting/restricted-funds/${id}/move`, {
      organization_id: orgId,
      ...payload,
    });
    return unwrap(data);
  },

  // ---- Import ----

  async importHarian(
    orgId: string,
    file: File,
    opts: { sheet_name?: string; dry_run?: boolean } = {},
  ) {
    const form = new FormData();
    form.append("file", file);
    form.append("organization_id", orgId);
    if (opts.sheet_name) form.append("sheet_name", opts.sheet_name);
    if (opts.dry_run) form.append("dry_run", "1");
    const { data } = await api.post<
      ApiEnvelope<{
        imported: number;
        skipped: number;
        unmapped: Record<string, number>;
        total_debit: number;
        total_credit: number;
        dry_run: boolean;
      }>
    >("/accounting/import/harian", form, {
      headers: { "Content-Type": "multipart/form-data" },
    });
    return unwrap(data);
  },

  // ---- PDF Export (Sprint 3) ----

  async downloadReportPdf(
    type: "balance-sheet" | "activities" | "trial-balance",
    orgId: string,
    params: Record<string, string | number | undefined> = {},
  ): Promise<void> {
    const { data, headers } = await api.get(
      `/accounting/reports/${type}/pdf`,
      {
        ...withOrg(orgId, params as Record<string, unknown>),
        responseType: "blob",
      },
    );
    const disposition: string = (headers as Record<string, string>)["content-disposition"] ?? "";
    const match = /filename[^;=\n]*=((['"]).*?\2|[^;\n]*)/.exec(disposition);
    const filename = match ? match[1].replace(/['"]/g, "") : `${type}.pdf`;
    const url = URL.createObjectURL(new Blob([data as BlobPart], { type: "application/pdf" }));
    const a = document.createElement("a");
    a.href = url;
    a.download = filename;
    a.click();
    URL.revokeObjectURL(url);
  },

  // ---- Recurring Org Entries (Sprint 2) ----

  async recurringList(orgId: string) {
    const { data } = await api.get<ApiEnvelope<RecurringOrgEntry[]>>(
      "/accounting/recurring",
      withOrg(orgId),
    );
    return unwrap(data);
  },

  async recurringCreate(
    orgId: string,
    payload: {
      debit_account_id: number;
      credit_account_id: number;
      description: string;
      category?: string | null;
      amount: number;
      frequency: "daily" | "weekly" | "monthly";
      interval?: number;
      start_date: string;
      end_date?: string | null;
      active?: boolean;
    },
  ) {
    const { data } = await api.post<ApiEnvelope<RecurringOrgEntry>>(
      "/accounting/recurring",
      payload,
      withOrg(orgId),
    );
    return unwrap(data);
  },

  async recurringUpdate(orgId: string, id: number, payload: Partial<{
    debit_account_id: number;
    credit_account_id: number;
    description: string;
    category: string | null;
    amount: number;
    frequency: "daily" | "weekly" | "monthly";
    interval: number;
    start_date: string;
    end_date: string | null;
    active: boolean;
  }>) {
    const { data } = await api.patch<ApiEnvelope<RecurringOrgEntry>>(
      `/accounting/recurring/${id}`,
      payload,
      withOrg(orgId),
    );
    return unwrap(data);
  },

  async recurringDelete(orgId: string, id: number) {
    const { data } = await api.delete<ApiEnvelope<null>>(
      `/accounting/recurring/${id}`,
      withOrg(orgId),
    );
    return data;
  },

  async recurringRun(orgId: string, id: number) {
    const { data } = await api.post<ApiEnvelope<{ journal_entry: JournalEntry; recurring: RecurringOrgEntry }>>(
      `/accounting/recurring/${id}/run`,
      {},
      withOrg(orgId),
    );
    return unwrap(data);
  },

  // ---- Budget vs Realisasi (Sprint 4) ----

  async budgetList(orgId: string, fiscalYear?: number) {
    const { data } = await api.get<ApiEnvelope<OrgBudget[]>>(
      "/accounting/budget",
      withOrg(orgId, fiscalYear ? { fiscal_year: fiscalYear } : undefined),
    );
    return unwrap(data);
  },

  async budgetCreate(
    orgId: string,
    payload: {
      name: string;
      fiscal_year: number;
      category?: string | null;
      account_id?: number | null;
      amount_planned: number;
      notes?: string | null;
    },
  ) {
    const { data } = await api.post<ApiEnvelope<OrgBudget>>(
      "/accounting/budget",
      { organization_id: orgId, ...payload },
    );
    return unwrap(data);
  },

  async budgetUpdate(orgId: string, id: number, payload: Partial<{
    name: string;
    category: string | null;
    account_id: number | null;
    amount_planned: number;
    notes: string | null;
  }>) {
    const { data } = await api.patch<ApiEnvelope<OrgBudget>>(
      `/accounting/budget/${id}`,
      payload,
      withOrg(orgId),
    );
    return unwrap(data);
  },

  async budgetDelete(orgId: string, id: number) {
    const { data } = await api.delete<ApiEnvelope<null>>(
      `/accounting/budget/${id}`,
      withOrg(orgId),
    );
    return data;
  },

  async budgetCompare(orgId: string, fiscalYear?: number) {
    const { data } = await api.get<ApiEnvelope<BudgetCompare>>(
      "/accounting/budget/compare",
      withOrg(orgId, fiscalYear ? { fiscal_year: fiscalYear } : undefined),
    );
    return unwrap(data);
  },

  async scanOcrCommitToJournal(
    orgId: string,
    ocrJobId: string,
    payload: {
      debit_account_id: number;
      credit_account_id: number;
      amount: number;
      date: string;
      description: string;
    },
  ) {
    const { data } = await api.post<ApiEnvelope<JournalEntry>>(
      `/accounting/scan-ocr/${ocrJobId}/commit`,
      payload,
      withOrg(orgId),
    );
    return unwrap(data);
  },
};

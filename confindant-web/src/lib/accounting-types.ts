// Types for the organization accounting module (matches confindant-backend
// /api/v1/accounting/* response shapes).

export type OrgRole = "admin" | "bendahara" | "auditor" | "viewer";

export type Organization = {
  id: string;
  name: string;
  slug: string;
  legal_name?: string | null;
  currency: string;
  role: OrgRole;
};

export type AccountType =
  | "asset"
  | "liability"
  | "net_asset"
  | "revenue"
  | "expense";

export type Account = {
  id: string;
  organization_id: string;
  code: string;
  name: string;
  type: AccountType;
  subtype?: string | null;
  normal_balance: "debit" | "credit";
  is_contra: boolean;
  opening_balance: number;
  is_active: boolean;
};

export type JournalLine = {
  id: string;
  account_id: string;
  debit: number;
  credit: number;
  memo?: string | null;
  account?: Account;
};

export type JournalEntry = {
  id: string;
  entry_number?: string | null;
  date: string;
  description: string;
  reference?: string | null;
  category?: string | null;
  classification?: string | null;
  status: "draft" | "posted" | "void";
  source: string;
  total_amount: number;
  lines: JournalLine[];
  created_at?: string;
};

// ---- Reports ----

export type ReportAccountRow = {
  code: string;
  name: string;
  subtype?: string | null;
  amount: number;
};

export type ReportGroup = {
  subtype: string;
  accounts: ReportAccountRow[];
  subtotal: number;
};

export type ReportSection = {
  accounts: ReportAccountRow[];
  groups: ReportGroup[];
  total: number;
};

export type BalanceSheet = {
  as_of: string;
  assets: ReportSection;
  liabilities: ReportSection;
  net_assets: {
    accounts: ReportAccountRow[];
    recorded_total: number;
    change_in_net_assets: number;
    total: number;
  };
  totals: {
    total_assets: number;
    total_liabilities: number;
    total_net_assets: number;
    total_liabilities_and_net_assets: number;
  };
  is_balanced: boolean;
  difference: number;
};

export type StatementOfActivities = {
  period: { from: string; to: string };
  revenue: ReportSection;
  expense: ReportSection;
  totals: {
    total_revenue: number;
    total_expense: number;
    change_in_net_assets: number;
  };
};

export type TrialBalanceRow = {
  code: string;
  name: string;
  type: AccountType;
  debit: number;
  credit: number;
};

export type TrialBalance = {
  as_of: string;
  rows: TrialBalanceRow[];
  total_debit: number;
  total_credit: number;
  is_balanced: boolean;
};

export type GeneralLedger = {
  account: {
    id: string;
    code: string;
    name: string;
    type: AccountType;
    normal_balance: string;
  };
  opening_balance: number;
  closing_balance: number;
  lines: {
    date: string;
    entry_number?: string | null;
    description: string;
    debit: number;
    credit: number;
    balance: number;
  }[];
};

export type MonthlyTrendPoint = {
  month: number;
  label: string;
  revenue: number;
  expense: number;
  net: number;
};

// ---- Fixed Assets ----

export type FixedAsset = {
  id: string;
  name: string;
  group: string | null;
  acquisition_date: string;
  acquisition_cost: number;
  depreciation_rate: number;
  accumulated_depreciation: number;
  book_value: number;
  is_active: boolean;
  notes?: string | null;
};

export type AssetSummary = {
  total_acquisition_cost: number;
  total_accumulated_depreciation: number;
  total_book_value: number;
  count: number;
};

// ---- Receivables / Payables ----

export type ReceivablePayable = {
  id: string;
  type: "receivable" | "payable";
  party_name: string;
  category?: string | null;
  account_id?: string | null;
  description?: string | null;
  original_amount: number;
  settled_amount: number;
  outstanding_amount: number;
  issued_date: string;
  due_date?: string | null;
  status: "open" | "partial" | "settled" | "written_off";
  period_label?: string | null;
};

// ---- Restricted Funds ----

export type RestrictedFund = {
  id: string;
  name: string;
  fund_type?: string | null;
  account_id?: string | null;
  balance: number;
  status: string;
  notes?: string | null;
};

export type RestrictedFundMovement = {
  id: string;
  date: string;
  direction: "in" | "out";
  amount: number;
  balance_after: number;
  description?: string | null;
};

export type OrgDashboard = {
  year: number;
  summary: {
    total_assets: number;
    total_liabilities: number;
    total_net_assets: number;
    cash: number;
    total_revenue: number;
    total_expense: number;
    change_in_net_assets: number;
  };
  is_balanced: boolean;
  monthly_trend: MonthlyTrendPoint[];
  top_expense_accounts: ReportAccountRow[];
  top_revenue_accounts: ReportAccountRow[];
};

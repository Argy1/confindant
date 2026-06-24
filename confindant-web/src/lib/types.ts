// Core types matching confindant-backend response shapes.

export type ApiEnvelope<T> = {
  success: boolean;
  message: string;
  data: T;
  meta?: Record<string, unknown>;
  errors?: Record<string, string | string[]>;
};

export type Paginated<T> = {
  data: T[];
  meta: { page: number; per_page: number; total: number; has_more: boolean };
};

export type User = {
  id: string;
  username: string;
  email: string;
  created_at?: string;
  updated_at?: string;
};

export type LoginResponse = {
  user: User;
  access_token: string;
  token_type: string;
};

export type Wallet = {
  id: string;
  user_id: string;
  wallet_name: string;
  balance: number;
  wallet_color?: string | null;
  created_at?: string;
  updated_at?: string;
};

export type WalletTransferResult = {
  transfer_group_id: string;
  from_wallet: Wallet;
  to_wallet: Wallet;
  outgoing_transaction: Transaction;
  incoming_transaction: Transaction;
};

export type TxType = "income" | "expense";
export type NeedWant = "needs" | "wants" | "mixed" | "unknown";
export type OcrStatus =
  | "none"
  | "pending"
  | "processing"
  | "completed"
  | "failed";

export type Transaction = {
  id: string;
  user_id: string;
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
  is_verified: boolean;
  items?: unknown[] | null;
  is_internal_transfer: boolean;
  transfer_group_id?: string | null;
  tags: string[];
  ocr_status: OcrStatus;
  ocr_confidence?: number | null;
  ocr_raw?: Record<string, unknown> | null;
  ai_category?: string | null;
  ai_confidence?: number | null;
  ai_suggested?: boolean;
  ai_provider?: string | null;
  created_at?: string;
  updated_at?: string;
};

export type Budget = {
  id: string;
  user_id: string;
  category: string;
  limit_amount: number;
  period_month: string;
  alert_threshold?: number;
  created_at?: string;
  updated_at?: string;
};

export type GoalContribution = {
  date_label: string;
  amount: number;
  note?: string | null;
};

export type Goal = {
  id: string;
  user_id: string;
  name: string;
  target_amount: number;
  current_amount: number;
  target_date_label: string;
  linked_wallet: string;
  contributions: GoalContribution[];
  auto_topup_enabled: boolean;
  auto_topup_percent?: number;
  created_at?: string;
  updated_at?: string;
};

export type Habit = {
  id: string;
  user_id: string;
  title: string;
  description: string;
  target_count: number;
  current_count: number;
  frequency: "daily" | "weekly";
  active: boolean;
  created_at?: string;
  updated_at?: string;
};

export type RecurringTransaction = {
  id: string;
  user_id: string;
  wallet_id: string;
  type: TxType;
  source?: string | null;
  category?: string | null;
  amount: number;
  merchant_name?: string | null;
  notes?: string | null;
  is_verified: boolean;
  tags: string[];
  frequency: "daily" | "weekly" | "monthly";
  interval: number;
  start_date: string;
  next_run_at: string;
  last_run_at?: string | null;
  end_date?: string | null;
  active: boolean;
  total_runs: number;
  last_error_code?: string | null;
  last_error_message?: string | null;
  created_at?: string;
  updated_at?: string;
};

export type DashboardData = {
  summary: {
    balance: number;
    income: number;
    expense: number;
    last_updated_label: string;
  };
  cashflow_forecast?: {
    next_7_days?: { date: string; projected_balance: number }[];
    next_30_days?: { date: string; projected_balance: number }[];
  } | null;
  quick_actions: { type: string; label: string }[];
  budget_items: {
    id: string;
    category: string;
    used: number;
    limit: number;
  }[];
  recent_transactions: {
    id: string;
    wallet_id: string;
    title: string;
    subtitle: string;
    amount: number;
    is_expense: boolean;
    type: TxType;
    source?: string | null;
    category?: string | null;
    notes?: string | null;
    tags?: string[];
  }[];
  insight_text?: string | null;
};

export type AnalyticsData = {
  income: number;
  expense: number;
  net_cashflow: number;
  income_vs_previous?: { amount: number; percent_change: number };
  expense_vs_previous?: { amount: number; percent_change: number };
  by_category: { category: string; amount: number; percent: number }[];
  daily_breakdown: { date: string; income: number; expense: number; net: number }[];
  budget_performance: {
    category: string;
    budget: number;
    spent: number;
    remaining: number;
    status: "on_track" | "warning" | "exceeded";
  }[];
  insight_text?: string;
  anomaly?: { category: string; spike_percent: number; message: string };
};

export type AnalyticsRaw = {
  summary: { total_income: number; total_expense: number; net_saving: number };
  category_breakdown: { label: string; amount: number }[];
  income_breakdown: { label: string; amount: number }[];
  net_flow_trend: { label: string; income: number; expense: number; amount: number }[];
  trend_points: { label: string; amount: number }[];
  income_trend_points: { label: string; amount: number }[];
  budget_progress: { category: string; used: number; limit: number }[];
  comparison: { mode: string; current_value: number; previous_value: number; delta_percent: number };
  anomaly: { category: string; spike_percent: number; message: string };
  insight_text: string;
};

export type ProfileData = {
  profile: {
    id: string;
      user_id: string;
    full_name: string;
    username: string;
    email: string;
    phone?: string | null;
    currency: string;
    avatar_path: string;
    notification_settings: {
      push_enabled: boolean;
      email_enabled: boolean;
      transaction_alerts: boolean;
      budget_alerts: boolean;
      weekly_report: boolean;
    };
    faq_items?: { question: string; answer: string; expanded?: boolean }[];
    about_info?: {
      app_name: string;
      version: string;
      build: string;
      description: string;
    };
    created_at?: string;
    updated_at?: string;
  };
  notifications: NotificationItem[];
};

export type NotificationItem = {
  id: string;
  user_id: string;
  title: string;
  subtitle: string;
  time_label: string;
  read: boolean;
  event_key?: string | null;
  created_at?: string;
};

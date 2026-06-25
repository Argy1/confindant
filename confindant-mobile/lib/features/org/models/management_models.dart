import 'package:confindant/core/network/dto_utils.dart';

class RecurringOrgData {
  const RecurringOrgData({
    required this.id,
    required this.debitAccountId,
    required this.creditAccountId,
    required this.description,
    required this.amount,
    required this.frequency,
    required this.interval,
    required this.startDate,
    required this.active,
    required this.totalRuns,
    this.category,
    this.endDate,
    this.nextRunAt,
    this.lastRunAt,
    this.debitAccountCode,
    this.debitAccountName,
    this.creditAccountCode,
    this.creditAccountName,
  });

  final String id;
  final String debitAccountId;
  final String creditAccountId;
  final String description;
  final double amount;
  final String frequency;
  final int interval;
  final String startDate;
  final bool active;
  final int totalRuns;
  final String? category;
  final String? endDate;
  final String? nextRunAt;
  final String? lastRunAt;
  final String? debitAccountCode;
  final String? debitAccountName;
  final String? creditAccountCode;
  final String? creditAccountName;

  factory RecurringOrgData.fromJson(Map<String, dynamic> json) {
    final debitAcc = json['debit_account'] as Map?;
    final creditAcc = json['credit_account'] as Map?;
    return RecurringOrgData(
      id: normalizeId(json),
      debitAccountId: json['debit_account_id']?.toString() ?? '',
      creditAccountId: json['credit_account_id']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      amount: asDouble(json['amount']),
      frequency: json['frequency']?.toString() ?? 'monthly',
      interval: asInt(json['interval'], fallback: 1),
      startDate: json['start_date']?.toString() ?? '',
      active: json['active'] == true,
      totalRuns: asInt(json['total_runs']),
      category: json['category']?.toString(),
      endDate: json['end_date']?.toString(),
      nextRunAt: json['next_run_at']?.toString(),
      lastRunAt: json['last_run_at']?.toString(),
      debitAccountCode: debitAcc?['code']?.toString(),
      debitAccountName: debitAcc?['name']?.toString(),
      creditAccountCode: creditAcc?['code']?.toString(),
      creditAccountName: creditAcc?['name']?.toString(),
    );
  }
}

class OrgMemberData {
  const OrgMemberData({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.joinedAt,
    this.avatar,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String joinedAt;
  final String? avatar;

  factory OrgMemberData.fromJson(Map<String, dynamic> json) {
    return OrgMemberData(
      id: normalizeId(json),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'viewer',
      joinedAt: json['joined_at']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
    );
  }
}

class OrgInvitationData {
  const OrgInvitationData({
    required this.token,
    required this.email,
    required this.role,
    required this.expiresAt,
    required this.inviterName,
  });

  final String token;
  final String email;
  final String role;
  final String expiresAt;
  final String inviterName;

  factory OrgInvitationData.fromJson(Map<String, dynamic> json) {
    final invitedBy = json['invited_by'] as Map? ?? const {};
    return OrgInvitationData(
      token: json['token']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'viewer',
      expiresAt: json['expires_at']?.toString() ?? '',
      inviterName: invitedBy['name']?.toString() ?? '',
    );
  }
}

class OrgBudgetData {
  const OrgBudgetData({
    required this.id,
    required this.name,
    required this.fiscalYear,
    required this.amountPlanned,
    this.category,
    this.accountId,
    this.accountCode,
    this.accountName,
    this.notes,
  });

  final String id;
  final String name;
  final int fiscalYear;
  final double amountPlanned;
  final String? category;
  final String? accountId;
  final String? accountCode;
  final String? accountName;
  final String? notes;

  factory OrgBudgetData.fromJson(Map<String, dynamic> json) {
    final acc = json['account'] as Map?;
    return OrgBudgetData(
      id: normalizeId(json),
      name: json['name']?.toString() ?? '',
      fiscalYear: asInt(json['fiscal_year'], fallback: DateTime.now().year),
      amountPlanned: asDouble(json['amount_planned']),
      category: json['category']?.toString(),
      accountId: acc != null ? normalizeId(Map<String, dynamic>.from(acc)) : null,
      accountCode: acc?['code']?.toString(),
      accountName: acc?['name']?.toString(),
      notes: json['notes']?.toString(),
    );
  }
}

class BudgetCompareItem {
  const BudgetCompareItem({
    required this.id,
    required this.name,
    required this.amountPlanned,
    required this.amountActual,
    required this.percentage,
    required this.variance,
    this.category,
    this.accountCode,
    this.accountName,
    this.notes,
  });

  final String id;
  final String name;
  final double amountPlanned;
  final double amountActual;
  final double percentage;
  final double variance;
  final String? category;
  final String? accountCode;
  final String? accountName;
  final String? notes;

  factory BudgetCompareItem.fromJson(Map<String, dynamic> json) {
    final acc = json['account'] as Map?;
    return BudgetCompareItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      amountPlanned: asDouble(json['amount_planned']),
      amountActual: asDouble(json['amount_actual']),
      percentage: asDouble(json['percentage']),
      variance: asDouble(json['variance']),
      category: json['category']?.toString(),
      accountCode: acc?['code']?.toString(),
      accountName: acc?['name']?.toString(),
      notes: json['notes']?.toString(),
    );
  }
}

class BudgetCompareData {
  const BudgetCompareData({
    required this.fiscalYear,
    required this.items,
    required this.totalPlanned,
    required this.totalActual,
    required this.totalVariance,
    required this.overallPercentage,
  });

  final int fiscalYear;
  final List<BudgetCompareItem> items;
  final double totalPlanned;
  final double totalActual;
  final double totalVariance;
  final double overallPercentage;

  factory BudgetCompareData.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] as Map? ?? const {};
    return BudgetCompareData(
      fiscalYear: asInt(json['fiscal_year'], fallback: DateTime.now().year),
      items: (json['items'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => BudgetCompareItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      totalPlanned: asDouble(totals['total_planned']),
      totalActual: asDouble(totals['total_actual']),
      totalVariance: asDouble(totals['total_variance']),
      overallPercentage: asDouble(totals['overall_percentage']),
    );
  }
}

class FixedAssetData {
  const FixedAssetData({
    required this.id,
    required this.name,
    required this.group,
    required this.acquisitionDate,
    required this.acquisitionCost,
    required this.accumulatedDepreciation,
    required this.bookValue,
  });

  final String id;
  final String name;
  final String? group;
  final String acquisitionDate;
  final double acquisitionCost;
  final double accumulatedDepreciation;
  final double bookValue;

  factory FixedAssetData.fromJson(Map<String, dynamic> json) {
    return FixedAssetData(
      id: normalizeId(json),
      name: json['name']?.toString() ?? '',
      group: json['group']?.toString(),
      acquisitionDate: json['acquisition_date']?.toString() ?? '',
      acquisitionCost: asDouble(json['acquisition_cost']),
      accumulatedDepreciation: asDouble(json['accumulated_depreciation']),
      bookValue: asDouble(json['book_value']),
    );
  }
}

class ReceivablePayableData {
  const ReceivablePayableData({
    required this.id,
    required this.type,
    required this.partyName,
    required this.category,
    required this.originalAmount,
    required this.settledAmount,
    required this.outstandingAmount,
    required this.issuedDate,
    required this.status,
    this.periodLabel,
  });

  final String id;
  final String type; // receivable | payable
  final String partyName;
  final String? category;
  final double originalAmount;
  final double settledAmount;
  final double outstandingAmount;
  final String issuedDate;
  final String status; // open | partial | settled | written_off
  final String? periodLabel;

  factory ReceivablePayableData.fromJson(Map<String, dynamic> json) {
    return ReceivablePayableData(
      id: normalizeId(json),
      type: json['type']?.toString() ?? 'receivable',
      partyName: json['party_name']?.toString() ?? '',
      category: json['category']?.toString(),
      originalAmount: asDouble(json['original_amount']),
      settledAmount: asDouble(json['settled_amount']),
      outstandingAmount: asDouble(json['outstanding_amount']),
      issuedDate: json['issued_date']?.toString() ?? '',
      status: json['status']?.toString() ?? 'open',
      periodLabel: json['period_label']?.toString(),
    );
  }
}

class RestrictedFundData {
  const RestrictedFundData({
    required this.id,
    required this.name,
    required this.fundType,
    required this.balance,
  });

  final String id;
  final String name;
  final String? fundType;
  final double balance;

  factory RestrictedFundData.fromJson(Map<String, dynamic> json) {
    return RestrictedFundData(
      id: normalizeId(json),
      name: json['name']?.toString() ?? '',
      fundType: json['fund_type']?.toString(),
      balance: asDouble(json['balance']),
    );
  }
}

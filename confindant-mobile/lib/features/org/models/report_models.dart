import 'package:confindant/core/network/dto_utils.dart';

/// One account line in a report section.
class ReportAccountRow {
  const ReportAccountRow({
    required this.code,
    required this.name,
    required this.amount,
    this.subtype,
  });

  final String code;
  final String name;
  final double amount;
  final String? subtype;

  factory ReportAccountRow.fromJson(Map<String, dynamic> json) {
    return ReportAccountRow(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      amount: asDouble(json['amount']),
      subtype: json['subtype']?.toString(),
    );
  }
}

/// A grouped subsection (by subtype) inside a report section.
class ReportGroup {
  const ReportGroup({
    required this.subtype,
    required this.accounts,
    required this.subtotal,
  });

  final String subtype;
  final List<ReportAccountRow> accounts;
  final double subtotal;

  factory ReportGroup.fromJson(Map<String, dynamic> json) {
    return ReportGroup(
      subtype: json['subtype']?.toString() ?? 'lain',
      accounts: (json['accounts'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => ReportAccountRow.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      subtotal: asDouble(json['subtotal']),
    );
  }
}

class ReportSection {
  const ReportSection({required this.groups, required this.total});

  final List<ReportGroup> groups;
  final double total;

  factory ReportSection.fromJson(Map<String, dynamic> json) {
    return ReportSection(
      groups: (json['groups'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => ReportGroup.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      total: asDouble(json['total']),
    );
  }
}

class BalanceSheetData {
  const BalanceSheetData({
    required this.asOf,
    required this.assets,
    required this.liabilities,
    required this.netAssetAccounts,
    required this.changeInNetAssets,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.totalNetAssets,
    required this.totalLiabilitiesAndNetAssets,
    required this.isBalanced,
    required this.difference,
  });

  final String asOf;
  final ReportSection assets;
  final ReportSection liabilities;
  final List<ReportAccountRow> netAssetAccounts;
  final double changeInNetAssets;
  final double totalAssets;
  final double totalLiabilities;
  final double totalNetAssets;
  final double totalLiabilitiesAndNetAssets;
  final bool isBalanced;
  final double difference;

  factory BalanceSheetData.fromJson(Map<String, dynamic> json) {
    final totals = Map<String, dynamic>.from(json['totals'] as Map? ?? {});
    final netAssets = Map<String, dynamic>.from(json['net_assets'] as Map? ?? {});
    return BalanceSheetData(
      asOf: json['as_of']?.toString() ?? '',
      assets: ReportSection.fromJson(
        Map<String, dynamic>.from(json['assets'] as Map? ?? {}),
      ),
      liabilities: ReportSection.fromJson(
        Map<String, dynamic>.from(json['liabilities'] as Map? ?? {}),
      ),
      netAssetAccounts: (netAssets['accounts'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => ReportAccountRow.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      changeInNetAssets: asDouble(netAssets['change_in_net_assets']),
      totalAssets: asDouble(totals['total_assets']),
      totalLiabilities: asDouble(totals['total_liabilities']),
      totalNetAssets: asDouble(totals['total_net_assets']),
      totalLiabilitiesAndNetAssets:
          asDouble(totals['total_liabilities_and_net_assets']),
      isBalanced: json['is_balanced'] == true,
      difference: asDouble(json['difference']),
    );
  }
}

class ActivitiesData {
  const ActivitiesData({
    required this.revenue,
    required this.expense,
    required this.totalRevenue,
    required this.totalExpense,
    required this.changeInNetAssets,
  });

  final ReportSection revenue;
  final ReportSection expense;
  final double totalRevenue;
  final double totalExpense;
  final double changeInNetAssets;

  factory ActivitiesData.fromJson(Map<String, dynamic> json) {
    final totals = Map<String, dynamic>.from(json['totals'] as Map? ?? {});
    return ActivitiesData(
      revenue: ReportSection.fromJson(
        Map<String, dynamic>.from(json['revenue'] as Map? ?? {}),
      ),
      expense: ReportSection.fromJson(
        Map<String, dynamic>.from(json['expense'] as Map? ?? {}),
      ),
      totalRevenue: asDouble(totals['total_revenue']),
      totalExpense: asDouble(totals['total_expense']),
      changeInNetAssets: asDouble(totals['change_in_net_assets']),
    );
  }
}

class TrialBalanceRow {
  const TrialBalanceRow({
    required this.code,
    required this.name,
    required this.debit,
    required this.credit,
  });

  final String code;
  final String name;
  final double debit;
  final double credit;

  factory TrialBalanceRow.fromJson(Map<String, dynamic> json) {
    return TrialBalanceRow(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      debit: asDouble(json['debit']),
      credit: asDouble(json['credit']),
    );
  }
}

class TrialBalanceData {
  const TrialBalanceData({
    required this.asOf,
    required this.rows,
    required this.totalDebit,
    required this.totalCredit,
    required this.isBalanced,
  });

  final String asOf;
  final List<TrialBalanceRow> rows;
  final double totalDebit;
  final double totalCredit;
  final bool isBalanced;

  factory TrialBalanceData.fromJson(Map<String, dynamic> json) {
    return TrialBalanceData(
      asOf: json['as_of']?.toString() ?? '',
      rows: (json['rows'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => TrialBalanceRow.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      totalDebit: asDouble(json['total_debit']),
      totalCredit: asDouble(json['total_credit']),
      isBalanced: json['is_balanced'] == true,
    );
  }
}

class LedgerLine {
  const LedgerLine({
    required this.date,
    required this.description,
    required this.entryNumber,
    required this.debit,
    required this.credit,
    required this.balance,
  });

  final String date;
  final String description;
  final String? entryNumber;
  final double debit;
  final double credit;
  final double balance;

  factory LedgerLine.fromJson(Map<String, dynamic> json) {
    return LedgerLine(
      date: json['date']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      entryNumber: json['entry_number']?.toString(),
      debit: asDouble(json['debit']),
      credit: asDouble(json['credit']),
      balance: asDouble(json['balance']),
    );
  }
}

class GeneralLedgerData {
  const GeneralLedgerData({
    required this.accountCode,
    required this.accountName,
    required this.openingBalance,
    required this.closingBalance,
    required this.lines,
  });

  final String accountCode;
  final String accountName;
  final double openingBalance;
  final double closingBalance;
  final List<LedgerLine> lines;

  factory GeneralLedgerData.fromJson(Map<String, dynamic> json) {
    final account = Map<String, dynamic>.from(json['account'] as Map? ?? {});
    return GeneralLedgerData(
      accountCode: account['code']?.toString() ?? '',
      accountName: account['name']?.toString() ?? '',
      openingBalance: asDouble(json['opening_balance']),
      closingBalance: asDouble(json['closing_balance']),
      lines: (json['lines'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => LedgerLine.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

/// A chart-of-accounts entry (used to map code -> id for ledger drill-down).
class OrgAccount {
  const OrgAccount({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.normalBalance,
    this.subtype,
    this.isContra = false,
  });

  final String id;
  final String code;
  final String name;
  final String type;
  final String normalBalance;
  final String? subtype;
  final bool isContra;

  factory OrgAccount.fromJson(Map<String, dynamic> json) {
    return OrgAccount(
      id: normalizeId(json),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      normalBalance: json['normal_balance']?.toString() ?? 'debit',
      subtype: json['subtype']?.toString(),
      isContra: json['is_contra'] == true,
    );
  }
}

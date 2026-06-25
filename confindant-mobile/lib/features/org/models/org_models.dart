import 'package:confindant/core/network/dto_utils.dart';

/// An organization the current user belongs to, with their role.
class Organization {
  const Organization({
    required this.id,
    required this.name,
    required this.slug,
    required this.role,
    this.legalName,
    this.currency = 'IDR',
  });

  final String id;
  final String name;
  final String slug;
  final String role; // admin | bendahara | auditor | viewer
  final String? legalName;
  final String currency;

  bool get canWrite => role == 'admin' || role == 'bendahara';

  String get roleLabel {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'bendahara':
        return 'Bendahara';
      case 'auditor':
        return 'Auditor';
      default:
        return 'Viewer';
    }
  }

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: normalizeId(json),
      name: json['name']?.toString() ?? 'Organisasi',
      slug: json['slug']?.toString() ?? '',
      role: json['role']?.toString() ?? 'viewer',
      legalName: json['legal_name']?.toString(),
      currency: json['currency']?.toString() ?? 'IDR',
    );
  }
}

/// Aggregated dashboard figures for an organization.
class OrgDashboardData {
  const OrgDashboardData({
    required this.year,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.totalNetAssets,
    required this.cash,
    required this.totalRevenue,
    required this.totalExpense,
    required this.changeInNetAssets,
    required this.isBalanced,
    required this.monthlyTrend,
    required this.topExpense,
    required this.topRevenue,
  });

  final int year;
  final double totalAssets;
  final double totalLiabilities;
  final double totalNetAssets;
  final double cash;
  final double totalRevenue;
  final double totalExpense;
  final double changeInNetAssets;
  final bool isBalanced;
  final List<OrgTrendPoint> monthlyTrend;
  final List<OrgAccountAmount> topExpense;
  final List<OrgAccountAmount> topRevenue;

  factory OrgDashboardData.fromJson(Map<String, dynamic> json) {
    final summary = Map<String, dynamic>.from(json['summary'] as Map? ?? {});
    return OrgDashboardData(
      year: asInt(json['year']),
      totalAssets: asDouble(summary['total_assets']),
      totalLiabilities: asDouble(summary['total_liabilities']),
      totalNetAssets: asDouble(summary['total_net_assets']),
      cash: asDouble(summary['cash']),
      totalRevenue: asDouble(summary['total_revenue']),
      totalExpense: asDouble(summary['total_expense']),
      changeInNetAssets: asDouble(summary['change_in_net_assets']),
      isBalanced: json['is_balanced'] == true,
      monthlyTrend: (json['monthly_trend'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => OrgTrendPoint.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      topExpense: (json['top_expense_accounts'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => OrgAccountAmount.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      topRevenue: (json['top_revenue_accounts'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => OrgAccountAmount.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class OrgTrendPoint {
  const OrgTrendPoint({
    required this.label,
    required this.revenue,
    required this.expense,
  });

  final String label;
  final double revenue;
  final double expense;

  factory OrgTrendPoint.fromJson(Map<String, dynamic> json) {
    return OrgTrendPoint(
      label: json['label']?.toString() ?? '',
      revenue: asDouble(json['revenue']),
      expense: asDouble(json['expense']),
    );
  }
}

class OrgAccountAmount {
  const OrgAccountAmount({
    required this.code,
    required this.name,
    required this.amount,
  });

  final String code;
  final String name;
  final double amount;

  factory OrgAccountAmount.fromJson(Map<String, dynamic> json) {
    return OrgAccountAmount(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      amount: asDouble(json['amount']),
    );
  }
}

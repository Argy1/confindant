import 'package:confindant/core/network/dto_utils.dart';

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

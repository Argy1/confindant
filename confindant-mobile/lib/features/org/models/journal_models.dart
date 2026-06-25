import 'package:confindant/core/network/dto_utils.dart';

class JournalLineData {
  const JournalLineData({
    required this.id,
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    required this.debit,
    required this.credit,
    this.memo,
  });

  final String id;
  final String accountId;
  final String accountCode;
  final String accountName;
  final double debit;
  final double credit;
  final String? memo;

  factory JournalLineData.fromJson(Map<String, dynamic> json) {
    final account = Map<String, dynamic>.from(json['account'] as Map? ?? {});
    return JournalLineData(
      id: normalizeId(json),
      accountId: json['account_id']?.toString() ?? '',
      accountCode: account['code']?.toString() ?? '',
      accountName: account['name']?.toString() ?? '',
      debit: asDouble(json['debit']),
      credit: asDouble(json['credit']),
      memo: json['memo']?.toString(),
    );
  }
}

class JournalEntryData {
  const JournalEntryData({
    required this.id,
    required this.entryNumber,
    required this.date,
    required this.description,
    required this.status,
    required this.totalAmount,
    required this.lines,
    this.reference,
    this.category,
  });

  final String id;
  final String? entryNumber;
  final String date;
  final String description;
  final String status; // draft | posted | void
  final double totalAmount;
  final List<JournalLineData> lines;
  final String? reference;
  final String? category;

  bool get isVoid => status == 'void';

  factory JournalEntryData.fromJson(Map<String, dynamic> json) {
    return JournalEntryData(
      id: normalizeId(json),
      entryNumber: json['entry_number']?.toString(),
      date: json['date']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'posted',
      totalAmount: asDouble(json['total_amount']),
      lines: (json['lines'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => JournalLineData.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      reference: json['reference']?.toString(),
      category: json['category']?.toString(),
    );
  }
}

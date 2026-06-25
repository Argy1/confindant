import 'package:confindant/core/constants/app_providers.dart';
import 'package:confindant/core/network/backend_api_service.dart';
import 'package:confindant/features/org/models/journal_models.dart';
import 'package:confindant/features/org/models/management_models.dart';
import 'package:confindant/features/org/models/org_models.dart';
import 'package:confindant/features/org/models/report_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Data access for organization-level resources (orgs, dashboard, reports).
class OrgDataSource {
  const OrgDataSource(this._api);

  final BackendApiService _api;

  Future<List<Organization>> organizations() async {
    final raw = await _api.myOrganizations();
    return raw.map(Organization.fromJson).toList();
  }

  Future<OrgDashboardData> dashboard(String orgId, {int? year}) async {
    final raw = await _api.orgDashboard(orgId, year: year);
    return OrgDashboardData.fromJson(raw);
  }

  Future<List<OrgAccount>> accounts(String orgId) async {
    final raw = await _api.orgAccounts(orgId);
    return raw.map(OrgAccount.fromJson).toList();
  }

  Future<BalanceSheetData> balanceSheet(String orgId, {String? asOf}) async {
    final raw = await _api.orgBalanceSheet(orgId, asOf: asOf);
    return BalanceSheetData.fromJson(raw);
  }

  Future<ActivitiesData> activities(String orgId, {int? year}) async {
    final raw = await _api.orgActivities(orgId, year: year);
    return ActivitiesData.fromJson(raw);
  }

  Future<TrialBalanceData> trialBalance(String orgId, {String? asOf}) async {
    final raw = await _api.orgTrialBalance(orgId, asOf: asOf);
    return TrialBalanceData.fromJson(raw);
  }

  Future<GeneralLedgerData> generalLedger(
    String orgId,
    String accountId, {
    String? fromDate,
    String? toDate,
  }) async {
    final raw = await _api.orgGeneralLedger(
      orgId,
      accountId,
      fromDate: fromDate,
      toDate: toDate,
    );
    return GeneralLedgerData.fromJson(raw);
  }

  Future<List<JournalEntryData>> journal(String orgId, {int perPage = 100}) async {
    final raw = await _api.orgJournal(orgId, perPage: perPage);
    return raw.map(JournalEntryData.fromJson).toList();
  }

  Future<JournalEntryData> journalShow(String orgId, String id) async {
    final raw = await _api.orgJournalShow(orgId, id);
    return JournalEntryData.fromJson(raw);
  }

  Future<JournalEntryData> journalCreate(
    String orgId,
    Map<String, dynamic> body,
  ) async {
    final raw = await _api.orgJournalCreate(orgId, body);
    return JournalEntryData.fromJson(raw);
  }

  Future<void> journalVoid(String orgId, String id) async {
    await _api.orgJournalVoid(orgId, id);
  }

  // --- Fixed assets ---

  Future<List<FixedAssetData>> fixedAssets(String orgId) async {
    final raw = await _api.orgFixedAssets(orgId);
    return raw.map(FixedAssetData.fromJson).toList();
  }

  Future<void> createFixedAsset(
    String orgId,
    Map<String, dynamic> body,
  ) async {
    await _api.orgCreateFixedAsset(orgId, body);
  }

  Future<Map<String, dynamic>> runDepreciation(String orgId, int year) async {
    return _api.orgRunDepreciation(orgId, year);
  }

  // --- Receivables / payables ---

  Future<List<ReceivablePayableData>> receivablesPayables(
    String orgId, {
    String? type,
  }) async {
    final raw = await _api.orgReceivablesPayables(orgId, type: type);
    return raw.map(ReceivablePayableData.fromJson).toList();
  }

  Future<void> createReceivablePayable(
    String orgId,
    Map<String, dynamic> body,
  ) async {
    await _api.orgCreateReceivablePayable(orgId, body);
  }

  Future<void> settleReceivablePayable(
    String orgId,
    String id,
    Map<String, dynamic> body,
  ) async {
    await _api.orgSettleReceivablePayable(orgId, id, body);
  }

  // --- Restricted funds ---

  Future<List<RestrictedFundData>> restrictedFunds(String orgId) async {
    final raw = await _api.orgRestrictedFunds(orgId);
    return raw.map(RestrictedFundData.fromJson).toList();
  }

  Future<void> createRestrictedFund(
    String orgId,
    Map<String, dynamic> body,
  ) async {
    await _api.orgCreateRestrictedFund(orgId, body);
  }

  Future<void> moveRestrictedFund(
    String orgId,
    String id,
    Map<String, dynamic> body,
  ) async {
    await _api.orgMoveRestrictedFund(orgId, id, body);
  }
}

final orgDataSourceProvider = Provider<OrgDataSource>((ref) {
  return OrgDataSource(ref.watch(backendApiServiceProvider));
});

/// Loads the organizations the current user belongs to.
final myOrganizationsProvider = FutureProvider<List<Organization>>((ref) async {
  return ref.watch(orgDataSourceProvider).organizations();
});

/// Whether the current user can write (input/post) in the active organization.
final orgCanWriteProvider = Provider.family<bool, String?>((ref, orgId) {
  if (orgId == null) return false;
  final orgs = ref.watch(myOrganizationsProvider).valueOrNull ?? const [];
  for (final o in orgs) {
    if (o.id == orgId) return o.canWrite;
  }
  return false;
});

/// Parameters for report providers keyed by org + year.
class OrgReportArgs {
  const OrgReportArgs(this.orgId, this.year);
  final String orgId;
  final int year;

  @override
  bool operator ==(Object other) =>
      other is OrgReportArgs && other.orgId == orgId && other.year == year;

  @override
  int get hashCode => Object.hash(orgId, year);
}

final orgDashboardProvider =
    FutureProvider.family<OrgDashboardData, OrgReportArgs>((ref, args) async {
      return ref.watch(orgDataSourceProvider).dashboard(args.orgId, year: args.year);
    });

final orgAccountsProvider =
    FutureProvider.family<List<OrgAccount>, String>((ref, orgId) async {
      return ref.watch(orgDataSourceProvider).accounts(orgId);
    });

/// Lookup map of account code -> id, so report rows (which only carry the code)
/// can drill into the ledger by id.
final orgAccountCodeToIdProvider =
    FutureProvider.family<Map<String, String>, String>((ref, orgId) async {
      final accounts = await ref.watch(orgAccountsProvider(orgId).future);
      return {for (final a in accounts) a.code: a.id};
    });

final orgBalanceSheetProvider =
    FutureProvider.family<BalanceSheetData, OrgReportArgs>((ref, args) async {
      return ref
          .watch(orgDataSourceProvider)
          .balanceSheet(args.orgId, asOf: '${args.year}-12-31');
    });

final orgActivitiesProvider =
    FutureProvider.family<ActivitiesData, OrgReportArgs>((ref, args) async {
      return ref
          .watch(orgDataSourceProvider)
          .activities(args.orgId, year: args.year);
    });

final orgTrialBalanceProvider =
    FutureProvider.family<TrialBalanceData, OrgReportArgs>((ref, args) async {
      return ref
          .watch(orgDataSourceProvider)
          .trialBalance(args.orgId, asOf: '${args.year}-12-31');
    });

final orgJournalProvider =
    FutureProvider.family<List<JournalEntryData>, String>((ref, orgId) async {
      return ref.watch(orgDataSourceProvider).journal(orgId);
    });

final orgJournalDetailProvider =
    FutureProvider.family<JournalEntryData, ({String orgId, String id})>(
      (ref, args) async {
        return ref.watch(orgDataSourceProvider).journalShow(args.orgId, args.id);
      },
    );

final orgFixedAssetsProvider =
    FutureProvider.family<List<FixedAssetData>, String>((ref, orgId) async {
      return ref.watch(orgDataSourceProvider).fixedAssets(orgId);
    });

final orgReceivablesPayablesProvider =
    FutureProvider.family<List<ReceivablePayableData>, ({String orgId, String type})>(
      (ref, args) async {
        return ref
            .watch(orgDataSourceProvider)
            .receivablesPayables(args.orgId, type: args.type);
      },
    );

final orgRestrictedFundsProvider =
    FutureProvider.family<List<RestrictedFundData>, String>((ref, orgId) async {
      return ref.watch(orgDataSourceProvider).restrictedFunds(orgId);
    });

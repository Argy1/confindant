import 'package:confindant/core/network/api_exception.dart';
import 'package:confindant/core/network/app_api_client.dart';

class BackendApiService {
  BackendApiService(this._client);

  final AppApiClient _client;

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final json = await _client.post(
      '/v1/register',
      body: {'username': username, 'email': email, 'password': password},
    );
    return _requireData(json);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final json = await _client.post(
      '/v1/login',
      body: {'email': email, 'password': password},
    );
    return _requireData(json);
  }

  Future<Map<String, dynamic>> me() async =>
      _requireData(await _client.get('/v1/user'));

  Future<void> logout() async {
    await _client.post('/v1/logout');
  }

  Future<List<Map<String, dynamic>>> wallets() async =>
      _asList(await _client.get('/v1/wallets'));

  Future<Map<String, dynamic>> createWallet(Map<String, dynamic> body) async {
    return _requireData(await _client.post('/v1/wallets', body: body));
  }

  Future<Map<String, dynamic>> updateWallet(
    String id,
    Map<String, dynamic> body,
  ) async {
    return _requireData(await _client.patch('/v1/wallets/$id', body: body));
  }

  Future<void> deleteWallet(String id) async {
    await _client.delete('/v1/wallets/$id');
  }

  Future<Map<String, dynamic>> transferWalletBalance({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    String? notes,
    DateTime? date,
  }) async {
    return _requireData(
      await _client.post(
        '/v1/wallets/transfer',
        body: {
          'from_wallet_id': fromWalletId,
          'to_wallet_id': toWalletId,
          'amount': amount,
          'notes': notes,
          'date': (date ?? DateTime.now()).toIso8601String(),
        },
      ),
    );
  }

  Future<Map<String, dynamic>> recalculateWalletBalances() async {
    return _requireData(await _client.post('/v1/wallets/recalculate-balances'));
  }

  Future<List<Map<String, dynamic>>> budgets() async =>
      _asList(await _client.get('/v1/budgets'));

  Future<Map<String, dynamic>> createBudget(Map<String, dynamic> body) async {
    return _requireData(await _client.post('/v1/budgets', body: body));
  }

  Future<Map<String, dynamic>> updateBudget(
    String id,
    Map<String, dynamic> body,
  ) async {
    return _requireData(await _client.patch('/v1/budgets/$id', body: body));
  }

  Future<void> deleteBudget(String id) async {
    await _client.delete('/v1/budgets/$id');
  }

  Future<List<Map<String, dynamic>>> transactions() async =>
      _asList(await _client.get('/v1/transactions'));

  Future<List<Map<String, dynamic>>> pagedTransactions({
    int page = 1,
    int perPage = 20,
    String type = 'all',
    String? walletId,
    String? fromDate,
    String? toDate,
    String? tag,
    String? queryText,
  }) async {
    final query = <String, dynamic>{'page': page, 'per_page': perPage, 'type': type};
    if (walletId != null && walletId.isNotEmpty) {
      query['wallet_id'] = walletId;
    }
    if (fromDate != null && fromDate.isNotEmpty) {
      query['from_date'] = fromDate;
    }
    if (toDate != null && toDate.isNotEmpty) {
      query['to_date'] = toDate;
    }
    if (tag != null && tag.isNotEmpty) {
      query['tag'] = tag;
    }
    if (queryText != null && queryText.isNotEmpty) {
      query['q'] = queryText;
    }
    return _asList(
      await _client.get(
        '/v1/transactions',
        query: query,
      ),
    );
  }

  Future<Map<String, dynamic>> createTransaction(
    Map<String, dynamic> body,
  ) async {
    return _requireData(await _client.post('/v1/transactions', body: body));
  }

  Future<Map<String, dynamic>> aiSuggestTransactionCategory(
    Map<String, dynamic> body,
  ) async {
    return _requireData(
      await _client.post('/v1/ai/transactions/categorize', body: body),
    );
  }

  Future<Map<String, dynamic>> aiParseTransactionInput({
    required String transcript,
    String locale = 'id',
  }) async {
    return _requireData(
      await _client.post('/v1/ai/transactions/parse-input', body: {
        'transcript': transcript,
        'locale': locale,
      }),
    );
  }

  Future<Map<String, dynamic>> aiSubmitTransactionCategoryFeedback(
    Map<String, dynamic> body,
  ) async {
    return _requireData(
      await _client.post('/v1/ai/transactions/feedback', body: body),
    );
  }

  Future<Map<String, dynamic>> aiCashflowForecast({
    int days = 30,
    String? walletId,
  }) async {
    final query = <String, dynamic>{'days': days};
    if (walletId != null && walletId.isNotEmpty) {
      query['wallet_id'] = walletId;
    }
    return _requireData(await _client.get('/v1/ai/cashflow-forecast', query: query));
  }

  Future<List<Map<String, dynamic>>> aiBudgetRecommendations({
    String? fromDate,
    String? toDate,
    String? walletId,
  }) async {
    final query = <String, dynamic>{};
    if (fromDate != null && fromDate.isNotEmpty) {
      query['from_date'] = fromDate;
    }
    if (toDate != null && toDate.isNotEmpty) {
      query['to_date'] = toDate;
    }
    if (walletId != null && walletId.isNotEmpty) {
      query['wallet_id'] = walletId;
    }
    return _asList(await _client.get('/v1/ai/budget-recommendations', query: query));
  }

  Future<Map<String, dynamic>> aiBudgetSimulation({
    required String category,
    required double changePercent,
    String? fromDate,
    String? toDate,
    String? walletId,
  }) async {
    final query = <String, dynamic>{
      'category': category,
      'change_percent': changePercent,
    };
    if (fromDate != null && fromDate.isNotEmpty) {
      query['from_date'] = fromDate;
    }
    if (toDate != null && toDate.isNotEmpty) {
      query['to_date'] = toDate;
    }
    if (walletId != null && walletId.isNotEmpty) {
      query['wallet_id'] = walletId;
    }
    return _requireData(await _client.get('/v1/ai/budget-simulation', query: query));
  }

  Future<Map<String, dynamic>> aiOcrMetrics({int days = 30}) async {
    return _requireData(
      await _client.get('/v1/ai/ocr-metrics', query: {'days': days}),
    );
  }

  Future<Map<String, dynamic>> aiFinanceQuery({
    required String query,
    String locale = 'id',
  }) async {
    return _requireData(
      await _client.post('/v1/ai/finance-query', body: {
        'query': query,
        'locale': locale,
      }),
    );
  }

  Future<List<Map<String, dynamic>>> aiFinanceQueryHistory({int limit = 20}) async {
    return _asList(
      await _client.get('/v1/ai/finance-query/history', query: {'limit': limit}),
    );
  }

  Future<void> clearAiFinanceQueryHistory() async {
    await _client.delete('/v1/ai/finance-query/history');
  }

  Future<Map<String, dynamic>> renameAiFinanceQueryHistoryItem({
    required String id,
    required String query,
  }) async {
    return _requireData(
      await _client.patch('/v1/ai/finance-query/history/$id', body: {'query': query}),
    );
  }

  Future<void> deleteAiFinanceQueryHistoryItem(String id) async {
    await _client.delete('/v1/ai/finance-query/history/$id');
  }

  Future<Map<String, dynamic>> updateTransaction(
    String id,
    Map<String, dynamic> body,
  ) async {
    return _requireData(
      await _client.patch('/v1/transactions/$id', body: body),
    );
  }

  Future<void> deleteTransaction(String id) async {
    await _client.delete('/v1/transactions/$id');
  }

  Future<List<Map<String, dynamic>>> recurringTransactions() async =>
      _asList(await _client.get('/v1/recurring-transactions'));

  Future<Map<String, dynamic>> createRecurringTransaction(
    Map<String, dynamic> body,
  ) async {
    return _requireData(
      await _client.post('/v1/recurring-transactions', body: body),
    );
  }

  Future<Map<String, dynamic>> updateRecurringTransaction(
    String id,
    Map<String, dynamic> body,
  ) async {
    return _requireData(
      await _client.patch('/v1/recurring-transactions/$id', body: body),
    );
  }

  Future<void> deleteRecurringTransaction(String id) async {
    await _client.delete('/v1/recurring-transactions/$id');
  }

  Future<Map<String, dynamic>> uploadReceipt({
    required Map<String, dynamic> fields,
    String? filePath,
  }) async {
    return _requireData(
      await _client.postMultipart(
        '/v1/transactions/scan-upload',
        fields: fields,
        fileField: 'receipt_image',
        filePath: filePath,
      ),
    );
  }

  Future<Map<String, dynamic>> dashboard() async =>
      _requireData(await _client.get('/v1/dashboard'));

  Future<Map<String, dynamic>> analytics({
    required String period,
    String? fromDate,
    String? toDate,
    String? walletId,
    String? category,
  }) async {
    final query = <String, dynamic>{'period': period};
    if (fromDate != null && fromDate.isNotEmpty) {
      query['from_date'] = fromDate;
    }
    if (toDate != null && toDate.isNotEmpty) {
      query['to_date'] = toDate;
    }
    if (walletId != null && walletId.isNotEmpty) {
      query['wallet_id'] = walletId;
    }
    if (category != null && category.isNotEmpty) {
      query['category'] = category;
    }

    return _requireData(
      await _client.get('/v1/analytics', query: query),
    );
  }

  Future<List<Map<String, dynamic>>> goals() async =>
      _asList(await _client.get('/v1/goals'));

  Future<Map<String, dynamic>> createGoal(Map<String, dynamic> body) async {
    return _requireData(await _client.post('/v1/goals', body: body));
  }

  Future<Map<String, dynamic>> updateGoal(
    String id,
    Map<String, dynamic> body,
  ) async {
    return _requireData(await _client.patch('/v1/goals/$id', body: body));
  }

  Future<void> deleteGoal(String id) async {
    await _client.delete('/v1/goals/$id');
  }

  Future<Map<String, dynamic>> addGoalContribution(
    String id,
    Map<String, dynamic> body,
  ) async {
    return _requireData(
      await _client.post('/v1/goals/$id/contributions', body: body),
    );
  }

  Future<Map<String, dynamic>> habitsBundle() async {
    final json = await _client.get('/v1/habits');
    final success = json['success'] == true;
    if (!success) {
      throw ApiException(json['message']?.toString() ?? 'Request failed');
    }
    final data = json['data'];
    final meta = json['meta'];
    return {
      'habits': data is List
          ? data
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
          : const <Map<String, dynamic>>[],
      'meta': meta is Map<String, dynamic>
          ? meta
          : (meta is Map ? Map<String, dynamic>.from(meta) : const <String, dynamic>{}),
    };
  }

  Future<List<Map<String, dynamic>>> habits() async {
    final bundle = await habitsBundle();
    return (bundle['habits'] as List<Map<String, dynamic>>? ?? const []);
  }

  Future<Map<String, dynamic>> incrementHabit(String id) async {
    return _requireData(await _client.post('/v1/habits/$id/increment'));
  }

  Future<Map<String, dynamic>> resetHabit(String id) async {
    return _requireData(await _client.post('/v1/habits/$id/reset'));
  }

  Future<Map<String, dynamic>> updateHabit(
    String id,
    Map<String, dynamic> body,
  ) async {
    return _requireData(await _client.patch('/v1/habits/$id', body: body));
  }

  Future<Map<String, dynamic>> profile() async =>
      _requireData(await _client.get('/v1/profile'));

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body) async {
    return _requireData(await _client.patch('/v1/profile', body: body));
  }

  Future<Map<String, dynamic>> uploadProfileAvatar({
    required String filePath,
  }) async {
    return _requireData(
      await _client.postMultipart(
        '/v1/profile/avatar',
        fields: const {},
        fileField: 'avatar',
        filePath: filePath,
      ),
    );
  }

  Future<Map<String, dynamic>> submitScanOcr({
    required String filePath,
  }) async {
    return _requireData(
      await _client.postMultipart(
        '/v1/transactions/scan-ocr',
        fields: const {},
        fileField: 'receipt_image',
        filePath: filePath,
      ),
    );
  }

  Future<Map<String, dynamic>> getScanOcr(String jobId) async =>
      _requireData(await _client.get('/v1/transactions/scan-ocr/$jobId'));

  Future<Map<String, dynamic>> commitScanOcr(
    String jobId,
    Map<String, dynamic> body,
  ) async {
    return _requireData(
      await _client.post('/v1/transactions/scan-ocr/$jobId/commit', body: body),
    );
  }

  Future<Map<String, dynamic>> submitScanOcrFeedback(
    String jobId,
    Map<String, dynamic> body,
  ) async {
    return _requireData(
      await _client.post('/v1/transactions/scan-ocr/$jobId/feedback', body: body),
    );
  }

  Future<Map<String, dynamic>> updateNotificationSettings(
    Map<String, dynamic> body,
  ) async {
    return _requireData(
      await _client.patch('/v1/profile/notification-settings', body: body),
    );
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    return _requireData(
      await _client.patch(
        '/v1/profile/change-password',
        body: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPasswordConfirmation,
        },
      ),
    );
  }

  Future<Map<String, dynamic>> privacyPolicy() async =>
      _requireData(await _client.get('/v1/legal/privacy'));

  Future<Map<String, dynamic>> termsOfService() async =>
      _requireData(await _client.get('/v1/legal/terms'));

  Future<Map<String, dynamic>> supportChannels() async =>
      _requireData(await _client.get('/v1/support/channels'));

  Future<List<Map<String, dynamic>>> notifications({
    int page = 1,
    int perPage = 20,
  }) async {
    return _asList(
      await _client.get(
        '/v1/notifications',
        query: {'page': page, 'per_page': perPage},
      ),
    );
  }

  Future<Map<String, dynamic>> markNotificationRead(String id) async {
    return _requireData(await _client.post('/v1/notifications/$id/mark-read'));
  }

  // ===================== ORGANIZATION ACCOUNTING =====================
  // All accounting endpoints accept an organization_id so the backend resolves
  // the active organization. Reports also carry a `meta` block, so these helpers
  // return the whole envelope where needed.

  Future<List<Map<String, dynamic>>> myOrganizations() async =>
      _asList(await _client.get('/v1/me/organizations'));

  Future<Map<String, dynamic>> orgDashboard(String orgId, {int? year}) async {
    return _requireData(
      await _client.get(
        '/v1/accounting/dashboard',
        query: {'organization_id': orgId, if (year != null) 'year': year},
      ),
    );
  }

  Future<List<Map<String, dynamic>>> orgAccounts(String orgId) async {
    return _asList(
      await _client.get(
        '/v1/accounting/accounts',
        query: {'organization_id': orgId},
      ),
    );
  }

  Future<Map<String, dynamic>> orgBalanceSheet(
    String orgId, {
    String? asOf,
  }) async {
    return _requireData(
      await _client.get(
        '/v1/accounting/reports/balance-sheet',
        query: {'organization_id': orgId, if (asOf != null) 'as_of': asOf},
      ),
    );
  }

  Future<Map<String, dynamic>> orgActivities(
    String orgId, {
    int? year,
    String? fromDate,
    String? toDate,
  }) async {
    return _requireData(
      await _client.get(
        '/v1/accounting/reports/activities',
        query: {
          'organization_id': orgId,
          if (year != null) 'year': year,
          if (fromDate != null) 'from_date': fromDate,
          if (toDate != null) 'to_date': toDate,
        },
      ),
    );
  }

  Future<Map<String, dynamic>> orgTrialBalance(
    String orgId, {
    String? asOf,
  }) async {
    return _requireData(
      await _client.get(
        '/v1/accounting/reports/trial-balance',
        query: {'organization_id': orgId, if (asOf != null) 'as_of': asOf},
      ),
    );
  }

  Future<Map<String, dynamic>> orgGeneralLedger(
    String orgId,
    String accountId, {
    String? fromDate,
    String? toDate,
  }) async {
    return _requireData(
      await _client.get(
        '/v1/accounting/reports/ledger/$accountId',
        query: {
          'organization_id': orgId,
          if (fromDate != null) 'from_date': fromDate,
          if (toDate != null) 'to_date': toDate,
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> orgJournal(
    String orgId, {
    int page = 1,
    int perPage = 50,
    String? status,
    String? fromDate,
    String? toDate,
  }) async {
    return _asList(
      await _client.get(
        '/v1/accounting/journal',
        query: {
          'organization_id': orgId,
          'page': page,
          'per_page': perPage,
          if (status != null) 'status': status,
          if (fromDate != null) 'from_date': fromDate,
          if (toDate != null) 'to_date': toDate,
        },
      ),
    );
  }

  Future<Map<String, dynamic>> orgJournalShow(String orgId, String id) async {
    return _requireData(
      await _client.get(
        '/v1/accounting/journal/$id',
        query: {'organization_id': orgId},
      ),
    );
  }

  Future<Map<String, dynamic>> orgJournalCreate(
    String orgId,
    Map<String, dynamic> body,
  ) async {
    return _requireData(
      await _client.post(
        '/v1/accounting/journal',
        body: {'organization_id': orgId, ...body},
      ),
    );
  }

  Future<Map<String, dynamic>> orgJournalVoid(String orgId, String id) async {
    return _requireData(
      await _client.post(
        '/v1/accounting/journal/$id/void',
        body: {'organization_id': orgId},
      ),
    );
  }

  // --- Fixed assets ---

  Future<List<Map<String, dynamic>>> orgFixedAssets(String orgId) async {
    return _asList(
      await _client.get(
        '/v1/accounting/fixed-assets',
        query: {'organization_id': orgId},
      ),
    );
  }

  Future<Map<String, dynamic>> orgCreateFixedAsset(
    String orgId,
    Map<String, dynamic> body,
  ) async {
    return _requireData(
      await _client.post(
        '/v1/accounting/fixed-assets',
        body: {'organization_id': orgId, ...body},
      ),
    );
  }

  Future<Map<String, dynamic>> orgRunDepreciation(
    String orgId,
    int year,
  ) async {
    return _requireData(
      await _client.post(
        '/v1/accounting/fixed-assets/run-depreciation',
        body: {'organization_id': orgId, 'year': year},
      ),
    );
  }

  // --- Receivables / payables ---

  Future<List<Map<String, dynamic>>> orgReceivablesPayables(
    String orgId, {
    String? type,
    String? status,
  }) async {
    return _asList(
      await _client.get(
        '/v1/accounting/receivables-payables',
        query: {
          'organization_id': orgId,
          if (type != null) 'type': type,
          if (status != null) 'status': status,
        },
      ),
    );
  }

  Future<Map<String, dynamic>> orgCreateReceivablePayable(
    String orgId,
    Map<String, dynamic> body,
  ) async {
    return _requireData(
      await _client.post(
        '/v1/accounting/receivables-payables',
        body: {'organization_id': orgId, ...body},
      ),
    );
  }

  Future<Map<String, dynamic>> orgSettleReceivablePayable(
    String orgId,
    String id,
    Map<String, dynamic> body,
  ) async {
    return _requireData(
      await _client.post(
        '/v1/accounting/receivables-payables/$id/settle',
        body: {'organization_id': orgId, ...body},
      ),
    );
  }

  // --- Restricted funds ---

  Future<List<Map<String, dynamic>>> orgRestrictedFunds(String orgId) async {
    return _asList(
      await _client.get(
        '/v1/accounting/restricted-funds',
        query: {'organization_id': orgId},
      ),
    );
  }

  Future<Map<String, dynamic>> orgCreateRestrictedFund(
    String orgId,
    Map<String, dynamic> body,
  ) async {
    return _requireData(
      await _client.post(
        '/v1/accounting/restricted-funds',
        body: {'organization_id': orgId, ...body},
      ),
    );
  }

  Future<Map<String, dynamic>> orgMoveRestrictedFund(
    String orgId,
    String id,
    Map<String, dynamic> body,
  ) async {
    return _requireData(
      await _client.post(
        '/v1/accounting/restricted-funds/$id/move',
        body: {'organization_id': orgId, ...body},
      ),
    );
  }

  // ---- Org Members ----

  Future<List<Map<String, dynamic>>> orgMemberList(String orgId) async {
    return _asList(
      await _client.get(
        '/v1/accounting/members',
        query: {'organization_id': orgId},
      ),
    );
  }

  Future<Map<String, dynamic>> orgMemberUpdateRole(
    String orgId,
    String userId,
    String role,
  ) async {
    return _requireData(
      await _client.patch(
        '/v1/accounting/members/$userId',
        body: {'organization_id': orgId, 'role': role},
      ),
    );
  }

  Future<void> orgMemberRemove(String orgId, String userId) async {
    await _client.delete(
      '/v1/accounting/members/$userId?organization_id=$orgId',
    );
  }

  Future<List<Map<String, dynamic>>> orgInvitationList(String orgId) async {
    return _asList(
      await _client.get(
        '/v1/accounting/members/invitations',
        query: {'organization_id': orgId},
      ),
    );
  }

  Future<Map<String, dynamic>> orgInviteCreate(
    String orgId,
    String email,
    String role,
  ) async {
    return _requireData(
      await _client.post(
        '/v1/accounting/members/invite',
        body: {'organization_id': orgId, 'email': email, 'role': role},
      ),
    );
  }

  Future<void> orgInviteCancel(String orgId, String token) async {
    await _client.delete(
      '/v1/accounting/members/invitations/$token?organization_id=$orgId',
    );
  }

  Future<Map<String, dynamic>> orgInviteInfo(String token) async {
    return _requireData(
      await _client.get('/v1/org-invite/$token'),
    );
  }

  Future<Map<String, dynamic>> orgInviteAccept(String token) async {
    return _requireData(
      await _client.post('/v1/org-invite/$token/accept'),
    );
  }

  // ---- Org Budget ----

  Future<List<Map<String, dynamic>>> orgBudgetList(
    String orgId, {
    int? fiscalYear,
  }) async {
    return _asList(
      await _client.get(
        '/v1/accounting/budget',
        query: {
          'organization_id': orgId,
          ...?fiscalYear != null ? {'fiscal_year': fiscalYear} : null,
        },
      ),
    );
  }

  Future<Map<String, dynamic>> orgBudgetCreate(
    String orgId,
    Map<String, dynamic> body,
  ) async {
    return _requireData(
      await _client.post(
        '/v1/accounting/budget',
        body: {'organization_id': orgId, ...body},
      ),
    );
  }

  Future<Map<String, dynamic>> orgBudgetUpdate(
    String orgId,
    String id,
    Map<String, dynamic> body,
  ) async {
    return _requireData(
      await _client.patch(
        '/v1/accounting/budget/$id',
        body: {'organization_id': orgId, ...body},
      ),
    );
  }

  Future<void> orgBudgetDelete(String orgId, String id) async {
    await _client.delete('/v1/accounting/budget/$id?organization_id=$orgId');
  }

  Future<Map<String, dynamic>> orgBudgetCompare(
    String orgId, {
    int? fiscalYear,
  }) async {
    return _requireData(
      await _client.get(
        '/v1/accounting/budget/compare',
        query: {
          'organization_id': orgId,
          ...?fiscalYear != null ? {'fiscal_year': fiscalYear} : null,
        },
      ),
    );
  }

  // ---- Org PDF Export ----

  Future<List<int>> orgDownloadReportPdf(
    String orgId,
    String type, {
    Map<String, dynamic>? params,
  }) async {
    return _client.getBytes(
      '/v1/accounting/reports/$type/pdf',
      query: {'organization_id': orgId, ...?params},
    );
  }

  // ---- Org Recurring Entries ----

  Future<List<Map<String, dynamic>>> orgRecurringList(String orgId) async {
    return _asList(
      await _client.get(
        '/v1/accounting/recurring',
        query: {'organization_id': orgId},
      ),
    );
  }

  Future<Map<String, dynamic>> orgRecurringCreate(
    String orgId,
    Map<String, dynamic> body,
  ) async {
    return _requireData(
      await _client.post(
        '/v1/accounting/recurring',
        body: {'organization_id': orgId, ...body},
      ),
    );
  }

  Future<Map<String, dynamic>> orgRecurringUpdate(
    String orgId,
    String id,
    Map<String, dynamic> body,
  ) async {
    return _requireData(
      await _client.patch(
        '/v1/accounting/recurring/$id',
        body: {'organization_id': orgId, ...body},
      ),
    );
  }

  Future<void> orgRecurringDelete(String orgId, String id) async {
    await _client.delete('/v1/accounting/recurring/$id?organization_id=$orgId');
  }

  Future<Map<String, dynamic>> orgRecurringRun(String orgId, String id) async {
    return _requireData(
      await _client.post(
        '/v1/accounting/recurring/$id/run',
        body: {'organization_id': orgId},
      ),
    );
  }

  // ---- Rekening Harian ----

  Future<Map<String, dynamic>> orgRekeningHarianList(
    String orgId, {
    String? fromDate,
    String? toDate,
    int perPage = 200,
    int page = 1,
  }) async {
    final json = await _client.get(
      '/v1/accounting/rekening-harian',
      query: {
        'organization_id': orgId,
        'per_page': perPage,
        'page': page,
        ...?fromDate != null ? {'from_date': fromDate} : null,
        ...?toDate != null ? {'to_date': toDate} : null,
      },
    );
    if (json['success'] != true) {
      throw ApiException(json['message']?.toString() ?? 'Request failed');
    }
    final rawData = json['data'];
    final rows = rawData is List
        ? rawData.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];
    final meta = json['meta'] is Map
        ? Map<String, dynamic>.from(json['meta'] as Map)
        : <String, dynamic>{};
    return {'rows': rows, 'meta': meta};
  }

  Future<Map<String, dynamic>> orgRekeningHarianCreate(
    String orgId, {
    required String date,
    required String uraian,
    double? pemasukan,
    double? pengeluaran,
    String? kategori,
    String? keterangan,
    String? klasifikasi,
  }) async {
    return _requireData(
      await _client.post(
        '/v1/accounting/rekening-harian',
        body: {
          'organization_id': orgId,
          'date': date,
          'uraian': uraian,
          ...?pemasukan != null ? {'pemasukan': pemasukan} : null,
          ...?pengeluaran != null ? {'pengeluaran': pengeluaran} : null,
          ...?kategori != null ? {'kategori': kategori} : null,
          ...?keterangan != null ? {'keterangan': keterangan} : null,
          ...?klasifikasi != null ? {'klasifikasi': klasifikasi} : null,
        },
      ),
    );
  }

  Future<void> orgRekeningHarianDelete(String orgId, int id) async {
    await _client.delete('/v1/accounting/rekening-harian/$id?organization_id=$orgId');
  }

  Future<Map<String, dynamic>> orgRekeningHarianCategories(
    String orgId,
  ) async {
    return _requireData(
      await _client.get(
        '/v1/accounting/rekening-harian/categories',
        query: {'organization_id': orgId},
      ),
    );
  }

  // ---- Org AI Chat ----

  Future<Map<String, dynamic>> orgAiFinanceQuery(
    String orgId, {
    required String query,
    String locale = 'id',
  }) async {
    return _requireData(
      await _client.post(
        '/v1/accounting/ai/finance-query',
        body: {'organization_id': orgId, 'query': query, 'locale': locale},
      ),
    );
  }

  Future<List<Map<String, dynamic>>> orgAiFinanceQueryHistory(
    String orgId, {
    int limit = 20,
  }) async {
    return _asList(
      await _client.get(
        '/v1/accounting/ai/finance-query/history',
        query: {'organization_id': orgId, 'limit': limit},
      ),
    );
  }

  Future<void> orgClearAiFinanceQueryHistory(String orgId) async {
    await _client.delete(
      '/v1/accounting/ai/finance-query/history?organization_id=$orgId',
    );
  }

  // ---- Org Scan Struk ----

  Future<Map<String, dynamic>> orgSubmitScanOcr(
    String orgId, {
    required String filePath,
  }) async {
    return _requireData(
      await _client.postMultipart(
        '/v1/transactions/scan-ocr',
        fields: {'organization_id': orgId},
        fileField: 'receipt_image',
        filePath: filePath,
      ),
    );
  }

  Future<Map<String, dynamic>> orgGetScanOcr(String jobId) async {
    return _requireData(
      await _client.get('/v1/transactions/scan-ocr/$jobId'),
    );
  }

  Future<Map<String, dynamic>> orgCommitScanOcrToJournal(
    String orgId,
    String jobId,
    Map<String, dynamic> body,
  ) async {
    return _requireData(
      await _client.post(
        '/v1/accounting/scan-ocr/$jobId/commit',
        body: {'organization_id': orgId, ...body},
      ),
    );
  }

  Map<String, dynamic> _requireData(Map<String, dynamic> json) {
    final success = json['success'] == true;
    if (!success) {
      throw ApiException(json['message']?.toString() ?? 'Request failed');
    }
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    if (data == null) return <String, dynamic>{};
    throw ApiException('Unexpected data shape');
  }

  List<Map<String, dynamic>> _asList(Map<String, dynamic> json) {
    final success = json['success'] == true;
    if (!success) {
      throw ApiException(json['message']?.toString() ?? 'Request failed');
    }
    final data = json['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }
}

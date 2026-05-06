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

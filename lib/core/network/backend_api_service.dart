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

  Future<Map<String, dynamic>> createTransaction(
    Map<String, dynamic> body,
  ) async {
    return _requireData(await _client.post('/v1/transactions', body: body));
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

  Future<Map<String, dynamic>> analytics({required String period}) async {
    return _requireData(
      await _client.get('/v1/analytics', query: {'period': period}),
    );
  }

  Future<List<Map<String, dynamic>>> goals() async =>
      _asList(await _client.get('/v1/goals'));

  Future<Map<String, dynamic>> createGoal(Map<String, dynamic> body) async {
    return _requireData(await _client.post('/v1/goals', body: body));
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

  Future<List<Map<String, dynamic>>> habits() async =>
      _asList(await _client.get('/v1/habits'));

  Future<Map<String, dynamic>> incrementHabit(String id) async {
    return _requireData(await _client.post('/v1/habits/$id/increment'));
  }

  Future<Map<String, dynamic>> resetHabit(String id) async {
    return _requireData(await _client.post('/v1/habits/$id/reset'));
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

  Future<Map<String, dynamic>> updateNotificationSettings(
    Map<String, dynamic> body,
  ) async {
    return _requireData(
      await _client.patch('/v1/profile/notification-settings', body: body),
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

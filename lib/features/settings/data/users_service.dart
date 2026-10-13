import '../../../core/network/api_client.dart';

class UsersService {
  UsersService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Map<String, dynamic>>> fetch() async {
    final payload = await _apiClient.get('/users?per_page=100');
    final data = payload['data'];
    final rawItems = data is List
        ? data
        : data is Map && data['data'] is List
        ? data['data'] as List
        : const [];
    return rawItems
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final payload = await _apiClient.post('/users', body: body);
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : body;
  }

  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> body,
  ) async {
    final payload = await _apiClient.put('/users/$id', body: body);
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : body;
  }

  Future<void> delete(String id) async {
    await _apiClient.delete('/users/$id');
  }

  Future<Map<String, dynamic>> resetPassword(
    String id, {
    String? password,
    String? passwordConfirmation,
  }) async {
    final payload = await _apiClient.post(
      '/users/$id/reset-password',
      body: {
        if (password != null && password.trim().isNotEmpty)
          'password': password.trim(),
        if (passwordConfirmation != null &&
            passwordConfirmation.trim().isNotEmpty)
          'password_confirmation': passwordConfirmation.trim(),
      },
    );
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> fetchReference(String endpoint) async {
    final payload = await _apiClient.get(endpoint);
    final data = payload['data'];
    final rawItems = data is List
        ? data
        : data is Map && data['data'] is List
        ? data['data'] as List
        : const [];
    return rawItems
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> createInvitation({
    String? email,
    required String roleName,
  }) async {
    final payload = await _apiClient.post(
      '/invitations',
      body: {
        'purpose': 'user_registration',
        'role_name': roleName,
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      },
    );
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }
}

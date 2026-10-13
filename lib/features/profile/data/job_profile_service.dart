import '../../../core/network/api_client.dart';

class JobProfileService {
  JobProfileService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Map<String, dynamic>?> fetch(String userId) async {
    final payload = await _apiClient.get('/users/$userId/job-profile');
    return _data(payload);
  }

  Future<Map<String, dynamic>> create(
    String userId,
    Map<String, dynamic> body,
  ) async {
    final payload = await _apiClient.post(
      '/users/$userId/job-profile',
      body: body,
    );
    return _data(payload) ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> update(
    String userId,
    Map<String, dynamic> body,
  ) async {
    final payload = await _apiClient.put(
      '/users/$userId/job-profile',
      body: body,
    );
    return _data(payload) ?? <String, dynamic>{};
  }

  Map<String, dynamic>? _data(Map<String, dynamic> payload) {
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : null;
  }
}

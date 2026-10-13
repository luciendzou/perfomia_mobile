import '../../../core/network/api_client.dart';

class CompanyProfileService {
  CompanyProfileService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> fetch(String id) async {
    final payload = await _apiClient.get('/companies/$id');
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> body,
  ) async {
    final payload = await _apiClient.put('/companies/$id', body: body);
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : body;
  }
}

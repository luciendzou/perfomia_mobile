import '../../../core/network/api_client.dart';

class CompanySettingsService {
  CompanySettingsService({ApiClient? apiClient, String? accessToken})
    : _apiClient = apiClient ?? ApiClient(accessToken: accessToken);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> fetch() async {
    final payload = await _apiClient.get('/settings/company');
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> update(Map<String, dynamic> body) async {
    final payload = await _apiClient.put('/settings/company', body: body);
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : body;
  }
}

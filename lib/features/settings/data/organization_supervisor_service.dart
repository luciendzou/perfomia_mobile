import '../../../core/network/api_client.dart';

class OrganizationSupervisorService {
  OrganizationSupervisorService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();
  final ApiClient _apiClient;

  Future<OrganizationSupervisorPage> fetch({
    String? search,
    String? scope,
    int page = 1,
  }) async {
    final params = <String, String>{'page': '$page', 'per_page': '15'};
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    if (scope != null && scope.isNotEmpty) params['scope'] = scope;
    final query = params.entries
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');
    final payload = await _apiClient.get('/organization-supervisors?$query');
    final data = payload['data'];
    final pageData = data is Map ? data : const <String, dynamic>{};
    final rawItems = pageData['data'] is List
        ? pageData['data'] as List
        : data is List
        ? data
        : const [];
    return OrganizationSupervisorPage(
      items: rawItems
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      currentPage: int.tryParse('${pageData['current_page'] ?? page}') ?? page,
      lastPage: int.tryParse('${pageData['last_page'] ?? page}') ?? page,
      total:
          int.tryParse('${pageData['total'] ?? rawItems.length}') ??
          rawItems.length,
    );
  }

  Future<void> create(Map<String, dynamic> body) async =>
      _apiClient.post('/organization-supervisors', body: body);

  Future<void> update(String id, Map<String, dynamic> body) async =>
      _apiClient.patch('/organization-supervisors/$id', body: body);

  Future<void> delete(String id) async =>
      _apiClient.delete('/organization-supervisors/$id');
}

class OrganizationSupervisorPage {
  const OrganizationSupervisorPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
  final List<Map<String, dynamic>> items;
  final int currentPage;
  final int lastPage;
  final int total;
}

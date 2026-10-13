import '../../../core/network/api_client.dart';

class EvaluationCriterionService {
  EvaluationCriterionService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<EvaluationCriterionPage> fetch({
    String? search,
    String? status,
    int page = 1,
  }) async {
    final params = <String, String>{'page': '$page', 'per_page': '20'};
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    if (status == 'active') params['is_active'] = '1';
    if (status == 'inactive') params['is_active'] = '0';
    final query = params.entries
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');
    final payload = await _apiClient.get('/evaluation-manager-criteria?$query');
    final data = payload['data'];
    final pageData = data is Map ? data : const <String, dynamic>{};
    final rawItems = pageData['data'] is List
        ? pageData['data'] as List
        : data is List
        ? data
        : const [];
    return EvaluationCriterionPage(
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

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final payload = await _apiClient.post(
      '/evaluation-manager-criteria',
      body: body,
    );
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : body;
  }

  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> body,
  ) async {
    final payload = await _apiClient.put(
      '/evaluation-manager-criteria/$id',
      body: body,
    );
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : body;
  }

  Future<void> delete(String id) async {
    await _apiClient.delete('/evaluation-manager-criteria/$id');
  }
}

class EvaluationCriterionPage {
  const EvaluationCriterionPage({
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

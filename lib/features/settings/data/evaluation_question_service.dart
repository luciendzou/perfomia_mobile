import '../../../core/network/api_client.dart';

class EvaluationQuestionService {
  EvaluationQuestionService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<EvaluationQuestionPage> fetch({
    String? search,
    String? language,
    int page = 1,
  }) async {
    final params = <String, String>{'page': '$page', 'per_page': '20'};
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    if (language != null && language.isNotEmpty) {
      params['language'] = language;
    }
    final query = params.entries
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');
    final payload = await _apiClient.get('/evaluation-questions?$query');
    final data = payload['data'];
    final pageData = data is Map ? data : const <String, dynamic>{};
    final rawItems = pageData['data'] is List
        ? pageData['data'] as List
        : data is List
        ? data
        : const [];
    final items = rawItems
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    return EvaluationQuestionPage(
      items: items,
      currentPage: int.tryParse('${pageData['current_page'] ?? page}') ?? page,
      lastPage: int.tryParse('${pageData['last_page'] ?? page}') ?? page,
      total:
          int.tryParse('${pageData['total'] ?? items.length}') ?? items.length,
    );
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final payload = await _apiClient.post('/evaluation-questions', body: body);
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : body;
  }

  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> body,
  ) async {
    final payload = await _apiClient.put(
      '/evaluation-questions/$id',
      body: body,
    );
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : body;
  }

  Future<void> delete(String id) async {
    await _apiClient.delete('/evaluation-questions/$id');
  }
}

class EvaluationQuestionPage {
  const EvaluationQuestionPage({
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

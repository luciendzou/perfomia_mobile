import '../../../core/network/api_client.dart';

class EvaluationService {
  EvaluationService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();
  final ApiClient _apiClient;

  Future<Map<String, dynamic>> show(String id) async {
    final payload = await _apiClient.get('/evaluations/$id');
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> start({
    required String userId,
    required int year,
  }) async {
    final payload = await _apiClient.post(
      '/evaluations/start',
      body: {'user_id': userId, 'year': year},
    );
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<Map<String, dynamic>?> myEvaluation({required int year}) async {
    final payload = await _apiClient.get('/evaluations/me?year=$year');
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : null;
  }

  Future<Map<String, dynamic>> exists({required int year}) async {
    final payload = await _apiClient.get('/evaluations/exists?year=$year');
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> regenerateQuestions(String id) async {
    final payload = await _apiClient.post(
      '/evaluations/$id/regenerate-questions',
    );
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> fetchManagerFeedbacks(String id) async {
    final payload = await _apiClient.get('/evaluations/$id/manager-feedbacks');
    final data = payload['data'];
    final rawItems = data is Map && data['items'] is List
        ? data['items'] as List
        : const [];
    return rawItems
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> submitAnswers(
    String id,
    List<Map<String, dynamic>> answers,
  ) async {
    await _apiClient.post(
      '/evaluations/$id/answers',
      body: {'answers': answers},
    );
  }

  Future<void> generateAiScore(String id) async {
    await _apiClient.post('/evaluations/$id/ai-score');
  }

  Future<void> submitManagerFeedback(
    String id, {
    int? rating,
    List<Map<String, dynamic>>? ratings,
    String? comment,
  }) async {
    final body = <String, dynamic>{
      if (ratings != null && ratings.isNotEmpty) 'ratings': ratings,
      if ((ratings == null || ratings.isEmpty) && rating != null)
        'rating': rating,
      if (comment != null && comment.trim().isNotEmpty)
        'comment': comment.trim(),
    };
    await _apiClient.post('/evaluations/$id/manager-feedbacks', body: body);
  }

  Future<ManagerCriteriaPage> fetchManagerCriteria(String id) async {
    final payload = await _apiClient.get('/evaluations/$id/manager-criteria');
    final data = payload['data'] is Map
        ? Map<String, dynamic>.from(payload['data'] as Map)
        : <String, dynamic>{};
    final items = data['items'] is List
        ? (data['items'] as List)
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];
    final currentRatings = data['current_user_ratings'] is List
        ? (data['current_user_ratings'] as List)
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];
    final scale = data['scale'] is Map
        ? Map<String, dynamic>.from(data['scale'] as Map)
        : <String, dynamic>{};
    return ManagerCriteriaPage(
      items: items,
      currentRatings: currentRatings,
      minScore: int.tryParse('${scale['min'] ?? 1}') ?? 1,
      maxScore: int.tryParse('${scale['max'] ?? 5}') ?? 5,
    );
  }

  Future<void> validate(
    String id, {
    required double score,
    String? feedback,
  }) async {
    await _apiClient.patch(
      '/evaluations/$id/validate',
      body: {
        'admin_score': score,
        if (feedback != null && feedback.trim().isNotEmpty)
          'admin_feedback': feedback.trim(),
      },
    );
  }

  Future<EvaluationPage> fetch({
    String? search,
    String? status,
    int page = 1,
  }) async {
    final params = <String, String>{'page': '$page', 'per_page': '20'};
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    if (status != null && status != 'all') {
      params['status'] = status;
    }
    final query = params.entries
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');
    final payload = await _apiClient.get('/evaluations?$query');
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
    return EvaluationPage(
      items: items,
      page: int.tryParse('${pageData['current_page'] ?? page}') ?? page,
      lastPage: int.tryParse('${pageData['last_page'] ?? page}') ?? page,
    );
  }
}

class EvaluationPage {
  const EvaluationPage({
    required this.items,
    required this.page,
    required this.lastPage,
  });
  final List<Map<String, dynamic>> items;
  final int page;
  final int lastPage;
}

class ManagerCriteriaPage {
  const ManagerCriteriaPage({
    required this.items,
    required this.currentRatings,
    required this.minScore,
    required this.maxScore,
  });

  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> currentRatings;
  final int minScore;
  final int maxScore;
}

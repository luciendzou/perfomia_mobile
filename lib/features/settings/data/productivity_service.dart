import '../../../core/network/api_client.dart';

class ProductivityService {
  ProductivityService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();
  final ApiClient _apiClient;

  Future<ProductivityData> fetch() async {
    final payload = await _apiClient.get('/dashboard?service_load=all');
    final root = payload['data'] is Map
        ? Map<String, dynamic>.from(payload['data'] as Map)
        : <String, dynamic>{};
    final metrics = root['metrics'] is Map
        ? Map<String, dynamic>.from(root['metrics'] as Map)
        : root;
    final events =
        (metrics['productivity_events'] is List
                ? metrics['productivity_events'] as List
                : const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
    return ProductivityData(
      score: metrics['productivity_score'] ?? root['productivity_score'],
      events: events,
      rules: metrics['scoring_rules'] ?? root['scoring_rules'],
    );
  }
}

class ProductivityData {
  const ProductivityData({
    required this.score,
    required this.events,
    required this.rules,
  });
  final dynamic score;
  final List<Map<String, dynamic>> events;
  final dynamic rules;
}

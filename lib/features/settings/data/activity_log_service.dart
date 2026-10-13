import '../../../core/network/api_client.dart';

class ActivityLogService {
  ActivityLogService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ActivityLogPage> fetch({
    String search = '',
    String entityType = '',
    String action = '',
    String userId = '',
    String dateFrom = '',
    String dateTo = '',
    int page = 1,
    int perPage = 15,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
      if (search.trim().isNotEmpty) 'search': search.trim(),
      if (entityType.isNotEmpty) 'entity_type': entityType,
      if (action.isNotEmpty) 'action': action,
      if (userId.isNotEmpty) 'user_id': userId,
      if (dateFrom.isNotEmpty) 'date_from': dateFrom,
      if (dateTo.isNotEmpty) 'date_to': dateTo,
    };
    final query = params.entries
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');
    final payload = await _apiClient.get('/activity-logs?$query');
    final data = payload['data'];
    final pageData = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    final rawItems = pageData['data'] is List
        ? pageData['data'] as List
        : data is List
        ? data
        : const [];
    return ActivityLogPage(
      items: rawItems
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      currentPage: int.tryParse('${pageData['current_page'] ?? page}') ?? page,
      lastPage: int.tryParse('${pageData['last_page'] ?? 1}') ?? 1,
      total:
          int.tryParse('${pageData['total'] ?? rawItems.length}') ??
          rawItems.length,
    );
  }
}

class ActivityLogPage {
  const ActivityLogPage({
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

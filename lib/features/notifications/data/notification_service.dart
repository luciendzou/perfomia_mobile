import '../../../core/network/api_client.dart';

class NotificationService {
  NotificationService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<NotificationPageData> fetch({
    String? readFilter,
    String? search,
    int page = 1,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'per_page': '20',
      'sort_by': 'created_at',
      'sort_direction': 'desc',
    };
    if (readFilter != null) query['is_read'] = readFilter;
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    final payload = await _apiClient.get(
      '/notifications?${Uri(queryParameters: query).query}',
    );
    final data = payload['data'];
    if (data is! Map<String, dynamic>) {
      return NotificationPageData(
        items: const [],
        unreadCount: 0,
        page: page,
        lastPage: page,
      );
    }
    final items = data['data'];
    return NotificationPageData(
      items: items is List
          ? items
                .whereType<Map<String, dynamic>>()
                .map(AppNotification.fromJson)
                .toList()
          : const [],
      unreadCount: int.tryParse('${data['unread_count'] ?? 0}') ?? 0,
      page: int.tryParse('${data['current_page'] ?? page}') ?? page,
      lastPage: int.tryParse('${data['last_page'] ?? page}') ?? page,
    );
  }

  Future<void> markAllRead() async {
    await _apiClient.post('/notifications/read-all');
  }

  Future<void> markRead(String id) async {
    await _apiClient.put(
      '/notifications/$id',
      body: {'is_read': true, 'read_at': DateTime.now().toIso8601String()},
    );
  }

  Future<void> delete(String id) async {
    await _apiClient.delete('/notifications/$id');
  }
}

class NotificationPageData {
  const NotificationPageData({
    required this.items,
    required this.unreadCount,
    required this.page,
    required this.lastPage,
  });

  final List<AppNotification> items;
  final int unreadCount;
  final int page;
  final int lastPage;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: (json['id'] ?? '').toString(),
        title: (json['title'] ?? 'Notification').toString(),
        message: (json['message'] ?? '').toString(),
        isRead: json['is_read'] == true || json['is_read'] == 1,
        createdAt: json['created_at']?.toString(),
      );

  final String title;
  final String id;
  final String message;
  final bool isRead;
  final String? createdAt;
}

import '../../../core/network/api_client.dart';

class CourrierService {
  CourrierService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> show(String id) async {
    final payload = await _apiClient.get('/courriers/$id');
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> createIncoming(Map<String, dynamic> body) async {
    final payload = await _apiClient.post('/courriers/incoming', body: body);
    return _data(payload);
  }

  Future<Map<String, dynamic>> createOutgoing(Map<String, dynamic> body) async {
    final payload = await _apiClient.post('/courriers/outgoing', body: body);
    return _data(payload);
  }

  Future<Map<String, dynamic>> receive(String id, {String? comment}) async {
    final payload = await _apiClient.post(
      '/courriers/$id/receive',
      body: {
        'action_date': _nowApiDate(),
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      },
    );
    return _data(payload);
  }

  Future<Map<String, dynamic>> process(String id, {String? comment}) async {
    final payload = await _apiClient.patch(
      '/courriers/$id/process',
      body: {
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      },
    );
    return _data(payload);
  }

  Future<Map<String, dynamic>> remind(String id, String comment) async {
    final payload = await _apiClient.post(
      '/courriers/$id/remind',
      body: {'comment': comment.trim(), 'action_date': _nowApiDate()},
    );
    return _data(payload);
  }

  Future<Map<String, dynamic>> complete(String id, {String? comment}) async {
    final payload = await _apiClient.patch(
      '/courriers/$id/complete',
      body: {
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      },
    );
    return _data(payload);
  }

  Future<Map<String, dynamic>> archive(String id, {String? comment}) async {
    final payload = await _apiClient.patch(
      '/courriers/$id/archive',
      body: {
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      },
    );
    return _data(payload);
  }

  Future<List<int>> downloadFile(String id) =>
      _apiClient.getBytes('/courrier-fichiers/$id/download');

  Map<String, dynamic> _data(Map<String, dynamic> payload) {
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  String _nowApiDate() {
    final value = DateTime.now();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} ${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
  }

  Future<List<Map<String, dynamic>>> recipients({String? search}) async {
    final recipients = <Map<String, dynamic>>[];
    var page = 1;
    var lastPage = 1;
    do {
      final params = <String, String>{'page': '$page', 'per_page': '100'};
      if (search != null && search.trim().isNotEmpty) {
        params['search'] = search.trim();
      }
      final query = params.entries
          .map(
            (entry) =>
                '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
          )
          .join('&');
      final payload = await _apiClient.get('/courriers/recipients?$query');
      final data = payload['data'];
      final pageData = data is Map ? data : const <String, dynamic>{};
      final rawItems = pageData['data'] is List
          ? pageData['data'] as List
          : data is List
          ? data
          : const [];
      recipients.addAll(
        rawItems.whereType<Map>().map(
          (item) => Map<String, dynamic>.from(item),
        ),
      );
      page = int.tryParse('${pageData['current_page'] ?? page}') ?? page;
      lastPage = int.tryParse('${pageData['last_page'] ?? page}') ?? page;
      page++;
    } while (page <= lastPage);
    return recipients;
  }

  Future<Map<String, dynamic>> transmit(
    String id, {
    required List<String> userIds,
    String? instruction,
    Map<String, String>? recipientInstructions,
    required bool createTask,
    String? comment,
    String? dueDate,
  }) async {
    final body = <String, dynamic>{
      if (userIds.length == 1) 'to_user_id': userIds.first,
      if (userIds.length > 1) 'to_user_ids': userIds,
      'create_task': createTask,
    };
    if (instruction != null) body['instruction'] = instruction;
    if (recipientInstructions != null && recipientInstructions.isNotEmpty) {
      body['recipient_instructions'] = recipientInstructions;
    }
    if (comment != null) body['comment'] = comment.trim();
    if (dueDate != null) body['due_date'] = dueDate;
    final payload = await _apiClient.post(
      '/courriers/$id/transmit',
      body: body,
    );
    return _data(payload);
  }

  Future<CourrierPage> fetchPage({
    String? search,
    String? type,
    String? status,
    String? userId,
    int page = 1,
    int perPage = 20,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
      'sort_by': 'updated_at',
      'sort_direction': 'desc',
    };
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    if (type != null && type != 'all') params['type'] = type;
    if (status != null && status != 'all') params['status'] = status;
    if (userId != null && userId != 'all') params['user_id'] = userId;

    final query = params.entries
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');
    final payload = await _apiClient.get('/courriers?$query');
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
    final currentPage =
        int.tryParse('${pageData['current_page'] ?? page}') ?? page;
    final lastPage =
        int.tryParse('${pageData['last_page'] ?? currentPage}') ?? currentPage;
    return CourrierPage(items: items, page: currentPage, lastPage: lastPage);
  }
}

class CourrierPage {
  const CourrierPage({
    required this.items,
    required this.page,
    required this.lastPage,
  });

  final List<Map<String, dynamic>> items;
  final int page;
  final int lastPage;
}

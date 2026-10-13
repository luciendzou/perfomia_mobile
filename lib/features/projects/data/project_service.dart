import '../../../core/network/api_client.dart';

class ProjectService {
  ProjectService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ProjectPage> fetchPage({
    String? search,
    String? status,
    String? ownerId,
    int page = 1,
    int perPage = 20,
  }) async {
    final params = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    if (status != null && status != 'all') params['status'] = status;
    if (ownerId != null && ownerId != 'all') params['owner_id'] = ownerId;
    final payload = await _apiClient.get('/projects?${_query(params)}');
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
    return ProjectPage(items: items, page: currentPage, lastPage: lastPage);
  }

  Future<List<Map<String, dynamic>>> fetch({
    String? search,
    String? status,
    String? ownerId,
  }) async {
    final params = <String, String>{'per_page': '100'};
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    if (status != null && status != 'all') params['status'] = status;
    if (ownerId != null && ownerId != 'all') params['owner_id'] = ownerId;
    final payload = await _apiClient.get('/projects?${_query(params)}');
    return _list(payload);
  }

  Future<Map<String, dynamic>> show(String id) async {
    final payload = await _apiClient.get('/projects/$id');
    return _map(payload);
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final payload = await _apiClient.post('/projects', body: body);
    return _map(payload);
  }

  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> body,
  ) async {
    final payload = await _apiClient.patch('/projects/$id', body: body);
    return _map(payload);
  }

  Future<Map<String, dynamic>> changeStatus(String id, String status) async {
    final payload = await _apiClient.patch(
      '/projects/$id/status',
      body: {'status': status},
    );
    return _map(payload);
  }

  Future<void> remove(String id) => _apiClient.delete('/projects/$id');

  Future<Map<String, dynamic>> progress(String id) async {
    final payload = await _apiClient.get('/projects/$id/progress');
    return _map(payload);
  }

  Future<Map<String, dynamic>> dashboard(String id) async {
    final payload = await _apiClient.get('/projects/$id/dashboard');
    return _map(payload);
  }

  Future<List<Map<String, dynamic>>> users() async {
    final payload = await _apiClient.get('/users?per_page=100');
    return _list(payload);
  }

  Future<List<Map<String, dynamic>>> members(String id) async {
    final payload = await _apiClient.get('/projects/$id/members?per_page=100');
    return _list(payload);
  }

  Future<Map<String, dynamic>> addMember(
    String projectId,
    String userId,
    String role,
  ) async {
    final payload = await _apiClient.post(
      '/projects/$projectId/members',
      body: {'user_id': userId, 'role': role},
    );
    return _map(payload);
  }

  Future<Map<String, dynamic>> updateMember(
    String projectId,
    String memberId,
    String role,
  ) async {
    final payload = await _apiClient.patch(
      '/projects/$projectId/members/$memberId',
      body: {'role': role},
    );
    return _map(payload);
  }

  Future<void> removeMember(String projectId, String memberId) =>
      _apiClient.delete('/projects/$projectId/members/$memberId');

  Future<Map<String, dynamic>> updateNested(
    String path,
    Map<String, dynamic> body,
  ) async {
    final payload = await _apiClient.patch(path, body: body);
    return _map(payload);
  }

  Future<void> deleteNested(String path) => _apiClient.delete(path);

  Future<Map<String, dynamic>> dispatchAlerts(String id) async {
    final payload = await _apiClient.post(
      '/projects/$id/alerts/dispatch',
      body: {'force': false},
    );
    return _map(payload);
  }

  Future<Map<String, dynamic>> submitClosureReport(
    String id,
    String text,
  ) async {
    final payload = await _apiClient.post(
      '/projects/$id/closure-report',
      body: {'closure_report_text': text},
    );
    return _map(payload);
  }

  Future<Map<String, dynamic>> validateClosureReport(String id) async {
    final payload = await _apiClient.patch(
      '/projects/$id/closure-report/validate',
    );
    return _map(payload);
  }

  Future<Map<String, dynamic>> rejectClosureReport(
    String id,
    String note,
  ) async {
    final payload = await _apiClient.patch(
      '/projects/$id/closure-report/reject',
      body: {'closure_report_review_note': note},
    );
    return _map(payload);
  }

  Future<List<Map<String, dynamic>>> nested(String path) async {
    final payload = await _apiClient.get(path);
    return _list(payload);
  }

  Future<Map<String, dynamic>> createNested(
    String path,
    Map<String, dynamic> body,
  ) async {
    final payload = await _apiClient.post(path, body: body);
    return _map(payload);
  }

  String _query(Map<String, String> values) => values.entries
      .map(
        (entry) =>
            '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
      )
      .join('&');

  List<Map<String, dynamic>> _list(Map<String, dynamic> payload) {
    final data = payload['data'];
    final rawItems = data is List
        ? data
        : data is Map && data['data'] is List
        ? data['data'] as List
        : const [];
    return rawItems
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Map<String, dynamic> _map(Map<String, dynamic> payload) {
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }
}

class ProjectPage {
  const ProjectPage({
    required this.items,
    required this.page,
    required this.lastPage,
  });

  final List<Map<String, dynamic>> items;
  final int page;
  final int lastPage;

  bool get hasMore => page < lastPage;
}

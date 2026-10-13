import '../../../core/network/api_client.dart';

class TaskService {
  TaskService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final payload = await _apiClient.post('/tasks', body: body);
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> users() async {
    final payload = await _apiClient.get('/users?per_page=100');
    final data = payload['data'];
    final rawItems = data is Map && data['data'] is List
        ? data['data'] as List
        : data is List
        ? data
        : const [];
    return rawItems
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<TaskPage> fetchPage({
    String? search,
    String? status,
    String? priority,
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
    if (status != null && status != 'all') params['status'] = status;
    if (priority != null && priority != 'all') params['priority'] = priority;
    if (userId != null && userId != 'all') params['user_id'] = userId;
    final query = params.entries
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');
    final payload = await _apiClient.get('/tasks?$query');
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
    return TaskPage(items: items, page: currentPage, lastPage: lastPage);
  }

  Future<Map<String, dynamic>> show(String id) async {
    final payload = await _apiClient.get('/tasks/$id');
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> body,
  ) async {
    final payload = await _apiClient.patch('/tasks/$id', body: body);
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> assignUser(String id, String userId) async {
    final payload = await _apiClient.patch(
      '/tasks/$id/assign',
      body: {'assigned_to': userId},
    );
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<void> deleteTask(String id) => _apiClient.delete('/tasks/$id');

  Future<Map<String, dynamic>> changeStatus(String id, String status) async {
    final payload = await _apiClient.patch(
      '/tasks/$id/status',
      body: {'status': status},
    );
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> acceptAssignment(
    String id, {
    String? note,
  }) async {
    final payload = await _apiClient.patch(
      '/tasks/$id/assignment/accept',
      body: {
        if (note != null && note.trim().isNotEmpty)
          'assignment_response_note': note.trim(),
      },
    );
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> declineAssignment(String id, String note) async {
    final payload = await _apiClient.patch(
      '/tasks/$id/assignment/decline',
      body: {'assignment_response_note': note},
    );
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> comments(String id) async {
    final page = await fetchCommentsPage(id);
    return page.items;
  }

  Future<TaskRelatedPage> fetchCommentsPage(
    String id, {
    int page = 1,
    int perPage = 20,
  }) async {
    final payload = await _apiClient.get(
      '/tasks/$id/comments?page=$page&per_page=$perPage',
    );
    return _relatedPage(payload, page);
  }

  Future<Map<String, dynamic>> addComment(String id, String comment) async {
    final payload = await _apiClient.post(
      '/tasks/$id/comments',
      body: {'comment': comment},
    );
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> addCommentWithAttachments(
    String id,
    String comment,
    List<String> filePaths,
  ) async {
    final payload = await _apiClient.postMultipartFiles(
      '/task-comments',
      fields: {'task_id': id, 'comment': comment},
      fileField: 'attachments[]',
      filePaths: filePaths,
    );
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateComment(
    String commentId,
    String comment,
  ) async {
    final payload = await _apiClient.put(
      '/task-comments/$commentId',
      body: {'comment': comment},
    );
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<void> deleteComment(String commentId) =>
      _apiClient.delete('/task-comments/$commentId');

  Future<void> markRead(String id) async {
    await _apiClient.post('/tasks/$id/read');
  }

  Future<void> markCommentRead(String id) async {
    await _apiClient.post('/task-comments/$id/read');
  }

  Future<List<int>> downloadTaskFile(String id) =>
      _apiClient.getBytes('/task-files/$id/download');

  Future<List<int>> downloadCommentFile(String id) =>
      _apiClient.getBytes('/task-comment-files/$id/download');

  Future<List<int>> downloadClosureReport(String id) =>
      _apiClient.getBytes('/tasks/$id/closure-report/download');

  Future<List<Map<String, dynamic>>> files(String id) async {
    final page = await fetchFilesPage(id);
    return page.items;
  }

  Future<TaskRelatedPage> fetchFilesPage(
    String id, {
    int page = 1,
    int perPage = 20,
  }) async {
    final payload = await _apiClient.get(
      '/tasks/$id/files?page=$page&per_page=$perPage',
    );
    return _relatedPage(payload, page);
  }

  Future<Map<String, dynamic>> uploadFile(String id, String filePath) async {
    final payload = await _apiClient.postMultipart(
      '/task-files',
      fields: {'task_id': id},
      fileField: 'file',
      filePath: filePath,
    );
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateFile(
    String fileId,
    String fileName,
  ) async {
    final payload = await _apiClient.put(
      '/task-files/$fileId',
      body: {'file_name': fileName},
    );
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<void> deleteFile(String fileId) =>
      _apiClient.delete('/task-files/$fileId');

  Future<void> markFileRead(String fileId) async {
    await _apiClient.post('/task-files/$fileId/read');
  }

  Future<Map<String, dynamic>> submitClosure(
    String id,
    String text, {
    String? filePath,
  }) async {
    final payload = filePath == null
        ? await _apiClient.post(
            '/tasks/$id/closure-report',
            body: {'closure_report_text': text},
          )
        : await _apiClient.postMultipart(
            '/tasks/$id/closure-report',
            fields: {
              if (text.trim().isNotEmpty) 'closure_report_text': text.trim(),
            },
            fileField: 'closure_report_file',
            filePath: filePath,
          );
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> validateClosure(String id) async {
    final payload = await _apiClient.patch(
      '/tasks/$id/closure-report/validate',
    );
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> rejectClosure(String id, String note) async {
    final payload = await _apiClient.patch(
      '/tasks/$id/closure-report/reject',
      body: {'closure_report_review_note': note},
    );
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  TaskRelatedPage _relatedPage(Map<String, dynamic> payload, int fallbackPage) {
    final data = payload['data'];
    if (data is Map) {
      final raw = data['data'];
      final items = raw is List
          ? raw
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : const <Map<String, dynamic>>[];
      final currentPage =
          int.tryParse('${data['current_page'] ?? fallbackPage}') ??
          fallbackPage;
      final lastPage =
          int.tryParse('${data['last_page'] ?? currentPage}') ?? currentPage;
      return TaskRelatedPage(
        items: items,
        page: currentPage,
        lastPage: lastPage,
      );
    }
    return TaskRelatedPage(
      items: const [],
      page: fallbackPage,
      lastPage: fallbackPage,
    );
  }

  Future<List<RecentTask>> fetchRecent() async {
    final payload = await _apiClient.get(
      '/tasks?per_page=5&sort_by=created_at&sort_direction=desc',
    );
    final data = payload['data'];
    final items = data is Map<String, dynamic> ? data['data'] : data;
    if (items is! List) return const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(RecentTask.fromJson)
        .toList();
  }
}

class RecentTask {
  const RecentTask({
    required this.id,
    required this.title,
    required this.status,
    this.priority,
    this.projectName,
    this.dueDate,
  });

  factory RecentTask.fromJson(Map<String, dynamic> json) {
    final project = json['project'];
    return RecentTask(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Tache sans titre').toString(),
      status: (json['status'] ?? 'todo').toString(),
      priority: json['priority']?.toString(),
      projectName: project is Map<String, dynamic>
          ? project['name']?.toString()
          : json['project_name']?.toString(),
      dueDate: json['due_date']?.toString(),
    );
  }

  final String id;
  final String title;
  final String status;
  final String? priority;
  final String? projectName;
  final String? dueDate;
}

class TaskPage {
  const TaskPage({
    required this.items,
    required this.page,
    required this.lastPage,
  });

  final List<Map<String, dynamic>> items;
  final int page;
  final int lastPage;

  bool get hasMore => page < lastPage;
}

class TaskRelatedPage {
  const TaskRelatedPage({
    required this.items,
    required this.page,
    required this.lastPage,
  });

  final List<Map<String, dynamic>> items;
  final int page;
  final int lastPage;

  bool get hasMore => page < lastPage;
}

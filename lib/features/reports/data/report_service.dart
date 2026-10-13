import '../../../core/network/api_client.dart';

class ReportService {
  ReportService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> companyProductivity({
    String? from,
    String? to,
  }) => _get('/reports/productivity/company', _dates(from, to));

  Future<Map<String, dynamic>> userProductivity(
    String userId, {
    String? from,
    String? to,
  }) => _get(
    '/reports/productivity/user/${Uri.encodeComponent(userId)}',
    _dates(from, to),
  );

  Future<Map<String, dynamic>> taskReport({
    required bool companyScope,
    required String userId,
    String? from,
    String? to,
  }) => _get('/reports/tasks', {
    ..._dates(from, to),
    'scope': companyScope ? 'company' : 'user',
    if (!companyScope) 'user_id': userId,
  });

  Future<Map<String, dynamic>> projectReport({
    required bool companyScope,
    required String userId,
    String? status,
    String? from,
    String? to,
  }) => _get('/reports/projects', {
    ..._dates(from, to),
    'scope': companyScope ? 'company' : 'user',
    if (!companyScope) 'user_id': userId,
    if (status != null && status != 'all') 'status': status,
  });

  Future<Map<String, dynamic>> courrierReport({
    required bool companyScope,
    required String userId,
    String? type,
    String? from,
    String? to,
  }) => _get('/reports/courriers', {
    ..._dates(from, to),
    'scope': companyScope ? 'company' : 'user',
    'type': type ?? 'all',
    if (!companyScope) 'user_id': userId,
  });

  Future<Map<String, dynamic>> bestEmployees({
    required bool companyScope,
    required String userId,
    int limit = 5,
    String? from,
    String? to,
  }) => _get('/reports/best-employees', {
    ..._dates(from, to),
    'limit': '$limit',
    'scope': companyScope ? 'company' : 'user',
    if (!companyScope) 'user_id': userId,
  });

  Map<String, String> _dates(String? from, String? to) => {
    if (from != null && from.isNotEmpty) 'from': from,
    if (to != null && to.isNotEmpty) 'to': to,
  };

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> params,
  ) async {
    final query = params.entries
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');
    final payload = await _apiClient.get(query.isEmpty ? path : '$path?$query');
    final data = payload['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<ReportBundle> fetch({
    required String userId,
    required bool companyScope,
    String? from,
    String? to,
    String projectStatus = 'all',
    String courrierType = 'all',
  }) async {
    final responses = await Future.wait([
      companyScope
          ? companyProductivity(from: from, to: to)
          : userProductivity(userId, from: from, to: to),
      taskReport(
        companyScope: companyScope,
        userId: userId,
        from: from,
        to: to,
      ),
      projectReport(
        companyScope: companyScope,
        userId: userId,
        status: projectStatus,
        from: from,
        to: to,
      ),
      courrierReport(
        companyScope: companyScope,
        userId: userId,
        type: courrierType,
        from: from,
        to: to,
      ),
      bestEmployees(
        companyScope: companyScope,
        userId: userId,
        from: from,
        to: to,
      ),
    ]);
    return ReportBundle(
      productivity: responses[0],
      tasks: responses[1],
      projects: responses[2],
      courriers: responses[3],
      bestEmployees: responses[4],
    );
  }
}

class ReportBundle {
  const ReportBundle({
    required this.productivity,
    required this.tasks,
    required this.projects,
    required this.courriers,
    required this.bestEmployees,
  });
  final Map<String, dynamic> productivity;
  final Map<String, dynamic> tasks;
  final Map<String, dynamic> projects;
  final Map<String, dynamic> courriers;
  final Map<String, dynamic> bestEmployees;
}

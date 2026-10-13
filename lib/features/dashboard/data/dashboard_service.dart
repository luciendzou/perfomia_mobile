import '../../../core/network/api_client.dart';

class DashboardService {
  DashboardService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<DashboardData> fetch() async {
    final payload = await _apiClient.get('/dashboard?service_load_limit=4');
    final data = payload['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Donnees du dashboard invalides.');
    }
    return DashboardData.fromJson(data);
  }
}

class DashboardData {
  const DashboardData({required this.summary, required this.serviceLoad});

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'];
    final metrics = json['metrics'];
    final summaryMap = summary is Map<String, dynamic>
        ? summary
        : const <String, dynamic>{};
    final metricsMap = metrics is Map<String, dynamic>
        ? metrics
        : const <String, dynamic>{};
    final services = metricsMap['service_load'];

    return DashboardData(
      summary: DashboardSummary.fromJson(summaryMap),
      serviceLoad: services is List
          ? services
                .whereType<Map<String, dynamic>>()
                .map(DashboardServiceLoad.fromJson)
                .toList()
          : const [],
    );
  }

  final DashboardSummary summary;
  final List<DashboardServiceLoad> serviceLoad;
}

class DashboardSummary {
  const DashboardSummary({
    required this.productivity,
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.overdueTasks,
    required this.projectsAtRisk,
    required this.pendingCourriers,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    double number(dynamic value) => double.tryParse('$value') ?? 0;
    int integer(dynamic value) => number(value).round();

    return DashboardSummary(
      productivity: number(
        json['productivity_score'] ?? json['avgProductivity'],
      ).clamp(0, 100),
      totalTasks: integer(json['totalTasks'] ?? json['total_tasks']),
      completedTasks: integer(
        json['completedTasks'] ?? json['completed_tasks'],
      ),
      pendingTasks: integer(json['pendingTasks'] ?? json['pending_tasks']),
      overdueTasks: integer(json['overdueTasks'] ?? json['overdue_tasks']),
      projectsAtRisk: integer(
        json['projectsAtRisk'] ?? json['projects_at_risk'],
      ),
      pendingCourriers: integer(
        json['pendingCourriers'] ?? json['pending_courriers'],
      ),
    );
  }

  final double productivity;
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int overdueTasks;
  final int projectsAtRisk;
  final int pendingCourriers;
}

class DashboardServiceLoad {
  const DashboardServiceLoad({
    required this.name,
    required this.total,
    required this.done,
    required this.remaining,
    required this.overdue,
    required this.completionRate,
  });

  factory DashboardServiceLoad.fromJson(Map<String, dynamic> json) {
    int integer(dynamic value) => int.tryParse('$value') ?? 0;
    double number(dynamic value) => double.tryParse('$value') ?? 0;

    return DashboardServiceLoad(
      name: (json['service_name'] ?? json['name'] ?? 'Service').toString(),
      total: integer(json['tasks_total'] ?? json['count']),
      done: integer(json['tasks_done']),
      remaining: integer(json['tasks_remaining']),
      overdue: integer(json['tasks_overdue']),
      completionRate: number(
        json['completion_rate'] ?? json['load'],
      ).clamp(0, 100),
    );
  }

  final String name;
  final int total;
  final int done;
  final int remaining;
  final int overdue;
  final double completionRate;
}

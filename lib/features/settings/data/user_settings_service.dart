import '../../../core/network/api_client.dart';

class UserSettingsService {
  UserSettingsService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<UserSettings> fetch() async {
    final payload = await _apiClient.get('/settings/me');
    final data = payload['data'];
    return UserSettings.fromJson(
      data is Map<String, dynamic> ? data : const {},
    );
  }

  Future<UserSettings> update(UserSettings settings) async {
    final payload = await _apiClient.put(
      '/settings/me',
      body: settings.toJson(),
    );
    final data = payload['data'];
    return UserSettings.fromJson(
      data is Map<String, dynamic> ? data : settings.toJson(),
    );
  }
}

class UserSettings {
  const UserSettings({
    this.language = 'fr',
    this.timezone = 'Africa/Douala',
    this.inAppNotifications = true,
    this.emailNotifications = true,
    this.whatsappNotifications = false,
    this.taskNotifications = true,
    this.evaluationNotifications = true,
    this.courrierNotifications = true,
    this.defaultDashboard = 'dashboard',
    this.defaultTasksView = 'list',
    this.defaultCourrierView = 'registre',
    this.itemsPerPage = 15,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
    language: json['language']?.toString() ?? 'fr',
    timezone: json['timezone']?.toString() ?? 'Africa/Douala',
    inAppNotifications: _bool(json['in_app_notifications_enabled'], true),
    emailNotifications: _bool(json['email_notifications_enabled'], true),
    whatsappNotifications: _bool(json['whatsapp_notifications_enabled'], false),
    taskNotifications: _bool(json['task_notifications_enabled'], true),
    evaluationNotifications: _bool(
      json['evaluation_notifications_enabled'],
      true,
    ),
    courrierNotifications: _bool(json['courrier_notifications_enabled'], true),
    defaultDashboard: json['default_dashboard']?.toString() ?? 'dashboard',
    defaultTasksView: json['default_tasks_view']?.toString() ?? 'list',
    defaultCourrierView:
        json['default_courrier_view']?.toString() ?? 'registre',
    itemsPerPage: int.tryParse('${json['items_per_page'] ?? 15}') ?? 15,
  );

  static bool _bool(dynamic value, bool fallback) => value == null
      ? fallback
      : value == true || value == 1 || value == '1' || value == 'true';

  final String language;
  final String timezone;
  final bool inAppNotifications;
  final bool emailNotifications;
  final bool whatsappNotifications;
  final bool taskNotifications;
  final bool evaluationNotifications;
  final bool courrierNotifications;
  final String defaultDashboard;
  final String defaultTasksView;
  final String defaultCourrierView;
  final int itemsPerPage;

  UserSettings copyWith({
    String? language,
    String? timezone,
    bool? inAppNotifications,
    bool? emailNotifications,
    bool? whatsappNotifications,
    bool? taskNotifications,
    bool? evaluationNotifications,
    bool? courrierNotifications,
    String? defaultDashboard,
    String? defaultTasksView,
    String? defaultCourrierView,
    int? itemsPerPage,
  }) => UserSettings(
    language: language ?? this.language,
    timezone: timezone ?? this.timezone,
    inAppNotifications: inAppNotifications ?? this.inAppNotifications,
    emailNotifications: emailNotifications ?? this.emailNotifications,
    whatsappNotifications: whatsappNotifications ?? this.whatsappNotifications,
    taskNotifications: taskNotifications ?? this.taskNotifications,
    evaluationNotifications:
        evaluationNotifications ?? this.evaluationNotifications,
    courrierNotifications: courrierNotifications ?? this.courrierNotifications,
    defaultDashboard: defaultDashboard ?? this.defaultDashboard,
    defaultTasksView: defaultTasksView ?? this.defaultTasksView,
    defaultCourrierView: defaultCourrierView ?? this.defaultCourrierView,
    itemsPerPage: itemsPerPage ?? this.itemsPerPage,
  );

  Map<String, dynamic> toJson() => {
    'language': language,
    'timezone': timezone,
    'in_app_notifications_enabled': inAppNotifications,
    'email_notifications_enabled': emailNotifications,
    'whatsapp_notifications_enabled': whatsappNotifications,
    'task_notifications_enabled': taskNotifications,
    'evaluation_notifications_enabled': evaluationNotifications,
    'courrier_notifications_enabled': courrierNotifications,
    'default_dashboard': defaultDashboard,
    'default_tasks_view': defaultTasksView,
    'default_courrier_view': defaultCourrierView,
    'items_per_page': itemsPerPage,
  };
}

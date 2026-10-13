import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/network/api_client.dart';
import '../../../core/ui/app_messenger.dart';
import '../../../core/localization/app_localizations.dart';
import '../../auth/data/auth_service.dart';
import 'activity_logs_page.dart';
import 'company_settings_page.dart';
import 'evaluation_criteria_page.dart';
import 'evaluation_questions_page.dart';
import 'organization_supervisors_page.dart';
import 'productivity_page.dart';
import 'users_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.session});

  final AuthSession session;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final Set<String> _roles;

  @override
  void initState() {
    super.initState();
    final roles = widget.session.user['roles'];
    _roles = roles is List
        ? roles
              .map((role) => role is Map ? role['name'] : role)
              .map((role) => '$role'.toLowerCase())
              .toSet()
        : <String>{widget.session.user['role']?.toString().toLowerCase() ?? ''};
  }

  bool get _isAdmin => _roles.intersection({'admin', 'super_admin'}).isNotEmpty;

  bool get _isStrictAdmin => _roles.contains('admin');

  bool get _isSuperAdmin => _roles.contains('super_admin');

  void _openCompanyPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CompanySettingsPage(session: widget.session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final organizationItems = [
      if (_isAdmin)
        _SettingsItem(
          icon: Iconsax.profile_2user,
          title: strings.usersTitle,
          description: strings.usersDescription,
          status: 'Administration',
          endpoint: '/users?per_page=100',
        ),
      if (_isAdmin)
        _SettingsItem(
          icon: Iconsax.building_4,
          title: strings.departmentsTitle,
          description: strings.departmentsDescription,
          status: 'Organisation',
          endpoint: '/departments?all=true',
        ),
      if (_isAdmin)
        _SettingsItem(
          icon: Iconsax.tree,
          title: strings.servicesTitle,
          description: strings.servicesDescription,
          status: 'Organisation',
          endpoint: '/services?all=true',
        ),
      if (_isAdmin)
        _SettingsItem(
          icon: Iconsax.people,
          title: strings.supervisorsTitle,
          description: strings.supervisorsDescription,
          status: 'Organisation',
          endpoint: '/organization-supervisors?all=true',
        ),
      if (_isAdmin)
        _SettingsItem(
          icon: Iconsax.chart,
          title: strings.productivityTitle,
          description: strings.productivityDescriptionSettings,
          status: 'Entreprise',
          endpoint: '/settings/company',
        ),
      if (_isAdmin)
        _SettingsItem(
          icon: Iconsax.activity,
          title: strings.activityLog,
          description: strings.activityLogDescription,
          status: 'Administration',
          endpoint: '/activity-logs?per_page=100',
        ),
    ];
    final evaluationItems = [
      if (_isStrictAdmin)
        _SettingsItem(
          icon: Iconsax.message_question,
          title: strings.questionsTitle,
          description: strings.questionsDescription,
          status: 'Evaluations',
          endpoint: '/evaluation-questions',
        ),
      if (_isStrictAdmin)
        _SettingsItem(
          icon: Iconsax.task_square,
          title: strings.criteriaTitle,
          description: strings.criteriaDescription,
          status: 'Evaluations',
          endpoint: '/evaluation-manager-criteria',
        ),
    ];
    final onboardingItems = [
      if (_isSuperAdmin)
        const _SettingsItem(
          icon: Iconsax.sms,
          title: 'Invitations',
          description: 'Invitations envoyees aux futurs utilisateurs.',
          status: 'Onboarding',
          endpoint: '/invitations?per_page=100',
        ),
      if (_isSuperAdmin)
        const _SettingsItem(
          icon: Iconsax.key,
          title: 'Codes d activation',
          description: 'Codes utilises pour activer les acces entreprise.',
          status: 'Onboarding',
          endpoint: '/activation-codes?per_page=100',
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(strings.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          Text(
            strings.configuration,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            strings.personalSettingsNotice,
            style: TextStyle(color: Color(0xff64748b), height: 1.4),
          ),
          const SizedBox(height: 24),
          _SettingsSectionLabel(label: strings.companySettings),
          const SizedBox(height: 8),
          if (_isAdmin)
            Card(
              child: _SettingsTile(
                icon: Iconsax.building_4,
                title: strings.companySettings,
                description: strings.companySettingsDescription,
                trailing: const Icon(Iconsax.arrow_right),
                onTap: _openCompanyPage,
              ),
            )
          else
            _AccessNotice(
              text: strings.isEnglish
                  ? 'Company settings are restricted to administrators.'
                  : 'Les parametres d entreprise sont reserves aux administrateurs.',
            ),
          if (_isAdmin) ...[
            const SizedBox(height: 24),
            _SettingsSectionLabel(label: strings.organization),
            const SizedBox(height: 8),
            ...organizationItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: _SettingsTile.fromItem(
                    item,
                    onTap: () => _openResource(item),
                  ),
                ),
              ),
            ),
          ],
          if (_isStrictAdmin) ...[
            const SizedBox(height: 24),
            _SettingsSectionLabel(label: strings.evaluationsSection),
            const SizedBox(height: 8),
            ...evaluationItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: _SettingsTile.fromItem(
                    item,
                    onTap: () => _openResource(item),
                  ),
                ),
              ),
            ),
          ],
          if (_isSuperAdmin) ...[
            const SizedBox(height: 24),
            const _SettingsSectionLabel(label: 'Onboarding'),
            const SizedBox(height: 8),
            ...onboardingItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: _SettingsTile.fromItem(
                    item,
                    onTap: () => _openResource(item),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openResource(_SettingsItem item) {
    if (item.endpoint == '/settings/company') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductivityPage(session: widget.session),
        ),
      );
      return;
    }
    if (item.endpoint.startsWith('/users')) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => UsersPage(session: widget.session)),
      );
      return;
    }
    if (item.endpoint.startsWith('/activity-logs')) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ActivityLogsPage(session: widget.session),
        ),
      );
      return;
    }
    if (item.endpoint == '/evaluation-questions') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EvaluationQuestionsPage(session: widget.session),
        ),
      );
      return;
    }
    if (item.endpoint == '/evaluation-manager-criteria') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EvaluationCriteriaPage(session: widget.session),
        ),
      );
      return;
    }
    if (item.endpoint.startsWith('/organization-supervisors')) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrganizationSupervisorsPage(session: widget.session),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsResourcePage(
          title: item.title,
          description: item.description,
          endpoint: item.endpoint,
          accessToken: widget.session.token,
        ),
      ),
    );
  }
}

class _CompanySettingsSheet extends StatefulWidget {
  const _CompanySettingsSheet({required this.initial, required this.onSave});

  final Map<String, dynamic> initial;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> body) onSave;

  @override
  State<_CompanySettingsSheet> createState() => _CompanySettingsSheetState();
}

class _CompanySettingsSheetState extends State<_CompanySettingsSheet> {
  late bool _notifications;
  late bool _whatsapp;
  late bool _evaluation;
  late bool _courrier;
  late bool _tasks;
  late bool _ai;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _notifications = _bool('notifications_enabled', true);
    _whatsapp = _bool('whatsapp_notifications_enabled', false);
    _evaluation = _bool('evaluation_enabled', true);
    _courrier = _bool('courrier_enabled', true);
    _tasks = _bool('task_management_enabled', true);
    _ai = _bool('allow_ai_evaluation', false);
  }

  bool _bool(String key, bool fallback) {
    final value = widget.initial[key];
    return value == null
        ? fallback
        : value == true || value == 1 || value == '1' || value == 'true';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave({
        'notifications_enabled': _notifications,
        'whatsapp_notifications_enabled': _whatsapp,
        'evaluation_enabled': _evaluation,
        'courrier_enabled': _courrier,
        'task_management_enabled': _tasks,
        'allow_ai_evaluation': _ai,
      });
    } on ApiException catch (error) {
      showAppError(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Parametres de l entreprise',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ces reglages s appliquent a l espace de travail.',
            style: TextStyle(color: Color(0xff64748b)),
          ),
          const SizedBox(height: 18),
          _switch('Notifications globales', _notifications, (value) {
            setState(() => _notifications = value);
          }),
          _switch('Notifications WhatsApp', _whatsapp, (value) {
            setState(() => _whatsapp = value);
          }),
          _switch('Evaluations', _evaluation, (value) {
            setState(() => _evaluation = value);
          }),
          _switch('Gestion des courriers', _courrier, (value) {
            setState(() => _courrier = value);
          }),
          _switch('Gestion des taches', _tasks, (value) {
            setState(() => _tasks = value);
          }),
          _switch('Evaluation par IA', _ai, (value) {
            setState(() => _ai = value);
          }),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enregistrer'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _switch(String title, bool value, ValueChanged<bool> onChanged) =>
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        value: value,
        onChanged: _saving ? null : onChanged,
      );
}

class _SettingsItem {
  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    required this.endpoint,
  });

  final IconData icon;
  final String title;
  final String description;
  final String status;
  final String endpoint;
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.trailing,
    this.onTap,
  });

  factory _SettingsTile.fromItem(
    _SettingsItem item, {
    required VoidCallback onTap,
  }) => _SettingsTile(
    icon: item.icon,
    title: item.title,
    description: item.description,
    trailing: const Icon(Iconsax.arrow_right),
    onTap: onTap,
  );

  final IconData icon;
  final String title;
  final String description;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
    leading: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Theme.of(context).colorScheme.primary),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(description),
    trailing: trailing,
    onTap: onTap,
  );
}

class _SettingsSectionLabel extends StatelessWidget {
  const _SettingsSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: TextStyle(
      color: Theme.of(context).colorScheme.primary,
      fontSize: 12,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.6,
    ),
  );
}

class _AccessNotice extends StatelessWidget {
  const _AccessNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, color: Color(0xff64748b)),
    ),
  );
}

class SettingsResourcePage extends StatefulWidget {
  const SettingsResourcePage({
    super.key,
    required this.title,
    required this.description,
    required this.endpoint,
    required this.accessToken,
  });

  final String title;
  final String description;
  final String endpoint;
  final String accessToken;

  @override
  State<SettingsResourcePage> createState() => _SettingsResourcePageState();
}

class _SettingsResourcePageState extends State<SettingsResourcePage> {
  late final ApiClient _apiClient;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];

  bool get _canCreate =>
      widget.endpoint.startsWith('/departments') ||
      widget.endpoint.startsWith('/services');

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(accessToken: widget.accessToken);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final payload = await _apiClient.get(widget.endpoint);
      final data = payload['data'];
      final rawItems = data is List
          ? data
          : data is Map && data['data'] is List
          ? data['data'] as List
          : const [];
      if (mounted) {
        setState(() {
          _items = rawItems
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Impossible de charger les donnees.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openCreate() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CreateResourceForm(
        isService: widget.endpoint.startsWith('/services'),
        apiClient: _apiClient,
        onSubmit: (body) async {
          await _apiClient.post(widget.endpoint.split('?').first, body: body);
          if (mounted) {
            Navigator.pop(context, true);
            showAppSuccess(
              widget.endpoint.startsWith('/services')
                  ? AppLocalizations.of(context).serviceAdded
                  : AppLocalizations.of(context).departmentAdded,
            );
          }
        },
      ),
    );
    if (created == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
      actions: [
        IconButton(
          tooltip: AppLocalizations.of(context).refresh,
          onPressed: _loading ? null : _load,
          icon: const Icon(Iconsax.refresh),
        ),
      ],
    ),
    floatingActionButton: _canCreate
        ? FloatingActionButton.extended(
            onPressed: _loading ? null : _openCreate,
            icon: const Icon(Iconsax.add),
            label: Text(
              widget.endpoint.startsWith('/services')
                  ? AppLocalizations.of(context).addService
                  : AppLocalizations.of(context).addDepartment,
            ),
          )
        : null,
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          Text(
            widget.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            widget.description,
            style: const TextStyle(color: Color(0xff64748b), height: 1.4),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _ResourceState(
              icon: Iconsax.danger,
              title: AppLocalizations.of(context).loadingError,
              message: _error!,
              action: TextButton.icon(
                onPressed: _load,
                icon: const Icon(Iconsax.refresh),
                label: Text(AppLocalizations.of(context).retry),
              ),
            )
          else if (_items.isEmpty)
            _ResourceState(
              icon: Iconsax.archive,
              title: AppLocalizations.of(context).noData,
              message: AppLocalizations.of(context).noDataAvailable,
            )
          else
            ..._items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(child: _ResourceRow(item: item)),
              ),
            ),
        ],
      ),
    ),
  );
}

class _CreateResourceForm extends StatefulWidget {
  const _CreateResourceForm({
    required this.isService,
    required this.apiClient,
    required this.onSubmit,
  });

  final bool isService;
  final ApiClient apiClient;
  final Future<void> Function(Map<String, dynamic> body) onSubmit;

  @override
  State<_CreateResourceForm> createState() => _CreateResourceFormState();
}

class _CreateResourceFormState extends State<_CreateResourceForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  List<Map<String, dynamic>> _departments = const [];
  String? _departmentId;
  bool _loadingDepartments = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isService) _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    setState(() => _loadingDepartments = true);
    try {
      final payload = await widget.apiClient.get('/departments?all=true');
      final data = payload['data'];
      final rawItems = data is List
          ? data
          : data is Map && data['data'] is List
          ? data['data'] as List
          : const [];
      if (mounted) {
        setState(() {
          _departments = rawItems
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          if (_departments.isNotEmpty) {
            _departmentId = _departments.first['id']?.toString();
          }
        });
      }
    } on ApiException catch (error) {
      showAppError(error.message);
    } finally {
      if (mounted) setState(() => _loadingDepartments = false);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await widget.onSubmit({
        'name': _name.text.trim(),
        'description': _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        if (widget.isService) 'department_id': _departmentId,
      });
    } on ApiException catch (error) {
      showAppError(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.isService
                  ? AppLocalizations.of(context).addService
                  : AppLocalizations.of(context).addDepartment,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).name,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? AppLocalizations.of(context).requiredField
                  : null,
            ),
            const SizedBox(height: 14),
            if (widget.isService)
              DropdownButtonFormField<String>(
                initialValue: _departmentId,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).department,
                ),
                items: _departments
                    .map(
                      (department) => DropdownMenuItem(
                        value: department['id']?.toString(),
                        child: Text(
                          department['name']?.toString() ?? 'Departement',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _saving || _loadingDepartments
                    ? null
                    : (value) => setState(() => _departmentId = value),
                validator: (value) => value == null || value.isEmpty
                    ? AppLocalizations.of(context).selectDepartment
                    : null,
              ),
            if (widget.isService) const SizedBox(height: 14),
            TextFormField(
              controller: _description,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).descriptionLabel,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _saving || _loadingDepartments ? null : _submit,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(AppLocalizations.of(context).save),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ResourceRow extends StatelessWidget {
  const _ResourceRow({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final title =
        item['name']?.toString() ??
        item['title']?.toString() ??
        item['question']?.toString() ??
        item['label']?.toString() ??
        item['action']?.toString() ??
        'Element';
    final userName = item['user'] is Map
        ? item['user']['full_name']?.toString()
        : null;
    final subtitle =
        item['description']?.toString() ??
        item['email']?.toString() ??
        item['role']?.toString() ??
        userName ??
        item['status']?.toString();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Iconsax.setting_2,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: subtitle == null ? null : Text(subtitle),
    );
  }
}

class _ResourceState extends StatelessWidget {
  const _ResourceState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 48),
    child: Column(
      children: [
        Icon(icon, size: 48, color: const Color(0xff94a3b8)),
        const SizedBox(height: 14),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xff64748b)),
        ),
        if (action != null) ...[const SizedBox(height: 10), action!],
      ],
    ),
  );
}

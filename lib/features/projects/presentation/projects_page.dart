import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/ui/app_messenger.dart';
import '../../auth/data/auth_service.dart';
import '../../tasks/data/task_service.dart';
import '../data/project_service.dart';

String _plainTextFromRichReport(String value) {
  var text = value
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '- ')
      .replaceAll(RegExp(r'</(?:p|div|li|h[1-6])>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]*>', caseSensitive: false), '');

  const entities = <String, String>{
    '&nbsp;': ' ',
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
  };
  entities.forEach((entity, replacement) {
    text = text.replaceAll(entity, replacement);
  });
  text = text.replaceAllMapped(
    RegExp(r'&#(x[0-9a-f]+|[0-9]+);', caseSensitive: false),
    (match) {
      final raw = match.group(1)!;
      final codePoint = raw.toLowerCase().startsWith('x')
          ? int.tryParse(raw.substring(1), radix: 16)
          : int.tryParse(raw);
      return codePoint == null
          ? match.group(0)!
          : String.fromCharCode(codePoint);
    },
  );

  return text
      .replaceAll('\r\n', '\n')
      .replaceAll(RegExp(r'[ \t]+\n'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key, required this.session});

  final AuthSession session;

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  late final ProjectService _service;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _projects = const [];
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 0;
  int _lastPage = 1;
  String _status = 'all';
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = ProjectService(
      apiClient: ApiClient(accessToken: widget.session.token),
    );
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 500) _loadMore();
  }

  Future<void> _load({bool reset = true}) async {
    if (_loadingMore) return;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _projects = const [];
        _page = 0;
        _lastPage = 1;
      }
    });
    try {
      final result = await _service.fetchPage(
        search: _searchController.text,
        status: _status,
        page: 1,
      );
      if (mounted) {
        setState(() {
          _projects = result.items;
          _page = result.page;
          _lastPage = result.lastPage;
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).projectLoadError);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || _page >= _lastPage) return;
    setState(() => _loadingMore = true);
    try {
      final result = await _service.fetchPage(
        search: _searchController.text,
        status: _status,
        page: _page + 1,
      );
      if (mounted) {
        setState(() {
          _projects = [..._projects, ...result.items];
          _page = result.page;
          _lastPage = result.lastPage;
        });
      }
    } on ApiException catch (error) {
      if (mounted) showAppError(error.message);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _create() async {
    List<Map<String, dynamic>> users;
    try {
      users = await _service.users();
    } on ApiException catch (error) {
      showAppError(error.message);
      return;
    }
    if (!mounted) return;
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProjectForm(
        availableUsers: users,
        onSubmit: (body) async {
          await _service.create(body);
          if (mounted) {
            Navigator.pop(context, true);
            showAppSuccess(AppLocalizations.of(context).projectCreated);
          }
        },
      ),
    );
    if (created == true && mounted) await _load();
  }

  void _open(Map<String, dynamic> project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectDetailsPage(
          session: widget.session,
          projectId: project['id'].toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final statusOptions = <String, String>{
      'all': strings.all,
      'planned': strings.planned,
      'active': strings.active,
      'on_hold': strings.onHold,
      'completed': strings.finished,
      'archived': strings.archived,
      'cancelled': strings.cancelled,
    };
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.projects,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                strings.projectsDescription,
                style: TextStyle(color: Color(0xff64748b)),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _load(),
                decoration: InputDecoration(
                  hintText: strings.searchProject,
                  prefixIcon: const Icon(Iconsax.search_normal),
                  suffixIcon: IconButton(
                    tooltip: strings.search,
                    onPressed: _load,
                    icon: const Icon(Iconsax.arrow_right),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: InputDecoration(
                  labelText: strings.filterByStatus,
                  prefixIcon: Icon(Iconsax.filter),
                ),
                items: statusOptions.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _status = value);
                  _load();
                },
              ),
              const SizedBox(height: 18),
              if (_loading)
                const _ProjectSkeletonList()
              else if (_error != null)
                _ProjectsState(
                  icon: Iconsax.danger,
                  title: strings.loadingError,
                  message: _error!,
                  action: TextButton.icon(
                    onPressed: _load,
                    icon: const Icon(Iconsax.refresh),
                    label: Text(strings.retry),
                  ),
                )
              else if (_projects.isEmpty)
                _ProjectsState(
                  icon: Iconsax.folder_open,
                  title: strings.noProject,
                  message: strings.projectsWillAppear,
                )
              else
                ..._projects.map(
                  (project) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: ListTile(
                        title: Text(
                          project['name']?.toString() ?? strings.projectEntity,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(_projectSubtitle(project)),
                        trailing: _StatusBadge(
                          status: project['status']?.toString(),
                        ),
                        onTap: () => _open(project),
                      ),
                    ),
                  ),
                ),
              if (_loadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          right: 18,
          bottom: 18,
          child: FloatingActionButton.extended(
            onPressed: _loading ? null : _create,
            icon: const Icon(Iconsax.add),
            label: Text(strings.add),
          ),
        ),
      ],
    );
  }

  String _projectSubtitle(Map<String, dynamic> project) {
    final owner = project['owner'] is Map
        ? project['owner']['full_name']?.toString()
        : null;
    final endDate = project['end_date']?.toString();
    return [
      owner,
      endDate,
    ].whereType<String>().where((item) => item.isNotEmpty).join(' - ');
  }
}

class ProjectDetailsPage extends StatefulWidget {
  const ProjectDetailsPage({
    super.key,
    required this.session,
    required this.projectId,
  });

  final AuthSession session;
  final String projectId;

  @override
  State<ProjectDetailsPage> createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends State<ProjectDetailsPage> {
  late final ProjectService _service;
  Map<String, dynamic>? _project;
  Map<String, dynamic>? _progress;
  Map<String, dynamic>? _dashboard;
  List<Map<String, dynamic>> _members = const [];
  List<Map<String, dynamic>> _users = const [];
  bool _loading = true;
  bool _actionLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = ProjectService(
      apiClient: ApiClient(accessToken: widget.session.token),
    );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.show(widget.projectId),
        _service.progress(widget.projectId),
        _service.members(widget.projectId),
      ]);
      Map<String, dynamic> dashboard = const {};
      try {
        dashboard = await _service.dashboard(widget.projectId);
      } on ApiException {
        // The project remains usable when the optional dashboard is denied.
      }
      if (mounted) {
        setState(() {
          _project = results[0] as Map<String, dynamic>;
          _progress = results[1] as Map<String, dynamic>;
          _members = results[2] as List<Map<String, dynamic>>;
          _dashboard = dashboard;
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Impossible de charger le projet.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _service.users();
      if (mounted) setState(() => _users = users);
    } on ApiException catch (error) {
      showAppError(error.message);
    }
  }

  Future<void> _addMember() async {
    if (_users.isEmpty) await _loadUsers();
    if (!mounted || _users.isEmpty) return;
    final strings = AppLocalizations.of(context);
    String? userId;
    String role = 'contributor';
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(strings.addMemberTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: strings.collaborator),
                items: _users.map((user) {
                  final id = user['id']?.toString() ?? '';
                  final name = _userName(user);
                  return DropdownMenuItem(value: id, child: Text(name));
                }).toList(),
                onChanged: (value) => setDialogState(() => userId = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: InputDecoration(labelText: strings.roleInProject),
                items: [
                  DropdownMenuItem(
                    value: 'manager',
                    child: Text(strings.managerRole),
                  ),
                  DropdownMenuItem(
                    value: 'reviewer',
                    child: Text(strings.reviewerRole),
                  ),
                  DropdownMenuItem(
                    value: 'contributor',
                    child: Text(strings.contributorRole),
                  ),
                  DropdownMenuItem(
                    value: 'observer',
                    child: Text(strings.observerRole),
                  ),
                ],
                onChanged: (value) =>
                    setDialogState(() => role = value ?? 'contributor'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => userId == null
                  ? null
                  : Navigator.pop(context, {'user_id': userId!, 'role': role}),
              child: Text(strings.add),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    setState(() => _actionLoading = true);
    try {
      await _service.addMember(
        widget.projectId,
        result['user_id']!,
        result['role']!,
      );
      showAppSuccess(strings.memberAdded);
      await _load();
    } on ApiException catch (error) {
      showAppError(error.message);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _removeMember(Map<String, dynamic> member) async {
    final memberId = member['id']?.toString();
    if (memberId == null) return;
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.removeMemberTitle),
        content: Text(strings.removeMemberMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.removeLabel),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.removeMember(widget.projectId, memberId);
      showAppSuccess(strings.memberRemoved);
      await _load();
    } on ApiException catch (error) {
      showAppError(error.message);
    }
  }

  Future<void> _updateMemberRole(Map<String, dynamic> member) async {
    final memberId = member['id']?.toString();
    if (memberId == null) return;
    final strings = AppLocalizations.of(context);
    final current = member['role']?.toString() ?? 'contributor';
    final role = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(strings.memberRoleTitle),
        children: <String>['manager', 'reviewer', 'contributor', 'observer']
            .map(
              (value) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, value),
                child: Row(
                  children: [
                    if (value == current)
                      const Icon(Iconsax.tick_circle, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      {
                        'manager': strings.managerRole,
                        'reviewer': strings.reviewerRole,
                        'contributor': strings.contributorRole,
                        'observer': strings.observerRole,
                      }[value]!,
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
    if (role == null || role == current) return;
    try {
      await _service.updateMember(widget.projectId, memberId, role);
      showAppSuccess(strings.roleUpdated);
      await _load();
    } on ApiException catch (error) {
      showAppError(error.message);
    }
  }

  static String _userName(Map<String, dynamic> user) {
    final fullName = user['full_name']?.toString();
    if (fullName != null && fullName.isNotEmpty) return fullName;
    return '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
  }

  List<String> _allowedProjectTransitions(Map<String, dynamic> project) {
    final workflow = project['workflow'];
    if (workflow is Map && workflow['allowed_status_transitions'] is List) {
      return (workflow['allowed_status_transitions'] as List)
          .map((value) => value.toString())
          .toList();
    }
    return const [];
  }

  Future<void> _changeStatus(String status) async {
    try {
      final project = await _service.changeStatus(widget.projectId, status);
      if (mounted) {
        setState(() => _project = project);
        showAppSuccess(AppLocalizations.of(context).projectStatusUpdated);
      }
      await _load();
    } on ApiException catch (error) {
      showAppError(error.message);
    }
  }

  Future<void> _delete() async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deleteProjectTitle),
        content: Text(strings.irreversibleAction),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.remove(widget.projectId);
      if (mounted) {
        Navigator.pop(context);
        showAppSuccess(AppLocalizations.of(context).projectDeleted);
      }
    } on ApiException catch (error) {
      showAppError(error.message);
    }
  }

  Future<void> _editProject() async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProjectForm(
        initial: _project,
        onSubmit: (body) async {
          await _service.update(widget.projectId, body);
          if (mounted) {
            Navigator.pop(context, true);
            showAppSuccess(AppLocalizations.of(context).projectUpdated);
          }
        },
      ),
    );
    if (updated == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final project = _project;
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(project?['name']?.toString() ?? 'Projet'),
        actions: [
          if (project?['status'] != 'cancelled' &&
              project?['can_delete'] == true)
            IconButton(
              tooltip: 'Supprimer',
              onPressed: _delete,
              icon: const Icon(Iconsax.trash),
            ),
          if (project?['status'] != 'cancelled' &&
              project?['can_update'] == true)
            IconButton(
              tooltip: 'Modifier',
              onPressed: _editProject,
              icon: const Icon(Iconsax.edit),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                children: const [_ProjectDetailSkeleton()],
              )
            : _error != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _ProjectsState(
                    icon: Iconsax.danger,
                    title: strings.loadingError,
                    message: _error!,
                    action: TextButton.icon(
                      onPressed: _load,
                      icon: const Icon(Iconsax.refresh),
                      label: Text(strings.retry),
                    ),
                  ),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                children: [
                  _ProjectHero(project: project!, progress: _progress),
                  const SizedBox(height: 16),
                  if (project['status'] != 'cancelled' &&
                      project['can_change_status'] == true)
                    _StatusActions(
                      status: project['status']?.toString() ?? 'planned',
                      allowedStatuses: _allowedProjectTransitions(project),
                      onStatus: _changeStatus,
                    ),
                  const SizedBox(height: 16),
                  _ProjectSection(
                    title: strings.team,
                    icon: Iconsax.people,
                    trailing:
                        project['status'] != 'cancelled' &&
                            project['can_manage_members'] == true
                        ? IconButton(
                            tooltip: 'Ajouter un membre',
                            onPressed: _actionLoading ? null : _addMember,
                            icon: const Icon(Iconsax.user_add),
                          )
                        : null,
                    child: _members.isEmpty
                        ? Text(strings.noMembers)
                        : Column(
                            children: _members
                                .map(
                                  (member) => _MemberRow(
                                    member: member,
                                    canManage:
                                        project['status'] != 'cancelled' &&
                                        project['can_manage_members'] == true,
                                    onEdit: () => _updateMemberRole(member),
                                    onRemove: () => _removeMember(member),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 12),
                  if (_dashboard != null) ...[
                    _ProjectDashboardSection(data: _dashboard!),
                    const SizedBox(height: 12),
                  ],
                  if (project['closure_report_status'] != null ||
                      project['can_submit_closure_report'] == true ||
                      project['can_validate_closure_report'] == true ||
                      project['can_reject_closure_report'] == true) ...[
                    _ClosureReportSection(
                      project: project,
                      service: _service,
                      projectId: widget.projectId,
                      onChanged: _load,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _ProjectSection(
                    title: strings.projectModules,
                    icon: Iconsax.element_4,
                    child: Column(
                      children: [
                        _ProjectModuleButton(
                          icon: Iconsax.task_square,
                          title: strings.tasks,
                          subtitle: strings.progress,
                          onTap: () => _openModule(
                            title: strings.tasks,
                            endpoint: '/tasks?project_id=${widget.projectId}',
                            createEndpoint: '/tasks',
                            kind: ProjectModuleKind.tasks,
                            canCreate:
                                project['can_assign_project_tasks'] == true ||
                                project['can_create_project_self_task'] == true,
                            canManage: project['can_update'] == true,
                            readOnly: project['status'] == 'cancelled',
                            selfOnly:
                                project['can_create_project_self_task'] ==
                                    true &&
                                project['can_assign_project_tasks'] != true,
                          ),
                        ),
                        _ProjectModuleButton(
                          icon: Iconsax.flag,
                          title: strings.milestones,
                          subtitle: strings.milestonesDescription,
                          onTap: () => _openModule(
                            title: strings.milestones,
                            endpoint:
                                '/projects/${widget.projectId}/milestones',
                            createEndpoint:
                                '/projects/${widget.projectId}/milestones',
                            kind: ProjectModuleKind.milestones,
                            canCreate: project['can_update'] == true,
                            canManage: project['can_update'] == true,
                            readOnly: project['status'] == 'cancelled',
                          ),
                        ),
                        _ProjectModuleButton(
                          icon: Iconsax.box,
                          title: strings.deliverables,
                          subtitle: strings.deliverablesDescription,
                          onTap: () => _openModule(
                            title: strings.deliverables,
                            endpoint:
                                '/projects/${widget.projectId}/deliverables',
                            createEndpoint:
                                '/projects/${widget.projectId}/deliverables',
                            kind: ProjectModuleKind.deliverables,
                            canCreate: project['can_update'] == true,
                            canManage: project['can_update'] == true,
                            readOnly: project['status'] == 'cancelled',
                          ),
                        ),
                        _ProjectModuleButton(
                          icon: Iconsax.danger,
                          title: strings.attentionPoints,
                          subtitle: strings.attentionPointsDescription,
                          onTap: () => _openModule(
                            title: strings.attentionPoints,
                            endpoint:
                                '/projects/${widget.projectId}/register-items',
                            createEndpoint:
                                '/projects/${widget.projectId}/register-items',
                            kind: ProjectModuleKind.registerItems,
                            canCreate: project['can_update'] == true,
                            canManage: project['can_update'] == true,
                            readOnly: project['status'] == 'cancelled',
                          ),
                        ),
                        _ProjectModuleButton(
                          icon: Iconsax.timer,
                          title: strings.timeAndBudget,
                          subtitle: strings.loggedProjectTime,
                          onTap: () => _openModule(
                            title: strings.timeAndBudget,
                            endpoint: '/projects/${widget.projectId}/work-logs',
                            createEndpoint:
                                '/projects/${widget.projectId}/work-logs',
                            kind: ProjectModuleKind.workLogs,
                            canCreate: project['can_update'] == true,
                            canManage: project['can_update'] == true,
                            readOnly: project['status'] == 'cancelled',
                          ),
                        ),
                        _ProjectModuleButton(
                          icon: Iconsax.refresh_2,
                          title: strings.projectActivity,
                          subtitle: strings.actionHistory,
                          onTap: () => _openModule(
                            title: strings.projectActivity,
                            endpoint: '/projects/${widget.projectId}/timeline',
                            kind: ProjectModuleKind.activity,
                            canCreate: false,
                            canManage: false,
                            readOnly: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _openModule({
    required String title,
    required String endpoint,
    required ProjectModuleKind kind,
    String? createEndpoint,
    bool canCreate = true,
    bool canManage = true,
    bool readOnly = false,
    bool selfOnly = false,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectModulePage(
          session: widget.session,
          projectId: widget.projectId,
          title: title,
          endpoint: endpoint,
          createEndpoint: createEndpoint,
          kind: kind,
          canCreate: canCreate,
          canManage: canManage,
          readOnly: readOnly,
          selfOnly: selfOnly,
        ),
      ),
    );
  }
}

enum ProjectModuleKind {
  tasks,
  milestones,
  deliverables,
  registerItems,
  workLogs,
  activity,
}

class _ProjectModuleButton extends StatelessWidget {
  const _ProjectModuleButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(icon),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(subtitle),
    trailing: const Icon(Iconsax.arrow_right),
    onTap: onTap,
  );
}

class ProjectModulePage extends StatefulWidget {
  const ProjectModulePage({
    super.key,
    required this.session,
    required this.projectId,
    required this.title,
    required this.endpoint,
    required this.kind,
    this.createEndpoint,
    this.canCreate = true,
    this.canManage = true,
    this.readOnly = false,
    this.selfOnly = false,
  });

  final AuthSession session;
  final String projectId;
  final String title;
  final String endpoint;
  final String? createEndpoint;
  final ProjectModuleKind kind;
  final bool canCreate;
  final bool canManage;
  final bool readOnly;
  final bool selfOnly;

  @override
  State<ProjectModulePage> createState() => _ProjectModulePageState();
}

class _ProjectModulePageState extends State<ProjectModulePage> {
  late final ProjectService _service;
  List<Map<String, dynamic>> _items = const [];
  List<Map<String, dynamic>> _members = const [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = ProjectService(
      apiClient: ApiClient(accessToken: widget.session.token),
    );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _service.nested(widget.endpoint);
      var members = _members;
      if (widget.kind == ProjectModuleKind.tasks) {
        members = await _service.members(widget.projectId);
      }
      if (mounted) {
        setState(() {
          _items = items;
          _members = members;
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    if (widget.createEndpoint == null || _saving) return;
    final body = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => widget.kind == ProjectModuleKind.tasks
          ? _TaskForm(
              members: _members,
              forcedAssignee: widget.selfOnly
                  ? widget.session.user['id']?.toString()
                  : null,
            )
          : _ModuleForm(kind: widget.kind),
    );
    if (body == null) return;
    setState(() => _saving = true);
    try {
      await _service.createNested(widget.createEndpoint!, {
        ...body,
        if (widget.kind == ProjectModuleKind.tasks)
          'project_id': widget.projectId,
        if (widget.kind == ProjectModuleKind.workLogs)
          'user_id': widget.session.user['id'],
      });
      showAppSuccess('Element ajoute.');
      await _load();
    } on ApiException catch (error) {
      showAppError(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _itemPath(String id) {
    if (widget.kind == ProjectModuleKind.tasks) return '/tasks/$id';
    return '${widget.endpoint}/$id';
  }

  Future<void> _edit(Map<String, dynamic> item) async {
    final id = item['id']?.toString();
    if (id == null) return;
    final body = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => widget.kind == ProjectModuleKind.tasks
          ? _TaskForm(
              members: _members,
              initial: item,
              forcedAssignee: widget.selfOnly
                  ? widget.session.user['id']?.toString()
                  : null,
            )
          : _ModuleForm(kind: widget.kind, initial: item),
    );
    if (body == null) return;
    try {
      await _service.updateNested(_itemPath(id), body);
      showAppSuccess('Element mis a jour.');
      await _load();
    } on ApiException catch (error) {
      showAppError(error.message);
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final id = item['id']?.toString();
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cet element ?'),
        content: const Text('Cette action est irreversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteNested(_itemPath(id));
      showAppSuccess('Element supprime.');
      await _load();
    } on ApiException catch (error) {
      showAppError(error.message);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    floatingActionButton:
        widget.createEndpoint == null || !widget.canCreate || widget.readOnly
        ? null
        : FloatingActionButton.extended(
            onPressed: _saving ? null : _create,
            icon: const Icon(Iconsax.add),
            label: const Text('Ajouter'),
          ),
    body: RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
              children: const [_ProjectModuleSkeleton()],
            )
          : _error != null
          ? ListView(
              children: [
                _ProjectsState(
                  icon: Iconsax.danger,
                  title: 'Chargement impossible',
                  message: _error!,
                  action: TextButton.icon(
                    onPressed: _load,
                    icon: const Icon(Iconsax.refresh),
                    label: const Text('Reessayer'),
                  ),
                ),
              ],
            )
          : _items.isEmpty
          ? ListView(
              children: [
                _ProjectsState(
                  icon: Iconsax.archive,
                  title: 'Aucun element',
                  message: 'Les donnees de ce module apparaitront ici.',
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, index) => _ModuleRow(
                item: _items[index],
                kind: widget.kind,
                onEdit:
                    widget.canManage &&
                        !widget.readOnly &&
                        (widget.kind != ProjectModuleKind.tasks ||
                            _items[index]['can_edit'] == true)
                    ? () => _edit(_items[index])
                    : null,
                onDelete:
                    widget.canManage &&
                        !widget.readOnly &&
                        (widget.kind != ProjectModuleKind.tasks ||
                            _items[index]['can_delete'] == true)
                    ? () => _delete(_items[index])
                    : null,
                onOpen: widget.kind == ProjectModuleKind.tasks
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProjectTaskDetailsPage(
                            session: widget.session,
                            taskId: _items[index]['id'].toString(),
                            readOnly: widget.readOnly,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
    ),
  );
}

class _TaskForm extends StatefulWidget {
  const _TaskForm({required this.members, this.initial, this.forcedAssignee});

  final List<Map<String, dynamic>> members;
  final Map<String, dynamic>? initial;
  final String? forcedAssignee;

  @override
  State<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<_TaskForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _period = TextEditingController();
  String? _assignedTo;
  String _priority = 'medium';
  String _status = 'todo';
  DateTime? _start;
  DateTime? _end;
  final _subtasks = <String>[];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _title.text = initial?['title']?.toString() ?? '';
    _description.text = initial?['description']?.toString() ?? '';
    _assignedTo = widget.forcedAssignee ?? initial?['assigned_to']?.toString();
    _priority = initial?['priority']?.toString() ?? 'medium';
    _status = initial?['status']?.toString() ?? 'todo';
    final rawSubtasks = initial?['subtasks'];
    if (rawSubtasks is List) {
      _subtasks.addAll(
        rawSubtasks
            .whereType<Map>()
            .map((item) => item['title']?.toString() ?? '')
            .where((title) => title.isNotEmpty),
      );
    }
    _start = _parseDate(initial?['start_date']);
    _end = _parseDate(initial?['due_date']);
    if (_start != null && _end != null) {
      _period.text = _formatPeriod(_start!, _end!);
    }
  }

  DateTime? _parseDate(dynamic value) => value == null
      ? null
      : DateTime.tryParse(value.toString().replaceFirst(' ', 'T'));

  String _formatPeriod(DateTime start, DateTime end) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(start.day)}/${two(start.month)}/${start.year} ${two(start.hour)}:${two(start.minute)} - ${two(end.day)}/${two(end.month)}/${end.year} ${two(end.hour)}:${two(end.minute)}';
  }

  String _apiDate(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} ${two(value.hour)}:${two(value.minute)}';
  }

  Future<void> _pickPeriod() async {
    final strings = AppLocalizations.of(context);
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _start != null && _end != null
          ? DateTimeRange(start: _start!, end: _end!)
          : null,
      helpText: strings.taskPeriod,
      saveText: strings.continueLabel,
      cancelText: strings.cancel,
    );
    if (range == null || !mounted) return;
    final startTime = await showTimePicker(
      context: context,
      initialTime: _start == null
          ? TimeOfDay.fromDateTime(now)
          : TimeOfDay.fromDateTime(_start!),
      helpText: strings.startTime,
    );
    if (startTime == null || !mounted) return;
    final endTime = await showTimePicker(
      context: context,
      initialTime: _end == null
          ? TimeOfDay.fromDateTime(now)
          : TimeOfDay.fromDateTime(_end!),
      helpText: strings.endTime,
    );
    if (endTime == null) return;
    final start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
      startTime.hour,
      startTime.minute,
    );
    final end = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      endTime.hour,
      endTime.minute,
    );
    if (!end.isAfter(start)) {
      showAppError(strings.invalidDateRange);
      return;
    }
    setState(() {
      _start = start;
      _end = end;
      _period.text = _formatPeriod(start, end);
    });
  }

  Future<void> _addSubtask() async {
    final strings = AppLocalizations.of(context);
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.addSubtask),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: strings.title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(strings.add),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value.trim().isNotEmpty) {
      setState(() => _subtasks.add(value.trim()));
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_start == null || _end == null) {
      showAppError(AppLocalizations.of(context).datesRequired);
      return;
    }
    setState(() => _saving = true);
    try {
      Navigator.pop(context, {
        'assigned_to': _assignedTo,
        'title': _title.text.trim(),
        'description': _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        'priority': _priority,
        'status': _status,
        'start_date': _apiDate(_start!),
        'due_date': _apiDate(_end!),
        'subtasks': _subtasks
            .asMap()
            .entries
            .map(
              (entry) => {
                'id': 'subtask-${entry.key}',
                'title': entry.value,
                'completed': false,
              },
            )
            .toList(),
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _memberName(Map<String, dynamic> member) {
    final user = member['user'] is Map
        ? Map<String, dynamic>.from(member['user'] as Map)
        : member;
    return user['full_name']?.toString() ??
        '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _period.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Padding(
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
                widget.initial == null ? strings.newTask : strings.editTask,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _title,
                decoration: InputDecoration(labelText: strings.title),
                validator: (value) => value == null || value.trim().isEmpty
                    ? strings.requiredField
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: strings.description,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              if (widget.forcedAssignee == null)
                DropdownButtonFormField<String>(
                  initialValue: _assignedTo,
                  decoration: InputDecoration(labelText: strings.assignTo),
                  items: widget.members
                      .map((member) {
                        final user = member['user'] is Map
                            ? member['user'] as Map
                            : member;
                        final id =
                            user['id']?.toString() ??
                            member['user_id']?.toString() ??
                            '';
                        return DropdownMenuItem(
                          value: id,
                          child: Text(_memberName(member)),
                        );
                      })
                      .where((item) => item.value != '')
                      .toList(),
                  validator: (value) => value == null || value.isEmpty
                      ? strings.requiredField
                      : null,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _assignedTo = value),
                )
              else
                InputDecorator(
                  decoration: InputDecoration(labelText: strings.assignTo),
                  child: Text(
                    _memberName(
                      widget.members.firstWhere((member) {
                        final user = member['user'] is Map
                            ? member['user'] as Map
                            : member;
                        return user['id']?.toString() ==
                                widget.forcedAssignee ||
                            member['user_id']?.toString() ==
                                widget.forcedAssignee;
                      }, orElse: () => {'full_name': 'Moi'}),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _priority,
                      decoration: InputDecoration(labelText: strings.priority),
                      items: [
                        DropdownMenuItem(
                          value: 'low',
                          child: Text(strings.low),
                        ),
                        DropdownMenuItem(
                          value: 'medium',
                          child: Text(strings.medium),
                        ),
                        DropdownMenuItem(
                          value: 'high',
                          child: Text(strings.high),
                        ),
                        DropdownMenuItem(
                          value: 'urgent',
                          child: Text(strings.urgent),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _priority = value ?? 'medium'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: InputDecoration(labelText: strings.status),
                      items: [
                        DropdownMenuItem(
                          value: 'todo',
                          child: Text(strings.todo),
                        ),
                        DropdownMenuItem(
                          value: 'in_progress',
                          child: Text(strings.inProgress),
                        ),
                        DropdownMenuItem(
                          value: 'review',
                          child: Text(strings.inReview),
                        ),
                        DropdownMenuItem(
                          value: 'done',
                          child: Text(strings.completed),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _status = value ?? 'todo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _period,
                readOnly: true,
                onTap: _saving ? null : _pickPeriod,
                decoration: InputDecoration(
                  labelText: strings.projectPeriod,
                  hintText: strings.selectDates,
                  suffixIcon: Icon(Iconsax.calendar),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? strings.datesRequired
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.subtasks,
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _saving ? null : _addSubtask,
                    icon: const Icon(Iconsax.add),
                    label: Text(strings.add),
                  ),
                ],
              ),
              if (_subtasks.isEmpty)
                Text(
                  strings.noSubtasks,
                  style: TextStyle(color: Color(0xff64748b)),
                )
              else
                ..._subtasks.asMap().entries.map(
                  (entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Iconsax.arrow_right_3),
                    title: Text(entry.value),
                    trailing: IconButton(
                      onPressed: _saving
                          ? null
                          : () => setState(() => _subtasks.removeAt(entry.key)),
                      icon: const Icon(Iconsax.trash),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: Text(
                  widget.initial == null ? 'Creer la tache' : 'Enregistrer',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProjectTaskDetailsPage extends StatefulWidget {
  const ProjectTaskDetailsPage({
    super.key,
    required this.session,
    required this.taskId,
    this.readOnly = false,
  });

  final AuthSession session;
  final String taskId;
  final bool readOnly;

  @override
  State<ProjectTaskDetailsPage> createState() => _ProjectTaskDetailsPageState();
}

class _ProjectTaskDetailsPageState extends State<ProjectTaskDetailsPage> {
  late final TaskService _service;
  late final ProjectService _projectService;
  Map<String, dynamic>? _task;
  List<Map<String, dynamic>> _comments = const [];
  List<Map<String, dynamic>> _files = const [];
  int _commentsPage = 1;
  int _commentsLastPage = 1;
  int _filesPage = 1;
  int _filesLastPage = 1;
  bool _loadingMoreFiles = false;
  bool _loading = true;
  bool _saving = false;
  bool _uploadingFile = false;
  String? _downloadingId;
  String? _error;
  String? _closureFilePath;
  List<String> _commentFilePaths = const [];
  final _comment = TextEditingController();
  final _closure = TextEditingController();

  @override
  void initState() {
    super.initState();
    _service = TaskService(
      apiClient: ApiClient(accessToken: widget.session.token),
    );
    _projectService = ProjectService(
      apiClient: ApiClient(accessToken: widget.session.token),
    );
    _load();
  }

  @override
  void dispose() {
    _comment.dispose();
    _closure.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.show(widget.taskId),
        _service.fetchCommentsPage(widget.taskId, perPage: 5),
        _service.fetchFilesPage(widget.taskId),
      ]);
      if (mounted) {
        final commentsPage = results[1] as TaskRelatedPage;
        final filesPage = results[2] as TaskRelatedPage;
        setState(() {
          _task = results[0] as Map<String, dynamic>;
          _comments = commentsPage.items;
          _commentsPage = commentsPage.page;
          _commentsLastPage = commentsPage.lastPage;
          _files = filesPage.items;
          _filesPage = filesPage.page;
          _filesLastPage = filesPage.lastPage;
        });
        unawaited(
          Future.wait(
            _comments
                .map((comment) => comment['id']?.toString())
                .whereType<String>()
                .map(_service.markCommentRead),
          ),
        );
      }
      try {
        await _service.markRead(widget.taskId);
      } on ApiException {
        // Reading a task must not prevent its details from being displayed.
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openCommentsPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskCommentsPage(
          session: widget.session,
          taskId: widget.taskId,
          taskTitle: _task?['title']?.toString() ?? 'Tache',
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _loadMoreFiles() async {
    if (_loadingMoreFiles || _filesPage >= _filesLastPage) return;
    setState(() => _loadingMoreFiles = true);
    try {
      final page = await _service.fetchFilesPage(
        widget.taskId,
        page: _filesPage + 1,
      );
      if (mounted) {
        setState(() {
          _files = [..._files, ...page.items];
          _filesPage = page.page;
          _filesLastPage = page.lastPage;
        });
      }
    } on ApiException catch (error) {
      showAppError(error.message);
    } finally {
      if (mounted) setState(() => _loadingMoreFiles = false);
    }
  }

  Future<void> _status(String status) async {
    if (widget.readOnly || _task?['can_change_status'] != true) return;
    try {
      await _service.changeStatus(widget.taskId, status);
      showAppSuccess('Statut mis a jour.');
      await _load();
    } on ApiException catch (error) {
      showAppError(error.message);
    }
  }

  Future<void> _acceptAssignment() async {
    if (widget.readOnly || _saving || _task?['can_accept_assignment'] != true) {
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.acceptAssignment(widget.taskId);
      showAppSuccess('Affectation acceptee.');
      await _load();
    } on ApiException catch (error) {
      showAppError(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _declineAssignment() async {
    if (widget.readOnly ||
        _saving ||
        _task?['can_decline_assignment'] != true) {
      return;
    }
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser l affectation'),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Motif'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (note == null || note.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await _service.declineAssignment(widget.taskId, note.trim());
      showAppSuccess('Affectation refusee.');
      await _load();
    } on ApiException catch (error) {
      showAppError(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleSubtask(int index) async {
    if (widget.readOnly || _task?['can_manage_subtasks'] != true) return;
    final current =
        (_task?['subtasks'] as List?)
            ?.whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList() ??
        [];
    if (index >= current.length) return;
    current[index]['completed'] = current[index]['completed'] != true;
    try {
      await _service.update(widget.taskId, {'subtasks': current});
      await _load();
    } on ApiException catch (error) {
      showAppError(error.message);
    }
  }

  bool _canEditTask(Map<String, dynamic> task) {
    return !widget.readOnly &&
        task['can_edit'] == true &&
        task['created_by']?.toString() ==
            widget.session.user['id']?.toString() &&
        task['status'] == 'todo';
  }

  bool _canStartTask(Map<String, dynamic> task) {
    if (widget.readOnly || task['can_change_status'] != true) return false;
    final workflow = task['workflow'];
    return task['can_start'] == true ||
        (workflow is Map && workflow['can_start'] == true);
  }

  Future<void> _addSubtask() async {
    if (widget.readOnly || _task?['can_manage_subtasks'] != true) {
      return;
    }
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une sous-tache'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Titre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.trim().isEmpty) return;
    final subtasks =
        (_task?['subtasks'] as List?)
            ?.whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList() ??
        [];
    subtasks.add({
      'id': 'subtask-${DateTime.now().microsecondsSinceEpoch}',
      'title': title.trim(),
      'completed': false,
    });
    setState(() => _saving = true);
    try {
      await _service.update(widget.taskId, {'subtasks': subtasks});
      showAppSuccess('Sous-tache ajoutee.');
      await _load();
    } on ApiException catch (error) {
      showAppError(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _updatePriority(String priority) async {
    if (widget.readOnly || _task == null || _task!['can_edit'] != true) return;
    setState(() => _saving = true);
    try {
      await _service.update(widget.taskId, {'priority': priority});
      showAppSuccess('Priorite mise a jour.');
      await _load();
    } on ApiException catch (error) {
      showAppError(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _choosePriority() async {
    if (!_canEditTask(_task ?? const {})) return;
    const options = {
      'low': 'Basse',
      'medium': 'Moyenne',
      'high': 'Haute',
      'urgent': 'Urgente',
    };
    final value = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Priorite'),
        children: options.entries
            .map(
              (entry) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, entry.key),
                child: Text(entry.value),
              ),
            )
            .toList(),
      ),
    );
    if (value != null && value != _task?['priority']) {
      await _updatePriority(value);
    }
  }

  Map<String, dynamic> _assignmentUser(Map<String, dynamic> item) {
    final nested = item['user'];
    return nested is Map ? Map<String, dynamic>.from(nested) : item;
  }

  String _assignmentUserLabel(Map<String, dynamic> item) {
    final user = _assignmentUser(item);
    final fullName = user['full_name']?.toString();
    if (fullName != null && fullName.trim().isNotEmpty) return fullName;
    final name = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'
        .trim();
    return name.isEmpty ? (user['email']?.toString() ?? 'Utilisateur') : name;
  }

  Future<void> _openAssignmentSheet() async {
    final task = _task;
    if (widget.readOnly || task?['can_assign'] != true) return;
    final projectId = task?['project_id']?.toString();
    final usersFuture = projectId == null || projectId.isEmpty
        ? _projectService.users()
        : _projectService.members(projectId);
    final selectedUserId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => FutureBuilder<List<Map<String, dynamic>>>(
        future: usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return const SizedBox(
              height: 180,
              child: Center(
                child: Text('Impossible de charger les utilisateurs.'),
              ),
            );
          }
          final users = snapshot.data ?? const <Map<String, dynamic>>[];
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * .65,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Text(
                      'Réassigner la tâche',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    child: users.isEmpty
                        ? const Center(
                            child: Text('Aucun utilisateur disponible.'),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                            itemCount: users.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (_, index) {
                              final item = users[index];
                              final user = _assignmentUser(item);
                              final id =
                                  user['id']?.toString() ??
                                  item['user_id']?.toString();
                              if (id == null || id.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              final isCurrent =
                                  id == task?['assigned_to']?.toString();
                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text(
                                    _assignmentUserLabel(
                                      item,
                                    ).trim().substring(0, 1).toUpperCase(),
                                  ),
                                ),
                                title: Text(_assignmentUserLabel(item)),
                                subtitle: user['email'] == null
                                    ? null
                                    : Text(user['email'].toString()),
                                trailing: isCurrent
                                    ? const Icon(
                                        Iconsax.tick_circle,
                                        color: Color(0xff2563eb),
                                      )
                                    : null,
                                onTap: () => Navigator.of(sheetContext).pop(id),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (selectedUserId == null ||
        selectedUserId == task?['assigned_to']?.toString()) {
      return;
    }
    await _assignTask(selectedUserId);
  }

  Future<void> _assignTask(String userId) async {
    if (widget.readOnly || _task?['can_assign'] != true || _saving) return;
    final strings = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await _service.assignUser(widget.taskId, userId);
      showAppSuccess(strings.taskReassigned);
      await _load();
    } on ApiException catch (error) {
      showAppError(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteTask() async {
    if (widget.readOnly || _task?['can_delete'] != true || _saving) return;
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deleteTaskTitle),
        content: Text(strings.irreversibleAction),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    try {
      await _service.deleteTask(widget.taskId);
      showAppSuccess(strings.taskDeleted);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (error) {
      showAppError(error.message);
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editTask() async {
    final task = _task;
    if (task == null || !_canEditTask(task)) return;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _TaskEditDialog(task: task),
    );
    if (result == null) return;
    setState(() => _saving = true);
    try {
      await _service.update(widget.taskId, result);
      if (mounted) showAppSuccess(AppLocalizations.of(context).taskUpdated);
      await _load();
    } on ApiException catch (error) {
      showAppError(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editComment(Map<String, dynamic> comment) async {
    if (comment['can_update'] != true) return;
    final id = comment['id']?.toString();
    if (id == null) return;
    final strings = AppLocalizations.of(context);
    final controller = TextEditingController(
      text: comment['comment']?.toString() ?? comment['body']?.toString() ?? '',
    );
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.editComment),
        content: TextField(controller: controller, minLines: 2, maxLines: 5),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(strings.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.trim().isEmpty) return;
    try {
      await _service.updateComment(id, value.trim());
      showAppSuccess(strings.commentUpdated);
      await _load();
    } on ApiException catch (error) {
      showAppError(error.message);
    }
  }

  Future<void> _deleteComment(Map<String, dynamic> comment) async {
    if (comment['can_delete'] != true) return;
    final id = comment['id']?.toString();
    if (id == null) return;
    final strings = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deleteCommentTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _service.deleteComment(id);
      showAppSuccess(strings.commentDeleted);
      await _load();
    } on ApiException catch (error) {
      showAppError(error.message);
    }
  }

  Future<void> _renameFile(Map<String, dynamic> file) async {
    if (file['can_update'] != true) return;
    final id = file['id']?.toString();
    if (id == null) return;
    final strings = AppLocalizations.of(context);
    final controller = TextEditingController(
      text: file['file_name']?.toString() ?? file['name']?.toString() ?? '',
    );
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.renameFile),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(strings.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.trim().isEmpty) return;
    try {
      await _service.updateFile(id, value.trim());
      showAppSuccess(strings.fileRenamed);
      await _load();
    } on ApiException catch (error) {
      showAppError(error.message);
    }
  }

  Future<void> _deleteFile(Map<String, dynamic> file) async {
    if (file['can_delete'] != true) return;
    final id = file['id']?.toString();
    if (id == null) return;
    final strings = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deleteFileTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _service.deleteFile(id);
      showAppSuccess(strings.fileDeleted);
      await _load();
    } on ApiException catch (error) {
      showAppError(error.message);
    }
  }

  Future<void> _downloadBytes({
    required String id,
    required String fileName,
    required Future<List<int>> Function() download,
    Future<void> Function()? markRead,
  }) async {
    if (_downloadingId != null) return;
    setState(() => _downloadingId = id);
    try {
      final bytes = await download();
      final path = await FilePicker.platform.saveFile(fileName: fileName);
      if (path == null || path.isEmpty) return;
      await File(path).writeAsBytes(bytes, flush: true);
      if (markRead != null) await markRead();
      showAppSuccess('Fichier telecharge.');
    } on ApiException catch (error) {
      showAppError(error.message);
    } on Exception catch (error) {
      showAppError('Telechargement impossible: $error');
    } finally {
      if (mounted) setState(() => _downloadingId = null);
    }
  }

  Future<void> _downloadTaskFile(Map<String, dynamic> file) async {
    final id = file['id']?.toString();
    if (id == null || id.isEmpty) return;
    final name = file['file_name']?.toString() ?? 'fichier';
    await _downloadBytes(
      id: id,
      fileName: name,
      download: () => _service.downloadTaskFile(id),
      markRead: () => _service.markFileRead(id),
    );
  }

  Future<void> _downloadCommentAttachment(
    Map<String, dynamic> comment,
    Map<String, dynamic> attachment,
  ) async {
    final attachmentId = attachment['id']?.toString();
    final commentId = comment['id']?.toString();
    if (attachmentId == null || attachmentId.isEmpty) return;
    await _downloadBytes(
      id: attachmentId,
      fileName: attachment['file_name']?.toString() ?? 'piece-jointe',
      download: () => _service.downloadCommentFile(attachmentId),
      markRead: commentId == null
          ? null
          : () => _service.markCommentRead(commentId),
    );
  }

  Future<void> _downloadClosureReport() async {
    final name = _task?['closure_report_file_name']?.toString();
    if (name == null || name.isEmpty) return;
    await _downloadBytes(
      id: 'closure-report',
      fileName: name,
      download: () => _service.downloadClosureReport(widget.taskId),
    );
  }

  Future<bool> _addComment() async {
    if (!canCommentForTask ||
        (_comment.text.trim().isEmpty && _commentFilePaths.isEmpty) ||
        _saving) {
      return false;
    }
    setState(() => _saving = true);
    try {
      if (_commentFilePaths.isEmpty) {
        await _service.addComment(widget.taskId, _comment.text.trim());
      } else {
        await _service.addCommentWithAttachments(
          widget.taskId,
          _comment.text.trim(),
          _commentFilePaths,
        );
      }
      _comment.clear();
      if (mounted) setState(() => _commentFilePaths = const []);
      showAppSuccess('Commentaire ajoute.');
      await _load();
      return true;
    } on ApiException catch (error) {
      showAppError(error.message);
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openCommentSheet() async {
    if (!canCommentForTask || _saving) return;
    _comment.clear();
    if (mounted) setState(() => _commentFilePaths = const []);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> pickFiles() async {
            final result = await FilePicker.platform.pickFiles(
              allowMultiple: true,
              withData: false,
            );
            final paths = result?.files
                .map((file) => file.path)
                .whereType<String>()
                .toList();
            if (paths == null || paths.isEmpty) return;
            if (mounted) setState(() => _commentFilePaths = paths);
            setSheetState(() {});
          }

          Future<void> submit() async {
            if (_comment.text.trim().isEmpty && _commentFilePaths.isEmpty) {
              return;
            }
            setSheetState(() {});
            final submitted = await _addComment();
            if (submitted && sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
            } else if (context.mounted) {
              setSheetState(() {});
            }
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              4,
              20,
              MediaQuery.viewInsetsOf(context).bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xffeaf2ff),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Iconsax.message_text,
                        color: Color(0xff2563eb),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ajouter un commentaire',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Partagez une information avec l equipe.',
                            style: TextStyle(
                              color: Color(0xff64748b),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fermer',
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Iconsax.close_circle),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _comment,
                  autofocus: true,
                  maxLines: 1,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Votre commentaire',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: Color(0xfff8fafc),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                  ),
                ),
                if (_commentFilePaths.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xfff1f5f9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Iconsax.attach_circle, size: 17),
                        const SizedBox(width: 8),
                        Text(
                          '${_commentFilePaths.length} piece(s) jointe(s)',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : pickFiles,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                        ),
                        icon: const Icon(Iconsax.attach_circle, size: 18),
                        label: const Text('Joindre'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _saving ? null : submit,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                        ),
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Iconsax.send_2, size: 18),
                        label: const Text('Envoyer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    _comment.clear();
    if (mounted) setState(() => _commentFilePaths = const []);
  }

  bool get canCommentForTask =>
      !widget.readOnly &&
      !['done', 'completed', 'cancelled'].contains(_task?['status']);

  Future<void> _uploadFile() async {
    if (widget.readOnly || _uploadingFile || _task?['can_add_file'] != true) {
      return;
    }
    final result = await FilePicker.platform.pickFiles(withData: false);
    final path = result?.files.single.path;
    if (path == null) return;
    setState(() => _uploadingFile = true);
    try {
      await _service.uploadFile(widget.taskId, path);
      showAppSuccess('Fichier ajoute.');
      await _load();
    } on ApiException catch (error) {
      showAppError(error.message);
    } finally {
      if (mounted) setState(() => _uploadingFile = false);
    }
  }

  Future<bool> _submitClosure() async {
    if (widget.readOnly ||
        _task?['can_submit_closure_report'] != true ||
        (_closure.text.trim().isEmpty && _closureFilePath == null) ||
        _saving) {
      return false;
    }
    setState(() => _saving = true);
    try {
      await _service.submitClosure(
        widget.taskId,
        _closure.text.trim(),
        filePath: _closureFilePath,
      );
      showAppSuccess('Rapport soumis.');
      _closure.clear();
      if (mounted) setState(() => _closureFilePath = null);
      await _load();
      return true;
    } on ApiException catch (error) {
      showAppError(error.message);
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openClosureSheet() async {
    if (widget.readOnly || _task?['can_submit_closure_report'] != true) {
      return;
    }
    _closure.clear();
    if (mounted) setState(() => _closureFilePath = null);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> pickFile() async {
            final result = await FilePicker.platform.pickFiles(withData: false);
            final path = result?.files.single.path;
            if (path == null) return;
            if (mounted) setState(() => _closureFilePath = path);
            setSheetState(() {});
          }

          Future<void> submit() async {
            if (_closure.text.trim().isEmpty && _closureFilePath == null) {
              return;
            }
            setSheetState(() {});
            final submitted = await _submitClosure();
            if (submitted && sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
            } else if (context.mounted) {
              setSheetState(() {});
            }
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              4,
              20,
              MediaQuery.viewInsetsOf(context).bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xffeaf2ff),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Iconsax.document_text,
                        color: Color(0xff2563eb),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ajouter le rapport de cloture',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Decrivez le travail realise et les resultats.',
                            style: TextStyle(
                              color: Color(0xff64748b),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fermer',
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Iconsax.close_circle),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _closure,
                  autofocus: true,
                  minLines: 5,
                  maxLines: 9,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Rapport',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: Color(0xfff8fafc),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xfff8fafc),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xffdbe3ef)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.attach_circle, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _closureFilePath == null
                              ? 'Aucun fichier joint'
                              : 'Fichier selectionne',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: _saving ? null : pickFile,
                        child: const Text('Parcourir'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _saving ? null : submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Iconsax.send_2, size: 18),
                  label: const Text('Soumettre le rapport'),
                ),
              ],
            ),
          );
        },
      ),
    );
    _closure.clear();
    if (mounted) setState(() => _closureFilePath = null);
  }

  DateTime? _taskDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString().replaceFirst(' ', 'T'));
  }

  String _apiDate(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} ${two(value.hour)}:${two(value.minute)}';
  }

  Future<void> _extendDueDate() async {
    final current = _taskDate(_task?['due_date']);
    if (widget.readOnly ||
        _saving ||
        _task?['can_extend_due_date'] != true ||
        current == null) {
      return;
    }
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(current.year, current.month, current.day),
      lastDate: DateTime(2100),
      initialDate: current,
      helpText: 'Nouvelle echeance',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      helpText: 'Heure de la nouvelle echeance',
    );
    if (time == null) return;
    final next = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (!next.isAfter(current)) {
      showAppError('La nouvelle echeance doit etre posterieure a l actuelle.');
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.update(widget.taskId, {'due_date': _apiDate(next)});
      showAppSuccess('Echeance prolongee.');
      await _load();
    } on ApiException catch (error) {
      showAppError(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _validateClosure() async {
    if (widget.readOnly || _task?['can_validate_closure_report'] != true) {
      return;
    }
    try {
      await _service.validateClosure(widget.taskId);
      showAppSuccess('Rapport valide.');
      await _load();
    } on ApiException catch (error) {
      showAppError(error.message);
    }
  }

  Future<void> _rejectClosure() async {
    if (widget.readOnly || _task?['can_reject_closure_report'] != true) return;
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Motif du rejet'),
        content: TextField(controller: controller, minLines: 2, maxLines: 4),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (note == null || note.trim().isEmpty) return;
    try {
      await _service.rejectClosure(widget.taskId, note.trim());
      showAppSuccess('Rapport rejete.');
      await _load();
    } on ApiException catch (error) {
      showAppError(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final task = _task;
    final canComment =
        !widget.readOnly &&
        !['done', 'completed', 'cancelled'].contains(task?['status']);
    final subtasks =
        (task?['subtasks'] as List?)
            ?.whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList() ??
        const <Map<String, dynamic>>[];
    final completedSubtasks = subtasks
        .where((item) => item['completed'] == true)
        .length;
    return Scaffold(
      appBar: AppBar(
        title: Text(task?['title']?.toString() ?? strings.taskEntity),
        actions: [
          if (task != null)
            PopupMenuButton<String>(
              tooltip: strings.tasks,
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _editTask();
                  case 'priority':
                    _choosePriority();
                  case 'assign':
                    _openAssignmentSheet();
                  case 'start':
                    _status('in_progress');
                  case 'extend':
                    _extendDueDate();
                  case 'comment':
                    _openCommentSheet();
                  case 'file':
                    _uploadFile();
                  case 'report':
                    _openClosureSheet();
                  case 'accept':
                    _acceptAssignment();
                  case 'decline':
                    _declineAssignment();
                  case 'validate_report':
                    _validateClosure();
                  case 'reject_report':
                    _rejectClosure();
                  case 'delete':
                    _deleteTask();
                }
              },
              itemBuilder: (_) => [
                if (_canEditTask(task))
                  PopupMenuItem(value: 'edit', child: Text(strings.editTask)),
                if (_canEditTask(task))
                  PopupMenuItem(
                    value: 'priority',
                    child: Text(strings.editPriority),
                  ),
                if (!widget.readOnly && task['can_assign'] == true)
                  PopupMenuItem(
                    value: 'assign',
                    child: Text(strings.reassignTask),
                  ),
                if (!widget.readOnly && _canStartTask(task))
                  PopupMenuItem(value: 'start', child: Text(strings.startTask)),
                if (!widget.readOnly && task['can_extend_due_date'] == true)
                  PopupMenuItem(
                    value: 'extend',
                    child: Text(strings.extendDueDate),
                  ),
                if (!widget.readOnly && canComment)
                  PopupMenuItem(
                    value: 'comment',
                    child: Text(strings.addComment),
                  ),
                if (!widget.readOnly && task['can_add_file'] == true)
                  PopupMenuItem(value: 'file', child: Text(strings.addFile)),
                if (!widget.readOnly &&
                    task['can_submit_closure_report'] == true)
                  PopupMenuItem(
                    value: 'report',
                    child: Text(strings.addReport),
                  ),
                if (!widget.readOnly && task['can_accept_assignment'] == true)
                  PopupMenuItem(
                    value: 'accept',
                    child: Text(strings.acceptAssignment),
                  ),
                if (!widget.readOnly && task['can_decline_assignment'] == true)
                  PopupMenuItem(
                    value: 'decline',
                    child: Text(strings.declineAssignment),
                  ),
                if (!widget.readOnly &&
                    task['can_validate_closure_report'] == true)
                  PopupMenuItem(
                    value: 'validate_report',
                    child: Text(strings.validateReport),
                  ),
                if (!widget.readOnly &&
                    task['can_reject_closure_report'] == true)
                  PopupMenuItem(
                    value: 'reject_report',
                    child: Text(strings.rejectReport),
                  ),
                if (!widget.readOnly && task['can_delete'] == true)
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(strings.deleteTask),
                  ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                children: const [_TaskDetailSkeleton()],
              )
            : _error != null
            ? ListView(
                children: [
                  _ProjectsState(
                    icon: Iconsax.danger,
                    title: strings.loadingError,
                    message: _error!,
                    action: TextButton.icon(
                      onPressed: _load,
                      icon: const Icon(Iconsax.refresh),
                      label: Text(strings.retry),
                    ),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                children: [
                  _TaskSummary(task: task!),
                  const SizedBox(height: 14),
                  _ProjectSection(
                    title:
                        '${strings.subtasks} $completedSubtasks/${subtasks.length}',
                    icon: Iconsax.task_square,
                    trailing:
                        task['can_manage_subtasks'] == true && !widget.readOnly
                        ? FilledButton.icon(
                            onPressed: _saving ? null : _addSubtask,
                            icon: const Icon(Iconsax.add, size: 17),
                            label: Text(strings.add),
                          )
                        : null,
                    child: subtasks.isEmpty
                        ? Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              strings.noSubtasks,
                              style: TextStyle(color: Color(0xff64748b)),
                            ),
                          )
                        : Column(
                            children: subtasks
                                .asMap()
                                .entries
                                .map(
                                  (entry) => CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    visualDensity: VisualDensity.compact,
                                    value: entry.value['completed'] == true,
                                    onChanged:
                                        !widget.readOnly &&
                                            task['can_manage_subtasks'] == true
                                        ? (_) => _toggleSubtask(entry.key)
                                        : null,
                                    title: Text(
                                      entry.value['title']?.toString() ??
                                          'Sous-tache',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  if (_files.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _ProjectSection(
                      title: '${strings.files} ${_files.length}',
                      icon: Iconsax.attach_circle,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ..._files.map(
                            (file) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              onTap: _downloadingId == file['id']?.toString()
                                  ? null
                                  : () => _downloadTaskFile(file),
                              leading: _downloadingId == file['id']?.toString()
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Iconsax.document_text),
                              title: Text(
                                file['file_name']?.toString() ??
                                    file['name']?.toString() ??
                                    strings.files,
                              ),
                              trailing:
                                  file['can_update'] == true ||
                                      file['can_delete'] == true
                                  ? PopupMenuButton<String>(
                                      onSelected: (value) => value == 'rename'
                                          ? _renameFile(file)
                                          : _deleteFile(file),
                                      itemBuilder: (_) => [
                                        if (file['can_update'] == true)
                                          PopupMenuItem(
                                            value: 'rename',
                                            child: Text(strings.rename),
                                          ),
                                        if (file['can_delete'] == true)
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text(strings.delete),
                                          ),
                                      ],
                                    )
                                  : null,
                            ),
                          ),
                          if (_filesPage < _filesLastPage)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _loadingMoreFiles
                                    ? null
                                    : _loadMoreFiles,
                                icon: _loadingMoreFiles
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Iconsax.arrow_down_1),
                                label: Text(strings.loadMoreFiles),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (_comments.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _ProjectSection(
                      title: '${strings.comments} ${_comments.length}',
                      icon: Iconsax.message_text,
                      child: Column(
                        children: [
                          ..._comments.map(
                            (item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              title: Text(
                                item['comment']?.toString() ??
                                    item['body']?.toString() ??
                                    '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['user'] is Map
                                        ? (item['user']['full_name']
                                                  ?.toString() ??
                                              strings.collaborator)
                                        : strings.collaborator,
                                  ),
                                  if (item['attachments'] is List &&
                                      (item['attachments'] as List).isNotEmpty)
                                    ...((item['attachments'] as List)
                                        .whereType<Map>()
                                        .map(
                                          (attachment) => TextButton.icon(
                                            onPressed:
                                                _downloadingId ==
                                                    attachment['id']?.toString()
                                                ? null
                                                : () =>
                                                      _downloadCommentAttachment(
                                                        item,
                                                        Map<
                                                          String,
                                                          dynamic
                                                        >.from(attachment),
                                                      ),
                                            icon: const Icon(
                                              Iconsax.document_download,
                                              size: 16,
                                            ),
                                            label: Text(
                                              attachment['file_name']
                                                      ?.toString() ??
                                                  strings.attachment,
                                            ),
                                          ),
                                        )),
                                ],
                              ),
                              trailing:
                                  item['can_update'] == true ||
                                      item['can_delete'] == true
                                  ? PopupMenuButton<String>(
                                      onSelected: (value) => value == 'edit'
                                          ? _editComment(item)
                                          : _deleteComment(item),
                                      itemBuilder: (_) => [
                                        if (item['can_update'] == true)
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Text(strings.edit),
                                          ),
                                        if (item['can_delete'] == true)
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text(strings.delete),
                                          ),
                                      ],
                                    )
                                  : null,
                            ),
                          ),
                          if (_commentsPage < _commentsLastPage)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _openCommentsPage,
                                icon: const Icon(Iconsax.export_3),
                                label: Text(strings.viewMoreComments),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _ProjectSection(
                    title: strings.closureReport,
                    icon: Iconsax.clipboard_text,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          task['closure_report_status'] == null
                              ? strings.pendingClosureReport
                              : '${strings.status}: ${_closureReportStatusLabel(task['closure_report_status']?.toString())}',
                        ),
                        if (task['closure_report_text'] != null &&
                            task['closure_report_text']
                                .toString()
                                .isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            _plainTextFromRichReport(
                              task['closure_report_text'].toString(),
                            ),
                            style: const TextStyle(color: Color(0xff64748b)),
                          ),
                        ],
                        if (task['closure_report_review_note'] != null &&
                            task['closure_report_review_note']
                                .toString()
                                .isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${strings.reviewNote}: ${task['closure_report_review_note']}',
                            style: const TextStyle(color: Color(0xff64748b)),
                          ),
                        ],
                        if (task['closure_report_file_name'] != null &&
                            task['closure_report_file_name']
                                .toString()
                                .isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _downloadingId == 'closure-report'
                                ? null
                                : _downloadClosureReport,
                            icon: _downloadingId == 'closure-report'
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Iconsax.document_download),
                            label: Text(
                              task['closure_report_file_name'].toString(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class TaskCommentsPage extends StatefulWidget {
  const TaskCommentsPage({
    super.key,
    required this.session,
    required this.taskId,
    required this.taskTitle,
  });

  final AuthSession session;
  final String taskId;
  final String taskTitle;

  @override
  State<TaskCommentsPage> createState() => _TaskCommentsPageState();
}

class _TaskDetailSkeleton extends StatelessWidget {
  const _TaskDetailSkeleton();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SkeletonLine(width: 220, height: 22),
              const SizedBox(height: 12),
              const _SkeletonLine(width: double.infinity, height: 12),
              const SizedBox(height: 8),
              const _SkeletonLine(width: 180, height: 12),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SkeletonLine(width: 82, height: 30),
                  _SkeletonLine(width: 92, height: 30),
                  _SkeletonLine(width: 124, height: 30),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      const _TaskDetailSkeletonSection(lines: 3),
      const SizedBox(height: 14),
      const _TaskDetailSkeletonSection(lines: 2),
      const SizedBox(height: 14),
      const _TaskDetailSkeletonSection(lines: 4),
    ],
  );
}

class _TaskDetailSkeletonSection extends StatelessWidget {
  const _TaskDetailSkeletonSection({required this.lines});

  final int lines;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SkeletonLine(width: 150, height: 16),
          const SizedBox(height: 16),
          ...List.generate(
            lines,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SkeletonLine(
                width: index.isEven ? double.infinity : 220,
                height: 12,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _TaskCommentsPageState extends State<TaskCommentsPage> {
  late final TaskService _service;
  List<Map<String, dynamic>> _comments = const [];
  int _page = 1;
  int _lastPage = 1;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = TaskService(
      apiClient: ApiClient(accessToken: widget.session.token),
    );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _service.fetchCommentsPage(
        widget.taskId,
        perPage: 20,
      );
      if (!mounted) return;
      setState(() {
        _comments = result.items;
        _page = result.page;
        _lastPage = result.lastPage;
      });
      unawaited(
        Future.wait(
          result.items
              .map((comment) => comment['id']?.toString())
              .whereType<String>()
              .map(_service.markCommentRead),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page >= _lastPage) return;
    setState(() => _loadingMore = true);
    try {
      final result = await _service.fetchCommentsPage(
        widget.taskId,
        page: _page + 1,
        perPage: 20,
      );
      if (!mounted) return;
      setState(() {
        _comments = [..._comments, ...result.items];
        _page = result.page;
        _lastPage = result.lastPage;
      });
      unawaited(
        Future.wait(
          result.items
              .map((comment) => comment['id']?.toString())
              .whereType<String>()
              .map(_service.markCommentRead),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) showAppError(error.message);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.comments)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                children: [
                  const SizedBox(height: 180),
                  _ProjectsState(
                    icon: Iconsax.danger,
                    title: strings.loadingError,
                    message: _error!,
                    action: TextButton.icon(
                      onPressed: _load,
                      icon: const Icon(Iconsax.refresh),
                      label: Text(strings.retry),
                    ),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Text(
                    widget.taskTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.commentsDisplayed(_comments.length),
                    style: const TextStyle(color: Color(0xff64748b)),
                  ),
                  const SizedBox(height: 14),
                  if (_comments.isEmpty)
                    _ProjectsState(
                      icon: Iconsax.message_text,
                      title: strings.noComments,
                      message: strings.noCommentsDescription,
                    )
                  else
                    ..._comments.map(
                      (comment) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          title: Text(
                            comment['comment']?.toString() ??
                                comment['body']?.toString() ??
                                '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            comment['user'] is Map
                                ? (comment['user']['full_name']?.toString() ??
                                      strings.collaborator)
                                : strings.collaborator,
                          ),
                        ),
                      ),
                    ),
                  if (_page < _lastPage)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: OutlinedButton(
                        onPressed: _loadingMore ? null : _loadMore,
                        child: _loadingMore
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(strings.loadMore),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _TaskEditDialog extends StatefulWidget {
  const _TaskEditDialog({required this.task});

  final Map<String, dynamic> task;

  @override
  State<_TaskEditDialog> createState() => _TaskEditDialogState();
}

class _TaskEditDialogState extends State<_TaskEditDialog> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  DateTime? _start;
  DateTime? _due;
  String _periodLabel = 'Modifier la periode';

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(
      text: widget.task['title']?.toString() ?? '',
    );
    _description = TextEditingController(
      text: widget.task['description']?.toString() ?? '',
    );
    _start = _parseDate(widget.task['start_date']);
    _due = _parseDate(widget.task['due_date']);
    if (_start != null && _due != null) {
      _periodLabel = _formatPeriod(_start!, _due!);
    }
  }

  DateTime? _parseDate(dynamic value) => value == null
      ? null
      : DateTime.tryParse(value.toString().replaceFirst(' ', 'T'));

  String _two(int value) => value.toString().padLeft(2, '0');

  String _formatPeriod(DateTime start, DateTime due) =>
      '${_two(start.day)}/${_two(start.month)}/${start.year} '
      '${_two(start.hour)}:${_two(start.minute)} - '
      '${_two(due.day)}/${_two(due.month)}/${due.year} '
      '${_two(due.hour)}:${_two(due.minute)}';

  String _apiDate(DateTime value) =>
      '${value.year}-${_two(value.month)}-${_two(value.day)} '
      '${_two(value.hour)}:${_two(value.minute)}';

  Future<void> _pickPeriod() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _start != null && _due != null
          ? DateTimeRange(start: _start!, end: _due!)
          : null,
      helpText: 'Periode de la tache',
      saveText: 'Continuer',
      cancelText: 'Annuler',
    );
    if (range == null || !mounted) return;
    final startTime = await showTimePicker(
      context: context,
      initialTime: _start == null
          ? TimeOfDay.fromDateTime(now)
          : TimeOfDay.fromDateTime(_start!),
      helpText: 'Heure de debut',
    );
    if (startTime == null || !mounted) return;
    final dueTime = await showTimePicker(
      context: context,
      initialTime: _due == null
          ? TimeOfDay.fromDateTime(now.add(const Duration(hours: 1)))
          : TimeOfDay.fromDateTime(_due!),
      helpText: 'Heure de fin',
    );
    if (dueTime == null) return;
    final start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
      startTime.hour,
      startTime.minute,
    );
    final due = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      dueTime.hour,
      dueTime.minute,
    );
    if (!due.isAfter(start)) {
      showAppError('La fin doit etre apres le debut.');
      return;
    }
    setState(() {
      _start = start;
      _due = due;
      _periodLabel = _formatPeriod(start, due);
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Modifier la tache'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Titre'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Description',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickPeriod,
            icon: const Icon(Iconsax.calendar),
            label: Text(_periodLabel),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      FilledButton(
        onPressed: _title.text.trim().isEmpty
            ? null
            : () => Navigator.pop(context, {
                'title': _title.text.trim(),
                'description': _description.text.trim(),
                if (_start != null) 'start_date': _apiDate(_start!),
                if (_due != null) 'due_date': _apiDate(_due!),
              }),
        child: const Text('Enregistrer'),
      ),
    ],
  );
}

class _TaskSummary extends StatelessWidget {
  const _TaskSummary({required this.task});
  final Map<String, dynamic> task;

  @override
  Widget build(BuildContext context) => _ProjectSection(
    title: 'Details de la tache',
    icon: Iconsax.task_square,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          task['title']?.toString() ?? 'Tache',
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        if (task['project'] is Map) ...[
          const SizedBox(height: 3),
          Text(
            task['project']['name']?.toString() ?? 'Projet',
            style: const TextStyle(color: Color(0xff64748b), fontSize: 12),
          ),
        ],
        const SizedBox(height: 10),
        Text(
          task['description']?.toString() ?? 'Aucune description.',
          style: const TextStyle(color: Color(0xff64748b), fontSize: 13),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              label: Text(
                _taskPriorityLabel(task['priority']),
                style: const TextStyle(fontSize: 11),
              ),
            ),
            Chip(
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              label: Text(
                _taskStatusLabel(task['status']),
                style: const TextStyle(fontSize: 11),
              ),
            ),
            if (task['due_date'] != null)
              Chip(
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                avatar: const Icon(Iconsax.calendar, size: 16),
                label: Text(
                  _taskDueDateLabel(task['due_date']),
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            if (task['assignment_status'] != null)
              Chip(
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                label: Text(
                  'Affectation : ${_assignmentStatusLabel(task['assignment_status'])}',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
          ],
        ),
        if (task['assignment_response_note'] != null) ...[
          const SizedBox(height: 8),
          Text(
            'Reponse a l affectation: ${task['assignment_response_note']}',
            style: const TextStyle(color: Color(0xff64748b), fontSize: 12),
          ),
        ],
      ],
    ),
  );
}

String _taskPriorityLabel(dynamic value) {
  switch (value?.toString()) {
    case 'low':
      return 'Basse';
    case 'medium':
      return 'Moyenne';
    case 'high':
      return 'Haute';
    case 'urgent':
      return 'Urgente';
    default:
      return 'Priorité non définie';
  }
}

String _closureReportStatusLabel(String? value) {
  switch (value) {
    case 'pending_validation':
      return 'En attente de validation';
    case 'validated':
      return 'Valide';
    case 'rejected':
      return 'Rejete';
    default:
      return 'Non soumis';
  }
}

String _alertTypeLabel(String? value) {
  switch (value) {
    case 'tasks_overdue':
      return 'Taches en retard';
    case 'milestones_overdue':
      return 'Jalons en retard';
    case 'deliverables_overdue':
      return 'Livrables en retard';
    case 'critical_risk':
      return 'Risque critique';
    case 'critical_blocker':
      return 'Blocage critique';
    default:
      return value == null || value.isEmpty ? 'Alerte projet' : value;
  }
}

String _taskStatusLabel(dynamic value) {
  switch (value?.toString()) {
    case 'todo':
      return 'À faire';
    case 'in_progress':
      return 'En cours';
    case 'review':
      return 'En revue';
    case 'done':
    case 'completed':
      return 'Terminée';
    case 'cancelled':
      return 'Annulée';
    default:
      return 'Statut non défini';
  }
}

String _assignmentStatusLabel(dynamic value) {
  switch (value?.toString()) {
    case 'pending':
      return 'En attente';
    case 'accepted':
      return 'Acceptée';
    case 'declined':
      return 'Refusée';
    case 'completed':
      return 'Terminée';
    default:
      return 'Non définie';
  }
}

String _taskDueDateLabel(dynamic value) {
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) return 'Échéance non définie';
  final date = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  if (date == null) return raw;
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year} à ${two(date.hour)}:${two(date.minute)}';
}

class _ModuleForm extends StatefulWidget {
  const _ModuleForm({required this.kind, this.initial});

  final ProjectModuleKind kind;
  final Map<String, dynamic>? initial;

  @override
  State<_ModuleForm> createState() => _ModuleFormState();
}

class _ModuleFormState extends State<_ModuleForm> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _minutes = TextEditingController(text: '60');

  @override
  void initState() {
    super.initState();
    _title.text = widget.initial?['title']?.toString() ?? '';
    _description.text = widget.initial?['description']?.toString() ?? '';
    if (widget.initial?['minutes'] != null) {
      _minutes.text = widget.initial!['minutes'].toString();
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _minutes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ajouter',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Titre'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          if (widget.kind == ProjectModuleKind.workLogs) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _minutes,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Minutes'),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final title = _title.text.trim();
              if (title.isEmpty) {
                showAppError('Le titre est obligatoire.');
                return;
              }
              final description = _description.text.trim();
              final body = <String, dynamic>{
                'title': title,
                if (description.isNotEmpty) 'description': description,
              };
              switch (widget.kind) {
                case ProjectModuleKind.tasks:
                  body.addAll({'priority': 'medium', 'status': 'todo'});
                case ProjectModuleKind.milestones:
                  body['status'] = 'planned';
                case ProjectModuleKind.deliverables:
                  body['status'] = 'pending';
                case ProjectModuleKind.registerItems:
                  body.addAll({
                    'type': 'risk',
                    'severity': 'medium',
                    'status': 'open',
                  });
                case ProjectModuleKind.workLogs:
                  body.addAll({
                    'minutes': int.tryParse(_minutes.text) ?? 60,
                    'work_date': _today(),
                  });
                case ProjectModuleKind.activity:
                  break;
              }
              Navigator.pop(context, body);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  String _today() {
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)}';
  }
}

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({
    required this.item,
    required this.kind,
    this.onEdit,
    this.onDelete,
    this.onOpen,
  });
  final Map<String, dynamic> item;
  final ProjectModuleKind kind;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final title = item['title'] ?? item['name'] ?? 'Element';
    final status = item['status']?.toString();
    final description = item['description']?.toString();
    final subtitle = [
      if (status != null && status.isNotEmpty) _moduleStatusLabel(kind, status),
      if (description != null && description.isNotEmpty) description,
    ].join(' - ');
    return Card(
      child: ListTile(
        title: Text(
          title.toString(),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        trailing: onEdit == null && onDelete == null
            ? null
            : PopupMenuButton<String>(
                onSelected: (value) =>
                    value == 'edit' ? onEdit?.call() : onDelete?.call(),
                itemBuilder: (_) => [
                  if (onEdit != null)
                    const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                  if (onDelete != null)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Supprimer'),
                    ),
                ],
              ),
        onTap: onOpen,
      ),
    );
  }
}

String _moduleStatusLabel(ProjectModuleKind kind, String status) {
  switch (kind) {
    case ProjectModuleKind.tasks:
      switch (status) {
        case 'in_progress':
          return 'En cours';
        case 'review':
          return 'En revue';
        case 'done':
        case 'completed':
          return 'Terminee';
        case 'cancelled':
          return 'Annulee';
        default:
          return 'A faire';
      }
    case ProjectModuleKind.milestones:
      switch (status) {
        case 'in_progress':
          return 'En cours';
        case 'completed':
          return 'Termine';
        case 'blocked':
          return 'Bloque';
        case 'cancelled':
          return 'Annule';
        default:
          return 'Planifie';
      }
    case ProjectModuleKind.deliverables:
      switch (status) {
        case 'in_progress':
          return 'En cours';
        case 'submitted':
          return 'Soumis';
        case 'accepted':
          return 'Accepte';
        case 'rejected':
          return 'Rejete';
        case 'cancelled':
          return 'Annule';
        default:
          return 'En attente';
      }
    case ProjectModuleKind.registerItems:
      switch (status) {
        case 'in_progress':
          return 'En cours';
        case 'closed':
          return 'Cloture';
        case 'cancelled':
          return 'Annule';
        default:
          return 'Ouvert';
      }
    case ProjectModuleKind.workLogs:
    case ProjectModuleKind.activity:
      return status;
  }
}

class _ProjectDashboardSection extends StatelessWidget {
  const _ProjectDashboardSection({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final progress = data['progress'] is Map
        ? Map<String, dynamic>.from(data['progress'] as Map)
        : data;
    final values =
        <String, dynamic>{
          'Taches': progress['tasks_total'],
          'Taches terminees': progress['tasks_completed'],
          'Jalons': progress['milestones_total'],
          'Livrables': progress['deliverables_total'],
          'Temps (min)':
              progress['total_minutes'] ?? progress['minutes_logged'],
          'Alertes': data['health'] is Map
              ? data['health']['alerts_total']
              : null,
        }..removeWhere(
          (_, value) => value == null || value is Map || value is List,
        );
    final alerts = data['alerts'] is List
        ? (data['alerts'] as List)
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : const <Map<String, dynamic>>[];
    if (values.isEmpty && alerts.isEmpty) return const SizedBox.shrink();
    return _ProjectSection(
      title: 'Synthese du projet',
      icon: Iconsax.chart_2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: values.entries
                .map(
                  (entry) => Chip(
                    label: Text('${entry.key}: ${entry.value}'),
                    avatar: const Icon(Iconsax.chart_2, size: 16),
                  ),
                )
                .toList(),
          ),
          if (alerts.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Alertes',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            ...alerts.map(
              (alert) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(
                  Iconsax.danger,
                  color: alert['severity'] == 'critical'
                      ? Colors.red
                      : Colors.orange,
                ),
                title: Text(alert['message']?.toString() ?? 'Alerte'),
                subtitle: Text(_alertTypeLabel(alert['type']?.toString())),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ClosureReportSection extends StatefulWidget {
  const _ClosureReportSection({
    required this.project,
    required this.service,
    required this.projectId,
    required this.onChanged,
  });

  final Map<String, dynamic> project;
  final ProjectService service;
  final String projectId;
  final Future<void> Function() onChanged;

  @override
  State<_ClosureReportSection> createState() => _ClosureReportSectionState();
}

class _ClosureReportSectionState extends State<_ClosureReportSection> {
  final _text = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final strings = AppLocalizations.of(context);
    if (_text.text.trim().isEmpty) {
      showAppError(strings.closureReportRequired);
      return;
    }
    await _run(
      () => widget.service.submitClosureReport(
        widget.projectId,
        _text.text.trim(),
      ),
      strings.closureReportSubmitted,
    );
  }

  Future<void> _validate() => _run(
    () => widget.service.validateClosureReport(widget.projectId),
    AppLocalizations.of(context).closureReportValidated,
  );

  Future<void> _reject() async {
    final message = AppLocalizations.of(context).closureReportRejected;
    final note = await _askNote();
    if (note == null || note.trim().isEmpty) return;
    await _run(
      () => widget.service.rejectClosureReport(widget.projectId, note.trim()),
      message,
    );
  }

  Future<String?> _askNote() async {
    final strings = AppLocalizations.of(context);
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.rejectionReason),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(labelText: strings.note),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(strings.rejectReport),
          ),
        ],
      ),
    );
    controller.dispose();
    return value;
  }

  Future<void> _run(
    Future<Map<String, dynamic>> Function() action,
    String success,
  ) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await action();
      showAppSuccess(success);
      await widget.onChanged();
    } on ApiException catch (error) {
      showAppError(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final status = widget.project['closure_report_status']?.toString();
    return _ProjectSection(
      title: strings.closureReport,
      icon: Iconsax.clipboard_text,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${strings.status}: ${_closureReportStatusLabel(status)}'),
          if (widget.project['closure_report_text'] != null &&
              widget.project['closure_report_text'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _plainTextFromRichReport(
                widget.project['closure_report_text'].toString(),
              ),
              style: const TextStyle(color: Color(0xff64748b)),
            ),
          ],
          if (widget.project['closure_report_review_note'] != null) ...[
            const SizedBox(height: 6),
            Text(widget.project['closure_report_review_note'].toString()),
          ],
          if (widget.project['can_submit_closure_report'] == true) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _text,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(labelText: strings.closureReport),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: const Icon(Iconsax.send_2),
              label: Text(strings.submit),
            ),
          ],
          if (widget.project['can_validate_closure_report'] == true ||
              widget.project['can_reject_closure_report'] == true) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                if (widget.project['can_validate_closure_report'] == true)
                  FilledButton.icon(
                    onPressed: _saving ? null : _validate,
                    icon: const Icon(Iconsax.tick_circle),
                    label: Text(strings.validate),
                  ),
                if (widget.project['can_reject_closure_report'] == true)
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _reject,
                    icon: const Icon(Iconsax.close_circle),
                    label: Text(strings.rejectReport),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProjectHero extends StatelessWidget {
  const _ProjectHero({required this.project, required this.progress});

  final Map<String, dynamic> project;
  final Map<String, dynamic>? progress;

  @override
  Widget build(BuildContext context) {
    final rawProgress =
        progress?['percent_complete'] ??
        progress?['percentComplete'] ??
        project['progress'] ??
        0;
    final value = (double.tryParse(rawProgress.toString()) ?? 0)
        .clamp(0, 100)
        .toDouble();
    final description = project['description']?.toString();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    project['name']?.toString() ?? 'Projet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StatusBadge(status: project['status']?.toString()),
              ],
            ),
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                description,
                style: const TextStyle(color: Color(0xff64748b)),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Progression',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${value.round()}%',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: value / 100, minHeight: 8),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(icon: Iconsax.profile, label: _ownerName(project)),
                _InfoChip(
                  icon: Iconsax.calendar,
                  label: project['end_date']?.toString() ?? 'Sans echeance',
                ),
                _InfoChip(
                  icon: Iconsax.flag,
                  label: _taskPriorityLabel(project['priority']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _ownerName(Map<String, dynamic> project) {
    final owner = project['owner'];
    if (owner is Map) {
      return owner['full_name']?.toString() ?? 'Responsable non defini';
    }
    return 'Responsable non defini';
  }
}

class _ProjectForm extends StatefulWidget {
  const _ProjectForm({
    required this.onSubmit,
    this.initial,
    this.availableUsers = const [],
  });

  final Future<void> Function(Map<String, dynamic> body) onSubmit;
  final Map<String, dynamic>? initial;
  final List<Map<String, dynamic>> availableUsers;

  @override
  State<_ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends State<_ProjectForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _startDate = TextEditingController();
  final _endDate = TextEditingController();
  final _dateRangeLabel = TextEditingController();
  String _priority = 'medium';
  bool _confidential = false;
  bool _saving = false;
  String? _selectedUserId;
  String _selectedMemberRole = 'contributor';
  final _selectedMembers = <Map<String, String>>[];
  DateTime? _startDateTime;
  DateTime? _endDateTime;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _name.text = initial?['name']?.toString() ?? '';
    _description.text = initial?['description']?.toString() ?? '';
    _priority = initial?['priority']?.toString() ?? 'medium';
    _confidential = initial?['confidential'] == true;
    _startDate.text = initial?['start_date']?.toString() ?? '';
    _endDate.text = initial?['end_date']?.toString() ?? '';
    final start = DateTime.tryParse(_startDate.text.replaceFirst(' ', 'T'));
    final end = DateTime.tryParse(_endDate.text.replaceFirst(' ', 'T'));
    if (start != null && end != null) {
      _startDateTime = start;
      _endDateTime = end;
      _dateRangeLabel.text =
          '${_formatDisplayDateTime(start)} - ${_formatDisplayDateTime(end)}';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _startDate.dispose();
    _endDate.dispose();
    _dateRangeLabel.dispose();
    super.dispose();
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
        'start_date': _startDate.text.trim().isEmpty
            ? null
            : _startDate.text.trim(),
        'end_date': _endDate.text.trim().isEmpty ? null : _endDate.text.trim(),
        'priority': _priority,
        'confidential': _confidential,
        if (_selectedMembers.isNotEmpty) 'members': _selectedMembers,
        if (widget.initial == null) 'status': 'planned',
      });
    } on ApiException catch (error) {
      showAppError(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _userName(Map<String, dynamic> user) {
    return user['full_name']?.toString() ??
        '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
  }

  void _addMember() {
    final userId = _selectedUserId;
    if (userId == null || userId.isEmpty) return;
    if (_selectedMembers.any((member) => member['user_id'] == userId)) {
      showAppError('Ce membre est deja ajoute.');
      return;
    }
    setState(() {
      _selectedMembers.add({'user_id': userId, 'role': _selectedMemberRole});
      _selectedUserId = null;
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _startDateTime != null && _endDateTime != null
          ? DateTimeRange(start: _startDateTime!, end: _endDateTime!)
          : null,
      currentDate: now,
      helpText: 'Choisir la periode du projet',
      saveText: 'Continuer',
      cancelText: 'Annuler',
    );
    if (range == null || !mounted) return;

    final startTime = await showTimePicker(
      context: context,
      initialTime: _startDateTime == null
          ? TimeOfDay.fromDateTime(now)
          : TimeOfDay.fromDateTime(_startDateTime!),
      helpText: 'Heure de debut',
      cancelText: 'Annuler',
      confirmText: 'Continuer',
    );
    if (startTime == null || !mounted) return;

    final endTime = await showTimePicker(
      context: context,
      initialTime: _endDateTime == null
          ? TimeOfDay.fromDateTime(now)
          : TimeOfDay.fromDateTime(_endDateTime!),
      helpText: 'Heure de fin',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );
    if (endTime == null) return;

    final start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
      startTime.hour,
      startTime.minute,
    );
    final end = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      endTime.hour,
      endTime.minute,
    );
    if (!end.isAfter(start)) {
      showAppError('La fin doit etre apres le debut du projet.');
      return;
    }

    setState(() {
      _startDateTime = start;
      _endDateTime = end;
      _startDate.text = _formatDateTime(start);
      _endDate.text = _formatDateTime(end);
      _dateRangeLabel.text =
          '${_formatDisplayDateTime(start)} - ${_formatDisplayDateTime(end)}';
    });
  }

  String _formatDisplayDateTime(DateTime value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${twoDigits(value.day)}/${twoDigits(value.month)}/${value.year} ${twoDigits(value.hour)}:${twoDigits(value.minute)}';
  }

  String _formatDateTime(DateTime value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${value.year}-${twoDigits(value.month)}-${twoDigits(value.day)} ${twoDigits(value.hour)}:${twoDigits(value.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Padding(
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
                widget.initial == null
                    ? strings.newProject
                    : strings.editProject,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _name,
                decoration: InputDecoration(labelText: strings.projectName),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Champ obligatoire.'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _description,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: strings.description,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: InputDecoration(labelText: strings.priority),
                items: [
                  DropdownMenuItem(value: 'low', child: Text(strings.low)),
                  DropdownMenuItem(
                    value: 'medium',
                    child: Text(strings.medium),
                  ),
                  DropdownMenuItem(value: 'high', child: Text(strings.high)),
                  DropdownMenuItem(
                    value: 'urgent',
                    child: Text(strings.urgent),
                  ),
                ],
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _priority = value ?? 'medium'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _dateRangeLabel,
                readOnly: true,
                onTap: _saving ? null : _pickDateRange,
                decoration: InputDecoration(
                  labelText: strings.projectPeriod,
                  hintText: strings.selectDates,
                  suffixIcon: Icon(Iconsax.calendar),
                ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(strings.confidentialProject),
                value: _confidential,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _confidential = value),
              ),
              if (widget.availableUsers.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  strings.initialTeam,
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedUserId,
                        isExpanded: true,
                        menuMaxHeight: 280,
                        decoration: InputDecoration(labelText: strings.member),
                        items: widget.availableUsers
                            .map((user) {
                              final id = user['id']?.toString() ?? '';
                              return DropdownMenuItem(
                                value: id,
                                child: Text(_userName(user)),
                              );
                            })
                            .where((item) => item.value != '')
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (value) =>
                                  setState(() => _selectedUserId = value),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedMemberRole,
                        isExpanded: true,
                        menuMaxHeight: 280,
                        decoration: InputDecoration(labelText: strings.role),
                        items: [
                          DropdownMenuItem(
                            value: 'manager',
                            child: Text('Manager'),
                          ),
                          DropdownMenuItem(
                            value: 'reviewer',
                            child: Text('Reviewer'),
                          ),
                          DropdownMenuItem(
                            value: 'contributor',
                            child: Text('Contributeur'),
                          ),
                          DropdownMenuItem(
                            value: 'observer',
                            child: Text('Observateur'),
                          ),
                        ],
                        onChanged: _saving
                            ? null
                            : (value) => setState(
                                () => _selectedMemberRole =
                                    value ?? 'contributor',
                              ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Ajouter le membre',
                      onPressed: _saving || _selectedUserId == null
                          ? null
                          : _addMember,
                      icon: const Icon(Iconsax.add_circle),
                    ),
                  ],
                ),
                if (_selectedMembers.isEmpty)
                  Text(
                    strings.noMemberAdded,
                    style: TextStyle(color: Color(0xff64748b)),
                  )
                else
                  ..._selectedMembers.map(
                    (member) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(Iconsax.profile),
                      title: Text(
                        _userName(
                          widget.availableUsers.firstWhere(
                            (user) =>
                                user['id']?.toString() == member['user_id'],
                            orElse: () => {'full_name': 'Membre'},
                          ),
                        ),
                      ),
                      subtitle: Text(member['role'] ?? 'contributor'),
                      trailing: IconButton(
                        onPressed: _saving
                            ? null
                            : () => setState(
                                () => _selectedMembers.remove(member),
                              ),
                        icon: const Icon(Iconsax.close_circle),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.initial == null
                              ? strings.createProject
                              : strings.save,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusActions extends StatelessWidget {
  const _StatusActions({
    required this.status,
    required this.allowedStatuses,
    required this.onStatus,
  });

  final String status;
  final List<String> allowedStatuses;
  final ValueChanged<String> onStatus;

  @override
  Widget build(BuildContext context) {
    final actions = <String, String>{
      if (status == 'planned') 'active': 'Demarrer',
      if (status == 'active') 'on_hold': 'Mettre en pause',
      if (status == 'on_hold') 'active': 'Reprendre',
      if (status == 'completed') 'archived': 'Archiver',
      if (status != 'cancelled' && status != 'completed')
        'cancelled': 'Annuler',
    };
    final visibleActions = actions.entries
        .where(
          (entry) =>
              allowedStatuses.isEmpty || allowedStatuses.contains(entry.key),
        )
        .toList();
    if (visibleActions.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: visibleActions
              .map(
                (entry) => OutlinedButton(
                  onPressed: () => onStatus(entry.key),
                  child: Text(entry.value),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _ProjectSection extends StatelessWidget {
  const _ProjectSection({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    ),
  );
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.canManage,
    required this.onEdit,
    required this.onRemove,
  });

  final Map<String, dynamic> member;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final user = member['user'] is Map ? member['user'] as Map : member;
    final name =
        user['full_name']?.toString() ??
        '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(child: Icon(Iconsax.profile)),
      title: Text(name.isEmpty ? 'Membre' : name),
      subtitle: Text(member['role']?.toString() ?? 'Membre'),
      trailing: canManage
          ? PopupMenuButton<String>(
              onSelected: (value) => value == 'edit' ? onEdit() : onRemove(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Modifier le role')),
                PopupMenuItem(value: 'remove', child: Text('Retirer')),
              ],
            )
          : null,
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) =>
      Chip(avatar: Icon(icon, size: 16), label: Text(label));
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final labels = <String, String>{
      'planned': strings.planned,
      'active': strings.active,
      'on_hold': strings.onHold,
      'completed': strings.finished,
      'archived': strings.archived,
      'cancelled': strings.cancelled,
    };
    final palette = <String, (Color, Color)>{
      'planned': (const Color(0xffeff6ff), const Color(0xff2563eb)),
      'active': (const Color(0xffecfdf5), const Color(0xff047857)),
      'on_hold': (const Color(0xfffffbeb), const Color(0xffb45309)),
      'completed': (const Color(0xfff0fdf4), const Color(0xff15803d)),
      'archived': (const Color(0xfff1f5f9), const Color(0xff475569)),
      'cancelled': (const Color(0xfffef2f2), const Color(0xffb91c1c)),
    };
    final colors =
        palette[status] ??
        (
          Theme.of(context).colorScheme.surfaceContainerHighest,
          Theme.of(context).colorScheme.onSurfaceVariant,
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        labels[status] ?? strings.planned,
        style: TextStyle(
          fontSize: 11,
          color: colors.$2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProjectDetailSkeleton extends StatelessWidget {
  const _ProjectDetailSkeleton();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _SkeletonLine(width: 42, height: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SkeletonLine(width: 190, height: 20),
                        const SizedBox(height: 8),
                        _SkeletonLine(width: 130, height: 12),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const _SkeletonLine(width: 68, height: 28),
                ],
              ),
              const SizedBox(height: 20),
              const _SkeletonLine(width: double.infinity, height: 12),
              const SizedBox(height: 8),
              const _SkeletonLine(width: 230, height: 12),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _SkeletonLine(width: double.infinity, height: 58),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SkeletonLine(width: double.infinity, height: 58),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      const _ProjectDetailSkeletonSection(lines: 3),
      const SizedBox(height: 14),
      const _ProjectDetailSkeletonSection(lines: 2),
      const SizedBox(height: 14),
      const _ProjectDetailSkeletonSection(lines: 4),
    ],
  );
}

class _ProjectDetailSkeletonSection extends StatelessWidget {
  const _ProjectDetailSkeletonSection({required this.lines});

  final int lines;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SkeletonLine(width: 150, height: 16),
          const SizedBox(height: 16),
          ...List.generate(
            lines,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SkeletonLine(
                width: index.isEven ? double.infinity : 210,
                height: 12,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProjectModuleSkeleton extends StatelessWidget {
  const _ProjectModuleSkeleton();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _SkeletonLine(width: 190, height: 20),
      const SizedBox(height: 18),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: List.generate(
              5,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    const _SkeletonLine(width: 36, height: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SkeletonLine(
                            width: index.isEven ? 190 : 150,
                            height: 13,
                          ),
                          const SizedBox(height: 7),
                          const _SkeletonLine(width: 110, height: 10),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const _SkeletonLine(width: 62, height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _ProjectSkeletonList extends StatelessWidget {
  const _ProjectSkeletonList();

  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      3,
      (index) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: _ProjectSkeletonCard(),
      ),
    ),
  );
}

class _ProjectSkeletonCard extends StatelessWidget {
  const _ProjectSkeletonCard();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonLine(width: 190, height: 18),
          SizedBox(height: 14),
          _SkeletonLine(width: double.infinity, height: 12),
          SizedBox(height: 8),
          _SkeletonLine(width: 240, height: 12),
          SizedBox(height: 18),
          _SkeletonLine(width: double.infinity, height: 8),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SkeletonLine(width: double.infinity, height: 34),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _SkeletonLine(width: double.infinity, height: 34),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(6),
    ),
  );
}

class _ProjectsState extends StatelessWidget {
  const _ProjectsState({
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

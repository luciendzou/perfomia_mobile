import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/network/api_client.dart';
import '../../../core/ui/app_messenger.dart';
import '../../../core/localization/app_localizations.dart';
import '../../auth/data/auth_service.dart';
import '../data/organization_supervisor_service.dart';
import '../data/users_service.dart';

class OrganizationSupervisorsPage extends StatefulWidget {
  const OrganizationSupervisorsPage({super.key, required this.session});
  final AuthSession session;
  @override
  State<OrganizationSupervisorsPage> createState() =>
      _OrganizationSupervisorsPageState();
}

class _OrganizationSupervisorsPageState
    extends State<OrganizationSupervisorsPage> {
  late final OrganizationSupervisorService _service;
  late final UsersService _usersService;
  final _search = TextEditingController();
  List<Map<String, dynamic>> _items = const [];
  List<Map<String, dynamic>> _users = const [];
  List<Map<String, dynamic>> _departments = const [];
  List<Map<String, dynamic>> _services = const [];
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String _scope = '';
  int _page = 1;
  int _lastPage = 1;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    final client = ApiClient(accessToken: widget.session.token);
    _service = OrganizationSupervisorService(apiClient: client);
    _usersService = UsersService(apiClient: client);
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({int? page}) async {
    setState(() {
      _loading = true;
      _error = null;
      if (page != null) _page = page;
    });
    try {
      final result = await _service.fetch(
        search: _search.text,
        scope: _scope,
        page: _page,
      );
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _page = result.currentPage;
        _lastPage = result.lastPage;
        _total = result.total;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = AppLocalizations.of(context).supervisorsLoadError,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadReferences() async {
    try {
      final result = await Future.wait([
        _usersService.fetch(),
        _usersService.fetchReference('/departments?all=true'),
        _usersService.fetchReference('/services?all=true'),
      ]);
      if (mounted) {
        setState(() {
          _users = result[0];
          _departments = result[1];
          _services = result[2];
        });
      }
    } catch (_) {}
  }

  String _name(dynamic id, List<Map<String, dynamic>> values, String fallback) {
    if (id == null || '$id'.isEmpty) return fallback;
    for (final item in values) {
      if (item['id']?.toString() == '$id') {
        return item['name']?.toString() ?? fallback;
      }
    }
    return fallback;
  }

  String _userName(Map<String, dynamic> item, BuildContext context) {
    final user = item['user'] is Map
        ? Map<String, dynamic>.from(item['user'] as Map)
        : null;
    final source =
        user ??
        _users.cast<Map<String, dynamic>?>().firstWhere(
          (value) => value?['id']?.toString() == item['user_id']?.toString(),
          orElse: () => null,
        );
    if (source == null) {
      return item['user_id']?.toString() ?? AppLocalizations.of(context).user;
    }
    final name = '${source['first_name'] ?? ''} ${source['last_name'] ?? ''}'
        .trim();
    return name.isNotEmpty
        ? name
        : (source['full_name'] ??
                  source['name'] ??
                  source['email'] ??
                  AppLocalizations.of(context).user)
              .toString();
  }

  String _scopeLabel(dynamic value, BuildContext context) => value == 'company'
      ? AppLocalizations.of(context).companyScope
      : value == 'department'
      ? AppLocalizations.of(context).department
      : AppLocalizations.of(context).serviceScope;

  Future<void> _openForm([Map<String, dynamic>? item]) async {
    await _loadReferences();
    if (!mounted) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SupervisorForm(
        initial: item,
        users: _users,
        departments: _departments,
        services: _services,
        onSave: (body) async {
          if (item == null) {
            await _service.create(body);
          } else {
            await _service.update(item['id'].toString(), body);
          }
        },
      ),
    );
    if (saved == true && mounted) await _load(page: _page);
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).deleteSupervisorTitle),
        content: Text(AppLocalizations.of(context).deleteSupervisorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context).delete),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _busy = true);
    try {
      await _service.delete(item['id'].toString());
      if (mounted) {
        await _load(page: _page > 1 && _items.length == 1 ? _page - 1 : _page);
      }
    } on ApiException catch (error) {
      if (mounted) {
        showAppError(error.message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _filters() async {
    var scope = _scope;
    final result = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppLocalizations.of(context).supervisorsTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: scope.isEmpty ? null : scope,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).supervisionScope,
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(AppLocalizations.of(context).allScopes),
                  ),
                  DropdownMenuItem(
                    value: 'company',
                    child: Text(AppLocalizations.of(context).companyScope),
                  ),
                  DropdownMenuItem(
                    value: 'department',
                    child: Text(AppLocalizations.of(context).department),
                  ),
                  DropdownMenuItem(
                    value: 'service',
                    child: Text(AppLocalizations.of(context).serviceScope),
                  ),
                ],
                onChanged: (value) => setModalState(() => scope = value ?? ''),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    _scope = scope;
                    Navigator.pop(context, true);
                  },
                  child: Text(AppLocalizations.of(context).applyFilters),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    _scope = '';
                    Navigator.pop(context, true);
                  },
                  child: Text(AppLocalizations.of(context).resetFilters),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result == true && mounted) await _load(page: 1);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(AppLocalizations.of(context).supervisorsTitle),
      actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          icon: const Icon(Iconsax.refresh),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _busy ? null : _openForm,
      icon: const Icon(Iconsax.add),
      label: Text(AppLocalizations.of(context).add),
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
        children: [
          Text(
            AppLocalizations.of(context).supervisorsTitle,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).supervisorsDescription,
            style: TextStyle(color: Color(0xff64748b), height: 1.4),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  onSubmitted: (_) => _load(page: 1),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Iconsax.search_normal),
                    hintText: AppLocalizations.of(context).searchSupervisor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _filters,
                icon: const Icon(Iconsax.filter),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_loading)
            const _SupervisorSkeleton()
          else if (_error != null)
            _SupervisorState(message: _error!, onRetry: _load)
          else if (_items.isEmpty)
            _SupervisorState(message: AppLocalizations.of(context).noResults)
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context).configuredAssignments,
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  AppLocalizations.of(context).supervisorCount(_total),
                  style: const TextStyle(color: Color(0xff64748b)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._items.map(
              (item) => _SupervisorTile(
                item: item,
                name: _userName(item, context),
                scope: _scopeLabel(item['scope'], context),
                perimeter: item['scope'] == 'company'
                    ? AppLocalizations.of(context).wholeCompany
                    : item['scope'] == 'department'
                    ? _name(
                        item['department_id'],
                        _departments,
                        AppLocalizations.of(context).notProvided,
                      )
                    : _name(
                        item['service_id'],
                        _services,
                        AppLocalizations.of(context).notProvided,
                      ),
                onEdit: () => _openForm(item),
                onDelete: _busy ? null : () => _delete(item),
              ),
            ),
            if (_lastPage > 1) ...[
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: _page > 1 ? () => _load(page: _page - 1) : null,
                    child: Text(AppLocalizations.of(context).previous),
                  ),
                  Text('Page $_page / $_lastPage'),
                  OutlinedButton(
                    onPressed: _page < _lastPage
                        ? () => _load(page: _page + 1)
                        : null,
                    child: Text(AppLocalizations.of(context).next),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    ),
  );
}

class _SupervisorTile extends StatelessWidget {
  const _SupervisorTile({
    required this.item,
    required this.name,
    required this.scope,
    required this.perimeter,
    required this.onEdit,
    required this.onDelete,
  });
  final Map<String, dynamic> item;
  final String name;
  final String scope;
  final String perimeter;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                if ((item['user']?['email']?.toString() ?? '').isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item['user']['email'].toString(),
                    style: const TextStyle(
                      color: Color(0xff64748b),
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Chip(label: scope),
                    _Chip(label: perimeter),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (item['can_view_tasks'] == true)
                      _Chip(label: AppLocalizations.of(context).viewTasks),
                    if (item['can_assign_tasks'] == true)
                      _Chip(label: AppLocalizations.of(context).assignTasks),
                    if (item['can_review_tasks'] == true)
                      _Chip(label: AppLocalizations.of(context).validateTasks),
                    if (item['can_manage_projects'] == true)
                      _Chip(label: AppLocalizations.of(context).manageProjects),
                    if (item['can_review_evaluations'] == true)
                      _Chip(
                        label: AppLocalizations.of(context).viewEvaluations,
                      ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete' && onDelete != null) onDelete!();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Text(AppLocalizations.of(context).edit),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(AppLocalizations.of(context).delete),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xffeef4ff),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        color: Color(0xff31558f),
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _SupervisorForm extends StatefulWidget {
  const _SupervisorForm({
    required this.initial,
    required this.users,
    required this.departments,
    required this.services,
    required this.onSave,
  });
  final Map<String, dynamic>? initial;
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> departments;
  final List<Map<String, dynamic>> services;
  final Future<void> Function(Map<String, dynamic>) onSave;
  @override
  State<_SupervisorForm> createState() => _SupervisorFormState();
}

class _SupervisorFormState extends State<_SupervisorForm> {
  String? _userId;
  String _scope = 'service';
  String? _departmentId;
  String? _serviceId;
  bool _viewTasks = true;
  bool _assignTasks = true;
  bool _reviewTasks = true;
  bool _manageProjects = false;
  bool _viewEvaluations = true;
  bool _reviewEvaluations = true;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    final item = widget.initial;
    _userId = item?['user_id']?.toString();
    _scope = item?['scope']?.toString() ?? 'service';
    _departmentId = item?['department_id']?.toString();
    _serviceId = item?['service_id']?.toString();
    _viewTasks = item?['can_view_tasks'] != false;
    _assignTasks = item?['can_assign_tasks'] != false;
    _reviewTasks = item?['can_review_tasks'] != false;
    _manageProjects = item?['can_manage_projects'] == true;
    _viewEvaluations = item?['can_view_evaluations'] != false;
    _reviewEvaluations = item?['can_review_evaluations'] != false;
  }

  Future<void> _save() async {
    if (_userId == null ||
        (_scope == 'department' && _departmentId == null) ||
        (_scope == 'service' && _serviceId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).supervisorRequired),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave({
        'user_id': _userId,
        'scope': _scope,
        'department_id': _scope == 'department' ? _departmentId : null,
        'service_id': _scope == 'service' ? _serviceId : null,
        'can_view_tasks': _viewTasks,
        'can_assign_tasks': _assignTasks,
        'can_review_tasks': _reviewTasks,
        'can_manage_projects': _manageProjects,
        'can_view_evaluations': _viewEvaluations,
        'can_review_evaluations': _reviewEvaluations,
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) {
        showAppError(error.message);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _userLabel(Map<String, dynamic> user, BuildContext context) {
    final name = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'
        .trim();
    return name.isNotEmpty
        ? name
        : (user['full_name'] ??
                  user['name'] ??
                  user['email'] ??
                  AppLocalizations.of(context).user)
              .toString();
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
            widget.initial == null
                ? AppLocalizations.of(context).addSupervisor
                : AppLocalizations.of(context).editSupervisor,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).supervisorFormDescription,
            style: TextStyle(color: Color(0xff64748b)),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: _userId,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).userRequired,
            ),
            items: widget.users
                .map(
                  (user) => DropdownMenuItem(
                    value: user['id']?.toString(),
                    child: Text(
                      _userLabel(user, context),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: _saving
                ? null
                : (value) => setState(() => _userId = value),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _scope,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).scopeRequired,
            ),
            items: [
              DropdownMenuItem(
                value: 'company',
                child: Text(AppLocalizations.of(context).wholeCompany),
              ),
              DropdownMenuItem(
                value: 'department',
                child: Text(AppLocalizations.of(context).department),
              ),
              DropdownMenuItem(
                value: 'service',
                child: Text(AppLocalizations.of(context).serviceScope),
              ),
            ],
            onChanged: _saving
                ? null
                : (value) => setState(() {
                    _scope = value ?? 'service';
                    if (_scope == 'company') {
                      _departmentId = null;
                      _serviceId = null;
                    }
                  }),
          ),
          if (_scope == 'department') ...[
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _departmentId,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).departmentRequired,
              ),
              items: widget.departments
                  .map(
                    (item) => DropdownMenuItem(
                      value: item['id']?.toString(),
                      child: Text(item['name']?.toString() ?? ''),
                    ),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _departmentId = value),
            ),
          ],
          if (_scope == 'service') ...[
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _serviceId,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).serviceRequired,
              ),
              items: widget.services
                  .map(
                    (item) => DropdownMenuItem(
                      value: item['id']?.toString(),
                      child: Text(item['name']?.toString() ?? ''),
                    ),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _serviceId = value),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).permissions,
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(AppLocalizations.of(context).viewTasks),
            value: _viewTasks,
            onChanged: _saving
                ? null
                : (value) => setState(() => _viewTasks = value),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(AppLocalizations.of(context).assignTasks),
            value: _assignTasks,
            onChanged: _saving
                ? null
                : (value) => setState(() => _assignTasks = value),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(AppLocalizations.of(context).validateTasks),
            value: _reviewTasks,
            onChanged: _saving
                ? null
                : (value) => setState(() => _reviewTasks = value),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(AppLocalizations.of(context).manageProjects),
            value: _manageProjects,
            onChanged: _saving
                ? null
                : (value) => setState(() => _manageProjects = value),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(AppLocalizations.of(context).viewEvaluations),
            value: _viewEvaluations,
            onChanged: _saving
                ? null
                : (value) => setState(() => _viewEvaluations = value),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(AppLocalizations.of(context).reviewEvaluations),
            value: _reviewEvaluations,
            onChanged: _saving
                ? null
                : (value) => setState(() => _reviewEvaluations = value),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: _saving ? null : _save,
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
  );
}

class _SupervisorSkeleton extends StatelessWidget {
  const _SupervisorSkeleton();
  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      5,
      (_) => Container(
        height: 130,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xffe9eff7),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
  );
}

class _SupervisorState extends StatelessWidget {
  const _SupervisorState({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 48),
    child: Column(
      children: [
        const Icon(Iconsax.profile_2user, size: 46, color: Color(0xff94a3b8)),
        const SizedBox(height: 14),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xff64748b)),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(AppLocalizations.of(context).retry),
          ),
        ],
      ],
    ),
  );
}

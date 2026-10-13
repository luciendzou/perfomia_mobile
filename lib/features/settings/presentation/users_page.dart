import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_client.dart';
import '../../../core/ui/app_messenger.dart';
import '../../../core/localization/app_localizations.dart';
import '../../auth/data/auth_service.dart';
import '../data/users_service.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key, required this.session});

  final AuthSession session;

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late final UsersService _usersService;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _users = const [];
  List<Map<String, dynamic>> _departments = const [];
  List<Map<String, dynamic>> _services = const [];

  @override
  void initState() {
    super.initState();
    _usersService = UsersService(
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
      final users = await _usersService.fetch();
      final departments = await _usersService.fetchReference(
        '/departments?all=true',
      );
      final services = await _usersService.fetchReference('/services?all=true');
      if (mounted) {
        setState(() {
          _users = users;
          _departments = departments;
          _services = services;
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Impossible de charger les utilisateurs.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addUser() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _UserForm(
        canManageRoles: _canManageRoles,
        canAssignSuperAdmin: _canAssignSuperAdmin,
        departments: _departments,
        services: _services,
        users: _users,
        onSubmit: (body) async {
          await _usersService.create(body);
          if (mounted) {
            Navigator.pop(context, true);
            showAppSuccess(AppLocalizations.of(context).userAdded);
          }
        },
      ),
    );
    if (created == true && mounted) await _load();
  }

  Future<void> _createInvitation() async {
    if (!_canManageUsers) return;
    final email = TextEditingController();
    var role = 'employee';
    final invitation = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                AppLocalizations.of(context).inviteUser,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).optionalEmail,
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).targetRole,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'employee',
                    child: Text(AppLocalizations.of(context).employee),
                  ),
                  DropdownMenuItem(
                    value: 'manager',
                    child: Text(AppLocalizations.of(context).manager),
                  ),
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text(AppLocalizations.of(context).admin),
                  ),
                ],
                onChanged: _canManageRoles
                    ? (value) => setModalState(() => role = value ?? 'employee')
                    : null,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: () async {
                    try {
                      final result = await _usersService.createInvitation(
                        email: email.text,
                        roleName: role,
                      );
                      if (context.mounted) {
                        Navigator.pop(context, result);
                        showAppSuccess(
                          AppLocalizations.of(context).invitationCreated,
                        );
                      }
                    } on ApiException catch (error) {
                      showAppError(error.message);
                    }
                  },
                  child: Text(AppLocalizations.of(context).generateLink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    email.dispose();
    if (!mounted || invitation == null) return;
    final token = invitation['token']?.toString() ?? '';
    if (token.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).invitationGenerated),
        content: SelectableText(token),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: token));
              if (context.mounted) {
                Navigator.pop(context);
                showAppSuccess(AppLocalizations.of(context).copied);
              }
            },
            child: Text(AppLocalizations.of(context).copy),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).close),
          ),
        ],
      ),
    );
  }

  Set<String> get _roles {
    final roles = widget.session.user['roles'];
    if (roles is List) {
      return roles
          .map((role) => role is Map ? role['name'] : role)
          .map((role) => '$role'.toLowerCase())
          .toSet();
    }
    return {widget.session.user['role']?.toString().toLowerCase() ?? ''};
  }

  bool get _canManageUsers =>
      _roles.contains('admin') || _roles.contains('super_admin');

  bool get _canManageRoles =>
      _roles.contains('admin') || _roles.contains('super_admin');

  bool get _canAssignSuperAdmin => _roles.contains('super_admin');

  String _userName(Map<String, dynamic> user) {
    final firstName = user['first_name']?.toString().trim() ?? '';
    final lastName = user['last_name']?.toString().trim() ?? '';
    final composed = '$firstName $lastName'.trim();
    if (composed.isNotEmpty && composed.toLowerCase() != 'element') {
      return composed;
    }
    final full = user['full_name']?.toString().trim();
    if (full?.isNotEmpty == true && full!.toLowerCase() != 'element') {
      return full;
    }
    final email = user['email']?.toString().trim() ?? '';
    if (email.contains('@')) {
      return email
          .split('@')
          .first
          .split(RegExp(r'[._-]+'))
          .where((part) => part.isNotEmpty)
          .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
          .join(' ');
    }
    return full?.isNotEmpty == true ? full! : 'Utilisateur';
  }

  String _userRole(Map<String, dynamic> user) {
    final roles = user['roles'];
    if (roles is List && roles.isNotEmpty) {
      final role = roles.first;
      return role is Map ? '${role['name'] ?? 'employee'}' : '$role';
    }
    return user['role_name']?.toString() ??
        user['role']?.toString() ??
        'employee';
  }

  String _referenceName(List<Map<String, dynamic>> items, dynamic id) {
    if (id == null) return AppLocalizations.of(context).notProvided;
    for (final item in items) {
      if ('${item['id']}' == '$id') {
        return item['name']?.toString() ??
            AppLocalizations.of(context).notProvided;
      }
    }
    return AppLocalizations.of(context).notProvided;
  }

  String _employmentLabel(dynamic value) => switch ('$value') {
    'active' => AppLocalizations.of(context).active,
    'inactive' => AppLocalizations.of(context).inactive,
    'terminated' => AppLocalizations.of(context).terminated,
    _ => AppLocalizations.of(context).notProvided,
  };

  String _availabilityLabel(dynamic value) => switch ('$value') {
    'active' => AppLocalizations.of(context).available,
    'on_leave' => AppLocalizations.of(context).onLeave,
    'on_permission' => AppLocalizations.of(context).permission,
    _ => AppLocalizations.of(context).notProvided,
  };

  Future<void> _editUser(Map<String, dynamic> user) async {
    if (!_canManageUsers) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _UserForm(
        user: user,
        canManageRoles: _canManageRoles,
        canAssignSuperAdmin: _canAssignSuperAdmin,
        departments: _departments,
        services: _services,
        users: _users,
        onSubmit: (body) async {
          await _usersService.update(user['id'].toString(), body);
          if (mounted) {
            Navigator.pop(context, true);
            showAppSuccess(AppLocalizations.of(context).userSaved);
          }
        },
      ),
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _showUserDetails(Map<String, dynamic> user) async {
    Widget detail(String label, dynamic value) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xff64748b)),
          ),
          const SizedBox(height: 3),
          Text(
            value?.toString().trim().isNotEmpty == true
                ? value.toString()
                : AppLocalizations.of(context).notProvided,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _userName(user),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              detail(AppLocalizations.of(context).mail, user['email']),
              detail(AppLocalizations.of(context).phone, user['phone']),
              detail(AppLocalizations.of(context).position, user['job_title']),
              detail(AppLocalizations.of(context).role, _userRole(user)),
              detail(
                AppLocalizations.of(context).department,
                _referenceName(_departments, user['department_id']),
              ),
              detail(
                AppLocalizations.of(context).service,
                _referenceName(_services, user['service_id']),
              ),
              detail(
                AppLocalizations.of(context).status,
                _employmentLabel(user['employment_status']),
              ),
              detail(
                AppLocalizations.of(context).availability,
                _availabilityLabel(user['availability_status']),
              ),
              if (user['availability_reason'] != null)
                detail(
                  AppLocalizations.of(context).reason,
                  user['availability_reason'],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resetPassword(Map<String, dynamic> user) async {
    if (!_canManageUsers) return;
    final password = TextEditingController();
    final confirmation = TextEditingController();
    final key = GlobalKey<FormState>();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppLocalizations.of(context).resetPassword,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context).resetPasswordHint),
              const SizedBox(height: 16),
              TextFormField(
                controller: password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).newPassword,
                ),
                validator: (value) =>
                    value != null && value.isNotEmpty && value.length < 8
                    ? '8 caracteres minimum.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmation,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).confirmation,
                ),
                validator: (value) => value != password.text
                    ? 'Les mots de passe ne correspondent pas.'
                    : null,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: () async {
                    if (!(key.currentState?.validate() ?? false)) return;
                    try {
                      await _usersService.resetPassword(
                        user['id'].toString(),
                        password: password.text,
                        passwordConfirmation: confirmation.text,
                      );
                      if (context.mounted) Navigator.pop(context, true);
                      showAppSuccess('Mot de passe reinitialise.');
                    } on ApiException catch (error) {
                      showAppError(error.message);
                    }
                  },
                  child: Text(AppLocalizations.of(context).reset),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    password.dispose();
    confirmation.dispose();
    if (saved == true && mounted) await _load();
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    if (!_canManageUsers) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).deleteUserTitle),
        content: Text(
          AppLocalizations.of(context).deleteUserMessage(_userName(user)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _usersService.delete(user['id'].toString());
      if (mounted) showAppSuccess(AppLocalizations.of(context).userDeleted);
      await _load();
    } on ApiException catch (error) {
      if (mounted) showAppError(error.message);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(AppLocalizations.of(context).usersTitle),
      actions: [
        if (_canManageUsers)
          IconButton(
            tooltip: 'Inviter',
            onPressed: _loading ? null : _createInvitation,
            icon: const Icon(Iconsax.link),
          ),
        IconButton(
          tooltip: 'Actualiser',
          onPressed: _loading ? null : _load,
          icon: const Icon(Iconsax.refresh),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _loading || !_canManageUsers ? null : _addUser,
      icon: const Icon(Iconsax.user_add),
      label: Text(AppLocalizations.of(context).add),
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          Text(
            AppLocalizations.of(context).userManagement,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).usersPageDescription,
            style: TextStyle(color: Color(0xff64748b), height: 1.4),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const _UsersSkeleton()
          else if (_error != null)
            _UsersState(
              icon: Iconsax.danger,
              title: AppLocalizations.of(context).loadingError,
              message: _error!,
              action: TextButton.icon(
                onPressed: _load,
                icon: const Icon(Iconsax.refresh),
                label: Text(AppLocalizations.of(context).retry),
              ),
            )
          else if (_users.isEmpty)
            _UsersState(
              icon: Iconsax.profile_2user,
              title: AppLocalizations.of(context).noUsers,
              message: AppLocalizations.of(context).addFirstUser,
            )
          else
            ..._users.map(
              (user) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: _UserRow(
                    user: user,
                    canManage: _canManageUsers,
                    onDetails: () => _showUserDetails(user),
                    onEdit: () => _editUser(user),
                    onResetPassword: () => _resetPassword(user),
                    onDelete: () => _deleteUser(user),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.canManage,
    required this.onDetails,
    required this.onEdit,
    required this.onResetPassword,
    required this.onDelete,
  });

  final Map<String, dynamic> user;
  final bool canManage;
  final VoidCallback onDetails;
  final VoidCallback onEdit;
  final VoidCallback onResetPassword;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final firstName = user['first_name']?.toString().trim() ?? '';
    final lastName = user['last_name']?.toString().trim() ?? '';
    final composedName = '$firstName $lastName'.trim();
    final fullName = user['full_name']?.toString().trim() ?? '';
    final email = user['email']?.toString().trim() ?? '';
    final hasPlaceholderName =
        composedName.toLowerCase().contains('element') ||
        fullName.toLowerCase().contains('element');
    final name = composedName.isNotEmpty && !hasPlaceholderName
        ? composedName
        : fullName.isNotEmpty && !hasPlaceholderName
        ? fullName
        : email.contains('@')
        ? email
              .split('@')
              .first
              .split(RegExp(r'[._-]+'))
              .where((part) => part.isNotEmpty)
              .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
              .join(' ')
        : 'Utilisateur';
    final roles = user['roles'];
    final role = roles is List && roles.isNotEmpty
        ? (roles.first is Map
              ? '${roles.first['name'] ?? 'employee'}'
              : '${roles.first}')
        : user['role_name']?.toString() ?? 'employee';
    final subtitle = [
      user['job_title']?.toString(),
      role,
      user['email']?.toString(),
    ].whereType<String>().where((item) => item.trim().isNotEmpty).join(' - ');

    final strings = AppLocalizations.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          (name.isEmpty ? 'U' : name.substring(0, 1)).toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      title: Text(
        name.isEmpty ? strings.user : name,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(subtitle),
      onTap: onDetails,
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'details':
              onDetails();
            case 'edit':
              onEdit();
            case 'password':
              onResetPassword();
            case 'delete':
              onDelete();
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(value: 'details', child: Text(strings.viewDetails)),
          if (canManage) ...[
            PopupMenuItem(value: 'edit', child: Text(strings.edit)),
            PopupMenuItem(
              value: 'password',
              child: Text(strings.resetPassword),
            ),
            PopupMenuItem(value: 'delete', child: Text(strings.delete)),
          ],
        ],
      ),
    );
  }
}

class _UserForm extends StatefulWidget {
  const _UserForm({
    required this.onSubmit,
    this.user,
    this.canManageRoles = false,
    this.canAssignSuperAdmin = false,
    this.departments = const [],
    this.services = const [],
    this.users = const [],
  });

  final Future<void> Function(Map<String, dynamic> body) onSubmit;
  final Map<String, dynamic>? user;
  final bool canManageRoles;
  final bool canAssignSuperAdmin;
  final List<Map<String, dynamic>> departments;
  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> users;

  @override
  State<_UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<_UserForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _jobTitle = TextEditingController();
  final _password = TextEditingController();
  final _availabilityStartsAt = TextEditingController();
  final _availabilityEndsAt = TextEditingController();
  final _availabilityReason = TextEditingController();
  String _role = 'employee';
  String? _departmentId;
  String? _serviceId;
  String? _managerId;
  String _employmentStatus = 'active';
  String _availability = 'active';
  bool _saving = false;

  bool get _editing => widget.user != null;

  void _selectService(String? value) {
    final service = widget.services.cast<Map<String, dynamic>?>().firstWhere(
      (item) => '${item?['id']}' == '$value',
      orElse: () => null,
    );
    setState(() {
      _serviceId = value;
      if (service?['name'] != null) {
        _jobTitle.text = service!['name'].toString();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    if (user == null) return;
    _firstName.text = '${user['first_name'] ?? ''}';
    _lastName.text = '${user['last_name'] ?? ''}';
    _email.text = '${user['email'] ?? ''}';
    _phone.text = '${user['phone'] ?? ''}';
    _jobTitle.text = '${user['job_title'] ?? ''}';
    _departmentId = user['department_id']?.toString();
    _serviceId = user['service_id']?.toString();
    _managerId = user['manager_id']?.toString();
    _employmentStatus = user['employment_status']?.toString() ?? 'active';
    _availability = user['availability_status']?.toString() ?? 'active';
    _availabilityStartsAt.text = '${user['availability_starts_at'] ?? ''}';
    _availabilityEndsAt.text = '${user['availability_ends_at'] ?? ''}';
    _availabilityReason.text = '${user['availability_reason'] ?? ''}';
    final roles = user['roles'];
    _role = roles is List && roles.isNotEmpty
        ? (roles.first is Map
              ? '${roles.first['name'] ?? 'employee'}'
              : '${roles.first}')
        : '${user['role_name'] ?? user['role'] ?? 'employee'}';
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _jobTitle.dispose();
    _password.dispose();
    _availabilityStartsAt.dispose();
    _availabilityEndsAt.dispose();
    _availabilityReason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await widget.onSubmit({
        'first_name': _firstName.text.trim(),
        'last_name': _lastName.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'job_title': _jobTitle.text.trim().isEmpty
            ? null
            : _jobTitle.text.trim(),
        if (!_editing || _password.text.trim().isNotEmpty)
          'password': _password.text,
        if (widget.canManageRoles) 'role_name': _role,
        'department_id': _departmentId,
        'service_id': _serviceId,
        'manager_id': _managerId,
        'employment_status': _employmentStatus,
        'availability_status': _availability,
        if (_availability != 'active') ...{
          'availability_starts_at': _availabilityStartsAt.text.trim().isEmpty
              ? null
              : _availabilityStartsAt.text.trim(),
          'availability_ends_at': _availabilityEndsAt.text.trim().isEmpty
              ? null
              : _availabilityEndsAt.text.trim(),
          'availability_reason': _availabilityReason.text.trim().isEmpty
              ? null
              : _availabilityReason.text.trim(),
        },
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _editing
                  ? AppLocalizations.of(context).edit
                  : AppLocalizations.of(context).addUser,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            _field(
              _firstName,
              AppLocalizations.of(context).firstName,
              required: true,
            ),
            _field(
              _lastName,
              AppLocalizations.of(context).lastName,
              required: true,
            ),
            _field(
              _email,
              AppLocalizations.of(context).email,
              keyboard: TextInputType.emailAddress,
              required: true,
            ),
            _field(
              _phone,
              AppLocalizations.of(context).phone,
              keyboard: TextInputType.phone,
            ),
            _field(
              _jobTitle,
              AppLocalizations.of(context).jobTitle,
              readOnly: true,
            ),
            Text(
              AppLocalizations.of(context).organization,
              style: TextStyle(
                color: Color(0xff64748b),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _departmentId,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).department,
              ),
              items: widget.departments
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item['id']?.toString(),
                      child: Text(item['name']?.toString() ?? 'Departement'),
                    ),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _departmentId = value),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _serviceId,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).service,
              ),
              items: widget.services
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item['id']?.toString(),
                      child: Text(item['name']?.toString() ?? 'Service'),
                    ),
                  )
                  .toList(),
              onChanged: _saving ? null : _selectService,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _managerId,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).supervisor,
              ),
              items:
                  widget.users
                      .where(
                        (item) =>
                            item['id']?.toString() !=
                            widget.user?['id']?.toString(),
                      )
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item['id']?.toString(),
                          child: Text(
                            '${item['first_name'] ?? ''} ${item['last_name'] ?? ''}'
                                .trim(),
                          ),
                        ),
                      )
                      .toList()
                    ..insert(
                      0,
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(AppLocalizations.of(context).noSupervisor),
                      ),
                    ),
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _managerId = value),
            ),
            const SizedBox(height: 14),
            Text(
              AppLocalizations.of(context).availabilityStatusSection,
              style: TextStyle(
                color: Color(0xff64748b),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _employmentStatus,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).employmentStatus,
              ),
              items: [
                DropdownMenuItem(
                  value: 'active',
                  child: Text(AppLocalizations.of(context).active),
                ),
                DropdownMenuItem(
                  value: 'inactive',
                  child: Text(AppLocalizations.of(context).inactive),
                ),
                DropdownMenuItem(
                  value: 'terminated',
                  child: Text(AppLocalizations.of(context).terminated),
                ),
              ],
              onChanged: _saving
                  ? null
                  : (value) =>
                        setState(() => _employmentStatus = value ?? 'active'),
            ),
            const SizedBox(height: 16),
            if (widget.canManageRoles)
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).role,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'employee',
                    child: Text(AppLocalizations.of(context).employee),
                  ),
                  DropdownMenuItem(
                    value: 'manager',
                    child: Text(AppLocalizations.of(context).manager),
                  ),
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text(AppLocalizations.of(context).admin),
                  ),
                  if (widget.canAssignSuperAdmin)
                    DropdownMenuItem(
                      value: 'super_admin',
                      child: Text(AppLocalizations.of(context).superAdmin),
                    ),
                ],
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _role = value ?? 'employee'),
              ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _availability,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).availability,
              ),
              items: [
                DropdownMenuItem(
                  value: 'active',
                  child: Text(AppLocalizations.of(context).available),
                ),
                DropdownMenuItem(
                  value: 'on_leave',
                  child: Text(AppLocalizations.of(context).onLeave),
                ),
                DropdownMenuItem(
                  value: 'on_permission',
                  child: Text(AppLocalizations.of(context).permission),
                ),
              ],
              onChanged: _saving
                  ? null
                  : (value) =>
                        setState(() => _availability = value ?? 'active'),
            ),
            if (_availability != 'active') ...[
              const SizedBox(height: 14),
              _field(
                _availabilityStartsAt,
                AppLocalizations.of(context).startUnavailable,
                keyboard: TextInputType.datetime,
              ),
              _field(
                _availabilityEndsAt,
                AppLocalizations.of(context).endUnavailable,
                keyboard: TextInputType.datetime,
              ),
              _field(
                _availabilityReason,
                AppLocalizations.of(context).unavailableReason,
              ),
            ],
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context).accessSection,
              style: TextStyle(
                color: Color(0xff64748b),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            _field(
              _password,
              _editing
                  ? AppLocalizations.of(context).passwordOptional
                  : AppLocalizations.of(context).temporaryPassword,
              obscure: true,
              required: !_editing,
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _editing
                            ? AppLocalizations.of(context).saveChanges
                            : AppLocalizations.of(context).createAccount,
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool obscure = false,
    bool readOnly = false,
    TextInputType? keyboard,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      obscureText: obscure,
      readOnly: readOnly,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (value) => value == null || value.trim().isEmpty
                ? 'Champ obligatoire.'
                : null
          : null,
    ),
  );
}

class _UsersSkeleton extends StatelessWidget {
  const _UsersSkeleton();

  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      6,
      (_) => Container(
        height: 78,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xffe9eff7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const _SkeletonBlock(width: 44, height: 44, radius: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  _SkeletonBlock(width: 150, height: 13),
                  SizedBox(height: 8),
                  _SkeletonBlock(width: 220, height: 10),
                ],
              ),
            ),
            const _SkeletonBlock(width: 24, height: 24, radius: 12),
          ],
        ),
      ),
    ),
  );
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.width,
    required this.height,
    this.radius = 6,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xffdbe5f0),
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

class _UsersState extends StatelessWidget {
  const _UsersState({
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

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/network/api_client.dart';
import '../../../core/localization/app_localizations.dart';
import '../../auth/data/auth_service.dart';
import '../data/activity_log_service.dart';

class ActivityLogsPage extends StatefulWidget {
  const ActivityLogsPage({super.key, required this.session});

  final AuthSession session;

  @override
  State<ActivityLogsPage> createState() => _ActivityLogsPageState();
}

class _ActivityLogsPageState extends State<ActivityLogsPage> {
  late final ActivityLogService _service;
  final _search = TextEditingController();
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;
  String? _error;
  String _entityType = '';
  String _action = '';
  String _userId = '';
  String _dateFrom = '';
  String _dateTo = '';
  int _page = 1;
  int _lastPage = 1;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _service = ActivityLogService(
      apiClient: ApiClient(accessToken: widget.session.token),
    );
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
        entityType: _entityType,
        action: _action,
        userId: _userId,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        page: _page,
      );
      if (mounted) {
        setState(() {
          _items = result.items;
          _page = result.currentPage;
          _lastPage = result.lastPage;
          _total = result.total;
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).activityLoadError);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _entityLabel(dynamic value, BuildContext context) {
    final raw = '$value';
    final short = raw.split('\\').last;
    final labels = <String, String>{
      'user': AppLocalizations.of(context).userEntity,
      'project': AppLocalizations.of(context).projectEntity,
      'task': AppLocalizations.of(context).taskEntity,
      'courrier': AppLocalizations.of(context).courrierEntity,
      'evaluation': AppLocalizations.of(context).evaluationEntity,
      'company': AppLocalizations.of(context).companyEntity,
    };
    final known = labels[raw.toLowerCase()] ?? labels[short.toLowerCase()];
    if (known != null) return known;
    return short.replaceAll('_', ' ');
  }

  String _actionLabel(dynamic value) => '$value'
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

  String _actor(Map<String, dynamic> item, BuildContext context) {
    final user = item['user'];
    if (user is Map) {
      final name =
          user['full_name'] ??
          '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
      if ('$name'.trim().isNotEmpty) return '$name';
      if (user['email'] != null) return '${user['email']}';
    }
    return item['user_id']?.toString() ??
        AppLocalizations.of(context).unknownUser;
  }

  String _date(dynamic value, BuildContext context) {
    final raw = value?.toString() ?? '';
    if (raw.length < 16) {
      return raw.isEmpty ? AppLocalizations.of(context).unknownDate : raw;
    }
    return '${raw.substring(0, 10)} a ${raw.substring(11, 16)}';
  }

  String _message(Map<String, dynamic> item, BuildContext context) =>
      (item['business_message'] ??
              item['description'] ??
              '${_actionLabel(item['action'])} - ${_entityLabel(item['entity_type'], context)}')
          .toString();

  List<Map<String, String>> _entityOptions(BuildContext context) {
    final values = _items
        .map((item) => item['entity_type']?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    return values
        .map((value) => {'value': value, 'label': _entityLabel(value, context)})
        .toList();
  }

  List<Map<String, String>> get _actionOptions {
    final values = _items
        .map((item) => item['action']?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    return values
        .map((value) => {'value': value, 'label': _actionLabel(value)})
        .toList();
  }

  List<Map<String, String>> _userOptions(BuildContext context) {
    final values = <String, String>{};
    for (final item in _items) {
      final id = item['user_id']?.toString();
      if (id != null && id.isNotEmpty) values[id] = _actor(item, context);
    }
    return values.entries
        .map((entry) => {'value': entry.key, 'label': entry.value})
        .toList();
  }

  int get _activeFilterCount => [
    _entityType,
    _action,
    _userId,
    _dateFrom,
    _dateTo,
  ].where((value) => value.isNotEmpty).length;

  Future<void> _openFilters() async {
    var entity = _entityType;
    var action = _action;
    var user = _userId;
    var from = _dateFrom;
    var to = _dateTo;
    final result = await showModalBottomSheet<bool>(
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppLocalizations.of(context).filterActivityLog,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                _filterSelect(
                  context: context,
                  label: AppLocalizations.of(context).module,
                  value: entity,
                  options: _entityOptions(context),
                  onChanged: (value) =>
                      setModalState(() => entity = value ?? ''),
                ),
                const SizedBox(height: 14),
                _filterSelect(
                  context: context,
                  label: AppLocalizations.of(context).action,
                  value: action,
                  options: _actionOptions,
                  onChanged: (value) =>
                      setModalState(() => action = value ?? ''),
                ),
                const SizedBox(height: 14),
                _filterSelect(
                  context: context,
                  label: AppLocalizations.of(context).user,
                  value: user,
                  options: _userOptions(context),
                  onChanged: (value) => setModalState(() => user = value ?? ''),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  initialValue: from,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).startDate,
                  ),
                  onChanged: (value) => from = value,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  initialValue: to,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).endDate,
                  ),
                  onChanged: (value) => to = value,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: () {
                      _entityType = entity;
                      _action = action;
                      _userId = user;
                      _dateFrom = from;
                      _dateTo = to;
                      Navigator.pop(context, true);
                    },
                    child: Text(AppLocalizations.of(context).apply),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      _entityType = '';
                      _action = '';
                      _userId = '';
                      _dateFrom = '';
                      _dateTo = '';
                      Navigator.pop(context, true);
                    },
                    child: Text(AppLocalizations.of(context).reset),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result == true && mounted) await _load(page: 1);
  }

  Widget _filterSelect({
    required BuildContext context,
    required String label,
    required String value,
    required List<Map<String, String>> options,
    required ValueChanged<String?> onChanged,
  }) => DropdownButtonFormField<String>(
    initialValue: value.isEmpty ? null : value,
    decoration: InputDecoration(labelText: label),
    items: [
      DropdownMenuItem<String>(
        value: null,
        child: Text(AppLocalizations.of(context).allItems(label)),
      ),
      ...options.map(
        (item) => DropdownMenuItem<String>(
          value: item['value'],
          child: Text(item['label'] ?? ''),
        ),
      ),
    ],
    onChanged: onChanged,
  );

  void _openDetails(Map<String, dynamic> item) {
    final metadata = item['metadata'];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppLocalizations.of(context).activityDetails,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              _detail(
                context,
                AppLocalizations.of(context).messageLabel,
                _message(item, context),
              ),
              _detail(
                context,
                AppLocalizations.of(context).dateLabel,
                _date(item['created_at'] ?? item['updated_at'], context),
              ),
              _detail(
                context,
                AppLocalizations.of(context).user,
                _actor(item, context),
              ),
              _detail(
                context,
                AppLocalizations.of(context).actionLabel,
                _actionLabel(item['action']),
              ),
              _detail(
                context,
                AppLocalizations.of(context).moduleLabel,
                _entityLabel(item['entity_type'], context),
              ),
              if (item['entity_id'] != null)
                _detail(
                  context,
                  AppLocalizations.of(context).identifier,
                  item['entity_id'],
                ),
              if (metadata is Map && metadata.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context).associatedData,
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                ...metadata.entries.map(
                  (entry) => _detail(context, '${entry.key}', entry.value),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(BuildContext context, String label, dynamic value) => Padding(
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
          '${value ?? AppLocalizations.of(context).notProvided}',
          style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(AppLocalizations.of(context).activityLog),
      actions: [
        IconButton(
          tooltip: AppLocalizations.of(context).refresh,
          onPressed: _loading ? null : _load,
          icon: const Icon(Iconsax.refresh),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Text(
            AppLocalizations.of(context).activityLogHeading,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).activityLogPageDescription,
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
                    hintText: AppLocalizations.of(context).searchActivity,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Stack(
                children: [
                  IconButton.filledTonal(
                    tooltip: AppLocalizations.of(context).filter,
                    onPressed: _openFilters,
                    icon: const Icon(Iconsax.filter),
                  ),
                  if (_activeFilterCount > 0)
                    Positioned(
                      right: 2,
                      top: 0,
                      child: CircleAvatar(
                        radius: 9,
                        child: Text(
                          '$_activeFilterCount',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_loading)
            const _ActivityLogSkeleton()
          else if (_error != null)
            _ActivityState(message: _error!, onRetry: _load)
          else if (_items.isEmpty)
            _ActivityState(
              message: AppLocalizations.of(context).noActivityMatch,
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context).recentActivities,
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  AppLocalizations.of(context).activityCount(_total),
                  style: const TextStyle(color: Color(0xff64748b)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._items.map(
              (item) => _ActivityLogTile(
                item: item,
                onTap: () => _openDetails(item),
                entityLabel: (value) => _entityLabel(value, context),
                actionLabel: _actionLabel,
                actor: (value) => _actor(value, context),
                date: (value) => _date(value, context),
                message: (value) => _message(value, context),
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

class _ActivityLogTile extends StatelessWidget {
  const _ActivityLogTile({
    required this.item,
    required this.onTap,
    required this.entityLabel,
    required this.actionLabel,
    required this.actor,
    required this.date,
    required this.message,
  });
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final String Function(dynamic) entityLabel;
  final String Function(dynamic) actionLabel;
  final String Function(Map<String, dynamic>) actor;
  final String Function(dynamic) date;
  final String Function(Map<String, dynamic>) message;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      contentPadding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Iconsax.refresh_2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        message(item),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          '${actor(item)}  -  ${actionLabel(item['action'])}  -  ${entityLabel(item['entity_type'])}\n${date(item['created_at'] ?? item['updated_at'])}',
        ),
      ),
      trailing: const Icon(Iconsax.arrow_right),
      onTap: onTap,
    ),
  );
}

class _ActivityLogSkeleton extends StatelessWidget {
  const _ActivityLogSkeleton();
  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      6,
      (_) => Container(
        height: 94,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xffe9eff7),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
  );
}

class _ActivityState extends StatelessWidget {
  const _ActivityState({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 48),
    child: Column(
      children: [
        const Icon(Iconsax.refresh_2, size: 46, color: Color(0xff94a3b8)),
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

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/network/api_client.dart';
import '../../../core/ui/app_messenger.dart';
import '../../../core/localization/app_localizations.dart';
import '../../auth/data/auth_service.dart';
import '../data/evaluation_criterion_service.dart';
import '../data/users_service.dart';

class EvaluationCriteriaPage extends StatefulWidget {
  const EvaluationCriteriaPage({super.key, required this.session});
  final AuthSession session;
  @override
  State<EvaluationCriteriaPage> createState() => _EvaluationCriteriaPageState();
}

class _EvaluationCriteriaPageState extends State<EvaluationCriteriaPage> {
  late final EvaluationCriterionService _service;
  late final UsersService _references;
  final _search = TextEditingController();
  List<Map<String, dynamic>> _items = const [];
  List<Map<String, dynamic>> _departments = const [];
  List<Map<String, dynamic>> _services = const [];
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String _status = '';
  int _page = 1;
  int _lastPage = 1;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    final client = ApiClient(accessToken: widget.session.token);
    _service = EvaluationCriterionService(apiClient: client);
    _references = UsersService(apiClient: client);
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
        status: _status,
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
          () => _error = AppLocalizations.of(context).criterionLoadError,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadReferences() async {
    try {
      final result = await Future.wait([
        _references.fetchReference('/departments?all=true'),
        _references.fetchReference('/services?all=true'),
      ]);
      if (mounted) {
        setState(() {
          _departments = result[0];
          _services = result[1];
        });
      }
    } catch (_) {}
  }

  String _name(
    dynamic id,
    List<Map<String, dynamic>> values,
    BuildContext context,
  ) {
    if (id == null || '$id'.isEmpty) return AppLocalizations.of(context).all;
    for (final item in values) {
      if (item['id']?.toString() == '$id') {
        return item['name']?.toString() ??
            AppLocalizations.of(context).notProvided;
      }
    }
    return AppLocalizations.of(context).notProvided;
  }

  Future<void> _openForm([Map<String, dynamic>? item]) async {
    await _loadReferences();
    if (!mounted) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CriterionForm(
        initial: item,
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).deleteCriterionTitle),
        content: Text(AppLocalizations.of(context).deleteCriterionMessage),
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
    if (confirmed != true) return;
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

  Future<void> _openFilters() async {
    var status = _status;
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
                AppLocalizations.of(context).filterCriteria,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: status.isEmpty ? null : status,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).status,
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(AppLocalizations.of(context).allCriteria),
                  ),
                  DropdownMenuItem(
                    value: 'active',
                    child: Text(AppLocalizations.of(context).activeCriteria),
                  ),
                  DropdownMenuItem(
                    value: 'inactive',
                    child: Text(AppLocalizations.of(context).inactiveCriteria),
                  ),
                ],
                onChanged: (value) => setModalState(() => status = value ?? ''),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    _status = status;
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
                    _status = '';
                    Navigator.pop(context, true);
                  },
                  child: Text(AppLocalizations.of(context).reset),
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
      title: Text(AppLocalizations.of(context).criteriaTitle),
      actions: [
        IconButton(
          tooltip: AppLocalizations.of(context).refresh,
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
            AppLocalizations.of(context).criteriaHeading,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).criteriaPageDescription,
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
                    hintText: AppLocalizations.of(context).searchCriteria,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _openFilters,
                icon: const Icon(Iconsax.filter),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_loading)
            const _CriterionSkeleton()
          else if (_error != null)
            _CriterionState(message: _error!, onRetry: _load)
          else if (_items.isEmpty)
            _CriterionState(
              message: AppLocalizations.of(context).noCriterionMatch,
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context).configuredCriteria,
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  AppLocalizations.of(context).criterionCount(_total),
                  style: const TextStyle(color: Color(0xff64748b)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._items.map(
              (item) => _CriterionTile(
                item: item,
                department: _name(item['department_id'], _departments, context),
                service: _name(item['service_id'], _services, context),
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

class _CriterionTile extends StatelessWidget {
  const _CriterionTile({
    required this.item,
    required this.department,
    required this.service,
    required this.onEdit,
    required this.onDelete,
  });
  final Map<String, dynamic> item;
  final String department;
  final String service;
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['label']?.toString() ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(active: item['is_active'] == true),
                  ],
                ),
                if ((item['description']?.toString() ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item['description'].toString(),
                    style: const TextStyle(
                      color: Color(0xff64748b),
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _MetaChip(
                      label: item['category']?.toString().isNotEmpty == true
                          ? item['category'].toString()
                          : AppLocalizations.of(context).notProvided,
                    ),
                    _MetaChip(label: department),
                    _MetaChip(label: service),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '${item['max_score'] ?? 5}/5',
                style: const TextStyle(
                  color: Color(0xff004aad),
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'ordre ${item['sort_order'] ?? 0}',
                style: const TextStyle(fontSize: 10, color: Color(0xff94a3b8)),
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
        ],
      ),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active});
  final bool active;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: active ? const Color(0xffe7f8ef) : const Color(0xfff1f5f9),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      active
          ? AppLocalizations.of(context).activeStatus
          : AppLocalizations.of(context).inactive,
      style: TextStyle(
        fontSize: 10,
        color: active ? const Color(0xff15803d) : const Color(0xff64748b),
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});
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

class _CriterionForm extends StatefulWidget {
  const _CriterionForm({
    required this.initial,
    required this.departments,
    required this.services,
    required this.onSave,
  });
  final Map<String, dynamic>? initial;
  final List<Map<String, dynamic>> departments;
  final List<Map<String, dynamic>> services;
  final Future<void> Function(Map<String, dynamic>) onSave;
  @override
  State<_CriterionForm> createState() => _CriterionFormState();
}

class _CriterionFormState extends State<_CriterionForm> {
  late final TextEditingController _label;
  late final TextEditingController _description;
  late final TextEditingController _category;
  late final TextEditingController _order;
  String? _departmentId;
  String? _serviceId;
  int _maxScore = 5;
  bool _active = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _label = TextEditingController(
      text: widget.initial?['label']?.toString() ?? '',
    );
    _description = TextEditingController(
      text: widget.initial?['description']?.toString() ?? '',
    );
    _category = TextEditingController(
      text: widget.initial?['category']?.toString() ?? '',
    );
    _order = TextEditingController(
      text: widget.initial?['sort_order']?.toString() ?? '0',
    );
    _departmentId = widget.initial?['department_id']?.toString();
    _serviceId = widget.initial?['service_id']?.toString();
    _maxScore =
        int.tryParse(widget.initial?['max_score']?.toString() ?? '') ?? 5;
    _active = widget.initial?['is_active'] != false;
  }

  @override
  void dispose() {
    _label.dispose();
    _description.dispose();
    _category.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final max = _maxScore.clamp(1, 5);
    if (_label.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).criterionFieldsRequired),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave({
        'label': _label.text.trim(),
        'description': _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        'category': _category.text.trim().isEmpty
            ? null
            : _category.text.trim(),
        'max_score': max,
        'sort_order': int.tryParse(_order.text) ?? 0,
        'is_active': _active,
        'department_id': _departmentId,
        'service_id': _serviceId,
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
                ? AppLocalizations.of(context).addCriterion
                : AppLocalizations.of(context).editCriterion,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).criterionFormDescription,
            style: TextStyle(color: Color(0xff64748b)),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _label,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).labelRequired,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _description,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).descriptionLabel,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _category,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).category,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _maxScore,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).maxScore,
                  ),
                  items: [
                    for (var i = 1; i <= 5; i++)
                      DropdownMenuItem(value: i, child: Text('$i / 5')),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _maxScore = value ?? 5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _order,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).sortOrder,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(AppLocalizations.of(context).criterionActive),
            value: _active,
            onChanged: _saving
                ? null
                : (value) => setState(() => _active = value),
          ),
          DropdownButtonFormField<String?>(
            initialValue: _departmentId,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).optionalDepartment,
            ),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(AppLocalizations.of(context).allDepartments),
              ),
              ...widget.departments.map(
                (item) => DropdownMenuItem<String?>(
                  value: item['id']?.toString(),
                  child: Text(item['name']?.toString() ?? ''),
                ),
              ),
            ],
            onChanged: _saving
                ? null
                : (value) => setState(() => _departmentId = value),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String?>(
            initialValue: _serviceId,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).optionalService,
            ),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(AppLocalizations.of(context).allServices),
              ),
              ...widget.services.map(
                (item) => DropdownMenuItem<String?>(
                  value: item['id']?.toString(),
                  child: Text(item['name']?.toString() ?? ''),
                ),
              ),
            ],
            onChanged: _saving
                ? null
                : (value) => setState(() => _serviceId = value),
          ),
          const SizedBox(height: 20),
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

class _CriterionSkeleton extends StatelessWidget {
  const _CriterionSkeleton();
  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      5,
      (_) => Container(
        height: 142,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xffe9eff7),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
  );
}

class _CriterionState extends StatelessWidget {
  const _CriterionState({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 48),
    child: Column(
      children: [
        const Icon(Iconsax.task_square, size: 46, color: Color(0xff94a3b8)),
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

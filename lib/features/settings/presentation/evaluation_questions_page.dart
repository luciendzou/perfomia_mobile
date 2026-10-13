import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/network/api_client.dart';
import '../../../core/ui/app_messenger.dart';
import '../../../core/localization/app_localizations.dart';
import '../../auth/data/auth_service.dart';
import '../data/evaluation_question_service.dart';
import '../data/users_service.dart';

class EvaluationQuestionsPage extends StatefulWidget {
  const EvaluationQuestionsPage({super.key, required this.session});

  final AuthSession session;

  @override
  State<EvaluationQuestionsPage> createState() =>
      _EvaluationQuestionsPageState();
}

class _EvaluationQuestionsPageState extends State<EvaluationQuestionsPage> {
  late final EvaluationQuestionService _service;
  late final UsersService _referenceService;
  final _search = TextEditingController();
  List<Map<String, dynamic>> _items = const [];
  List<Map<String, dynamic>> _departments = const [];
  List<Map<String, dynamic>> _services = const [];
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _language = '';
  int _page = 1;
  int _lastPage = 1;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    final client = ApiClient(accessToken: widget.session.token);
    _service = EvaluationQuestionService(apiClient: client);
    _referenceService = UsersService(apiClient: client);
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
        language: _language,
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
          () => _error = AppLocalizations.of(context).questionsLoadError,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _referenceName(
    dynamic id,
    List<Map<String, dynamic>> values,
    BuildContext context,
  ) {
    if (id == null || '$id'.isEmpty) {
      return AppLocalizations.of(context).all;
    }
    final item = values.cast<Map<String, dynamic>?>().firstWhere(
      (value) => value?['id']?.toString() == '$id',
      orElse: () => null,
    );
    return item?['name']?.toString() ??
        AppLocalizations.of(context).notProvided;
  }

  Future<void> _loadReferences() async {
    try {
      final result = await Future.wait([
        _referenceService.fetchReference('/departments?all=true'),
        _referenceService.fetchReference('/services?all=true'),
      ]);
      if (mounted) {
        setState(() {
          _departments = result[0];
          _services = result[1];
        });
      }
    } catch (_) {
      // The question form remains usable without optional organization scopes.
    }
  }

  Future<void> _openForm([Map<String, dynamic>? item]) async {
    await _loadReferences();
    if (!mounted) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _QuestionFormSheet(
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
        title: Text(AppLocalizations.of(context).deleteQuestionTitle),
        content: Text(AppLocalizations.of(context).deleteQuestionMessage),
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
    setState(() => _saving = true);
    try {
      await _service.delete(item['id'].toString());
      if (mounted) {
        await _load(page: _page > 1 && _items.length == 1 ? _page - 1 : _page);
      }
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    showAppError(message);
  }

  Future<void> _openFilters() async {
    var language = _language;
    final result = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(context).filterQuestions,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setModalState) =>
                  DropdownButtonFormField<String>(
                    initialValue: language.isEmpty ? null : language,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).defaultLanguage,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(AppLocalizations.of(context).allLanguages),
                      ),
                      DropdownMenuItem(
                        value: 'fr',
                        child: Text(
                          AppLocalizations.of(context).frenchLanguage,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'en',
                        child: Text(
                          AppLocalizations.of(context).englishLanguage,
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setModalState(() => language = value ?? ''),
                  ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: () {
                  _language = language;
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
                  _language = '';
                  Navigator.pop(context, true);
                },
                child: Text(AppLocalizations.of(context).reset),
              ),
            ),
          ],
        ),
      ),
    );
    if (result == true && mounted) await _load(page: 1);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(AppLocalizations.of(context).questionsTitle),
      actions: [
        IconButton(
          tooltip: AppLocalizations.of(context).refresh,
          onPressed: _loading ? null : _load,
          icon: const Icon(Iconsax.refresh),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _saving ? null : _openForm,
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
            AppLocalizations.of(context).questionsTitle,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).questionsDescription,
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
                    hintText: AppLocalizations.of(context).searchQuestion,
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
            const _QuestionSkeleton()
          else if (_error != null)
            _QuestionState(message: _error!, onRetry: _load)
          else if (_items.isEmpty)
            _QuestionState(
              message: AppLocalizations.of(context).noQuestionMatch,
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context).configuredQuestions,
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  AppLocalizations.of(context).questionCount(_total),
                  style: const TextStyle(color: Color(0xff64748b)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._items.map(
              (item) => _QuestionTile(
                item: item,
                department: _referenceName(
                  item['department_id'],
                  _departments,
                  context,
                ),
                service: _referenceName(item['service_id'], _services, context),
                onEdit: () => _openForm(item),
                onDelete: _saving ? null : () => _delete(item),
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

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({
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
                Text(
                  item['question']?.toString() ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item['job_title']?.toString() ??
                      AppLocalizations.of(context).notProvided,
                  style: const TextStyle(
                    color: Color(0xff475569),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _MetaChip(label: department),
                    _MetaChip(label: service),
                    _MetaChip(
                      label: (item['language']?.toString() ?? 'fr')
                          .toUpperCase(),
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

class _QuestionFormSheet extends StatefulWidget {
  const _QuestionFormSheet({
    required this.initial,
    required this.departments,
    required this.services,
    required this.onSave,
  });
  final Map<String, dynamic>? initial;
  final List<Map<String, dynamic>> departments;
  final List<Map<String, dynamic>> services;
  final Future<void> Function(Map<String, dynamic> body) onSave;
  @override
  State<_QuestionFormSheet> createState() => _QuestionFormSheetState();
}

class _QuestionFormSheetState extends State<_QuestionFormSheet> {
  late final TextEditingController _jobTitle;
  late final TextEditingController _question;
  String? _departmentId;
  String? _serviceId;
  String _language = 'fr';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _jobTitle = TextEditingController(
      text: widget.initial?['job_title']?.toString() ?? '',
    );
    _question = TextEditingController(
      text: widget.initial?['question']?.toString() ?? '',
    );
    _departmentId = widget.initial?['department_id']?.toString();
    _serviceId = widget.initial?['service_id']?.toString();
    _language = widget.initial?['language']?.toString() ?? 'fr';
  }

  @override
  void dispose() {
    _jobTitle.dispose();
    _question.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_jobTitle.text.trim().isEmpty || _question.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).questionFieldsRequired),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave({
        'job_title': _jobTitle.text.trim(),
        'question': _question.text.trim(),
        'language': _language,
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
                ? AppLocalizations.of(context).addQuestion
                : AppLocalizations.of(context).editQuestion,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).questionFormDescription,
            style: TextStyle(color: Color(0xff64748b)),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _jobTitle,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).targetPosition,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _question,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).questionRequired,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _language,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).defaultLanguage,
            ),
            items: [
              DropdownMenuItem(
                value: 'fr',
                child: Text(AppLocalizations.of(context).frenchLanguage),
              ),
              DropdownMenuItem(
                value: 'en',
                child: Text(AppLocalizations.of(context).englishLanguage),
              ),
            ],
            onChanged: _saving
                ? null
                : (value) => setState(() => _language = value ?? 'fr'),
          ),
          const SizedBox(height: 14),
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

class _QuestionSkeleton extends StatelessWidget {
  const _QuestionSkeleton();
  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      5,
      (_) => Container(
        height: 128,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xffe9eff7),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
  );
}

class _QuestionState extends StatelessWidget {
  const _QuestionState({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 48),
    child: Column(
      children: [
        const Icon(
          Iconsax.message_question,
          size: 46,
          color: Color(0xff94a3b8),
        ),
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

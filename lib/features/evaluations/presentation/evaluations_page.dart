import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/network/api_client.dart';
import '../../../core/ui/app_messenger.dart';
import '../../../core/localization/app_localizations.dart';
import '../../auth/data/auth_service.dart';
import '../data/evaluation_service.dart';
import 'evaluation_detail_page.dart';

class EvaluationsPage extends StatefulWidget {
  const EvaluationsPage({super.key, required this.session});
  final AuthSession session;
  @override
  State<EvaluationsPage> createState() => _EvaluationsPageState();
}

class _EvaluationsPageState extends State<EvaluationsPage> {
  late final EvaluationService _service;
  final _search = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _starting = false;
  int _page = 1;
  int _lastPage = 1;
  String _status = 'all';
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = EvaluationService(
      apiClient: ApiClient(accessToken: widget.session.token),
    );
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 500) _loadMore();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
      _lastPage = 1;
    });
    try {
      final result = await _service.fetch(
        search: _search.text,
        status: _status,
      );
      if (mounted) {
        setState(() {
          _items = result.items;
          _page = result.page;
          _lastPage = result.lastPage;
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = AppLocalizations.of(context).evaluationLoadError,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || _page >= _lastPage) return;
    setState(() => _loadingMore = true);
    try {
      final result = await _service.fetch(
        search: _search.text,
        status: _status,
        page: _page + 1,
      );
      if (mounted) {
        setState(() {
          _items = [..._items, ...result.items];
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

  String _person(Map<String, dynamic> item) {
    final user = item['user'] is Map
        ? Map<String, dynamic>.from(item['user'] as Map)
        : <String, dynamic>{};
    return (user['full_name'] ??
            user['name'] ??
            '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}')
        .toString()
        .trim();
  }

  Map<String, String> _statuses(BuildContext context) => {
    'all': AppLocalizations.of(context).allEvaluations,
    'not_started': AppLocalizations.of(context).evaluationNotStarted,
    'self_in_progress': AppLocalizations.of(context).evaluationInProgress,
    'manager_review_pending': AppLocalizations.of(context).managerReviewPending,
    'ai_scored': AppLocalizations.of(context).aiScoreAvailable,
    'manager_reviewed': AppLocalizations.of(context).managerReviewed,
    'admin_review_pending': AppLocalizations.of(context).adminReviewPending,
    'completed': AppLocalizations.of(context).completedEvaluations,
  };

  String _statusLabel(String? value, BuildContext context) =>
      _statuses(context)[value] ??
      value?.replaceAll('_', ' ') ??
      AppLocalizations.of(context).evaluationNotStarted;

  bool get _canStartSelfEvaluation {
    final roles = widget.session.user['roles'];
    final names = roles is List
        ? roles
              .map((role) => role is Map ? role['name'] : role)
              .map((role) => '$role'.toLowerCase())
              .toSet()
        : <String>{widget.session.user['role']?.toString().toLowerCase() ?? ''};
    return !names.contains('admin') && !names.contains('hyper_admin');
  }

  Future<void> _startEvaluation() async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      final data = await _service.start(
        userId: widget.session.user['id']?.toString() ?? '',
        year: DateTime.now().year,
      );
      final evaluation = data['evaluation'];
      final id = evaluation is Map
          ? evaluation['id']?.toString()
          : data['id']?.toString();
      if (!mounted) return;
      if (id == null || id.isEmpty) {
        throw ApiException(
          AppLocalizations.of(context).evaluationCreatedWithoutId,
        );
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              EvaluationDetailPage(session: widget.session, evaluationId: id),
        ),
      );
      await _load();
    } on ApiException catch (error) {
      if (mounted) showAppError(error.message);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _openFilters() async {
    final strings = AppLocalizations.of(context);
    var selectedStatus = _status;
    final result = await showModalBottomSheet<String>(
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
                strings.filterEvaluations,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                decoration: InputDecoration(labelText: strings.status),
                items: _statuses(context).entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setModalState(() => selectedStatus = value);
                  }
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, selectedStatus),
                  child: Text(strings.apply),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _status = result);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.evaluationTitle),
        actions: [
          if (_canStartSelfEvaluation)
            TextButton.icon(
              onPressed: _starting ? null : _startEvaluation,
              icon: _starting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Iconsax.play),
              label: Text(strings.start),
            ),
          IconButton(onPressed: _load, icon: const Icon(Iconsax.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            Text(
              strings.evaluationTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              strings.evaluationsListDescription,
              style: TextStyle(color: Colors.blueGrey.shade600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onSubmitted: (_) => _load(),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Iconsax.search_normal),
                      hintText: strings.searchCollaborator,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: strings.filterEvaluations,
                  onPressed: _openFilters,
                  icon: const Icon(Iconsax.filter),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_loading) ...[
              const _EvaluationSkeleton(),
            ] else if (_error != null) ...[
              _EvaluationError(message: _error!, onRetry: _load),
            ] else if (_items.isEmpty) ...[
              _EvaluationEmpty(
                canStart: _canStartSelfEvaluation,
                onStart: _startEvaluation,
              ),
            ] else ...[
              ..._items.map(
                (item) => _EvaluationRow(
                  name: _person(item).isEmpty
                      ? strings.unknownEvaluationUser
                      : _person(item),
                  year: '${item['year'] ?? '-'}',
                  status: _statusLabel(item['status']?.toString(), context),
                  score: item['final_score'] ?? item['task_score'],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EvaluationDetailPage(
                        session: widget.session,
                        evaluationId: item['id'].toString(),
                      ),
                    ),
                  ),
                ),
              ),
              if (_loadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EvaluationRow extends StatelessWidget {
  const _EvaluationRow({
    required this.name,
    required this.year,
    required this.status,
    this.score,
    this.onTap,
  });
  final String name, year, status;
  final dynamic score;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(child: Text(name.substring(0, 1).toUpperCase())),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text('$year  -  $status'),
      trailing: Text(
        score == null ? '-' : '$score%',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      onTap: onTap,
    ),
  );
}

class _EvaluationSkeleton extends StatelessWidget {
  const _EvaluationSkeleton();
  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      5,
      (_) => Container(
        height: 78,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xffe9eff7),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
  );
}

class _EvaluationEmpty extends StatelessWidget {
  const _EvaluationEmpty({required this.canStart, required this.onStart});
  final bool canStart;
  final VoidCallback onStart;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Center(
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context).noEvaluationMatch,
            textAlign: TextAlign.center,
          ),
          if (canStart) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Iconsax.play),
                label: Text(AppLocalizations.of(context).startMyEvaluation),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _EvaluationError extends StatelessWidget {
  const _EvaluationError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(message, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: onRetry,
        child: Text(AppLocalizations.of(context).retry),
      ),
    ],
  );
}

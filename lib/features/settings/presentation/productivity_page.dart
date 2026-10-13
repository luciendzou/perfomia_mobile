import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/network/api_client.dart';
import '../../../core/localization/app_localizations.dart';
import '../../auth/data/auth_service.dart';
import '../data/productivity_service.dart';

class ProductivityPage extends StatefulWidget {
  const ProductivityPage({super.key, required this.session});
  final AuthSession session;
  @override
  State<ProductivityPage> createState() => _ProductivityPageState();
}

class _ProductivityPageState extends State<ProductivityPage> {
  late final ProductivityService _service;
  ProductivityData? _data;
  bool _loading = true;
  String? _error;
  int _tab = 0;
  int _eventPage = 1;
  int _rulePage = 1;

  @override
  void initState() {
    super.initState();
    _service = ProductivityService(
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
      final data = await _service.fetch();
      if (mounted) {
        setState(() {
          _data = data;
          _eventPage = 1;
          _rulePage = 1;
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = AppLocalizations.of(context).productivityLoadError,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _ruleRows {
    final rules = _data?.rules;
    if (rules is List) {
      return rules
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (rules is! Map) return const [];
    final rows = <Map<String, dynamic>>[];
    for (final section in rules.entries) {
      if (section.value is! Map) continue;
      for (final item in (section.value as Map).entries) {
        if ({
          'score_mode',
          'score_min',
          'score_max',
          'admin_excluded',
          'super_admin_excluded',
        }.contains(item.key)) {
          continue;
        }
        rows.add({
          'section': _label(section.key),
          'label': _label(item.key),
          'value': item.value,
        });
      }
    }
    return rows;
  }

  List<Map<String, dynamic>> _slice(
    List<Map<String, dynamic>> values,
    int page,
  ) => values.skip((page - 1) * 8).take(8).toList();
  String _label(dynamic value) => '$value'
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
  String _date(dynamic value) {
    final raw = '$value';
    return raw.length >= 16
        ? '${raw.substring(0, 10)} ${raw.substring(11, 16)}'
        : raw;
  }

  double _number(dynamic value) => double.tryParse('$value') ?? 0;

  @override
  Widget build(BuildContext context) {
    final events = _data?.events ?? const <Map<String, dynamic>>[];
    final rules = _ruleRows;
    final eventPages = events.isEmpty ? 1 : (events.length / 8).ceil();
    final rulePages = rules.isEmpty ? 1 : (rules.length / 8).ceil();
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).productivityTitle),
        actions: [
          IconButton(
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
              AppLocalizations.of(context).productivityTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context).productivityDescriptionSettings,
              style: TextStyle(color: Color(0xff64748b), height: 1.4),
            ),
            const SizedBox(height: 18),
            if (_loading)
              const _ProductivitySkeleton()
            else if (_error != null)
              _ProductivityState(message: _error!, onRetry: _load)
            else ...[
              _ScoreCard(score: _data?.score),
              const SizedBox(height: 16),
              SegmentedButton<int>(
                segments: [
                  ButtonSegment(
                    value: 0,
                    label: Text(
                      AppLocalizations.of(context).productivityEvents,
                    ),
                    icon: Icon(Iconsax.activity),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text(AppLocalizations.of(context).productivityRules),
                    icon: Icon(Iconsax.task_square),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (value) =>
                    setState(() => _tab = value.first),
              ),
              const SizedBox(height: 14),
              if (_tab == 0) ...[
                if (events.isEmpty)
                  _ProductivityState(
                    message: AppLocalizations.of(context).noProductivityEvents,
                  )
                else
                  ..._slice(events, _eventPage).map(
                    (item) =>
                        _EventTile(item: item, date: _date, number: _number),
                  ),
                if (eventPages > 1)
                  _Pager(
                    page: _eventPage,
                    pages: eventPages,
                    onPrevious: _eventPage > 1
                        ? () => setState(() => _eventPage--)
                        : null,
                    onNext: _eventPage < eventPages
                        ? () => setState(() => _eventPage++)
                        : null,
                  ),
              ] else ...[
                if (rules.isEmpty)
                  _ProductivityState(
                    message: AppLocalizations.of(context).noProductivityRules,
                  )
                else
                  ..._slice(
                    rules,
                    _rulePage,
                  ).map((item) => _RuleTile(item: item, number: _number)),
                if (rulePages > 1)
                  _Pager(
                    page: _rulePage,
                    pages: rulePages,
                    onPrevious: _rulePage > 1
                        ? () => setState(() => _rulePage--)
                        : null,
                    onNext: _rulePage < rulePages
                        ? () => setState(() => _rulePage++)
                        : null,
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score});
  final dynamic score;

  @override
  Widget build(BuildContext context) {
    final value = double.tryParse('$score') ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xffe7f0ff),
              child: Text(
                '${value.round()}%',
                style: const TextStyle(
                  color: Color(0xff175cd3),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).productivityScore,
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).productivityScoreDescription,
                    style: TextStyle(color: Color(0xff64748b)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.item,
    required this.date,
    required this.number,
  });
  final Map<String, dynamic> item;
  final String Function(dynamic) date;
  final double Function(dynamic) number;

  @override
  Widget build(BuildContext context) {
    final points = number(item['points_delta']);
    final positive = points > 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        leading: CircleAvatar(
          backgroundColor: positive
              ? const Color(0xffe7f8ef)
              : const Color(0xffffeded),
          child: Icon(
            positive ? Iconsax.trend_up : Iconsax.trend_down,
            color: positive ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          item['title']?.toString() ??
              item['reference']?.toString() ??
              AppLocalizations.of(context).event,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${item['reason_label'] ?? item['reason_code'] ?? AppLocalizations.of(context).activity}\n${date(item['occurred_at'])}',
        ),
        trailing: Text(
          '${points >= 0 ? '+' : ''}${points.toStringAsFixed(0)} ${AppLocalizations.of(context).points}',
          style: TextStyle(
            color: positive ? Colors.green : Colors.red,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _RuleTile extends StatelessWidget {
  const _RuleTile({required this.item, required this.number});
  final Map<String, dynamic> item;
  final double Function(dynamic) number;

  @override
  Widget build(BuildContext context) {
    final value = number(item['value']);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(
          item['label']?.toString() ?? '',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          item['section']?.toString() ?? AppLocalizations.of(context).rule,
        ),
        trailing: Text(
          '${value >= 0 ? '+' : ''}${value.toStringAsFixed(0)} ${AppLocalizations.of(context).points}',
          style: TextStyle(
            color: value >= 0 ? Colors.green : Colors.red,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({
    required this.page,
    required this.pages,
    required this.onPrevious,
    required this.onNext,
  });
  final int page;
  final int pages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      OutlinedButton(
        onPressed: onPrevious,
        child: Text(AppLocalizations.of(context).previous),
      ),
      Text('Page $page / $pages'),
      OutlinedButton(
        onPressed: onNext,
        child: Text(AppLocalizations.of(context).next),
      ),
    ],
  );
}

class _ProductivitySkeleton extends StatelessWidget {
  const _ProductivitySkeleton();
  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      5,
      (_) => Container(
        height: 82,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xffe9eff7),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
  );
}

class _ProductivityState extends StatelessWidget {
  const _ProductivityState({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 48),
    child: Column(
      children: [
        const Icon(Iconsax.chart_2, size: 46, color: Color(0xff94a3b8)),
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

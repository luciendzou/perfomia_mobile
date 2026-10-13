import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../core/ui/app_messenger.dart';
import '../../../core/localization/app_localizations.dart';
import '../../auth/data/auth_service.dart';
import '../data/report_service.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key, required this.session});
  final AuthSession session;
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late Future<ReportBundle> _future;
  String _tab = 'productivity';
  String _projectStatus = 'all';
  String _courrierType = 'all';
  DateTime? _from;
  DateTime? _to;

  bool get _companyScope {
    final roles = widget.session.user['roles'];
    final names = roles is List
        ? roles
              .map((role) => role is Map ? role['name'] : role)
              .map((role) => '$role'.toLowerCase())
              .toSet()
        : <String>{widget.session.user['role']?.toString().toLowerCase() ?? ''};
    return names.contains('admin');
  }

  String? _date(DateTime? value) => value == null
      ? null
      : '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<ReportBundle> _load() => ReportService().fetch(
    userId: widget.session.user['id']?.toString() ?? '',
    companyScope: _companyScope,
    from: _date(_from),
    to: _date(_to),
    projectStatus: _projectStatus,
    courrierType: _courrierType,
  );

  void _reload() {
    setState(() => _future = _load());
  }

  Future<void> _refresh() async {
    _reload();
    try {
      await _future;
    } catch (error) {
      if (mounted) showAppError(error.toString());
    }
  }

  double _score(ReportBundle report) =>
      (double.tryParse(
                '${report.productivity['productivity_score'] ?? report.productivity['avgProductivity'] ?? 0}',
              ) ??
              0)
          .clamp(0, 100);

  Future<void> _exportPdf() async {
    try {
      final strings = AppLocalizations.of(context);
      final report = await _future;
      final taskSummary = report.tasks['summary'] is Map
          ? Map<String, dynamic>.from(report.tasks['summary'] as Map)
          : <String, dynamic>{};
      final projectSummary = report.projects['summary'] is Map
          ? Map<String, dynamic>.from(report.projects['summary'] as Map)
          : <String, dynamic>{};
      final courrierSummary = report.courriers['summary'] is Map
          ? Map<String, dynamic>.from(report.courriers['summary'] as Map)
          : <String, dynamic>{};
      final document = pw.Document();
      document.addPage(
        pw.MultiPage(
          build: (_) => [
            pw.Header(level: 0, text: strings.reportsTitle),
            pw.Text(
              _companyScope ? strings.companyView : strings.myPerformance,
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: [strings.indicator, strings.value],
              data: [
                [strings.productivity, '${_score(report)}%'],
                [strings.totalTasks, '${taskSummary['totalTasks'] ?? 0}'],
                [
                  strings.completedTasks,
                  '${taskSummary['completedTasks'] ?? 0}',
                ],
                [strings.overdueTasks, '${taskSummary['overdueTasks'] ?? 0}'],
                [
                  strings.totalProjects,
                  '${projectSummary['totalProjects'] ?? 0}',
                ],
                [
                  strings.activeProjects,
                  '${projectSummary['activeProjects'] ?? 0}',
                ],
                [
                  strings.projectsAtRisk,
                  '${projectSummary['projectsAtRisk'] ?? 0}',
                ],
                [
                  strings.totalCourriers,
                  '${courrierSummary['totalCourriers'] ?? 0}',
                ],
                [
                  strings.pendingCourriers,
                  '${courrierSummary['pendingCourriers'] ?? 0}',
                ],
              ],
            ),
          ],
        ),
      );
      final bytes = await document.save();
      await SharePlus.instance.share(
        ShareParams(
          title: strings.reportsTitle,
          files: [
            XFile.fromData(
              Uint8List.fromList(bytes),
              name: 'rapport-perfomia.pdf',
              mimeType: 'application/pdf',
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        showAppError('${AppLocalizations.of(context).exportPdfError}$error');
      }
    }
  }

  Future<void> _exportExcel() async {
    try {
      final strings = AppLocalizations.of(context);
      final report = await _future;
      final taskSummary = report.tasks['summary'] is Map
          ? Map<String, dynamic>.from(report.tasks['summary'] as Map)
          : <String, dynamic>{};
      final projectSummary = report.projects['summary'] is Map
          ? Map<String, dynamic>.from(report.projects['summary'] as Map)
          : <String, dynamic>{};
      final courrierSummary = report.courriers['summary'] is Map
          ? Map<String, dynamic>.from(report.courriers['summary'] as Map)
          : <String, dynamic>{};
      final workbook = Excel.createExcel();
      final sheet = workbook['Rapport'];
      sheet.appendRow([
        TextCellValue(strings.indicator),
        TextCellValue(strings.value),
      ]);
      final rows = {
        strings.productivity: '${_score(report)}%',
        strings.totalTasks: '${taskSummary['totalTasks'] ?? 0}',
        strings.completedTasks: '${taskSummary['completedTasks'] ?? 0}',
        strings.overdueTasks: '${taskSummary['overdueTasks'] ?? 0}',
        strings.totalProjects: '${projectSummary['totalProjects'] ?? 0}',
        strings.activeProjects: '${projectSummary['activeProjects'] ?? 0}',
        strings.projectsAtRisk: '${projectSummary['projectsAtRisk'] ?? 0}',
        strings.totalCourriers: '${courrierSummary['totalCourriers'] ?? 0}',
        strings.pendingCourriers: '${courrierSummary['pendingCourriers'] ?? 0}',
      };
      for (final entry in rows.entries) {
        sheet.appendRow([TextCellValue(entry.key), TextCellValue(entry.value)]);
      }
      final bytes = workbook.save();
      if (bytes == null) throw Exception('Fichier vide');
      await SharePlus.instance.share(
        ShareParams(
          title: strings.reportsTitle,
          files: [
            XFile.fromData(
              Uint8List.fromList(bytes),
              name: 'rapport-perfomia.xlsx',
              mimeType:
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        showAppError('${AppLocalizations.of(context).exportExcelError}$error');
      }
    }
  }

  Future<void> _pickPeriod() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _from != null && _to != null
          ? DateTimeRange(start: _from!, end: _to!)
          : null,
    );
    if (range == null) return;
    setState(() {
      _from = range.start;
      _to = range.end;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.reportsTitle),
        actions: [
          PopupMenuButton<String>(
            tooltip: strings.export,
            icon: const Icon(Iconsax.export_3),
            onSelected: (value) =>
                value == 'pdf' ? _exportPdf() : _exportExcel(),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'pdf', child: Text(strings.exportPdf)),
              PopupMenuItem(value: 'excel', child: Text(strings.exportExcel)),
            ],
          ),
          IconButton(
            tooltip: strings.refresh,
            onPressed: _refresh,
            icon: const Icon(Iconsax.refresh),
          ),
        ],
      ),
      body: FutureBuilder<ReportBundle>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _ReportSkeleton();
          }
          if (snapshot.hasError || snapshot.data == null) {
            return _ReportError(onRetry: _refresh);
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: _ReportContent(
              report: snapshot.data!,
              companyScope: _companyScope,
              tab: _tab,
              projectStatus: _projectStatus,
              courrierType: _courrierType,
              hasPeriod: _from != null && _to != null,
              onTabChanged: (value) => setState(() => _tab = value),
              onPeriod: _pickPeriod,
              onProjectStatus: (value) {
                setState(() {
                  _projectStatus = value;
                  _future = _load();
                });
              },
              onCourrierType: (value) {
                setState(() {
                  _courrierType = value;
                  _future = _load();
                });
              },
            ),
          );
        },
      ),
    );
  }
}

class _ReportContent extends StatelessWidget {
  const _ReportContent({
    required this.report,
    required this.companyScope,
    required this.tab,
    required this.projectStatus,
    required this.courrierType,
    required this.hasPeriod,
    required this.onTabChanged,
    required this.onPeriod,
    required this.onProjectStatus,
    required this.onCourrierType,
  });
  final ReportBundle report;
  final bool companyScope;
  final String tab;
  final String projectStatus;
  final String courrierType;
  final bool hasPeriod;
  final ValueChanged<String> onTabChanged;
  final VoidCallback onPeriod;
  final ValueChanged<String> onProjectStatus;
  final ValueChanged<String> onCourrierType;

  Map<String, dynamic> _summary(Map<String, dynamic> value) =>
      value['summary'] is Map<String, dynamic>
      ? value['summary'] as Map<String, dynamic>
      : <String, dynamic>{};
  int _number(Map<String, dynamic> value, String key) =>
      int.tryParse('${value[key] ?? 0}') ?? 0;
  double _score() =>
      (double.tryParse(
                '${report.productivity['productivity_score'] ?? report.productivity['avgProductivity'] ?? 0}',
              ) ??
              0)
          .clamp(0, 100);

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final taskSummary = _summary(report.tasks);
    final projectSummary = _summary(report.projects);
    final courrierSummary = _summary(report.courriers);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        Text(
          companyScope ? strings.companyView : strings.myPerformance,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          strings.reportActivityDescription,
          style: TextStyle(color: Colors.blueGrey.shade600),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _Tab(
                label: strings.productivity,
                value: 'productivity',
                active: tab,
                onTap: onTabChanged,
              ),
              _Tab(
                label: strings.tasks,
                value: 'tasks',
                active: tab,
                onTap: onTabChanged,
              ),
              _Tab(
                label: strings.projects,
                value: 'projects',
                active: tab,
                onTap: onTabChanged,
              ),
              _Tab(
                label: strings.courriers,
                value: 'courriers',
                active: tab,
                onTap: onTabChanged,
              ),
              if (companyScope)
                _Tab(
                  label: strings.topEmployees,
                  value: 'employees',
                  active: tab,
                  onTap: onTabChanged,
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onPeriod,
          icon: const Icon(Iconsax.calendar),
          label: Text(
            hasPeriod ? strings.reportPeriodCustom : strings.reportLast30Days,
          ),
        ),
        if (tab == 'projects') ...[
          const SizedBox(height: 8),
          _FilterChips(
            values: {
              'all': strings.all,
              'planned': strings.planned,
              'active': strings.active,
              'on_hold': strings.onHold,
              'completed': strings.completed,
              'archived': strings.archived,
              'cancelled': strings.cancelled,
            },
            selected: projectStatus,
            onChanged: onProjectStatus,
          ),
        ],
        if (tab == 'courriers') ...[
          const SizedBox(height: 8),
          _FilterChips(
            values: {
              'all': strings.all,
              'incoming': strings.incoming,
              'outgoing': strings.outgoing,
              'internal': strings.internal,
            },
            selected: courrierType,
            onChanged: onCourrierType,
          ),
        ],
        const SizedBox(height: 16),
        if (tab == 'productivity') _Productivity(score: _score()),
        if (tab == 'tasks')
          _ReportSection(
            title: strings.tasks,
            icon: Iconsax.task_square,
            children: _metrics(taskSummary, [
              ('totalTasks', strings.total, null),
              ('completedTasks', strings.completed, Color(0xff059669)),
              ('pendingTasks', strings.pending, Color(0xff2563eb)),
              ('overdueTasks', strings.overdue, Color(0xffdc2626)),
            ]),
          ),
        if (tab == 'projects')
          _ReportSection(
            title: strings.projects,
            icon: Iconsax.folder,
            children: _metrics(projectSummary, [
              ('totalProjects', strings.total, null),
              ('activeProjects', strings.active, Color(0xff2563eb)),
              ('completedProjects', strings.completed, Color(0xff059669)),
              ('projectsAtRisk', strings.atRisk, Color(0xffdc2626)),
            ]),
          ),
        if (tab == 'courriers')
          _ReportSection(
            title: strings.courriers,
            icon: Iconsax.sms,
            children: _metrics(courrierSummary, [
              ('totalCourriers', strings.total, null),
              ('pendingCourriers', strings.pending, Color(0xff2563eb)),
              ('overdueCourriers', strings.overdue, Color(0xffdc2626)),
            ]),
          ),
        if (tab == 'employees') _Employees(data: report.bestEmployees),
        if (tab == 'productivity')
          _TrendChart(
            title: strings.productivityEvolution,
            values: _trend(report.productivity['trend']),
          ),
        if (tab == 'tasks')
          _Breakdown(
            title: strings.statusDistribution,
            values: report.tasks['statusBreakdown'],
          ),
        if (tab == 'tasks')
          _TrendChart(
            title: strings.taskEvolution,
            values: _trend(report.tasks['trend']),
          ),
        if (tab == 'projects')
          _Breakdown(
            title: strings.statusDistribution,
            values: report.projects['statusBreakdown'],
          ),
        if (tab == 'projects')
          _TrendChart(
            title: strings.projectEvolution,
            values: _trend(report.projects['trend']),
          ),
        if (tab == 'courriers') ...[
          _Breakdown(
            title: strings.byStatus,
            values: report.courriers['statusBreakdown'],
          ),
          _Breakdown(
            title: strings.byType,
            values: report.courriers['typeBreakdown'],
          ),
          _TrendChart(
            title: strings.courrierEvolution,
            values: _trend(report.courriers['trend']),
          ),
        ],
      ],
    );
  }

  List<Widget> _metrics(
    Map<String, dynamic> summary,
    List<(String, String, Color?)> values,
  ) => values
      .map(
        (item) => _Metric(
          label: item.$2,
          value: _number(summary, item.$1),
          color: item.$3,
        ),
      )
      .toList();

  List<double> _trend(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) {
      if (item is! Map) return 0.0;
      return double.tryParse(
            '${item['value'] ?? item['total'] ?? item['completed'] ?? 0}',
          ) ??
          0;
    }).toList();
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.title, required this.values});
  final String title;
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            SizedBox(
              height: 150,
              width: double.infinity,
              child: CustomPaint(
                painter: _TrendPainter(
                  values: values,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${values.length} points sur la periode selectionnee',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({required this.values, required this.color});
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = values.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );
    final ceiling = maxValue <= 0 ? 1 : maxValue;
    final gridPaint = Paint()
      ..color = const Color(0xffe7edf5)
      ..strokeWidth = 1;
    for (var index = 0; index < 4; index++) {
      final y = size.height * index / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final points = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * index / (values.length - 1);
      final y =
          size.height - (values[index] / ceiling * (size.height - 10)) - 5;
      points.add(Offset(x, y));
    }
    final area = Path()..moveTo(points.first.dx, size.height);
    for (final point in points) {
      area.lineTo(point.dx, point.dy);
    }
    area.lineTo(points.last.dx, size.height);
    area.close();
    canvas.drawPath(area, Paint()..color = color.withValues(alpha: 0.10));
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      line.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    final dotPaint = Paint()..color = color;
    for (final point in points) {
      canvas.drawCircle(point, 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.value,
    required this.active,
    required this.onTap,
  });
  final String label, value, active;
  final ValueChanged<String> onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: value == active,
      onSelected: (_) => onTap(value),
    ),
  );
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.values,
    required this.selected,
    required this.onChanged,
  });
  final Map<String, String> values;
  final String selected;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: values.entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(entry.value),
                selected: entry.key == selected,
                onSelected: (_) => onChanged(entry.key),
              ),
            ),
          )
          .toList(),
    ),
  );
}

class _Productivity extends StatelessWidget {
  const _Productivity({required this.score});
  final double score;
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 13,
                      backgroundColor: const Color(0xffe6eef9),
                    ),
                  ),
                  Text(
                    '${score.round()}%',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              strings.productivityOverall,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(strings.reportScoreDescription),
          ],
        ),
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  const _ReportSection({
    required this.title,
    required this.icon,
    required this.children,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: children),
        ],
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.color});
  final String label;
  final int value;
  final Color? color;
  @override
  Widget build(BuildContext context) => Container(
    width: 132,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xfff8fafc),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600),
        ),
      ],
    ),
  );
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.title, required this.values});
  final String title;
  final dynamic values;
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final map = values is Map
        ? Map<String, dynamic>.from(values as Map)
        : <String, dynamic>{};
    if (map.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            ...map.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(_label(strings, entry.key))),
                    Text(
                      '${entry.value}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _label(AppLocalizations strings, String value) =>
      {
        'todo': strings.todo,
        'in_progress': strings.inProgress,
        'review': strings.inReview,
        'done': strings.completed,
        'planned': strings.planned,
        'active': strings.active,
        'on_hold': strings.onHold,
        'completed': strings.completed,
        'cancelled': strings.cancelled,
        'incoming': strings.incoming,
        'outgoing': strings.outgoing,
        'internal': strings.internal,
      }[value] ??
      value;
}

class _Employees extends StatelessWidget {
  const _Employees({required this.data});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final raw = data['bestEmployees'] ?? data['employees'];
    final employees = raw is List
        ? raw.whereType<Map>().toList()
        : const <Map>[];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.topEmployees,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 10),
            if (employees.isEmpty)
              Text(strings.noReportData)
            else
              ...employees.map(
                (employee) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Text(
                      '${employee['first_name'] ?? employee['name'] ?? '?'}'
                          .substring(0, 1)
                          .toUpperCase(),
                    ),
                  ),
                  title: Text(
                    '${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}'
                            .trim()
                            .isEmpty
                        ? '${employee['name'] ?? employee['email'] ?? 'Utilisateur'}'
                        : '${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}',
                  ),
                  trailing: Text(
                    '${employee['productivity_score'] ?? employee['avgProductivity'] ?? employee['score'] ?? 0}%',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReportSkeleton extends StatelessWidget {
  const _ReportSkeleton();
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: List.generate(
      6,
      (index) => Container(
        height: index == 0 ? 120 : 92,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xffe9eff7),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
  );
}

class _ReportError extends StatelessWidget {
  const _ReportError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Iconsax.chart_2, size: 42, color: Color(0xff64748b)),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).reportLoadError,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(AppLocalizations.of(context).retry),
          ),
        ],
      ),
    ),
  );
}

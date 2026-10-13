import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/ui/app_messenger.dart';
import '../../auth/data/auth_service.dart';
import '../../projects/data/project_service.dart';
import '../../projects/presentation/projects_page.dart';
import '../data/task_service.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key, required this.session});

  final AuthSession session;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  late final TaskService _service;
  late final ProjectService _projectService;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _tasks = const [];
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 0;
  int _lastPage = 1;
  String _status = 'all';
  String _priority = 'all';
  String _scope = 'all';
  String _view = 'list';
  DateTime _selectedDay = DateTime.now();
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = TaskService(
      apiClient: ApiClient(accessToken: widget.session.token),
    );
    _projectService = ProjectService(
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
        _tasks = const [];
        _page = 0;
        _lastPage = 1;
      }
    });
    try {
      final result = await _service.fetchPage(
        search: _searchController.text,
        status: _status,
        priority: _priority,
        userId: _scope == 'mine' ? widget.session.user['id']?.toString() : null,
        page: 1,
      );
      if (mounted) {
        setState(() {
          _tasks = result.items;
          _page = result.page;
          _lastPage = result.lastPage;
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Impossible de charger les taches.');
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
        priority: _priority,
        userId: _scope == 'mine' ? widget.session.user['id']?.toString() : null,
        page: _page + 1,
      );
      if (mounted) {
        setState(() {
          _tasks = [..._tasks, ...result.items];
          _page = result.page;
          _lastPage = result.lastPage;
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _create() async {
    final strings = AppLocalizations.of(context);
    try {
      final results = await Future.wait([
        _service.users(),
        _projectService.fetch(),
      ]);
      final users = results[0];
      final projects = results[1];
      if (!mounted) return;
      final body = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _GlobalTaskForm(
          users: users,
          projects: projects,
          currentUserId: widget.session.user['id']?.toString(),
        ),
      );
      if (body == null) return;
      await _service.create(body);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.taskCreated)));
        await _load();
      }
    } on ApiException catch (error) {
      if (mounted) {
        showAppError(error.message);
      }
    }
  }

  Future<void> _openFilters() async {
    final strings = AppLocalizations.of(context);
    var status = _status;
    var priority = _priority;
    var scope = _scope;
    final result = await showModalBottomSheet<Map<String, String>>(
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
                'Filtrer les tâches',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: InputDecoration(labelText: strings.status),
                items:
                    <String, String>{
                          'all': strings.allStatuses,
                          'todo': strings.toDo,
                          'in_progress': strings.inProgress,
                          'review': strings.underReview,
                          'done': strings.completed,
                        }.entries
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) setModalState(() => status = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: priority,
                decoration: InputDecoration(labelText: strings.priority),
                items:
                    <String, String>{
                          'all': strings.allPriorities,
                          'low': strings.low,
                          'medium': strings.medium,
                          'high': strings.high,
                          'urgent': strings.urgent,
                        }.entries
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) setModalState(() => priority = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: scope,
                decoration: InputDecoration(labelText: strings.scope),
                items: [
                  DropdownMenuItem(
                    value: 'all',
                    child: Text(strings.allVisibleTasks),
                  ),
                  DropdownMenuItem(value: 'mine', child: Text(strings.myTasks)),
                ],
                onChanged: (value) {
                  if (value != null) setModalState(() => scope = value);
                },
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        foregroundColor: const Color(0xffdc2626),
                        side: const BorderSide(color: Color(0xffdc2626)),
                      ),
                      child: Text(strings.cancel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, {
                        'status': status,
                        'priority': priority,
                        'scope': scope,
                      }),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                      ),
                      child: Text(strings.apply),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _status = result['status'] ?? 'all';
      _priority = result['priority'] ?? 'all';
      _scope = result['scope'] ?? 'all';
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.tasks,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: _create,
                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                icon: const Icon(Iconsax.add, size: 18),
                label: Text(strings.add),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            strings.tasksDescription,
            style: TextStyle(color: Color(0xff64748b)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _load(),
                  decoration: InputDecoration(
                    hintText: strings.searchTask,
                    isDense: true,
                    prefixIcon: Icon(Iconsax.search_normal, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: strings.filterTasks,
                onPressed: _openFilters,
                style: IconButton.styleFrom(minimumSize: const Size(56, 56)),
                icon: const Icon(Iconsax.filter),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'list',
                label: Text(strings.list),
                icon: Icon(Iconsax.element_3),
              ),
              ButtonSegment(
                value: 'calendar',
                label: Text(strings.calendar),
                icon: Icon(Iconsax.calendar),
              ),
            ],
            selected: {_view},
            style: ButtonStyle(
              minimumSize: WidgetStateProperty.all(const Size.fromHeight(58)),
            ),
            onSelectionChanged: (value) => setState(() => _view = value.first),
          ),
          const SizedBox(height: 14),
          if (_loading)
            const _TaskSkeletonList()
          else if (_error != null)
            _TaskState(
              icon: Iconsax.danger,
              title: strings.loadingError,
              message: _error!,
              action: TextButton.icon(
                onPressed: _load,
                icon: const Icon(Iconsax.refresh),
                label: Text(strings.retry),
              ),
            )
          else if (_tasks.isEmpty && _view != 'calendar')
            _TaskState(
              icon: Iconsax.task,
              title: strings.noTask,
              message: strings.tasksWillAppear,
            )
          else if (_view == 'calendar')
            _calendarView()
          else
            ..._tasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TaskListRow(
                  task: task,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProjectTaskDetailsPage(
                          session: widget.session,
                          taskId: task['id'].toString(),
                        ),
                      ),
                    );
                    if (mounted) _load();
                  },
                ),
              ),
            ),
          if (_loadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
    );
  }

  Widget _calendarView() {
    final strings = AppLocalizations.of(context);
    final dayStart = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    final dayEnd = dayStart.add(const Duration(days: 1));
    final dayTasks = _tasks.where((task) {
      final start =
          _parseTaskDate(task['start_date']) ??
          _parseTaskDate(task['created_at']);
      final due = _parseTaskDate(task['due_date']) ?? start;
      if (start == null || due == null) return false;
      return start.isBefore(dayEnd) && due.isAfter(dayStart);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TaskMonthCalendar(
          month: _calendarMonth,
          selectedDay: _selectedDay,
          tasks: _tasks,
          onPreviousMonth: () => setState(() {
            _calendarMonth = DateTime(
              _calendarMonth.year,
              _calendarMonth.month - 1,
            );
          }),
          onNextMonth: () => setState(() {
            _calendarMonth = DateTime(
              _calendarMonth.year,
              _calendarMonth.month + 1,
            );
          }),
          onDaySelected: (day) => setState(() => _selectedDay = day),
          taskOverlapsDay: _taskOverlapsDay,
        ),
        const SizedBox(height: 12),
        Text(
          '${dayTasks.length} tâche(s) le ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (dayTasks.isEmpty)
          _TaskState(
            icon: Iconsax.calendar_tick,
            title: strings.noTasksForDate,
            message: strings.tasksForDateWillAppear,
          )
        else
          ...dayTasks.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TaskCard(
                task: task,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProjectTaskDetailsPage(
                        session: widget.session,
                        taskId: task['id'].toString(),
                      ),
                    ),
                  );
                  if (mounted) _load();
                },
              ),
            ),
          ),
      ],
    );
  }

  DateTime? _parseTaskDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString().replaceFirst(' ', 'T'));
  }

  bool _taskOverlapsDay(Map<String, dynamic> task, DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final start =
        _parseTaskDate(task['start_date']) ??
        _parseTaskDate(task['created_at']);
    final due = _parseTaskDate(task['due_date']) ?? start;
    if (start == null || due == null) return false;
    return start.isBefore(dayEnd) &&
        due.add(const Duration(seconds: 1)).isAfter(dayStart);
  }
}

class _TaskMonthCalendar extends StatelessWidget {
  const _TaskMonthCalendar({
    required this.month,
    required this.selectedDay,
    required this.tasks,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onDaySelected,
    required this.taskOverlapsDay,
  });

  final DateTime month;
  final DateTime selectedDay;
  final List<Map<String, dynamic>> tasks;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onDaySelected;
  final bool Function(Map<String, dynamic>, DateTime) taskOverlapsDay;

  static const _weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
  static const _months = [
    'Janvier',
    'Fevrier',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Aout',
    'Septembre',
    'Octobre',
    'Novembre',
    'Decembre',
  ];

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final firstDay = DateTime(month.year, month.month, 1);
    final leadingDays = firstDay.weekday - 1;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final cellCount = ((leadingDays + daysInMonth + 6) ~/ 7) * 7;
    final today = DateTime.now();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: strings.previousMonth,
                  onPressed: onPreviousMonth,
                  style: IconButton.styleFrom(minimumSize: const Size(56, 56)),
                  icon: const Icon(Iconsax.arrow_left),
                ),
                Expanded(
                  child: Text(
                    '${_months[month.month - 1]} ${month.year}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: strings.nextMonth,
                  onPressed: onNextMonth,
                  style: IconButton.styleFrom(minimumSize: const Size(56, 56)),
                  icon: const Icon(Iconsax.arrow_right),
                ),
              ],
            ),
            Row(
              children: _weekdays
                  .map(
                    (weekday) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          weekday,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xff64748b),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cellCount,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (context, index) {
                final dayNumber = index - leadingDays + 1;
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const SizedBox.shrink();
                }
                final day = DateTime(month.year, month.month, dayNumber);
                final dayTasks = tasks
                    .where((task) => taskOverlapsDay(task, day))
                    .toList();
                final selected = _sameDay(day, selectedDay);
                final isToday = _sameDay(day, today);
                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onDaySelected(day),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: selected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : isToday
                          ? const Color(0xfff1f5f9)
                          : null,
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : const Color(0xffe2e8f0),
                        width: selected ? 1.4 : 0.8,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : const Color(0xff334155),
                          ),
                        ),
                        if (dayTasks.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _statusColor(dayTasks.first['status']),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${dayTasks.length} tâche${dayTasks.length > 1 ? 's' : ''}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _statusColor(
                                      dayTasks.first['status'],
                                    ),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  static Color _statusColor(dynamic status) {
    switch (status?.toString()) {
      case 'done':
        return const Color(0xff059669);
      case 'in_progress':
        return const Color(0xff2563eb);
      case 'review':
        return const Color(0xffd97706);
      case 'cancelled':
        return const Color(0xffdc2626);
      default:
        return const Color(0xff64748b);
    }
  }
}

class _GlobalTaskForm extends StatefulWidget {
  const _GlobalTaskForm({
    required this.users,
    required this.projects,
    required this.currentUserId,
  });

  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> projects;
  final String? currentUserId;

  @override
  State<_GlobalTaskForm> createState() => _GlobalTaskFormState();
}

class _GlobalTaskFormState extends State<_GlobalTaskForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  String? _projectId;
  String? _assignedTo;
  String _assignmentMode = 'self';
  String _priority = 'medium';
  DateTime? _start;
  DateTime? _due;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDates() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _start != null && _due != null
          ? DateTimeRange(start: _start!, end: _due!)
          : null,
      helpText: 'Période de la tâche',
      saveText: 'Valider',
    );
    if (range != null && mounted) {
      setState(() {
        _start = range.start;
        _due = range.end;
      });
    }
  }

  String _date(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} 09:00:00';
  }

  String _name(Map<String, dynamic> user) =>
      user['full_name']?.toString() ??
      '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .9,
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  strings.createTask,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  strings.independentTaskDescription,
                  style: TextStyle(color: Color(0xff64748b)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _title,
                  decoration: InputDecoration(labelText: strings.title),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? strings.requiredTitle
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
                DropdownButtonFormField<String>(
                  initialValue: _projectId,
                  isExpanded: true,
                  menuMaxHeight: 280,
                  decoration: InputDecoration(labelText: strings.linkedProject),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text(strings.generalTask),
                    ),
                    ...widget.projects.map(
                      (project) => DropdownMenuItem<String>(
                        value: project['id']?.toString(),
                        child: Text(
                          project['name']?.toString() ?? 'Projet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _projectId = value),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'self', label: Text(strings.forMe)),
                    ButtonSegment(
                      value: 'other',
                      label: Text(strings.collaborator),
                    ),
                  ],
                  selected: {_assignmentMode},
                  onSelectionChanged: (value) =>
                      setState(() => _assignmentMode = value.first),
                ),
                const SizedBox(height: 12),
                if (_assignmentMode == 'other')
                  DropdownButtonFormField<String>(
                    initialValue: _assignedTo,
                    decoration: InputDecoration(labelText: strings.assignTo),
                    items: widget.users
                        .map(
                          (user) => DropdownMenuItem(
                            value: user['id']?.toString(),
                            child: Text(_name(user)),
                          ),
                        )
                        .where((item) => item.value != null)
                        .toList(),
                    onChanged: (value) => setState(() => _assignedTo = value),
                  ),
                const SizedBox(height: 12),
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
                  onChanged: (value) {
                    if (value != null) setState(() => _priority = value);
                  },
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _pickDates,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: Text(
                    _start == null || _due == null
                        ? strings.definePeriod
                        : '${_start!.day}/${_start!.month}/${_start!.year} - ${_due!.day}/${_due!.month}/${_due!.year}',
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () {
                    if (!(_formKey.currentState?.validate() ?? false)) return;
                    if (_start == null || _due == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(strings.datesRequired)),
                      );
                      return;
                    }
                    if (!_due!.isAfter(_start!)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(strings.dueAfterStart)),
                      );
                      return;
                    }
                    Navigator.pop(context, {
                      'title': _title.text.trim(),
                      'description': _description.text.trim().isEmpty
                          ? null
                          : _description.text.trim(),
                      if (_assignmentMode == 'self' &&
                          widget.currentUserId != null)
                        'assigned_to': widget.currentUserId,
                      if (_assignmentMode == 'other' && _assignedTo != null)
                        'assigned_to': _assignedTo,
                      if (_projectId != null) 'project_id': _projectId,
                      'priority': _priority,
                      'status': 'todo',
                      if (_start != null) 'start_date': _date(_start!),
                      if (_due != null) 'due_date': _date(_due!),
                    });
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: Text(strings.createTask),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskListRow extends StatelessWidget {
  const _TaskListRow({required this.task, required this.onTap});

  final Map<String, dynamic> task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final project = task['project'];
    final projectName = project is Map
        ? project['name']?.toString() ?? 'Tache generale'
        : 'Tache generale';
    final due = task['due_date']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xffe8f0ff),
          child: Icon(
            Iconsax.task,
            size: 19,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          task['title']?.toString() ?? 'Tache',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          due == null ? projectName : '$projectName  •  $due',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Color(0xff64748b)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TaskStatus(status: task['status']?.toString()),
            const SizedBox(width: 4),
            const Icon(Iconsax.arrow_right, size: 20, color: Color(0xff94a3b8)),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.onTap});

  final Map<String, dynamic> task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task['title']?.toString() ?? 'Tache',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _TaskStatus(status: task['status']?.toString()),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              _projectName,
              style: const TextStyle(color: Color(0xff64748b), fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  avatar: const Icon(Iconsax.flag, size: 16),
                  label: Text(
                    task['priority']?.toString() ?? 'medium',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                if (task['due_date'] != null)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    avatar: const Icon(Iconsax.calendar, size: 16),
                    label: Text(
                      task['due_date'].toString(),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                if (task['assignment_status'] == 'pending')
                  const Chip(
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(
                      'Affectation en attente',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  String get _projectName {
    final project = task['project'];
    if (project is Map) return project['name']?.toString() ?? 'Tache generale';
    return 'Tache generale';
  }
}

class _TaskStatus extends StatelessWidget {
  const _TaskStatus({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    const colors = {
      'todo': Color(0xff64748b),
      'in_progress': Color(0xff2563eb),
      'review': Color(0xffd97706),
      'done': Color(0xff059669),
    };
    const labels = {
      'todo': 'A faire',
      'in_progress': 'En cours',
      'review': 'En revue',
      'done': 'Terminee',
    };
    final value = status ?? 'todo';
    return Chip(
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      label: Text(labels[value] ?? value),
      labelStyle: TextStyle(
        color: colors[value] ?? const Color(0xff64748b),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: (colors[value] ?? const Color(0xff64748b)).withValues(
        alpha: .1,
      ),
      side: BorderSide.none,
    );
  }
}

class _TaskSkeletonList extends StatelessWidget {
  const _TaskSkeletonList();

  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      4,
      (_) => const Padding(
        padding: EdgeInsets.only(bottom: 6),
        child: Card(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                _TaskSkeletonBlock(width: 36, height: 36, radius: 18),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TaskSkeletonBlock(width: 190, height: 14),
                      SizedBox(height: 8),
                      _TaskSkeletonBlock(width: 130, height: 11),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                _TaskSkeletonBlock(width: 62, height: 24, radius: 12),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _TaskSkeletonBlock extends StatelessWidget {
  const _TaskSkeletonBlock({
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
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

class _TaskState extends StatelessWidget {
  const _TaskState({
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
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(icon, size: 34, color: const Color(0xff94a3b8)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xff64748b)),
          ),
          if (action != null) ...[const SizedBox(height: 8), action!],
        ],
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/ui/app_messenger.dart';
import '../../auth/data/auth_service.dart';
import '../../branding/data/branding_service.dart';
import '../../dashboard/data/dashboard_service.dart';
import '../../tasks/data/task_service.dart';
import '../../tasks/presentation/tasks_page.dart';
import '../../courriers/presentation/courriers_page.dart';
import '../../evaluations/presentation/evaluations_page.dart';
import '../../notifications/presentation/notifications_page.dart';
import '../../profile/presentation/profile_page.dart';
import '../../projects/presentation/projects_page.dart';
import '../../reports/presentation/reports_page.dart';
import '../../settings/presentation/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.session, required this.onLogout});

  final AuthSession session;
  final VoidCallback onLogout;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  CompanyBranding? _branding;
  bool _brandingLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBranding();
  }

  Future<void> _loadBranding() async {
    try {
      final branding = await BrandingService().fetch();
      if (mounted) {
        setState(() {
          _branding = branding;
          _brandingLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _brandingLoaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: _CompanyHeader(branding: _branding, loading: !_brandingLoaded),
        actions: [
          IconButton(
            tooltip: strings.notifications,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            ),
            icon: const Icon(Iconsax.notification),
          ),
          IconButton(
            tooltip: strings.profile,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProfilePage(session: widget.session),
              ),
            ),
            icon: const Icon(Iconsax.profile_circle),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _DashboardTab(
            session: widget.session,
            onOpenTasks: () => setState(() => _selectedIndex = 2),
          ),
          ProjectsPage(session: widget.session),
          TasksPage(session: widget.session),
          CourriersPage(session: widget.session),
          _MoreTab(onLogout: widget.onLogout, session: widget.session),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          NavigationDestination(
            icon: Icon(Iconsax.home),
            selectedIcon: Icon(Iconsax.home_2),
            label: strings.home,
          ),
          NavigationDestination(
            icon: Icon(Iconsax.folder),
            selectedIcon: Icon(Iconsax.folder_2),
            label: strings.projects,
          ),
          NavigationDestination(
            icon: Icon(Iconsax.task),
            selectedIcon: Icon(Iconsax.task_square),
            label: strings.tasks,
          ),
          NavigationDestination(
            icon: Icon(Iconsax.sms),
            selectedIcon: Icon(Iconsax.sms_tracking),
            label: strings.courriers,
          ),
          NavigationDestination(
            icon: Icon(Iconsax.more),
            selectedIcon: Icon(Iconsax.more_circle),
            label: strings.more,
          ),
        ],
      ),
    );
  }
}

class _CompanyHeader extends StatelessWidget {
  const _CompanyHeader({required this.branding, required this.loading});

  final CompanyBranding? branding;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final companyName = branding?.companyName?.trim().isNotEmpty == true
        ? branding!.companyName!.trim()
        : 'PERFOMIA';
    final logoUrl = branding?.logoUrl;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (logoUrl != null && logoUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              logoUrl,
              width: 30,
              height: 30,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  _CompanyInitial(name: companyName),
            ),
          )
        else
          _CompanyInitial(name: companyName),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            loading ? ' ' : companyName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _CompanyInitial extends StatelessWidget {
  const _CompanyInitial({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? 'P'
        : name.trim().substring(0, 1).toUpperCase();
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DashboardTab extends StatefulWidget {
  const _DashboardTab({required this.session, required this.onOpenTasks});

  final AuthSession session;
  final VoidCallback onOpenTasks;

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  final _service = DashboardService();
  final _taskService = TaskService();
  DashboardData? _dashboard;
  List<RecentTask> _recentTasks = const [];
  bool _loading = true;

  String get _scopeLabel {
    final roles = widget.session.user['roles'];
    final names = roles is List
        ? roles
              .map(
                (role) => role is Map<String, dynamic>
                    ? role['name']?.toString()
                    : role.toString(),
              )
              .toSet()
        : <String>{};
    final hierarchy = widget.session.user['hierarchy_level'];
    final isCompanyBoss =
        hierarchy is Map &&
        (hierarchy['is_company_boss_level'] == true ||
            hierarchy['is_company_boss_level'] == 1 ||
            hierarchy['is_company_boss_level']?.toString() == '1');
    if (names.contains('admin') || isCompanyBoss) return 'Vue entreprise';
    if (names.contains('super_admin') || names.contains('manager')) {
      return 'Vue equipe';
    }
    return 'Vue personnelle';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.fetch(),
        _taskService.fetchRecent(),
      ]);
      if (mounted) {
        setState(() {
          _dashboard = results[0] as DashboardData;
          _recentTasks = results[1] as List<RecentTask>;
        });
      }
    } on ApiException catch (error) {
      showAppError(error.message);
    } catch (_) {
      if (mounted) {
        showAppError(AppLocalizations.of(context).dashboardLoadError);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final userName = [
      widget.session.user['first_name'],
      widget.session.user['last_name'],
    ].whereType<String>().join(' ').trim();
    final summary = _dashboard?.summary;

    if (_loading && _dashboard == null) {
      return const _DashboardSkeleton();
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Text(
            '${strings.hello}${userName.isEmpty ? '' : ', $userName'}',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '$_scopeLabel · Voici un apercu de votre activite.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xff64748b)),
          ),
          const SizedBox(height: 22),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          _ProductivityCard(value: summary?.productivity ?? 0),
          const SizedBox(height: 14),
          _KpiGrid(summary: summary),
          const SizedBox(height: 14),
          _RecentTasksCard(
            tasks: _recentTasks,
            session: widget.session,
            onOpenTasks: widget.onOpenTasks,
          ),
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        const _SkeletonBlock(width: 210, height: 30),
        const SizedBox(height: 10),
        const _SkeletonBlock(width: 270, height: 16),
        const SizedBox(height: 22),
        Container(
          height: 270,
          decoration: BoxDecoration(
            color: const Color(0xffe9eff7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SkeletonCircle(diameter: 156),
              SizedBox(height: 18),
              _SkeletonBlock(width: 120, height: 18),
              SizedBox(height: 8),
              _SkeletonBlock(width: 220, height: 13),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 116,
          children: List.generate(
            6,
            (_) => Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xffe9eff7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SkeletonBlock(width: 34, height: 34),
                  _SkeletonBlock(width: 42, height: 24),
                  _SkeletonBlock(width: 92, height: 12),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          height: 230,
          decoration: BoxDecoration(
            color: const Color(0xffe9eff7),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(18),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBlock(width: 130, height: 19),
              SizedBox(height: 8),
              _SkeletonBlock(width: 220, height: 13),
              SizedBox(height: 24),
              _SkeletonBlock(width: double.infinity, height: 42),
              SizedBox(height: 10),
              _SkeletonBlock(width: double.infinity, height: 42),
            ],
          ),
        ),
      ],
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xffdce6f2),
      borderRadius: BorderRadius.circular(8),
    ),
  );
}

class _SkeletonCircle extends StatelessWidget {
  const _SkeletonCircle({required this.diameter});

  final double diameter;

  @override
  Widget build(BuildContext context) => Container(
    width: diameter,
    height: diameter,
    decoration: const BoxDecoration(
      color: Color(0xffdce6f2),
      shape: BoxShape.circle,
    ),
  );
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.summary});

  final DashboardSummary? summary;

  @override
  Widget build(BuildContext context) {
    final data = summary;
    final strings = AppLocalizations.of(context);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      mainAxisExtent: 116,
      children: [
        _MetricCard(
          label: strings.totalTasks,
          value: '${data?.totalTasks ?? 0}',
          icon: Iconsax.task_square,
          color: const Color(0xff2878ff),
        ),
        _MetricCard(
          label: strings.pendingTasks,
          value: '${data?.pendingTasks ?? 0}',
          icon: Iconsax.timer,
          color: const Color(0xfff59e0b),
        ),
        _MetricCard(
          label: strings.completedTasks,
          value: '${data?.completedTasks ?? 0}',
          icon: Iconsax.tick_circle,
          color: const Color(0xff12b981),
        ),
        _MetricCard(
          label: strings.overdue,
          value: '${data?.overdueTasks ?? 0}',
          icon: Iconsax.clock,
          color: const Color(0xffef6a62),
        ),
        _MetricCard(
          label: strings.projectsAtRisk,
          value: '${data?.projectsAtRisk ?? 0}',
          icon: Iconsax.danger,
          color: const Color(0xff2878ff),
        ),
        _MetricCard(
          label: strings.pendingCourriers,
          value: '${data?.pendingCourriers ?? 0}',
          icon: Iconsax.sms,
          color: const Color(0xff8b5cf6),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withAlpha(24),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xff64748b), fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _ProductivityCard extends StatelessWidget {
  const _ProductivityCard({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final progress = (value / 100).clamp(0, 1).toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 26, 18, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 156,
              height: 156,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 13,
                      backgroundColor: const Color(0xffe6eef9),
                      color: const Color(0xff2878ff),
                    ),
                  ),
                  Text(
                    '${value.round()}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              strings.productivity,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              strings.productivityDescription,
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xff64748b), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTasksCard extends StatelessWidget {
  const _RecentTasksCard({
    required this.tasks,
    required this.session,
    required this.onOpenTasks,
  });

  final List<RecentTask> tasks;
  final AuthSession session;
  final VoidCallback onOpenTasks;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.recentTasks,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              strings.recentTasksDescription,
              style: TextStyle(color: Color(0xff64748b)),
            ),
            const SizedBox(height: 14),
            if (tasks.isEmpty)
              Text(
                strings.noRecentTasks,
                style: TextStyle(color: Color(0xff64748b)),
              )
            else
              ...tasks.map(
                (task) => _RecentTaskRow(
                  task: task,
                  onTap: task.id.isEmpty
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProjectTaskDetailsPage(
                              session: session,
                              taskId: task.id,
                            ),
                          ),
                        ),
                ),
              ),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onOpenTasks,
                icon: const Icon(Iconsax.arrow_right, size: 18),
                label: Text(strings.viewAllTasks),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTaskRow extends StatelessWidget {
  const _RecentTaskRow({required this.task, this.onTap});

  final RecentTask task;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                _StatusPill(status: task.status),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              [
                if (task.projectName != null) task.projectName!,
                if (task.dueDate != null) strings.dueDate(task.dueDate!),
              ].join(' · '),
              style: const TextStyle(fontSize: 11, color: Color(0xff64748b)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final done = status == 'done' || status == 'completed';
    final label = done
        ? strings.completed
        : status == 'in_progress'
        ? strings.inProgress
        : strings.todo;
    final color = done ? const Color(0xff07884f) : const Color(0xff2878ff);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: done ? const Color(0xffe8fbf3) : const Color(0xffedf4ff),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MoreTab extends StatelessWidget {
  const _MoreTab({required this.onLogout, required this.session});

  final VoidCallback onLogout;
  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      children: [
        Text(
          strings.more,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          strings.moreDescription,
          style: TextStyle(color: Color(0xff64748b), height: 1.4),
        ),
        const SizedBox(height: 22),
        _MoreSectionLabel(label: strings.quickAccess),
        const SizedBox(height: 8),
        Card(
          child: _MoreTile(
            icon: Iconsax.notification,
            title: strings.notifications,
            subtitle: strings.notificationsDescription,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: _MoreTile(
            icon: Iconsax.chart_2,
            title: strings.reports,
            subtitle: strings.reportsDescription,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ReportsPage(session: session)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: _MoreTile(
            icon: Iconsax.clipboard_text,
            title: strings.evaluations,
            subtitle: strings.evaluationsDescription,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EvaluationsPage(session: session),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: _MoreTile(
            icon: Iconsax.setting_2,
            title: strings.settings,
            subtitle: strings.settingsDescription,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SettingsPage(session: session)),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _MoreSectionLabel(label: strings.account),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 6,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xffffeeec),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Iconsax.logout, color: Color(0xffb42318)),
            ),
            title: Text(
              strings.signOut,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(strings.signOutDescription),
            onTap: onLogout,
          ),
        ),
        const SizedBox(height: 28),
        const Center(
          child: Text(
            'PERFOMIA Mobile',
            style: TextStyle(
              color: Color(0xff94a3b8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _MoreSectionLabel extends StatelessWidget {
  const _MoreSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: TextStyle(
      color: Theme.of(context).colorScheme.primary,
      fontSize: 12,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.6,
    ),
  );
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
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
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
    leading: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Theme.of(context).colorScheme.primary),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(subtitle),
    trailing: const Icon(Iconsax.arrow_right),
    onTap: onTap,
  );
}

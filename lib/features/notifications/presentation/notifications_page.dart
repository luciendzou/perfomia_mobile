import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/network/api_client.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/ui/app_messenger.dart';
import '../data/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _service = NotificationService();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  List<AppNotification> _items = const [];
  int _unreadCount = 0;
  int _page = 1;
  int _lastPage = 1;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String? _busyId;
  String? _readFilter;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 500) _loadMore();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
        _lastPage = 1;
      });
    }
    try {
      final data = await _service.fetch(
        readFilter: _readFilter,
        search: _searchController.text,
      );
      if (mounted) {
        setState(() {
          _items = data.items;
          _unreadCount = data.unreadCount;
          _page = data.page;
          _lastPage = data.lastPage;
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Impossible de charger les notifications.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || _page >= _lastPage) return;
    setState(() => _loadingMore = true);
    try {
      final data = await _service.fetch(
        readFilter: _readFilter,
        search: _searchController.text,
        page: _page + 1,
      );
      if (mounted) {
        setState(() {
          _items = [..._items, ...data.items];
          _unreadCount = data.unreadCount;
          _page = data.page;
          _lastPage = data.lastPage;
        });
      }
    } on ApiException catch (error) {
      if (mounted) showAppError(error.message);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _service.markAllRead();
      await _load();
    } on ApiException catch (error) {
      showAppError(error.message);
    }
  }

  Future<void> _markRead(AppNotification notification) async {
    if (notification.id.isEmpty || notification.isRead || _busyId != null) {
      return;
    }
    setState(() => _busyId = notification.id);
    try {
      await _service.markRead(notification.id);
      await _load();
    } on ApiException catch (error) {
      showAppError(error.message);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _delete(AppNotification notification) async {
    if (notification.id.isEmpty || _busyId != null) return;
    setState(() => _busyId = notification.id);
    try {
      await _service.delete(notification.id);
      await _load();
    } on ApiException catch (error) {
      showAppError(error.message);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _openFilters() async {
    final strings = AppLocalizations.of(context);
    var readFilter = _readFilter ?? 'all';
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
                strings.filterNotifications,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: readFilter,
                decoration: InputDecoration(
                  labelText: strings.notificationState,
                ),
                items: [
                  DropdownMenuItem<String>(
                    value: 'all',
                    child: Text(strings.allNotifications),
                  ),
                  DropdownMenuItem<String>(
                    value: 'false',
                    child: Text(strings.unread),
                  ),
                  DropdownMenuItem<String>(
                    value: 'true',
                    child: Text(strings.read),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setModalState(() => readFilter = value);
                  }
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
                      onPressed: () => Navigator.pop(context, readFilter),
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
    setState(() => _readFilter = result == 'all' ? null : result);
    await _load();
  }

  String _date(String? value) {
    final raw = value ?? '';
    if (raw.length < 16) {
      return raw.isEmpty ? AppLocalizations.of(context).unknownDate : raw;
    }
    return '${raw.substring(0, 10)} a ${raw.substring(11, 16)}';
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.notificationsTitle),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _loading ? null : _markAllRead,
              child: Text(strings.markAllRead),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _load(),
                    decoration: InputDecoration(
                      hintText: strings.searchNotification,
                      prefixIcon: const Icon(Iconsax.search_normal),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: strings.clear,
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                                _load();
                              },
                              icon: const Icon(Iconsax.close_circle),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: strings.filterNotifications,
                  onPressed: _openFilters,
                  style: IconButton.styleFrom(minimumSize: const Size(56, 56)),
                  icon: const Icon(Iconsax.filter),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_loading && _items.isEmpty)
              const _NotificationSkeleton()
            else if (_error != null)
              _NotificationState(message: _error!, onRetry: _load)
            else if (_items.isEmpty)
              const _EmptyNotifications()
            else
              ..._items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _NotificationTile(
                    notification: item,
                    date: _date(item.createdAt),
                    busy: _busyId == item.id,
                    onRead: () => _markRead(item),
                    onDelete: () => _delete(item),
                  ),
                ),
              ),
            if (_loadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.date,
    required this.busy,
    required this.onRead,
    required this.onDelete,
  });

  final AppNotification notification;
  final String date;
  final bool busy;
  final VoidCallback onRead;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: notification.isRead ? Colors.white : const Color(0xffedf4ff),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        leading: CircleAvatar(
          backgroundColor: notification.isRead
              ? const Color(0xffeef2f7)
              : theme.colorScheme.primaryContainer,
          child: Icon(
            notification.isRead
                ? Iconsax.notification
                : Iconsax.notification_status,
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(
          notification.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '${notification.message}\n$date',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : PopupMenuButton<String>(
                tooltip: AppLocalizations.of(context).actions,
                onSelected: (value) {
                  if (value == 'read') onRead();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  if (!notification.isRead)
                    PopupMenuItem(
                      value: 'read',
                      child: Text(AppLocalizations.of(context).markAsRead),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(AppLocalizations.of(context).delete),
                  ),
                ],
              ),
      ),
    );
  }
}

class _NotificationSkeleton extends StatelessWidget {
  const _NotificationSkeleton();

  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      5,
      (_) => Container(
        height: 104,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xffe9eff7),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
  );
}

class _NotificationState extends StatelessWidget {
  const _NotificationState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 360,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.cloud_remove, size: 48, color: Color(0xff94a3b8)),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xff64748b)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(AppLocalizations.of(context).retry),
          ),
        ],
      ),
    ),
  );
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 420,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.notification,
            size: 58,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).noNotifications,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).notificationsWillAppear,
            style: TextStyle(color: Color(0xff64748b)),
          ),
        ],
      ),
    ),
  );
}

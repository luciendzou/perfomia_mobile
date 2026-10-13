import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/network/api_client.dart';
import '../../../core/ui/app_messenger.dart';
import '../../../core/localization/app_localizations.dart';
import '../../auth/data/auth_service.dart';
import '../data/courrier_service.dart';

String formatCourrierDate(dynamic value) {
  if (value == null) return '';
  final raw = value.toString().trim();
  if (raw.isEmpty) return '';
  final parsed = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  if (parsed == null) return raw;
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(parsed.day)}/${two(parsed.month)}/${parsed.year} ${two(parsed.hour)}:${two(parsed.minute)}';
}

class CourriersPage extends StatefulWidget {
  const CourriersPage({super.key, required this.session});

  final AuthSession session;

  @override
  State<CourriersPage> createState() => _CourriersPageState();
}

class _CourriersPageState extends State<CourriersPage> {
  late final CourrierService _service;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _courriers = const [];
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 0;
  int _lastPage = 1;
  String _type = 'all';
  String _status = 'all';
  String _scope = 'all';
  String? _error;

  static const _types = <String, String>{
    'all': 'Tous les types',
    'incoming': 'Entrants',
    'outgoing': 'Sortants',
  };

  static const _statuses = <String, String>{
    'all': 'Tous les statuts',
    'registered': 'Enregistrés',
    'in_transit': 'En transmission',
    'received': 'Reçus',
    'completed': 'Terminés',
    'archived': 'Archivés',
  };

  @override
  void initState() {
    super.initState();
    _service = CourrierService(
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

  String _currentUserLabel() {
    final user = widget.session.user;
    final fullName = user['full_name']?.toString().trim();
    if (fullName != null && fullName.isNotEmpty) return fullName;
    final firstName = user['first_name']?.toString().trim() ?? '';
    final lastName = user['last_name']?.toString().trim() ?? '';
    final name = '$firstName $lastName'.trim();
    return name.isNotEmpty ? name : (user['email']?.toString() ?? 'Moi');
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _courriers = const [];
      _page = 0;
      _lastPage = 1;
    });
    try {
      final result = await _service.fetchPage(
        search: _searchController.text,
        type: _type,
        status: _status,
        userId: _scope == 'mine' ? widget.session.user['id']?.toString() : null,
      );
      if (mounted) {
        setState(() {
          _courriers = result.items;
          _page = result.page;
          _lastPage = result.lastPage;
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Impossible de charger les courriers.');
      }
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
        type: _type,
        status: _status,
        userId: _scope == 'mine' ? widget.session.user['id']?.toString() : null,
        page: _page + 1,
      );
      if (mounted) {
        setState(() {
          _courriers = [..._courriers, ...result.items];
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

  Future<void> _openFilters() async {
    final strings = AppLocalizations.of(context);
    var type = _type;
    var status = _status;
    var scope = _scope;
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              18,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.filterCourriers,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fermer',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Iconsax.close_circle),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: strings.courrierType),
                  items: _types.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setModalState(() => type = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: strings.courrierStatus,
                  ),
                  items: _statuses.entries
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
                  initialValue: scope,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: strings.perimeter),
                  items: [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text(strings.allVisibleCourriers),
                    ),
                    DropdownMenuItem(
                      value: 'mine',
                      child: Text(strings.myCourriers),
                    ),
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
                        ),
                        child: Text(strings.cancel),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, {
                          'type': type,
                          'status': status,
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
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _type = result['type'] ?? 'all';
      _status = result['status'] ?? 'all';
      _scope = result['scope'] ?? 'all';
    });
    await _load();
  }

  Future<void> _create({required bool incoming}) async {
    final body = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CreateCourrierForm(
        incoming: incoming,
        currentUserLabel: _currentUserLabel(),
      ),
    );
    if (body == null) return;
    try {
      if (incoming) {
        await _service.createIncoming(body);
      } else {
        await _service.createOutgoing(body);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              incoming
                  ? AppLocalizations.of(context).incomingAdded
                  : AppLocalizations.of(context).outgoingAdded,
            ),
          ),
        );
        await _load();
      }
    } on ApiException catch (error) {
      if (mounted) {
        showAppError(error.message);
      }
    }
  }

  Future<void> _openCreateChooser() async {
    final strings = AppLocalizations.of(context);
    final incoming = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.addCourrier,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Iconsax.import),
                label: Text(strings.incoming),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Iconsax.export),
                label: Text(strings.outgoing),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (incoming != null && mounted) await _create(incoming: incoming);
  }

  // ignore: unused_element
  Future<void> _transmit(Map<String, dynamic> courrier) async {
    try {
      final recipients = await _service.recipients();
      if (!mounted) return;
      final result = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _TransmitForm(recipients: recipients),
      );
      if (result == null) return;
      await _service.transmit(
        courrier['id'].toString(),
        userIds: List<String>.from(result['user_ids'] as List),
        instruction: result['instruction']?.toString(),
        recipientInstructions: Map<String, String>.from(
          result['recipient_instructions'] as Map,
        ),
        createTask: result['create_task'] == true,
        comment: result['comment']?.toString(),
        dueDate: result['due_date']?.toString(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['create_task'] == true
                  ? AppLocalizations.of(context).mailAndTaskCreated
                  : AppLocalizations.of(context).mailTransmitted,
            ),
          ),
        );
        await _load();
      }
    } on ApiException catch (error) {
      if (mounted) {
        showAppError(error.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateChooser,
        icon: const Icon(Iconsax.add),
        label: Text(strings.addCourrier),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text(
              strings.courrierTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              strings.courriersDescription,
              style: TextStyle(color: Color(0xff64748b)),
            ),
            const SizedBox(height: 14),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _load(),
                      decoration: InputDecoration(
                        hintText: strings.searchCourrier,
                        isDense: true,
                        prefixIcon: const Icon(Iconsax.search_normal, size: 20),
                        suffixIcon: IconButton(
                          tooltip: strings.filterCourriers,
                          onPressed: _openFilters,
                          icon: const Icon(Iconsax.filter),
                        ),
                      ),
                    ),
                    if (_scope == '__inline_scope__')
                      DropdownButtonFormField<String>(
                        initialValue: _scope,
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: strings.perimeter,
                          prefixIcon: Icon(Iconsax.profile_circle, size: 20),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text(strings.allVisibleCourriers),
                          ),
                          DropdownMenuItem(
                            value: 'mine',
                            child: Text(strings.myCourriers),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _scope = value);
                          _load();
                        },
                      ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: _status == 'archived'
                  ? TextButton.icon(
                      onPressed: () {
                        setState(() => _status = 'all');
                        _load();
                      },
                      icon: const Icon(Iconsax.received, size: 18),
                      label: Text(strings.activeCourriers),
                    )
                  : TextButton.icon(
                      onPressed: () {
                        setState(() => _status = 'archived');
                        _load();
                      },
                      icon: const Icon(Iconsax.archive, size: 18),
                      label: Text(strings.archivedCourriers),
                    ),
            ),
            const SizedBox(height: 14),
            if (_loading)
              const _CourrierSkeletonList()
            else if (_error != null)
              _CourrierState(
                icon: Iconsax.danger,
                title: strings.loadingError,
                message: _error!,
                action: TextButton.icon(
                  onPressed: _load,
                  icon: const Icon(Iconsax.refresh),
                  label: Text(strings.retry),
                ),
              )
            else if (_courriers.isEmpty)
              _CourrierState(
                icon: Iconsax.sms,
                title: strings.noCourrier,
                message: strings.noCourrierMatch,
              )
            else
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var index = 0; index < _courriers.length; index++)
                      _CourrierCard(
                        courrier: _courriers[index],
                        showDivider: index < _courriers.length - 1,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CourrierDetailPage(
                                session: widget.session,
                                courrierId: _courriers[index]['id'].toString(),
                              ),
                            ),
                          );
                          if (mounted) _load();
                        },
                      ),
                  ],
                ),
              ),
            if (_loadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
          ],
        ),
      ),
    );
  }
}

class _CourrierCard extends StatelessWidget {
  const _CourrierCard({
    required this.courrier,
    this.showDivider = false,
    this.onTap,
  });

  final Map<String, dynamic> courrier;
  final bool showDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = courrier['status']?.toString() ?? 'registered';
    final type = courrier['type']?.toString() ?? 'incoming';
    final subject = courrier['subject']?.toString().trim();
    final reference = courrier['reference']?.toString() ?? 'Courrier';
    final confidential = courrier['confidential'] == true;
    final currentHolders = courrier['current_holders'];
    final holderCount = currentHolders is List ? currentHolders.length : 0;

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: Color(0xffe5eaf1)))
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xffeaf2ff),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      type == 'outgoing' ? Iconsax.export : Iconsax.import,
                      color: const Color(0xff2878ff),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reference,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xff64748b),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subject?.isNotEmpty == true ? subject! : 'Sans objet',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(status: status),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: type == 'outgoing'
                        ? Iconsax.arrow_up_2
                        : Iconsax.arrow_down_2,
                    label: type == 'outgoing' ? 'Sortant' : 'Entrant',
                  ),
                  if (confidential)
                    const _InfoChip(icon: Iconsax.lock, label: 'Confidentiel'),
                  if (holderCount > 0)
                    _InfoChip(
                      icon: Iconsax.profile_2user,
                      label: '$holderCount détenteur(s)',
                    ),
                ],
              ),
              if (courrier['due_date'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Échéance : ${formatCourrierDate(courrier['due_date'])}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xff64748b),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class CourrierDetailPage extends StatefulWidget {
  const CourrierDetailPage({
    super.key,
    required this.session,
    required this.courrierId,
  });

  final AuthSession session;
  final String courrierId;

  @override
  State<CourrierDetailPage> createState() => _CourrierDetailPageState();
}

class _CourrierDetailPageState extends State<CourrierDetailPage> {
  late final CourrierService _service;
  Map<String, dynamic>? _courrier;
  bool _loading = true;
  bool _saving = false;
  String? _downloadingFileId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = CourrierService(
      apiClient: ApiClient(accessToken: widget.session.token),
    );
    _load();
  }

  bool get _canViewHistory {
    final roles = widget.session.user['roles'];
    if (roles is List) {
      return roles.any((role) {
        final name = role is Map ? role['name']?.toString() : role.toString();
        return name == 'admin';
      });
    }
    return widget.session.user['role']?.toString() == 'admin';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final courrier = await _service.show(widget.courrierId);
      if (mounted) setState(() => _courrier = courrier);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Impossible de charger le courrier.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _runAction(
    Future<Map<String, dynamic>> Function(String? comment) action,
    String success, {
    String? confirmation,
  }) async {
    if (confirmation != null && !await _confirm(confirmation)) return;
    final comment = await _commentDialog();
    if (comment == null) return;
    setState(() => _saving = true);
    try {
      await action(comment);
      await _load();
      if (mounted) {
        showAppSuccess(success);
      }
    } on ApiException catch (error) {
      if (mounted) {
        showAppError(error.message);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirm(String message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer l’action'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<String?> _commentDialog({bool required = false}) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Commentaire'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: required
                ? 'Saisissez le commentaire obligatoire'
                : 'Ajouter un commentaire',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (required && controller.text.trim().isEmpty) return;
              Navigator.pop(context, controller.text.trim());
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _transmit() async {
    if (_saving || _courrier?['can_transmit_courrier'] != true) return;
    final recipients = await _service.recipients();
    if (!mounted) return;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TransmitForm(recipients: recipients),
    );
    if (result == null) return;
    setState(() => _saving = true);
    try {
      final updated = await _service.transmit(
        widget.courrierId,
        userIds: List<String>.from(result['user_ids'] as List),
        instruction: result['instruction']?.toString(),
        recipientInstructions: Map<String, String>.from(
          result['recipient_instructions'] as Map,
        ),
        createTask: result['create_task'] == true,
        comment: result['comment']?.toString(),
        dueDate: result['due_date']?.toString(),
      );
      if (mounted) {
        setState(() => _courrier = updated);
        await _load();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['create_task'] == true
                  ? 'Courrier transmis et tâche créée.'
                  : 'Courrier transmis.',
            ),
          ),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        showAppError(error.message);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _downloadFile(Map<String, dynamic> file) async {
    final id = file['id']?.toString();
    if (id == null || id.isEmpty || _downloadingFileId != null) return;
    final name = file['file_name']?.toString().trim().isNotEmpty == true
        ? file['file_name'].toString()
        : 'courrier-$id';
    setState(() => _downloadingFileId = id);
    try {
      final bytes = await _service.downloadFile(id);
      final path = await FilePicker.platform.saveFile(fileName: name);
      if (path == null) return;
      await File(path).writeAsBytes(bytes, flush: true);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fichier enregistré : $path')));
      }
    } on ApiException catch (error) {
      if (mounted) {
        showAppError(error.message);
      }
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Téléchargement impossible.')),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingFileId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail du courrier')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _CourrierState(
              icon: Iconsax.danger,
              title: 'Chargement impossible',
              message: _error!,
              action: TextButton.icon(
                onPressed: _load,
                icon: const Icon(Iconsax.refresh),
                label: const Text('Réessayer'),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  _header(),
                  const SizedBox(height: 12),
                  _actions(),
                  const SizedBox(height: 12),
                  if (_canViewHistory) ...[
                    _historyLink(),
                    const SizedBox(height: 12),
                  ],
                  _files(),
                ],
              ),
            ),
    );
  }

  Widget _header() {
    final courrier = _courrier!;
    final type = courrier['type']?.toString() == 'outgoing'
        ? 'Sortant'
        : 'Entrant';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    courrier['reference']?.toString() ?? 'Courrier',
                    style: const TextStyle(
                      color: Color(0xff64748b),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _StatusChip(
                  status: courrier['status']?.toString() ?? 'registered',
                ),
                _overflowMenu(),
              ],
            ),
            if (courrier['reminder_count'] != null &&
                (int.tryParse('${courrier['reminder_count']}') ?? 0) > 0)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _InfoChip(
                  icon: Iconsax.notification_status,
                  label: '${courrier['reminder_count']} relance(s)',
                ),
              ),
            if (courrier['status']?.toString() == 'archived')
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Ce courrier est archivé. Aucune action supplémentaire n’est possible.',
                  style: TextStyle(color: Color(0xff64748b)),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              courrier['subject']?.toString() ?? 'Sans objet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              courrier['content']?.toString() ?? '',
              style: const TextStyle(height: 1.45),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: type == 'Sortant'
                      ? Iconsax.arrow_up_2
                      : Iconsax.arrow_down_2,
                  label: type,
                ),
                if (courrier['confidential'] == true)
                  const _InfoChip(icon: Iconsax.lock, label: 'Confidentiel'),
                if (courrier['current_recipient_instruction'] != null)
                  _InfoChip(
                    icon: Iconsax.task_square,
                    label: _instructionLabel(
                      courrier['current_recipient_instruction'].toString(),
                    ),
                  ),
              ],
            ),
            _recipients(),
          ],
        ),
      ),
    );
  }

  Widget _recipients() {
    final recipients = _courrier!['recipients'];
    final items = recipients is List ? recipients : const [];
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Destinataires',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          ...items.map((raw) {
            final item = Map<String, dynamic>.from(raw as Map);
            final user = item['user'] is Map
                ? Map<String, dynamic>.from(item['user'] as Map)
                : item;
            final name = user['full_name']?.toString() ?? 'Utilisateur';
            final instruction = item['instruction']?.toString();
            final status = item['status']?.toString() ?? 'pending';
            return ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(
                item['is_read'] == true ? Iconsax.sms_tracking : Iconsax.sms,
                color: item['is_read'] == true
                    ? const Color(0xff15803d)
                    : const Color(0xffb45309),
              ),
              title: Text(name),
              subtitle: Text(
                '${_instructionLabel(instruction ?? 'forward')} • $status',
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _overflowMenu() {
    final strings = AppLocalizations.of(context);
    final courrier = _courrier!;
    final hasActions =
        courrier['can_transmit_courrier'] == true ||
        courrier['can_remind_courrier'] == true ||
        courrier['can_complete_courrier'] == true ||
        courrier['can_archive_courrier'] == true;
    if (!hasActions) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      tooltip: strings.actions,
      onSelected: _handleOverflowAction,
      itemBuilder: (context) => [
        if (courrier['can_transmit_courrier'] == true)
          PopupMenuItem(value: 'transmit', child: Text(strings.transmit)),
        if (courrier['can_remind_courrier'] == true)
          PopupMenuItem(value: 'remind', child: Text(strings.remind)),
        if (courrier['can_complete_courrier'] == true)
          PopupMenuItem(value: 'complete', child: Text(strings.closeCourrier)),
        if (courrier['can_archive_courrier'] == true)
          PopupMenuItem(value: 'archive', child: Text(strings.archiveCourrier)),
      ],
    );
  }

  Future<void> _handleOverflowAction(String action) async {
    if (_saving) return;
    switch (action) {
      case 'transmit':
        await _transmit();
      case 'remind':
        await _runAction(
          (comment) => _service.remind(widget.courrierId, comment ?? ''),
          'Relance envoyee.',
        );
      case 'complete':
        await _runAction(
          (comment) => _service.complete(widget.courrierId, comment: comment),
          'Courrier cloture.',
          confirmation:
              'La cloture bloque les actions de suivi normales. Continuer ?',
        );
      case 'archive':
        await _runAction(
          (comment) => _service.archive(widget.courrierId, comment: comment),
          'Courrier archive.',
          confirmation:
              'L archivage est definitif pour le workflow du courrier. Continuer ?',
        );
    }
  }

  bool _showActionInBody(String action) => false;

  Widget _actions() {
    final strings = AppLocalizations.of(context);
    final courrier = _courrier!;
    final buttons = <Widget>[];
    if (courrier['can_receive_courrier'] == true) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: _saving
              ? null
              : () => _runAction(
                  (comment) =>
                      _service.receive(widget.courrierId, comment: comment),
                  'Réception confirmée.',
                ),
          icon: const Icon(Iconsax.sms_tracking),
          label: const Text('Confirmer la réception'),
        ),
      );
    }
    if (courrier['can_process_courrier'] == true) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: _saving
              ? null
              : () => _runAction(
                  (comment) =>
                      _service.process(widget.courrierId, comment: comment),
                  'Action du courrier enregistrée.',
                ),
          icon: const Icon(Iconsax.task_square),
          label: Text(strings.process),
        ),
      );
    }
    if (_showActionInBody('transmit') &&
        courrier['can_transmit_courrier'] == true) {
      buttons.add(
        FilledButton.icon(
          onPressed: _saving ? null : _transmit,
          icon: const Icon(Iconsax.send_2),
          label: Text(strings.transmit),
        ),
      );
    }
    if (_showActionInBody('remind') &&
        courrier['can_remind_courrier'] == true) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: _saving
              ? null
              : () => _runAction(
                  (comment) =>
                      _service.remind(widget.courrierId, comment ?? ''),
                  'Relance envoyée.',
                ),
          icon: const Icon(Iconsax.notification_status),
          label: Text(strings.remind),
        ),
      );
    }
    if (_showActionInBody('complete') &&
        courrier['can_complete_courrier'] == true) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: _saving
              ? null
              : () => _runAction(
                  (comment) =>
                      _service.complete(widget.courrierId, comment: comment),
                  'Courrier clôturé.',
                  confirmation:
                      'La clôture bloque les actions de suivi normales. Continuer ?',
                ),
          icon: const Icon(Iconsax.tick_circle),
          label: const Text('Clôturer'),
        ),
      );
    }
    if (_showActionInBody('archive') &&
        courrier['can_archive_courrier'] == true) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: _saving
              ? null
              : () => _runAction(
                  (comment) =>
                      _service.archive(widget.courrierId, comment: comment),
                  'Courrier archivé.',
                  confirmation:
                      'L’archivage est définitif pour le workflow du courrier. Continuer ?',
                ),
          icon: const Icon(Iconsax.archive),
          label: Text(strings.archiveCourrier),
        ),
      );
    }
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(spacing: 8, runSpacing: 8, children: buttons),
      ),
    );
  }

  Widget _historyLink() {
    final movements = _courrier!['mouvements'];
    final items = movements is List ? movements : const [];
    return Card(
      child: ListTile(
        leading: const Icon(Iconsax.route_square),
        title: const Text(
          'Parcours du courrier',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          items.isEmpty
              ? 'Aucun mouvement enregistre.'
              : '${items.length} mouvement(s) a consulter',
        ),
        trailing: const Icon(Iconsax.arrow_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CourrierHistoryPage(courrier: _courrier!),
            ),
          );
        },
      ),
    );
  }

  // Kept as a local fallback for the detail workflow.
  // ignore: unused_element
  Widget _timeline() {
    final movements = _courrier!['mouvements'];
    final items = movements is List ? movements : const [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historique',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Text(
                'Aucun mouvement enregistré.',
                style: TextStyle(color: Color(0xff64748b)),
              )
            else
              ...items.map(
                (item) => _MovementTile(
                  movement: Map<String, dynamic>.from(item as Map),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _files() {
    final files = _courrier!['fichiers'];
    final items = files is List ? files : const [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fichiers',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Text(
                'Aucun fichier joint.',
                style: TextStyle(color: Color(0xff64748b)),
              )
            else
              ...items.map((item) {
                final file = Map<String, dynamic>.from(item as Map);
                final id = file['id']?.toString();
                final downloading = id != null && id == _downloadingFileId;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Iconsax.attach_circle),
                  title: Text(file['file_name']?.toString() ?? 'Fichier'),
                  subtitle: Text(formatCourrierDate(file['created_at'])),
                  trailing: downloading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          tooltip: 'Télécharger',
                          onPressed: () => _downloadFile(file),
                          icon: const Icon(Iconsax.document_download),
                        ),
                );
              }),
          ],
        ),
      ),
    );
  }

  String _instructionLabel(String value) => switch (value) {
    'forward' => 'Transmettre',
    'process' => 'Traiter',
    'information' => 'Information',
    'retain' => 'Conserver',
    _ => value,
  };
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.movement});

  final Map<String, dynamic> movement;

  @override
  Widget build(BuildContext context) {
    final from = movement['from_user'] is Map
        ? movement['from_user']['full_name']
        : null;
    final to = movement['to_user'] is Map
        ? movement['to_user']['full_name']
        : null;
    final service = movement['service'] is Map
        ? movement['service']['name']
        : null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: const CircleAvatar(
        radius: 16,
        child: Icon(Iconsax.route_square, size: 17),
      ),
      title: Text(
        movement['action']?.toString() ?? 'Mouvement',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        [
          if (from != null) 'De $from',
          if (to != null) 'À $to',
          if (service != null) 'Service : $service',
          if (movement['comment'] != null) movement['comment'].toString(),
        ].join(' • '),
      ),
      trailing: Text(
        formatCourrierDate(movement['action_date']),
        textAlign: TextAlign.right,
        style: const TextStyle(fontSize: 10, color: Color(0xff64748b)),
      ),
    );
  }
}

class CourrierHistoryPage extends StatelessWidget {
  const CourrierHistoryPage({super.key, required this.courrier});

  final Map<String, dynamic> courrier;

  @override
  Widget build(BuildContext context) {
    final rawMovements = courrier['mouvements'];
    final movements = rawMovements is List ? rawMovements : const [];
    return Scaffold(
      appBar: AppBar(title: const Text('Parcours du courrier')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    courrier['reference']?.toString() ?? 'Courrier',
                    style: const TextStyle(
                      color: Color(0xff64748b),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    courrier['subject']?.toString() ?? 'Sans objet',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Historique complet',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  if (movements.isEmpty)
                    const Text(
                      'Aucun mouvement enregistre.',
                      style: TextStyle(color: Color(0xff64748b)),
                    )
                  else
                    ...movements.map(
                      (item) => _MovementTile(
                        movement: Map<String, dynamic>.from(item as Map),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateCourrierForm extends StatefulWidget {
  const _CreateCourrierForm({
    required this.incoming,
    required this.currentUserLabel,
  });

  final bool incoming;
  final String currentUserLabel;

  @override
  State<_CreateCourrierForm> createState() => _CreateCourrierFormState();
}

class _CreateCourrierFormState extends State<_CreateCourrierForm> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _content = TextEditingController();
  final _external = TextEditingController();
  bool _confidential = false;
  bool _useCurrentUserAsSource = false;

  @override
  void dispose() {
    _subject.dispose();
    _content.dispose();
    _external.dispose();
    super.dispose();
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
              widget.incoming
                  ? AppLocalizations.of(context).addIncoming
                  : AppLocalizations.of(context).addOutgoing,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              widget.incoming
                  ? 'Enregistrez un courrier reçu de l’extérieur.'
                  : 'Enregistrez un courrier envoyé vers l’extérieur.',
              style: const TextStyle(color: Color(0xff64748b)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _subject,
              decoration: const InputDecoration(labelText: 'Objet'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'L’objet est obligatoire.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _external,
              decoration: InputDecoration(
                labelText: widget.incoming
                    ? 'Expéditeur externe'
                    : 'Destinataire externe',
              ),
              enabled: !(widget.incoming && _useCurrentUserAsSource),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Ce champ est obligatoire.'
                  : null,
            ),
            if (widget.incoming)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Le courrier vient de moi'),
                subtitle: Text(widget.currentUserLabel),
                value: _useCurrentUserAsSource,
                onChanged: (value) {
                  final selected = value ?? false;
                  setState(() {
                    _useCurrentUserAsSource = selected;
                    _external.text = selected ? widget.currentUserLabel : '';
                  });
                },
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _content,
              minLines: 4,
              maxLines: 7,
              decoration: const InputDecoration(
                labelText: 'Contenu',
                alignLabelWithHint: true,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Le contenu est obligatoire.'
                  : null,
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Courrier confidentiel'),
              subtitle: const Text(
                'Limiter la visibilité aux personnes autorisées',
              ),
              value: _confidential,
              onChanged: (value) => setState(() => _confidential = value),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () {
                if (!(_formKey.currentState?.validate() ?? false)) return;
                Navigator.pop(context, {
                  'subject': _subject.text.trim(),
                  'content': _content.text.trim(),
                  if (widget.incoming)
                    'source_external': _external.text.trim()
                  else
                    'destination_external': _external.text.trim(),
                  'confidential': _confidential,
                });
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              icon: const Icon(Iconsax.save_2),
              label: Text(AppLocalizations.of(context).saveMail),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TransmitForm extends StatefulWidget {
  const _TransmitForm({required this.recipients});

  final List<Map<String, dynamic>> recipients;

  @override
  State<_TransmitForm> createState() => _TransmitFormState();
}

class _TransmitFormState extends State<_TransmitForm> {
  final _formKey = GlobalKey<FormState>();
  final _comment = TextEditingController();
  final _selectedUserIds = <String>{};
  final _instructions = <String, String>{};
  bool _createTask = false;
  DateTime? _dueDate;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: _dueDate ?? DateTime.now(),
      helpText: 'Échéance de la tâche',
    );
    if (selected != null && mounted) setState(() => _dueDate = selected);
  }

  String _formatDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} 23:59:00';

  String _name(Map<String, dynamic> item) =>
      item['full_name']?.toString() ??
      '${item['first_name'] ?? ''} ${item['last_name'] ?? ''}'.trim();

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
              'Transmettre le courrier',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choisissez le prochain détenteur et l’action attendue.',
              style: TextStyle(color: Color(0xff64748b)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Destinataires et instructions',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...widget.recipients.map(_recipientTile),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Créer une tâche'),
              subtitle: const Text('Assigner une tâche au destinataire'),
              value: _createTask,
              onChanged: (value) => setState(() => _createTask = value),
            ),
            if (_createTask) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _comment,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Consigne de la tâche',
                  alignLabelWithHint: true,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'La consigne est obligatoire pour créer une tâche.'
                    : null,
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _pickDueDate,
                icon: const Icon(Iconsax.calendar),
                label: Text(
                  _dueDate == null
                      ? 'Définir l’échéance'
                      : 'Échéance : ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                ),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                if (!(_formKey.currentState?.validate() ?? false)) return;
                if (_createTask && _dueDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('L’échéance de la tâche est obligatoire.'),
                    ),
                  );
                  return;
                }
                if (_selectedUserIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sélectionnez au moins un destinataire.'),
                    ),
                  );
                  return;
                }
                Navigator.pop(context, {
                  'user_ids': _selectedUserIds.toList(),
                  'recipient_instructions': _instructions,
                  'instruction': _selectedUserIds.length == 1
                      ? _instructions[_selectedUserIds.first]
                      : null,
                  'create_task': _createTask,
                  'comment': _comment.text.trim(),
                  if (_dueDate != null) 'due_date': _formatDate(_dueDate!),
                });
              },
              icon: const Icon(Iconsax.send_2),
              label: const Text('Transmettre'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _recipientTile(Map<String, dynamic> item) {
    final id = item['id']?.toString();
    if (id == null || id.isEmpty) return const SizedBox.shrink();
    final selected = _selectedUserIds.contains(id);
    final instruction = _instructions[id] ?? 'forward';
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Column(
        children: [
          CheckboxListTile(
            value: selected,
            dense: true,
            title: Text(_name(item)),
            subtitle: Text(item['job_title']?.toString() ?? ''),
            secondary: const Icon(Iconsax.profile),
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedUserIds.add(id);
                  _instructions[id] = instruction;
                } else {
                  _selectedUserIds.remove(id);
                  _instructions.remove(id);
                }
              });
            },
          ),
          if (selected)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: DropdownButtonFormField<String>(
                initialValue: instruction,
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Instruction pour ce destinataire',
                  prefixIcon: Icon(Iconsax.route_square),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'forward',
                    child: Text('Transmettre'),
                  ),
                  DropdownMenuItem(value: 'process', child: Text('Traiter')),
                  DropdownMenuItem(
                    value: 'information',
                    child: Text('Pour information'),
                  ),
                  DropdownMenuItem(value: 'retain', child: Text('Conserver')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _instructions[id] = value);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'completed' => const Color(0xff15803d),
      'archived' => const Color(0xff64748b),
      'in_transit' => const Color(0xffb45309),
      _ => const Color(0xff2878ff),
    };
    final label = switch (status) {
      'in_transit' => 'En transmission',
      'completed' => 'Terminé',
      'archived' => 'Archivé',
      'received' => 'Reçu',
      _ => 'Enregistré',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Chip(
    visualDensity: VisualDensity.compact,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    avatar: Icon(icon, size: 16),
    label: Text(label, style: const TextStyle(fontSize: 11)),
  );
}

class _CourrierSkeletonList extends StatelessWidget {
  const _CourrierSkeletonList();

  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      4,
      (_) => const Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Card(
          child: SizedBox(
            height: 128,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
      ),
    ),
  );
}

class _CourrierState extends StatelessWidget {
  const _CourrierState({
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
      padding: const EdgeInsets.all(26),
      child: Column(
        children: [
          Icon(icon, size: 38, color: const Color(0xff8ba1bb)),
          const SizedBox(height: 10),
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

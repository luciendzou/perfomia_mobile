import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/network/api_client.dart';
import '../../../core/ui/app_messenger.dart';
import '../../../core/localization/app_localizations.dart';
import '../../auth/data/auth_service.dart';
import '../data/company_profile_service.dart';
import '../data/company_settings_service.dart';

class CompanySettingsPage extends StatefulWidget {
  const CompanySettingsPage({super.key, required this.session});
  final AuthSession session;
  @override
  State<CompanySettingsPage> createState() => _CompanySettingsPageState();
}

class _CompanySettingsPageState extends State<CompanySettingsPage> {
  late final CompanySettingsService _service;
  late final CompanyProfileService _profileService;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  final _questions = TextEditingController();
  final _taskWeight = TextEditingController();
  final _aiWeight = TextEditingController();
  final _managerWeight = TextEditingController();
  final _adminWeight = TextEditingController();
  final _prefix = TextEditingController();
  final _archiveDays = TextEditingController();
  final _companyName = TextEditingController();
  final _companyEmail = TextEditingController();
  final _companyPhone = TextEditingController();
  final _companyAddress = TextEditingController();
  final _companyCountry = TextEditingController();
  final _companyStatus = TextEditingController();
  String _language = 'fr';
  String _timezone = 'Africa/Douala';
  String _dateFormat = 'Y-m-d';
  String _timeFormat = 'H:i';
  bool _notifications = true;
  bool _whatsapp = false;
  bool _evaluations = true;
  bool _courriers = true;
  bool _tasks = true;
  bool _ai = false;
  bool _autoArchive = false;
  DateTime? _evaluationStartAt;

  @override
  void initState() {
    super.initState();
    _service = CompanySettingsService(accessToken: widget.session.token);
    _profileService = CompanyProfileService(
      apiClient: ApiClient(accessToken: widget.session.token),
    );
    _load();
  }

  @override
  void dispose() {
    for (final controller in [
      _questions,
      _taskWeight,
      _aiWeight,
      _managerWeight,
      _adminWeight,
      _prefix,
      _archiveDays,
      _companyName,
      _companyEmail,
      _companyPhone,
      _companyAddress,
      _companyCountry,
      _companyStatus,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _bool(dynamic value, bool fallback) => value == null
      ? fallback
      : value == true || value == 1 || value == '1' || value == 'true';
  String _value(Map<String, dynamic> data, String key, String fallback) =>
      data[key]?.toString().isNotEmpty == true
      ? data[key].toString()
      : fallback;

  DateTime? _parseDateTime(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  String _formatDateTime(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}';
  }

  String _apiDateTime(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}:00';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final settings = await _service.fetch();
      final companyId = widget.session.user['company_id']?.toString();
      final data = companyId == null || companyId.isEmpty
          ? <String, dynamic>{}
          : await _profileService.fetch(companyId);
      if (!mounted) return;
      setState(() {
        _companyName.text = _value(data, 'name', '');
        _companyEmail.text = _value(data, 'email', '');
        _companyPhone.text = _value(data, 'phone', '');
        _companyAddress.text = _value(data, 'address', '');
        _companyCountry.text = _value(data, 'country', 'CM');
        _companyStatus.text = _value(data, 'status', 'active');
        _language = _value(settings, 'default_language', 'fr');
        _timezone = _value(settings, 'timezone', 'Africa/Douala');
        _dateFormat = _value(settings, 'date_format', 'Y-m-d');
        _timeFormat = _value(settings, 'time_format', 'H:i');
        _notifications = _bool(settings['notifications_enabled'], true);
        _whatsapp = _bool(settings['whatsapp_notifications_enabled'], false);
        _evaluations = _bool(settings['evaluation_enabled'], true);
        _courriers = _bool(settings['courrier_enabled'], true);
        _tasks = _bool(settings['task_management_enabled'], true);
        _ai = _bool(settings['allow_ai_evaluation'], false);
        _autoArchive = _bool(settings['courrier_auto_archive'], false);
        _evaluationStartAt = _parseDateTime(settings['evaluation_start_at']);
        _questions.text = _value(settings, 'evaluation_questions_count', '10');
        _taskWeight.text = _value(settings, 'evaluation_task_weight', '40');
        _aiWeight.text = _value(settings, 'evaluation_ai_weight', '40');
        _managerWeight.text = _value(
          settings,
          'evaluation_manager_weight',
          '10',
        );
        _adminWeight.text = _value(settings, 'evaluation_admin_weight', '10');
        _prefix.text = _value(settings, 'courrier_reference_prefix', 'COUR');
        _archiveDays.text = _value(
          settings,
          'courrier_auto_archive_days',
          '30',
        );
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Impossible de charger les parametres entreprise.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _int(TextEditingController controller, int fallback) =>
      int.tryParse(controller.text.trim()) ?? fallback;

  Future<void> _save() async {
    final task = _int(_taskWeight, 40);
    final ai = _int(_aiWeight, 40);
    final manager = _int(_managerWeight, 10);
    final admin = _int(_adminWeight, 10);
    if (task != 40 || ai != 40 || manager != 10 || admin != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).weightsInvalid)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.update({
        'default_language': _language,
        'timezone': _timezone,
        'date_format': _dateFormat,
        'time_format': _timeFormat,
        'notifications_enabled': _notifications,
        'whatsapp_notifications_enabled': _whatsapp,
        'evaluation_enabled': _evaluations,
        'courrier_enabled': _courriers,
        'task_management_enabled': _tasks,
        'allow_ai_evaluation': _ai,
        'evaluation_start_at': _evaluationStartAt == null
            ? null
            : _apiDateTime(_evaluationStartAt!),
        'evaluation_questions_count': _int(_questions, 10),
        'evaluation_task_weight': task,
        'evaluation_ai_weight': ai,
        'evaluation_manager_weight': manager,
        'evaluation_admin_weight': admin,
        'courrier_reference_prefix': _prefix.text.trim(),
        'courrier_auto_archive': _autoArchive,
        'courrier_auto_archive_days': _autoArchive
            ? _int(_archiveDays, 30)
            : null,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).settingsUpdated)),
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

  Future<void> _pickEvaluationStartAt() async {
    final strings = AppLocalizations.of(context);
    final current = _evaluationStartAt ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: strings.openingDate,
      cancelText: strings.cancel,
      confirmText: strings.continueLabel,
    );
    if (!mounted || date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      helpText: strings.openingTime,
      cancelText: strings.cancel,
      confirmText: strings.validate,
    );
    if (!mounted || time == null) return;

    setState(() {
      _evaluationStartAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  bool get _isSuperAdmin {
    final roles = widget.session.user['roles'];
    return roles is List &&
        roles.any(
          (role) =>
              (role is Map ? role['name'] : role).toString().toLowerCase() ==
              'super_admin',
        );
  }

  Future<void> _saveCompany() async {
    final companyId = widget.session.user['company_id']?.toString();
    if (companyId == null ||
        companyId.isEmpty ||
        _companyName.text.trim().isEmpty ||
        _companyEmail.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).companyRequired)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _profileService.update(companyId, {
        'name': _companyName.text.trim(),
        'email': _companyEmail.text.trim(),
        'phone': _companyPhone.text.trim().isEmpty
            ? null
            : _companyPhone.text.trim(),
        'address': _companyAddress.text.trim().isEmpty
            ? null
            : _companyAddress.text.trim(),
        'country': _companyCountry.text.trim().isEmpty
            ? null
            : _companyCountry.text.trim(),
        if (_isSuperAdmin) 'status': _companyStatus.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).companyUpdated)),
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

  Widget _section(String title, String subtitle, List<Widget> children) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xff64748b), height: 1.35),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    ),
  );
  Widget _switch(String title, bool value, ValueChanged<bool> onChanged) =>
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        value: value,
        onChanged: _saving ? null : onChanged,
      );
  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
  }) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    decoration: InputDecoration(labelText: label),
  );

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).companySettings),
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
              strings.companySettings,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              strings.personalSettingsNotice,
              style: TextStyle(color: Color(0xff64748b), height: 1.4),
            ),
            const SizedBox(height: 18),
            if (_loading)
              const _CompanySkeleton()
            else if (_error != null)
              _CompanyState(message: _error!, onRetry: _load)
            else ...[
              _section(
                strings.companyInformation,
                strings.companyInformationDescription,
                [
                  _field(_companyName, strings.companyName),
                  const SizedBox(height: 12),
                  _field(_companyEmail, 'Email'),
                  const SizedBox(height: 12),
                  _field(_companyPhone, strings.phone),
                  const SizedBox(height: 12),
                  _field(_companyAddress, strings.address),
                  const SizedBox(height: 12),
                  _field(_companyCountry, strings.country),
                  if (_isSuperAdmin) ...[
                    const SizedBox(height: 12),
                    _field(_companyStatus, strings.companyStatus),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _saving ? null : _saveCompany,
                      child: Text(AppLocalizations.of(context).saveInformation),
                    ),
                  ),
                ],
              ),
              _section(strings.modules, strings.modulesDescription, [
                _switch(
                  strings.globalNotifications,
                  _notifications,
                  (value) => setState(() => _notifications = value),
                ),
                _switch(
                  strings.whatsappNotifications,
                  _whatsapp,
                  (value) => setState(() => _whatsapp = value),
                ),
                _switch(
                  strings.taskManagement,
                  _tasks,
                  (value) => setState(() => _tasks = value),
                ),
                _switch(
                  strings.mailManagement,
                  _courriers,
                  (value) => setState(() => _courriers = value),
                ),
                _switch(
                  strings.evaluations,
                  _evaluations,
                  (value) => setState(() => _evaluations = value),
                ),
                _switch(
                  strings.aiEvaluation,
                  _ai,
                  (value) => setState(() => _ai = value),
                ),
              ]),
              _section(strings.general, strings.generalDescription, [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _language,
                  decoration: InputDecoration(
                    labelText: strings.defaultLanguage,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'fr',
                      child: Text(strings.frenchLanguage),
                    ),
                    DropdownMenuItem(
                      value: 'en',
                      child: Text(strings.englishLanguage),
                    ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _language = value ?? 'fr'),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _timezone,
                  decoration: InputDecoration(labelText: strings.timezone),
                  items: const [
                    DropdownMenuItem(
                      value: 'Africa/Douala',
                      child: Text('Africa/Douala'),
                    ),
                    DropdownMenuItem(value: 'UTC', child: Text('UTC')),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(
                          () => _timezone = value ?? 'Africa/Douala',
                        ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _dateFormat,
                  decoration: InputDecoration(labelText: strings.dateFormat),
                  items: const [
                    DropdownMenuItem(value: 'Y-m-d', child: Text('YYYY-MM-DD')),
                    DropdownMenuItem(value: 'd/m/Y', child: Text('DD/MM/YYYY')),
                    DropdownMenuItem(value: 'm/d/Y', child: Text('MM/DD/YYYY')),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) =>
                            setState(() => _dateFormat = value ?? 'Y-m-d'),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _timeFormat,
                  decoration: InputDecoration(labelText: strings.hourFormat),
                  items: [
                    DropdownMenuItem(
                      value: 'H:i',
                      child: Text(strings.twentyFourHours),
                    ),
                    DropdownMenuItem(
                      value: 'h:i A',
                      child: Text(strings.twelveHours),
                    ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _timeFormat = value ?? 'H:i'),
                ),
              ]),
              _section(
                strings.evaluationsSection,
                strings.evaluationSettingsDescription,
                [
                  InkWell(
                    onTap: _saving ? null : _pickEvaluationStartAt,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: strings.evaluationStartDate,
                        suffixIcon: _evaluationStartAt == null
                            ? const Icon(Iconsax.calendar)
                            : IconButton(
                                tooltip: strings.removeDate,
                                onPressed: _saving
                                    ? null
                                    : () => setState(
                                        () => _evaluationStartAt = null,
                                      ),
                                icon: const Icon(Iconsax.close_circle),
                              ),
                      ),
                      child: Text(
                        _evaluationStartAt == null
                            ? strings.chooseDateTime
                            : _formatDateTime(_evaluationStartAt!),
                        style: TextStyle(
                          color: _evaluationStartAt == null
                              ? const Color(0xff64748b)
                              : const Color(0xff172033),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _field(
                    _questions,
                    strings.questionsCount,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          _taskWeight,
                          strings.taskWeight,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          _aiWeight,
                          'IA (%)',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          _managerWeight,
                          strings.managerWeight,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          _adminWeight,
                          strings.adminWeight,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              _section(strings.courriers, strings.courrierSettingsDescription, [
                _field(_prefix, strings.referencePrefix),
                const SizedBox(height: 10),
                _switch(
                  strings.autoArchive,
                  _autoArchive,
                  (value) => setState(() => _autoArchive = value),
                ),
                if (_autoArchive)
                  _field(
                    _archiveDays,
                    strings.archiveDelay,
                    keyboardType: TextInputType.number,
                  ),
              ]),
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
                      : Text(strings.saveSettings),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompanySkeleton extends StatelessWidget {
  const _CompanySkeleton();
  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(
      4,
      (_) => Container(
        height: 150,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xffe9eff7),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
  );
}

class _CompanyState extends StatelessWidget {
  const _CompanyState({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 48),
    child: Column(
      children: [
        const Icon(Iconsax.building_4, size: 46, color: Color(0xff94a3b8)),
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

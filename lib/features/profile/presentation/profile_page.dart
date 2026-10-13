import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/network/api_client.dart';
import '../../../core/ui/app_messenger.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/app_language.dart';
import '../../auth/data/auth_service.dart';
import '../../settings/data/user_settings_service.dart';
import '../data/job_profile_service.dart';
import 'job_profile_details_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.session});

  final AuthSession session;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService();
  final _settingsService = UserSettingsService();
  final _jobProfileService = JobProfileService();
  late Map<String, dynamic> _user;
  UserSettings _settings = const UserSettings();
  bool _loading = false;
  bool _savingSettings = false;

  static const _cameroonDiplomas = <String>[
    'CEP',
    'BEPC',
    'CAP',
    'Probatoire',
    'Baccalaureat',
    'BTS',
    'DUT',
    'Licence',
    'Licence professionnelle',
    'Master',
    'Ingenieur',
    'Doctorat',
  ];

  static const _studyFields = <String>[
    'Informatique',
    'Genie logiciel',
    'Reseaux et securite',
    "Systemes d'information",
    'Data / Intelligence artificielle',
    'Gestion',
    'Comptabilite',
    'Finance',
    'Ressources humaines',
    'Marketing',
    'Droit',
    'Communication',
    'Logistique',
    'Genie civil',
    'Electrotechnique',
    'Maintenance industrielle',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _user = widget.session.user;
    _refresh();
  }

  Future<void> _refresh() async {
    if (mounted) setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _authService.currentUser(),
        _settingsService.fetch(),
      ]);
      if (mounted) {
        setState(() {
          _user = results[0] as Map<String, dynamic>;
          _settings = results[1] as UserSettings;
        });
      }
    } on ApiException catch (error) {
      showAppError(error.message);
    } catch (_) {
      showAppError('Impossible de charger votre profil.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editProfile() async {
    final firstName = TextEditingController(
      text: _user['first_name']?.toString() ?? '',
    );
    final lastName = TextEditingController(
      text: _user['last_name']?.toString() ?? '',
    );
    final phone = TextEditingController(text: _user['phone']?.toString() ?? '');
    final jobTitle = TextEditingController(
      text: _user['job_title']?.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FormSheet(
        title: 'Modifier mes informations',
        actionLabel: 'Enregistrer',
        formKey: formKey,
        fields: [
          TextFormField(
            controller: firstName,
            decoration: const InputDecoration(labelText: 'Prenom'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Champ obligatoire.'
                : null,
          ),
          TextFormField(
            controller: lastName,
            decoration: const InputDecoration(labelText: 'Nom'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Champ obligatoire.'
                : null,
          ),
          TextFormField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Telephone'),
          ),
          TextFormField(
            controller: jobTitle,
            decoration: const InputDecoration(labelText: 'Poste'),
          ),
        ],
        onSubmit: () async {
          if (!(formKey.currentState?.validate() ?? false)) return;
          try {
            final user = await _authService.updateProfile(
              firstName: firstName.text,
              lastName: lastName.text,
              phone: phone.text,
              jobTitle: jobTitle.text,
            );
            if (mounted) setState(() => _user = user);
            if (context.mounted) Navigator.pop(context, true);
            showAppSuccess('Profil mis a jour.');
          } on ApiException catch (error) {
            showAppError(error.message);
          }
        },
      ),
    );
    firstName.dispose();
    lastName.dispose();
    phone.dispose();
    jobTitle.dispose();
    if (saved == true && mounted) setState(() {});
  }

  Future<void> _changePassword() async {
    final current = TextEditingController();
    final password = TextEditingController();
    final confirmation = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FormSheet(
        title: 'Securite du compte',
        actionLabel: 'Changer le mot de passe',
        formKey: formKey,
        fields: [
          TextFormField(
            controller: current,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mot de passe actuel'),
            validator: _required,
          ),
          TextFormField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nouveau mot de passe',
            ),
            validator: (value) => value == null || value.length < 8
                ? '8 caracteres minimum.'
                : null,
          ),
          TextFormField(
            controller: confirmation,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirmer le mot de passe',
            ),
            validator: (value) => value != password.text
                ? 'Les mots de passe ne correspondent pas.'
                : null,
          ),
        ],
        onSubmit: () async {
          if (!(formKey.currentState?.validate() ?? false)) return;
          try {
            await _authService.updatePassword(
              currentPassword: current.text,
              password: password.text,
              confirmation: confirmation.text,
            );
            if (context.mounted) Navigator.pop(context);
            showAppSuccess('Mot de passe mis a jour.');
          } on ApiException catch (error) {
            showAppError(error.message);
          }
        },
      ),
    );
    current.dispose();
    password.dispose();
    confirmation.dispose();
  }

  Future<void> _editJobProfile() async {
    final jobTitle = _user['job_title']?.toString().trim() ?? '';
    if (jobTitle.isEmpty) {
      showAppError(
        'Renseignez d abord votre titre de poste dans vos informations personnelles.',
      );
      return;
    }
    final profile = _user['job_profile'] is Map
        ? Map<String, dynamic>.from(_user['job_profile'] as Map)
        : <String, dynamic>{};
    final parsedLevel = _parseJobProfileLevel(profile['level']?.toString());
    String? selectedDiploma = parsedLevel.$1.isEmpty ? null : parsedLevel.$1;
    String? selectedStudyField = parsedLevel.$2.isEmpty ? null : parsedLevel.$2;
    final description = TextEditingController(
      text: profile['description']?.toString() ?? '',
    );
    final missions = TextEditingController(
      text: profile['missions']?.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();
    final userId = _user['id']?.toString();

    if (userId == null || userId.isEmpty) {
      showAppError('Utilisateur introuvable.');
      return;
    }

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FormSheet(
        title: 'Fiche de poste',
        actionLabel: profile.isEmpty ? 'Ajouter la fiche' : 'Enregistrer',
        formKey: formKey,
        fields: [
          TextFormField(
            initialValue: jobTitle,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Role',
              helperText: 'Repris automatiquement du titre du poste.',
            ),
          ),
          DropdownButtonFormField<String>(
            initialValue: _cameroonDiplomas.contains(selectedDiploma)
                ? selectedDiploma
                : null,
            decoration: const InputDecoration(labelText: 'Dernier diplome'),
            items: _cameroonDiplomas
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) => selectedDiploma = value,
            validator: (value) => value == null || value.isEmpty
                ? 'Le dernier diplome est requis.'
                : null,
          ),
          DropdownButtonFormField<String>(
            initialValue: _studyFields.contains(selectedStudyField)
                ? selectedStudyField
                : null,
            decoration: const InputDecoration(labelText: "Domaine d'etude"),
            items: _studyFields
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) => selectedStudyField = value,
            validator: (value) => value == null || value.isEmpty
                ? "Le domaine d'etude est requis."
                : null,
          ),
          TextFormField(
            controller: description,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Description du poste',
              hintText: 'Resumez la responsabilite du poste',
              alignLabelWithHint: true,
            ),
          ),
          TextFormField(
            controller: missions,
            minLines: 4,
            maxLines: 7,
            decoration: const InputDecoration(
              labelText: 'Missions',
              hintText: 'Listez les missions principales',
              alignLabelWithHint: true,
            ),
          ),
        ],
        onSubmit: () async {
          if (!(formKey.currentState?.validate() ?? false)) return;
          final level = [selectedDiploma, selectedStudyField]
              .whereType<String>()
              .where((value) => value.trim().isNotEmpty)
              .join(' | ');
          final body = <String, dynamic>{
            'level': _nullableText(level),
            'description': _nullableText(description.text),
            'missions': _nullableText(missions.text),
          };
          try {
            final result = profile.isEmpty
                ? await _jobProfileService.create(userId, body)
                : await _jobProfileService.update(userId, body);
            if (result.isNotEmpty && mounted) {
              setState(() => _user = {..._user, 'job_profile': result});
            }
            if (context.mounted) Navigator.pop(context, true);
            showAppSuccess('Fiche de poste mise a jour.');
          } on ApiException catch (error) {
            showAppError(error.message);
          }
        },
      ),
    );
    description.dispose();
    missions.dispose();
    if (saved == true && mounted) setState(() {});
  }

  static String? _nullableText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static (String, String) _parseJobProfileLevel(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return ('', '');
    for (final separator in [' | ', ' - ']) {
      if (raw.contains(separator)) {
        final parts = raw.split(separator);
        return (parts.first.trim(), parts.skip(1).join(separator).trim());
      }
    }
    return (raw, '');
  }

  Future<void> _toggleSetting(UserSettings next) async {
    final previous = _settings;
    setState(() {
      _settings = next;
      _savingSettings = true;
    });
    try {
      final saved = await _settingsService.update(next);
      if (mounted) setState(() => _settings = saved);
      appLanguageNotifier.value = AppLanguage.fromCode(saved.language);
      showAppSuccess('Preferences enregistrees.');
    } on ApiException catch (error) {
      if (mounted) setState(() => _settings = previous);
      showAppError(error.message);
    } finally {
      if (mounted) setState(() => _savingSettings = false);
    }
  }

  static String? _required(String? value) =>
      value == null || value.isEmpty ? 'Champ obligatoire.' : null;

  static String _displayValue(String? value) =>
      value == null || value.trim().isEmpty ? 'Non renseigne' : value;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final firstName = _user['first_name']?.toString() ?? '';
    final lastName = _user['last_name']?.toString() ?? '';
    final fullName = [
      firstName,
      lastName,
    ].where((value) => value.isNotEmpty).join(' ');
    final roles = _user['roles'];
    final roleLabel = roles is List && roles.isNotEmpty
        ? roles.first.toString()
        : 'Utilisateur';
    final jobProfile = _user['job_profile'] is Map
        ? Map<String, dynamic>.from(_user['job_profile'] as Map)
        : <String, dynamic>{};
    final parsedJobLevel = _parseJobProfileLevel(
      jobProfile['level']?.toString(),
    );
    final jobDiploma = parsedJobLevel.$1;
    final jobStudyField = parsedJobLevel.$2;
    final jobDescription = jobProfile['description']?.toString();
    final jobMissions = jobProfile['missions']?.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.profileTitle),
        actions: [
          IconButton(
            tooltip: strings.refresh,
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Iconsax.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Center(
              child: CircleAvatar(
                radius: 42,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  (fullName.isNotEmpty ? fullName.substring(0, 1) : 'P')
                      .toUpperCase(),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              fullName.isEmpty ? 'Utilisateur' : fullName,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              roleLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xff64748b)),
            ),
            const SizedBox(height: 28),
            _SectionCard(
              title: strings.personalInformation,
              action: IconButton(
                tooltip: strings.edit,
                onPressed: _editProfile,
                icon: const Icon(Iconsax.edit),
              ),
              children: [
                _ProfileRow(
                  icon: Iconsax.sms,
                  label: 'E-mail',
                  value: _user['email']?.toString() ?? 'Non renseigne',
                ),
                _ProfileRow(
                  icon: Iconsax.call,
                  label: 'Telephone',
                  value: _user['phone']?.toString() ?? 'Non renseigne',
                ),
                _ProfileRow(
                  icon: Iconsax.briefcase,
                  label: 'Poste',
                  value: _user['job_title']?.toString() ?? 'Non renseigne',
                ),
                _ProfileRow(
                  icon: Iconsax.building_4,
                  label: 'Entreprise',
                  value:
                      (_user['company'] is Map
                              ? _user['company']['name']
                              : null)
                          ?.toString() ??
                      'Non renseignee',
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Fiche de poste',
              onTap: jobProfile.isEmpty
                  ? _editJobProfile
                  : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => JobProfileDetailsPage(
                          jobProfile: jobProfile,
                          fallbackRole: _user['job_title']?.toString(),
                        ),
                      ),
                    ),
              action: IconButton(
                tooltip: jobProfile.isEmpty ? 'Ajouter' : 'Modifier',
                onPressed: _editJobProfile,
                icon: Icon(
                  jobProfile.isEmpty ? Iconsax.add : Iconsax.edit,
                ),
              ),
              children: [
                if (jobProfile.isEmpty)
                  const ListTile(
                    leading: Icon(Iconsax.document_text),
                    title: Text('Aucune fiche de poste'),
                    subtitle: Text(
                      'Ajoutez votre niveau, votre description et vos missions.',
                    ),
                  )
                else ...[
                  _ProfileRow(
                    icon: Iconsax.personalcard,
                    label: 'Role',
                    value: _displayValue(
                      jobProfile['role']?.toString() ??
                          _user['job_title']?.toString(),
                    ),
                  ),
                  _ProfileRow(
                    icon: Iconsax.teacher,
                    label: 'Dernier diplome',
                    value: _displayValue(jobDiploma),
                  ),
                  _ProfileRow(
                    icon: Iconsax.book,
                    label: "Domaine d'etude",
                    value: _displayValue(jobStudyField),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: Icon(
                      Iconsax.export_3,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text(
                      'Voir la fiche complète',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${jobDescription?.trim().isNotEmpty == true ? 'Description' : ''}${jobDescription?.trim().isNotEmpty == true && jobMissions?.trim().isNotEmpty == true ? ' et ' : ''}${jobMissions?.trim().isNotEmpty == true ? 'missions' : ''}',
                    ),
                    trailing: const Icon(Iconsax.arrow_right),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: strings.security,
              children: [
                ListTile(
                  leading: Icon(
                    Iconsax.lock,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(strings.password),
                  subtitle: Text(strings.changePasswordDescription),
                  trailing: const Icon(Iconsax.arrow_right),
                  onTap: _changePassword,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: strings.preferencesAndNotifications,
              children: [
                ListTile(
                  leading: Icon(
                    Iconsax.language_circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(strings.defaultLanguage),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: const ['fr', 'en'].contains(_settings.language)
                          ? _settings.language
                          : null,
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
                      onChanged: _savingSettings
                          ? null
                          : (value) {
                              if (value != null) {
                                _toggleSetting(
                                  _settings.copyWith(language: value),
                                );
                              }
                            },
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Iconsax.clock,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(strings.timezoneLabel),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value:
                          const [
                            'Africa/Douala',
                            'UTC',
                          ].contains(_settings.timezone)
                          ? _settings.timezone
                          : null,
                      items: [
                        DropdownMenuItem(
                          value: 'Africa/Douala',
                          child: Text('Douala (GMT+1)'),
                        ),
                        DropdownMenuItem(value: 'UTC', child: Text('UTC')),
                      ],
                      onChanged: _savingSettings
                          ? null
                          : (value) {
                              if (value != null) {
                                _toggleSetting(
                                  _settings.copyWith(timezone: value),
                                );
                              }
                            },
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Iconsax.element_4,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(strings.defaultHome),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value:
                          const [
                            'dashboard',
                            'projects',
                            'tasks',
                            'courriers',
                            'evaluations',
                          ].contains(_settings.defaultDashboard)
                          ? _settings.defaultDashboard
                          : null,
                      items: [
                        DropdownMenuItem(
                          value: 'dashboard',
                          child: Text(strings.dashboard),
                        ),
                        DropdownMenuItem(
                          value: 'projects',
                          child: Text('Projets'),
                        ),
                        DropdownMenuItem(
                          value: 'tasks',
                          child: Text(strings.tasks),
                        ),
                        DropdownMenuItem(
                          value: 'courriers',
                          child: Text(strings.courriers),
                        ),
                        DropdownMenuItem(
                          value: 'evaluations',
                          child: Text(strings.evaluations),
                        ),
                      ],
                      onChanged: _savingSettings
                          ? null
                          : (value) {
                              if (value != null) {
                                _toggleSetting(
                                  _settings.copyWith(defaultDashboard: value),
                                );
                              }
                            },
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Iconsax.element_3,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Vue des taches'),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value:
                          const [
                            'kanban',
                            'list',
                          ].contains(_settings.defaultTasksView)
                          ? _settings.defaultTasksView
                          : null,
                      items: const [
                        DropdownMenuItem(
                          value: 'kanban',
                          child: Text('Kanban'),
                        ),
                        DropdownMenuItem(value: 'list', child: Text('Liste')),
                      ],
                      onChanged: _savingSettings
                          ? null
                          : (value) {
                              if (value != null) {
                                _toggleSetting(
                                  _settings.copyWith(defaultTasksView: value),
                                );
                              }
                            },
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Iconsax.sms,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Vue des courriers'),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value:
                          const [
                            'registre',
                            'tracking',
                          ].contains(_settings.defaultCourrierView)
                          ? _settings.defaultCourrierView
                          : null,
                      items: const [
                        DropdownMenuItem(
                          value: 'registre',
                          child: Text('Registre'),
                        ),
                        DropdownMenuItem(
                          value: 'tracking',
                          child: Text('Suivi'),
                        ),
                      ],
                      onChanged: _savingSettings
                          ? null
                          : (value) {
                              if (value != null) {
                                _toggleSetting(
                                  _settings.copyWith(
                                    defaultCourrierView: value,
                                  ),
                                );
                              }
                            },
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Iconsax.menu,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Elements par page'),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value:
                          const [
                            10,
                            15,
                            20,
                            50,
                            100,
                          ].contains(_settings.itemsPerPage)
                          ? _settings.itemsPerPage
                          : null,
                      items: const [10, 15, 20, 50, 100]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text('$value'),
                            ),
                          )
                          .toList(),
                      onChanged: _savingSettings
                          ? null
                          : (value) {
                              if (value != null) {
                                _toggleSetting(
                                  _settings.copyWith(itemsPerPage: value),
                                );
                              }
                            },
                    ),
                  ),
                ),
                SwitchListTile(
                  title: Text(strings.inAppNotifications),
                  value: _settings.inAppNotifications,
                  onChanged: _savingSettings
                      ? null
                      : (value) => _toggleSetting(
                          _settings.copyWith(inAppNotifications: value),
                        ),
                ),
                SwitchListTile(
                  title: Text(strings.emailNotifications),
                  value: _settings.emailNotifications,
                  onChanged: _savingSettings
                      ? null
                      : (value) => _toggleSetting(
                          _settings.copyWith(emailNotifications: value),
                        ),
                ),
                SwitchListTile(
                  title: Text(strings.whatsappNotifications),
                  value: _settings.whatsappNotifications,
                  onChanged: _savingSettings
                      ? null
                      : (value) => _toggleSetting(
                          _settings.copyWith(whatsappNotifications: value),
                        ),
                ),
                SwitchListTile(
                  title: Text(strings.taskNotifications),
                  value: _settings.taskNotifications,
                  onChanged: _savingSettings
                      ? null
                      : (value) => _toggleSetting(
                          _settings.copyWith(taskNotifications: value),
                        ),
                ),
                SwitchListTile(
                  title: Text(strings.evaluationNotifications),
                  value: _settings.evaluationNotifications,
                  onChanged: _savingSettings
                      ? null
                      : (value) => _toggleSetting(
                          _settings.copyWith(evaluationNotifications: value),
                        ),
                ),
                SwitchListTile(
                  title: Text(strings.courrierNotifications),
                  value: _settings.courrierNotifications,
                  onChanged: _savingSettings
                      ? null
                      : (value) => _toggleSetting(
                          _settings.copyWith(courrierNotifications: value),
                        ),
                ),
              ],
            ),
            if (_loading) ...[
              const SizedBox(height: 18),
              const LinearProgressIndicator(minHeight: 2),
            ],
          ],
        ),
      ),
    );
  }
}

class _FormSheet extends StatelessWidget {
  const _FormSheet({
    required this.title,
    required this.actionLabel,
    required this.formKey,
    required this.fields,
    required this.onSubmit,
  });

  final String title;
  final String actionLabel;
  final GlobalKey<FormState> formKey;
  final List<Widget> fields;
  final Future<void> Function() onSubmit;

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
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            ...fields.map(
              (field) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: field,
              ),
            ),
            FilledButton(
              onPressed: onSubmit,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
    this.action,
    this.onTap,
  });

  final String title;
  final List<Widget> children;
  final Widget? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Column(
        children: [
          ListTile(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            trailing: action,
          ),
          ...children,
        ],
      ),
    ),
  );
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
    title: Text(
      label,
      style: const TextStyle(fontSize: 12, color: Color(0xff64748b)),
    ),
    subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
  );
}

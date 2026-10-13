import 'dart:async';

import 'package:flutter/material.dart';

import 'app_theme.dart';
import '../core/localization/app_language.dart';
import '../core/localization/app_localizations.dart';
import '../core/notifications/push_notification_service.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../core/storage/onboarding_storage.dart';
import '../core/ui/app_messenger.dart';
import '../features/auth/data/auth_service.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/notifications/presentation/notifications_page.dart';
import '../features/splash/presentation/splash_page.dart';
import '../features/settings/data/user_settings_service.dart';

class PerfomiaApp extends StatefulWidget {
  const PerfomiaApp({super.key});

  @override
  State<PerfomiaApp> createState() => _PerfomiaAppState();
}

class _PerfomiaAppState extends State<PerfomiaApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final AuthService _authService;
  late final OnboardingStorage _onboardingStorage;
  late final TokenStorage _tokenStorage;
  late final LanguageStorage _languageStorage;
  AuthSession? _session;
  AppLanguage _language = AppLanguage.french;
  bool _checkingSession = true;
  bool _showSplash = true;
  bool _showOnboarding = false;
  bool _languageChangedSinceStartup = false;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    _tokenStorage = TokenStorage();
    _authService = AuthService(tokenStorage: _tokenStorage);
    _onboardingStorage = OnboardingStorage();
    _languageStorage = LanguageStorage();
    appLanguageNotifier.addListener(_onLanguageChanged);
    ApiClient.onUnauthorized = _handleUnauthorized;
    _restoreLanguage();
    _restoreSession();
    _splashTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
          _checkingSession = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    appLanguageNotifier.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    final language = appLanguageNotifier.value;
    if (mounted && language != null) {
      _languageChangedSinceStartup = true;
      if (language == _language) return;
      setState(() => _language = language);
    }
  }

  Future<void> _handleUnauthorized() async {
    if (!mounted || _session == null) return;
    setState(() {
      _session = null;
      _showOnboarding = false;
    });
    showAppError('Votre session a expire. Veuillez vous reconnecter.');
  }

  Future<void> _restoreSession() async {
    if (mounted) setState(() => _checkingSession = false);

    try {
      final token = await _tokenStorage.readToken();
      final cachedUser = await _tokenStorage.readUser();
      if (token != null && token.isNotEmpty) {
        try {
          final user = await _authService.currentUser();
          await _syncBackendLanguage(token);
          _session = AuthSession(token: token, user: user);
          _showOnboarding = !(await _onboardingStorage.isCompleted());
          unawaited(_initializeNotifications());
        } on ApiException catch (error) {
          if (error.statusCode == 401 || error.statusCode == 419) {
            await _authService.logout();
          } else if (cachedUser != null) {
            _session = AuthSession(token: token, user: cachedUser);
            _showOnboarding = !(await _onboardingStorage.isCompleted());
          }
        } catch (error) {
          debugPrint('Session restoration failed: $error');
          if (cachedUser != null) {
            _session = AuthSession(token: token, user: cachedUser);
            _showOnboarding = !(await _onboardingStorage.isCompleted());
          }
        }
      }
    } catch (error) {
      debugPrint('Session storage unavailable: $error');
      // A storage failure must leave the user on the login screen.
    }
    if (mounted) setState(() {});
  }

  Future<void> _restoreLanguage() async {
    try {
      final language = await _languageStorage.read();
      if (!mounted || _languageChangedSinceStartup || language == null) return;
      if (language != _language) setState(() => _language = language);
      appLanguageNotifier.value = language;
    } catch (_) {
      // French remains available if the saved preference cannot be read.
    }
  }

  Future<void> _logout() async {
    try {
      await PushNotificationService.instance.unregister(_authService);
      await _authService.logout();
    } finally {
      if (mounted) setState(() => _session = null);
    }
  }

  Future<void> _authenticated(AuthSession session) async {
    await _syncBackendLanguage(session.token);
    final onboardingCompleted = await _onboardingStorage.isCompleted();
    if (!mounted) return;
    setState(() {
      _session = session;
      _showOnboarding = !onboardingCompleted;
    });
    unawaited(_initializeNotifications());
  }

  Future<void> _initializeNotifications() async {
    try {
      await PushNotificationService.instance
          .initialize(authService: _authService, onOpened: _openNotifications)
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Notifications must not block access to the application.
    }
  }

  void _openNotifications() {
    _navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
  }

  Future<void> _syncBackendLanguage(String token) async {
    try {
      final settings = await UserSettingsService(
        apiClient: ApiClient(accessToken: token),
      ).fetch();
      final language = AppLanguage.fromCode(settings.language);
      appLanguageNotifier.value = language;
      if (mounted) setState(() => _language = language);
      try {
        await _languageStorage
            .write(language)
            .timeout(const Duration(seconds: 3));
      } catch (_) {
        // The backend preference remains active even if local storage fails.
      }
    } on ApiException {
      // Keep the cached language when the settings endpoint is temporarily unavailable.
    } catch (_) {
      // Keep the cached language when the settings endpoint is temporarily unavailable.
    }
  }

  Future<void> _completeOnboarding() async {
    if (mounted) setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Perfomia',
      locale: Locale(_language.code),
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: appMessengerKey,
      theme: PerfomiaTheme.light(),
      builder: (context, child) =>
          LocalizationScope(language: _language, child: child!),
      home: _showSplash || _checkingSession
          ? const SplashPage()
          : _session == null
          ? LoginPage(
              authService: _authService,
              onAuthenticated: _authenticated,
            )
          : _showOnboarding
          ? OnboardingPage(onCompleted: _completeOnboarding)
          : HomePage(session: _session!, onLogout: _logout),
    );
  }
}

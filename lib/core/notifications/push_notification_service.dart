import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/auth/data/auth_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } on FirebaseException {
    return;
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize({required AuthService authService, VoidCallback? onOpened}) async {
    if (kIsWeb) return;
    if (_initialized) return;

    try {
      await Firebase.initializeApp();
    } on FirebaseException {
      // Firebase config is supplied per environment; keep the app usable until it is present.
      return;
    }

    await _configureLocalNotifications();
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await authService.registerFcmToken(token, _platform);
    }

    _messaging.onTokenRefresh.listen((token) async {
      await authService.registerFcmToken(token, _platform);
    });

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen((_) => onOpened?.call());
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) onOpened?.call();
    _initialized = true;
  }

  Future<void> unregister(AuthService authService) async {
    if (kIsWeb) return;
    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await authService.unregisterFcmToken(token);
      }
    } catch (_) {
      // Local logout must not be blocked by notification cleanup.
    }
  }

  String get _platform => Platform.isIOS ? 'ios' : 'android';

  Future<void> _configureLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    final android = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'perfomia_notifications',
        'Notifications Perfomia',
        description: 'Alertes et mises à jour de votre espace Perfomia.',
        importance: Importance.high,
      ),
    );
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'perfomia_notifications',
          'Notifications Perfomia',
          channelDescription: 'Alertes et mises à jour de votre espace Perfomia.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}

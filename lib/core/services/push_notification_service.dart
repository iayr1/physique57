import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/firebase_options.dart';

// Top-level entry-point for background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}

  final notification = message.notification;
  if (notification != null) {
    const androidChannel = AndroidNotificationChannel(
      'erms_channel',
      'ERMS High Priority Alerts',
      description: 'Instant notification alerts for request status updates, approvals, tasks and announcements',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final localNotifications = FlutterLocalNotificationsPlugin();
    await localNotifications.show(
      notification.hashCode,
      notification.title ?? 'ERMS Notification',
      notification.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannel.id,
          androidChannel.name,
          channelDescription: androidChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
    'erms_channel',
    'ERMS High Priority Alerts',
    description: 'Instant notification alerts for request status updates, approvals, tasks and announcements',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static StreamSubscription<QuerySnapshot>? _firestoreNotifSub;
  static DateTime _serviceStartTime = DateTime.now();

  static Future<void> initialize() async {
    _serviceStartTime = DateTime.now();

    try {
      // 1. Request notification permissions (Android 13+ & iOS)
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );
      debugPrint('Notification Permission Status: ${settings.authorizationStatus}');

      // 2. Initialize Local Notifications Plugin
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification clicked with payload: ${details.payload}');
        },
      );

      // 3. Create High Priority Channel on Android
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);

      // 4. Listen to foreground FCM messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null) {
          showLocalNotification(
            id: notification.hashCode,
            title: notification.title ?? 'ERMS Alert',
            body: notification.body ?? '',
            payload: message.data['requestId']?.toString(),
          );
        }
      });

      // 5. Handle notification click when app opened from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('App opened from background notification: ${message.data}');
      });

      // 6. Subscribe to global announcements topic
      await _messaging.subscribeToTopic('all_employees');
    } catch (e) {
      debugPrint('PushNotificationService initialization error: $e');
    }
  }

  // Explicit helper to show a native notification
  static Future<void> showLocalNotification({
    int? id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _localNotifications.show(
        id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
            fullScreenIntent: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  // Start real-time Firestore notification listener for active employee
  static void startFirestoreNotificationListener(String userEmail) {
    _firestoreNotifSub?.cancel();
    final cleanEmail = userEmail.trim().toLowerCase();

    // Listen for new notifications addressed to user or 'all'
    _firestoreNotifSub = FirebaseFirestore.instance
        .collection('notifications')
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;

          final recipient = (data['recipientEmail'] ?? '').toString().toLowerCase();
          final title = data['title'] ?? 'New Alert';
          final message = data['message'] ?? '';
          final requestId = data['requestId'] ?? '';
          final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

          // Only trigger if notification is addressed to this user or 'all', and was created after service start
          final isForUser = recipient == cleanEmail || recipient == 'all';
          final isRecent = timestamp != null && timestamp.isAfter(_serviceStartTime.subtract(const Duration(seconds: 5)));

          if (isForUser && isRecent) {
            showLocalNotification(
              id: change.doc.id.hashCode,
              title: title,
              body: message,
              payload: requestId,
            );
          }
        }
      }
    });
  }

  static void stopFirestoreNotificationListener() {
    _firestoreNotifSub?.cancel();
    _firestoreNotifSub = null;
  }

  static Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (_) {
      return null;
    }
  }
}

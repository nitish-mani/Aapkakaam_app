import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseNotifications {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  // Deduplication tracking
  static final Map<String, int> _processedMessages = {};
  static Timer? _cleanupTimer;
  static bool _handlersInitialized = false;
  static bool _isNotificationClick = false;

  static final StreamController<Map<String, dynamic>>
  _notificationClickStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get notificationClickStream =>
      _notificationClickStreamController.stream;

  static Future<bool> initialize() async {
    if (_handlersInitialized) return false;
    _handlersInitialized = true;
    bool isPermissionGranted = false;

    try {
      await _initializeNotifications();
      isPermissionGranted = await _setupPermissionsAndToken();
      await _setupMessageHandlers();

      // Setup periodic cleanup every 2 minutes
      _cleanupTimer = Timer.periodic(const Duration(minutes: 2), (_) {
        final now = DateTime.now().millisecondsSinceEpoch;
        _processedMessages.removeWhere(
          (_, timestamp) => now - timestamp > 120000,
        ); // 2 minutes
      });
    } catch (e) {
      print('Error initializing Firebase Notifications: $e');
    }

    return isPermissionGranted;
  }

  static Future<void> _initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(android: initializationSettingsAndroid),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _isNotificationClick = true;
        if (response.payload != null) {
          _notificationClickStreamController.add(jsonDecode(response.payload!));
        }
        // Reset flag after handling
        Future.delayed(const Duration(milliseconds: 500), () {
          _isNotificationClick = false;
        });
      },
    );
  }

  static Future<bool> _setupPermissionsAndToken() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Notification permissions granted');
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        fcmToken.value = token;
        print('FCM Token: $token');
      }
      return true;
    }
    return false;
  }

  static Future<void> _setupMessageHandlers() async {
    // Handle foreground messages - show notification but don't navigate
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final messageHash = _createMessageHash(message);
      final now = DateTime.now().millisecondsSinceEpoch;

      if (_processedMessages.containsKey(messageHash)) {
        final lastProcessed = _processedMessages[messageHash]!;
        if (now - lastProcessed < 5000) {
          print('Skipping duplicate message: $messageHash');
          return;
        }
      }

      _processedMessages[messageHash] = now;
      print('Processing message: $messageHash');

      await _showNotification(message);
      setNotificationCount(message.data);
      print(message.data);
      // Don't call _handleNotificationData here to prevent auto-navigation
    });

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _isNotificationClick = true;
      _notificationClickStreamController.add(message.data);
      Future.delayed(const Duration(milliseconds: 500), () {
        _isNotificationClick = false;
      });
    });

    // Handle initial notification when app is launched
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _isNotificationClick = true;
      _handleNotificationData(initialMessage.data);
      // Reset flag after handling
      Future.delayed(const Duration(milliseconds: 500), () {
        _isNotificationClick = false;
      });
    }
  }

  static int calculateNewNotificationCount(Map<String, bool> data) {
    int count = 0;
    data.forEach((key, value) {
      if (value) {
        count++;
      }
    });
    return count;
  }

  static void setNotificationCount(Map<String, dynamic> data) {
    final id = data['id']?.toString() ?? '';
    upsertBooking(id, true);

    int count = calculateNewNotificationCount(bookingIdNotifier.value);
    bookingCountNotifier.value = count;
    print('bookingCountNotifier : ${bookingCountNotifier.value}');
  }

  static void _updateUIForBooking(Map<String, dynamic> data) {
    if (!_isNotificationClick) {
      return; // Only navigate if notification was clicked
    }

    // final id = data['id']?.toString() ?? '';
    if (isVendor.value) {
      selectedPageNotifier.value = 1;
      bookingStatusNotifier.value = 1;
      monthNotifier.value = int.parse(data['month']) + 1;
      yearNotifier.value = int.parse(data['year']);
    } else {
      selectedPageNotifier.value = 2;
      bookingStatusNotifier.value = 1;
    }
  }

  static void _updateUIForCancellation(Map<String, dynamic> data) {
    if (!_isNotificationClick) {
      return; // Only navigate if notification was clicked
    }

    // final id = data['id']?.toString() ?? '';
    if (isVendor.value) {
      selectedPageNotifier.value = 1;
      bookingStatusNotifier.value = 3;
      monthNotifier.value = int.parse(data['month']) + 1;
      yearNotifier.value = int.parse(data['year']);
      // upsertBooking(id, true);
    } else {
      selectedPageNotifier.value = 2;
      bookingStatusNotifier.value = 3;
    }
  }

  static String _createMessageHash(RemoteMessage message) {
    // Create a unique hash based on message content and timestamp
    final content = '${message.messageId}-${message.data.toString()}';
    return content.hashCode.toString();
  }

  static Future<void> _showNotification(RemoteMessage message) async {
    try {
      final notificationId = Random().nextInt(2147483647);

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
            icon: '@mipmap/ic_launcher',
            color: Colors.black,
            playSound: true,
            enableVibration: true,
          );

      await flutterLocalNotificationsPlugin.show(
        notificationId,
        message.notification?.title ??
            message.data['title'] ??
            'New Notification',
        message.notification?.body ??
            message.data['body'] ??
            'You have a new message',
        const NotificationDetails(android: androidDetails),
        payload: jsonEncode(message.data),
      );
      print(message);
      // final id = message['id']?.toString() ?? '';
      //   upsertBooking(id, value)
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  static void _handleNotificationData(Map<String, dynamic> data) {
    print('Handling notification data: $data');

    final type = data['type'];
    // final id = data['id']?.toString() ?? '';

    switch (type) {
      case 'booking':
        _updateUIForBooking(data);
        _refreshBookingsData();
        break;
      case 'cancelled':
        _updateUIForCancellation(data);
        _refreshBookingsData();
        break;
      case 'profile_update':
        profileRefreshNotifier.value = !profileRefreshNotifier.value;
        break;
      default:
        if (data['screen'] == 'profile') {
          // Handle profile navigation
        }
    }
  }

  static void upsertBooking(String id, bool value) {
    bookingIdNotifier.value = {...bookingIdNotifier.value, id: value};
  }

  static void _refreshBookingsData() {
    bookingsRefreshNotifier.value = !bookingsRefreshNotifier.value;
  }

  static void dispose() {
    _cleanupTimer?.cancel();
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/models/data_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================
/// BACKGROUND FCM HANDLER
/// ============================================================

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();

    debugPrint('FCM BACKGROUND MESSAGE: ${message.messageId}');

    debugPrint('FCM BACKGROUND DATA: ${message.data}');
  } catch (e, stackTrace) {
    debugPrint('FCM background handler error: $e');

    debugPrintStack(stackTrace: stackTrace);
  }
}

/// ============================================================
/// FIREBASE NOTIFICATIONS
/// ============================================================

class FirebaseNotifications {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  // ============================================================
  // INTERNAL STATE
  // ============================================================

  static final Map<String, int> _processedMessages = {};

  static Timer? _cleanupTimer;

  static bool _handlersInitialized = false;

  static bool _tokenRefreshListenerInitialized = false;

  static bool _isNotificationClick = false;

  static bool _tokenUpdateInProgress = false;

  // ============================================================
  // NOTIFICATION CLICK STREAM
  // ============================================================

  static final StreamController<Map<String, dynamic>>
  _notificationClickStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get notificationClickStream =>
      _notificationClickStreamController.stream;

  // ============================================================
  // INITIALIZE
  // ============================================================

  static Future<bool> initialize() async {
    if (_handlersInitialized) {
      debugPrint('Firebase Notifications already initialized');

      await synchronizeCurrentToken();

      return true;
    }

    _handlersInitialized = true;

    bool permissionGranted = false;

    try {
      debugPrint('Initializing Firebase Notifications...');

      // --------------------------------------------------------
      // Local notifications
      // --------------------------------------------------------

      await _initializeNotifications();

      // --------------------------------------------------------
      // Permission + token
      // --------------------------------------------------------

      permissionGranted = await _setupPermissionsAndToken();

      // --------------------------------------------------------
      // FCM message handlers
      // --------------------------------------------------------

      await _setupMessageHandlers();

      // --------------------------------------------------------
      // Cleanup duplicate-message cache
      // --------------------------------------------------------

      _cleanupTimer = Timer.periodic(const Duration(minutes: 2), (_) {
        final now = DateTime.now().millisecondsSinceEpoch;

        _processedMessages.removeWhere(
          (_, timestamp) => now - timestamp > 120000,
        );
      });

      debugPrint('Firebase Notifications initialized');
    } catch (e, stackTrace) {
      debugPrint('Firebase Notifications initialization error: $e');

      debugPrintStack(stackTrace: stackTrace);
    }

    return permissionGranted;
  }

  // ============================================================
  // LOCAL NOTIFICATION INITIALIZATION
  // ============================================================

  static Future<void> _initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'High priority AapkaKaam notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final androidPlugin =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidPlugin?.createNotificationChannel(channel);

    await androidPlugin?.requestNotificationsPermission();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        try {
          _isNotificationClick = true;

          debugPrint('Local notification clicked');

          if (response.payload != null && response.payload!.isNotEmpty) {
            final decoded = jsonDecode(response.payload!);

            final data = Map<String, dynamic>.from(decoded);

            _notificationClickStreamController.add(data);

            _handleNotificationData(data);
          }
        } catch (e, stackTrace) {
          debugPrint('Local notification click error: $e');

          debugPrintStack(stackTrace: stackTrace);
        }

        Future.delayed(const Duration(milliseconds: 500), () {
          _isNotificationClick = false;
        });
      },
    );
  }

  // ============================================================
  // PERMISSION + TOKEN
  // ============================================================

  static Future<bool> _setupPermissionsAndToken() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      debugPrint(
        'FCM Authorization status: '
        '${settings.authorizationStatus}',
      );

      final authorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (!authorized) {
        debugPrint('FCM notification permission not granted');

        return false;
      }

      debugPrint('FCM notification permission granted');

      final token = await _firebaseMessaging.getToken();

      if (token != null && token.isNotEmpty) {
        await _handleFcmToken(token);
      }

      _setupTokenRefreshListener();

      return true;
    } catch (e, stackTrace) {
      debugPrint('FCM permission/token error: $e');

      debugPrintStack(stackTrace: stackTrace);

      return false;
    }
  }

  // ============================================================
  // TOKEN REFRESH LISTENER
  // ============================================================

  static void _setupTokenRefreshListener() {
    if (_tokenRefreshListenerInitialized) {
      return;
    }

    _tokenRefreshListenerInitialized = true;

    _firebaseMessaging.onTokenRefresh.listen(
      (newToken) async {
        try {
          final token = newToken.trim();

          if (token.isEmpty) {
            return;
          }

          debugPrint('FCM TOKEN REFRESHED');

          debugPrint(token);

          await _handleFcmToken(token);
        } catch (e, stackTrace) {
          debugPrint('FCM token refresh handling error: $e');

          debugPrintStack(stackTrace: stackTrace);
        }
      },
      onError: (error) {
        debugPrint('FCM token refresh stream error: $error');
      },
    );
  }

  // ============================================================
  // HANDLE TOKEN
  // ============================================================

  static Future<void> _handleFcmToken(String token) async {
    final normalizedToken = token.trim();

    if (normalizedToken.isEmpty) {
      return;
    }

    fcmToken.value = normalizedToken;

    debugPrint('FCM token updated locally');

    await _updateTokenOnServer(normalizedToken);
  }

  // ============================================================
  // SYNCHRONIZE CURRENT TOKEN
  // ============================================================

  static Future<void> synchronizeCurrentToken() async {
    try {
      final token = await _firebaseMessaging.getToken();

      if (token == null || token.trim().isEmpty) {
        debugPrint(
          'Cannot synchronize FCM token: '
          'token unavailable',
        );

        return;
      }

      await _handleFcmToken(token.trim());
    } catch (e, stackTrace) {
      debugPrint('FCM token synchronization error: $e');

      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // ============================================================
  // UPDATE TOKEN ON SERVER
  // ============================================================

  static Future<void> _updateTokenOnServer(String token) async {
    if (_tokenUpdateInProgress) {
      debugPrint('FCM token update already in progress');

      return;
    }

    try {
      _tokenUpdateInProgress = true;

      final prefs = await SharedPreferences.getInstance();

      // --------------------------------------------------------
      // Determine logged-in account
      // --------------------------------------------------------

      final isVendorUser = prefs.getBool('isVendor') ?? isVendor.value;

      final category = isVendorUser ? 'vendor' : 'user';

      final categoryData = prefs.getString(category);

      if (categoryData == null || categoryData.isEmpty) {
        debugPrint(
          'FCM token not synchronized: '
          'no logged-in $category data',
        );

        return;
      }

      final decoded = jsonDecode(categoryData);

      final authToken = decoded['token']?.toString();

      if (authToken == null || authToken.isEmpty) {
        debugPrint(
          'FCM token not synchronized: '
          'authentication token missing',
        );

        return;
      }

      // --------------------------------------------------------
      // Endpoint
      // --------------------------------------------------------

      final url = Uri.parse("${KConstantURL.url}/$category/edit/fcmToken");

      final body = <String, dynamic>{'fcmToken': token};

      if (category == 'user') {
        final userId = decoded['userId']?.toString();

        if (userId != null && userId.isNotEmpty) {
          body['userId'] = userId;
        }
      } else {
        final vendorId = decoded['vendorId']?.toString();

        if (vendorId != null && vendorId.isNotEmpty) {
          body['vendorId'] = vendorId;
        }
      }

      debugPrint('Updating FCM token on backend...');

      final response = await http
          .patch(
            url,
            headers: {
              'Authorization': 'Bearer $authToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint(
        'FCM token update response: '
        '${response.statusCode}',
      );

      if (response.statusCode == 200) {
        dynamic updatedData;

        try {
          updatedData = jsonDecode(response.body);
        } catch (_) {
          updatedData = {};
        }

        await _saveUpdatedTokenLocally(
          prefs: prefs,
          category: category,
          decoded: decoded,
          token: token,
          responseData: updatedData,
        );

        debugPrint(
          'FCM token successfully synchronized '
          'with backend',
        );

        return;
      }

      if (response.statusCode == 401) {
        debugPrint(
          'FCM token update unauthorized. '
          'User/vendor may need to login again.',
        );

        return;
      }

      debugPrint(
        'FCM token update failed: '
        '${response.statusCode}',
      );

      debugPrint('Response: ${response.body}');
    } catch (e, stackTrace) {
      debugPrint('FCM backend token update error: $e');

      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _tokenUpdateInProgress = false;
    }
  }

  // ============================================================
  // SAVE UPDATED TOKEN LOCALLY
  // ============================================================

  static Future<void> _saveUpdatedTokenLocally({
    required SharedPreferences prefs,
    required String category,
    required Map<String, dynamic> decoded,
    required String token,
    required dynamic responseData,
  }) async {
    try {
      String? serverMessage;

      if (responseData is Map) {
        serverMessage = responseData['message']?.toString();
      }

      // --------------------------------------------------------
      // USER
      // --------------------------------------------------------

      if (category == 'user') {
        final existingUser = UserModel.fromJson(decoded);

        final updatedUser = existingUser.copyWith(
          fcmToken: token,
          message: serverMessage ?? existingUser.message,
        );

        await prefs.setString('user', jsonEncode(updatedUser.toJson()));

        return;
      }

      // --------------------------------------------------------
      // VENDOR
      // --------------------------------------------------------

      final existingVendor = VendorModel.fromJson(decoded);

      final updatedVendor = existingVendor.copyWith(
        fcmToken: token,
        message: serverMessage ?? existingVendor.message,
      );

      await prefs.setString('vendor', jsonEncode(updatedVendor.toJson()));
    } catch (e, stackTrace) {
      debugPrint('Failed to save updated FCM token locally: $e');

      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // ============================================================
  // MESSAGE HANDLERS
  // ============================================================

  static Future<void> _setupMessageHandlers() async {
    // ==========================================================
    // FOREGROUND
    // ==========================================================

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      try {
        debugPrint(
          'FCM FOREGROUND MESSAGE: '
          '${message.messageId}',
        );

        debugPrint('FCM DATA: ${message.data}');

        final messageHash = _createMessageHash(message);

        final now = DateTime.now().millisecondsSinceEpoch;

        // ------------------------------------------------------
        // DEDUPLICATE
        // ------------------------------------------------------

        if (_processedMessages.containsKey(messageHash)) {
          final lastProcessed = _processedMessages[messageHash]!;

          if (now - lastProcessed < 5000) {
            debugPrint('Skipping duplicate message');

            return;
          }
        }

        _processedMessages[messageHash] = now;

        // ------------------------------------------------------
        // SHOW LOCAL NOTIFICATION
        // ------------------------------------------------------

        await _showNotification(message);

        // ------------------------------------------------------
        // UPDATE BOOKING COUNT
        // ------------------------------------------------------

        setNotificationCount(message.data);
      } catch (e, stackTrace) {
        debugPrint('Foreground FCM handler error: $e');

        debugPrintStack(stackTrace: stackTrace);
      }
    });

    // ==========================================================
    // BACKGROUND → USER CLICK
    // ==========================================================

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      try {
        _isNotificationClick = true;

        final data = Map<String, dynamic>.from(message.data);

        debugPrint('Notification opened: $data');

        _notificationClickStreamController.add(data);

        _handleNotificationData(data);
      } catch (e, stackTrace) {
        debugPrint('onMessageOpenedApp error: $e');

        debugPrintStack(stackTrace: stackTrace);
      }

      Future.delayed(const Duration(milliseconds: 500), () {
        _isNotificationClick = false;
      });
    });

    // ==========================================================
    // TERMINATED → USER CLICK
    // ==========================================================

    final initialMessage = await _firebaseMessaging.getInitialMessage();

    if (initialMessage != null) {
      try {
        _isNotificationClick = true;

        final data = Map<String, dynamic>.from(initialMessage.data);

        debugPrint('Initial notification: $data');

        _handleNotificationData(data);
      } catch (e, stackTrace) {
        debugPrint('Initial notification error: $e');

        debugPrintStack(stackTrace: stackTrace);
      }

      Future.delayed(const Duration(milliseconds: 500), () {
        _isNotificationClick = false;
      });
    }
  }

  // ============================================================
  // NOTIFICATION COUNT
  // ============================================================

  static int calculateNewNotificationCount(Map<String, bool> data) {
    int count = 0;

    data.forEach((_, value) {
      if (value) {
        count++;
      }
    });

    return count;
  }

  static void setNotificationCount(Map<String, dynamic> data) {
    try {
      final id = data['bookingId']?.toString() ?? data['id']?.toString() ?? '';

      if (id.isNotEmpty) {
        upsertBooking(id, true);
      }

      final count = calculateNewNotificationCount(bookingIdNotifier.value);

      bookingCountNotifier.value = count;

      debugPrint('bookingCountNotifier: $count');
    } catch (e) {
      debugPrint('setNotificationCount error: $e');
    }
  }

  // ============================================================
  // BOOKING UI
  // ============================================================

  static void _updateUIForBooking(Map<String, dynamic> data) {
    if (!_isNotificationClick) {
      return;
    }

    try {
      if (isVendor.value) {
        selectedPageNotifier.value = 1;

        bookingStatusNotifier.value = 1;

        final month = int.tryParse(data['month']?.toString() ?? '');

        final year = int.tryParse(data['year']?.toString() ?? '');

        if (month != null) {
          monthNotifier.value = month + 1;
        }

        if (year != null) {
          yearNotifier.value = year;
        }
      } else {
        selectedPageNotifier.value = 2;

        bookingStatusNotifier.value = 1;
      }
    } catch (e) {
      debugPrint('_updateUIForBooking error: $e');
    }
  }

  // ============================================================
  // CANCELLATION UI
  // ============================================================

  static void _updateUIForCancellation(Map<String, dynamic> data) {
    if (!_isNotificationClick) {
      return;
    }

    try {
      if (isVendor.value) {
        selectedPageNotifier.value = 1;

        bookingStatusNotifier.value = 3;

        final month = int.tryParse(data['month']?.toString() ?? '');

        final year = int.tryParse(data['year']?.toString() ?? '');

        if (month != null) {
          monthNotifier.value = month + 1;
        }

        if (year != null) {
          yearNotifier.value = year;
        }
      } else {
        selectedPageNotifier.value = 2;

        bookingStatusNotifier.value = 3;
      }
    } catch (e) {
      debugPrint('_updateUIForCancellation error: $e');
    }
  }

  // ============================================================
  // VENDOR NEW BOOKING
  // ============================================================

  static void _handleVendorNewBooking(Map<String, dynamic> data) {
    if (!_isNotificationClick) {
      return;
    }

    debugPrint('Handling NEW BOOKING for vendor');

    selectedPageNotifier.value = 1;

    bookingStatusNotifier.value = 1;

    final month = int.tryParse(data['month']?.toString() ?? '');

    final year = int.tryParse(data['year']?.toString() ?? '');

    if (month != null) {
      monthNotifier.value = month + 1;
    }

    if (year != null) {
      yearNotifier.value = year;
    }

    _refreshBookingsData();
  }

  // ============================================================
  // USER BOOKING CONFIRMED
  // ============================================================

  static void _handleUserBookingConfirmed(Map<String, dynamic> data) {
    if (!_isNotificationClick) {
      return;
    }

    debugPrint('Handling BOOKING CONFIRMED for user');

    selectedPageNotifier.value = 2;

    bookingStatusNotifier.value = 1;

    _refreshBookingsData();
  }

  // ============================================================
  // VENDOR BOOKING CANCELLED
  // ============================================================

  static void _handleVendorBookingCancelled(Map<String, dynamic> data) {
    if (!_isNotificationClick) {
      return;
    }

    debugPrint('Handling BOOKING CANCELLED for vendor');

    selectedPageNotifier.value = 1;

    bookingStatusNotifier.value = 3;

    final month = int.tryParse(data['month']?.toString() ?? '');

    final year = int.tryParse(data['year']?.toString() ?? '');

    if (month != null) {
      monthNotifier.value = month + 1;
    }

    if (year != null) {
      yearNotifier.value = year;
    }

    _refreshBookingsData();
  }

  // ============================================================
  // NOTIFICATION DATA
  // ============================================================

  static void _handleNotificationData(Map<String, dynamic> data) {
    try {
      debugPrint('Handling notification data: $data');

      // --------------------------------------------------------
      // Extract notification metadata
      // --------------------------------------------------------

      final type = data['type']?.toString();

      final recipientRole = data['recipientRole']?.toString();

      final notificationType = data['notificationType']?.toString();

      debugPrint(
        'Notification type: '
        '$notificationType',
      );

      debugPrint(
        'Recipient role: '
        '$recipientRole',
      );

      // --------------------------------------------------------
      // BOOKING
      // --------------------------------------------------------

      switch (type) {
        case 'booking':
          if (notificationType == 'new_booking' && recipientRole == 'vendor') {
            _handleVendorNewBooking(data);
          } else if (notificationType == 'booking_confirmed' &&
              recipientRole == 'user') {
            _handleUserBookingConfirmed(data);
          } else {
            // Backward compatibility
            _updateUIForBooking(data);

            _refreshBookingsData();
          }

          break;

        // ------------------------------------------------------
        // CANCELLED
        // ------------------------------------------------------

        case 'cancelled':
          if (notificationType == 'booking_cancelled' &&
              recipientRole == 'vendor') {
            _handleVendorBookingCancelled(data);
          } else {
            // Backward compatibility
            _updateUIForCancellation(data);

            _refreshBookingsData();
          }

          break;

        // ------------------------------------------------------
        // PROFILE
        // ------------------------------------------------------

        case 'profile_update':
          profileRefreshNotifier.value = !profileRefreshNotifier.value;

          break;

        // ------------------------------------------------------
        // UNKNOWN
        // ------------------------------------------------------

        default:
          if (data['screen']?.toString() == 'profile') {
            // Add profile navigation
            // if required.
          }

          break;
      }
    } catch (e, stackTrace) {
      debugPrint('_handleNotificationData error: $e');

      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // ============================================================
  // MESSAGE HASH
  // ============================================================

  static String _createMessageHash(RemoteMessage message) {
    final content =
        '${message.messageId}|'
        '${jsonEncode(message.data)}';

    return content.hashCode.toString();
  }

  // ============================================================
  // SHOW LOCAL NOTIFICATION
  // ============================================================

  static Future<void> _showNotification(RemoteMessage message) async {
    try {
      final notificationId =
          message.messageId?.hashCode.abs() ??
          DateTime.now().millisecondsSinceEpoch.remainder(2147483647);

      final title =
          message.notification?.title ??
          message.data['title']?.toString() ??
          'New Notification';

      final body =
          message.notification?.body ??
          message.data['body']?.toString() ??
          'You have a new message';

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
            showWhen: true,
          );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: jsonEncode(message.data),
      );

      debugPrint('Local notification displayed');
    } catch (e, stackTrace) {
      debugPrint('Error showing notification: $e');

      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // ============================================================
  // BOOKING
  // ============================================================

  static void upsertBooking(String id, bool value) {
    if (id.isEmpty) {
      return;
    }

    bookingIdNotifier.value = {...bookingIdNotifier.value, id: value};
  }

  // ============================================================
  // REFRESH BOOKINGS
  // ============================================================

  static void _refreshBookingsData() {
    bookingsRefreshNotifier.value = !bookingsRefreshNotifier.value;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  static void dispose() {
    _cleanupTimer?.cancel();

    _cleanupTimer = null;

    _processedMessages.clear();

    _handlersInitialized = false;

    _tokenRefreshListenerInitialized = false;

    _tokenUpdateInProgress = false;

    if (!_notificationClickStreamController.isClosed) {
      _notificationClickStreamController.close();
    }
  }
}

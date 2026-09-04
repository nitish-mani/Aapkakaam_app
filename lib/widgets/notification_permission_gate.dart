// import 'package:app_settings/app_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class NotificationPermissionGate extends StatefulWidget {
  final Widget child;

  const NotificationPermissionGate({super.key, required this.child});

  @override
  State<NotificationPermissionGate> createState() =>
      _NotificationPermissionGateState();
}

class _NotificationPermissionGateState extends State<NotificationPermissionGate>
    with WidgetsBindingObserver {
  bool _checking = true;
  bool _allowed = false;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  // ==========================================================
  // APP LIFECYCLE
  // ==========================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  // ==========================================================
  // CHECK NOTIFICATION PERMISSION
  // ==========================================================

  Future<void> _checkPermission() async {
    if (!mounted) return;

    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();

      debugPrint(
        'Notification permission status: '
        '${settings.authorizationStatus}',
      );

      final authorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (!mounted) return;

      setState(() {
        _allowed = authorized;
        _checking = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Notification permission check failed: $e');

      debugPrint(stackTrace.toString());

      if (!mounted) return;

      setState(() {
        _checking = false;
        _allowed = false;
      });
    }
  }

  // ==========================================================
  // REQUEST NOTIFICATION PERMISSION
  // ==========================================================

  Future<void> _requestNotificationPermission() async {
    if (_requesting) return;

    if (!mounted) return;

    setState(() {
      _requesting = true;
    });

    try {
      final messaging = FirebaseMessaging.instance;

      // --------------------------------------------------------
      // CHECK CURRENT STATUS
      // --------------------------------------------------------

      final current = await messaging.getNotificationSettings();

      debugPrint(
        'Current notification status: '
        '${current.authorizationStatus}',
      );

      // --------------------------------------------------------
      // ALREADY AUTHORIZED
      // --------------------------------------------------------

      if (current.authorizationStatus == AuthorizationStatus.authorized ||
          current.authorizationStatus == AuthorizationStatus.provisional) {
        if (!mounted) return;

        setState(() {
          _allowed = true;
          _requesting = false;
        });

        return;
      }

      // --------------------------------------------------------
      // REQUEST PERMISSION
      // --------------------------------------------------------

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      debugPrint(
        'Permission request result: '
        '${settings.authorizationStatus}',
      );

      final authorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (!mounted) return;

      // --------------------------------------------------------
      // AUTHORIZED
      // --------------------------------------------------------

      if (authorized) {
        setState(() {
          _allowed = true;
          _requesting = false;
        });

        // ------------------------------------------------------
        // OPTIONAL FCM TOPIC
        // ------------------------------------------------------
        //
        // await messaging.subscribeToTopic('all_users');

        return;
      }

      // --------------------------------------------------------
      // DENIED
      // --------------------------------------------------------

      setState(() {
        _allowed = false;
        _requesting = false;
      });

      // --------------------------------------------------------
      // OPEN ANDROID NOTIFICATION SETTINGS
      // --------------------------------------------------------

      await _openNotificationSettings();
    } catch (e, stackTrace) {
      debugPrint('Notification permission request failed: $e');

      debugPrint(stackTrace.toString());

      if (!mounted) return;

      setState(() {
        _requesting = false;
        _allowed = false;
      });

      // --------------------------------------------------------
      // FALLBACK TO SETTINGS
      // --------------------------------------------------------

      await _openNotificationSettings();
    }
  }

  // ==========================================================
  // OPEN NOTIFICATION SETTINGS
  // ==========================================================

  Future<void> _openNotificationSettings() async {
    try {
      if (Platform.isIOS) {
        final Uri uri = Uri.parse('app-settings:');

        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      } else if (Platform.isAndroid) {
        // Opens the application's settings page.
        final Uri uri = Uri.parse('app-settings:');

        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      }
    } catch (e) {
      debugPrint('Could not open app settings: $e');
    }
  }
  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    // --------------------------------------------------------
    // CHECKING
    // --------------------------------------------------------

    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // --------------------------------------------------------
    // ALLOWED
    // --------------------------------------------------------

    if (_allowed) {
      return widget.child;
    }

    // --------------------------------------------------------
    // PERMISSION PAGE
    // --------------------------------------------------------

    return _buildPermissionPage(context);
  }

  // ==========================================================
  // PERMISSION PAGE
  // ==========================================================

  Widget _buildPermissionPage(BuildContext context) {
    final theme = Theme.of(context);

    final primary = theme.colorScheme.primary;

    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0B1020) : const Color(0xFFF5F7FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ==================================================
                // ICON
                // ==================================================
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary, primary.withOpacity(0.65)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(0.30),
                        blurRadius: 25,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.white,
                    size: 52,
                  ),
                ),

                const SizedBox(height: 28),

                // ==================================================
                // TITLE
                // ==================================================
                Text(
                  'Notifications Required',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),

                const SizedBox(height: 10),

                // ==================================================
                // HINDI TITLE
                // ==================================================
                Text(
                  'नोटिफिकेशन की अनुमति जरूरी है',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // DESCRIPTION
                // ==================================================
                Text(
                  'Aapkakaam आपको जरूरी booking और job request की जानकारी समय पर भेजने के लिए notifications का उपयोग करता है।',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: isDark ? Colors.white60 : Colors.grey[700],
                  ),
                ),

                const SizedBox(height: 28),

                // ==================================================
                // JOB REQUEST CARD
                // ==================================================
                _buildInfoCard(
                  context,
                  icon: Icons.work_rounded,
                  title: 'Job Requests',
                  subtitle: 'नई job और booking request की जानकारी',
                ),

                const SizedBox(height: 12),

                // ==================================================
                // IMPORTANT UPDATE CARD
                // ==================================================
                _buildInfoCard(
                  context,
                  icon: Icons.notifications_active_rounded,
                  title: 'Important Updates',
                  subtitle: 'बुकिंग और काम से जुड़े जरूरी अपडेट',
                ),

                const SizedBox(height: 30),

                // ==================================================
                // ENABLE BUTTON
                // ==================================================
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed:
                        _requesting ? null : _requestNotificationPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child:
                        _requesting
                            ? const SizedBox(
                              width: 23,
                              height: 23,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                            : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_active),
                                SizedBox(width: 10),
                                Text(
                                  'Enable Notifications',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                  ),
                ),

                const SizedBox(height: 12),

                // ==================================================
                // SETTINGS BUTTON
                // ==================================================
                TextButton(
                  onPressed: _requesting ? null : _openNotificationSettings,
                  child: Text(
                    'Open Notification Settings',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ==================================================
                // FOOTER
                // ==================================================
                Text(
                  'आप कभी भी Android Settings से notification permission बदल सकते हैं।',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // INFO CARD
  // ==========================================================

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color:
              isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.grey.withOpacity(0.12),
        ),
      ),

      child: Row(
        children: [
          // ====================================================
          // ICON
          // ====================================================
          Container(
            width: 44,
            height: 44,

            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.10),

              borderRadius: BorderRadius.circular(12),
            ),

            child: Icon(icon, color: theme.colorScheme.primary),
          ),

          const SizedBox(width: 13),

          // ====================================================
          // TEXT
          // ====================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

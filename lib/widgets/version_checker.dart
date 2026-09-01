import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_aapkakaam/data/notifiers.dart';

/// ================================================================
/// SERVER CONTROLLED VERSION + MAINTENANCE CHECKER
/// ================================================================
///
/// Handles:
///
/// 1. App version checking
/// 2. Optional updates
/// 3. Force updates
/// 4. Update analytics
/// 5. Website/server maintenance
/// 6. Full-screen maintenance mode
/// 7. Automatic maintenance recovery
///
/// APIs:
///
/// Version:
/// GET /app-version/check
///
/// Maintenance:
/// GET /website-maintenance/status
///
class VersionChecker extends StatefulWidget {
  final Widget child;

  /// API base URL.
  ///
  /// Example:
  ///
  /// https://api.example.com/api
  ///
  /// IMPORTANT:
  /// apiBaseUrl should already contain /api.
  final String apiBaseUrl;

  /// Version check cooldown.
  final Duration checkCooldown;

  /// Maintenance status refresh interval.
  final Duration maintenanceCheckInterval;

  const VersionChecker({
    super.key,
    required this.child,
    required this.apiBaseUrl,
    this.checkCooldown = const Duration(minutes: 30),
    this.maintenanceCheckInterval = const Duration(minutes: 1),
  });

  @override
  State<VersionChecker> createState() => _VersionCheckerState();
}

class _VersionCheckerState extends State<VersionChecker>
    with WidgetsBindingObserver {
  bool _dialogShowing = false;

  bool _checkingMaintenance = false;

  bool _maintenanceActive = false;

  DateTime? _lastSuccessfulCheck;

  String? _currentVersion;
  String? _currentPlatform;

  MaintenanceData? _maintenanceData;

  Timer? _maintenanceTimer;

  AppLifecycleState? _previousLifecycleState;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChecks();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _maintenanceTimer?.cancel();

    super.dispose();
  }

  /// ================================================================
  /// INITIAL CHECKS
  /// ================================================================

  Future<void> _initializeChecks() async {
    await _checkMaintenance(reason: 'app_start', forceUpdate: true);

    await _checkVersion(reason: 'app_start', ignoreCooldown: true);

    _startMaintenancePolling();
  }

  /// ================================================================
  /// APP LIFECYCLE
  /// ================================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    debugPrint('VersionChecker lifecycle -> $state');

    if (state == AppLifecycleState.resumed) {
      _checkMaintenance(reason: 'app_resume', forceUpdate: true);

      _checkVersion(reason: 'app_resume', ignoreCooldown: false);
    }

    _previousLifecycleState = state;
  }

  /// ================================================================
  /// MAINTENANCE POLLING
  /// ================================================================

  void _startMaintenancePolling() {
    _maintenanceTimer?.cancel();

    _maintenanceTimer = Timer.periodic(widget.maintenanceCheckInterval, (_) {
      _checkMaintenance(reason: 'automatic_poll', forceUpdate: true);
    });
  }

  /// ================================================================
  /// CHECK MAINTENANCE
  /// ================================================================

  Future<void> _checkMaintenance({
    required String reason,
    bool forceUpdate = false,
  }) async {
    if (_checkingMaintenance) {
      debugPrint('Maintenance check skipped: already checking');
      return;
    }

    _checkingMaintenance = true;

    try {
      final baseUrl = _getBaseUrl();

      if (baseUrl.isEmpty) {
        debugPrint('Maintenance check failed: API URL is empty');
        return;
      }

      final uri = Uri.parse('$baseUrl/website-maintenance/status');

      debugPrint('Checking maintenance ($reason): $uri');

      final response = await http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));

      debugPrint('Maintenance status: ${response.statusCode}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return;
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        debugPrint('Maintenance API returned invalid JSON');
        return;
      }

      if (decoded['success'] != true) {
        return;
      }

      final dynamic maintenanceJson = decoded['maintenance'];

      if (maintenanceJson is! Map) {
        debugPrint('Maintenance object missing');
        return;
      }

      final maintenance = MaintenanceData.fromJson(
        Map<String, dynamic>.from(maintenanceJson),
      );

      if (!mounted) {
        return;
      }

      final wasActive = _maintenanceActive;

      setState(() {
        _maintenanceActive = maintenance.active;
        _maintenanceData = maintenance;
      });

      debugPrint('Maintenance active=${maintenance.active}');

      if (wasActive && !maintenance.active) {
        debugPrint('Maintenance finished. Application restored.');
      }

      if (!wasActive && maintenance.active) {
        debugPrint('Maintenance started. Showing maintenance page.');
      }
    } catch (error) {
      debugPrint('Maintenance check failed ($reason): $error');

      /// Fail open.
      ///
      /// Network/API failure must not automatically
      /// lock the user out of the application.
    } finally {
      _checkingMaintenance = false;
    }
  }

  /// ================================================================
  /// VERSION CHECK
  /// ================================================================

  Future<void> _checkVersion({
    required String reason,
    required bool ignoreCooldown,
  }) async {
    if (_dialogShowing) {
      debugPrint('Version check skipped because dialog is showing');
      return;
    }

    if (!ignoreCooldown && _lastSuccessfulCheck != null) {
      final elapsed = DateTime.now().difference(_lastSuccessfulCheck!);

      if (elapsed < widget.checkCooldown) {
        debugPrint(
          'Version check skipped. '
          'Last check ${elapsed.inMinutes} minutes ago.',
        );

        return;
      }
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();

      final platform = Platform.isIOS ? 'ios' : 'android';

      final currentVersion = packageInfo.version.trim();

      _currentVersion = currentVersion;
      _currentPlatform = platform;

      if (currentVersion.isEmpty) {
        debugPrint('Current version is empty');

        return;
      }

      final baseUrl = _getBaseUrl();

      if (baseUrl.isEmpty) {
        return;
      }

      final uri = Uri.parse('$baseUrl/app-version/check').replace(
        queryParameters: {'platform': platform, 'version': currentVersion},
      );

      debugPrint('Checking version: $uri');

      final response = await http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          'Version server returned '
          '${response.statusCode}',
        );

        return;
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        debugPrint('Invalid version API JSON');

        return;
      }

      if (decoded['success'] != true) {
        return;
      }

      _lastSuccessfulCheck = DateTime.now();

      final result = VersionCheckResult.fromJson(decoded);

      if (!mounted) {
        return;
      }

      debugPrint(
        'Version check result: '
        'update=${result.updateAvailable}, '
        'force=${result.forceUpdate}',
      );

      await _handleVersionResult(result);
    } catch (error, stackTrace) {
      debugPrint('VersionChecker failed ($reason): $error');

      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// ================================================================
  /// HANDLE VERSION RESULT
  /// ================================================================

  Future<void> _handleVersionResult(VersionCheckResult result) async {
    if (!mounted || _dialogShowing) {
      return;
    }

    if (!result.updateAvailable) {
      return;
    }

    _dialogShowing = true;

    try {
      await showDialog<void>(
        context: context,

        barrierDismissible: !result.forceUpdate,

        builder: (dialogContext) {
          return PopScope(
            canPop: !result.forceUpdate,
            child: _UpdateDialog(
              result: result,
              onUpdate: () {
                _handleUpdatePressed(result);
              },
            ),
          );
        },
      );
    } finally {
      _dialogShowing = false;
    }
  }

  /// ================================================================
  /// RETRY MAINTENANCE
  /// ================================================================

  Future<void> _retryMaintenance() async {
    await _checkMaintenance(reason: 'manual_retry', forceUpdate: true);
  }

  /// ================================================================
  /// UPDATE CLICK
  /// ================================================================

  Future<void> _handleUpdatePressed(VersionCheckResult result) async {
    await _recordEvent(
      type: 'update_click',
      version: _currentVersion ?? '',
      platform: _currentPlatform ?? '',
    );

    await _openUpdateUrl(result.updateUrl);
  }

  /// ================================================================
  /// RECORD EVENT
  /// ================================================================

  Future<void> _recordEvent({
    required String type,
    required String version,
    required String platform,
  }) async {
    if (version.trim().isEmpty || platform.trim().isEmpty) {
      return;
    }

    try {
      final baseUrl = _getBaseUrl();

      if (baseUrl.isEmpty) {
        return;
      }

      final uri = Uri.parse('$baseUrl/app-version/event');

      await http
          .post(
            uri,
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'platform': platform,
              'version': version,
              'type': type,
            }),
          )
          .timeout(const Duration(seconds: 5));
    } catch (error) {
      debugPrint('Analytics failed: $error');
    }
  }

  /// ================================================================
  /// OPEN UPDATE URL
  /// ================================================================

  Future<void> _openUpdateUrl(String url) async {
    final value = url.trim();

    if (value.isEmpty) {
      _showMessage('Update link is not configured.');

      return;
    }

    final uri = Uri.tryParse(value);

    if (uri == null ||
        !uri.hasScheme ||
        (!uri.isScheme('https') && !uri.isScheme('http'))) {
      _showMessage('Invalid update URL.');

      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened && mounted) {
        _showMessage('Unable to open the update page.');
      }
    } catch (error) {
      debugPrint('Unable to open update URL: $error');

      if (mounted) {
        _showMessage('Unable to open the update page.');
      }
    }
  }

  /// ================================================================
  /// BASE URL
  /// ================================================================

  String _getBaseUrl() {
    return widget.apiBaseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
  }

  /// ================================================================
  /// MESSAGE
  /// ================================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// ================================================================
  /// BUILD
  /// ================================================================

  @override
  Widget build(BuildContext context) {
    /// Maintenance has highest priority.
    if (_maintenanceActive) {
      return _MaintenancePage(
        data: _maintenanceData,
        onRetry: _retryMaintenance,
      );
    }

    return widget.child;
  }
}

/// ================================================================
/// VERSION CHECK RESULT
/// ================================================================

class VersionCheckResult {
  final bool updateAvailable;
  final bool forceUpdate;

  final String latestVersion;
  final String minimumVersion;

  final String updateTitle;
  final String updateMessage;
  final String updateUrl;

  const VersionCheckResult({
    required this.updateAvailable,
    required this.forceUpdate,
    required this.latestVersion,
    required this.minimumVersion,
    required this.updateTitle,
    required this.updateMessage,
    required this.updateUrl,
  });

  factory VersionCheckResult.fromJson(Map<String, dynamic> json) {
    return VersionCheckResult(
      updateAvailable: json['updateAvailable'] == true,

      forceUpdate: json['forceUpdate'] == true,

      latestVersion: json['latestVersion']?.toString().trim() ?? '',

      minimumVersion: json['minimumVersion']?.toString().trim() ?? '',

      updateTitle: _stringOrDefault(json['updateTitle'], 'Update Available'),

      updateMessage: _stringOrDefault(
        json['updateMessage'],
        'A new version of AapkaKaam is available.',
      ),

      updateUrl: json['updateUrl']?.toString().trim() ?? '',
    );
  }

  static String _stringOrDefault(dynamic value, String fallback) {
    final result = value?.toString().trim() ?? '';

    return result.isEmpty ? fallback : result;
  }
}

/// ================================================================
/// MAINTENANCE DATA
/// ================================================================

class MaintenanceData {
  final bool active;

  final String title;
  final String subtitle;
  final String message;

  final String hindiTitle;
  final String hindiSubtitle;
  final String hindiMessage;

  final DateTime? startAt;
  final DateTime? endAt;

  const MaintenanceData({
    required this.active,
    required this.title,
    required this.subtitle,
    required this.message,
    required this.hindiTitle,
    required this.hindiSubtitle,
    required this.hindiMessage,
    this.startAt,
    this.endAt,
  });

  factory MaintenanceData.fromJson(Map<String, dynamic> json) {
    return MaintenanceData(
      active: json['active'] == true,

      title: json['title']?.toString().trim() ?? '',

      subtitle: json['subtitle']?.toString().trim() ?? '',

      message: json['message']?.toString().trim() ?? '',

      hindiTitle: json['hindiTitle']?.toString().trim() ?? '',

      hindiSubtitle: json['hindiSubtitle']?.toString().trim() ?? '',

      hindiMessage: json['hindiMessage']?.toString().trim() ?? '',

      // Backend uses startDateTime
      startAt: _parseDate(json['startDateTime'] ?? json['startAt']),

      // Backend uses endDateTime
      endAt: _parseDate(json['endDateTime'] ?? json['endAt']),
    );
  }
  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString())?.toLocal();
  }
}

/// ================================================================
/// UPDATE DIALOG
/// ================================================================

class _UpdateDialog extends StatelessWidget {
  final VersionCheckResult result;
  final VoidCallback onUpdate;

  const _UpdateDialog({required this.result, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    final primary = theme.colorScheme.primary;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,

      surfaceTintColor: Colors.transparent,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),

      title: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.system_update_rounded, color: primary),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              result.updateTitle,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
            ),
          ),
        ],
      ),

      content: Text(
        result.updateMessage,
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
      ),

      actions: [
        if (!result.forceUpdate)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Later'),
          ),

        FilledButton.icon(
          onPressed: result.updateUrl.isEmpty ? null : onUpdate,
          icon: const Icon(Icons.open_in_new_rounded),
          label: const Text('Update'),
        ),
      ],
    );
  }
}

/// ================================================================
/// FULL SCREEN MAINTENANCE PAGE
/// ================================================================

class _MaintenancePage extends StatefulWidget {
  final MaintenanceData? data;
  final Future<void> Function() onRetry;

  const _MaintenancePage({required this.data, required this.onRetry});

  @override
  State<_MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<_MaintenancePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  bool _retrying = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();

    super.dispose();
  }

  Future<void> _handleRetry() async {
    if (_retrying) {
      return;
    }

    setState(() {
      _retrying = true;
    });

    try {
      await widget.onRetry();
    } finally {
      if (mounted) {
        setState(() {
          _retrying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _backgroundColor(context),

        body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -120,
                right: -100,
                child: _backgroundCircle(context, 300),
              ),

              Positioned(
                bottom: -150,
                left: -120,
                child: _backgroundCircle(context, 340),
              ),

              // Main Content
              Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),

                  padding: const EdgeInsets.fromLTRB(22, 65, 22, 30),

                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),

                    child: ValueListenableBuilder<bool>(
                      valueListenable: isHindiNotifier,

                      builder: (context, isHindi, _) {
                        final title = _getTitle(data, isHindi);
                        final subtitle = _getSubtitle(data, isHindi);
                        final message = _getMessage(data, isHindi);

                        return Column(
                          children: [
                            _buildAnimatedIcon(context),

                            const SizedBox(height: 30),

                            _buildBadge(context, isHindi),

                            const SizedBox(height: 22),

                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: Theme.of(
                                context,
                              ).textTheme.headlineMedium?.copyWith(
                                color: _mainTextColor(context),
                                fontSize: 31,
                                fontWeight: FontWeight.w900,
                              ),
                            ),

                            const SizedBox(height: 12),

                            Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                color: _primaryColor(context),
                                fontWeight: FontWeight.w700,
                                height: 1.4,
                              ),
                            ),

                            const SizedBox(height: 18),

                            Text(
                              message,
                              textAlign: TextAlign.center,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.copyWith(
                                color: _secondaryTextColor(context),
                                height: 1.7,
                              ),
                            ),

                            if (data?.endAt != null) ...[
                              const SizedBox(height: 20),

                              _buildExpectedEndCard(
                                context,
                                isHindi,
                                data!.endAt!,
                              ),
                            ],

                            const SizedBox(height: 30),

                            _buildInformationCard(context, isHindi),

                            const SizedBox(height: 28),

                            _buildRetryButton(context, isHindi),

                            const SizedBox(height: 18),

                            Text(
                              'Aapkakaam',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color: _secondaryTextColor(context),
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              isHindi
                                  ? 'आपके धैर्य के लिए धन्यवाद ❤️'
                                  : 'Thank you for your patience ❤️',
                              textAlign: TextAlign.center,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: _secondaryTextColor(context),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),

              // IMPORTANT: हमेशा सबसे ऊपर होना चाहिए
              Positioned(top: 8, right: 16, child: _languageToggleButton()),
            ],
          ),
        ),
      ),
    );
  }

  /// ================================================================
  /// LANGUAGE
  /// ================================================================

  Widget _languageToggleButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: isHindiNotifier,
      builder: (context, isHindi, _) {
        final primary = _primaryColor(context);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),

            onTap: () {
              debugPrint('Before: ${isHindiNotifier.value}');

              isHindiNotifier.value = !isHindiNotifier.value;

              debugPrint('After: ${isHindiNotifier.value}');
            },

            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color:
                    _isDark(context) ? const Color(0xFF1A1A2E) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: primary.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.language_rounded, size: 18, color: primary),
                  const SizedBox(width: 6),

                  Text(
                    isHindi ? 'हिंदी' : 'English',
                    style: TextStyle(
                      color: _mainTextColor(context),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// ================================================================
  /// TEXT
  /// ================================================================

  String _getTitle(MaintenanceData? data, bool isHindi) {
    if (isHindi) {
      return data?.hindiTitle.trim().isNotEmpty == true
          ? data!.hindiTitle
          : 'हम जल्द वापस आएंगे';
    }

    return data?.title.trim().isNotEmpty == true
        ? data!.title
        : "We'll Be Back Soon";
  }

  String _getSubtitle(MaintenanceData? data, bool isHindi) {
    if (isHindi) {
      return data?.hindiSubtitle.trim().isNotEmpty == true
          ? data!.hindiSubtitle
          : 'हम आपके लिए कुछ बेहतर बना रहे हैं';
    }

    return data?.subtitle.trim().isNotEmpty == true
        ? data!.subtitle
        : 'We are improving something better for you.';
  }

  String _getMessage(MaintenanceData? data, bool isHindi) {
    if (isHindi) {
      return data?.hindiMessage.trim().isNotEmpty == true
          ? data!.hindiMessage
          : 'Aapkakaam पर रखरखाव का काम चल रहा है। कृपया कुछ समय बाद दोबारा प्रयास करें।';
    }

    return data?.message.trim().isNotEmpty == true
        ? data!.message
        : 'Aapkakaam is temporarily unavailable while we perform scheduled maintenance.';
  }

  /// ================================================================
  /// ANIMATED ICON
  /// ================================================================

  Widget _buildAnimatedIcon(BuildContext context) {
    final primary = _primaryColor(context);

    return AnimatedBuilder(
      animation: _animationController,

      builder: (context, child) {
        final value = _animationController.value;

        return Transform.scale(scale: 1 + value * 0.05, child: child);
      },

      child: Container(
        width: 124,
        height: 124,

        decoration: BoxDecoration(
          shape: BoxShape.circle,

          color: primary.withOpacity(0.10),

          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.14),
              blurRadius: 40,
              spreadRadius: 8,
            ),
          ],
        ),

        child: Center(
          child: Container(
            width: 84,
            height: 84,

            decoration: BoxDecoration(shape: BoxShape.circle, color: primary),

            child: const Icon(
              Icons.construction_rounded,
              color: Colors.white,
              size: 43,
            ),
          ),
        ),
      ),
    );
  }

  /// ================================================================
  /// BADGE
  /// ================================================================

  Widget _buildBadge(BuildContext context, bool isHindi) {
    final primary = _primaryColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),

      decoration: BoxDecoration(
        color: primary.withOpacity(0.10),

        borderRadius: BorderRadius.circular(50),

        border: Border.all(color: primary.withOpacity(0.25)),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Container(
            width: 8,
            height: 8,

            decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
          ),

          const SizedBox(width: 10),

          Text(
            isHindi ? 'रखरखाव' : 'MAINTENANCE',

            style: TextStyle(
              color: primary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: isHindi ? 0 : 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// ================================================================
  /// EXPECTED END
  /// ================================================================

  Widget _buildExpectedEndCard(
    BuildContext context,
    bool isHindi,
    DateTime endAt,
  ) {
    final primary = _primaryColor(context);

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: primary.withOpacity(0.08),

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: primary.withOpacity(0.18)),
      ),

      child: Row(
        children: [
          Icon(Icons.schedule_rounded, color: primary),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  isHindi ? 'अनुमानित समाप्ति समय' : 'Expected completion',

                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 4),

                Text(
                  _formatDateTime(endAt),

                  style: TextStyle(color: _secondaryTextColor(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final date = value.toLocal();

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;

    final minute = date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '$hour:$minute $period';
  }

  /// ================================================================
  /// INFORMATION CARD
  /// ================================================================

  Widget _buildInformationCard(BuildContext context, bool isHindi) {
    final isDark = _isDark(context);

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151B2E) : Colors.white,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFE7EAF0),
        ),
      ),

      child: Column(
        children: [
          _MaintenanceInfoRow(
            icon: Icons.system_update_alt_rounded,

            title: isHindi ? 'सिस्टम में सुधार' : 'System Improvement',

            subtitle:
                isHindi
                    ? 'हम अपनी सेवाओं को बेहतर बना रहे हैं'
                    : 'We are improving our services',

            color: _primaryColor(context),
          ),

          const SizedBox(height: 20),

          _MaintenanceInfoRow(
            icon: Icons.security_rounded,

            title: isHindi ? 'आपका डेटा सुरक्षित है' : 'Your Data is Safe',

            subtitle:
                isHindi
                    ? 'आपका खाता और डेटा सुरक्षित है'
                    : 'Your account and data remain secure',

            color: _primaryColor(context),
          ),

          const SizedBox(height: 20),

          _MaintenanceInfoRow(
            icon: Icons.access_time_rounded,

            title:
                isHindi ? 'सेवा जल्द उपलब्ध होगी' : 'Service Will Be Back Soon',

            subtitle:
                isHindi
                    ? 'कृपया कुछ समय बाद दोबारा जांचें'
                    : 'Please check again in a little while',

            color: _primaryColor(context),
          ),
        ],
      ),
    );
  }

  /// ================================================================
  /// RETRY BUTTON
  /// ================================================================

  Widget _buildRetryButton(BuildContext context, bool isHindi) {
    final primary = _primaryColor(context);

    return SizedBox(
      width: double.infinity,

      child: FilledButton.icon(
        onPressed: _retrying ? null : _handleRetry,

        style: FilledButton.styleFrom(
          padding: const EdgeInsets.all(16),

          backgroundColor: primary,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),

        icon:
            _retrying
                ? const SizedBox(
                  width: 20,
                  height: 20,

                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
                : const Icon(Icons.refresh_rounded),

        label: Text(
          _retrying
              ? (isHindi ? 'जांच रहे हैं...' : 'Checking...')
              : (isHindi ? 'दोबारा प्रयास करें' : 'Try Again'),
        ),
      ),
    );
  }

  /// ================================================================
  /// BACKGROUND
  /// ================================================================

  Widget _backgroundCircle(BuildContext context, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,

        decoration: BoxDecoration(
          shape: BoxShape.circle,

          color: _primaryColor(
            context,
          ).withOpacity(_isDark(context) ? 0.10 : 0.06),
        ),
      ),
    );
  }

  bool _isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  Color _primaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  Color _backgroundColor(BuildContext context) {
    return _isDark(context) ? const Color(0xFF0B1020) : const Color(0xFFF7F9FC);
  }

  Color _mainTextColor(BuildContext context) {
    return _isDark(context) ? Colors.white : const Color(0xFF111827);
  }

  Color _secondaryTextColor(BuildContext context) {
    return _isDark(context) ? Colors.white70 : const Color(0xFF64748B);
  }
}

/// ================================================================
/// MAINTENANCE INFORMATION ROW
/// ================================================================

class _MaintenanceInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _MaintenanceInfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Container(
          width: 48,
          height: 48,

          decoration: BoxDecoration(
            color: color.withOpacity(0.10),

            borderRadius: BorderRadius.circular(14),
          ),

          child: Icon(icon, color: color, size: 24),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,

                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,

                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),

                  height: 1.5,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

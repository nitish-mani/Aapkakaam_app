import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Displays the active Home Banner configured from the Aapkakaam admin panel.
///
/// Expected public API response:
/// {
///   "success": true,
///   "banner": {
///     "imageUrl": "https://...",
///     "clickUrl": "https://...",
///     "enabled": true
///   }
/// }
///
/// [apiBaseUrl] must include `/api`, e.g. `https://YOUR_API_HOST/api`.
/// Reuse the same API base URL that is passed to VersionChecker in main.dart.
class HomeBanner extends StatefulWidget {
  final String apiBaseUrl;

  const HomeBanner({super.key, required this.apiBaseUrl});

  @override
  State<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<HomeBanner> with WidgetsBindingObserver {
  Map<String, dynamic>? _banner;
  bool _imageFailed = false;
  bool _requestInProgress = false;
  DateTime? _lastSuccessfulFetch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchBanner();
  }

  @override
  void didUpdateWidget(covariant HomeBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.apiBaseUrl != widget.apiBaseUrl) {
      _fetchBanner(force: true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final lastFetch = _lastSuccessfulFetch;
      if (lastFetch == null ||
          DateTime.now().difference(lastFetch) >= const Duration(minutes: 5)) {
        _fetchBanner();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _fetchBanner({bool force = false}) async {
    if (_requestInProgress) return;

    final lastFetch = _lastSuccessfulFetch;
    if (!force &&
        lastFetch != null &&
        DateTime.now().difference(lastFetch) < const Duration(minutes: 5)) {
      return;
    }

    final baseUrl = widget.apiBaseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    if (baseUrl.isEmpty) {
      debugPrint('HomeBanner: API base URL is empty.');
      return;
    }

    _requestInProgress = true;

    try {
      // apiBaseUrl already contains /api; do not add /api again.
      final uri = Uri.parse('$baseUrl/home-banner');

      final response = await http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('HomeBanner: GET $uri returned ${response.statusCode}.');
        return;
      }

      final dynamic decoded = jsonDecode(response.body);
      print('HomeBanner: API response: $decoded');
      if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
        debugPrint('HomeBanner: invalid API response.');
        return;
      }

      final dynamic rawbanner = decoded['banner'];
      if (rawbanner is! Map) {
        debugPrint('HomeBanner: response.banner is missing.');
        return;
      }

      final banner = Map<String, dynamic>.from(rawbanner);
      final imageUrl = banner['imageUrl']?.toString().trim() ?? '';
      final enabled = banner['enabled'] == true;

      if (!enabled || !_isHttpUrl(imageUrl)) {
        if (!mounted) return;
        setState(() {
          _banner = null;
          _imageFailed = false;
          _lastSuccessfulFetch = DateTime.now();
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _banner = banner;
        _imageFailed = false;
        _lastSuccessfulFetch = DateTime.now();
      });
    } catch (error, stackTrace) {
      // Fail open: a banner failure must never block the home screen.
      debugPrint('HomeBanner: fetch failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _requestInProgress = false;
    }
  }

  bool _isHttpUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
  }

  Future<void> _openClickUrl() async {
    final value = _banner?['clickUrl']?.toString().trim() ?? '';
    if (value.isEmpty || !_isHttpUrl(value)) return;

    final uri = Uri.tryParse(value);
    if (uri == null) return;

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open this link.')),
        );
      }
    } catch (error) {
      debugPrint('HomeBanner: unable to open click URL: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    final imageUrl = banner?['imageUrl']?.toString().trim() ?? '';

    if (banner == null || imageUrl.isEmpty || _imageFailed) {
      return const SizedBox.shrink();
    }

    final clickUrl = banner['clickUrl']?.toString().trim() ?? '';
    final isClickable = _isHttpUrl(clickUrl);

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: AspectRatio(
        aspectRatio: 16 / 6,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          // Image.network uses Flutter's image cache. Keep the UI responsive
          // while a remote banner downloads.
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            final expected = progress.expectedTotalBytes;
            final value =
                expected == null
                    ? null
                    : progress.cumulativeBytesLoaded / expected;
            return Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              alignment: Alignment.center,
              child: SizedBox(
                width: 26.w,
                height: 26.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  value: value,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint('HomeBanner: image failed to load: $error');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_imageFailed) {
                setState(() => _imageFailed = true);
              }
            });
            return Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              alignment: Alignment.center,
              child: const Icon(Icons.image_not_supported_outlined),
            );
          },
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        clipBehavior: Clip.antiAlias,
        child:
            isClickable ? InkWell(onTap: _openClickUrl, child: image) : image,
      ),
    );
  }
}

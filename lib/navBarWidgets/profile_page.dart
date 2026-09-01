// this file is made responsive for all devices and screen sizes.

import 'dart:io';
import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/models/data_model.dart';
import 'package:app_aapkakaam/widgets/address_page.dart';
import 'package:app_aapkakaam/widgets/create_booking.dart';
import 'package:app_aapkakaam/widgets/payment_page.dart';
import 'package:app_aapkakaam/widgets/view_share.dart';
import 'package:app_aapkakaam/widgets/earnings.dart';
import 'package:app_aapkakaam/widgets/concern.dart';
import 'package:app_aapkakaam/widgets/leave_management.dart';
import 'package:app_aapkakaam/widgets/wage_rate_page.dart';
import 'package:app_aapkakaam/widgets/welcome_page.dart';
import 'package:flutter/material.dart';

// Hindi/Devanagari text is supported. For best rendering, add a font such as Noto Sans Devanagari to pubspec.yaml.
// ignore: depend_on_referenced_packages
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with WidgetsBindingObserver {
  // Global language helper:
  // true = Hindi, false = English.
  String _t(String english, String hindi) {
    return isHindiNotifier.value ? hindi : english;
  }

  UserModel? user;
  VendorModel? vendor;
  bool _isLoading = true;
  bool _isLoading1 = false;
  bool _isRefreshing = false;

  // Job emojis for display
  final Map<String, String> _jobEmojis = {
    'labour': '🔧',
    'mason': '🧱',
    'electrician': '⚡',
    'plumber': '🔧',
    'carpenter': '🪚',
    'painter': '🎨',
    'cleaner': '🧹',
    'driver': '🚗',
    'cook': '🍳',
    'gardener': '🌿',
    'mechanic': '🔩',
    'welder': '🔥',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  Future<void> _loadData() async {
    try {
      if (isVendor.value) {
        await getVendorData();
      } else {
        await getUserData();
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> downloadAndSaveImage(String imageUrl, String fileName) async {
    if (imageUrl.isEmpty) return;

    try {
      // 1. Download image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) throw Exception('Image download failed');

      // 2. Get app directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';

      // 3. Delete previous image if it exists
      if (savedImagePath.value.isNotEmpty) {
        final oldFile = File(savedImagePath.value);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      }

      // 4. Save new image
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // 5. Update path (only if file exists)
      if (await file.exists()) {
        savedImagePath.value = filePath;
      }
    } catch (e) {
      debugPrint('Failed to save image: $e');
    }
  }

  Future<void> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString("user");

    if (userData != null && mounted) {
      try {
        setState(() {
          user = UserModel.fromJson(jsonDecode(userData));
        });

        if (user?.imgURL != null && user!.imgURL!.isNotEmpty) {
          await downloadAndSaveImage(
            user!.imgURL!,
            'user_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
        }
      } catch (e) {
        debugPrint('Error parsing user data: $e');
      }
    }
  }

  Future<void> getVendorData() async {
    final prefs = await SharedPreferences.getInstance();
    final vendorData = prefs.getString("vendor");
    // print(vendorData);
    if (vendorData != null && mounted) {
      try {
        setState(() {
          vendor = VendorModel.fromJson(jsonDecode(vendorData));
        });

        if (vendor?.imgURL != null && vendor!.imgURL!.isNotEmpty) {
          await downloadAndSaveImage(
            vendor!.imgURL!,
            'vendor_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
        }
      } catch (e) {
        debugPrint('Error parsing vendor data: $e');
      }
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing || !mounted) return;

    setState(() {
      _isRefreshing = true;
    });
    await _loadData();
  }

  // Listen to profile refresh notifier
  void _listenToRefreshNotifier() {
    if (mounted && profileRefreshNotifier.value == true) {
      profileRefreshNotifier.value = false;
      _refreshData();
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading1 = true;
    });

    final prefs = await SharedPreferences.getInstance();

    try {
      final isVendor1 = isVendor.value;
      final category = isVendor1 ? 'vendor' : 'user';
      final categoryData = prefs.getString(category);

      if (categoryData == null) {
        print("categoryData is null — aborting logout");
        setState(() {
          _isLoading1 = false;
        });
        if (mounted) {
          print("No user data found. Please login again.");
        }
        return;
      }

      final decoded = jsonDecode(categoryData);
      final url = Uri.parse("${KConstantURL.url}/$category/edit/fcmToken");

      final body = {
        'fcmToken': "",
        if (category == "user") "userId": decoded['userId'],
        if (category == "vendor") "vendorId": decoded['vendorId'],
      };

      final response = await http
          .patch(
            url,
            headers: {
              "Authorization": 'Bearer ${decoded['token']}',
              "Content-Type": "application/json",
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      await prefs.clear();
      selectedPageNotifier.value = 0;

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading1 = false;
      });

      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) => WelcomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fade = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            );
            return FadeTransition(opacity: fade, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
        (route) => false,
      );
    } catch (e) {
      setState(() {
        _isLoading1 = false;
      });
      if (mounted) {
        print("Logout failed: $e");
      }
    }
  }

  // Helper method to navigate with refresh callback
  Future<void> _navigateAndRefresh(Widget page) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
    // Refresh when coming back from any page
    if (mounted) {
      await _refreshData();
    }
  }

  // ============================================================
  // WAGE RATE DISPLAY HELPERS
  // ============================================================

  String getJobEmoji(String job) {
    return _jobEmojis[job.toLowerCase()] ?? '📌';
  }

  String getJobDisplay(String job) {
    // You can add more job display names here
    final displayNames = {
      'labour': 'Labour',
      'mason': 'Mason',
      'electrician': 'Electrician',
      'plumber': 'Plumber',
      'carpenter': 'Carpenter',
      'painter': 'Painter',
      'cleaner': 'Cleaner',
      'driver': 'Driver',
      'cook': 'Cook',
      'gardener': 'Gardener',
      'mechanic': 'Mechanic',
      'welder': 'Welder',
    };
    return displayNames[job.toLowerCase()] ?? job;
  }

  /// Get wage rate for a specific job by name
  double? _getWageRateForJob(String job) {
    if (vendor == null) return null;
    final jobs = vendor!.type;
    final index = jobs.indexWhere(
      (item) => item.toLowerCase() == job.toLowerCase(),
    );
    if (index >= 0 && index < vendor!.wageRate.length) {
      return vendor!.wageRate[index];
    }
    return null;
  }

  /// Get wage rate type for a specific job by name
  String _getWageRateTypeForJob(String job) {
    if (vendor == null) return '';
    final jobs = vendor!.type;
    final index = jobs.indexWhere(
      (item) => item.toLowerCase() == job.toLowerCase(),
    );
    if (index >= 0 && index < vendor!.wageRateType.length) {
      return vendor!.wageRateType[index];
    }
    return '';
  }

  /// Check if a job has a wage rate set
  bool _hasWageRateForJob(String job) {
    final rate = _getWageRateForJob(job);
    return rate != null && rate > 0;
  }

  /// Get all jobs with their rates for display
  List<Map<String, dynamic>> _getJobsWithRates() {
    if (vendor == null) return [];
    final result = <Map<String, dynamic>>[];
    final jobs = vendor!.type;
    final rates = vendor!.wageRate;
    final types = vendor!.wageRateType;

    for (int i = 0; i < jobs.length; i++) {
      final job = jobs[i];
      final rate = i < rates.length ? rates[i] : null;
      final type = i < types.length ? types[i] : '';
      result.add({'job': job, 'rate': rate, 'rateType': type});
    }
    return result;
  }

  /// Get formatted wage display for a job
  String _getFormattedWageDisplay(String job) {
    final rate = _getWageRateForJob(job);
    final type = _getWageRateTypeForJob(job);

    if (rate == null || rate <= 0) {
      return _t('Not set', 'निर्धारित नहीं');
    }
    if (type.isEmpty) {
      return '₹${rate.toStringAsFixed(0)}';
    }
    return '₹${rate.toStringAsFixed(0)} / $type';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // Listen to profile refresh notifier
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToRefreshNotifier();
    });

    return ValueListenableBuilder<bool>(
      valueListenable: isHindiNotifier,
      builder: (context, isHindi, _) {
        return ValueListenableBuilder(
          valueListenable: isDarkThemeNotifier,
          builder: (context, isDarkTheme, _) {
            return ValueListenableBuilder(
              valueListenable: isVendor,
              builder: (context, isVendorValue, _) {
                return ValueListenableBuilder(
                  valueListenable: isLoggedIn,
                  builder: (context, loggedIn, _) {
                    final theme = Theme.of(context);
                    final scheme = theme.colorScheme;

                    if (_isLoading) {
                      return _buildLoadingState(isDarkTheme, scheme);
                    }

                    return RefreshIndicator(
                      color: scheme.primary,
                      onRefresh: _refreshData,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  _buildHeroHeader(
                                    isDarkTheme,
                                    isVendorValue,
                                    scheme,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoCard(
                                    isDarkTheme,
                                    isVendorValue,
                                    scheme,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildActionSection(
                                    isDarkTheme,
                                    isVendorValue,
                                    loggedIn,
                                    scheme,
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingState(bool isDarkTheme, ColorScheme scheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(19),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: scheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _t("Loading profile…", "प्रोफ़ाइल लोड हो रही है…"),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDarkTheme ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(
    bool isDarkTheme,
    bool isVendorValue,
    ColorScheme scheme,
  ) {
    final name = isVendorValue ? vendor?.name : user?.name;
    final professions =
        isVendorValue ? (vendor?.type ?? <String>[]) : <String>[];
    final rating = vendor?.rating;
    final count = vendor?.ratingCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDarkTheme
                  ? [
                    scheme.primary.withOpacity(.28),
                    scheme.surfaceContainerHighest,
                  ]
                  : [scheme.primary, scheme.primary.withOpacity(.72)],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withOpacity(.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: savedImagePath.value.isEmpty ? null : _showProfileImage,
                child: Container(
                  width: 116,
                  height: 116,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundColor: scheme.primary.withOpacity(.12),
                    backgroundImage:
                        savedImagePath.value.isNotEmpty
                            ? FileImage(File(savedImagePath.value))
                            : null,
                    child:
                        savedImagePath.value.isEmpty
                            ? Icon(
                              isVendorValue
                                  ? Icons.person_rounded
                                  : Icons.person_rounded,
                              size: 54,
                              color: scheme.primary,
                            )
                            : null,
                  ),
                ),
              ),
              Positioned(
                right: -4,
                bottom: 2,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          isDarkTheme
                              ? scheme.surfaceContainerHighest
                              : Colors.white,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    isVendorValue
                        ? Icons.verified_rounded
                        : Icons.person_rounded,
                    size: 16,
                    color: scheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            capitalizeWords(name),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDarkTheme ? Colors.white : Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              letterSpacing: -.4,
            ),
          ),
          const SizedBox(height: 7),
          if (isVendorValue && professions.isNotEmpty)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 7,
              runSpacing: 7,
              children:
                  professions
                      .take(VendorModel.maxJobs)
                      .map(
                        (job) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.16),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(.20),
                            ),
                          ),
                          child: Text(
                            '🛠️ ${capitalizeWords(job)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.16),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(.20)),
              ),
              child: const Text(
                '👤 User',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (isVendorValue) ...[
            const SizedBox(height: 14),
            _buildRatingPill(scheme, rating, count),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingPill(ColorScheme scheme, double? rating, int? count) {
    final safeRating = rating ?? 0.0;
    final safeCount = count ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.16),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
          const SizedBox(width: 5),
          Text(
            safeRating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            _t('($safeCount reviews)', '($safeCount रिव्यू)'),
            style: TextStyle(
              color: Colors.white.withOpacity(.78),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    bool isDarkTheme,
    bool isVendorValue,
    ColorScheme scheme,
  ) {
    final balance =
        isVendorValue
            ? (vendor?.balance ?? 0).toStringAsFixed(2)
            : (user?.balance ?? 0).toStringAsFixed(2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
            isDarkTheme
                ? scheme.surfaceContainerHighest.withOpacity(.65)
                : scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outline.withOpacity(.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkTheme ? .12 : .05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            _t("Profile details", "प्रोफ़ाइल विवरण"),
            Icons.person_outline_rounded,
            scheme,
          ),
          const SizedBox(height: 12),
          _infoTile(
            _t("Name", "नाम"),
            capitalizeWords(isVendorValue ? vendor?.name : user?.name),
            Icons.badge_outlined,
            scheme,
          ),
          _infoTile(
            _t("Mobile", "मोबाइल"),
            isVendorValue
                ? vendor?.phoneNo.toString()
                : user?.phoneNo.toString(),
            Icons.phone_outlined,
            scheme,
          ),
          // ============================================================
          // WAGE RATE DISPLAY - WITH MULTI-JOB SUPPORT
          // ============================================================
          if (isVendorValue) _buildWageRateDisplay(scheme),
          _infoTile(
            _t("Balance", "बैलेंस"),
            '₹ $balance',
            Icons.account_balance_wallet_outlined,
            scheme,
            valueAccent: true,
          ),
          const SizedBox(height: 5),
          _buildAddressCard(isDarkTheme, isVendorValue, scheme),
        ],
      ),
    );
  }

  // ============================================================
  // WAGE RATE DISPLAY WIDGET
  // ============================================================

  Widget _buildWageRateDisplay(ColorScheme scheme) {
    final jobsWithRates = _getJobsWithRates();
    final hasRates = jobsWithRates.any((item) => item['rate'] != null);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(.06),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: scheme.primary.withOpacity(.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Row(
            children: [
              Icon(
                Icons.currency_rupee_rounded,
                size: 20,
                color: scheme.primary,
              ),
              const SizedBox(width: 11),
              Text(
                _t("Service Charge", "सेवा शुल्क"),
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (hasRates) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${jobsWithRates.where((item) => item['rate'] != null).length} set',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Display all jobs with their rates
          if (jobsWithRates.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _t(
                  "No jobs added. Please add jobs first.",
                  "कोई काम नहीं जोड़ा गया। कृपया पहले काम जोड़ें।",
                ),
                style: TextStyle(
                  color: scheme.onSurface.withOpacity(.60),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            ...jobsWithRates.map((item) {
              final job = item['job'] as String;
              final rate = item['rate'] as double?;
              final type = item['rateType'] as String;

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: scheme.onSurface.withOpacity(.035),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(
                      getJobEmoji(job),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        capitalizeWords(getJobDisplay(job)),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    if (rate != null && rate > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary.withOpacity(.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹${rate.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                              ),
                            ),
                            if (type.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Text(
                                '/ $type',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: scheme.onSurface.withOpacity(.60),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _t("Not set", "निर्धारित नहीं"),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: scheme.onSurface.withOpacity(.45),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),

          // Show "Set Wage Rate" hint if no rates are set
          if (!hasRates && jobsWithRates.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(.20)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _t(
                        'Tap "Update Service Charge" below to add rates for your jobs.',
                        'नीचे "सेवा शुल्क अपडेट करें " पर टैप करें अपने कामों के दरें जोड़ने के लिए।',
                      ),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon, ColorScheme scheme) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: scheme.primary, size: 21),
        ),
        const SizedBox(width: 11),
        Text(
          title,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -.2,
          ),
        ),
      ],
    );
  }

  Widget _infoTile(
    String label,
    String? value,
    IconData icon,
    ColorScheme scheme, {
    bool valueAccent = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: scheme.onSurface.withOpacity(.035),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: scheme.onSurface.withOpacity(.58),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value?.isNotEmpty == true ? value! : 'N/A',
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueAccent ? scheme.primary : scheme.onSurface,
                fontSize: 14,
                fontWeight: valueAccent ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(
    bool isDarkTheme,
    bool isVendorValue,
    ColorScheme scheme,
  ) {
    final village =
        isVendorValue
            ? _safeGetAddress(vendor?.address, 'vill')
            : _safeGetAddress(user?.address, 'vill');
    final post =
        isVendorValue
            ? _safeGetAddress(vendor?.address, 'post')
            : _safeGetAddress(user?.address, 'post');
    final district =
        isVendorValue
            ? _safeGetAddress(vendor?.address, 'dist')
            : _safeGetAddress(user?.address, 'dist');
    final state =
        isVendorValue
            ? _safeGetAddress(vendor?.address, 'state')
            : _safeGetAddress(user?.address, 'state');
    final pincode =
        isVendorValue
            ? _safeGetAddress(vendor?.address, 'pincode')
            : _safeGetAddress(user?.address, 'pincode');

    final parts =
        [
          village,
          post,
          district,
          state,
        ].where((e) => e.isNotEmpty && e != 'N/A').toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.primary.withOpacity(.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(.11),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.location_on_outlined, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t("Address", "पता"),
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  parts.isEmpty
                      ? _t("Address not added", "पता नहीं जोड़ा गया है")
                      : parts.join(', '),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurface.withOpacity(.68),
                    height: 1.35,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (pincode != 'N/A') ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'PIN $pincode',
                      style: TextStyle(
                        color: scheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection(
    bool isDarkTheme,
    bool isVendorValue,
    bool loggedIn,
    ColorScheme scheme,
  ) {
    final actions = <Widget>[
      _modernAction(
        _t("View Sharing", "शेयरिंग देखें"),
        _t(
          "Manage profile visibility & sharing",
          "प्रोफ़ाइल शेयरिंग प्रबंधित करें",
        ),
        Icons.share_outlined,
        scheme,
        () => _navigateAndRefresh(const ViewShare()),
      ),
      _modernAction(
        _t("Earnings", "कमाई"),
        _t("View your earnings and transactions", "अपनी कमाई और लेन-देन देखें"),
        Icons.trending_up_rounded,
        scheme,
        () => _navigateAndRefresh(const EarningsPage()),
      ),
      if (isVendorValue)
        _modernAction(
          _t("Create Booking", "बुकिंग बनाएं"),
          _t("Create a new customer booking", "नई ग्राहक बुकिंग बनाएं"),
          Icons.calendar_month_rounded,
          scheme,
          () => _navigateAndRefresh(const CreateBooking()),
        ),
      if (isVendorValue)
        _modernAction(
          _t("Update Service Charge", "सेवा शुल्क अपडेट करें"),
          _t(
            "Update your service charge for each job",
            "प्रत्येक काम के लिए अपनी सेवा शुल्क अपडेट करें",
          ),
          Icons.currency_rupee_rounded,
          scheme,
          _showWageRateDialog,
        ),
      if (isVendorValue)
        _modernAction(
          _t("Leave Management", "छुट्टी प्रबंधन "),
          _t(
            "Manage your leave and availability",
            "अपनी छुट्टी और उपलब्धता प्रबंधित करें",
          ),
          Icons.event_busy_outlined,
          scheme,
          () => _navigateAndRefresh(const LeaveManagementPage()),
        ),
      _modernAction(
        _t('Add / Update Address', "पता बदलें"),
        _t("Keep your service location updated", "अपना सेवा पता अपडेट रखें"),
        Icons.location_on_outlined,
        scheme,
        _showAddressDialog,
      ),
      _modernAction(
        _t("Add Balance", "बैलेंस जोड़ें"),
        _t("Add money to your account", "अपने खाते में बैलेंस जोड़ें"),
        Icons.account_balance_wallet_outlined,
        scheme,
        () => _navigateAndRefresh(const PaymentPage()),
      ),
      _modernAction(
        _t("Raise Concern", "समस्या बताएं"),
        _t(
          "Tell us if something needs attention",
          "किसी समस्या के बारे में हमें बताएं",
        ),
        Icons.support_agent_rounded,
        scheme,
        () => _navigateAndRefresh(const ConcernsPage()),
      ),
      _modernAction(
        _t("Logout", "लॉगआउट"),
        _t("Sign out from this device", "इस डिवाइस से लॉगआउट करें"),
        Icons.logout_rounded,
        scheme,
        _logout,
        destructive: true,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
            isDarkTheme
                ? scheme.surfaceContainerHighest.withOpacity(.55)
                : scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outline.withOpacity(.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            _t("Quick actions", "त्वरित कार्य"),
            Icons.grid_view_rounded,
            scheme,
          ),
          const SizedBox(height: 14),
          ...actions,
        ],
      ),
    );
  }

  Widget _modernAction(
    String title,
    String subtitle,
    IconData icon,
    ColorScheme scheme,
    VoidCallback onTap, {
    bool destructive = false,
  }) {
    final color = destructive ? scheme.error : scheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: color.withOpacity(.055),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(.09)),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withOpacity(.11),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 23),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurface.withOpacity(.52),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: scheme.onSurface.withOpacity(.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProfileImage() {
    if (savedImagePath.value.isEmpty) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(.78),
      builder:
          (_) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: InteractiveViewer(
                    minScale: .8,
                    maxScale: 4,
                    child: Image.file(
                      File(savedImagePath.value),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton.filled(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _showWageRateDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => const WageRatePage(),
    );

    if (result == true) {
      await _refreshData();
    }
  }

  Future<void> _showAddressDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => const AddAddressDialog(),
    );

    if (result == true) {
      await _refreshData();
    }
  }

  String _safeGetAddress(List<Address>? addresses, String field) {
    if (addresses == null || addresses.isEmpty) return 'N/A';

    final address = addresses[0];
    switch (field) {
      case 'vill':
        return address.vill;
      case 'post':
        return address.post;
      case 'dist':
        return address.dist;
      case 'state':
        return address.state;
      case 'pincode':
        return address.pincode;
      default:
        return 'N/A';
    }
  }

  String capitalizeWords(String? input) {
    if (input == null) return '';
    return input
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '',
        )
        .join(' ');
  }

  void updateVendorAddress(
    VendorModel vendor,
    Map<String, dynamic> responseJson,
  ) async {
    List<Address> updatedAddress =
        (responseJson['address'] as List)
            .map((e) => Address.fromJson(e))
            .toList();

    VendorModel updatedVendor = VendorModel(
      token: vendor.token,
      vendorId: vendor.vendorId,
      name: vendor.name,
      email: vendor.email,
      verifyEmail: vendor.verifyEmail,
      phoneNo: vendor.phoneNo,
      verifyPhoneNo: vendor.verifyPhoneNo,
      type: vendor.type,
      gender: vendor.gender,
      rating: vendor.rating,
      ratingCount: vendor.ratingCount,
      wageRate: vendor.wageRate,
      address: updatedAddress,
      balance: vendor.balance,
      wageRateType: vendor.wageRateType,
      commission: vendor.commission,
      transactionCount: vendor.transactionCount,
      totalDiscount: vendor.totalDiscount,
      totalOriginalAmount: vendor.totalOriginalAmount,
      imgURL: vendor.imgURL,
      pending: vendor.pending,
      completed: vendor.completed,
      canceled: vendor.canceled,
      earning: vendor.earning,
      pincode: vendor.pincode,
      fcmToken: vendor.fcmToken,
      shareCount: vendor.shareCount,
      experience: vendor.experience,
      message: responseJson['message'] ?? vendor.message,
    );

    final prefs = await SharedPreferences.getInstance();
    prefs.setString('vendor', jsonEncode(updatedVendor.toJson()));
  }

  void updateUserAddress(
    UserModel user,
    Map<String, dynamic> responseJson,
  ) async {
    List<Address> updatedAddress =
        (responseJson['address'] as List)
            .map((e) => Address.fromJson(e))
            .toList();

    UserModel updatedUser = UserModel(
      token: user.token,
      userId: user.userId,
      name: user.name,
      email: user.email,
      verifyEmail: user.verifyEmail,
      phoneNo: user.phoneNo,
      verifyPhoneNo: user.verifyPhoneNo,
      gender: user.gender,
      address: updatedAddress,
      balance: user.balance,
      imgURL: user.imgURL,
      message: responseJson['message'] ?? user.message,
    );

    final prefs = await SharedPreferences.getInstance();
    prefs.setString('user', jsonEncode(updatedUser.toJson()));
  }
}

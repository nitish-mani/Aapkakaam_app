// this file is made responsive with custom "Other" option support and full Hindi translation.
// Supports multiple jobs with corresponding wage rates and rate types

import 'dart:convert';
import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WageRatePage extends StatefulWidget {
  const WageRatePage({super.key});

  static String t(String en, String hi) {
    return isHindiNotifier.value ? hi : en;
  }

  @override
  State<WageRatePage> createState() => _WageRatePageState();
}

class _WageRatePageState extends State<WageRatePage> {
  String _t(String en, String hi) => WageRatePage.t(en, hi);

  // ============================================================
  // STATE VARIABLES
  // ============================================================

  // Selected job for editing
  String? _selectedJobForWage;

  // Current wage rate value
  final TextEditingController _wageRateController = TextEditingController();

  // Selected rate type
  String? _selectedWageRateType;

  // Custom rate type input
  final TextEditingController _customRateTypeController =
      TextEditingController();

  // Show custom input field
  bool _showCustomInput = false;

  // Loading state
  bool _isLoading = false;

  // User data
  Map<String, dynamic>? _userData;

  // ============================================================
  // CONSTANTS
  // ============================================================

  // Rate types with translations
  final List<Map<String, String>> _rateTypes = const [
    {'en': 'Day', 'hi': 'दिन'},
    {'en': 'Hour', 'hi': 'घंटा'},
    {'en': 'Km', 'hi': 'किलोमीटर'},
    {'en': '1k People', 'hi': '1 हजार लोग'},
    {'en': 'Service', 'hi': 'सेवा'},
    {'en': 'Other', 'hi': 'अन्य'},
  ];

  // Rate type icons
  final Map<String, IconData> _rateTypeIcons = {
    'Day': Icons.calendar_today_rounded,
    'Hour': Icons.access_time_rounded,
    'Km': Icons.directions_car_rounded,
    '1k People': Icons.people_alt_outlined,
    'Service': Icons.build_circle_outlined,
    'Other': Icons.more_horiz_rounded,
  };

  // Job emojis
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

  // Job display names
  final Map<String, String> _jobDisplayNames = {
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

  // ============================================================
  // HELPERS
  // ============================================================

  String getJobEmoji(String job) {
    return _jobEmojis[job.toLowerCase()] ?? '📌';
  }

  String getJobDisplay(String job) {
    final display = _jobDisplayNames[job.toLowerCase()];
    return display ?? job;
  }

  String _getRateTypeDisplay(String value) {
    final found = _rateTypes.firstWhere(
      (item) => item['en'] == value,
      orElse: () => {'en': value, 'hi': value},
    );
    return isHindiNotifier.value ? found['hi']! : found['en']!;
  }

  // Get the final rate type value
  String _getFinalRateType() {
    if (_selectedWageRateType == 'Other') {
      final customValue = _customRateTypeController.text.trim();
      return customValue.isNotEmpty ? customValue : 'Other';
    }
    return _selectedWageRateType ?? '';
  }

  String _getFinalRateTypeDisplay() {
    final value = _getFinalRateType();
    if (value == 'Other') {
      final customValue = _customRateTypeController.text.trim();
      return customValue.isNotEmpty ? customValue : _t('Other', 'अन्य');
    }
    return _getRateTypeDisplay(value);
  }

  // Get list of jobs from user data
  List<String> _getJobs() {
    final data = _userData;
    if (data == null) return [];

    final jobs = data['type'];
    if (jobs is List) {
      return jobs.map((e) => e.toString()).toList();
    } else if (jobs is String) {
      return [jobs];
    }
    return [];
  }

  // Get wage rates list from user data
  List<dynamic> _getWageRates() {
    final data = _userData;
    if (data == null) return [];

    final rates = data['wageRate'];
    if (rates is List) return rates;
    if (rates is num) return [rates];
    return [];
  }

  // Get wage rate types list from user data
  List<dynamic> _getWageRateTypes() {
    final data = _userData;
    if (data == null) return [];

    final types = data['wageRateType'];
    if (types is List) return types;
    if (types is String) return [types];
    return [];
  }

  // Get wage rate for a specific job
  String? _getWageRateForJob(String job) {
    final jobs = _getJobs();
    final rates = _getWageRates();
    final index = jobs.indexOf(job);

    if (index >= 0 && index < rates.length) {
      final rate = rates[index];
      if (rate != null && rate.toString().isNotEmpty) {
        return rate.toString();
      }
    }
    return null;
  }

  // Get wage rate type for a specific job
  String? _getWageRateTypeForJob(String job) {
    final jobs = _getJobs();
    final types = _getWageRateTypes();
    final index = jobs.indexOf(job);

    if (index >= 0 && index < types.length) {
      final type = types[index];
      if (type != null && type.toString().isNotEmpty) {
        return type.toString();
      }
    }
    return null;
  }

  // ============================================================
  // RESET FORM
  // ============================================================

  void _resetForm() {
    setState(() {
      _selectedJobForWage = null;
      _wageRateController.clear();
      _selectedWageRateType = null;
      _customRateTypeController.clear();
      _showCustomInput = false;
    });
  }

  // ============================================================
  // HANDLE JOB SELECTION
  // ============================================================

  void _onJobSelected(String? job) {
    setState(() {
      _selectedJobForWage = job;

      if (job == null || job.isEmpty) {
        _wageRateController.clear();
        _selectedWageRateType = null;
        _customRateTypeController.clear();
        _showCustomInput = false;
        return;
      }

      // Get existing rate and type for this job
      final rate = _getWageRateForJob(job);
      final type = _getWageRateTypeForJob(job);

      _wageRateController.text = rate ?? '';

      // Check if it's a custom type (not in predefined list)
      if (type != null && type.isNotEmpty) {
        if (!_rateTypes.any((item) => item['en'] == type)) {
          // It's a custom type
          _selectedWageRateType = 'Other';
          _customRateTypeController.text = type;
          _showCustomInput = true;
        } else {
          _selectedWageRateType = type;
          _showCustomInput = false;
          _customRateTypeController.clear();
        }
      } else {
        _selectedWageRateType = null;
        _showCustomInput = false;
        _customRateTypeController.clear();
      }
    });
  }

  // ============================================================
  // HANDLE RATE TYPE CHANGE
  // ============================================================

  void _onRateTypeChanged(String? value) {
    setState(() {
      _selectedWageRateType = value;
      if (value == 'Other') {
        _showCustomInput = true;
        // If there's already a custom value, keep it
        if (_customRateTypeController.text.isEmpty) {
          _customRateTypeController.clear();
        }
      } else {
        _showCustomInput = false;
        _customRateTypeController.clear();
      }
    });
  }

  // ============================================================
  // UPDATE WAGE RATE
  // ============================================================

  Future<void> _updateWageRate() async {
    final wageRateText = _wageRateController.text.trim();

    // Validate wage rate
    if (wageRateText.isEmpty || double.tryParse(wageRateText) == null) {
      _showErrorSnackbar(
        context,
        _t('Please enter a valid wage rate', 'कृपया सही मजदूरी दर दर्ज करें'),
      );
      return;
    }

    // Validate job selection
    if (_selectedJobForWage == null || _selectedJobForWage!.isEmpty) {
      _showErrorSnackbar(
        context,
        _t('Please select a job', 'कृपया एक काम चुनें'),
      );
      return;
    }

    // Validate rate type
    if (_selectedWageRateType == null) {
      _showErrorSnackbar(
        context,
        _t('Please select wage rate type', 'कृपया दर का प्रकार चुनें'),
      );
      return;
    }

    // If "Other" is selected but custom input is empty
    if (_selectedWageRateType == 'Other' &&
        _customRateTypeController.text.trim().isEmpty) {
      _showErrorSnackbar(
        context,
        _t('Please enter custom rate type', 'कृपया कस्टम दर प्रकार दर्ज करें'),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final vendorJson = prefs.getString('vendor');

      if (vendorJson == null) {
        throw Exception('Vendor not logged in');
      }

      final decoded = jsonDecode(vendorJson) as Map<String, dynamic>;
      final token = decoded['token'];
      final vendorId = decoded['vendorId'];

      // Get current jobs, rates, and types
      final currentJobs = _getJobs();
      final currentRates = _getWageRates().cast<num?>().toList();
      final currentTypes =
          _getWageRateTypes().map((e) => e?.toString() ?? '').toList();

      final jobIndex = currentJobs.indexOf(_selectedJobForWage!);

      // Ensure arrays are long enough
      while (currentRates.length <= jobIndex) {
        currentRates.add(null);
      }
      while (currentTypes.length <= jobIndex) {
        currentTypes.add('');
      }

      // Update the rate and type for the selected job
      currentRates[jobIndex] = int.parse(wageRateText);
      currentTypes[jobIndex] = _getFinalRateType();

      // Remove trailing nulls
      while (currentRates.isNotEmpty && currentRates.last == null) {
        currentRates.removeLast();
        if (currentTypes.length > currentRates.length) {
          currentTypes.removeLast();
        }
      }

      final url = Uri.parse('${KConstantURL.url}/vendor/wageRate');

      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'wageRate': currentRates,
          'wageRateType': currentTypes,
          'vendorId': vendorId,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        await _updateVendorWageRate(decoded, result);
        isWageRateAvailable.value = true;

        if (!mounted) return;

        // Reset form on success
        _resetForm();

        _showSuccessSnackbar(
          context,
          _t(
            'Wage rate updated successfully',
            'मजदूरी दर सफलतापूर्वक अपडेट हो गई',
          ),
        );
      } else {
        throw Exception('Failed to update wage rate');
      }
    } catch (e) {
      debugPrint('Wage rate update error: $e');

      if (!mounted) return;

      _showErrorSnackbar(context, _t('Something went wrong', 'कुछ गलत हो गया'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ============================================================
  // UPDATE VENDOR IN STORAGE
  // ============================================================

  Future<void> _updateVendorWageRate(
    Map<String, dynamic> decoded,
    Map<String, dynamic> responseJson,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final vendorJson = prefs.getString('vendor');
    if (vendorJson == null) return;

    // ✅ FIX: Convert using Map.from()
    final currentVendor = Map<String, dynamic>.from(jsonDecode(vendorJson));

    final updatedVendor = {
      ...currentVendor,
      'wageRate': responseJson['wageRate'] ?? currentVendor['wageRate'],
      'wageRateType':
          responseJson['wageRateType'] ?? currentVendor['wageRateType'] ?? '',
      'message': responseJson['message'] ?? currentVendor['message'] ?? '',
    };

    await prefs.setString('vendor', jsonEncode(updatedVendor));

    setState(() {
      _userData = updatedVendor;
    });
  }
  // ============================================================
  // LOAD USER DATA
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final vendorJson = prefs.getString('vendor');
    if (vendorJson != null) {
      setState(() {
        _userData = jsonDecode(vendorJson);
      });
    }
  }

  // ============================================================
  // SNACKBARS
  // ============================================================

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Center(
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        content: Center(
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  void dispose() {
    _wageRateController.dispose();
    _customRateTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isHindiNotifier,
      builder: (context, isHindi, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: isDarkThemeNotifier,
          builder: (context, isDarkTheme, __) {
            final colorScheme = Theme.of(context).colorScheme;
            final primary = colorScheme.primary;
            final onPrimary = colorScheme.onPrimary;
            final surface = colorScheme.surface;
            final surfaceAlt =
                isDarkTheme
                    ? const Color(0xFF1E1E2E)
                    : colorScheme.surfaceContainerLow;
            final textColor =
                isDarkTheme ? Colors.white : colorScheme.onSurface;
            final mutedColor =
                isDarkTheme ? Colors.white60 : colorScheme.onSurfaceVariant;
            final outline =
                isDarkTheme
                    ? Colors.white.withOpacity(0.08)
                    : colorScheme.outlineVariant;

            final jobs = _getJobs();
            final hasJobs = jobs.isNotEmpty;

            return Scaffold(
              backgroundColor:
                  isDarkTheme ? const Color(0xFF0B1020) : colorScheme.surface,
              appBar: AppBar(
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor:
                    isDarkTheme ? const Color(0xFF0B1020) : colorScheme.surface,
                foregroundColor: textColor,
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  _t("Service Charge", "सेवा शुल्क"),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: _resetForm,
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: textColor.withOpacity(0.7),
                    ),
                    tooltip: _t('Reset', 'रीसेट'),
                  ),
                ],
              ),
              body: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxHeight < 650;
                    final horizontal = constraints.maxWidth < 380 ? 16.0 : 22.0;

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        horizontal,
                        compact ? 12 : 20,
                        horizontal,
                        24,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 620),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ==========================================
                              // HEADER CARD
                              // ==========================================
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(compact ? 18 : 24),
                                decoration: BoxDecoration(
                                  color:
                                      isDarkTheme
                                          ? const Color(0xFF1A1A2E)
                                          : Colors.white.withOpacity(.45),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color:
                                        isDarkTheme
                                            ? Colors.white.withOpacity(0.06)
                                            : colorScheme.primary.withOpacity(
                                              .12,
                                            ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: compact ? 52 : 60,
                                      height: compact ? 52 : 60,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            primary,
                                            primary.withOpacity(0.7),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Icon(
                                        Icons.payments_rounded,
                                        color: onPrimary,
                                        size: compact ? 27 : 31,
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _t(
                                              'Set your service charge',
                                              'अपनी सेवा शुल्क तय करें',
                                            ),
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: compact ? 18 : 22,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            hasJobs
                                                ? _t(
                                                  'Set rates for each of your jobs.',
                                                  'अपने प्रत्येक काम के लिए दरें तय करें।',
                                                )
                                                : _t(
                                                  'Add jobs first to set service charge.',
                                                  'शुल्क दर सेट करने के लिए पहले काम जोड़ें।',
                                                ),
                                            style: TextStyle(
                                              color: mutedColor,
                                              fontSize: 12.5,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: compact ? 16 : 22),

                              // ==========================================
                              // NO JOBS WARNING
                              // ==========================================
                              if (!hasJobs) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.orange.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.orange,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _t(
                                            'Please add at least one job to set service charges.',
                                            'कृपया शुल्क दरें सेट करने के लिए कम से कम एक काम जोड़ें।',
                                          ),
                                          style: TextStyle(
                                            color: Colors.orange.shade800,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],

                              // ==========================================
                              // JOB SELECTION
                              // ==========================================
                              if (hasJobs) ...[
                                Text(
                                  _t('Select Job', 'काम चुनें'),
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                Container(
                                  decoration: BoxDecoration(
                                    color: surfaceAlt,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: outline,
                                      width: isDarkTheme ? 1.5 : 1,
                                    ),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedJobForWage,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: primary.withOpacity(
                                            isDarkTheme ? 0.20 : .10,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.work_rounded,
                                          color: primary,
                                        ),
                                      ),
                                      hintText: _t(
                                        'Select a job',
                                        'कोई काम चुनें',
                                      ),
                                      hintStyle: TextStyle(
                                        color: mutedColor,
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    dropdownColor:
                                        isDarkTheme
                                            ? const Color(0xFF1A1A2E)
                                            : surface,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    icon: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: mutedColor,
                                    ),
                                    items: [
                                      DropdownMenuItem<String>(
                                        value: null,
                                        child: Text(
                                          _t('Select a job', 'कोई काम चुनें'),
                                        ),
                                      ),
                                      ...jobs.map((job) {
                                        return DropdownMenuItem<String>(
                                          value: job,
                                          child: Row(
                                            children: [
                                              Text(
                                                getJobEmoji(job),
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  getJobDisplay(job),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const Spacer(),
                                              // Show current rate if exists
                                              if (_getWageRateForJob(job) !=
                                                  null) ...[
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: primary.withOpacity(
                                                      0.1,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '₹${_getWageRateForJob(job)}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: primary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                    onChanged: _onJobSelected,
                                  ),
                                ),

                                const SizedBox(height: 20),
                              ],

                              // ==========================================
                              // WAGE RATE INPUT (shown when job selected)
                              // ==========================================
                              if (_selectedJobForWage != null &&
                                  _selectedJobForWage!.isNotEmpty) ...[
                                Text(
                                  _t("Service Charge", "सेवा शुल्क "),
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                Container(
                                  decoration: BoxDecoration(
                                    color: surfaceAlt,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: outline,
                                      width: isDarkTheme ? 1.5 : 1,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _wageRateController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: false,
                                        ),
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    decoration: InputDecoration(
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: primary.withOpacity(
                                            isDarkTheme ? 0.20 : .10,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.currency_rupee_rounded,
                                          color: primary,
                                        ),
                                      ),
                                      hintText: _t(
                                        'Enter amount',
                                        'राशि दर्ज करें',
                                      ),
                                      hintStyle: TextStyle(
                                        color: mutedColor,
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 16,
                                          ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // ==========================================
                                // RATE TYPE
                                // ==========================================
                                Text(
                                  _t('Service Charge type', 'शुल्क का प्रकार'),
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                Container(
                                  decoration: BoxDecoration(
                                    color: surfaceAlt,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: outline,
                                      width: isDarkTheme ? 1.5 : 1,
                                    ),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedWageRateType,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: primary.withOpacity(
                                            isDarkTheme ? 0.20 : .10,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.schedule_rounded,
                                          color: primary,
                                        ),
                                      ),
                                      hintText: _t(
                                        'Select rate type',
                                        'दर का प्रकार चुनें',
                                      ),
                                      hintStyle: TextStyle(
                                        color: mutedColor,
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    dropdownColor:
                                        isDarkTheme
                                            ? const Color(0xFF1A1A2E)
                                            : surface,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    icon: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: mutedColor,
                                    ),
                                    items:
                                        _rateTypes.map((type) {
                                          final enValue = type['en']!;
                                          final displayName =
                                              isHindiNotifier.value
                                                  ? type['hi']!
                                                  : enValue;
                                          final icon =
                                              _rateTypeIcons[enValue] ??
                                              Icons.more_horiz_rounded;
                                          return DropdownMenuItem<String>(
                                            value: enValue,
                                            child: Row(
                                              children: [
                                                Icon(icon, size: 18),
                                                const SizedBox(width: 9),
                                                Flexible(
                                                  child: Text(
                                                    displayName,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                    onChanged: _onRateTypeChanged,
                                  ),
                                ),

                                // ==========================================
                                // CUSTOM INPUT
                                // ==========================================
                                if (_showCustomInput) ...[
                                  const SizedBox(height: 12),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            primary.withOpacity(0.1),
                                            primary.withOpacity(0.05),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: primary.withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 16,
                                              top: 8,
                                            ),
                                            child: Text(
                                              _t(
                                                'Enter custom rate type',
                                                'कस्टम दर प्रकार दर्ज करें',
                                              ),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: primary,
                                              ),
                                            ),
                                          ),
                                          TextField(
                                            controller:
                                                _customRateTypeController,
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            decoration: InputDecoration(
                                              prefixIcon: Container(
                                                margin: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: primary.withOpacity(
                                                    0.1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Icon(
                                                  Icons.edit_note_rounded,
                                                  color: primary,
                                                  size: 20,
                                                ),
                                              ),
                                              hintText:
                                                  isHindiNotifier.value
                                                      ? 'जैसे: प्रति वर्ग फुट, प्रति महीना, आदि।'
                                                      : 'e.g. Per Square Feet, Per Month, etc.',
                                              hintStyle: TextStyle(
                                                color: mutedColor,
                                                fontSize: 13,
                                              ),
                                              border: InputBorder.none,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 12,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],

                                // ==========================================
                                // SELECTED TYPE PREVIEW
                                // ==========================================
                                if (_selectedWageRateType != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          primary.withOpacity(
                                            isDarkTheme ? 0.15 : 0.08,
                                          ),
                                          primary.withOpacity(
                                            isDarkTheme ? 0.08 : 0.03,
                                          ),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: primary.withOpacity(
                                          isDarkTheme ? 0.25 : 0.15,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color: primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _getFinalRateType().isNotEmpty
                                              ? _t(
                                                'Selected: ${_getFinalRateTypeDisplay()}',
                                                'चयनित: ${_getFinalRateTypeDisplay()}',
                                              )
                                              : _t(
                                                'Selected: ${_getRateTypeDisplay(_selectedWageRateType!)}',
                                                'चयनित: ${_getRateTypeDisplay(_selectedWageRateType!)}',
                                              ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                SizedBox(height: compact ? 22 : 30),

                                // ==========================================
                                // SAVE BUTTON
                                // ==========================================
                                SizedBox(
                                  width: double.infinity,
                                  height: compact ? 50 : 54,
                                  child: ElevatedButton(
                                    onPressed:
                                        _isLoading ? null : _updateWageRate,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primary,
                                      foregroundColor: onPrimary,
                                      disabledBackgroundColor: primary
                                          .withOpacity(.40),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(17),
                                      ),
                                    ),
                                    child:
                                        _isLoading
                                            ? SizedBox(
                                              width: 23,
                                              height: 23,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: onPrimary,
                                              ),
                                            )
                                            : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.check_rounded,
                                                  size: 21,
                                                  color: onPrimary,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _t(
                                                    'Save Wage Rate',
                                                    'मजदूरी दर सेव करें',
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w900,
                                                    color: onPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                  ),
                                ),
                              ],

                              // ==========================================
                              // DISPLAY ALL JOB RATES (read-only)
                              // ==========================================
                              if (hasJobs &&
                                  (_selectedJobForWage == null ||
                                      _selectedJobForWage!.isEmpty)) ...[
                                const SizedBox(height: 16),

                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: surfaceAlt,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: outline,
                                      width: isDarkTheme ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.list_alt_rounded,
                                            size: 18,
                                            color: primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _t(
                                              'All Job Rates',
                                              'सभी काम की दरें',
                                            ),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: textColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      ...jobs.map((job) {
                                        final rate = _getWageRateForJob(job);
                                        final type = _getWageRateTypeForJob(
                                          job,
                                        );

                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 12,
                                          ),
                                          margin: const EdgeInsets.only(
                                            bottom: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: outline,
                                              width: 0.5,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                getJobEmoji(job),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  getJobDisplay(job),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: textColor,
                                                  ),
                                                ),
                                              ),
                                              if (rate != null &&
                                                  rate.isNotEmpty) ...[
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: primary.withOpacity(
                                                      0.1,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        '₹$rate',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: primary,
                                                        ),
                                                      ),
                                                      if (type != null &&
                                                          type.isNotEmpty) ...[
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          '/ $type',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: mutedColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ] else ...[
                                                Text(
                                                  _t(
                                                    'Not set',
                                                    'निर्धारित नहीं',
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: mutedColor,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 12),

                              // ==========================================
                              // FOOTER NOTE
                              // ==========================================
                              Center(
                                child: Text(
                                  _t(
                                    'You can update this anytime.',
                                    'आप इसे कभी भी अपडेट कर सकते हैं।',
                                  ),
                                  style: TextStyle(
                                    color: mutedColor,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

import 'dart:convert';
import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class Leave {
  final String id;
  final DateTime from;
  final DateTime to;
  final String? reason;
  final String status;
  final DateTime createdAt;

  Leave({
    required this.id,
    required this.from,
    required this.to,
    this.reason,
    required this.status,
    required this.createdAt,
  });

  factory Leave.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      try {
        DateTime utcDate = DateTime.parse(value.toString());
        return utcDate.add(const Duration(hours: 5, minutes: 30));
      } catch (e) {
        return DateTime.now();
      }
    }

    return Leave(
      id: json['_id']?.toString() ?? '',
      from: parseDate(json['from']),
      to: parseDate(json['to']),
      reason: json['reason']?.toString(),
      status: json['status']?.toString() ?? 'active',
      createdAt: parseDate(json['createdAt']),
    );
  }

  String get classification {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);

    if (status == 'cancelled') return 'cancelled';
    if (fromDate.isBefore(today) && toDate.isAfter(today)) return 'current';
    if (fromDate.isAfter(today) || fromDate.isAtSameMomentAs(today))
      return 'future';
    return 'past';
  }
}

class LeaveManagementPage extends StatefulWidget {
  const LeaveManagementPage({super.key});

  @override
  State<LeaveManagementPage> createState() => _LeaveManagementPageState();
}

class _LeaveManagementPageState extends State<LeaveManagementPage>
    with SingleTickerProviderStateMixin {
  List<Leave> _leaves = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  late AnimationController _animationController;

  // Language helper
  String _t(String en, String hi) => isHindiNotifier.value ? hi : en;

  @override
  void initState() {
    super.initState();
    _initializeDateFormatting();
    _fetchLeaves();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _initializeDateFormatting() {
    try {
      initializeDateFormatting('hi', null);
    } catch (e) {
      print('Locale initialization error: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchLeaves() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final isVendor1 = isVendor.value;
      final category = isVendor1 ? 'vendor' : 'user';
      final categoryData = prefs.getString(category);

      if (categoryData == null) {
        setState(() => _isLoading = false);
        return;
      }

      final decoded = jsonDecode(categoryData);
      final token = 'Bearer ${decoded['token']}';

      final response = await http
          .get(
            Uri.parse("${KConstantURL.url}/vendor/getLeaveStats"),
            headers: {
              'Authorization': token,
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final leavesList = data['data'] as List? ?? [];
          setState(() {
            _leaves = leavesList.map((item) => Leave.fromJson(item)).toList();
          });
        }
      } else {
        _showMessage(
          _t('Failed to load leaves', 'छुट्टियाँ लोड करने में विफल'),
          Colors.red,
        );
      }
    } catch (e) {
      _showMessage(
        _t('Error loading leaves', 'छुट्टियाँ लोड करने में त्रुटि'),
        Colors.red,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelLeave(String leaveId) async {
    if (leaveId.isEmpty) {
      _showMessage(
        _t('Leave ID is required', 'छुट्टी आईडी आवश्यक है'),
        Colors.red,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final isVendor1 = isVendor.value;
      final category = isVendor1 ? 'vendor' : 'user';
      final categoryData = prefs.getString(category);

      if (categoryData == null) {
        setState(() => _isSubmitting = false);
        _showMessage(
          _t('User data not found', 'उपयोगकर्ता डेटा नहीं मिला'),
          Colors.red,
        );
        return;
      }

      final decoded = jsonDecode(categoryData);
      final token = 'Bearer ${decoded['token']}';

      final response = await http
          .delete(
            Uri.parse("${KConstantURL.url}/vendor/cancelLeave/$leaveId"),
            headers: {
              'Authorization': token,
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _showMessage(
          data['message'] ??
              _t(
                'Leave cancelled successfully',
                'छुट्टी सफलतापूर्वक रद्द की गई',
              ),
          Colors.green,
        );
        await _fetchLeaves();
      } else {
        try {
          final errorData = jsonDecode(response.body);
          _showMessage(
            errorData['message'] ??
                _t('Failed to cancel leave', 'छुट्टी रद्द करने में विफल'),
            Colors.red,
          );
        } catch (e) {
          _showMessage(
            _t('Failed to cancel leave', 'छुट्टी रद्द करने में विफल'),
            Colors.red,
          );
        }
      }
    } catch (e) {
      _showMessage(
        _t('Error cancelling leave', 'छुट्टी रद्द करने में त्रुटि'),
        Colors.red,
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _createLeave(
    DateTime from,
    DateTime to,
    String? reason,
    color,
  ) async {
    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final isVendor1 = isVendor.value;
      final category = isVendor1 ? 'vendor' : 'user';
      final categoryData = prefs.getString(category);

      if (categoryData == null) {
        setState(() => _isSubmitting = false);
        return;
      }

      final decoded = jsonDecode(categoryData);
      final token = 'Bearer ${decoded['token']}';

      final response = await http
          .post(
            Uri.parse("${KConstantURL.url}/vendor/createLeave"),
            headers: {
              'Authorization': token,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'from': from.toUtc().toIso8601String(),
              'to': to.toUtc().toIso8601String(),
              'reason': reason ?? '',
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showMessage(
          _t(
            'Leave created successfully! 🎉',
            'छुट्टी सफलतापूर्वक बनाई गई! 🎉',
          ),
          color,
        );
        await _fetchLeaves();
      } else {
        try {
          final errorData = jsonDecode(response.body);
          _showMessage(
            errorData['message'] ??
                _t('Failed to process request', 'अनुरोध संसाधित करने में विफल'),
            Colors.red,
          );
        } catch (e) {
          _showMessage(
            _t('Failed to process request', 'अनुरोध संसाधित करने में विफल'),
            Colors.red,
          );
        }
      }
    } catch (e) {
      _showMessage(
        _t('Error creating leave', 'छुट्टी बनाने में त्रुटि'),
        Colors.red,
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }

  String _formatDate(DateTime date) {
    try {
      final isHindi = isHindiNotifier.value;
      if (isHindi) {
        return DateFormat('d MMMM yyyy', 'hi').format(date);
      }
      return DateFormat('d MMMM yyyy').format(date);
    } catch (e) {
      return DateFormat('d MMMM yyyy').format(date);
    }
  }

  String _formatShortDate(DateTime date) {
    try {
      final isHindi = isHindiNotifier.value;
      if (isHindi) {
        return DateFormat('d MMM yyyy', 'hi').format(date);
      }
      return DateFormat('d MMM yyyy').format(date);
    } catch (e) {
      return DateFormat('d MMM yyyy').format(date);
    }
  }

  String _getStatusLabel(String status) {
    final map = {
      'current': _t('Active', 'सक्रिय'),
      'future': _t('Upcoming', 'आगामी'),
      'past': _t('Completed', 'पूर्ण'),
      'cancelled': _t('Cancelled', 'रद्द'),
    };
    return map[status] ?? status;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'current':
        return const Color(0xFFE65100);
      case 'future':
        return const Color(0xFF0D47A1);
      case 'past':
        return const Color(0xFF2E7D32);
      case 'cancelled':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF616161);
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'current':
        return const Color(0xFFFFF3E0);
      case 'future':
        return const Color(0xFFE3F2FD);
      case 'past':
        return const Color(0xFFE8F5E9);
      case 'cancelled':
        return const Color(0xFFFFEBEE);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'current':
        return Icons.timelapse;
      case 'future':
        return Icons.event_available;
      case 'past':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.circle;
    }
  }

  List<Leave> _getLeavesByStatus(String status) {
    return _leaves.where((leave) => leave.classification == status).toList();
  }

  void _showCreateLeaveDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;

    DateTime? fromDate;
    DateTime? toDate;
    String? reason;
    final TextEditingController reasonController = TextEditingController();

    final List<Map<String, String>> reasonSuggestions = [
      {'en': 'Personal leave', 'hi': 'व्यक्तिगत छुट्टी'},
      {'en': 'Family function', 'hi': 'पारिवारिक समारोह'},
      {'en': 'Medical emergency', 'hi': 'चिकित्सा आपातकाल'},
      {'en': 'Vacation', 'hi': 'छुट्टी'},
      {'en': 'Personal work', 'hi': 'निजी काम'},
      {'en': 'Religious event', 'hi': 'धार्मिक कार्यक्रम'},
    ];

    String defaultReason = _t('Personal leave', 'व्यक्तिगत छुट्टी');
    reasonController.text = defaultReason;
    reason = defaultReason;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setStateDialog) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                backgroundColor:
                    isDark ? const Color(0xFF1A1A2E) : Colors.white,
                elevation: 24,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  constraints: BoxConstraints(
                    maxWidth: 420,
                    maxHeight: MediaQuery.of(context).size.height * 0.9,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    primaryColor,
                                    primaryColor.withOpacity(0.7),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.beach_access,
                                color: colorScheme.onPrimary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _t(
                                      'Request Leave',
                                      'छुट्टी का अनुरोध करें',
                                    ),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isDark
                                              ? Colors.white
                                              : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    _t(
                                      'Plan your time off',
                                      'अपनी छुट्टी की योजना बनाएं',
                                    ),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color:
                                    isDark ? Colors.white70 : Colors.grey[400],
                                size: 24,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // From Date
                        _buildModernDatePickerField(
                          label: _t('Start Date', 'प्रारंभ तिथि'),
                          value: fromDate,
                          icon: Icons.calendar_today,
                          onTap: () async {
                            final picked = await _showCustomCalendarDialog(
                              context: context,
                              title: _t(
                                'Select Start Date',
                                'प्रारंभ तिथि चुनें',
                              ),
                              initialDate: fromDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                              isDark: isDark,
                              primaryColor: primaryColor,
                            );
                            if (picked != null) {
                              setStateDialog(() {
                                fromDate = picked;
                                if (toDate != null &&
                                    toDate!.isBefore(picked)) {
                                  toDate = picked;
                                }
                              });
                            }
                          },
                          isDark: isDark,
                          primaryColor: primaryColor,
                        ),
                        const SizedBox(height: 14),

                        // To Date
                        _buildModernDatePickerField(
                          label: _t('End Date', 'समाप्ति तिथि'),
                          value: toDate,
                          icon: Icons.calendar_today,
                          onTap: () async {
                            final picked = await _showCustomCalendarDialog(
                              context: context,
                              title: _t(
                                'Select End Date',
                                'समाप्ति तिथि चुनें',
                              ),
                              initialDate: toDate ?? fromDate ?? DateTime.now(),
                              firstDate: fromDate ?? DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                              isDark: isDark,
                              primaryColor: primaryColor,
                            );
                            if (picked != null) {
                              setStateDialog(() {
                                toDate = picked;
                              });
                            }
                          },
                          isDark: isDark,
                          primaryColor: primaryColor,
                        ),
                        const SizedBox(height: 14),

                        // Reason with Suggestions
                        Text(
                          _t('Reason', 'कारण'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? const Color(0xFF252540)
                                    : Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  isDark
                                      ? Colors.white.withOpacity(0.06)
                                      : const Color(0xFFE8ECF3),
                            ),
                          ),
                          child: TextField(
                            controller: reasonController,
                            decoration: InputDecoration(
                              hintText: _t(
                                'Brief reason for leave...',
                                'छुट्टी का संक्षिप्त कारण...',
                              ),
                              hintStyle: TextStyle(
                                color:
                                    isDark
                                        ? Colors.grey[500]
                                        : Colors.grey[400],
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 3,
                            maxLength: 200,
                            onChanged: (value) {
                              setStateDialog(() {
                                reason = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              reasonSuggestions.map((suggestion) {
                                final label =
                                    isHindiNotifier.value
                                        ? suggestion['hi']!
                                        : suggestion['en']!;
                                final isSelected =
                                    reasonController.text == label;
                                return GestureDetector(
                                  onTap: () {
                                    setStateDialog(() {
                                      reasonController.text = label;
                                      reason = label;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient:
                                          isSelected
                                              ? LinearGradient(
                                                colors: [
                                                  primaryColor,
                                                  primaryColor.withOpacity(0.7),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                              : null,
                                      color:
                                          isSelected
                                              ? null
                                              : (isDark
                                                  ? const Color(0xFF252540)
                                                  : Colors.grey[100]),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? primaryColor
                                                : (isDark
                                                    ? Colors.grey[700]!
                                                    : Colors.grey[300]!),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isSelected)
                                          Icon(
                                            Icons.check_circle,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        if (isSelected)
                                          const SizedBox(width: 6),
                                        Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight:
                                                isSelected
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                            color:
                                                isSelected
                                                    ? Colors.white
                                                    : (isDark
                                                        ? Colors.white70
                                                        : Colors.grey[700]),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 14,
                                color:
                                    isDark
                                        ? Colors.grey[500]
                                        : Colors.grey[400],
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _t(
                                    'Tap on any suggestion above to quickly fill the reason',
                                    'ऊपर दिए गए किसी भी सुझाव पर टैप करें कारण को जल्दी भरने के लिए',
                                  ),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        isDark
                                            ? Colors.grey[500]
                                            : Colors.grey[400],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Actions
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color:
                                          isDark
                                              ? Colors.grey[600]!
                                              : Colors.grey[300]!,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  _t('Cancel', 'रद्द करें'),
                                  style: TextStyle(
                                    color:
                                        isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (fromDate == null) {
                                    _showMessage(
                                      _t(
                                        'Please select a start date',
                                        'कृपया प्रारंभ तिथि चुनें',
                                      ),
                                      Colors.orange,
                                    );
                                    return;
                                  }
                                  if (toDate == null) {
                                    _showMessage(
                                      _t(
                                        'Please select an end date',
                                        'कृपया समाप्ति तिथि चुनें',
                                      ),
                                      Colors.orange,
                                    );
                                    return;
                                  }
                                  if (toDate!.isBefore(fromDate!)) {
                                    _showMessage(
                                      _t(
                                        'End date must be after start date',
                                        'समाप्ति तिथि प्रारंभ तिथि के बाद होनी चाहिए',
                                      ),
                                      Colors.orange,
                                    );
                                    return;
                                  }
                                  if (reasonController.text.trim().isEmpty) {
                                    _showMessage(
                                      _t(
                                        'Please enter a reason',
                                        'कृपया एक कारण दर्ज करें',
                                      ),
                                      Colors.orange,
                                    );
                                    return;
                                  }

                                  Navigator.pop(context);
                                  _createLeave(
                                    fromDate!,
                                    toDate!,
                                    reason,
                                    primaryColor,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child:
                                    _isSubmitting
                                        ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                        : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check, size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              _t(
                                                'Confirm Leave',
                                                'छुट्टी की पुष्टि करें',
                                              ),
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }

  // Custom Calendar Dialog with Hindi Support
  Future<DateTime?> _showCustomCalendarDialog({
    required BuildContext context,
    required String title,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required bool isDark,
    required Color primaryColor,
  }) async {
    DateTime? tempDate = initialDate;
    DateTime currentMonth = DateTime(initialDate.year, initialDate.month, 1);

    // Hindi month names
    const List<String> hindiMonths = [
      'जनवरी',
      'फरवरी',
      'मार्च',
      'अप्रैल',
      'मई',
      'जून',
      'जुलाई',
      'अगस्त',
      'सितम्बर',
      'अक्टूबर',
      'नवम्बर',
      'दिसम्बर',
    ];

    // Hindi weekday names (short)
    const List<String> hindiWeekdays = [
      'सोम',
      'मंगल',
      'बुध',
      'गुरु',
      'शुक्र',
      'शनि',
      'रवि',
    ];

    const List<String> englishWeekdays = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    return await showDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setStateDialog) {
              final isHindi = isHindiNotifier.value;
              final daysInMonth =
                  DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
              final firstDayOfMonth = DateTime(
                currentMonth.year,
                currentMonth.month,
                1,
              );
              final startWeekday = firstDayOfMonth.weekday;
              final startOffset = startWeekday - 1;

              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                backgroundColor:
                    isDark ? const Color(0xFF1A1A2E) : Colors.white,
                elevation: 24,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  constraints: BoxConstraints(
                    maxWidth: 400,
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor,
                                  primaryColor.withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.calendar_month_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Text(
                                  _t('Pick a date', 'तिथि चुनें'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: isDark ? Colors.white70 : Colors.grey[400],
                              size: 24,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Month Navigation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(Icons.chevron_left_rounded, size: 28),
                            color: isDark ? Colors.white : Colors.black87,
                            onPressed: () {
                              setStateDialog(() {
                                currentMonth = DateTime(
                                  currentMonth.year,
                                  currentMonth.month - 1,
                                  1,
                                );
                              });
                            },
                          ),
                          Text(
                            isHindi
                                ? '${hindiMonths[currentMonth.month - 1]} ${currentMonth.year}'
                                : '${_getEnglishMonth(currentMonth.month)} ${currentMonth.year}',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.chevron_right_rounded, size: 28),
                            color: isDark ? Colors.white : Colors.black87,
                            onPressed: () {
                              setStateDialog(() {
                                currentMonth = DateTime(
                                  currentMonth.year,
                                  currentMonth.month + 1,
                                  1,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Weekday Headers
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: List.generate(7, (index) {
                            final weekdayName =
                                isHindi
                                    ? hindiWeekdays[index]
                                    : englishWeekdays[index];
                            return Expanded(
                              child: Center(
                                child: Text(
                                  weekdayName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Calendar Grid
                      Expanded(
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                childAspectRatio: 1.0,
                                mainAxisSpacing: 4,
                                crossAxisSpacing: 4,
                              ),
                          itemCount: 42,
                          itemBuilder: (context, index) {
                            final day = index - startOffset + 1;
                            final date = DateTime(
                              currentMonth.year,
                              currentMonth.month,
                              day,
                            );

                            if (day < 1 || day > daysInMonth) {
                              return const SizedBox.shrink();
                            }

                            final isSelected =
                                tempDate != null &&
                                tempDate!.year == date.year &&
                                tempDate!.month == date.month &&
                                tempDate!.day == date.day;

                            final isToday =
                                DateTime.now().year == date.year &&
                                DateTime.now().month == date.month &&
                                DateTime.now().day == date.day;

                            final isDisabled =
                                date.isBefore(firstDate) ||
                                date.isAfter(lastDate);

                            return GestureDetector(
                              onTap:
                                  isDisabled
                                      ? null
                                      : () {
                                        setStateDialog(() {
                                          tempDate = date;
                                        });
                                      },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? primaryColor
                                          : isToday
                                          ? primaryColor.withOpacity(0.12)
                                          : null,
                                  shape: BoxShape.circle,
                                  border:
                                      isToday && !isSelected
                                          ? Border.all(
                                            color: primaryColor,
                                            width: 1.5,
                                          )
                                          : null,
                                ),
                                child: Center(
                                  child: Text(
                                    '$day',
                                    style: TextStyle(
                                      color:
                                          isDisabled
                                              ? (isDark
                                                  ? Colors.grey[700]
                                                  : Colors.grey[400])
                                              : isSelected
                                              ? Colors.white
                                              : isToday
                                              ? primaryColor
                                              : (isDark
                                                  ? Colors.white
                                                  : Colors.black87),
                                      fontWeight:
                                          isSelected || isToday
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Selected date preview
                      if (tempDate != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryColor.withOpacity(0.08),
                                primaryColor.withOpacity(0.03),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 18,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isHindi
                                    ? '${tempDate!.day} ${hindiMonths[tempDate!.month - 1]} ${tempDate!.year}'
                                    : _formatDate(tempDate!),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color:
                                        isDark
                                            ? Colors.grey[600]!
                                            : Colors.grey[300]!,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              child: Text(
                                _t('Cancel', 'रद्द करें'),
                                style: TextStyle(
                                  color:
                                      isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (tempDate != null) {
                                  Navigator.pop(context, tempDate);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    tempDate != null
                                        ? primaryColor
                                        : Colors.grey[400],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                _t('Confirm', 'पुष्टि करें'),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  String _getEnglishMonth(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  Widget _buildModernDatePickerField({
    required String label,
    required DateTime? value,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    required Color primaryColor,
  }) {
    final isSelected = value != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '✓',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: primaryColor.withOpacity(0.08),
            highlightColor: primaryColor.withOpacity(0.04),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient:
                    isSelected
                        ? LinearGradient(
                          colors: [
                            isDark
                                ? const Color(0xFF1A1A2E).withOpacity(0.9)
                                : Colors.white,
                            isDark
                                ? const Color(0xFF252540).withOpacity(0.9)
                                : const Color(0xFFF8FAFD),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                        : null,
                color:
                    isSelected
                        ? null
                        : (isDark
                            ? const Color(0xFF252540)
                            : const Color(0xFFF8FAFD)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isSelected
                          ? primaryColor
                          : (isDark
                              ? Colors.white.withOpacity(0.06)
                              : const Color(0xFFE8ECF3)),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                            spreadRadius: -2,
                          ),
                        ]
                        : null,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient:
                          isSelected
                              ? LinearGradient(
                                colors: [
                                  primaryColor,
                                  primaryColor.withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                              : null,
                      color:
                          isSelected
                              ? null
                              : (isDark
                                  ? const Color(0xFF1A1A2E)
                                  : const Color(0xFFF0F2F8)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color:
                          isSelected
                              ? Colors.white
                              : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isSelected
                          ? _formatDate(value!)
                          : _t('Select $label', '$label चुनें'),
                      style: TextStyle(
                        color:
                            isSelected
                                ? (isDark ? Colors.white : Colors.black87)
                                : (isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[400]),
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: primaryColor,
                      ),
                    )
                  else
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                ],
              ),
            ),
          ),
        ),
        if (isSelected)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _t(
                      'Selected: ${_formatDate(value!)}',
                      'चयनित: ${_formatDate(value!)}',
                    ),
                    style: TextStyle(
                      fontSize: 11,
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showCancelConfirmation(Leave leave) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            elevation: 24,
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade400, Colors.red.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _t('Cancel Leave', 'छुट्टी रद्द करें'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _t(
                      'Are you sure you want to cancel this leave request?',
                      'क्या आप वाकई इस छुट्टी के अनुरोध को रद्द करना चाहते हैं?',
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors:
                            isDark
                                ? [
                                  const Color(0xFF252540),
                                  const Color(0xFF1A1A2E),
                                ]
                                : [Colors.grey[50]!, Colors.grey[100]!],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            isDark
                                ? Colors.white.withOpacity(0.06)
                                : const Color(0xFFE8ECF3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_note,
                          size: 16,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        const SizedBox(width: 8),

                        // ✅ Flexible prevents overflow
                        Flexible(
                          child: Text(
                            _formatShortDate(leave.from),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            overflow:
                                TextOverflow
                                    .ellipsis, // Shows ... if text is too long
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                          ),
                        ),

                        // ✅ Flexible prevents overflow
                        Flexible(
                          child: Text(
                            _formatShortDate(leave.to),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            overflow:
                                TextOverflow
                                    .ellipsis, // Shows ... if text is too long
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (leave.reason != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isDark ? const Color(0xFF252540) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '📝 ${leave.reason}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _t(
                            'This action cannot be undone',
                            'यह कार्रवाई वापस नहीं ली जा सकती',
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color:
                                    isDark
                                        ? Colors.grey[600]!
                                        : Colors.grey[300]!,
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: Text(
                            _t('Keep It', 'रखें'),
                            style: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _cancelLeave(leave.id);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child:
                              _isSubmitting
                                  ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                  : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.delete_outline, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        _t('Yes, Cancel', 'हाँ, रद्द करें'),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildLeaveCard(Leave leave) {
    final status = leave.classification;
    final statusColor = _getStatusColor(status);
    final statusBgColor = _getStatusBgColor(status);
    final statusLabel = _getStatusLabel(status);
    final statusIcon = _getStatusIcon(status);
    final isDark = Theme.of(context).brightness != Brightness.dark;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDark
                  ? [const Color(0xFF1A1A2E), const Color(0xFF252540)]
                  : [Colors.white, const Color(0xFFFAFAFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Status Color Accent Bar
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [statusColor, statusColor.withOpacity(0.6)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Icon with Glow
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              statusColor.withOpacity(0.15),
                              statusColor.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: statusColor.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(statusIcon, size: 22, color: statusColor),
                      ),
                      const SizedBox(width: 14),
                      // Date and Reason
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date Range
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? const Color(0xFF252540)
                                        : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      _formatShortDate(leave.from),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            isDark
                                                ? Colors.white
                                                : Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: false,
                                      maxLines: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward_ios,
                                      size: 8,
                                      color:
                                          isDark
                                              ? Colors.grey[500]
                                              : Colors.grey[400],
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      _formatShortDate(leave.to),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            isDark
                                                ? Colors.white
                                                : Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: false,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (leave.reason != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isDark
                                          ? const Color(0xFF252540)
                                          : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        isDark
                                            ? Colors.white.withOpacity(0.06)
                                            : const Color(0xFFE8ECF3),
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text('📝', style: TextStyle(fontSize: 12)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        leave.reason!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              isDark
                                                  ? Colors.grey[300]
                                                  : Colors.grey[700],
                                          fontStyle: FontStyle.italic,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Status Badge and Actions
                  Row(
                    children: [
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              statusBgColor,
                              statusBgColor.withOpacity(0.6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Action Buttons
                      if (status == 'future' || status == 'current') ...[
                        Container(
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? const Color(0xFF252540)
                                    : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed:
                                _isSubmitting
                                    ? null
                                    : () => _showCancelConfirmation(leave),
                            icon: Icon(
                              Icons.close_outlined,
                              size: 18,
                              color: Colors.red.shade400,
                            ),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            tooltip: _t('Cancel Leave', 'छुट्टी रद्द करें'),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? const Color(0xFF252540)
                                  : Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 10,
                              color:
                                  isDark ? Colors.grey[500] : Colors.grey[400],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_t('Created', 'बनाया गया')}: ${_formatShortDate(leave.createdAt)}',
                              style: TextStyle(
                                fontSize: 9,
                                color:
                                    isDark
                                        ? Colors.grey[500]
                                        : Colors.grey[400],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Leave> leaves, IconData icon) {
    final isDark = Theme.of(context).brightness != Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF252540) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isDark ? Colors.white70 : Colors.grey[700],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.grey[700],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      isDark ? Colors.grey[600]! : Colors.grey[200]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${leaves.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (leaves.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors:
                    isDark
                        ? [const Color(0xFF1A1A2E), const Color(0xFF252540)]
                        : [Colors.grey[50]!, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isDark
                        ? Colors.white.withOpacity(0.06)
                        : const Color(0xFFE8ECF3),
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _t('No $title leaves', '$title छुट्टियाँ नहीं'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: leaves.map((leave) => _buildLeaveCard(leave)).toList(),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final surface = colorScheme.surface;
    final onSurface = colorScheme.onSurface;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0B1020) : const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A2E) : surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, primaryColor.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.beach_access,
                      color: colorScheme.onPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t('Leave Management', 'छुट्टी प्रबंधन'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : onSurface,
                          ),
                        ),
                        Text(
                          '${_leaves.length} ${_t('total leaves', 'कुल छुट्टियाँ')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color:
                          isDark ? const Color(0xFF252540) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.refresh,
                        size: 20,
                        color: isDark ? Colors.white70 : Colors.grey[700],
                      ),
                      onPressed: _isLoading ? null : _fetchLeaves,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _showCreateLeaveDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(_t('Take Leave', 'छुट्टी लें')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child:
                  _isLoading
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: primaryColor),
                            const SizedBox(height: 16),
                            Text(
                              _t(
                                'Loading leaves...',
                                'छुट्टियाँ लोड हो रही हैं...',
                              ),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                      : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildSection(
                              _t('Active', 'सक्रिय'),
                              _getLeavesByStatus('current'),
                              Icons.timelapse,
                            ),
                            const SizedBox(height: 16),
                            _buildSection(
                              _t('Upcoming', 'आगामी'),
                              _getLeavesByStatus('future'),
                              Icons.event_available,
                            ),
                            const SizedBox(height: 16),
                            _buildSection(
                              _t('Completed', 'पूर्ण'),
                              _getLeavesByStatus('past'),
                              Icons.check_circle,
                            ),
                            if (_getLeavesByStatus('cancelled').isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildSection(
                                _t('Cancelled', 'रद्द'),
                                _getLeavesByStatus('cancelled'),
                                Icons.cancel,
                              ),
                            ],
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

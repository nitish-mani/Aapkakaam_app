import 'dart:convert';
import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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
    // Parse UTC dates and convert to IST (UTC+5:30)
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      try {
        DateTime utcDate = DateTime.parse(value.toString());
        // Convert to IST (Asia/Kolkata) - Add 5 hours 30 minutes
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

  @override
  void initState() {
    super.initState();
    _fetchLeaves();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
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
        _showMessage('Failed to load leaves', Colors.red);
      }
    } catch (e) {
      _showMessage('Error loading leaves', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelLeave(String leaveId) async {
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
          .delete(
            Uri.parse("${KConstantURL.url}/vendor/cancelLeave/$leaveId"),
            headers: {
              'Authorization': token,
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        _showMessage('Leave cancelled successfully', Colors.green);
        await _fetchLeaves();
      } else {
        try {
          final errorData = jsonDecode(response.body);
          _showMessage(
            errorData['message'] ?? 'Failed to cancel leave',
            Colors.red,
          );
        } catch (e) {
          _showMessage('Failed to cancel leave', Colors.red);
        }
      }
    } catch (e) {
      _showMessage('Error cancelling leave', Colors.red);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _createLeave(DateTime from, DateTime to, String? reason) async {
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
        _showMessage('Leave created successfully! 🎉', Colors.green);
        await _fetchLeaves();
      } else {
        try {
          final errorData = jsonDecode(response.body);
          _showMessage(
            errorData['message'] ?? 'Failed to process request',
            Colors.red,
          );
        } catch (e) {
          _showMessage('Failed to process request', Colors.red);
        }
      }
    } catch (e) {
      _showMessage('Error creating leave', Colors.red);
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
    return DateFormat('d MMMM yyyy').format(date);
  }

  String _formatShortDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'current':
        return 'Active';
      case 'future':
        return 'Upcoming';
      case 'past':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Completed';
    }
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
    DateTime? fromDate;
    DateTime? toDate;
    String? reason;
    final TextEditingController reasonController = TextEditingController();

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
                backgroundColor: isDark ? Colors.grey[850] : Colors.white,
                elevation: 24,
                child: Container(
                  padding: const EdgeInsets.all(28),
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
                                    Colors.green.shade400,
                                    Colors.green.shade700,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.beach_access,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Request Leave',
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
                                    'Plan your time off',
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

                        const SizedBox(height: 24),

                        // From Date
                        _buildDatePickerField(
                          label: 'Start Date',
                          value: fromDate,
                          icon: Icons.calendar_today,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: fromDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: Colors.green.shade600,
                                      onPrimary: Colors.white,
                                      onSurface: Colors.black87,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
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
                        ),

                        const SizedBox(height: 16),

                        // To Date
                        _buildDatePickerField(
                          label: 'End Date',
                          value: toDate,
                          icon: Icons.calendar_today,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: toDate ?? fromDate ?? DateTime.now(),
                              firstDate: fromDate ?? DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: Colors.green.shade600,
                                      onPrimary: Colors.white,
                                      onSurface: Colors.black87,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setStateDialog(() {
                                toDate = picked;
                              });
                            }
                          },
                          isDark: isDark,
                        ),

                        const SizedBox(height: 16),

                        // Reason
                        Text(
                          'Reason (Optional)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  isDark
                                      ? Colors.grey[700]!
                                      : Colors.grey[200]!,
                            ),
                          ),
                          child: TextField(
                            controller: reasonController,
                            decoration: InputDecoration(
                              hintText: 'Brief reason for leave...',
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

                        const SizedBox(height: 24),

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
                                  'Cancel',
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
                                      'Please select a start date',
                                      Colors.orange,
                                    );
                                    return;
                                  }
                                  if (toDate == null) {
                                    _showMessage(
                                      'Please select an end date',
                                      Colors.orange,
                                    );
                                    return;
                                  }
                                  if (toDate!.isBefore(fromDate!)) {
                                    _showMessage(
                                      'End date must be after start date',
                                      Colors.orange,
                                    );
                                    return;
                                  }

                                  Navigator.pop(context);
                                  _createLeave(fromDate!, toDate!, reason);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 2,
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
                                        : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              'Confirm Leave',
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

  Widget _buildDatePickerField({
    required String label,
    required DateTime? value,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    value != null
                        ? Colors.green.shade300
                        : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
                width: value != null ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color:
                      value != null
                          ? Colors.green.shade600
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value != null ? _formatDate(value) : 'Select $label',
                    style: TextStyle(
                      color:
                          value != null
                              ? (isDark ? Colors.white : Colors.black87)
                              : (isDark ? Colors.grey[500] : Colors.grey[400]),
                      fontWeight:
                          value != null ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
                if (value != null)
                  Icon(
                    Icons.check_circle,
                    size: 18,
                    color: Colors.green.shade600,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCancelConfirmation(Leave leave) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            backgroundColor: isDark ? Colors.grey[850] : Colors.white,
            elevation: 24,
            child: Container(
              padding: const EdgeInsets.all(28),
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
                  const SizedBox(height: 20),
                  Text(
                    'Cancel Leave',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Are you sure you want to cancel this leave request?',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors:
                            isDark
                                ? [Colors.grey[800]!, Colors.grey[700]!]
                                : [Colors.grey[50]!, Colors.grey[100]!],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_note,
                          size: 18,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _formatShortDate(leave.from),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                          ),
                        ),
                        Text(
                          _formatShortDate(leave.to),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
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
                        color: isDark ? Colors.grey[800] : Colors.grey[50],
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
                          'This action cannot be undone',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
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
                            'Keep It',
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
                            elevation: 2,
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
                                  : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.delete_outline, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Yes, Cancel',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDark
                  ? [const Color(0xFF1E1E1E), const Color(0xFF2A2A2A)]
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
                                        ? Colors.grey[800]
                                        : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      _formatDate(leave.from),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            isDark
                                                ? Colors.white
                                                : Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: true,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward_ios,
                                      size: 10,
                                      color:
                                          isDark
                                              ? Colors.grey[500]
                                              : Colors.grey[400],
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      _formatDate(leave.to),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            isDark
                                                ? Colors.white
                                                : Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: true,
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
                                          ? Colors.grey[800]
                                          : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        isDark
                                            ? Colors.grey[700]!
                                            : Colors.grey[200]!,
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
                            color: isDark ? Colors.grey[800] : Colors.grey[50],
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
                            tooltip: 'Cancel Leave',
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
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
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
                              'Created: ${DateFormat('dd MMM, yyyy').format(leave.createdAt)}',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
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
                        ? [Colors.grey[850]!, Colors.grey[800]!]
                        : [Colors.grey[50]!, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
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
                    'No $title leaves',
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

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
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
                        colors: [Colors.green.shade400, Colors.green.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.beach_access,
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
                          'Leave Management',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          '${_leaves.length} total leaves',
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
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
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
                    label: const Text('Take Leave'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
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
                      ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Loading leaves...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                      : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildSection(
                              'Active',
                              _getLeavesByStatus('current'),
                              Icons.timelapse,
                            ),
                            const SizedBox(height: 16),
                            _buildSection(
                              'Upcoming',
                              _getLeavesByStatus('future'),
                              Icons.event_available,
                            ),
                            const SizedBox(height: 16),
                            _buildSection(
                              'Completed',
                              _getLeavesByStatus('past'),
                              Icons.check_circle,
                            ),
                            if (_getLeavesByStatus('cancelled').isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildSection(
                                'Cancelled',
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

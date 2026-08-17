import 'dart:convert';
import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Concern {
  final String id;
  final String category;
  final String subject;
  final String description;
  final String priority;
  final String status;
  final String? adminResponse;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  Concern({
    required this.id,
    required this.category,
    required this.subject,
    required this.description,
    required this.priority,
    required this.status,
    this.adminResponse,
    required this.createdAt,
    this.resolvedAt,
  });

  factory Concern.fromJson(Map<String, dynamic> json) {
    // Parse UTC date and convert to IST (UTC+5:30)
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      try {
        // Parse the UTC date from server
        DateTime utcDate = DateTime.parse(value.toString());
        // Convert to IST (Asia/Kolkata) - Add 5 hours 30 minutes
        return utcDate.add(const Duration(hours: 5, minutes: 30));
      } catch (e) {
        return DateTime.now();
      }
    }

    return Concern(
      id: json['_id']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'Medium',
      status: json['status']?.toString() ?? 'Open',
      adminResponse: json['adminResponse']?.toString(),
      createdAt: parseDate(json['createdAt']),
      resolvedAt:
          json['resolvedAt'] != null ? parseDate(json['resolvedAt']) : null,
    );
  }
}

class ConcernsPage extends StatefulWidget {
  const ConcernsPage({super.key});

  @override
  State<ConcernsPage> createState() => _ConcernsPageState();
}

class _ConcernsPageState extends State<ConcernsPage>
    with SingleTickerProviderStateMixin {
  List<Concern> _concerns = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  Concern? _selectedConcern;

  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedCategory = '';
  String _selectedPriority = 'Medium';
  String _searchQuery = '';
  String _selectedStatus = 'All';

  final List<String> _categories = [
    'Payment',
    'Booking',
    'Service',
    'Vendor',
    'User',
    'Cancellation',
    'Refund',
    'Technical',
    'Other',
  ];

  final List<String> _priorities = ['Low', 'Medium', 'High', 'Critical'];
  final List<String> _statuses = [
    'All',
    'Open',
    'InProgress',
    'Resolved',
    'Rejected',
    'Closed',
  ];

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _fetchConcerns();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchConcerns() async {
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
            Uri.parse("${KConstantURL.url}/concerns"),
            headers: {
              'Authorization': token,
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final concernsList = data['concerns'] as List? ?? [];
          setState(() {
            _concerns =
                concernsList.map((item) => Concern.fromJson(item)).toList();
          });
        }
      } else {
        _showMessage('Failed to load concerns', Colors.red);
      }
    } catch (e) {
      _showMessage('Error loading concerns', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitConcern() async {
    if (_selectedCategory.isEmpty) {
      _showMessage('Please select a category', Colors.orange);
      return;
    }
    if (_subjectController.text.trim().isEmpty) {
      _showMessage('Please enter a subject', Colors.orange);
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showMessage('Please enter a description', Colors.orange);
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
        return;
      }

      final decoded = jsonDecode(categoryData);
      final token = 'Bearer ${decoded['token']}';

      final response = await http
          .post(
            Uri.parse("${KConstantURL.url}/concerns"),
            headers: {
              'Authorization': token,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'category': _selectedCategory,
              'subject': _subjectController.text.trim(),
              'description': _descriptionController.text.trim(),
              'priority': _selectedPriority,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showMessage('Concern submitted successfully!', Colors.green);
        _subjectController.clear();
        _descriptionController.clear();
        _selectedCategory = '';
        _selectedPriority = 'Medium';
        _animationController.reverse();
        await _fetchConcerns();
      } else {
        _showMessage('Failed to submit concern', Colors.red);
      }
    } catch (e) {
      _showMessage('Error submitting concern', Colors.red);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Format date to IST
  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  // Format time to IST (12-hour format with AM/PM)
  String _getTime(DateTime date) {
    // Convert to IST if not already
    final istDate = date;
    final hour = istDate.hour;
    final minute = istDate.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $ampm';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Open':
        return Colors.blue;
      case 'InProgress':
        return Colors.orange;
      case 'Resolved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Closed':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Low':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'High':
        return Colors.red.shade400;
      case 'Critical':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  List<Concern> get _filteredConcerns {
    return _concerns.where((concern) {
      final matchSearch =
          concern.subject.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          concern.description.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      final matchStatus =
          _selectedStatus == 'All' || concern.status == _selectedStatus;
      return matchSearch && matchStatus;
    }).toList();
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
            _buildHeader(isDark),

            // Stats Row
            _buildStatsRow(isDark),

            // Search & Filter
            _buildSearchBar(isDark),

            // Main Content
            Expanded(
              child:
                  _isLoading
                      ? _buildLoadingState()
                      : _filteredConcerns.isEmpty
                      ? _buildEmptyState(isDark)
                      : _buildConcernsList(isDark),
            ),
          ],
        ),
      ),

      // Floating Action Button
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDark
                  ? [Colors.grey[850]!, Colors.grey[900]!]
                  : [Colors.white, Colors.grey[50]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
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
                colors: [Colors.amber.shade400, Colors.orange.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('🎫', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Concerns',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  '${_concerns.length} total • ${_concerns.where((c) => c.status == 'Open' || c.status == 'InProgress').length} active',
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
              onPressed: _isLoading ? null : _fetchConcerns,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    final pending =
        _concerns
            .where((c) => c.status == 'Open' || c.status == 'InProgress')
            .length;
    final resolved = _concerns.where((c) => c.status == 'Resolved').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildStatCard('Total', _concerns.length, Colors.blue, isDark),
          const SizedBox(width: 8),
          _buildStatCard('Pending', pending, Colors.orange, isDark),
          const SizedBox(width: 8),
          _buildStatCard('Resolved', resolved, Colors.green, isDark),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search concerns...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStatus,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 13,
                ),
                dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                items:
                    _statuses.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                onChanged: (value) => setState(() => _selectedStatus = value!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 3, color: Colors.blue),
          SizedBox(height: 16),
          Text(
            'Loading concerns...',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Text('📭', style: TextStyle(fontSize: 40)),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty && _selectedStatus == 'All'
                  ? 'No concerns yet'
                  : 'No matching concerns',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty && _selectedStatus == 'All'
                  ? 'Submit your first concern to get started'
                  : 'Try adjusting your search or filters',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty || _selectedStatus != 'All') ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _selectedStatus = 'All';
                  });
                },
                child: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConcernsList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredConcerns.length,
      itemBuilder: (context, index) {
        final concern = _filteredConcerns[index];
        return _buildConcernCard(concern, isDark);
      },
    );
  }

  Widget _buildConcernCard(Concern concern, bool isDark) {
    final statusColor = _getStatusColor(concern.status);
    final priorityColor = _getPriorityColor(concern.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status & Category
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
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
                    const SizedBox(width: 4),
                    Text(
                      concern.status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  concern.category,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              const Spacer(),
              // Show IST time
              Text(
                '${_formatDate(concern.createdAt)} • ${_getTime(concern.createdAt)}',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Subject
          Text(
            concern.subject,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),

          const SizedBox(height: 6),

          // Description
          Text(
            concern.description.length > 100
                ? '${concern.description.substring(0, 100)}...'
                : concern.description,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              height: 1.4,
            ),
          ),

          const SizedBox(height: 12),

          // Priority & Time
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  concern.priority,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: priorityColor,
                  ),
                ),
              ),
            ],
          ),

          // Admin Response
          if (concern.adminResponse != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.green.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Text('💬', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Response',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                        Text(
                          concern.adminResponse!.length > 50
                              ? '${concern.adminResponse!.substring(0, 50)}...'
                              : concern.adminResponse!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // View Details Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showDetailDialog(concern, isDark),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text(
                'View Details',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.grey[700],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(Concern concern, bool isDark) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: isDark ? Colors.grey[850] : Colors.white,
            child: Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(
                maxWidth: 400,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              concern.subject,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      concern.status,
                                    ).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    concern.status,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: _getStatusColor(concern.status),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_formatDate(concern.createdAt)} • ${_getTime(concern.createdAt)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: isDark ? Colors.white70 : Colors.grey[600],
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  const Divider(height: 20),

                  // Category & Priority
                  Row(
                    children: [
                      _buildDetailChip(
                        'Category',
                        concern.category,
                        Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      _buildDetailChip(
                        'Priority',
                        concern.priority,
                        _getPriorityColor(concern.priority),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      concern.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),

                  if (concern.adminResponse != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Admin Response',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isDark
                                  ? Colors.grey[700]!
                                  : Colors.green.shade200,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        concern.adminResponse!,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Close Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDetailChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        _showNewConcernDialog();
      },
      icon: const Icon(Icons.add),
      label: const Text('New Concern'),
      backgroundColor: Colors.blue.shade600,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  void _showNewConcernDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String category = '';
    String priority = 'Medium';
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setStateDialog) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: isDark ? Colors.grey[850] : Colors.white,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  constraints: BoxConstraints(
                    maxWidth: 400,
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'New Concern',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color:
                                    isDark ? Colors.white70 : Colors.grey[600],
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Category
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Category *',
                            labelStyle: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    isDark
                                        ? Colors.grey[700]!
                                        : Colors.grey[300]!,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          value: category.isEmpty ? null : category,
                          hint: const Text('Select Category'),
                          items:
                              _categories.map((cat) {
                                return DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat),
                                );
                              }).toList(),
                          onChanged:
                              (value) =>
                                  setStateDialog(() => category = value!),
                        ),

                        const SizedBox(height: 12),

                        // Priority
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Priority *',
                            labelStyle: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    isDark
                                        ? Colors.grey[700]!
                                        : Colors.grey[300]!,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          value: priority,
                          items:
                              _priorities.map((pri) {
                                return DropdownMenuItem(
                                  value: pri,
                                  child: Text(pri),
                                );
                              }).toList(),
                          onChanged:
                              (value) =>
                                  setStateDialog(() => priority = value!),
                        ),

                        const SizedBox(height: 12),

                        // Subject
                        TextField(
                          controller: subjectController,
                          decoration: InputDecoration(
                            labelText: 'Subject *',
                            labelStyle: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    isDark
                                        ? Colors.grey[700]!
                                        : Colors.grey[300]!,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLength: 200,
                        ),

                        const SizedBox(height: 12),

                        // Description
                        TextField(
                          controller: descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Description *',
                            labelStyle: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    isDark
                                        ? Colors.grey[700]!
                                        : Colors.grey[300]!,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            alignLabelWithHint: true,
                          ),
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 4,
                          maxLength: 5000,
                        ),

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color:
                                          isDark
                                              ? Colors.grey[600]!
                                              : Colors.grey[300]!,
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
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    _isSubmitting
                                        ? null
                                        : () async {
                                          if (category.isEmpty) {
                                            _showMessage(
                                              'Please select a category',
                                              Colors.orange,
                                            );
                                            return;
                                          }
                                          if (subjectController.text
                                              .trim()
                                              .isEmpty) {
                                            _showMessage(
                                              'Please enter a subject',
                                              Colors.orange,
                                            );
                                            return;
                                          }
                                          if (descriptionController.text
                                              .trim()
                                              .isEmpty) {
                                            _showMessage(
                                              'Please enter a description',
                                              Colors.orange,
                                            );
                                            return;
                                          }

                                          setState(() => _isSubmitting = true);

                                          try {
                                            final prefs =
                                                await SharedPreferences.getInstance();
                                            final isVendor1 = isVendor.value;
                                            final cat =
                                                isVendor1 ? 'vendor' : 'user';
                                            final categoryData = prefs
                                                .getString(cat);

                                            if (categoryData == null) {
                                              setState(
                                                () => _isSubmitting = false,
                                              );
                                              return;
                                            }

                                            final decoded = jsonDecode(
                                              categoryData,
                                            );
                                            final token =
                                                'Bearer ${decoded['token']}';

                                            final response = await http
                                                .post(
                                                  Uri.parse(
                                                    "${KConstantURL.url}/concerns",
                                                  ),
                                                  headers: {
                                                    'Authorization': token,
                                                    'Content-Type':
                                                        'application/json',
                                                  },
                                                  body: jsonEncode({
                                                    'category': category,
                                                    'subject':
                                                        subjectController.text
                                                            .trim(),
                                                    'description':
                                                        descriptionController
                                                            .text
                                                            .trim(),
                                                    'priority': priority,
                                                  }),
                                                )
                                                .timeout(
                                                  const Duration(seconds: 15),
                                                );

                                            if (response.statusCode == 200 ||
                                                response.statusCode == 201) {
                                              _showMessage(
                                                'Concern submitted successfully!',
                                                Colors.green,
                                              );
                                              Navigator.pop(context);
                                              await _fetchConcerns();
                                            } else {
                                              _showMessage(
                                                'Failed to submit concern',
                                                Colors.red,
                                              );
                                            }
                                          } catch (e) {
                                            _showMessage(
                                              'Error submitting concern',
                                              Colors.red,
                                            );
                                          } finally {
                                            setState(
                                              () => _isSubmitting = false,
                                            );
                                          }
                                        },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child:
                                    _isSubmitting
                                        ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                        : const Text(
                                          'Submit',
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
                ),
              );
            },
          ),
    );
  }
}

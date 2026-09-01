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
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      try {
        DateTime utcDate = DateTime.parse(value.toString());
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

  final List<Map<String, String>> _categories = [
    {'en': 'Payment', 'hi': 'भुगतान'},
    {'en': 'Booking', 'hi': 'बुकिंग'},
    {'en': 'Service', 'hi': 'सेवा'},
    {'en': 'Vendor', 'hi': 'विक्रेता'},
    {'en': 'User', 'hi': 'उपयोगकर्ता'},
    {'en': 'Cancellation', 'hi': 'रद्दीकरण'},
    {'en': 'Refund', 'hi': 'वापसी'},
    {'en': 'Technical', 'hi': 'तकनीकी'},
    {'en': 'Other', 'hi': 'अन्य'},
  ];

  final List<Map<String, String>> _priorities = [
    {'en': 'Low', 'hi': 'कम'},
    {'en': 'Medium', 'hi': 'मध्यम'},
    {'en': 'High', 'hi': 'उच्च'},
    {'en': 'Critical', 'hi': 'गंभीर'},
  ];

  final List<Map<String, String>> _statuses = [
    {'en': 'All', 'hi': 'सभी'},
    {'en': 'Open', 'hi': 'खुला'},
    {'en': 'InProgress', 'hi': 'प्रगति पर'},
    {'en': 'Resolved', 'hi': 'हल किया'},
    {'en': 'Rejected', 'hi': 'अस्वीकृत'},
    {'en': 'Closed', 'hi': 'बंद'},
  ];

  late AnimationController _animationController;

  String _t(String en, String hi) => isHindiNotifier.value ? hi : en;

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
        _showMessage(
          _t('Failed to load concerns', 'समस्याएँ लोड करने में विफल'),
          Colors.red,
        );
      }
    } catch (e) {
      _showMessage(
        _t('Error loading concerns', 'समस्याएँ लोड करने में त्रुटि'),
        Colors.red,
      );
    } finally {
      setState(() => _isLoading = false);
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

  String _formatDate(DateTime date) {
    final months =
        isHindiNotifier.value
            ? [
              'जन',
              'फर',
              'मार्च',
              'अप्रै',
              'मई',
              'जून',
              'जुल',
              'अग',
              'सित',
              'अक्टू',
              'नव',
              'दिस',
            ]
            : [
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

  String _getTime(DateTime date) {
    final istDate = date;
    final hour = istDate.hour;
    final minute = istDate.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $ampm';
  }

  String _getStatusDisplay(String status) {
    final map = {
      'Open': _t('Open', 'खुला'),
      'InProgress': _t('In Progress', 'प्रगति पर'),
      'Resolved': _t('Resolved', 'हल किया'),
      'Rejected': _t('Rejected', 'अस्वीकृत'),
      'Closed': _t('Closed', 'बंद'),
    };
    return map[status] ?? status;
  }

  String _getPriorityDisplay(String priority) {
    final map = {
      'Low': _t('Low', 'कम'),
      'Medium': _t('Medium', 'मध्यम'),
      'High': _t('High', 'उच्च'),
      'Critical': _t('Critical', 'गंभीर'),
    };
    return map[priority] ?? priority;
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final surface = colorScheme.surface;
    final onSurface = colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0B1020) : const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark, primaryColor, surface, onSurface),
            _buildStatsRow(isDark, primaryColor, surface, onSurface),
            _buildSearchBar(isDark, surface, onSurface, primaryColor),
            Expanded(
              child:
                  _isLoading
                      ? _buildLoadingState(primaryColor)
                      : _filteredConcerns.isEmpty
                      ? _buildEmptyState(isDark, onSurface)
                      : _buildConcernsList(
                        isDark,
                        surface,
                        onSurface,
                        primaryColor,
                      ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(primaryColor),
    );
  }

  Widget _buildHeader(
    bool isDark,
    Color primaryColor,
    Color surface,
    Color onSurface,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDark
                  ? [const Color(0xFF1A1A2E), const Color(0xFF0B1020)]
                  : [surface, const Color(0xFFF7F9FC)],
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
                colors: [primaryColor, primaryColor.withOpacity(0.7)],
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
                  _t('My Concerns', 'मेरी समस्याएँ'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : onSurface,
                  ),
                ),
                Text(
                  '${_concerns.length} ${_t('total', 'कुल')} • ${_concerns.where((c) => c.status == 'Open' || c.status == 'InProgress').length} ${_t('active', 'सक्रिय')}',
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

  Widget _buildStatsRow(
    bool isDark,
    Color primaryColor,
    Color surface,
    Color onSurface,
  ) {
    final pending =
        _concerns
            .where((c) => c.status == 'Open' || c.status == 'InProgress')
            .length;
    final resolved = _concerns.where((c) => c.status == 'Resolved').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildStatCard(
            _t('Total', 'कुल'),
            _concerns.length,
            primaryColor,
            isDark,
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            _t('Pending', 'लंबित'),
            pending,
            Colors.orange,
            isDark,
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            _t('Resolved', 'हल किया'),
            resolved,
            Colors.green,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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

  Widget _buildSearchBar(
    bool isDark,
    Color surface,
    Color onSurface,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              // padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isDark
                          ? Colors.white.withOpacity(0.06)
                          : const Color(0xFFE8ECF3),
                  width: 1,
                ),
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
                  hintText: _t('Search concerns...', 'समस्याएँ खोजें...'),
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
                  color: isDark ? Colors.white : onSurface,
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
              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isDark
                        ? Colors.white.withOpacity(0.06)
                        : const Color(0xFFE8ECF3),
                width: 1,
              ),
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
                  color: isDark ? Colors.white : onSurface,
                  fontSize: 13,
                ),
                dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                items:
                    _statuses.map((status) {
                      final display =
                          isHindiNotifier.value ? status['hi']! : status['en']!;
                      return DropdownMenuItem(
                        value: status['en'],
                        child: Text(display),
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

  Widget _buildLoadingState(Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 3, color: primaryColor),
          const SizedBox(height: 16),
          Text(
            _t('Loading concerns...', 'समस्याएँ लोड हो रही हैं...'),
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color onSurface) {
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
                  ? _t('No concerns yet', 'अभी कोई समस्या नहीं')
                  : _t('No matching concerns', 'कोई मेल खाने वाली समस्या नहीं'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty && _selectedStatus == 'All'
                  ? _t(
                    'Submit your first concern to get started',
                    'शुरू करने के लिए अपनी पहली समस्या सबमिट करें',
                  )
                  : _t(
                    'Try adjusting your search or filters',
                    'अपनी खोज या फ़िल्टर समायोजित करें',
                  ),
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
                child: Text(_t('Clear Filters', 'फ़िल्टर साफ़ करें')),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConcernsList(
    bool isDark,
    Color surface,
    Color onSurface,
    Color primaryColor,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredConcerns.length,
      itemBuilder: (context, index) {
        final concern = _filteredConcerns[index];
        return _buildConcernCard(
          concern,
          isDark,
          surface,
          onSurface,
          primaryColor,
        );
      },
    );
  }

  Widget _buildConcernCard(
    Concern concern,
    bool isDark,
    Color surface,
    Color onSurface,
    Color primaryColor,
  ) {
    final statusColor = _getStatusColor(concern.status);
    final priorityColor = _getPriorityColor(concern.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE8ECF3),
          width: 1,
        ),
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
                      _getStatusDisplay(concern.status),
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
                  color: primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isHindiNotifier.value
                      ? _categories.firstWhere(
                        (c) => c['en'] == concern.category,
                      )['hi']!
                      : concern.category,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
              const Spacer(),
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
              color: isDark ? Colors.white : onSurface,
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

          // Priority
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
                  _getPriorityDisplay(concern.priority),
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
                          _t('Admin Response', 'प्रशासक उत्तर'),
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
              onPressed:
                  () => _showDetailDialog(
                    concern,
                    isDark,
                    surface,
                    onSurface,
                    primaryColor,
                  ),
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
                _t('View Details', 'विवरण देखें'),
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

  void _showDetailDialog(
    Concern concern,
    bool isDark,
    Color surface,
    Color onSurface,
    Color primaryColor,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
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
                                color: isDark ? Colors.white : onSurface,
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
                                    _getStatusDisplay(concern.status),
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
                        _t('Category', 'श्रेणी'),
                        isHindiNotifier.value
                            ? _categories.firstWhere(
                              (c) => c['en'] == concern.category,
                            )['hi']!
                            : concern.category,
                        Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      _buildDetailChip(
                        _t('Priority', 'प्राथमिकता'),
                        _getPriorityDisplay(concern.priority),
                        _getPriorityColor(concern.priority),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Description
                  Text(
                    _t('Description', 'विवरण'),
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
                        color: isDark ? Colors.white : onSurface,
                        height: 1.5,
                      ),
                    ),
                  ),

                  if (concern.adminResponse != null &&
                      concern.adminResponse!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      _t('Admin Response', 'प्रशासक उत्तर'),
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
                          color: isDark ? Colors.white : onSurface,
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
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(_t('Close', 'बंद करें')),
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

  Widget _buildFAB(Color primaryColor) {
    return FloatingActionButton.extended(
      onPressed: () => _showNewConcernDialog(),
      icon: const Icon(Icons.add),
      label: Text(_t('New Concern', 'नई समस्या')),
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  void _showNewConcernDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final surface = colorScheme.surface;
    final onSurface = colorScheme.onSurface;

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
                backgroundColor:
                    isDark ? const Color(0xFF1A1A2E) : Colors.white,
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
                                _t('New Concern', 'नई समस्या'),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : onSurface,
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
                            labelText: _t('Category *', 'श्रेणी *'),
                            labelStyle: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    isDark
                                        ? Colors.grey[700]!
                                        : Colors.grey[300]!,
                              ),
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
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          value: category.isEmpty ? null : category,
                          hint: Text(_t('Select Category', 'श्रेणी चुनें')),
                          items:
                              _categories.map((cat) {
                                final display =
                                    isHindiNotifier.value
                                        ? cat['hi']!
                                        : cat['en']!;
                                return DropdownMenuItem(
                                  value: cat['en'],
                                  child: Text(display),
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
                            labelText: _t('Priority *', 'प्राथमिकता *'),
                            labelStyle: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    isDark
                                        ? Colors.grey[700]!
                                        : Colors.grey[300]!,
                              ),
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
                              borderSide: BorderSide(
                                color: primaryColor,
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
                                final display =
                                    isHindiNotifier.value
                                        ? pri['hi']!
                                        : pri['en']!;
                                return DropdownMenuItem(
                                  value: pri['en'],
                                  child: Text(display),
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
                            labelText: _t('Subject *', 'विषय *'),
                            labelStyle: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    isDark
                                        ? Colors.grey[700]!
                                        : Colors.grey[300]!,
                              ),
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
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          style: TextStyle(
                            color: isDark ? Colors.white : onSurface,
                          ),
                          maxLength: 200,
                        ),

                        const SizedBox(height: 12),

                        // Description
                        TextField(
                          controller: descriptionController,
                          decoration: InputDecoration(
                            labelText: _t('Description *', 'विवरण *'),
                            labelStyle: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color:
                                    isDark
                                        ? Colors.grey[700]!
                                        : Colors.grey[300]!,
                              ),
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
                              borderSide: BorderSide(
                                color: primaryColor,
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
                            color: isDark ? Colors.white : onSurface,
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
                                  _t('Cancel', 'रद्द करें'),
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
                                              _t(
                                                'Please select a category',
                                                'कृपया एक श्रेणी चुनें',
                                              ),
                                              Colors.orange,
                                            );
                                            return;
                                          }
                                          if (subjectController.text
                                              .trim()
                                              .isEmpty) {
                                            _showMessage(
                                              _t(
                                                'Please enter a subject',
                                                'कृपया एक विषय दर्ज करें',
                                              ),
                                              Colors.orange,
                                            );
                                            return;
                                          }
                                          if (descriptionController.text
                                              .trim()
                                              .isEmpty) {
                                            _showMessage(
                                              _t(
                                                'Please enter a description',
                                                'कृपया एक विवरण दर्ज करें',
                                              ),
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
                                                _t(
                                                  'Concern submitted successfully!',
                                                  'समस्या सफलतापूर्वक सबमिट की गई!',
                                                ),
                                                primaryColor,
                                              );
                                              Navigator.pop(context);
                                              await _fetchConcerns();
                                            } else {
                                              _showMessage(
                                                _t(
                                                  'Failed to submit concern',
                                                  'समस्या सबमिट करने में विफल',
                                                ),
                                                Colors.red,
                                              );
                                            }
                                          } catch (e) {
                                            _showMessage(
                                              _t(
                                                'Error submitting concern',
                                                'समस्या सबमिट करने में त्रुटि',
                                              ),
                                              Colors.red,
                                            );
                                          } finally {
                                            setState(
                                              () => _isSubmitting = false,
                                            );
                                          }
                                        },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child:
                                    _isSubmitting
                                        ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                        : Text(
                                          _t('Submit', 'सबमिट करें'),
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

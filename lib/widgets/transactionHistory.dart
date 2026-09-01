import 'dart:convert';
import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TransactionStatsPage extends StatefulWidget {
  const TransactionStatsPage({super.key});

  @override
  _TransactionStatsPageState createState() => _TransactionStatsPageState();
}

class _TransactionStatsPageState extends State<TransactionStatsPage> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;
  String _timeRange = 'all';

  final List<String> _timeRanges = ['all', 'week', 'month', 'year'];
  final Map<String, String> _timeRangeLabels = {
    'all': 'All Time',
    'week': 'This Week',
    'month': 'This Month',
    'year': 'This Year',
  };
  final Map<String, String> _timeRangeLabelsHi = {
    'all': 'सभी समय',
    'week': 'इस सप्ताह',
    'month': 'इस महीने',
    'year': 'इस वर्ष',
  };

  // Language helper
  String _t(String en, String hi) => isHindiNotifier.value ? hi : en;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final isVendor1 = isVendor.value;
      final category = isVendor1 ? 'vendor' : 'user';
      final categoryData = prefs.getString(category);

      if (categoryData == null) {
        setState(() {
          _error = _t('User data not found', 'उपयोगकर्ता डेटा नहीं मिला');
          _isLoading = false;
        });
        return;
      }

      final decoded = jsonDecode(categoryData);
      final token = 'Bearer ${decoded['token']}';

      final response = await http.get(
        Uri.parse(
          "${KConstantURL.url}/payment/transactions/stats?range=$_timeRange",
        ),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _stats = data;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error =
                data['message'] ??
                _t('Failed to fetch stats', 'आँकड़े प्राप्त करने में विफल');
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = _t(
            'Failed to fetch transaction stats',
            'लेन-देन आँकड़े प्राप्त करने में विफल',
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = _t(
          'Error fetching transaction stats',
          'लेन-देन आँकड़े प्राप्त करने में त्रुटि',
        );
        _isLoading = false;
      });
    }
  }

  String _getStatusLabel(String? status) {
    if (status == null) return 'UNKNOWN';
    final isHindi = isHindiNotifier.value;
    final statusMap = {
      'completed': isHindi ? 'पूर्ण' : 'Completed',
      'pending': isHindi ? 'लंबित' : 'Pending',
      'initiated': isHindi ? 'शुरू' : 'Initiated',
      'failed': isHindi ? 'विफल' : 'Failed',
      'abandoned': isHindi ? 'छोड़ा' : 'Abandoned',
      'refunded': isHindi ? 'वापस' : 'Refunded',
    };
    return statusMap[status] ?? status.toUpperCase();
  }

  Color _getStatusColorValue(String? status) {
    if (status == null) return Colors.grey;
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'initiated':
        return Colors.blue;
      case 'failed':
        return Colors.red;
      case 'abandoned':
        return Colors.grey;
      case 'refunded':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusIcon(String? status) {
    if (status == null) return '❓';
    final iconMap = {
      'completed': '✅',
      'pending': '⏳',
      'initiated': '🔄',
      'failed': '❌',
      'abandoned': '🚫',
      'refunded': '↩️',
    };
    return iconMap[status] ?? '❓';
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
      appBar: AppBar(
        title: Text(
          _t('Transaction Statistics', 'लेन-देन आँकड़े'),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDark ? Colors.white : onSurface,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : surface,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : onSurface,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoading
              ? _buildLoadingState(primaryColor)
              : _error != null
              ? _buildErrorState(primaryColor)
              : _stats == null
              ? _buildEmptyState(isDark)
              : _buildContent(isDark, surface, onSurface, primaryColor),
    );
  }

  Widget _buildLoadingState(Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryColor),
          const SizedBox(height: 16),
          Text(
            _t(
              'Loading transaction stats...',
              'लेन-देन आँकड़े लोड हो रहे हैं...',
            ),
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchStats,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(_t('Retry', 'पुनः प्रयास करें')),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('Back', 'वापस')),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _t('No transaction data available', 'कोई लेन-देन डेटा उपलब्ध नहीं'),
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    bool isDark,
    Color surface,
    Color onSurface,
    Color primaryColor,
  ) {
    final summary = _stats?['summary'] as Map<String, dynamic>?;
    final statusStats = _stats?['stats'] as List? ?? [];
    final totalCount = summary?['total'] ?? 0;

    final filteredStatusStats =
        statusStats.where((stat) {
          return stat['_id'] != null;
        }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Filter
          _buildTimeFilter(isDark, surface, onSurface, primaryColor),

          const SizedBox(height: 20),

          // Summary Cards
          _buildSummaryCards(summary, totalCount, isDark, surface, onSurface),

          const SizedBox(height: 24),

          // Status Breakdown
          _buildStatusBreakdown(
            filteredStatusStats,
            totalCount,
            isDark,
            surface,
            onSurface,
          ),

          const SizedBox(height: 24),

          // Quick Stats
          _buildQuickStats(summary, totalCount, isDark, surface, onSurface),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTimeFilter(
    bool isDark,
    Color surface,
    Color onSurface,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE8ECF3),
          width: 1,
        ),
      ),
      child: Row(
        children:
            _timeRanges.map((range) {
              final isSelected = _timeRange == range;
              final label =
                  isHindiNotifier.value
                      ? _timeRangeLabelsHi[range]!
                      : _timeRangeLabels[range]!;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _timeRange = range;
                    });
                    _fetchStats();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? (isDark
                                  ? const Color(0xFF2A2A3E)
                                  : Colors.white)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                              : null,
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color:
                              isSelected
                                  ? primaryColor
                                  : (isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600]),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildSummaryCards(
    Map<String, dynamic>? summary,
    int totalCount,
    bool isDark,
    Color surface,
    Color onSurface,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          '📊',
          _t('Total Transactions', 'कुल लेन-देन'),
          (summary?['total'] ?? 0).toString(),
          Colors.blue,
          isDark,
        ),
        _buildStatCard(
          '✅',
          _t('Successful', 'सफल'),
          (summary?['completed'] ?? 0).toString(),
          Colors.green,
          isDark,
          subtitle:
              '${summary?['conversionRate'] ?? 0}% ${_t('conversion', 'रूपांतरण')}',
        ),
        _buildStatCard(
          '💰',
          _t('Total Recharge', 'कुल रिचार्ज'),
          '₹${summary?['totalRevenue'] ?? 0}',
          Colors.purple,
          isDark,
        ),
        _buildStatCard(
          '🏷️',
          _t('Total Discount', 'कुल छूट'),
          '₹${summary?['totalDiscountGiven'] ?? 0}',
          Colors.orange,
          isDark,
        ),
        _buildStatCard(
          '🚫',
          _t('Abandoned', 'छोड़ा गया'),
          (summary?['abandoned'] ?? 0).toString(),
          Colors.grey,
          isDark,
          subtitle:
              totalCount > 0
                  ? '${((summary?['abandoned'] ?? 0) / totalCount * 100).toStringAsFixed(1)}% ${_t('abandoned', 'छोड़ा')}'
                  : '0% ${_t('abandoned', 'छोड़ा')}',
        ),
        _buildStatCard(
          '❌',
          _t('Failed', 'विफल'),
          (summary?['failed'] ?? 0).toString(),
          Colors.red,
          isDark,
          subtitle:
              totalCount > 0
                  ? '${((summary?['failed'] ?? 0) / totalCount * 100).toStringAsFixed(1)}% ${_t('failed', 'विफल')}'
                  : '0% ${_t('failed', 'विफल')}',
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String icon,
    String label,
    String value,
    Color color,
    bool isDark, {
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBreakdown(
    List<dynamic> statusStats,
    int totalCount,
    bool isDark,
    Color surface,
    Color onSurface,
  ) {
    return Container(
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
          Text(
            _t('Status Breakdown', 'स्थिति विवरण'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : onSurface,
            ),
          ),
          const SizedBox(height: 12),
          if (statusStats.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _t(
                    'No transaction status data available',
                    'कोई लेन-देन स्थिति डेटा उपलब्ध नहीं',
                  ),
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
            )
          else
            Column(
              children:
                  statusStats.map((stat) {
                    final status = stat['_id'] ?? 'unknown';
                    final count = stat['count'] ?? 0;
                    final percentage =
                        totalCount > 0 ? (count / totalCount) * 100 : 0;
                    final statusColor = _getStatusColorValue(status);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      _getStatusIcon(status),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _getStatusLabel(status),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            isDark ? Colors.white : onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '$count ${_t('transactions', 'लेन-देन')} (${percentage.toStringAsFixed(1)}%)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor:
                                  isDark ? Colors.grey[700] : Colors.grey[200],
                              color: statusColor,
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_t('Amount', 'राशि')}: ₹${stat['totalAmount'] ?? 0}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      isDark
                                          ? Colors.grey[500]
                                          : Colors.grey[500],
                                ),
                              ),
                              Text(
                                '${_t('Discount', 'छूट')}: ₹${stat['totalDiscount'] ?? 0}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      isDark
                                          ? Colors.grey[500]
                                          : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(
    Map<String, dynamic>? summary,
    int totalCount,
    bool isDark,
    Color surface,
    Color onSurface,
  ) {
    final avgTransaction =
        totalCount > 0 && (summary?['completed'] ?? 0) > 0
            ? ((summary?['totalRevenue'] ?? 0) / (summary?['completed'] ?? 1))
                .toInt()
            : 0;

    return Container(
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
          Text(
            _t('Quick Stats', 'त्वरित आँकड़े'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : onSurface,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _buildQuickStat(
                _t('Initiated', 'शुरू'),
                (summary?['initiated'] ?? 0).toString(),
                Colors.blue,
                isDark,
              ),
              _buildQuickStat(
                _t('Pending', 'लंबित'),
                (summary?['pending'] ?? 0).toString(),
                Colors.orange,
                isDark,
              ),
              _buildQuickStat(
                _t('Success Rate', 'सफलता दर'),
                '${summary?['conversionRate'] ?? 0}%',
                Colors.green,
                isDark,
              ),
              _buildQuickStat(
                _t('Avg. Transaction', 'औसत लेन-देन'),
                '₹$avgTransaction',
                Colors.purple,
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252540) : Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

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
          _error = 'User data not found';
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
            _error = data['message'] ?? 'Failed to fetch stats';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to fetch transaction stats';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching transaction stats';
        _isLoading = false;
      });
    }
  }

  String _getStatusLabel(String? status) {
    if (status == null) return 'UNKNOWN';
    final statusMap = {
      'completed': 'Completed',
      'pending': 'Pending',
      'initiated': 'Initiated',
      'failed': 'Failed',
      'abandoned': 'Abandoned',
      'refunded': 'Refunded',
    };
    return statusMap[status] ?? status.toUpperCase();
  }

  String _getStatusColor(String? status) {
    if (status == null) return 'unknown';
    final colorMap = {
      'completed': 'completed',
      'pending': 'pending',
      'initiated': 'initiated',
      'failed': 'failed',
      'abandoned': 'abandoned',
      'refunded': 'refunded',
    };
    return colorMap[status] ?? 'unknown';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Transaction Statistics',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: isDark ? Colors.grey[850] : Colors.white,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoading
              ? _buildLoadingState()
              : _error != null
              ? _buildErrorState()
              : _stats == null
              ? _buildEmptyState()
              : _buildContent(isDark),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading transaction stats...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
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
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Retry'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No transaction data available',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    final summary = _stats?['summary'] as Map<String, dynamic>?;
    final statusStats = _stats?['stats'] as List? ?? [];
    final totalCount = summary?['total'] ?? 0;

    // Filter out null/undefined statuses
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
          _buildTimeFilter(isDark),

          const SizedBox(height: 20),

          // Summary Cards
          _buildSummaryCards(summary, totalCount, isDark),

          const SizedBox(height: 24),

          // Status Breakdown
          _buildStatusBreakdown(filteredStatusStats, totalCount, isDark),

          const SizedBox(height: 24),

          // Quick Stats
          _buildQuickStats(summary, totalCount, isDark),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTimeFilter(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children:
            _timeRanges.map((range) {
              final isSelected = _timeRange == range;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _timeRange = range;
                    });
                    _fetchStats();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? (isDark ? Colors.grey[700] : Colors.white)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        _timeRangeLabels[range]!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color:
                              isSelected
                                  ? (isDark ? Colors.white : Colors.black87)
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
          'Total Transactions',
          (summary?['total'] ?? 0).toString(),
          Colors.blue,
          isDark,
        ),
        _buildStatCard(
          '✅',
          'Successful',
          (summary?['completed'] ?? 0).toString(),
          Colors.green,
          isDark,
          subtitle: '${summary?['conversionRate'] ?? 0}% conversion',
        ),
        _buildStatCard(
          '💰',
          'Total Recharge',
          '₹${summary?['totalRevenue'] ?? 0}',
          Colors.purple,
          isDark,
        ),
        _buildStatCard(
          '🏷️',
          'Total Discount',
          '₹${summary?['totalDiscountGiven'] ?? 0}',
          Colors.orange,
          isDark,
        ),
        _buildStatCard(
          '🚫',
          'Abandoned',
          (summary?['abandoned'] ?? 0).toString(),
          Colors.grey,
          isDark,
          subtitle:
              totalCount > 0
                  ? '${((summary?['abandoned'] ?? 0) / totalCount * 100).toStringAsFixed(1)}% abandoned'
                  : '0% abandoned',
        ),
        _buildStatCard(
          '❌',
          'Failed',
          (summary?['failed'] ?? 0).toString(),
          Colors.red,
          isDark,
          subtitle:
              totalCount > 0
                  ? '${((summary?['failed'] ?? 0) / totalCount * 100).toStringAsFixed(1)}% failed'
                  : '0% failed',
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
        color: isDark ? Colors.grey[850] : Colors.white,
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
  ) {
    return Container(
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
          Text(
            'Status Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          if (statusStats.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No transaction status data available',
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
                                            isDark
                                                ? Colors.white
                                                : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '$count transactions (${percentage.toStringAsFixed(1)}%)',
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
                                'Amount: ₹${stat['totalAmount'] ?? 0}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      isDark
                                          ? Colors.grey[500]
                                          : Colors.grey[500],
                                ),
                              ),
                              Text(
                                'Discount: ₹${stat['totalDiscount'] ?? 0}',
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
  ) {
    final avgTransaction =
        totalCount > 0 && (summary?['completed'] ?? 0) > 0
            ? ((summary?['totalRevenue'] ?? 0) / (summary?['completed'] ?? 1))
                .toInt()
            : 0;

    return Container(
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
          Text(
            'Quick Stats',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
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
                'Initiated',
                (summary?['initiated'] ?? 0).toString(),
                Colors.blue,
                isDark,
              ),
              _buildQuickStat(
                'Pending',
                (summary?['pending'] ?? 0).toString(),
                Colors.orange,
                isDark,
              ),
              _buildQuickStat(
                'Success Rate',
                '${summary?['conversionRate'] ?? 0}%',
                Colors.green,
                isDark,
              ),
              _buildQuickStat(
                'Avg. Transaction',
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
        color: isDark ? Colors.grey[800] : Colors.grey[50],
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

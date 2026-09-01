import 'dart:convert';
import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic> _earnings = {};
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Colors
  static const Color _primaryGradientStart = Color(0xFF4F46E5);
  static const Color _primaryGradientEnd = Color(0xFF7C3AED);
  static const Color _accentGreen = Color(0xFF22C55E);
  static const Color _accentOrange = Color(0xFFF59E0B);
  static const Color _accentRed = Color(0xFFEF4444);
  static const Color _accentBlue = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _fetchEarnings();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ============================================================
  // HINDI TRANSLATION HELPER
  // ============================================================

  String _t(String en, String hi) {
    return isHindiNotifier.value ? hi : en;
  }

  // ============================================================
  // FETCH EARNINGS
  // ============================================================

  Future<void> _fetchEarnings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final isVendor1 = isVendor.value;
      final category = isVendor1 ? 'vendor' : 'user';
      final categoryData = prefs.getString(category);

      if (categoryData == null) {
        setState(() {
          _errorMessage = 'User data not found';
          _isLoading = false;
        });
        return;
      }

      final decoded = jsonDecode(categoryData);
      final token = 'Bearer ${decoded['token']}';
      final userId = isVendor1 ? decoded['vendorId'] : decoded['userId'];

      final response = await http
          .get(
            Uri.parse("${KConstantURL.url}/$category/getEarnings/$userId"),
            headers: {
              'Authorization': token,
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _earnings = data;
          _isLoading = false;
        });
        _animationController.forward();
      } else {
        setState(() {
          _errorMessage = 'Failed to load earnings';
          _isLoading = false;
        });
        _showErrorSnackbar(
          context,
          _t('Something went wrong', 'कुछ गलत हो गया'),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: ${e.toString()}';
        _isLoading = false;
      });
      _showErrorSnackbar(context, _t('Something went wrong', 'कुछ गलत हो गया'));
    }
  }

  // ============================================================
  // WITHDRAWAL HANDLERS
  // ============================================================

  void _handleWithdraw() {
    final earning = (_earnings['earning'] ?? 0).toDouble();
    final shareCount = (_earnings['shareCount'] ?? 0).toInt();

    if (earning < 1000 || shareCount < 100) {
      _showErrorSnackbar(
        context,
        _t(
          'Minimum ₹1000 earning & 100 shares required',
          'न्यूनतम ₹1000 कमाई और 100 शेयर आवश्यक',
        ),
      );
      return;
    }

    _showWithdrawalDialog();
  }

  void _showWithdrawalDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final earning = (_earnings['earning'] ?? 0).toDouble();

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_accentGreen, _accentGreen.withOpacity(0.6)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _t('Withdraw Request', 'निकासी अनुरोध'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _t(
                      'You are about to withdraw ₹${earning.toStringAsFixed(2)}',
                      'आप ₹${earning.toStringAsFixed(2)} निकालने वाले हैं',
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey[200]!,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _t(
                            'Will be credited in 2-3 business days',
                            '2-3 कार्य दिवसों में जमा हो जाएगा',
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _accentGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _t('Processing', 'प्रसंस्करण'),
                            style: TextStyle(
                              fontSize: 10,
                              color: _accentGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor:
                                isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.grey[100],
                          ),
                          child: Text(
                            _t('Cancel', 'रद्द करें'),
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.grey[600],
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
                            _showSuccessSnackbar(
                              context,
                              _t(
                                'Withdrawal request submitted successfully!',
                                'निकासी अनुरोध सफलतापूर्वक सबमिट किया गया!',
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _t('Confirm', 'पुष्टि करें'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
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
  }

  // ============================================================
  // SNACKBARS
  // ============================================================

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _accentRed,
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
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
        backgroundColor: _primaryGradientEnd,
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  int _getTotalOrders() {
    final pending = _earnings['pendingShareBy'] ?? 0;
    final completed = _earnings['completedShareBy'] ?? 0;
    final canceled = _earnings['canceledShareBy'] ?? 0;
    return pending + completed + canceled;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isHindiNotifier,
      builder: (context, isHindi, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: isDarkThemeNotifier,
          builder: (context, isDarkTheme, _) {
            return _buildPage(
              context,
              isHindi: isHindi,
              isDarkTheme: isDarkTheme,
            );
          },
        );
      },
    );
  }

  Widget _buildPage(
    BuildContext context, {
    required bool isHindi,
    required bool isDarkTheme,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    final backgroundColor =
        isDarkTheme ? const Color(0xFF0B1020) : const Color(0xFFF0F2F8);
    final cardColor = isDarkTheme ? const Color(0xFF1A1A2E) : Colors.white;
    final textColor = isDarkTheme ? Colors.white : Colors.black87;
    // ✅ FIX: Use non-nullable Color
    final secondaryTextColor = isDarkTheme ? Colors.white60 : Colors.grey[600]!;
    final borderColor =
        isDarkTheme ? Colors.white.withOpacity(0.06) : Colors.grey[200]!;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          _t('Earnings', 'कमाई'),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: 0.3,
            color: textColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDarkTheme ? Colors.white : Colors.black87,

        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                isDarkTheme ? Colors.white.withOpacity(0.05) : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primaryGradientStart, _primaryGradientEnd],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _t('Loading earnings...', 'कमाई लोड हो रही है...'),
                      style: TextStyle(color: secondaryTextColor, fontSize: 14),
                    ),
                  ],
                ),
              )
              : FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Balance Card
                        _buildBalanceCard(
                          isDarkTheme,
                          isHindi,
                          isSmallScreen,
                          cardColor,
                          textColor,
                          secondaryTextColor,
                          borderColor,
                        ),

                        const SizedBox(height: 24),

                        // Stats Grid
                        _buildStatsGrid(
                          isDarkTheme,
                          isHindi,
                          isSmallScreen,
                          cardColor,
                          textColor,
                          secondaryTextColor,
                          borderColor,
                        ),

                        const SizedBox(height: 24),

                        // Withdraw Section
                        _buildWithdrawSection(
                          isDarkTheme,
                          isHindi,
                          isSmallScreen,
                          cardColor,
                          textColor,
                          secondaryTextColor,
                          borderColor,
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  // ============================================================
  // BALANCE CARD
  // ============================================================

  Widget _buildBalanceCard(
    bool isDarkTheme,
    bool isHindi,
    bool isSmallScreen,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    final earning = (_earnings['earning'] ?? 0).toDouble();
    final shareCount = (_earnings['shareCount'] ?? 0).toInt();
    final pending = _earnings['pendingShareBy'] ?? 0;
    final completed = _earnings['completedShareBy'] ?? 0;
    final canceled = _earnings['canceledShareBy'] ?? 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            _primaryGradientStart,
            _primaryGradientEnd,
            Color(0xFF6D28D9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF4F46E5).withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.wallet_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _t('Total Earnings', 'कुल कमाई'),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.share_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$shareCount ${_t('shares', 'शेयर')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${earning.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '.${(earning % 1).toStringAsFixed(2).split('.')[1]}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildMiniStat(_t('Pending', 'लंबित'), pending, Colors.white),
              _buildMiniDivider(),
              _buildMiniStat(_t('Completed', 'पूर्ण'), completed, Colors.white),
              _buildMiniDivider(),
              _buildMiniStat(_t('Canceled', 'रद्द'), canceled, Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, int value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value.toString(),
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withOpacity(0.15),
    );
  }

  // ============================================================
  // STATS GRID
  // ============================================================

  Widget _buildStatsGrid(
    bool isDarkTheme,
    bool isHindi,
    bool isSmallScreen,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    final totalOrders = _getTotalOrders();
    final pending = _earnings['pendingShareBy'] ?? 0;
    final completed = _earnings['completedShareBy'] ?? 0;
    final canceled = _earnings['canceledShareBy'] ?? 0;

    final stats = [
      {
        'label': _t('Total Orders', 'कुल ऑर्डर'),
        'value': totalOrders.toString(),
        'bgColor':
            isDarkTheme ? const Color(0xFF1A1A3E) : const Color(0xFFEEF2FF),
        'iconColor': _accentBlue,
        'icon': Icons.shopping_bag_outlined,
      },
      {
        'label': _t('New Orders', 'नए ऑर्डर'),
        'value': pending.toString(),
        'bgColor':
            isDarkTheme ? const Color(0xFF3A1A1A) : const Color(0xFFFFF3E0),
        'iconColor': _accentOrange,
        'icon': Icons.pending_outlined,
      },
      {
        'label': _t('Completed', 'पूर्ण'),
        'value': completed.toString(),
        'bgColor':
            isDarkTheme ? const Color(0xFF1A3A1A) : const Color(0xFFE8F5E9),
        'iconColor': _accentGreen,
        'icon': Icons.check_circle_outline,
      },
      {
        'label': _t('Canceled', 'रद्द'),
        'value': canceled.toString(),
        'bgColor':
            isDarkTheme ? const Color(0xFF3A1A1A) : const Color(0xFFFFEBEE),
        'iconColor': _accentRed,
        'icon': Icons.cancel_outlined,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            _t('Order Statistics', 'ऑर्डर आंकड़े'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children:
              stats.map((stat) {
                return _buildStatCard(
                  label: stat['label'] as String,
                  value: stat['value'] as String,
                  bgColor: stat['bgColor'] as Color,
                  iconColor: stat['iconColor'] as Color,
                  icon: stat['icon'] as IconData,
                  isDarkTheme: isDarkTheme,
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color bgColor,
    required Color iconColor,
    required IconData icon,
    required bool isDarkTheme,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkTheme ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDarkTheme ? Colors.white.withOpacity(0.06) : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkTheme ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WITHDRAW SECTION
  // ============================================================

  Widget _buildWithdrawSection(
    bool isDarkTheme,
    bool isHindi,
    bool isSmallScreen,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    final earning = (_earnings['earning'] ?? 0).toDouble();
    final shareCount = (_earnings['shareCount'] ?? 0).toInt();
    final canWithdraw = earning >= 1000 && shareCount >= 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            _t('Withdraw Funds', 'निकासी'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkTheme ? 0.2 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Progress indicators
              Row(
                children: [
                  Expanded(
                    child: _buildProgressIndicator(
                      label: _t('Earning', 'कमाई'),
                      current: earning,
                      target: 1000,
                      color: _primaryGradientStart,
                      isDarkTheme: isDarkTheme,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildProgressIndicator(
                      label: _t('Shares', 'शेयर'),
                      current: shareCount.toDouble(),
                      target: 100,
                      color: _accentOrange,
                      isDarkTheme: isDarkTheme,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Withdraw button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canWithdraw ? _handleWithdraw : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        canWithdraw ? _accentGreen : Colors.grey[300],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: canWithdraw ? 4 : 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        canWithdraw ? Icons.arrow_upward : Icons.lock_outline,
                        size: 18,
                        color: canWithdraw ? Colors.white : Colors.grey[400],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        canWithdraw
                            ? _t('Withdraw Now', 'अभी निकालें')
                            : _t('Locked', 'बंद'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: canWithdraw ? Colors.white : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Info note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isDarkTheme
                          ? Colors.white.withOpacity(0.03)
                          : const Color(0xFFF8FAFD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isDarkTheme
                            ? Colors.white.withOpacity(0.05)
                            : const Color(0xFFE8ECF3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: secondaryTextColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _t(
                          'Minimum ₹1000 earning & 100 shares required',
                          'न्यूनतम ₹1000 कमाई और 100 शेयर आवश्यक',
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Progress status
              if (!canWithdraw) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _accentOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _accentOrange.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: _accentOrange,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _t(
                          'Need ₹${(1000 - earning).toStringAsFixed(0)} more',
                          '₹${(1000 - earning).toStringAsFixed(0)} और चाहिए',
                        ),
                        style: TextStyle(
                          fontSize: 11,
                          color: _accentOrange,
                          fontWeight: FontWeight.w600,
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
    );
  }

  // ✅ FIXED: Uses LayoutBuilder to calculate width properly
  Widget _buildProgressIndicator({
    required String label,
    required double current,
    required double target,
    required Color color,
    required bool isDarkTheme,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    final percentage = (current / target).clamp(0.0, 1.0);
    final isComplete = current >= target;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: secondaryTextColor,
              ),
            ),
            Text(
              isComplete ? '✓' : '${(percentage * 100).toInt()}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isComplete ? _accentGreen : color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  height: 4,
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    color:
                        isDarkTheme
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey[200],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  height: 4,
                  width: constraints.maxWidth * percentage,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          isComplete
                              ? [_accentGreen, _accentGreen]
                              : [color, color.withOpacity(0.6)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 2),
        Text(
          '₹${current.toStringAsFixed(0)} / ₹${target.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 9,
            color: secondaryTextColor.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

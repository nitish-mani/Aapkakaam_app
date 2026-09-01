// this file is made responsive for all devices with Hindi support.

import 'dart:convert';
import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/models/data_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ViewShare extends StatefulWidget {
  const ViewShare({super.key});

  @override
  State<ViewShare> createState() => _ViewShareState();
}

class _ViewShareState extends State<ViewShare>
    with SingleTickerProviderStateMixin {
  Future<Map<String, dynamic>>? futureCards;
  int pageNo = 0;
  int totalShared = 0;
  int totalPages = 0;
  bool _isLoading = false;
  bool _isFetched = false;
  UserModel? user;
  VendorModel? vendor;
  List<dynamic> _shareList = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Colors
  static const Color _primaryBlue = Color(0xFF4F46E5);
  static const Color _primaryPurple = Color(0xFF7C3AED);
  static const Color _accentGreen = Color(0xFF22C55E);
  static const Color _accentOrange = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _loadUserData();
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
  // LOAD USER DATA
  // ============================================================

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final vendorData = prefs.getString('vendor');

    if (userData != null) {
      final decodedUser = jsonDecode(userData);
      setState(() {
        user = UserModel.fromJson(decodedUser);
      });
    }

    if (vendorData != null) {
      final decodedVendor = jsonDecode(vendorData);
      setState(() {
        vendor = VendorModel.fromJson(decodedVendor);
      });
    }
  }

  // ============================================================
  // FETCH SHARE DATA
  // ============================================================

  Future<void> _fetchShareData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _isFetched = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final vendorData = prefs.getString('vendor');
    final isVendorUser = vendorData != null;

    String token;
    String userId;

    if (isVendorUser && vendorData != null) {
      final decodedVendor = jsonDecode(vendorData);
      token = 'Bearer ${decodedVendor['token']}';
      userId = decodedVendor['vendorId'];
    } else if (userData != null) {
      final decodedUser = jsonDecode(userData);
      token = 'Bearer ${decodedUser['token']}';
      userId = decodedUser['userId'];
    } else {
      setState(() => _isLoading = false);
      _showErrorDialog(
        context,
        _t('User data not found', 'उपयोगकर्ता डेटा नहीं मिला'),
      );
      return;
    }

    try {
      final url = Uri.parse(
        isVendorUser
            ? "${KConstantURL.url}/vendor/getShare/$userId/$pageNo"
            : "${KConstantURL.url}/user/getShare/$userId/$pageNo",
      );

      final response = await http.get(url, headers: {"Authorization": token});

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final shareList = jsonResponse['share'] ?? [];
        final total = jsonResponse['total'] ?? 0;
        // print(jsonResponse);
        int totalPages = (total / 12).ceil();
        final int totalPagesFinal = totalPages > 0 ? totalPages : 1;

        if (mounted) {
          setState(() {
            _shareList = shareList;
            totalShared = total;
            totalPages = totalPagesFinal;
            _isLoading = false;
          });
          _animationController.forward();
        }
      } else {
        final error = json.decode(response.body);
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorDialog(
            context,
            error['message'] ??
                _t('Failed to load share data', 'शेयर डेटा लोड करने में विफल'),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog(context, _t('Error: $e', 'त्रुटि: $e'));
      }
    }
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _goToPreviousPage() {
    if (pageNo > 1) {
      setState(() {
        pageNo--;
        _fetchShareData();
      });
    }
  }

  void _goToNextPage() {
    if (pageNo < totalPages - 1) {
      setState(() {
        pageNo++;
        _fetchShareData();
      });
    }
  }

  // ============================================================
  // DIALOGS
  // ============================================================

  void _showEndDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            title: Row(
              children: [
                Icon(Icons.info_outline, color: _accentOrange),
                const SizedBox(width: 8),
                Text(
                  _t('No more pages', 'कोई और पेज नहीं'),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              _t('You have reached the end.', 'आप अंत तक पहुँच गए हैं।'),
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  _t('OK', 'ठीक है'),
                  style: TextStyle(color: _primaryBlue),
                ),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            title: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  _t('Error', 'त्रुटि'),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  _t('OK', 'ठीक है'),
                  style: TextStyle(color: _primaryBlue),
                ),
              ),
            ],
          ),
    );
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(String dateString) {
    try {
      final DateTime utcDate = DateTime.parse(dateString);
      final DateTime localDate = utcDate.add(
        const Duration(hours: 5, minutes: 30),
      );
      return '${localDate.day}/${localDate.month}/${localDate.year} ${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
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
            return _buildPage(context, isDarkTheme: isDarkTheme);
          },
        );
      },
    );
  }

  Widget _buildPage(BuildContext context, {required bool isDarkTheme}) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 400;

    final backgroundColor =
        isDarkTheme ? const Color(0xFF0B1020) : const Color(0xFFF0F2F8);
    final cardColor = isDarkTheme ? const Color(0xFF1A1A2E) : Colors.white;
    final textColor = isDarkTheme ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkTheme ? Colors.white60 : Colors.grey[600]!;
    final borderColor =
        isDarkTheme ? Colors.white.withOpacity(0.06) : Colors.grey[200]!;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _t('Share', 'शेयर'),
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 18 : 20,
              ),
            ),
            Text(
              '${_t('Total Share', 'कुल शेयर')} = $totalShared',
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: isSmallScreen ? 11 : 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                isDarkTheme ? Colors.white.withOpacity(0.05) : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child:
                    _isFetched
                        ? _buildShareList(
                          isDarkTheme,
                          mediaQuery,
                          isSmallScreen,
                          textColor,
                          secondaryTextColor,
                          borderColor,
                          cardColor,
                        )
                        : _buildFetchButton(
                          isDarkTheme,
                          mediaQuery,
                          isSmallScreen,
                          textColor,
                          secondaryTextColor,
                        ),
              ),
            ),
            if (_isFetched && _shareList.isNotEmpty) ...[
              _buildPaginationControls(
                isDarkTheme,
                mediaQuery,
                isSmallScreen,
                textColor,
                secondaryTextColor,
                borderColor,
              ),
              SizedBox(height: mediaQuery.size.height * 0.01),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FETCH BUTTON
  // ============================================================

  Widget _buildFetchButton(
    bool isDarkTheme,
    MediaQueryData mediaQuery,
    bool isSmallScreen,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryBlue, _primaryPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _primaryBlue.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(Icons.share_outlined, size: 36, color: Colors.white),
          ),
          SizedBox(height: mediaQuery.size.height * 0.025),
          Text(
            _t('View Your Shared Contacts', 'अपने शेयर किए गए संपर्क देखें'),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isSmallScreen ? 16 : 18,
              color: textColor,
            ),
          ),
          SizedBox(height: mediaQuery.size.height * 0.01),
          Text(
            _t(
              'Tap the button below to fetch your share data',
              'अपना शेयर डेटा प्राप्त करने के लिए नीचे दिए गए बटन पर टैप करें',
            ),
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: isSmallScreen ? 12 : 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: mediaQuery.size.height * 0.025),
          ElevatedButton.icon(
            onPressed: _fetchShareData,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: mediaQuery.size.width * 0.08,
                vertical: mediaQuery.size.height * 0.02,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 4,
            ),
            icon: const Icon(Icons.download_rounded, size: 20),
            label: Text(
              _t('Fetch Share Data', 'शेयर डेटा प्राप्त करें'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAGINATION CONTROLS
  // ============================================================

  Widget _buildPaginationControls(
    bool isDarkTheme,
    MediaQueryData mediaQuery,
    bool isSmallScreen,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    final canGoBack = pageNo > 1;
    final canGoForward = pageNo < totalPages - 1;
    final totalPage = (totalShared / 12).ceil();
    final page = pageNo + 1;

    return Container(
      height: 56,
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isDarkTheme ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkTheme ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPaginationButton(
            icon: Icons.chevron_left_rounded,
            onPressed: canGoBack ? _goToPreviousPage : null,
            isDarkTheme: isDarkTheme,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: (isDarkTheme ? Colors.white : Colors.black).withOpacity(
                0.06,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  '$page',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 14 : 16,
                    color: textColor,
                  ),
                ),
                Text(
                  ' / $totalPage',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          _buildPaginationButton(
            icon: Icons.chevron_right_rounded,
            onPressed:
                canGoForward ? _goToNextPage : () => _showEndDialog(context),
            isDarkTheme: isDarkTheme,
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationButton({
    required IconData icon,
    VoidCallback? onPressed,
    required bool isDarkTheme,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                onPressed != null
                    ? (isDarkTheme
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.04))
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color:
                onPressed != null
                    ? (isDarkTheme ? Colors.white : Colors.black87)
                    : (isDarkTheme ? Colors.white30 : Colors.grey[400]),
            size: 24,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SHARE LIST
  // ============================================================

  Widget _buildShareList(
    bool isDarkTheme,
    MediaQueryData mediaQuery,
    bool isSmallScreen,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
    Color cardColor,
  ) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryBlue, _primaryPurple],
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
            SizedBox(height: mediaQuery.size.height * 0.02),
            Text(
              _t('Loading...', 'लोड हो रहा है...'),
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_shareList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: (isDarkTheme ? Colors.white : Colors.black).withOpacity(
                  0.05,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.share_outlined,
                size: 40,
                color: isDarkTheme ? Colors.white30 : Colors.grey[400],
              ),
            ),
            SizedBox(height: mediaQuery.size.height * 0.02),
            Text(
              _t(
                "You haven't shared to anyone yet.",
                'आपने अभी तक किसी के साथ शेयर नहीं किया है।',
              ),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 16 : 18,
                color: textColor,
              ),
            ),
            SizedBox(height: mediaQuery.size.height * 0.01),
            Text(
              _t(
                'Start sharing to build your network!',
                'अपना नेटवर्क बनाने के लिए शेयर करना शुरू करें!',
              ),
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 4),
        itemCount: _shareList.length,
        itemBuilder:
            (context, index) => Column(
              children: [
                _buildShareCard(
                  context,
                  _shareList[index],
                  isDarkTheme,
                  mediaQuery,
                  isSmallScreen,
                  textColor,
                  secondaryTextColor,
                  borderColor,
                  cardColor,
                ),

                // Add ad after every 3 shares
              ],
            ),
      ),
    );
  }

  // ============================================================
  // SHARE CARD
  // ============================================================

  Widget _buildShareCard(
    BuildContext context,
    dynamic share,
    bool isDarkTheme,
    MediaQueryData mediaQuery,
    bool isSmallScreen,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
    Color cardColor,
  ) {
    final name = share['name'] ?? 'N/A';
    final phoneNo = share['phoneNo']?.toString() ?? 'N/A';
    final shareDate = _formatDate(share['shareDate'] ?? share['date'] ?? '');
    final userId = share['userId']?.toString() ?? '';

    // Generate avatar from phone number
    final String avatarText = name.substring(0, 2).toUpperCase() ?? 'N/A';

    // Get random color based on phone number
    final Color avatarColor = _getColorFromString(phoneNo);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.only(bottom: mediaQuery.size.height * 0.015),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkTheme ? 0.15 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [avatarColor, avatarColor.withOpacity(0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: avatarColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  avatarText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            SizedBox(width: mediaQuery.size.width * 0.03),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _t('Name', 'नाम'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 11 : 13,
                          color: secondaryTextColor,
                        ),
                      ),
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 13 : 15,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: mediaQuery.size.height * 0.005),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _t('Phone Number', 'फोन नंबर'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 11 : 13,
                          color: secondaryTextColor,
                        ),
                      ),
                      Text(
                        phoneNo,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 13 : 15,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: mediaQuery.size.height * 0.005),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _t('Shared On', 'शेयर किया गया'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 11 : 13,
                          color: secondaryTextColor,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: isSmallScreen ? 12 : 14,
                            color: _primaryBlue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            shareDate,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // User ID (small)
                  if (userId.isNotEmpty) ...[
                    SizedBox(height: mediaQuery.size.height * 0.003),
                    Text(
                      'ID: #${userId.substring(0, userId.length > 8 ? 8 : userId.length)}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 9 : 10,
                        color: secondaryTextColor.withOpacity(0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HELPER: Get color from string
  // ============================================================

  Color _getColorFromString(String input) {
    final colors = [
      const Color(0xFF4F46E5),
      const Color(0xFF7C3AED),
      const Color(0xFFEC4899),
      const Color(0xFFEF4444),
      const Color(0xFFF59E0B),
      const Color(0xFF22C55E),
      const Color(0xFF06B6D4),
      const Color(0xFF3B82F6),
    ];
    if (input.isEmpty) return colors[0];
    final index = input.hashCode.abs() % colors.length;
    return colors[index];
  }
}

// this file is made responsive for all devices with Hindi support.

import 'dart:convert';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/models/data_model.dart';
import 'package:app_aapkakaam/widgets/payment_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with SingleTickerProviderStateMixin {
  UserModel? _user;
  VendorModel? _vendor;
  bool _isLoading = true;

  // ✅ FIX: Initialize with nullable instead of late
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<double>? _scaleAnimation;

  // Colors
  static const Color _primaryBlue = Color(0xFF4F46E5);
  static const Color _primaryPurple = Color(0xFF7C3AED);
  static const Color _accentGreen = Color(0xFF22C55E);
  static const Color _accentOrange = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeOutBack),
    );
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController?.dispose();
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
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (isVendor.value) {
        final vendorData = prefs.getString("vendor");
        if (vendorData != null) {
          setState(
            () => _vendor = VendorModel.fromJson(jsonDecode(vendorData)),
          );
        }
      } else {
        final userData = prefs.getString("user");
        if (userData != null) {
          setState(() => _user = UserModel.fromJson(jsonDecode(userData)));
        }
      }
    } catch (e) {
      debugPrint("Error loading wallet data: $e");
    } finally {
      setState(() => _isLoading = false);
      _animationController?.forward();
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
    final textColor = isDarkTheme ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkTheme ? Colors.white60 : Colors.grey[600]!;
    final cardColor = isDarkTheme ? const Color(0xFF1A1A2E) : Colors.white;

    final balance = isVendor.value ? _vendor?.balance : _user?.balance;
    final userName = isVendor.value ? _vendor?.name : _user?.name;
    final userEmail = isVendor.value ? _vendor?.email : _user?.email;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          _t('Wallet', 'वॉलेट'),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 18 : 22,
            color: textColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
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
                    const SizedBox(height: 16),
                    Text(
                      _t('Loading wallet...', 'वॉलेट लोड हो रहा है...'),
                      style: TextStyle(color: secondaryTextColor, fontSize: 14),
                    ),
                  ],
                ),
              )
              : (_fadeAnimation != null && _scaleAnimation != null
                  ? FadeTransition(
                    opacity: _fadeAnimation!,
                    child: ScaleTransition(
                      scale: _scaleAnimation!,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        child: Column(
                          children: [
                            // User Info Card
                            _buildUserInfoCard(
                              isDarkTheme,
                              isSmallScreen,
                              textColor,
                              secondaryTextColor,
                              cardColor,
                              userName,
                              userEmail,
                            ),

                            const SizedBox(height: 20),

                            // Balance Card
                            _buildBalanceCard(
                              isDarkTheme,
                              isSmallScreen,
                              textColor,
                              secondaryTextColor,
                              cardColor,
                              balance,
                            ),

                            const SizedBox(height: 24),

                            // Quick Stats
                            // _buildQuickStats(
                            //   isDarkTheme,
                            //   isSmallScreen,
                            //   textColor,
                            //   secondaryTextColor,
                            //   cardColor,
                            // ),
                            const SizedBox(height: 24),

                            // Action Buttons
                            _buildActionButtons(
                              context,
                              isDarkTheme,
                              isSmallScreen,
                              textColor,
                              secondaryTextColor,
                            ),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  )
                  : SingleChildScrollView(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    child: Column(
                      children: [
                        // User Info Card
                        _buildUserInfoCard(
                          isDarkTheme,
                          isSmallScreen,
                          textColor,
                          secondaryTextColor,
                          cardColor,
                          userName,
                          userEmail,
                        ),

                        const SizedBox(height: 20),

                        // Balance Card
                        _buildBalanceCard(
                          isDarkTheme,
                          isSmallScreen,
                          textColor,
                          secondaryTextColor,
                          cardColor,
                          balance,
                        ),

                        const SizedBox(height: 24),

                        // Quick Stats
                        // _buildQuickStats(
                        //   isDarkTheme,
                        //   isSmallScreen,
                        //   textColor,
                        //   secondaryTextColor,
                        //   cardColor,
                        // ),
                        const SizedBox(height: 24),

                        // Action Buttons
                        _buildActionButtons(
                          context,
                          isDarkTheme,
                          isSmallScreen,
                          textColor,
                          secondaryTextColor,
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  )),
    );
  }

  // ============================================================
  // USER INFO CARD
  // ============================================================

  Widget _buildUserInfoCard(
    bool isDarkTheme,
    bool isSmallScreen,
    Color textColor,
    Color secondaryTextColor,
    Color cardColor,
    String? userName,
    String? userEmail,
  ) {
    final name = userName ?? _t('User', 'उपयोगकर्ता');
    final email = userEmail ?? _t('No email', 'कोई ईमेल नहीं');

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryBlue, _primaryPurple, _primaryBlue.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isSmallScreen ? 50 : 60,
            height: isSmallScreen ? 50 : 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 22 : 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: isSmallScreen ? 11 : 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isVendor.value
                        ? _t('Vendor', 'विक्रेता')
                        : _t('Customer', 'ग्राहक'),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: isSmallScreen ? 9 : 11,
                      fontWeight: FontWeight.w500,
                    ),
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
  // BALANCE CARD
  // ============================================================

  Widget _buildBalanceCard(
    bool isDarkTheme,
    bool isSmallScreen,
    Color textColor,
    Color secondaryTextColor,
    Color cardColor,
    double? balance,
  ) {
    final displayBalance = balance ?? 0.0;
    final formattedBalance = displayBalance.toStringAsFixed(2);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              isDarkTheme ? Colors.white.withOpacity(0.06) : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkTheme ? 0.2 : 0.04),
            blurRadius: 20,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_accentGreen, _accentGreen.withOpacity(0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.wallet_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('Total Balance', 'कुल बैलेंस'),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: secondaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _t('Available for use', 'उपयोग के लिए उपलब्ध'),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 11,
                      color: secondaryTextColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹',
                style: TextStyle(
                  color: _primaryBlue,
                  fontSize: isSmallScreen ? 20 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                formattedBalance,
                style: TextStyle(
                  color: textColor,
                  fontSize: isSmallScreen ? 34 : 42,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          if (displayBalance > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _accentGreen.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    color: _accentGreen,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _t('Account active', 'खाता सक्रिय'),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 11,
                      color: _accentGreen,
                      fontWeight: FontWeight.w600,
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

  // ============================================================
  // QUICK STATS
  // ============================================================

  // Widget _buildQuickStats(
  //   bool isDarkTheme,
  //   bool isSmallScreen,
  //   Color textColor,
  //   Color secondaryTextColor,
  //   Color cardColor,
  // ) {
  //   final stats = [
  //     {
  //       'icon': Icons.shopping_bag_outlined,
  //       'label': _t('Total Orders', 'कुल ऑर्डर'),
  //       'value':
  //           isVendor.value ? _vendor?.completed ?? 0 : _user?.completed ?? 0,
  //       'color': _primaryBlue,
  //     },
  //     {
  //       'icon': Icons.pending_actions_outlined,
  //       'label': _t('Pending', 'लंबित'),
  //       'value': isVendor.value ? _vendor?.pending ?? 0 : _user?.pending ?? 0,
  //       'color': _accentOrange,
  //     },
  //     {
  //       'icon': Icons.check_circle_outline,
  //       'label': _t('Completed', 'पूर्ण'),
  //       'value':
  //           isVendor.value ? _vendor?.completed ?? 0 : _user?.completed ?? 0,
  //       'color': _accentGreen,
  //     },
  //     {
  //       'icon': Icons.cancel_outlined,
  //       'label': _t('Canceled', 'रद्द'),
  //       'value': isVendor.value ? _vendor?.canceled ?? 0 : _user?.canceled ?? 0,
  //       'color': Colors.red,
  //     },
  //   ];

  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 4),
  //         child: Text(
  //           _t('Quick Stats', 'त्वरित आँकड़े'),
  //           style: TextStyle(
  //             fontSize: isSmallScreen ? 14 : 16,
  //             fontWeight: FontWeight.w700,
  //             color: textColor,
  //           ),
  //         ),
  //       ),
  //       const SizedBox(height: 12),
  //       GridView.count(
  //         shrinkWrap: true,
  //         physics: const NeverScrollableScrollPhysics(),
  //         crossAxisCount: 2,
  //         crossAxisSpacing: 12,
  //         mainAxisSpacing: 12,
  //         childAspectRatio: 1.6,
  //         children:
  //             stats.map((stat) {
  //               return Container(
  //                 padding: const EdgeInsets.all(12),
  //                 decoration: BoxDecoration(
  //                   color: cardColor,
  //                   borderRadius: BorderRadius.circular(16),
  //                   border: Border.all(
  //                     color:
  //                         isDarkTheme
  //                             ? Colors.white.withOpacity(0.06)
  //                             : Colors.grey[200]!,
  //                   ),
  //                   boxShadow: [
  //                     BoxShadow(
  //                       color: Colors.black.withOpacity(
  //                         isDarkTheme ? 0.2 : 0.04,
  //                       ),
  //                       blurRadius: 8,
  //                       offset: const Offset(0, 4),
  //                     ),
  //                   ],
  //                 ),
  //                 child: Row(
  //                   children: [
  //                     Container(
  //                       padding: const EdgeInsets.all(8),
  //                       decoration: BoxDecoration(
  //                         color: (stat['color'] as Color).withOpacity(0.1),
  //                         borderRadius: BorderRadius.circular(10),
  //                       ),
  //                       child: Icon(
  //                         stat['icon'] as IconData,
  //                         color: stat['color'] as Color,
  //                         size: isSmallScreen ? 18 : 20,
  //                       ),
  //                     ),
  //                     const SizedBox(width: 8),
  //                     Expanded(
  //                       child: Column(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         mainAxisAlignment: MainAxisAlignment.center,
  //                         children: [
  //                           Text(
  //                             stat['value'].toString(),
  //                             style: TextStyle(
  //                               fontSize: isSmallScreen ? 16 : 18,
  //                               fontWeight: FontWeight.bold,
  //                               color: textColor,
  //                             ),
  //                           ),
  //                           Text(
  //                             stat['label'] as String,
  //                             style: TextStyle(
  //                               fontSize: isSmallScreen ? 9 : 10,
  //                               color: secondaryTextColor,
  //                               fontWeight: FontWeight.w500,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               );
  //             }).toList(),
  //       ),
  //     ],
  //   );
  // }

  // ============================================================
  // ACTION BUTTONS
  // ============================================================

  Widget _buildActionButtons(
    BuildContext context,
    bool isDarkTheme,
    bool isSmallScreen,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Column(
      children: [
        // Add Balance Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 4,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PaymentPage()),
              );
            },
            icon: Icon(
              Icons.add_circle_outline_rounded,
              size: isSmallScreen ? 20 : 24,
              color: Colors.white,
            ),
            label: Text(
              _t('Add Balance', 'बैलेंस जोड़ें'),
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Refresh Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: textColor,
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              side: BorderSide(
                color:
                    isDarkTheme
                        ? Colors.white.withOpacity(0.2)
                        : Colors.grey[300]!,
              ),
            ),
            onPressed: () {
              _loadUserData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _t('Refreshing wallet...', 'वॉलेट रिफ्रेश हो रहा है...'),
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: _primaryBlue,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            icon: Icon(Icons.refresh_rounded, size: isSmallScreen ? 18 : 22),
            label: Text(
              _t('Refresh Balance', 'बैलेंस रिफ्रेश करें'),
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

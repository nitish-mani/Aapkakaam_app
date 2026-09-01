// this file is made responsive for all devices with Hindi support.

import 'dart:convert';
import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/models/data_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AvailableVendor extends StatefulWidget {
  const AvailableVendor({
    super.key,
    required this.bookingDate,
    this.profession = "",
    this.hindiName = "",
  });

  final DateTime bookingDate;
  final String profession;
  final String hindiName;

  @override
  State<AvailableVendor> createState() => _AvailableVendorState();
}

class _AvailableVendorState extends State<AvailableVendor>
    with SingleTickerProviderStateMixin {
  Future<Map<String, dynamic>>? _futureVendors;
  VendorModel? _vendor;
  UserModel? _user;
  bool _isVendor = false;
  String _pincode = '';
  double balance = 0;
  int _pageNo = 1;
  int itemCount = 10;
  final int _minRating = 0;
  final int _minWageRate = 0;
  bool _isLoading = false;
  bool _isBooking = false;
  bool _isReviewLoading = false;
  List<dynamic> _reviews = [];
  bool _isReviewsModalOpen = false;
  String? _selectedVendorId;
  String? _selectedVendorName;

  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  // Colors
  static const Color _primaryBlue = Color(0xFF4F46E5);
  static const Color _primaryPurple = Color(0xFF7C3AED);
  static const Color _accentGreen = Color(0xFF22C55E);
  static const Color _accentOrange = Color(0xFFF59E0B);
  static const Color _accentRed = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeIn),
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
  // HELPER METHODS
  // ============================================================

  double _getRatingAsDouble(dynamic rating) {
    if (rating == null) return 0.0;
    if (rating is double) return rating;
    if (rating is int) return rating.toDouble();
    if (rating is String) {
      return double.tryParse(rating) ?? 0.0;
    }
    return 0.0;
  }

  int _getIntValue(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  String _capitalizeWords(String input) {
    if (input.isEmpty) return input;
    return input
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '',
        )
        .join(' ');
  }

  String _maskPhoneNumber(String phone) {
    if (phone.length < 10) return phone;
    final visiblePart = phone.substring(0, 2);
    final maskedPart = '*' * (phone.length - 4);
    final lastTwo = phone.substring(phone.length - 2);
    return '$visiblePart$maskedPart$lastTwo';
  }

  Color _getColorFromString(String input) {
    final colors = [
      _primaryBlue,
      _primaryPurple,
      const Color(0xFFEC4899),
      const Color(0xFFEF4444),
      _accentOrange,
      _accentGreen,
      const Color(0xFF06B6D4),
      const Color(0xFF3B82F6),
    ];
    if (input.isEmpty) return colors[0];
    final index = input.hashCode.abs() % colors.length;
    return colors[index];
  }

  // ============================================================
  // LOAD USER DATA
  // ============================================================

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookingDate = widget.bookingDate;

      final userData = prefs.getString('user');
      final vendorData = prefs.getString('vendor');

      if (userData != null) {
        final decodedUser = jsonDecode(userData);
        _user = UserModel.fromJson(decodedUser);
        _pincode = _user?.address.firstOrNull?.pincode.toString() ?? '';
        balance = _user?.balance ?? _vendor?.balance ?? 0;
      }

      if (vendorData != null) {
        final decodedVendor = jsonDecode(vendorData);
        _vendor = VendorModel.fromJson(decodedVendor);
        _isVendor = true;
        _pincode = _vendor?.address.firstOrNull?.pincode.toString() ?? '';
        balance = _user?.balance ?? _vendor?.balance ?? 0;
      }

      final token =
          _isVendor ? 'Bearer ${_vendor?.token}' : 'Bearer ${_user?.token}';

      setState(() {
        _futureVendors = _fetchVendors(token, bookingDate);
        _isLoading = false;
      });
      _animationController?.forward();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ============================================================
  // FETCH VENDORS
  // ============================================================

  Future<Map<String, dynamic>> _fetchVendors(
    String token,
    DateTime bookingDate,
  ) async {
    final dateForVendorApi = DateFormat(
      'EEE MMM dd yyyy',
      'en_US',
    ).format(bookingDate);
    try {
      final endpoint = _isVendor ? 'getAllV' : 'getAll';
      final jobType = widget.profession.toLowerCase();

      final url =
          '${KConstantURL.url}/vendor/$endpoint/'
          '$jobType/$_pincode/$dateForVendorApi/'
          '$_pageNo/$_minRating/$_minWageRate';

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Authorization': token,
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch vendors');
      }

      final decoded = jsonDecode(response.body);
      final vendors = decoded['vendors'] as List? ?? [];
      return {...decoded, 'vendors': vendors};
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================
  // BOOKING
  // ============================================================

  Future<void> _handleBookNow({
    required BuildContext context,
    required String vendorId,
    required String jobType,
    required String phoneNo,
  }) async {
    if (_isBooking) return;

    setState(() => _isBooking = true);

    final normalizedJobType = jobType.trim().toLowerCase();
    final dateForVendorApi = DateFormat(
      'EEE MMM dd yyyy',
      'en_US',
    ).format(widget.bookingDate);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user');
      final vendorData = prefs.getString('vendor');

      if (userData == null && vendorData == null) {
        throw Exception("User data not found");
      }

      final decoded = jsonDecode(_isVendor ? vendorData! : userData!);
      final token = 'Bearer ${decoded['token']}';
      final userId = _isVendor ? decoded['vendorId'] : decoded['userId'];

      final bookingEndpoint =
          "${KConstantURL.url}/bookings/postToBookings${_isVendor ? 'V' : 'U'}";

      final bookingResponse = await http
          .post(
            Uri.parse(bookingEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': token,
            },
            body: jsonEncode({
              'userId': userId,
              'name': decoded['name'],
              'vendorId': vendorId,
              'bookingDate': dateForVendorApi,
              'pincode': _pincode,
              'type': normalizedJobType,
              'phoneNo': phoneNo,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (bookingResponse.statusCode < 200 ||
          bookingResponse.statusCode >= 300) {
        final errorData = jsonDecode(bookingResponse.body);
        throw Exception(errorData['message'] ?? 'Booking failed');
      }

      final responseData = jsonDecode(bookingResponse.body);

      if (_isVendor && _vendor != null) {
        await _updateVendorBalance(responseData);
      } else if (_user != null) {
        await _updateUserBalance(responseData);
      }

      if (mounted) {
        _showSuccessSnackbar(
          context,
          responseData['message'] ??
              _t('Booking created successfully', 'बुकिंग सफलतापूर्वक बनाई गई'),
        );
      }

      if (mounted) {
        await _refreshVendorList();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  Future<void> _updateUserBalance(Map<String, dynamic> responseData) async {
    final updatedUser = UserModel(
      token: _user!.token,
      userId: _user!.userId,
      name: _user!.name,
      email: _user!.email,
      verifyEmail: _user!.verifyEmail,
      phoneNo: _user!.phoneNo,
      verifyPhoneNo: _user!.verifyPhoneNo,
      gender: _user!.gender,
      address: _user!.address,
      balance: responseData['data']?['balance'] ?? _user!.balance,
      transactionCount:
          responseData['transactionCount'] ?? _user!.transactionCount,
      totalDiscount: responseData['totalDiscount'] ?? _user!.totalDiscount,
      totalOriginalAmount:
          responseData['totalOriginalAmount'] ?? _user!.totalOriginalAmount,
      pending: _user!.pending,
      completed: _user!.completed,
      canceled: _user!.canceled,
      pincode: _user!.pincode,
      message: responseData['message'] ?? _user!.message,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(updatedUser.toJson()));
    if (mounted) {
      setState(() => _user = updatedUser);
    }
  }

  Future<void> _updateVendorBalance(Map<String, dynamic> responseData) async {
    final updatedVendor = VendorModel(
      token: _vendor!.token,
      vendorId: _vendor!.vendorId,
      name: _vendor!.name,
      email: _vendor!.email,
      verifyEmail: _vendor!.verifyEmail,
      phoneNo: _vendor!.phoneNo,
      verifyPhoneNo: _vendor!.verifyPhoneNo,
      type: _vendor!.type,
      gender: _vendor!.gender,
      rating: _vendor!.rating,
      ratingCount: _vendor!.ratingCount,
      wageRate: _vendor!.wageRate,
      address: _vendor!.address,
      balance: responseData['data']?['balance'] ?? _vendor!.balance,
      wageRateType: _vendor!.wageRateType,
      transactionCount:
          responseData['transactionCount'] ?? _vendor!.transactionCount,
      totalDiscount: responseData['totalDiscount'] ?? _vendor!.totalDiscount,
      totalOriginalAmount:
          responseData['totalOriginalAmount'] ?? _vendor!.totalOriginalAmount,
      pending: _vendor!.pending,
      completed: _vendor!.completed,
      canceled: _vendor!.canceled,
      earning: responseData['earning'] ?? _vendor!.earning,
      pincode: _vendor!.pincode,
      message: responseData['message'] ?? _vendor!.message,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vendor', jsonEncode(updatedVendor.toJson()));
    if (mounted) {
      setState(() => _vendor = updatedVendor);
    }
  }

  Future<void> _refreshVendorList() async {
    final bookingDate = widget.bookingDate;
    final token =
        _isVendor ? 'Bearer ${_vendor?.token}' : 'Bearer ${_user?.token}';

    try {
      final newVendors = await _fetchVendors(token, bookingDate);
      if (mounted) {
        setState(() {
          _futureVendors = Future.value(newVendors);
        });
      }
    } catch (e) {
      debugPrint('❌ Vendor refresh failed: $e');
    }
  }

  // ============================================================
  // REVIEWS
  // ============================================================

  Future<void> _fetchReviews(String vendorId, String vendorName) async {
    setState(() {
      _isReviewLoading = true;
      _isReviewsModalOpen = true;
      _selectedVendorId = vendorId;
      _selectedVendorName = vendorName;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user');
      final vendorData = prefs.getString('vendor');

      final decoded = jsonDecode(_isVendor ? vendorData! : userData!);
      final token = 'Bearer ${decoded['token']}';
      final userId = _isVendor ? decoded['vendorId'] : decoded['userId'];

      final url = Uri.parse(
        _isVendor
            ? "${KConstantURL.url}/bookings/getReviewsV/$userId/$vendorId/1"
            : "${KConstantURL.url}/bookings/getReviewsU/$userId/$vendorId/1",
      );

      final response = await http.get(url, headers: {"Authorization": token});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _reviews = data['reviews'] ?? [];
            _isReviewLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _reviews = [];
            _isReviewLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _reviews = [];
          _isReviewLoading = false;
        });
      }
    }
  }

  void _closeReviewsModal() {
    setState(() {
      _isReviewsModalOpen = false;
      _reviews = [];
      _selectedVendorId = null;
      _selectedVendorName = null;
    });
  }

  // ============================================================
  // DIALOGS & SNACKBARS
  // ============================================================

  void _showBookingConfirmation(
    BuildContext context,
    dynamic vendor,
    String jobType,
  ) {
    final bookingDate = widget.bookingDate;
    final formattedDate =
        "${bookingDate.day}/${bookingDate.month}/${bookingDate.year}";
    final address = _user?.address.firstOrNull ?? _vendor?.address.firstOrNull;
    final totalDiscount = _user?.totalDiscount ?? _vendor?.totalDiscount ?? 0;
    final totalOriginalAmount =
        _user?.totalOriginalAmount ?? _vendor?.totalOriginalAmount ?? 0;
    final discountedPrice =
        totalOriginalAmount > 0
            ? ((1 - totalDiscount / totalOriginalAmount) * 10).toStringAsFixed(
              2,
            )
            : "10.00";

    final String vendorName = vendor['name'] ?? '';
    final String firstLetter =
        vendorName.isNotEmpty ? vendorName[0].toUpperCase() : 'V';
    final double ratingValue = _getRatingAsDouble(vendor['rating']);
    final int ratingCount = _getIntValue(vendor['ratingCount']);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder:
          (dialogContext) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
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
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            firstLetter,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vendorName.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Row(
                              children: [
                                _buildStarRating(ratingValue, starSize: 14),
                                const SizedBox(width: 4),
                                Text(
                                  ratingCount > 0
                                      ? '${ratingValue.toStringAsFixed(1)} ($ratingCount ${_t('Reviews', 'समीक्षाएँ')})'
                                      : _t('New Vendor', 'नया विक्रेता'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        isDark
                                            ? Colors.white60
                                            : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Details
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildDetailItem(
                          '🔧',
                          _t('Service', 'सेवा'),
                          vendor['type']?.toUpperCase() ?? '',
                        ),
                        _buildDivider(isDark),
                        _buildDetailItem(
                          '📅',
                          _t('Date', 'तारीख'),
                          formattedDate,
                        ),
                        _buildDivider(isDark),
                        _buildDetailItem(
                          '📍',
                          _t('Location', 'स्थान'),
                          '${address?.vill ?? ''}, ${address?.post ?? ''}',
                        ),
                        _buildDivider(isDark),
                        _buildDetailItem(
                          '💰',
                          _t('Cost', 'लागत'),
                          '₹${vendor['wageRate']} / ${vendor['wageRateType'] ?? 'day'}',
                          isPrice: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Fee note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _primaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _primaryBlue.withOpacity(0.15)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: _primaryBlue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _t(
                                  'Booking fee of ₹$discountedPrice will be deducted from your balance. This fee is non-refundable.',
                                  '₹$discountedPrice की बुकिंग शुल्क आपके बैलेंस से काटा जाएगा। यह शुल्क वापस नहीं किया जाएगा।',
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isDark
                                          ? Colors.white70
                                          : Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _t('Available Balance', 'उपलब्ध बैलेंस'),
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isDark ? Colors.white60 : Colors.grey[600],
                              ),
                            ),
                            Text(
                              '₹${balance.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: _accentGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
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
                              color: _accentRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _handleBookNow(
                              context: context,
                              vendorId: vendor['_id'],
                              jobType: jobType,
                              phoneNo: vendor['phoneNo'].toString(),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _t('Confirm Booking', 'बुकिंग की पुष्टि करें'),
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

  Widget _buildDetailItem(
    String icon,
    String label,
    String value, {
    bool isPrice = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: isPrice ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                    color: isPrice ? _primaryBlue : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 8,
      color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey[200],
    );
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _accentGreen,
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
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _accentRed,
        content: Center(
          child: Text(
            error,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
              isDarkTheme: isDarkTheme,
              isHindi: isHindi,
            );
          },
        );
      },
    );
  }

  Widget _buildPage(
    BuildContext context, {
    required bool isDarkTheme,
    required bool isHindi,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 400;
    final textColor = isDarkTheme ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkTheme ? Colors.white60 : Colors.grey[600]!;
    final backgroundColor =
        isDarkTheme ? const Color(0xFF0B1020) : const Color(0xFFF0F2F8);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          isHindi
              ? 'उपलब्ध ${widget.hindiName}'
              : 'Available ${widget.profession}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 16 : 20,
            color: textColor,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.wallet_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  '₹${balance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
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
                      _t(
                        'Loading ${widget.profession}...',
                        '${widget.hindiName} लोड हो रहे हैं...',
                      ),
                      style: TextStyle(color: secondaryTextColor, fontSize: 14),
                    ),
                  ],
                ),
              )
              : (_fadeAnimation != null
                  ? FadeTransition(
                    opacity: _fadeAnimation!,
                    child: Column(
                      children: [
                        Expanded(
                          child: _buildVendorList(
                            isDarkTheme,
                            mediaQuery,
                            isSmallScreen,
                            textColor,
                            secondaryTextColor,
                          ),
                        ),
                        if (itemCount > 0)
                          SafeArea(
                            top: false,
                            minimum: const EdgeInsets.only(bottom: 8),
                            child: _buildPaginationControls(
                              isDarkTheme,
                              mediaQuery,
                              isSmallScreen,
                              textColor,
                              secondaryTextColor,
                            ),
                          ),
                      ],
                    ),
                  )
                  : Column(
                    children: [
                      Expanded(
                        child: _buildVendorList(
                          isDarkTheme,
                          mediaQuery,
                          isSmallScreen,
                          textColor,
                          secondaryTextColor,
                        ),
                      ),
                      if (itemCount > 0)
                        SafeArea(
                          top: false,
                          minimum: const EdgeInsets.only(bottom: 8),
                          child: _buildPaginationControls(
                            isDarkTheme,
                            mediaQuery,
                            isSmallScreen,
                            textColor,
                            secondaryTextColor,
                          ),
                        ),
                    ],
                  )),
    );
  }

  // ============================================================
  // VENDOR LIST
  // ============================================================

  Widget _buildVendorList(
    bool isDarkTheme,
    MediaQueryData mediaQuery,
    bool isSmallScreen,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _futureVendors,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: _accentRed),
                const SizedBox(height: 12),
                Text(
                  _t(
                    'Error loading ${widget.profession}',
                    '${widget.hindiName} लोड करने में त्रुटि',
                  ),
                  style: TextStyle(
                    fontSize: mediaQuery.size.width * 0.04,
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(
                    fontSize: mediaQuery.size.width * 0.032,
                    color: secondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: (isDarkTheme ? Colors.white : Colors.black)
                        .withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.search_off_rounded,
                    size: 40,
                    color: isDarkTheme ? Colors.white30 : Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _t(
                    'No ${widget.profession} available',
                    'कोई ${widget.hindiName} उपलब्ध नहीं',
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: mediaQuery.size.width * 0.045,
                    color: textColor,
                  ),
                ),
              ],
            ),
          );
        }

        final vendorList = snapshot.data!["vendors"] as List? ?? [];
        if (vendorList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: isDarkTheme ? Colors.white30 : Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  _t(
                    'No ${widget.profession} available',
                    'कोई ${widget.hindiName} उपलब्ध नहीं',
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: mediaQuery.size.width * 0.045,
                    color: textColor,
                  ),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            ListView.builder(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
              itemCount: vendorList.length,
              itemBuilder:
                  (context, index) => Column(
                    children: [
                      _buildVendorCard(
                        vendorList[index],
                        isDarkTheme,
                        mediaQuery,
                        isSmallScreen,
                        textColor,
                        secondaryTextColor,
                      ),
                    ],
                  ),
            ),

            if (_isReviewsModalOpen)
              _buildReviewsModal(
                isDarkTheme,
                mediaQuery,
                isSmallScreen,
                textColor,
                secondaryTextColor,
              ),
          ],
        );
      },
    );
  }

  // ============================================================
  // VENDOR CARD
  // ============================================================

  Widget _buildVendorCard(
    dynamic vendor,
    bool isDarkTheme,
    MediaQueryData mediaQuery,
    bool isSmallScreen,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final balance = _user?.balance ?? _vendor?.balance ?? 0;
    final canBook = balance >= 10;
    final vendorName = vendor['name'] ?? '';
    final firstLetter =
        vendorName.isNotEmpty ? vendorName[0].toUpperCase() : 'V';

    final double ratingValue = _getRatingAsDouble(vendor['rating']);
    final int ratingCount = _getIntValue(vendor['ratingCount']);
    final int completedVendor = _getIntValue(vendor['completedVendor']);
    final int experience = _getIntValue(vendor['experience']);

    final avatarColor = _getColorFromString(vendorName);

    final cardColor = isDarkTheme ? const Color(0xFF1A1A2E) : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.only(bottom: mediaQuery.size.height * 0.015),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDarkTheme ? Colors.white.withOpacity(0.06) : Colors.grey[200]!,
        ),
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
                  firstLetter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
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
                  // Name & Verified
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _capitalizeWords(vendorName),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 14 : 16,
                            color: textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (vendor['isVerified'] == true) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.verified_rounded,
                          color: _primaryBlue,
                          size: isSmallScreen ? 14 : 16,
                        ),
                      ],
                    ],
                  ),

                  // Type
                  Text(
                    _capitalizeWords(vendor['type'] ?? ''),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 13,
                      color: secondaryTextColor,
                    ),
                  ),

                  // Rating
                  Row(
                    children: [
                      _buildStarRating(
                        ratingValue,
                        starSize: isSmallScreen ? 12 : 14,
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _fetchReviews(vendor['_id'], vendorName),
                        child: Text(
                          ratingCount > 0
                              ? '${ratingValue.toStringAsFixed(1)} ($ratingCount ${_t('Reviews', 'समीक्षाएँ')})'
                              : _t('New Vendor', 'नया विक्रेता'),
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 12,
                            color: _primaryBlue,
                            decoration:
                                ratingCount > 0
                                    ? TextDecoration.underline
                                    : null,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Stats
                  Row(
                    children: [
                      if (completedVendor > 0) ...[
                        Icon(
                          Icons.check_circle_rounded,
                          color: _accentGreen,
                          size: isSmallScreen ? 14 : 16,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '$completedVendor ${_t('Jobs Completed', 'कार्य पूर्ण')}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 11,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                      if (completedVendor > 0 && experience > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 1,
                          height: 14,
                          color: secondaryTextColor.withOpacity(0.3),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (experience > 0) ...[
                        Icon(
                          Icons.emoji_events_rounded,
                          color: _accentOrange,
                          size: isSmallScreen ? 14 : 16,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '$experience ${_t('Years', 'साल')}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 11,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Phone
                  Text(
                    '📱 ${_maskPhoneNumber(vendor['phoneNo'].toString())}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 11 : 12,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),

            // Price & Book Button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Text(
                      '₹${vendor['wageRate']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 16 : 18,
                        color: _primaryBlue,
                      ),
                    ),
                    Text(
                      '/${vendor['wageRateType'] ?? 'day'}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 11,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: isSmallScreen ? 70 : 80,
                  height: 36,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          canBook
                              ? Theme.of(context).primaryColor
                              : Colors.grey[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: canBook ? 2 : 0,
                    ),
                    onPressed:
                        canBook && !_isBooking
                            ? () => _showBookingConfirmation(
                              context,
                              vendor,
                              widget.profession,
                            )
                            : null,
                    child:
                        _isBooking
                            ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : Text(
                              canBook
                                  ? _t('Book', 'बुक करें')
                                  : _t('Low Balance', 'कम बैलेंस'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 11 : 12,
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
  }

  Widget _buildStarRating(double rating, {double starSize = 12}) {
    return Row(
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star_rounded, color: Colors.amber, size: starSize);
        } else if (index < rating && rating - index >= 0.5) {
          return Icon(
            Icons.star_half_rounded,
            color: Colors.amber,
            size: starSize,
          );
        } else {
          return Icon(
            Icons.star_outline_rounded,
            color: Colors.amber,
            size: starSize,
          );
        }
      }),
    );
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  Widget _buildPaginationControls(
    bool isDarkTheme,
    MediaQueryData mediaQuery,
    bool isSmallScreen,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final canGoBack = _pageNo > 1;
    final canGoForward = itemCount > 12 && _pageNo < itemCount / 12;
    final totalPage = (itemCount / 12).ceil();

    return Container(
      height: 56,
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isDarkTheme ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDarkTheme ? Colors.white.withOpacity(0.06) : Colors.grey[200]!,
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPaginationButton(
            icon: Icons.chevron_left_rounded,
            onPressed: canGoBack ? () => _goToPreviousPage() : null,
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
                  '$_pageNo',
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
            onPressed: canGoForward ? () => _goToNextPage() : null,
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

  Future<void> _goToPreviousPage() async {
    setState(() {
      _pageNo = _pageNo > 1 ? _pageNo - 1 : 1;
    });
    await _refreshVendorList();
  }

  Future<void> _goToNextPage() async {
    setState(() {
      _pageNo++;
    });
    await _refreshVendorList();
  }

  // ============================================================
  // REVIEWS MODAL
  // ============================================================

  Widget _buildReviewsModal(
    bool isDarkTheme,
    MediaQueryData mediaQuery,
    bool isSmallScreen,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return GestureDetector(
      onTap: _closeReviewsModal,
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: Center(
          child: TweenAnimationBuilder(
            duration: const Duration(milliseconds: 300),
            tween: Tween<double>(begin: 0.8, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              width: mediaQuery.size.width * 0.92,
              height: mediaQuery.size.height * 0.8,
              decoration: BoxDecoration(
                color: isDarkTheme ? const Color(0xFF1A1A2E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryBlue, _primaryPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _t(
                              ' Reviews for ${_selectedVendorName?.toUpperCase() ?? widget.profession}',
                              ' ${_selectedVendorName?.toUpperCase() ?? widget.hindiName} के लिए समीक्षाएँ',
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                          onPressed: _closeReviewsModal,
                        ),
                      ],
                    ),
                  ),
                  // Body
                  Expanded(
                    child:
                        _isReviewLoading
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _t(
                                      'Loading reviews...',
                                      'समीक्षाएँ लोड हो रही हैं...',
                                    ),
                                    style: TextStyle(color: secondaryTextColor),
                                  ),
                                ],
                              ),
                            )
                            : _reviews.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    '📝',
                                    style: TextStyle(fontSize: 48),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _t(
                                      'No reviews yet',
                                      'अभी कोई समीक्षा नहीं',
                                    ),
                                    style: TextStyle(
                                      fontSize: mediaQuery.size.width * 0.04,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    _t(
                                      'Be the first to review!',
                                      'समीक्षा करने वाले पहले व्यक्ति बनें!',
                                    ),
                                    style: TextStyle(
                                      fontSize: mediaQuery.size.width * 0.032,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _reviews.length,
                              itemBuilder: (context, index) {
                                final review = _reviews[index];
                                return _buildReviewItem(
                                  review,
                                  isDarkTheme,
                                  mediaQuery,
                                  isSmallScreen,
                                  index,
                                  textColor,
                                  secondaryTextColor,
                                );
                              },
                            ),
                  ),
                  // Footer
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color:
                              isDarkTheme
                                  ? Colors.white.withOpacity(0.06)
                                  : Colors.grey[200]!,
                        ),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _closeReviewsModal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _t('Close Reviews', 'समीक्षाएँ बंद करें'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewItem(
    dynamic review,
    bool isDarkTheme,
    MediaQueryData mediaQuery,
    bool isSmallScreen,
    int index,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final String reviewerName = review['bookedById']?['name'] ?? '';
    final String firstLetter =
        reviewerName.isNotEmpty ? reviewerName[0].toUpperCase() : 'U';
    final double ratingValue = _getRatingAsDouble(review['rating']);
    final String reviewText =
        review['review'] ?? _t('No review text', 'कोई समीक्षा पाठ नहीं');
    final String bookingBy = review['bookingBy'] ?? 'User';

    String formattedDate = _t('Date not specified', 'तारीख निर्दिष्ट नहीं');
    if (review['bookingDate'] != null) {
      try {
        final DateTime utcDate = DateTime.parse(
          review['bookingDate'].toString(),
        );
        final DateTime localDate = utcDate.add(
          const Duration(hours: 5, minutes: 30),
        );
        formattedDate = "${localDate.day}/${localDate.month}/${localDate.year}";
      } catch (e) {
        formattedDate = _t('Invalid date', 'अमान्य तारीख');
      }
    }

    final cardColor =
        isDarkTheme ? Colors.white.withOpacity(0.03) : Colors.grey[50];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDarkTheme ? Colors.white.withOpacity(0.05) : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryBlue, _primaryPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        firstLetter,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reviewerName.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 12 : 13,
                          color: textColor,
                        ),
                      ),
                      Text(
                        bookingBy,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 10 : 11,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  ...List.generate(5, (starIndex) {
                    return Icon(
                      starIndex < ratingValue.floor()
                          ? Icons.star_rounded
                          : starIndex < ratingValue &&
                              ratingValue - starIndex >= 0.5
                          ? Icons.star_half_rounded
                          : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: isSmallScreen ? 14 : 16,
                    );
                  }),
                  const SizedBox(width: 4),
                  Text(
                    ratingValue.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 11 : 12,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            reviewText,
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 13,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '📅 $formattedDate',
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 11,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

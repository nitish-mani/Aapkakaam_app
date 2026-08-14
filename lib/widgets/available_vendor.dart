// this file is made responsive for all devices.

import 'dart:convert';
import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/models/data_model.dart';
import 'package:app_aapkakaam/widgets/banner_ad_widget.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AvailableVendor extends StatefulWidget {
  const AvailableVendor({
    super.key,
    required this.bookingDate,
    this.profession = "",
  });

  final DateTime bookingDate;
  final String profession;

  @override
  State<AvailableVendor> createState() => _AvailableVendorState();
}

class _AvailableVendorState extends State<AvailableVendor> {
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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ==================== HELPER METHODS ====================

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

  // ==================== END HELPER METHODS ====================

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
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

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
          "${KConstantURL.url}/bookings/postToBookings"
          "${_isVendor ? 'V' : 'U'}";

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

      final updatedBalance = responseData['data']?['balance'];

      if (_isVendor && _vendor != null) {
        await _updateVendorBalance(responseData);
      } else if (_user != null) {
        await _updateUserBalance(responseData);
      }

      if (mounted) {
        _showSuccessSnackbar(
          context,
          responseData['message'] ?? 'Booking created successfully',
        );
      }

      // Refresh using EXACT same date/type normalization
      if (mounted) {
        await _refreshVendorList();
      }
    } catch (e, stackTrace) {
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
    debugPrint('🔄 Refreshing vendor list...');

    final bookingDate = widget.bookingDate;
    // final dateForVendorApi = DateFormat(
    //   'EEE MMM dd yyyy',
    //   'en_US',
    // ).format(widget.bookingDate);

    final token =
        _isVendor ? 'Bearer ${_vendor?.token}' : 'Bearer ${_user?.token}';

    debugPrint('📅 Booking date: $bookingDate');
    debugPrint('📍 Pincode: $_pincode');
    debugPrint('📄 Page: $_pageNo');

    try {
      final newVendors = await _fetchVendors(token, bookingDate);

      final vendors = newVendors['vendors'] as List? ?? [];

      debugPrint(
        '✅ Vendor refresh completed. '
        'Count: ${vendors.length}',
      );

      for (final vendor in vendors) {
        debugPrint(
          '👤 Available vendor: '
          '${vendor['_id']} - ${vendor['name']}',
        );
      }

      if (mounted) {
        setState(() {
          _futureVendors = Future.value(newVendors);
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Vendor refresh failed: $e');

      debugPrint('StackTrace: $stackTrace');
    }
  }

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
      debugPrint("Error fetching reviews: $e");
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

    // Get first letter of name safely
    final String vendorName = vendor['name'] ?? '';
    final String firstLetter =
        vendorName.isNotEmpty ? vendorName[0].toUpperCase() : 'V';

    // Get rating safely
    final double ratingValue = _getRatingAsDouble(vendor['rating']);
    final int ratingCount = _getIntValue(vendor['ratingCount']);

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.amber,
                  radius: 20,
                  child: Text(
                    firstLetter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          _buildStarRating(ratingValue),
                          const SizedBox(width: 4),
                          Text(
                            ratingCount > 0
                                ? '${ratingValue.toStringAsFixed(1)} ($ratingCount reviews)'
                                : 'New Vendor',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailItem(
                    '🔧',
                    'Service',
                    vendor['type']?.toUpperCase() ?? '',
                  ),
                  _buildDetailItem('📅', 'Date', formattedDate),
                  _buildDetailItem(
                    '📍',
                    'Location',
                    '${address?.vill ?? ''}, ${address?.post ?? ''}',
                  ),
                  _buildDetailItem(
                    '💰',
                    'Cost',
                    '₹${vendor['wageRate']} / ${vendor['wageRateType'] ?? 'day'}',
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Booking fee of ₹$discountedPrice will be deducted from your balance. This fee is non-refundable.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
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
                              'Available Balance:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              '₹${balance.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.green,
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _handleBookNow(
                    context: context,
                    vendorId: vendor['_id'],
                    jobType: jobType,
                    phoneNo: vendor['phoneNo'].toString(),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text(
                  'Confirm Booking',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailItem(String icon, String label, String value) {
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Center(
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Center(
          child: Text(
            error,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return ValueListenableBuilder<bool>(
      valueListenable: isDarkThemeNotifier,
      builder: (context, isDarkTheme, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Available ${widget.profession}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: mediaQuery.size.width * 0.05,
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDarkTheme ? Colors.black26 : Colors.white30,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '₹${balance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: mediaQuery.size.width * 0.03, // Smaller font size
                    fontWeight: FontWeight.w600,
                    color: isDarkTheme ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
            backgroundColor: isDarkTheme ? Colors.teal : Colors.amber,
          ),
          backgroundColor: isDarkTheme ? Colors.grey[100] : Colors.grey[900],
          body: SizedBox(
            height: mediaQuery.size.height * 0.85,
            child: Column(
              children: [
                Expanded(
                  child:
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _buildVendorList(isDarkTheme, mediaQuery),
                ),
                if (itemCount > 0)
                  _buildPaginationControls(isDarkTheme, mediaQuery),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVendorList(bool isDarkTheme, MediaQueryData mediaQuery) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _futureVendors,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: isDarkTheme ? Colors.teal : Colors.amber,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error: ${snapshot.error}",
              style: TextStyle(
                color: isDarkTheme ? Colors.black : Colors.white,
                fontSize: mediaQuery.size.width * 0.04,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              children: [
                SizedBox(height: 18),
                const Center(child: BannerAdWidget()),
                SizedBox(height: 18),
                Text(
                  "No ${widget.profession} available",
                  style: TextStyle(
                    color: isDarkTheme ? Colors.black : Colors.white,
                    fontSize: mediaQuery.size.width * 0.045,
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
              children: [
                SizedBox(height: 18),
                const Center(child: BannerAdWidget()),
                SizedBox(height: 18),
                Text(
                  "No ${widget.profession} available",
                  style: TextStyle(
                    color: isDarkTheme ? Colors.black : Colors.white,
                    fontSize: mediaQuery.size.width * 0.045,
                  ),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            ListView.builder(
              padding: EdgeInsets.all(mediaQuery.size.width * 0.03),
              itemCount: vendorList.length,
              itemBuilder:
                  (context, index) => Column(
                    children: [
                      if (index % 5 == 0) ...[
                        const Center(child: BannerAdWidget()),
                        SizedBox(height: 8),
                      ],
                      _buildVendorCard(
                        vendorList[index],
                        isDarkTheme,
                        mediaQuery,
                        widget.profession,
                      ),
                    ],
                  ),
            ),
            // Reviews Modal
            if (_isReviewsModalOpen)
              _buildReviewsModal(isDarkTheme, mediaQuery),
          ],
        );
      },
    );
  }

  Widget _buildVendorCard(
    dynamic vendor,
    bool isDarkTheme,
    MediaQueryData mediaQuery,
    String jobType,
  ) {
    final balance = _user?.balance ?? _vendor?.balance ?? 0;
    final canBook = balance >= 10;
    final vendorName = vendor['name'] ?? '';

    // Safely get values
    final double ratingValue = _getRatingAsDouble(vendor['rating']);
    final int ratingCount = _getIntValue(vendor['ratingCount']);
    final int completedVendor = _getIntValue(vendor['completedVendor']);
    final int experience = _getIntValue(vendor['experience']);

    return Card(
      margin: EdgeInsets.only(bottom: mediaQuery.size.height * 0.015),
      elevation: 2,
      color: isDarkTheme ? Colors.white : Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(mediaQuery.size.width * 0.04),
        child: Row(
          children: [
            // Profile Picture
            _buildProfilePicture(vendor, isDarkTheme, mediaQuery),
            SizedBox(width: mediaQuery.size.width * 0.04),
            // Vendor Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _capitalizeWords(vendorName),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: mediaQuery.size.width * 0.045,
                          color: isDarkTheme ? Colors.black : Colors.white,
                        ),
                      ),
                      if (vendor['isVerified'] == true) ...[
                        SizedBox(width: 4),
                        Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: mediaQuery.size.width * 0.04,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    _capitalizeWords(vendor['type']),
                    style: TextStyle(
                      fontSize: mediaQuery.size.width * 0.04,
                      color: isDarkTheme ? Colors.black54 : Colors.white70,
                    ),
                  ),
                  Row(
                    children: [
                      _buildStarRating(
                        ratingValue,
                        starSize: mediaQuery.size.width * 0.035,
                      ),
                      SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _fetchReviews(vendor['_id'], vendorName),
                        child: Text(
                          ratingCount > 0
                              ? '${ratingValue.toStringAsFixed(1)} ($ratingCount Reviews)'
                              : 'New Vendor',
                          style: TextStyle(
                            fontSize: mediaQuery.size.width * 0.032,
                            color: Colors.blue,
                            decoration:
                                ratingCount > 0
                                    ? TextDecoration.underline
                                    : null,
                            fontWeight: FontWeight.bold,
                            decorationColor: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Stats
                  _buildVendorStats(
                    vendor,
                    isDarkTheme,
                    mediaQuery,
                    completedVendor,
                    experience,
                  ),
                  // Phone
                  Text(
                    '📱 ${_maskPhoneNumber(vendor['phoneNo'].toString())}',
                    style: TextStyle(
                      fontSize: mediaQuery.size.width * 0.035,
                      color: isDarkTheme ? Colors.black : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Book Now Button
            Column(
              children: [
                Text(
                  '₹${vendor['wageRate']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: mediaQuery.size.width * 0.045,
                    color: isDarkTheme ? Colors.teal : Colors.amber,
                  ),
                ),
                Text(
                  '/ ${vendor['wageRateType'] ?? 'day'}',
                  style: TextStyle(
                    fontSize: mediaQuery.size.width * 0.03,
                    color: isDarkTheme ? Colors.black54 : Colors.white54,
                  ),
                ),
                SizedBox(height: mediaQuery.size.height * 0.01),
                Tooltip(
                  message:
                      canBook
                          ? 'Book now for ₹10'
                          : 'Insufficient balance. Need ₹10 for booking.',
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          canBook
                              ? (isDarkTheme ? Colors.teal : Colors.amber)
                              : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: mediaQuery.size.width * 0.04,
                        vertical: mediaQuery.size.height * 0.01,
                      ),
                    ),
                    onPressed:
                        canBook && !_isBooking
                            ? () => _showBookingConfirmation(
                              context,
                              vendor,
                              jobType,
                            )
                            : null,
                    child:
                        _isBooking
                            ? SizedBox(
                              width: mediaQuery.size.width * 0.05,
                              height: mediaQuery.size.width * 0.05,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : Text(
                              canBook ? 'Book' : 'Low Balance',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: mediaQuery.size.width * 0.035,
                                color:
                                    isDarkTheme ? Colors.white : Colors.black,
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

  Widget _buildProfilePicture(
    dynamic vendor,
    bool isDarkTheme,
    MediaQueryData mediaQuery,
  ) {
    final isMale = vendor['gender'] == 'Male';
    final iconData = isMale ? Icons.person : Icons.person_outline;

    return Container(
      width: mediaQuery.size.width * 0.12,
      height: mediaQuery.size.width * 0.12,
      decoration: BoxDecoration(
        color: isDarkTheme ? Colors.teal.shade100 : Colors.amber.shade100,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDarkTheme ? Colors.teal : Colors.amber,
          width: 2,
        ),
      ),
      child: Icon(
        iconData,
        size: mediaQuery.size.width * 0.07,
        color: isDarkTheme ? Colors.teal : Colors.amber,
      ),
    );
  }

  Widget _buildStarRating(double rating, {double starSize = 12}) {
    return Row(
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star, color: Colors.amber, size: starSize);
        } else if (index < rating && rating - index >= 0.5) {
          return Icon(Icons.star_half, color: Colors.amber, size: starSize);
        } else {
          return Icon(Icons.star_border, color: Colors.amber, size: starSize);
        }
      }),
    );
  }

  Widget _buildVendorStats(
    dynamic vendor,
    bool isDarkTheme,
    MediaQueryData mediaQuery,
    int completedVendor,
    int experience,
  ) {
    final List<Widget> stats = [];

    if (completedVendor > 0) {
      stats.add(
        Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: mediaQuery.size.width * 0.035,
            ),
            SizedBox(width: 2),
            Text(
              '$completedVendor Jobs',
              style: TextStyle(
                fontSize: mediaQuery.size.width * 0.032,
                color: isDarkTheme ? Colors.black54 : Colors.white54,
              ),
            ),
          ],
        ),
      );
    }

    if (experience > 0) {
      stats.add(
        Row(
          children: [
            Icon(
              Icons.emoji_events,
              color: Colors.orange,
              size: mediaQuery.size.width * 0.035,
            ),
            SizedBox(width: 2),
            Text(
              '$experience Years',
              style: TextStyle(
                fontSize: mediaQuery.size.width * 0.032,
                color: isDarkTheme ? Colors.black54 : Colors.white54,
              ),
            ),
          ],
        ),
      );
    }

    if (stats.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children:
            stats
                .map(
                  (stat) => Padding(
                    padding: EdgeInsets.only(
                      right: mediaQuery.size.width * 0.03,
                    ),
                    child: stat,
                  ),
                )
                .toList(),
      ),
    );
  }

  String _maskPhoneNumber(String phone) {
    if (phone.length < 10) return phone;
    final visiblePart = phone.substring(0, 2);
    final maskedPart = '*' * (phone.length - 4);
    final lastTwo = phone.substring(phone.length - 2);
    return '$visiblePart$maskedPart$lastTwo';
  }

  Widget _buildReviewsModal(bool isDarkTheme, MediaQueryData mediaQuery) {
    return GestureDetector(
      onTap: _closeReviewsModal,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            width: mediaQuery.size.width * 0.9,
            height: mediaQuery.size.height * 0.8,
            decoration: BoxDecoration(
              color: isDarkTheme ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '⭐ Reviews for ${_selectedVendorName?.toUpperCase() ?? ''}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: mediaQuery.size.width * 0.045,
                            color: isDarkTheme ? Colors.white : Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: isDarkTheme ? Colors.white : Colors.black,
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
                            child: CircularProgressIndicator(
                              color: isDarkTheme ? Colors.teal : Colors.amber,
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
                                SizedBox(height: 12),
                                Text(
                                  'No reviews yet',
                                  style: TextStyle(
                                    fontSize: mediaQuery.size.width * 0.04,
                                    color:
                                        isDarkTheme
                                            ? Colors.white54
                                            : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _reviews.length,
                            itemBuilder: (context, index) {
                              final review = _reviews[index];
                              return _buildReviewItem(
                                review,
                                isDarkTheme,
                                mediaQuery,
                                index,
                              );
                            },
                          ),
                ),
                // Footer
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ElevatedButton(
                    onPressed: _closeReviewsModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkTheme ? Colors.teal : Colors.amber,
                      minimumSize: Size(double.infinity, 40),
                    ),
                    child: Text(
                      'Close Reviews',
                      style: TextStyle(
                        color: isDarkTheme ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
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
    int index,
  ) {
    // Get first letter of reviewer name safely
    final String reviewerName = review['bookedById']?['name'] ?? '';
    final String firstLetter =
        reviewerName.isNotEmpty ? reviewerName[0].toUpperCase() : 'U';

    // Get rating safely
    final double ratingValue = _getRatingAsDouble(review['rating']);

    // Format booking date to local time
    String formattedDate = 'Date not specified';
    if (review['bookingDate'] != null) {
      try {
        final DateTime utcDate = DateTime.parse(
          review['bookingDate'].toString(),
        );
        // Convert to local time (Asia/Kolkata - UTC+5:30)
        final DateTime localDate = utcDate.add(Duration(hours: 5, minutes: 30));
        formattedDate = "${localDate.day}/${localDate.month}/${localDate.year}";
      } catch (e) {
        formattedDate = 'Invalid date';
      }
    }

    // Format reviewed date to local time
    String formattedReviewedOn = '';
    if (review['reviewedOn'] != null) {
      try {
        final DateTime utcDate = DateTime.parse(
          review['reviewedOn'].toString(),
        );
        final DateTime localDate = utcDate.add(Duration(hours: 5, minutes: 30));
        formattedReviewedOn =
            "${localDate.day}/${localDate.month}/${localDate.year}";
      } catch (e) {
        formattedReviewedOn = '';
      }
    }

    return Column(
      children: [
        if (index > 0)
          Divider(color: isDarkTheme ? Colors.grey[700] : Colors.grey[300]),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            isDarkTheme ? Colors.teal : Colors.amber,
                        child: Text(
                          firstLetter,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
                              fontSize: mediaQuery.size.width * 0.04,
                              color: isDarkTheme ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            review['bookingBy'] ?? 'User',
                            style: TextStyle(
                              fontSize: mediaQuery.size.width * 0.03,
                              color:
                                  isDarkTheme ? Colors.white54 : Colors.black54,
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
                              ? Icons.star
                              : starIndex < ratingValue &&
                                  ratingValue - starIndex >= 0.5
                              ? Icons.star_half
                              : Icons.star_border,
                          color: Colors.amber,
                          size: mediaQuery.size.width * 0.035,
                        );
                      }),
                      const SizedBox(width: 4),
                      Text(
                        ratingValue.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: mediaQuery.size.width * 0.03,
                          color: isDarkTheme ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                review['review'] ?? 'No review text',
                style: TextStyle(
                  fontSize: mediaQuery.size.width * 0.035,
                  color: isDarkTheme ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '📅 $formattedDate',
                    style: TextStyle(
                      fontSize: mediaQuery.size.width * 0.03,
                      color: isDarkTheme ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  if (formattedReviewedOn.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Text(
                      'Reviewed: $formattedReviewedOn',
                      style: TextStyle(
                        fontSize: mediaQuery.size.width * 0.03,
                        color: isDarkTheme ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationControls(bool isDarkTheme, MediaQueryData mediaQuery) {
    final canGoBack = _pageNo > 1;
    final canGoForward = itemCount > 12 && _pageNo < itemCount / 12;

    return Container(
      margin: EdgeInsets.all(mediaQuery.size.width * 0.03),
      height: mediaQuery.size.height * 0.06,
      decoration: BoxDecoration(
        color: isDarkTheme ? Colors.white : Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              size: mediaQuery.size.width * 0.05,
            ),
            color: isDarkTheme ? Colors.black : Colors.white,
            onPressed: canGoBack ? () => _goToPreviousPage() : null,
          ),
          Text(
            '$_pageNo',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: mediaQuery.size.width * 0.045,
              color: isDarkTheme ? Colors.black : Colors.white,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.arrow_forward_ios,
              size: mediaQuery.size.width * 0.05,
            ),
            color: isDarkTheme ? Colors.black : Colors.white,
            onPressed: canGoForward ? () => _goToNextPage() : null,
          ),
        ],
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

  String _capitalizeWords(String input) {
    return input
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '',
        )
        .join(' ');
  }
}

// this file is made responsive for all devices with modern UI/UX.

import 'dart:convert';
import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/models/data_model.dart';
// import 'package:app_aapkakaam/widgets/banner_ad_widget.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  Future<Map<String, dynamic>>? futureCards;
  int orderDetails = 1;
  UserModel? user;
  VendorModel? vendor;
  int pageNo = 1;
  int totalOrders = 0;
  late Map<dynamic, bool> isLoadingC;
  late Map<dynamic, bool> isLoading;
  String? ratingOrderId;
  final TextEditingController ratingController = TextEditingController();
  final TextEditingController reviewController = TextEditingController();
  int _selectedRating = 0;
  int _hoveredRating = 0;
  late TabController _tabController;

  // Counters for badges
  int pendingCount = 0;
  int completedCount = 0;
  int canceledCount = 0;

  // Store current user ID for self-booking detection
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          orderDetails = _tabController.index + 1;
        });
      }
    });

    isLoadingC = {};
    isLoading = {};
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    ratingController.dispose();
    reviewController.dispose();
    super.dispose();
  }

  // Helper to get booking ID from order
  String _getBookingId(dynamic order) {
    if (order['bookingId'] != null &&
        order['bookingId'].toString().isNotEmpty) {
      return order['bookingId'].toString();
    }
    if (order['_id'] != null && order['_id'].toString().isNotEmpty) {
      return order['_id'].toString();
    }
    if (order['id'] != null && order['id'].toString().isNotEmpty) {
      return order['id'].toString();
    }
    return '';
  }

  // ============================================================
  // UTC TO ASIA/KOLKATA TIMEZONE CONVERTER
  // ============================================================

  /// Converts UTC DateTime to Asia/Kolkata timezone (UTC+5:30)
  DateTime _toAsiaKolkata(DateTime utcDate) {
    if (utcDate == null) return DateTime.now();
    // Add 5 hours 30 minutes to convert UTC to Asia/Kolkata
    return utcDate.add(const Duration(hours: 5, minutes: 30));
  }

  /// Parses date from string and converts to Asia/Kolkata timezone
  DateTime _parseAndConvertToAsiaKolkata(String? dateString) {
    if (dateString == null || dateString.isEmpty) return DateTime.now();
    try {
      final utcDate = DateTime.parse(dateString);
      return _toAsiaKolkata(utcDate);
    } catch (e) {
      debugPrint('Date parsing error: $e');
      return DateTime.now();
    }
  }

  /// Formats date in Asia/Kolkata timezone
  String _formatDate(DateTime date) {
    final isHindi = isHindiNotifier.value;
    // Convert to Asia/Kolkata if not already
    final localDate = date;

    if (isHindi) {
      return '${localDate.day}/${localDate.month}/${localDate.year}';
    }
    return '${localDate.day}/${localDate.month}/${localDate.year}';
  }

  // Language helper
  String _t(String en, String hi) => isHindiNotifier.value ? hi : en;

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final vendorData = prefs.getString('vendor');

    if (userData != null) {
      final decodedUser = jsonDecode(userData);
      setState(() {
        user = UserModel.fromJson(decodedUser);
        currentUserId = decodedUser['userId']?.toString();
        futureCards = _fetchCards(
          decodedUser['userId'],
          pageNo,
          'Bearer ${decodedUser['token']}',
        );
      });
    }

    if (vendorData != null) {
      final decodedVendor = jsonDecode(vendorData);
      setState(() {
        vendor = VendorModel.fromJson(decodedVendor);
        currentUserId = decodedVendor['vendorId']?.toString();
        futureCards = _fetchCards(
          decodedVendor['vendorId'],
          pageNo,
          'Bearer ${decodedVendor['token']}',
        );
      });
    }
  }

  Future<Map<String, dynamic>> _fetchCards(
    String userId,
    int pageNo,
    String token,
  ) async {
    final url = Uri.parse(
      isVendor.value
          ? "${KConstantURL.url}/bookings/getOrdersV/$userId/$pageNo"
          : "${KConstantURL.url}/bookings/getOrdersU/$userId/$pageNo",
    );

    try {
      final response = await http.get(url, headers: {"Authorization": token});

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        totalOrders = jsonResponse['total'] ?? 0;
        initializeIsLoadingCFromResponse(jsonResponse);
        _calculateOrderCounts(jsonResponse);
        print(jsonResponse);
        return jsonResponse;
      }
      throw Exception("Failed to load orders: ${response.statusCode}");
    } catch (e) {
      throw Exception("Error fetching orders: $e");
    }
  }

  void _calculateOrderCounts(Map<String, dynamic> response) {
    List<dynamic> orders = response['orders'] ?? [];
    int pending = 0;
    int completed = 0;
    int canceled = 0;

    for (var order in orders) {
      if (order['cancelOrder'] == true) {
        canceled++;
      } else if (order['orderCompleted'] == true) {
        completed++;
      } else {
        pending++;
      }
    }

    setState(() {
      pendingCount = pending;
      completedCount = completed;
      canceledCount = canceled;
    });
  }

  void initializeIsLoadingCFromResponse(Map<String, dynamic> response) {
    List<dynamic> orders = response['orders'] ?? [];
    isLoadingC = {for (var order in orders) _getBookingId(order): false};
    isLoading = {for (var order in orders) _getBookingId(order): false};
  }

  void updateIsLoadingForId(String id, bool value) {
    if (isLoading.containsKey(id)) {
      isLoading[id] = value;
    }
  }

  void updateIsLoadingForIdC(String id, bool value) {
    if (isLoadingC.containsKey(id)) {
      isLoadingC[id] = value;
    }
  }

  // Show confirmation dialog with theme colors
  Future<bool> _showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
    String confirmText,
    Color confirmColor,
  ) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: colorScheme.surface,
            title: Row(
              children: [
                Icon(
                  confirmColor == colorScheme.error
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
                  color: confirmColor,
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: TextStyle(fontSize: 15, color: colorScheme.onSurface),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  _t('Cancel', 'रद्द करें'),
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmColor,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 0,
                ),
                child: Text(
                  confirmText,
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    ).then((value) => value ?? false);
  }

  // Cancel Order with Bilingual Support
  Future<void> _handleCancelOrder({
    required BuildContext context,
    required String bookingId,
  }) async {
    final isHindi = isHindiNotifier.value;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (bookingId.isEmpty) {
      _showSnackBar(
        context,
        isHindi ? 'बुकिंग आईडी आवश्यक है' : 'Booking ID is required',
        false,
      );
      return;
    }

    final confirmed = await _showConfirmationDialog(
      context,
      isHindi ? 'ऑर्डर रद्द करें' : 'Cancel Order',
      isHindi
          ? 'क्या आप वाकई इस ऑर्डर को रद्द करना चाहते हैं? यह कार्रवाई वापस नहीं ली जा सकती।'
          : 'Are you sure you want to cancel this order? This action cannot be undone.',
      isHindi ? 'हाँ, रद्द करें' : 'Yes, Cancel',
      colorScheme.error,
    );

    if (!confirmed) return;

    setState(() => updateIsLoadingForIdC(bookingId, true));
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final vendorData = prefs.getString('vendor');
    final isVendorUser = vendorData != null;
    final token =
        "Bearer ${isVendorUser ? jsonDecode(vendorData)['token'] : jsonDecode(userData!)['token']}";
    final userId =
        isVendorUser
            ? jsonDecode(vendorData)['vendorId']
            : jsonDecode(userData!)['userId'];

    try {
      final response = await http.patch(
        Uri.parse(
          isVendorUser
              ? "${KConstantURL.url}/bookings/cancelOrderV"
              : "${KConstantURL.url}/bookings/cancelOrderU",
        ),
        headers: {"Content-Type": "application/json", "Authorization": token},
        body: jsonEncode({'bookingId': bookingId}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (isVendorUser && vendor != null) {
          await _updateVendorData(responseData);
        } else if (user != null) {
          await _updateUserData(responseData);
        }
        setState(() {
          updateIsLoadingForIdC(bookingId, false);
          futureCards = _fetchCards(userId, pageNo, token);
        });
        _showSnackBar(
          context,
          responseData['message'] ??
              (isHindi
                  ? 'ऑर्डर सफलतापूर्वक रद्द कर दिया गया'
                  : 'Order cancelled successfully'),
          true,
        );
      } else {
        setState(() => updateIsLoadingForIdC(bookingId, false));
        final error = jsonDecode(response.body);
        _showSnackBar(
          context,
          error['message'] ??
              (isHindi ? 'ऑर्डर रद्द करने में विफल' : 'Failed to cancel order'),
          false,
        );
      }
    } catch (e) {
      setState(() => updateIsLoadingForIdC(bookingId, false));
      _showSnackBar(context, isHindi ? 'त्रुटि: $e' : "Error: $e", false);
    }
  }

  // Mark as Completed with Bilingual Support
  Future<void> _handleMarkAsCompletedOrder({
    required BuildContext context,
    required String bookingId,
  }) async {
    final isHindi = isHindiNotifier.value;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (bookingId.isEmpty) {
      _showSnackBar(
        context,
        isHindi ? 'बुकिंग आईडी आवश्यक है' : 'Booking ID is required',
        false,
      );
      return;
    }

    final confirmed = await _showConfirmationDialog(
      context,
      isHindi ? 'पूर्ण के रूप में चिह्नित करें' : 'Mark as Completed',
      isHindi
          ? 'क्या आप वाकई इस ऑर्डर को पूर्ण के रूप में चिह्नित करना चाहते हैं?'
          : 'Are you sure you want to mark this order as completed?',
      isHindi ? 'हाँ, पूर्ण करें' : 'Yes, Complete',
      colorScheme.primary,
    );

    if (!confirmed) return;

    setState(() => updateIsLoadingForId(bookingId, true));
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final vendorData = prefs.getString('vendor');
    final isVendorUser = vendorData != null;
    final token =
        "Bearer ${isVendorUser ? jsonDecode(vendorData)['token'] : jsonDecode(userData!)['token']}";
    final userId =
        isVendorUser
            ? jsonDecode(vendorData)['vendorId']
            : jsonDecode(userData!)['userId'];

    try {
      final response = await http.patch(
        Uri.parse(
          isVendorUser
              ? "${KConstantURL.url}/bookings/orderCompletedV"
              : "${KConstantURL.url}/bookings/orderCompletedU",
        ),
        headers: {"Content-Type": "application/json", "Authorization": token},
        body: jsonEncode({'bookingId': bookingId}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (isVendorUser && vendor != null) {
          await _updateVendorData(responseData);
        } else if (user != null) {
          await _updateUserData(responseData);
        }
        setState(() {
          updateIsLoadingForId(bookingId, false);
          futureCards = _fetchCards(userId, pageNo, token);
        });
        _showSnackBar(
          context,
          responseData['message'] ??
              (isHindi
                  ? 'ऑर्डर सफलतापूर्वक पूर्ण किया गया'
                  : 'Order completed successfully'),
          true,
        );
      } else {
        setState(() => updateIsLoadingForId(bookingId, false));
        final error = jsonDecode(response.body);
        _showSnackBar(
          context,
          error['message'] ??
              (isHindi
                  ? 'ऑर्डर पूर्ण करने में विफल'
                  : 'Failed to complete order'),
          false,
        );
      }
    } catch (e) {
      setState(() => updateIsLoadingForId(bookingId, false));
      _showSnackBar(context, isHindi ? 'त्रुटि: $e' : "Error: $e", false);
    }
  }

  Future<void> _updateUserData(Map<String, dynamic> responseData) async {
    if (user == null) return;
    final updatedUser = UserModel(
      token: user!.token,
      userId: user!.userId,
      name: user!.name,
      email: user!.email,
      verifyEmail: user!.verifyEmail,
      phoneNo: user!.phoneNo,
      verifyPhoneNo: user!.verifyPhoneNo,
      gender: user!.gender,
      address: user!.address,
      balance: responseData['balance'] ?? user!.balance,
      transactionCount:
          responseData['transactionCount'] ?? user!.transactionCount,
      totalDiscount: responseData['totalDiscount'] ?? user!.totalDiscount,
      totalOriginalAmount:
          responseData['totalOriginalAmount'] ?? user!.totalOriginalAmount,
      pending: responseData['pending'] ?? user!.pending,
      completed: responseData['completed'] ?? user!.completed,
      canceled: responseData['canceled'] ?? user!.canceled,
      pincode: user!.pincode,
      message: responseData['message'] ?? user!.message,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(updatedUser.toJson()));
    setState(() => user = updatedUser);
  }

  Future<void> _updateVendorData(Map<String, dynamic> responseData) async {
    if (vendor == null) return;
    final updatedVendor = VendorModel(
      token: vendor!.token,
      vendorId: vendor!.vendorId,
      name: vendor!.name,
      email: vendor!.email,
      verifyEmail: vendor!.verifyEmail,
      phoneNo: vendor!.phoneNo,
      verifyPhoneNo: vendor!.verifyPhoneNo,
      type: vendor!.type,
      gender: vendor!.gender,
      rating: vendor!.rating,
      ratingCount: vendor!.ratingCount,
      wageRate: vendor!.wageRate,
      address: vendor!.address,
      balance: responseData['balance'] ?? vendor!.balance,
      wageRateType: vendor!.wageRateType,
      transactionCount:
          responseData['transactionCount'] ?? vendor!.transactionCount,
      totalDiscount: responseData['totalDiscount'] ?? vendor!.totalDiscount,
      totalOriginalAmount:
          responseData['totalOriginalAmount'] ?? vendor!.totalOriginalAmount,
      pending: responseData['pending'] ?? vendor!.pending,
      completed: responseData['completed'] ?? vendor!.completed,
      canceled: responseData['canceled'] ?? vendor!.canceled,
      earning: responseData['earning'] ?? vendor!.earning,
      pincode: vendor!.pincode,
      message: responseData['message'] ?? vendor!.message,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vendor', jsonEncode(updatedVendor.toJson()));
    setState(() => vendor = updatedVendor);
  }

  // Rating Order with Enhanced UI
  Future<void> _handleRatingOrder({
    required BuildContext context,
    required String bookingId,
  }) async {
    final rating = _selectedRating;
    if (rating < 1 || rating > 5) {
      _showSnackBar(context, 'Please select a rating between 1 and 5', false);
      return;
    }

    setState(() => updateIsLoadingForId(bookingId, true));
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final vendorData = prefs.getString('vendor');
    final isVendorUser = vendorData != null;
    final token =
        "Bearer ${isVendorUser ? jsonDecode(vendorData)['token'] : jsonDecode(userData!)['token']}";
    final userId =
        isVendorUser
            ? jsonDecode(vendorData)['vendorId']
            : jsonDecode(userData!)['userId'];

    try {
      final response = await http.patch(
        Uri.parse(
          isVendorUser
              ? "${KConstantURL.url}/bookings/ratingV"
              : "${KConstantURL.url}/bookings/ratingU",
        ),
        headers: {"Content-Type": "application/json", "Authorization": token},
        body: jsonEncode({
          'bookingId': bookingId,
          'rating': rating,
          'review': reviewController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          updateIsLoadingForId(bookingId, false);
          futureCards = _fetchCards(userId, pageNo, token);
          ratingOrderId = null;
          _selectedRating = 0;
          ratingController.clear();
          reviewController.clear();
        });
        _showSnackBar(context, jsonDecode(response.body)['message'], true);
      } else {
        setState(() => updateIsLoadingForId(bookingId, false));
        _showSnackBar(context, jsonDecode(response.body)['message'], false);
      }
    } catch (e) {
      setState(() => updateIsLoadingForId(bookingId, false));
      _showSnackBar(context, "Error: $e", false);
    }
  }

  // Show Rating Dialog
  void _showRatingDialog(
    BuildContext context,
    dynamic order,
    bool isDarkTheme,
  ) {
    final String bookingId = _getBookingId(order);
    final int existingRating = order['rating'] ?? 0;
    final String existingReview = order['review'] ?? '';

    if (existingRating > 0) {
      _showAlreadyRatedDialog(context, existingRating, existingReview);
      return;
    }

    _selectedRating = 0;
    _hoveredRating = 0;
    reviewController.clear();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: colorScheme.surface,
              child: Container(
                padding: EdgeInsets.all(0),
                constraints: BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, primaryColor.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.star_rate_rounded,
                                color: Colors.yellow[400],
                                size: 28,
                              ),
                              SizedBox(width: 12),
                              Text(
                                isHindiNotifier.value
                                    ? 'अपना अनुभव साझा करें'
                                    : 'Share Your Experience',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            isHindiNotifier.value
                                ? 'आपकी बुकिंग कैसी थी?'
                                : 'How was your booking?',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            isHindiNotifier.value
                                ? 'आपकी प्रतिक्रिया दूसरों को बेहतर निर्णय लेने में मदद करती है'
                                : 'Your feedback helps others make better decisions',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Star Rating
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(5, (index) {
                                    final starValue = index + 1;
                                    final isFilled =
                                        starValue <=
                                        (_hoveredRating > 0
                                            ? _hoveredRating
                                            : _selectedRating);
                                    return GestureDetector(
                                      onTap:
                                          () => setStateDialog(
                                            () => _selectedRating = starValue,
                                          ),

                                      child: AnimatedContainer(
                                        duration: Duration(milliseconds: 150),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: Icon(
                                          isFilled
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded,
                                          color:
                                              isFilled
                                                  ? Colors.amber
                                                  : Colors.grey[400],
                                          size: 44,
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                SizedBox(height: 8),
                                AnimatedSwitcher(
                                  duration: Duration(milliseconds: 200),
                                  child: Text(
                                    _selectedRating > 0
                                        ? _getRatingLabel(_selectedRating)
                                        : (isHindiNotifier.value
                                            ? 'रेटिंग देने के लिए स्टार पर टैप करें'
                                            : 'Tap a star to rate'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          _selectedRating > 0
                                              ? _getRatingColor(_selectedRating)
                                              : Colors.grey[500],
                                    ),
                                    key: ValueKey(_selectedRating),
                                  ),
                                ),
                                Text(
                                  _selectedRating > 0
                                      ? _getRatingSubtext(_selectedRating)
                                      : (isHindiNotifier.value
                                          ? '1 से 5 स्टार में से चुनें'
                                          : 'Choose from 1 to 5 stars'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Review TextField
                          TextFormField(
                            controller: reviewController,
                            maxLines: 3,
                            maxLength: 500,
                            decoration: InputDecoration(
                              labelText:
                                  isHindiNotifier.value
                                      ? '📝 समीक्षा लिखें'
                                      : '📝 Write a Review',
                              hintText:
                                  isHindiNotifier.value
                                      ? 'आपको क्या पसंद आया? मुख्य बातें साझा करें...'
                                      : 'What stood out to you? Share the highlights...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor:
                                  isDarkTheme
                                      ? Colors.grey[800]
                                      : Colors.grey[50],
                              prefixIcon: Icon(
                                Icons.edit_note,
                                color: Colors.grey[500],
                              ),
                              counterText: '',
                            ),
                          ),
                          SizedBox(height: 12),

                          // Suggestion chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildSuggestionChip(
                                isHindiNotifier.value
                                    ? '👍 बढ़िया सेवा!'
                                    : '👍 Great service!',
                              ),
                              _buildSuggestionChip(
                                isHindiNotifier.value
                                    ? '😊 पेशेवर और मिलनसार'
                                    : '😊 Professional and friendly',
                              ),
                              _buildSuggestionChip(
                                isHindiNotifier.value
                                    ? '⭐ अत्यधिक अनुशंसित!'
                                    : '⭐ Highly recommended!',
                              ),
                              _buildSuggestionChip(
                                isHindiNotifier.value
                                    ? '🔄 फिर से बुक करूंगा'
                                    : '🔄 Will book again',
                              ),
                            ],
                          ),

                          SizedBox(height: 16),

                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () {
                                    _selectedRating = 0;
                                    reviewController.clear();
                                    Navigator.pop(dialogContext);
                                  },
                                  child: Text(
                                    isHindiNotifier.value
                                        ? 'रद्द करें'
                                        : 'Cancel',
                                    style: TextStyle(
                                      color: Colors.red[400],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_selectedRating < 1 ||
                                        _selectedRating > 5) {
                                      _showSnackBar(
                                        context,
                                        isHindiNotifier.value
                                            ? 'कृपया रेटिंग चुनें'
                                            : 'Please select a rating',
                                        false,
                                      );
                                      return;
                                    }
                                    Navigator.pop(dialogContext);
                                    _handleRatingOrder(
                                      context: context,
                                      bookingId: bookingId,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    isHindiNotifier.value
                                        ? 'समीक्षा सबमिट करें'
                                        : 'Submit Review',
                                    style: TextStyle(
                                      color: colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
          },
        );
      },
    );
  }

  Widget _buildSuggestionChip(String label) {
    return GestureDetector(
      onTap: () {
        final current = reviewController.text;
        final cleanLabel = label.replaceAll(RegExp(r'[😊⭐👍🔄]'), '').trim();
        final newText = current + (current.isNotEmpty ? ' ' : '') + cleanLabel;
        reviewController.text = newText;
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
      ),
    );
  }

  String _getRatingLabel(int rating) {
    if (isHindiNotifier.value) {
      switch (rating) {
        case 1:
          return '😔 सुधार की जरूरत';
        case 2:
          return '😕 बेहतर हो सकता था';
        case 3:
          return '😐 ठीक था';
        case 4:
          return '😊 अच्छा अनुभव';
        case 5:
          return '🌟 उत्कृष्ट!';
        default:
          return 'रेटिंग देने के लिए स्टार पर टैप करें';
      }
    }
    switch (rating) {
      case 1:
        return '😔 Needs Improvement';
      case 2:
        return '😕 Could Be Better';
      case 3:
        return '😐 It Was Okay';
      case 4:
        return '😊 Good Experience';
      case 5:
        return '🌟 Excellent!';
      default:
        return 'Tap a star to rate';
    }
  }

  String _getRatingSubtext(int rating) {
    if (isHindiNotifier.value) {
      switch (rating) {
        case 1:
          return "अगली बार बेहतर करेंगे";
        case 2:
          return "आपकी ईमानदारी के लिए धन्यवाद";
        case 3:
          return "सुधार की गुंजाइश है";
        case 4:
          return "खुशी है कि आपको पसंद आया!";
        case 5:
          return "बिल्कुल अद्भुत अनुभव!";
        default:
          return '1 से 5 स्टार में से चुनें';
      }
    }
    switch (rating) {
      case 1:
        return "We'll do better next time";
      case 2:
        return 'Thank you for your honesty';
      case 3:
        return 'Room for improvement';
      case 4:
        return 'Glad you enjoyed it!';
      case 5:
        return 'Absolutely amazing experience!';
      default:
        return 'Choose from 1 to 5 stars';
    }
  }

  Color _getRatingColor(int rating) {
    if (rating >= 4) return Colors.green;
    if (rating >= 3) return Colors.orange;
    if (rating > 0) return Colors.red;
    return Colors.grey;
  }

  void _showAlreadyRatedDialog(
    BuildContext context,
    int rating,
    String review,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: colorScheme.surface,
            title: Column(
              children: [
                Icon(Icons.star_rounded, color: Colors.amber, size: 48),
                SizedBox(height: 8),
                Text(
                  isHindiNotifier.value
                      ? '🌟 पहले ही रेट किया जा चुका है!'
                      : '🌟 Already Rated!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 32,
                    );
                  }),
                ),
                SizedBox(height: 8),
                Text(
                  isHindiNotifier.value
                      ? 'आपने इस विक्रेता को $rating/5 रेट किया'
                      : 'You rated this vendor $rating/5',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (review.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '"$review"',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 8),
                Text(
                  isHindiNotifier.value
                      ? 'आपकी प्रतिक्रिया के लिए धन्यवाद! 🙏'
                      : 'Thank you for your feedback! 🙏',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  isHindiNotifier.value ? 'ठीक है' : 'Got it',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final surface = colorScheme.surface;
    final onSurface = colorScheme.onSurface;
    // final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 400;

    return ValueListenableBuilder<bool>(
      valueListenable: isDarkThemeNotifier,
      builder: (context, isDarkTheme, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: isVendor,
          builder: (context, isVendor, _) {
            return Padding(
              padding: EdgeInsets.all(mediaQuery.size.width * 0.025),
              child: Column(
                children: [
                  // Wrap TabBar with ValueListenableBuilder to react to language changes
                  ValueListenableBuilder<bool>(
                    valueListenable: isHindiNotifier,
                    builder: (context, isHindi, _) {
                      return _buildModernTabBar(
                        isDarkTheme,
                        mediaQuery,
                        isSmallScreen,
                        primaryColor,
                        colorScheme,
                      );
                    },
                  ),
                  SizedBox(height: mediaQuery.size.height * 0.015),
                  Expanded(
                    child: _buildOrderList(
                      isDarkTheme,
                      mediaQuery,
                      isSmallScreen,
                      primaryColor,
                      surface,
                      onSurface,
                    ),
                  ),
                  _buildModernPagination(
                    isDarkTheme,
                    mediaQuery,
                    isSmallScreen,
                    primaryColor,
                    colorScheme,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModernTabBar(
    bool isDarkTheme,
    MediaQueryData mediaQuery,
    bool isSmallScreen,
    Color primaryColor,
    ColorScheme colorScheme,
  ) {
    final isHindi = isHindiNotifier.value;
    final tabs = [
      {
        'label': isHindi ? 'लंबित' : 'Pending',
        'count': pendingCount,
        'color': primaryColor,
      },
      {
        'label': isHindi ? 'पूर्ण' : 'Completed',
        'count': completedCount,
        'color': Colors.green,
      },
      {
        'label': isHindi ? 'रद्द' : 'Canceled',
        'count': canceledCount,
        'color': colorScheme.error,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDarkTheme ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDarkTheme
                  ? Colors.white.withOpacity(0.06)
                  : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkTheme ? 0.2 : 0.04),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(4),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final tab = tabs[index];
            final isSelected = orderDetails == index + 1;
            final Color tabColor = tab['color'] as Color;
            final int count = tab['count'] as int;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    orderDetails = index + 1;
                    _tabController.animateTo(index);
                  });
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 250),
                  height: mediaQuery.size.height * 0.055,
                  decoration: BoxDecoration(
                    color: isSelected ? tabColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? tabColor : Colors.transparent,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tab['label'] as String,
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? colorScheme.onPrimary
                                      : (isDarkTheme
                                          ? Colors.white70
                                          : Colors.grey[600]),
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                              fontSize: isSmallScreen ? 11 : 13,
                            ),
                          ),
                          if (count > 0) ...[
                            SizedBox(width: 6),
                            AnimatedContainer(
                              duration: Duration(milliseconds: 250),
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? Colors.white.withOpacity(0.3)
                                        : tabColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  color:
                                      isSelected ? Colors.white : Colors.white,
                                  fontSize: isSmallScreen ? 9 : 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (isSelected)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 3,
                            color: Colors.white.withOpacity(0.5),
                            margin: EdgeInsets.symmetric(horizontal: 20),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildModernPagination(
    bool isDarkTheme,
    MediaQueryData mediaQuery,
    bool isSmallScreen,
    Color primaryColor,
    ColorScheme colorScheme,
  ) {
    final canGoBack = pageNo > 1;
    final totalPages = (totalOrders / 12).ceil();
    final totalPagesCount = totalPages == 0 ? 1 : totalPages;
    final canGoForward = totalOrders > 12 && pageNo < totalPagesCount;

    return Container(
      height: mediaQuery.size.height * 0.065,
      padding: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDarkTheme ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDarkTheme
                  ? Colors.white.withOpacity(0.06)
                  : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkTheme ? 0.2 : 0.04),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPaginationButton(
            icon: Icons.chevron_left_rounded,
            onTap: canGoBack ? _goToPreviousPage : null,
            isDarkTheme: isDarkTheme,
            primaryColor: primaryColor,
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(
              color: (isDarkTheme ? Colors.white : Colors.black).withOpacity(
                0.08,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$pageNo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 14 : 16,
                    color: isDarkTheme ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  ' / $totalPagesCount',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: isDarkTheme ? Colors.white60 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          _buildPaginationButton(
            icon: Icons.chevron_right_rounded,
            onTap: canGoForward ? _goToNextPage : null,
            isDarkTheme: isDarkTheme,
            primaryColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationButton({
    required IconData icon,
    VoidCallback? onTap,
    required bool isDarkTheme,
    required Color primaryColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:
                onTap != null
                    ? (isDarkTheme
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05))
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color:
                onTap != null
                    ? (isDarkTheme ? Colors.white : Colors.black)
                    : (isDarkTheme ? Colors.white30 : Colors.grey[400]),
            size: 24,
          ),
        ),
      ),
    );
  }

  void _goToPreviousPage() {
    setState(() {
      pageNo--;
      futureCards = _fetchCards(
        user?.userId.toString() ?? vendor?.vendorId.toString() ?? '',
        pageNo,
        'Bearer ${user?.token ?? vendor?.token ?? ''}',
      );
    });
  }

  void _goToNextPage() {
    setState(() {
      pageNo++;
      futureCards = _fetchCards(
        user?.userId.toString() ?? vendor?.vendorId.toString() ?? '',
        pageNo,
        'Bearer ${user?.token ?? vendor?.token ?? ''}',
      );
    });
  }

  Widget _buildOrderList(
    bool isDarkTheme,
    MediaQueryData mediaQuery,
    bool isSmallScreen,
    Color primaryColor,
    Color surface,
    Color onSurface,
  ) {
    return ValueListenableBuilder<bool>(
      valueListenable: isHindiNotifier,
      builder: (context, isHindi, _) {
        return FutureBuilder<Map<String, dynamic>>(
          future: futureCards,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Container(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    color: primaryColor,
                    strokeWidth: 3,
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: Colors.red[400],
                    ),
                    SizedBox(height: 12),
                    Text(
                      isHindi
                          ? 'ऑर्डर लोड करने में विफल'
                          : 'Failed to load orders',
                      style: TextStyle(
                        color: isDarkTheme ? Colors.white : Colors.black,
                        fontSize: mediaQuery.size.width * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "${snapshot.error}",
                      style: TextStyle(
                        color: isDarkTheme ? Colors.white60 : Colors.grey[600],
                        fontSize: 12,
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
                    Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: isDarkTheme ? Colors.white30 : Colors.grey[400],
                    ),
                    SizedBox(height: 12),
                    Text(
                      isHindi ? 'कोई ऑर्डर उपलब्ध नहीं' : 'No orders available',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: mediaQuery.size.width * 0.045,
                        color: isDarkTheme ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Get ALL orders without filtering by status
            final allOrders = snapshot.data!["orders"] ?? [];

            // Now filter by status for display
            final ordersList =
                allOrders.where((order) {
                  if (orderDetails == 1) {
                    return !order['cancelOrder'] && !order['orderCompleted'];
                  }
                  if (orderDetails == 2) return order['orderCompleted'] == true;
                  if (orderDetails == 3) return order['cancelOrder'] == true;
                  return true;
                }).toList();

            if (ordersList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: isDarkTheme ? Colors.white30 : Colors.grey[400],
                    ),
                    SizedBox(height: 12),
                    Text(
                      _getEmptyStateMessage(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: mediaQuery.size.width * 0.045,
                        color: isDarkTheme ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Simple approach: show an ad after every 2 orders
            final List<Widget> items = [];

            for (int i = 0; i < ordersList.length; i++) {
              // Add the order
              items.add(
                _buildModernOrderCard(
                  context,
                  ordersList[i],
                  isDarkTheme,
                  mediaQuery,
                  isSmallScreen,
                  i,
                  primaryColor,
                  surface,
                  onSurface,
                ),
              );
            }

            return ListView(
              padding: EdgeInsets.symmetric(horizontal: 2),
              children: items,
            );
          },
        );
      },
    );
  }

  String _getEmptyStateMessage() {
    final isHindi = isHindiNotifier.value;
    switch (orderDetails) {
      case 1:
        return isHindi ? "कोई लंबित ऑर्डर नहीं" : "No pending orders";
      case 2:
        return isHindi ? "कोई पूर्ण ऑर्डर नहीं" : "No completed orders";
      case 3:
        return isHindi ? "कोई रद्द ऑर्डर नहीं" : "No canceled orders";
      default:
        return isHindi ? "कोई ऑर्डर उपलब्ध नहीं" : "No orders available";
    }
  }

  Widget _buildModernOrderCard(
    BuildContext context,
    dynamic order,
    bool isDarkTheme,
    MediaQueryData mediaQuery,
    bool isSmallScreen,
    int index,
    Color primaryColor,
    Color surface,
    Color onSurface,
  ) {
    final isHindi = isHindiNotifier.value;
    final String bookingId = _getBookingId(order);
    final bool isCancelLoading = isLoadingC[bookingId] ?? false;
    final bool isCompleteLoading = isLoading[bookingId] ?? false;

    // Fix: Check if userId and vendorId exist and are equal
    final String? orderUserId = order['userId']?.toString();
    final String? orderVendorId = order['vendorId']?.toString();

    // Check if this is a self-booked order
    final bool isSelfBooked =
        orderUserId != null &&
        orderVendorId != null &&
        orderUserId.isNotEmpty &&
        orderVendorId.isNotEmpty &&
        orderUserId == orderVendorId;

    Color statusColor;
    String statusIcon;
    String statusLabel;

    if (order['cancelOrder'] == true) {
      statusColor = const Color(0xFFEF4444);
      statusIcon = '✕';
      statusLabel = isHindi ? 'रद्द' : 'Canceled';
    } else if (order['orderCompleted'] == true) {
      statusColor = const Color(0xFF22C55E);
      statusIcon = '✓';
      statusLabel = isHindi ? 'पूर्ण' : 'Completed';
    } else {
      statusColor = primaryColor;
      statusIcon = '⏳';
      statusLabel = isHindi ? 'लंबित' : 'Pending';
    }

    // Parse and convert date to Asia/Kolkata timezone
    String formattedDate = 'Date not available';
    if (order['date'] != null) {
      final dateStr = order['date'].toString();
      final parsedDate = _parseAndConvertToAsiaKolkata(dateStr);
      formattedDate = _formatDate(parsedDate);
    }

    // Get order type with proper capitalization
    String orderType = order['type']?.toString() ?? 'Service';
    String orderName = order['name']?.toString() ?? 'Unknown';

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.only(bottom: mediaQuery.size.height * 0.015),
      decoration: BoxDecoration(
        color: isDarkTheme ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDarkTheme ? 0.2 : 0.04),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Status Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: statusColor.withOpacity(0.08),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(statusIcon, style: TextStyle(fontSize: 14)),
                      SizedBox(width: 6),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 11 : 13,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '#${bookingId.substring(0, bookingId.length > 8 ? 8 : bookingId.length)}',
                    style: TextStyle(
                      color: isDarkTheme ? Colors.white60 : Colors.grey[500],
                      fontSize: isSmallScreen ? 10 : 12,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [statusColor, statusColor.withOpacity(0.6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            orderName.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _capitalizeWords(orderName),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 14 : 16,
                                color: isDarkTheme ? Colors.white : onSurface,
                              ),
                            ),
                            Text(
                              _capitalizeWords(orderType),
                              style: TextStyle(
                                color:
                                    isDarkTheme
                                        ? Colors.white60
                                        : Colors.grey[600],
                                fontSize: isSmallScreen ? 11 : 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  // Details Grid
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isDarkTheme
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildModernDetailRow(
                          '📞',
                          order['phoneNo']?.toString() ?? 'N/A',
                          isDarkTheme,
                          isSmallScreen,
                        ),
                        _buildModernDivider(isDarkTheme),
                        _buildModernDetailRow(
                          '📅',
                          formattedDate,
                          isDarkTheme,
                          isSmallScreen,
                          isColored: true,
                        ),
                        if (isSelfBooked) ...[
                          _buildModernDivider(isDarkTheme),
                          _buildModernDetailRow(
                            '👤',
                            isHindi ? 'स्वयं बुक' : 'Self Booked',
                            isDarkTheme,
                            isSmallScreen,
                            isColored: true,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Actions - Using Theme Colors
                  if (orderDetails == 1) ...[
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildModernActionButton(
                            context,
                            isHindi ? 'रद्द करें' : 'Cancel',
                            Colors.red,
                            () => _handleCancelOrder(
                              context: context,
                              bookingId: bookingId,
                            ),
                            isLoading: isCancelLoading,
                            icon: Icons.close_rounded,
                            isDarkTheme: isDarkTheme,
                            primaryColor: primaryColor,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _buildModernActionButton(
                            context,
                            isHindi ? 'पूर्ण करें' : 'Complete',
                            primaryColor,
                            () => _handleMarkAsCompletedOrder(
                              context: context,
                              bookingId: bookingId,
                            ),
                            isLoading: isCompleteLoading,
                            icon: Icons.check_rounded,
                            isDarkTheme: isDarkTheme,
                            primaryColor: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (orderDetails == 2) ...[
                    SizedBox(height: 12),
                    _buildModernRatingSection(
                      context,
                      order,
                      isDarkTheme,
                      mediaQuery,
                      primaryColor,
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

  Widget _buildModernDetailRow(
    String icon,
    String value,
    bool isDarkTheme,
    bool isSmallScreen, {
    bool isColored = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(icon, style: TextStyle(fontSize: isSmallScreen ? 12 : 14)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              _capitalizeWords(value),
              style: TextStyle(
                color:
                    isColored
                        ? const Color(0xFF4F46E5)
                        : (isDarkTheme ? Colors.white : Colors.black),
                fontWeight: isColored ? FontWeight.bold : FontWeight.w500,
                fontSize: isSmallScreen ? 12 : 14,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDivider(bool isDarkTheme) {
    return Divider(
      height: 8,
      color: isDarkTheme ? Colors.white.withOpacity(0.06) : Colors.grey[200],
    );
  }

  Widget _buildModernActionButton(
    BuildContext context,
    String text,
    Color color,
    VoidCallback onPressed, {
    bool isLoading = false,
    required IconData icon,
    required bool isDarkTheme,
    required Color primaryColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: colorScheme.onPrimary,
        padding: EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      onPressed: isLoading ? null : onPressed,
      child:
          isLoading
              ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.onPrimary,
                ),
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: colorScheme.onPrimary),
                  SizedBox(width: 6),
                  Text(
                    text,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildModernRatingSection(
    BuildContext context,
    dynamic order,
    bool isDarkTheme,
    MediaQueryData mediaQuery,
    Color primaryColor,
  ) {
    final isHindi = isHindiNotifier.value;
    final String bookingId = _getBookingId(order);
    final int rating = order['rating'] ?? 0;
    final String review = order['review'] ?? '';
    final bool isLoadingRating = isLoading[bookingId] ?? false;

    if (rating > 0) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isDarkTheme
                  ? Colors.white.withOpacity(0.05)
                  : const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('⭐', style: TextStyle(fontSize: 14)),
                SizedBox(width: 8),
                Text(
                  isHindi ? 'रेटिंग' : 'Rated',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '$rating/5',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                SizedBox(width: 8),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ),
              ],
            ),
            if (review.isNotEmpty) ...[
              SizedBox(height: 4),
              Text(
                '📝 "$review"',
                style: TextStyle(
                  color: isDarkTheme ? Colors.white70 : Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return _buildModernActionButton(
      context,
      isHindi ? 'रेटिंग दें' : 'Give Rating',
      primaryColor,
      () => _showRatingDialog(context, order, isDarkTheme),
      isLoading: isLoadingRating,
      icon: Icons.star_rate_rounded,
      isDarkTheme: isDarkTheme,
      primaryColor: primaryColor,
    );
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

  void _showSnackBar(BuildContext context, String message, bool isSuccess) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isSuccess ? colorScheme.primary : colorScheme.error,
        content: Center(
          child: Text(
            message,
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        duration: Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ),
    );
  }
}

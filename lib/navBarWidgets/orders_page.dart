// this file is made responsive for all devices.

import 'dart:convert';
import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/models/data_model.dart';
import 'package:app_aapkakaam/widgets/banner_ad_widget.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
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

  // Counters for badges
  int pendingCount = 0;
  int completedCount = 0;
  int canceledCount = 0;

  @override
  void initState() {
    super.initState();
    isLoadingC = {};
    isLoading = {};
    _loadUserData();
  }

  @override
  void dispose() {
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

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final vendorData = prefs.getString('vendor');

    if (userData != null) {
      final decodedUser = jsonDecode(userData);
      setState(() {
        user = UserModel.fromJson(decodedUser);
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
        print(jsonResponse);
        totalOrders = jsonResponse['total'] ?? 0;
        initializeIsLoadingCFromResponse(jsonResponse);
        _calculateOrderCounts(jsonResponse);
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
      } else if (order['cancelOrder'] == false &&
          order['orderCompleted'] == false) {
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

  // Show confirmation dialog
  Future<bool> _showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
    String confirmText,
    Color confirmColor,
  ) async {
    return await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('No', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
                child: Text(
                  confirmText,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    ).then((value) => value ?? false);
  }

  // Cancel Order
  Future<void> _handleCancelOrder({
    required BuildContext context,
    required String bookingId,
  }) async {
    if (bookingId.isEmpty) {
      _showSnackBar(context, 'Booking ID is required', false);
      return;
    }

    final confirmed = await _showConfirmationDialog(
      context,
      'Cancel Order',
      'Are you sure you want to cancel this order?',
      'Yes, Cancel',
      Colors.red,
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
          responseData['message'] ?? 'Order cancelled successfully',
          true,
        );
      } else {
        setState(() => updateIsLoadingForIdC(bookingId, false));
        final error = jsonDecode(response.body);
        _showSnackBar(
          context,
          error['message'] ?? 'Failed to cancel order',
          false,
        );
      }
    } catch (e) {
      setState(() => updateIsLoadingForIdC(bookingId, false));
      _showSnackBar(context, "Error: $e", false);
    }
  }

  // Mark as Completed
  Future<void> _handleMarkAsCompletedOrder({
    required BuildContext context,
    required String bookingId,
  }) async {
    if (bookingId.isEmpty) {
      _showSnackBar(context, 'Booking ID is required', false);
      return;
    }

    final confirmed = await _showConfirmationDialog(
      context,
      'Mark as Completed',
      'Are you sure you want to mark this order as completed?',
      'Yes, Complete',
      Colors.green,
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
          responseData['message'] ?? 'Order completed successfully',
          true,
        );
      } else {
        setState(() => updateIsLoadingForId(bookingId, false));
        final error = jsonDecode(response.body);
        _showSnackBar(
          context,
          error['message'] ?? 'Failed to complete order',
          false,
        );
      }
    } catch (e) {
      setState(() => updateIsLoadingForId(bookingId, false));
      _showSnackBar(context, "Error: $e", false);
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
    // Check if already rated
    // This will be handled in the UI

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

    // If already rated, show info
    if (existingRating > 0) {
      _showAlreadyRatedDialog(context, existingRating, existingReview);
      return;
    }

    _selectedRating = 0;
    ratingController.clear();
    reviewController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.shade400,
                          Colors.deepPurple.shade700,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share Your Experience',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'How was your booking? ✨',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Your feedback helps others make better decisions',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Star Rating
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              final starValue = index + 1;
                              return GestureDetector(
                                onTap: () {
                                  setStateDialog(() {
                                    _selectedRating = starValue;
                                  });
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: Icon(
                                    starValue <= _selectedRating
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 40,
                                  ),
                                ),
                              );
                            }),
                          ),
                          SizedBox(height: 8),
                          Text(
                            _getRatingLabel(_selectedRating),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _getRatingColor(_selectedRating),
                            ),
                          ),
                          Text(
                            _getRatingSubtext(_selectedRating),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
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
                        labelText: '📝 Write a Review',
                        hintText:
                            'What stood out to you? Share the highlights...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor:
                            isDarkTheme ? Colors.grey[800] : Colors.grey[50],
                        counterText: '${reviewController.text.length}/500',
                      ),
                    ),
                    SizedBox(height: 12),
                    // Suggestion chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildSuggestionChip('👍 Great service!', () {
                          final current = reviewController.text;
                          final newText =
                              current +
                              (current.isNotEmpty ? ' ' : '') +
                              'Great service! 👍';
                          reviewController.text = newText;
                        }),
                        _buildSuggestionChip(
                          '😊 Professional and friendly',
                          () {
                            final current = reviewController.text;
                            final newText =
                                current +
                                (current.isNotEmpty ? ' ' : '') +
                                'Professional and friendly 😊';
                            reviewController.text = newText;
                          },
                        ),
                        _buildSuggestionChip('⭐ Highly recommended!', () {
                          final current = reviewController.text;
                          final newText =
                              current +
                              (current.isNotEmpty ? ' ' : '') +
                              'Highly recommended! ⭐';
                          reviewController.text = newText;
                        }),
                        _buildSuggestionChip('🔄 Will book again', () {
                          final current = reviewController.text;
                          final newText =
                              current +
                              (current.isNotEmpty ? ' ' : '') +
                              'Will book again 🔄';
                          reviewController.text = newText;
                        }),
                      ],
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            isDarkTheme ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '💡 Your review helps the community. Be honest and constructive!',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDarkTheme ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _selectedRating = 0;
                    ratingController.clear();
                    reviewController.clear();
                    Navigator.pop(dialogContext);
                  },
                  child: Text('Cancel', style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_selectedRating < 1 || _selectedRating > 5) {
                      _showSnackBar(
                        context,
                        'Please select a rating between 1 and 5',
                        false,
                      );
                      return;
                    }
                    Navigator.pop(dialogContext);
                    _handleRatingOrder(context: context, bookingId: bookingId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                  ),
                  child: Text(
                    '🌟 Submit Review',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSuggestionChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[700]),
        ),
      ),
    );
  }

  String _getRatingLabel(int rating) {
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
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Column(
              children: [
                Text(
                  '🌟 Already Rated!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
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
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    );
                  }),
                ),
                SizedBox(height: 8),
                Text(
                  'You rated this vendor $rating/5',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                if (review.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '"$review"',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 8),
                Text(
                  'Thank you for your feedback! 🙏',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  '👍 Got it',
                  style: TextStyle(color: Colors.purple),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return ValueListenableBuilder<bool>(
      valueListenable: isDarkThemeNotifier,
      builder: (context, isDarkTheme, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: isVendor,
          builder: (context, isVendor, _) {
            return Padding(
              padding: EdgeInsets.all(mediaQuery.size.width * 0.02),
              child: Column(
                children: [
                  _buildTabBar(isDarkTheme, mediaQuery),
                  SizedBox(height: mediaQuery.size.height * 0.01),
                  Expanded(child: _buildOrderList(isDarkTheme, mediaQuery)),
                  SizedBox(height: mediaQuery.size.height * 0.01),
                  _buildPaginationControls(isDarkTheme, mediaQuery),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaginationControls(bool isDarkTheme, MediaQueryData mediaQuery) {
    final canGoBack = pageNo > 1;
    final canGoForward = totalOrders > 12 && pageNo < totalOrders / 12;
    final totalPage = (totalOrders / 12).ceil();
    final totalPages = totalPage == 0 ? 1 : totalPage;
    return Container(
      height: mediaQuery.size.height * 0.06,
      padding: EdgeInsets.symmetric(horizontal: mediaQuery.size.width * 0.02),
      decoration: BoxDecoration(
        color: isDarkTheme ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            color: isDarkTheme ? Colors.white : Colors.black,
            onPressed: canGoBack ? _goToPreviousPage : null,
          ),
          Text(
            '$pageNo/$totalPages',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: mediaQuery.size.width * 0.045,
              color: isDarkTheme ? Colors.white : Colors.black,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            color: isDarkTheme ? Colors.white : Colors.black,
            onPressed:
                canGoForward ? _goToNextPage : () => _showEndDialog(context),
          ),
        ],
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

  void _showEndDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("No more pages"),
            content: const Text("You have reached the end."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  Widget _buildTabBar(bool isDarkTheme, MediaQueryData mediaQuery) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: mediaQuery.size.height * 0.01),
      decoration: BoxDecoration(
        color: isDarkTheme ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTabWithBadge(
            'Pending',
            1,
            Colors.blue,
            pendingCount,
            isDarkTheme,
            mediaQuery,
          ),
          _buildTabWithBadge(
            'Completed',
            2,
            Colors.green,
            completedCount,
            isDarkTheme,
            mediaQuery,
          ),
          _buildTabWithBadge(
            'Canceled',
            3,
            Colors.red,
            canceledCount,
            isDarkTheme,
            mediaQuery,
          ),
        ],
      ),
    );
  }

  Widget _buildTabWithBadge(
    String text,
    int value,
    Color color,
    int count,
    bool isDarkTheme,
    MediaQueryData mediaQuery,
  ) {
    return count == 0
        ? _buildOrderTab(text, value, color, isDarkTheme, mediaQuery)
        : Stack(
          clipBehavior: Clip.none,
          children: [
            _buildOrderTab(text, value, color, isDarkTheme, mediaQuery),
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.pink,
                  shape: BoxShape.circle,
                ),
                constraints: BoxConstraints(minWidth: 20, minHeight: 20),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
  }

  Widget _buildOrderList(bool isDarkTheme, MediaQueryData mediaQuery) {
    return FutureBuilder<Map<String, dynamic>>(
      future: futureCards,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: isDarkTheme ? Colors.white : Colors.black,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error: ${snapshot.error}",
              style: TextStyle(
                color: isDarkTheme ? Colors.white : Colors.black,
                fontSize: mediaQuery.size.width * 0.04,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              "No orders available",
              style: TextStyle(
                color: isDarkTheme ? Colors.white : Colors.black,
                fontSize: mediaQuery.size.width * 0.04,
              ),
            ),
          );
        }

        final ordersList =
            (snapshot.data!["orders"] ?? []).where((order) {
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
              children: [
                SizedBox(height: 18),
                Center(child: BannerAdWidget()),
                SizedBox(height: 18),
                Text(
                  _getEmptyStateMessage(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: mediaQuery.size.width * 0.04,
                    color: isDarkTheme ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: mediaQuery.size.width * 0.02,
          ),
          itemCount: ordersList.length,
          itemBuilder:
              (context, index) => Column(
                children: [
                  index % 3 == 0
                      ? Center(child: BannerAdWidget())
                      : const SizedBox.shrink(),
                  index % 3 == 0
                      ? SizedBox(height: 8)
                      : const SizedBox.shrink(),
                  _buildOrderCard(
                    context,
                    ordersList[index],
                    isDarkTheme,
                    mediaQuery,
                    index,
                  ),
                ],
              ),
        );
      },
    );
  }

  String _getEmptyStateMessage() {
    switch (orderDetails) {
      case 1:
        return "No pending orders available";
      case 2:
        return "No completed orders available";
      case 3:
        return "No canceled orders available";
      default:
        return "No orders available";
    }
  }

  Widget _buildOrderCard(
    BuildContext context,
    dynamic order,
    bool isDarkTheme,
    MediaQueryData mediaQuery,
    int index,
  ) {
    final isSmallScreen = mediaQuery.size.width < 350;
    final String bookingId = _getBookingId(order);
    final bool isCancelLoading = isLoadingC[bookingId] ?? false;
    final bool isCompleteLoading = isLoading[bookingId] ?? false;
    final int rating =
        order['rating'] is num ? (order['rating'] as num).toInt() : 0;

    final String review = order['review']?.toString() ?? '';

    final String userId = order['userId']?.toString() ?? '';
    final String vendorId = order['vendorId']?.toString() ?? '';

    final bool isSelfBooked =
        userId.isNotEmpty && vendorId.isNotEmpty && userId == vendorId;

    Color borderColor;
    if (order['cancelOrder'] == true) {
      borderColor = Colors.red;
    } else if (order['orderCompleted'] == true) {
      borderColor = Colors.green;
    } else {
      borderColor = Colors.blue;
    }

    return Container(
      margin: EdgeInsets.only(bottom: mediaQuery.size.height * 0.015),
      padding: EdgeInsets.all(mediaQuery.size.width * 0.03),
      decoration: BoxDecoration(
        color: isDarkTheme ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildOrderInfoRow('Name', order['name'], isDarkTheme, isSmallScreen),
          _buildOrderInfoRow(
            'Mobile',
            order['phoneNo'].toString(),
            isDarkTheme,
            isSmallScreen,
          ),
          _buildOrderInfoRow(
            'Profession',
            order['type'],
            isDarkTheme,
            isSmallScreen,
          ),
          _buildOrderInfoRow(
            'Date',
            DateTime.parse(order['date']).toLocal().toString().split(' ')[0],
            isDarkTheme,
            isSmallScreen,
          ),
          if (isSelfBooked)
            _buildOrderInfoRow(
              'Self Booked',
              'Yes',
              isDarkTheme,
              isSmallScreen,
            ),

          // Pending Order Actions
          if (orderDetails == 1) ...[
            SizedBox(height: mediaQuery.size.height * 0.01),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Cancel Order',
                    Colors.red,
                    () => _handleCancelOrder(
                      context: context,
                      bookingId: bookingId,
                    ),
                    isLoading: isCancelLoading,
                  ),
                ),
                SizedBox(width: mediaQuery.size.width * 0.02),
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Mark Completed',
                    Colors.green,
                    () => _handleMarkAsCompletedOrder(
                      context: context,
                      bookingId: bookingId,
                    ),
                    isLoading: isCompleteLoading,
                  ),
                ),
              ],
            ),
          ],

          // Completed Order Rating Section
          if (orderDetails == 2) ...[
            SizedBox(height: mediaQuery.size.height * 0.01),
            _buildRatingSection(context, order, isDarkTheme, mediaQuery),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderInfoRow(
    String label,
    String value,
    bool isDarkTheme,
    bool isSmallScreen,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 2.0 : 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 12 : 14,
              color: isDarkTheme ? Colors.white : Colors.black,
            ),
          ),
          Text(
            _capitalizeWords(value),
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              color: _getStatusColor(orderDetails),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildActionButton(
    BuildContext context,
    String text,
    Color color,
    VoidCallback onPressed, {
    bool isLoading = false,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.height * 0.01,
        ),
        minimumSize: Size(double.infinity, 40),
      ),
      onPressed: isLoading ? null : onPressed,
      child:
          isLoading
              ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
              : Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: MediaQuery.of(context).size.width * 0.035,
                ),
              ),
    );
  }

  Widget _buildRatingSection(
    BuildContext context,
    dynamic order,
    bool isDarkTheme,
    MediaQueryData mediaQuery,
  ) {
    final String bookingId = _getBookingId(order);
    final int rating = order['rating'] ?? 0;
    final String review = order['review'] ?? '';
    final bool isLoadingRating = isLoading[bookingId] ?? false;

    // Already rated
    if (rating > 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Rated',
                style: TextStyle(
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.bold,
                  fontSize: mediaQuery.size.width * 0.04,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$rating/5',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: mediaQuery.size.width * 0.04,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: mediaQuery.size.width * 0.04,
                  );
                }),
              ),
            ],
          ),
          if (review.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reviewed',
                  style: TextStyle(
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: mediaQuery.size.width * 0.04,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    review,
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: mediaQuery.size.width * 0.04,
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    }

    // Show "Give Rating" button - opens enhanced rating dialog
    return _buildActionButton(
      context,
      'Give Rating & Review',
      Colors.blue,
      () => _showRatingDialog(context, order, isDarkTheme),
      isLoading: isLoadingRating,
    );
  }

  Widget _buildOrderTab(
    String text,
    int value,
    Color color,
    bool isDarkTheme,
    MediaQueryData mediaQuery,
  ) {
    final isSelected = orderDetails == value;

    return GestureDetector(
      onTap: () => setState(() => orderDetails = value),
      child: Container(
        padding: EdgeInsets.all(mediaQuery.size.width * 0.01),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected
                    ? (isDarkTheme ? Colors.white : Colors.black)
                    : (isDarkTheme ? Colors.black : Colors.white),
            width: 2,
          ),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: mediaQuery.size.width * 0.03,
            vertical: mediaQuery.size.height * 0.01,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isDarkTheme ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: mediaQuery.size.width * 0.035,
            ),
          ),
        ),
      ),
    );
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

  void _showSnackBar(BuildContext context, String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        content: Center(
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

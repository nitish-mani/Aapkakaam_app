// this file is made responsive for all devices.

import 'dart:convert';
import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/models/data_model.dart';
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

  @override
  void initState() {
    super.initState();
    isLoadingC = {}; // Initialize as empty map
    isLoading = {}; // Initialize as empty map
    _loadUserData();
  }

  @override
  void dispose() {
    ratingController.dispose();
    super.dispose();
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
        totalOrders = jsonResponse['total'] ?? 0;
        initializeIsLoadingCFromResponse(jsonResponse);
        return jsonResponse;
      }
      throw Exception("Failed to load orders: ${response.statusCode}");
    } catch (e) {
      throw Exception("Error fetching orders: $e");
    }
  }

  void initializeIsLoadingCFromResponse(Map<String, dynamic> response) {
    List<dynamic> orders = response['orders'] ?? [];
    isLoadingC = {for (var order in orders) order['_id']: false};
    isLoading = {for (var order in orders) order['_id']: false};
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

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    // final isPortrait = mediaQuery.orientation == Orientation.portrait;

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
            '$pageNo',
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
          _buildOrderTab('Pending', 1, Colors.blue, isDarkTheme, mediaQuery),
          _buildOrderTab('Completed', 2, Colors.green, isDarkTheme, mediaQuery),
          _buildOrderTab('Canceled', 3, Colors.red, isDarkTheme, mediaQuery),
        ],
      ),
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
            child: Text(
              _getEmptyStateMessage(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: mediaQuery.size.width * 0.04,
                color: isDarkTheme ? Colors.white : Colors.black,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: mediaQuery.size.width * 0.02,
          ),
          itemCount: ordersList.length,
          itemBuilder:
              (context, index) => _buildOrderCard(
                context,
                ordersList[index],
                isDarkTheme,
                mediaQuery,
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
  ) {
    final isSmallScreen = mediaQuery.size.width < 350;

    return Container(
      margin: EdgeInsets.only(bottom: mediaQuery.size.height * 0.015),
      padding: EdgeInsets.all(mediaQuery.size.width * 0.03),
      decoration: BoxDecoration(
        color: isDarkTheme ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(8),
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
          _buildOrderInfoRow('Date', order['date'], isDarkTheme, isSmallScreen),

          if (orderDetails == 1) ...[
            SizedBox(height: mediaQuery.size.height * 0.01),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Cancel Order',
                    Colors.red,
                    () => _showOrdersDialog(context, 'cancel', order['_id']),
                    isLoading: isLoadingC[order['_id']] ?? false,
                  ),
                ),
                SizedBox(width: mediaQuery.size.width * 0.02),
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Mark Completed',
                    Colors.green,
                    () => _showOrdersDialog(
                      context,
                      'mark as completed',
                      order['_id'],
                    ),
                    isLoading: isLoading[order['_id']] ?? false,
                  ),
                ),
              ],
            ),
          ],

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
      ),
      onPressed: isLoading ? null : onPressed,
      child:
          isLoading
              ? SizedBox(
                width: 16,
                height: 16,
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
    if (order['rating'] != 0) {
      return Text(
        'You have rated [ ${order['rating']}/5 ]',
        style: TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
          fontSize: mediaQuery.size.width * 0.04,
        ),
        textAlign: TextAlign.center,
      );
    }

    if (ratingOrderId == order['_id']) {
      return Column(
        children: [
          TextFormField(
            controller: ratingController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Rate (1 to 5)',
              labelStyle: TextStyle(
                color: isDarkTheme ? Colors.white : Colors.black,
              ),
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: mediaQuery.size.height * 0.01),
          _buildActionButton(
            context,
            'Submit Rating',
            Colors.blue,
            () {
              final rating = int.tryParse(ratingController.text);
              if (rating == null || rating < 1 || rating > 5) {
                _showInvalidRatingDialog(context);
                return;
              }
              _handleRatingOrder(context: context, bookingId: order['_id']);
            },
            isLoading: isLoading[order['_id']] ?? false,
          ),
        ],
      );
    }

    return _buildActionButton(
      context,
      'Give Rating to Vendor',
      Colors.blue,
      () {
        setState(() {
          ratingOrderId = order['_id'];
          ratingController.clear();
        });
      },
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

  void _showOrdersDialog(BuildContext context, String orderType, String id) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(
              _capitalizeWords(orderType),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text('Are you sure you want to $orderType this order?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('No'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  orderType == 'cancel'
                      ? _handleCancelOrder(context: context, bookingId: id)
                      : _handleMarkAsCompletedOrder(
                        context: context,
                        bookingId: id,
                      );
                },
                child: Text(
                  'Yes',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }

  void _showInvalidRatingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Invalid Rating"),
            content: const Text("Please enter a rating between 1 and 5."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  Future<void> _updateUserBonusAmount(
    UserModel? user,
    Map<String, dynamic> responseJson,
  ) async {
    if (user != null) {
      final updatedUser = UserModel(
        token: user.token,
        userId: user.userId,
        name: user.name,
        email: user.email,
        verifyEmail: user.verifyEmail,
        phoneNo: user.phoneNo,
        verifyPhoneNo: user.verifyPhoneNo,
        gender: user.gender,
        address: user.address,
        balance: user.balance,
        bonusAmount: responseJson['bonusAmount'] ?? user.bonusAmount,
        imgURL: user.imgURL,
        message: responseJson['message'] ?? user.message,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(updatedUser.toJson()));
    }
  }

  Future<void> _updateVendorBonusAmount(
    VendorModel? vendor,
    Map<String, dynamic> responseJson,
  ) async {
    if (vendor != null) {
      final updatedVendor = VendorModel(
        token: vendor.token,
        vendorId: vendor.vendorId,
        name: vendor.name,
        email: vendor.email,
        verifyEmail: vendor.verifyEmail,
        phoneNo: vendor.phoneNo,
        verifyPhoneNo: vendor.verifyPhoneNo,
        type: vendor.type,
        gender: vendor.gender,
        rating: vendor.rating,
        ratingCount: vendor.ratingCount,
        wageRate: vendor.wageRate,
        address: vendor.address,
        balance: vendor.balance,
        bonusAmount: responseJson['bonusAmount'] ?? vendor.bonusAmount,
        imgURL: vendor.imgURL,
        message: responseJson['message'] ?? vendor.message,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('vendor', jsonEncode(updatedVendor.toJson()));
    }
  }

  Future<void> _handleRatingOrder({
    required BuildContext context,
    required String bookingId,
  }) async {
    setState(() => updateIsLoadingForId(bookingId, true));
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final vendorData = prefs.getString('vendor');
    final isVendor = vendorData != null;
    final token =
        "Bearer ${isVendor ? jsonDecode(vendorData)['token'] : jsonDecode(userData!)['token']}";
    final userId =
        isVendor
            ? jsonDecode(vendorData)['vendorId']
            : jsonDecode(userData!)['userId'];

    try {
      final response = await http.patch(
        Uri.parse(
          isVendor
              ? "${KConstantURL.url}/bookings/ratingV"
              : "${KConstantURL.url}/bookings/ratingU",
        ),
        headers: {"Content-Type": "application/json", "Authorization": token},
        body: jsonEncode({
          'bookingId': bookingId,
          'rating': int.parse(ratingController.text),
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          updateIsLoadingForId(bookingId, false);
          futureCards = _fetchCards(userId, pageNo, token);
          ratingOrderId = null;
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

  Future<void> _handleMarkAsCompletedOrder({
    required BuildContext context,
    required String bookingId,
  }) async {
    setState(() => updateIsLoadingForId(bookingId, true));
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final vendorData = prefs.getString('vendor');
    final isVendor = vendorData != null;
    final token =
        "Bearer ${isVendor ? jsonDecode(vendorData)['token'] : jsonDecode(userData!)['token']}";
    final userId =
        isVendor
            ? jsonDecode(vendorData)['vendorId']
            : jsonDecode(userData!)['userId'];

    try {
      final response = await http.patch(
        Uri.parse(
          isVendor
              ? "${KConstantURL.url}/bookings/orderCompletedV"
              : "${KConstantURL.url}/bookings/orderCompletedU",
        ),
        headers: {"Content-Type": "application/json", "Authorization": token},
        body: jsonEncode({'bookingId': bookingId}),
      );

      if (response.statusCode == 200) {
        setState(() {
          updateIsLoadingForId(bookingId, false);
          futureCards = _fetchCards(userId, pageNo, token);
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

  Future<void> _handleCancelOrder({
    required BuildContext context,
    required String bookingId,
  }) async {
    setState(() => updateIsLoadingForIdC(bookingId, true));
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final vendorData = prefs.getString('vendor');
    final isVendor = vendorData != null;
    final token =
        "Bearer ${isVendor ? jsonDecode(vendorData)['token'] : jsonDecode(userData!)['token']}";
    final userId =
        isVendor
            ? jsonDecode(vendorData)['vendorId']
            : jsonDecode(userData!)['userId'];

    try {
      final response = await http.patch(
        Uri.parse(
          isVendor
              ? "${KConstantURL.url}/bookings/cancelOrderV"
              : "${KConstantURL.url}/bookings/cancelOrderU",
        ),
        headers: {"Content-Type": "application/json", "Authorization": token},
        body: jsonEncode({'bookingId': bookingId}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (isVendor) {
          await _updateVendorBonusAmount(vendor, responseData);
        } else {
          await _updateUserBonusAmount(user, responseData);
        }

        setState(() {
          updateIsLoadingForIdC(bookingId, false);
          futureCards = _fetchCards(userId, pageNo, token);
        });
        _showSnackBar(context, responseData['message'], true);
      } else {
        setState(() => updateIsLoadingForIdC(bookingId, false));
        _showSnackBar(context, jsonDecode(response.body)['message'], false);
      }
    } catch (e) {
      setState(() => updateIsLoadingForIdC(bookingId, false));
      _showSnackBar(context, "Error: $e", false);
    }
  }

  void _showSnackBar(BuildContext context, String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        content: Center(
          child: Text(
            message,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/models/data_model.dart';
import 'package:app_aapkakaam/widgets/transactionHistory.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_aapkakaam/widgets/paymentSuccessful.dart';
import 'package:app_aapkakaam/widgets/paymentFailed.dart';
import 'package:app_aapkakaam/widgets/transactionHistory.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  Razorpay? _razorpay;
  int? _loadingIndex;
  String? _errorMessage;
  bool _isLoading = false;
  String? _currentOrderId;
  int? _currentAmount;
  double _currentBalance = 0.0;

  // Temporary storage for the active transaction details
  Map<String, dynamic>? _currentTransactionDetails;

  final List<Map<String, dynamic>> pricingOptions = [
    {"original": 100, "discounted": 100},
    {"original": 500, "discounted": 475},
    {"original": 1000, "discounted": 900},
    {"original": 1500, "discounted": 1270},
    {"original": 2000, "discounted": 1600},
    {"original": 5000, "discounted": 3500},
    {"original": 10000, "discounted": 6000},
    {"original": 20000, "discounted": 10000},
  ];

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();

    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);

    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);

    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _loadCurrentBalance();
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  Future<void> _loadCurrentBalance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isVendor1 = isVendor.value;
      final category = isVendor1 ? 'vendor' : 'user';
      final categoryData = prefs.getString(category);

      if (categoryData != null) {
        final decoded = jsonDecode(categoryData);
        setState(() {
          _currentBalance = (decoded['balance'] ?? 0).toDouble();
        });
      }
    } catch (e) {
      print('Error loading balance: $e');
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('Payment Success Response: ${response.paymentId}');

    if (_currentTransactionDetails == null) {
      if (mounted) {
        setState(() {
          _loadingIndex = null;
          _isLoading = false;
          _errorMessage = 'Transaction details not found';
        });
      }
      return;
    }

    try {
      const serverUrl = KConstantURL.url;

      final verifyRes = await http.post(
        Uri.parse("$serverUrl/payment/verify-payment"),
        headers: {
          "Authorization": "Bearer ${_currentTransactionDetails!['token']}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "razorpay_payment_id": response.paymentId,

          "razorpay_order_id": response.orderId,

          "razorpay_signature": response.signature,

          "amount": _currentTransactionDetails!['amount'],

          "discount":
              (_currentTransactionDetails!['amount'] *
                  _currentTransactionDetails!['discountPercent'] /
                  100),

          "discountPercent": _currentTransactionDetails!['discountPercent'],

          "balance": _currentTransactionDetails!['amount'],

          "userId": _currentTransactionDetails!['userId'],

          "vendorId": _currentTransactionDetails!['vendorId'],

          "category": _currentTransactionDetails!['category'],

          "name": _currentTransactionDetails!['name'],

          "email": _currentTransactionDetails!['email'],

          "phoneNo": _currentTransactionDetails!['contact'],
        }),
      );

      print(
        'Payment verification status: '
        '${verifyRes.statusCode}',
      );

      final data = jsonDecode(verifyRes.body);

      if (data['success'] == true) {
        // Update local user/vendor data
        await _updateUserData(data);

        if (!mounted) return;

        // Navigate to Payment Success Page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PaymentSuccessPage(
                  paymentId: response.paymentId ?? '',
                  orderId: response.orderId ?? '',
                  amount:
                      data['transaction']?['finalAmount'] ??
                      _currentTransactionDetails!['amount'],
                ),
          ),
        );
      } else {
        // Payment verification failed
        if (!mounted) return;

        _showMessage(
          data['message'] ?? 'Payment verification failed',
          Colors.red,
        );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PaymentFailedPage()),
        );
      }
    } catch (e) {
      print('Verification Error: $e');

      if (!mounted) return;

      setState(() {
        _errorMessage = "Verification failed: ${e.toString()}";
      });

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PaymentFailedPage()),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingIndex = null;
          _isLoading = false;
          _currentTransactionDetails = null;
        });
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('Payment Error: ${response.code} - ${response.message}');

    // Log payment failure
    _logPaymentFailure(
      _currentOrderId ?? '',
      _currentAmount ?? 0,
      response.code.toString(),
      response.message ?? 'Payment failed',
    );

    setState(() {
      _loadingIndex = null;
      _isLoading = false;
      _currentTransactionDetails = null;
      _errorMessage = response.message ?? 'Payment failed';
    });

    _showMessage(response.message ?? 'Payment failed', Colors.red);

    // Navigate to Payment Failed Page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PaymentFailedPage()),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External Wallet: ${response.walletName}');
    _showMessage('External wallet selected', Colors.blue);
  }

  Future<void> _updateUserData(Map<String, dynamic> responseData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isVendor1 = isVendor.value;
      final category = isVendor1 ? 'vendor' : 'user';
      final categoryData = prefs.getString(category);

      if (categoryData == null) return;

      final decoded = jsonDecode(categoryData);

      if (isVendor1) {
        // Update VendorModel
        final vendor = VendorModel.fromJson(decoded);
        final updatedVendor = vendor.copyWith(
          balance: responseData['balance']?.toDouble() ?? vendor.balance,
          totalDiscount:
              responseData['totalDiscount']?.toDouble() ?? vendor.totalDiscount,
          transactionCount:
              responseData['transactionCount'] ?? vendor.transactionCount,
          totalOriginalAmount:
              responseData['totalOriginalAmount']?.toDouble() ??
              vendor.totalOriginalAmount,
          message: responseData['message'] ?? vendor.message,
        );
        await prefs.setString('vendor', jsonEncode(updatedVendor.toJson()));
        setState(() {
          _currentBalance = updatedVendor.balance;
        });
      } else {
        // Update UserModel
        final user = UserModel.fromJson(decoded);
        final updatedUser = user.copyWith(
          balance: responseData['balance']?.toDouble() ?? user.balance,
          totalDiscount:
              responseData['totalDiscount']?.toDouble() ?? user.totalDiscount,
          transactionCount:
              responseData['transactionCount'] ?? user.transactionCount,
          totalOriginalAmount:
              responseData['totalOriginalAmount']?.toDouble() ??
              user.totalOriginalAmount,
          message: responseData['message'] ?? user.message,
        );
        await prefs.setString('user', jsonEncode(updatedUser.toJson()));
        setState(() {
          _currentBalance = updatedUser.balance;
        });
      }
    } catch (e) {
      print('Error updating user data: $e');
    }
  }

  Future<void> _logPaymentFailure(
    String orderId,
    int amount,
    String errorCode,
    String errorMessage,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isVendor1 = isVendor.value;
      final category = isVendor1 ? 'vendor' : 'user';
      final categoryData = prefs.getString(category);

      if (categoryData == null) return;

      final decoded = jsonDecode(categoryData);
      final token = 'Bearer ${decoded['token']}';

      await http.post(
        Uri.parse("${KConstantURL.url}/payment/payment-failed"),
        headers: {"Content-Type": "application/json", "Authorization": token},
        body: jsonEncode({
          "orderId": orderId,
          "amount": amount,
          "userId": decoded['userId'] ?? '',
          "vendorId": decoded['vendorId'] ?? '',
          "category": category,
          "error": {"code": errorCode, "message": errorMessage},
          "timestamp": DateTime.now().toIso8601String(),
        }),
      );
      print('Payment failure tracked successfully');
    } catch (e) {
      print('Failed to log payment failure: $e');
    }
  }

  Future<void> _logAbandonedPayment(String orderId, int amount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isVendor1 = isVendor.value;
      final category = isVendor1 ? 'vendor' : 'user';
      final categoryData = prefs.getString(category);

      if (categoryData == null) return;

      final decoded = jsonDecode(categoryData);
      final token = 'Bearer ${decoded['token']}';

      await http.post(
        Uri.parse("${KConstantURL.url}/payment/abandoned-payment"),
        headers: {"Content-Type": "application/json", "Authorization": token},
        body: jsonEncode({
          "orderId": orderId,
          "amount": amount,
          "userId": decoded['userId'] ?? '',
          "vendorId": decoded['vendorId'] ?? '',
          "category": category,
          "timestamp": DateTime.now().toIso8601String(),
        }),
      );
      print('Abandoned payment tracked successfully');
    } catch (e) {
      print('Failed to log abandoned payment: $e');
    }
  }

  void _handleRazorpayClose() {
    print('Razorpay modal closed by user');
    _showMessage(
      'Payment was cancelled. You can try again anytime.',
      Colors.orange,
    );

    // Log abandoned payment
    if (_currentOrderId != null && _currentAmount != null) {
      _logAbandonedPayment(_currentOrderId!, _currentAmount!);
    }

    setState(() {
      _loadingIndex = null;
      _isLoading = false;
      _currentTransactionDetails = null;
    });
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green
                  ? Icons.check_circle
                  : color == Colors.orange
                  ? Icons.warning_amber
                  : Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }

  Future<void> handlePay(int amount, int discountPercent, int index) async {
    setState(() {
      _loadingIndex = index;
      _errorMessage = null;
      _currentAmount = amount;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final isVendor1 = isVendor.value;
      final category = isVendor1 ? 'vendor' : 'user';
      final categoryData = prefs.getString(category);

      if (categoryData == null) {
        setState(() {
          _errorMessage = 'User data not found';
          _loadingIndex = null;
        });
        return;
      }

      final decoded = jsonDecode(categoryData);
      final token = decoded['token'];
      final name = decoded['name'] ?? 'Guest';
      final email = decoded['email'] ?? 'guest@aapkakaam.com';
      final contact = (decoded['phoneNo'] ?? '9999999999').toString();
      final userId = decoded['userId'] ?? '';
      final vendorId = decoded['vendorId'] ?? '';

      const serverUrl = KConstantURL.url;

      // Create order on server
      final createOrderRes = await http.post(
        Uri.parse("$serverUrl/payment/create-order"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "amount": amount,
          "userId": userId,
          "vendorId": vendorId,
          "category": category,
          "currency": "INR",
        }),
      );

      if (createOrderRes.statusCode != 200) {
        throw Exception("Order creation failed");
      }

      final orderData = jsonDecode(createOrderRes.body);

      if (orderData['success'] != true) {
        throw Exception(orderData['message'] ?? 'Order creation failed');
      }

      final order = orderData['order'];
      _currentOrderId = order['id'];

      // Save transaction details
      _currentTransactionDetails = {
        "token": token,
        "amount": amount,
        "discountPercent": discountPercent,
        "name": name,
        "email": email,
        "contact": contact,
        "userId": userId,
        "vendorId": vendorId,
        "category": category,
      };

      setState(() {
        _isLoading = true;
        _loadingIndex = null;
      });

      // Razorpay options
      var options = {
        'key': 'rzp_test_THfazRmCIeemjt', // Replace with your key
        'amount': order['amount'].toString(),
        'currency': order['currency'] ?? 'INR',
        'name': 'Aapkakaam',
        'description': 'Purchase Credits - ₹$amount',
        'order_id': order['id'],
        'prefill': {'contact': contact, 'email': email, 'name': name},
        'notes': {
          'userId': userId,
          'vendorId': vendorId,
          'category': category,
          'amount': amount,
          'discountPercent': discountPercent,
        },
        'theme': {"color": "#4f46e5"},
        'timeout': 300,
      };

      // Open Razorpay checkout
      _razorpay!.open(options);
    } catch (e) {
      print('Error in handlePay: $e');
      setState(() {
        _errorMessage = e.toString();
        _loadingIndex = null;
        _isLoading = false;
        _currentTransactionDetails = null;
      });
      _showMessage(e.toString(), Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isVendor1 = isVendor.value;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Add Balance",
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              // Header Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.purple.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.wallet,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add Balance',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Current Balance: ₹${_currentBalance.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        // FIX: Actually navigate to the page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TransactionStatsPage(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        'Transaction History',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _errorMessage = null),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

              // Loading State
              if (_isLoading)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Preparing payment...',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                // Pricing Options Grid
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                    itemCount: pricingOptions.length,
                    itemBuilder: (context, index) {
                      final option = pricingOptions[index];
                      // For users, divide by 10
                      final userAmount = {
                        'discounted': option['discounted'] / 10,
                        'original': option['original'] / 10,
                      };
                      final selectedOption = isVendor1 ? option : userAmount;
                      final discountPercent =
                          ((selectedOption['original'] -
                                      selectedOption['discounted']) /
                                  selectedOption['original'] *
                                  100)
                              .round();

                      return _buildPricingCard(
                        option: selectedOption,
                        discountPercent: discountPercent,
                        index: index,
                        isDark: isDark,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricingCard({
    required Map<String, dynamic> option,
    required int discountPercent,
    required int index,
    required bool isDark,
  }) {
    final isSelected = _loadingIndex == index;
    final discounted = option['discounted'];
    final original = option['original'];
    final savings = original - discounted;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? Colors.blue.shade400 : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient:
              isSelected
                  ? LinearGradient(
                    colors: [Colors.blue.shade50, Colors.blue.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Discount badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color:
                    discountPercent > 0
                        ? Colors.green.shade100
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                discountPercent > 0 ? '-$discountPercent%' : '0%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color:
                      discountPercent > 0
                          ? Colors.green.shade700
                          : Colors.grey.shade600,
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Price
            Text(
              '₹$discounted',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),

            // Original price with strike-through
            if (discountPercent > 0)
              Text(
                '₹$original',
                style: TextStyle(
                  fontSize: 11,
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey.shade500,
                ),
              ),

            const SizedBox(height: 2),

            // Savings
            if (discountPercent > 0)
              Text(
                'Save ₹$savings',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.green.shade600,
                ),
              ),

            const SizedBox(height: 8),

            // Pay button
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton(
                onPressed:
                    isSelected || _isLoading
                        ? null
                        : () =>
                        // Pass discounted amount instead of original
                        handlePay(original.toInt(), discountPercent, index),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isSelected || _isLoading
                          ? Colors.grey.shade400
                          : Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child:
                    isSelected || _isLoading
                        ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text('Pay Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

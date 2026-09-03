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

  // Language helper
  String _t(String en, String hi) => isHindiNotifier.value ? hi : en;

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

      final data = jsonDecode(verifyRes.body);

      if (data['success'] == true) {
        await _updateUserData(data);

        if (!mounted) return;

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
        if (!mounted) return;
        _showMessage(
          data['message'] ??
              _t('Payment verification failed', 'भुगतान सत्यापन विफल'),
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
        _errorMessage =
            "${_t('Verification failed', 'सत्यापन विफल')}: ${e.toString()}";
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
      _errorMessage = response.message ?? _t('Payment failed', 'भुगतान विफल');
    });

    _showMessage(
      response.message ?? _t('Payment failed', 'भुगतान विफल'),
      Colors.red,
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PaymentFailedPage()),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External Wallet: ${response.walletName}');
    _showMessage(
      _t('External wallet selected', 'बाहरी वॉलेट चुना गया'),
      Colors.blue,
    );
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
      _t(
        'Payment was cancelled. You can try again anytime.',
        'भुगतान रद्द कर दिया गया। आप कभी भी पुनः प्रयास कर सकते हैं।',
      ),
      Colors.orange,
    );

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
          _errorMessage = _t(
            'User data not found',
            'उपयोगकर्ता डेटा नहीं मिला',
          );
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
        throw Exception(_t("Order creation failed", "ऑर्डर निर्माण विफल"));
      }

      final orderData = jsonDecode(createOrderRes.body);

      if (orderData['success'] != true) {
        throw Exception(
          orderData['message'] ??
              _t('Order creation failed', 'ऑर्डर निर्माण विफल'),
        );
      }

      final order = orderData['order'];
      _currentOrderId = order['id'];

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

      var options = {
        'key': 'rzp_test_THfazRmCIeemjt',
        'amount': order['amount'].toString(),
        'currency': order['currency'] ?? 'INR',
        'name': 'Aapkakaam',
        'description': '${_t('Purchase Credits', 'क्रेडिट खरीदें')} - ₹$amount',
        'order_id': order['id'],
        'prefill': {'contact': contact, 'email': email, 'name': name},
        'notes': {
          'userId': userId,
          'vendorId': vendorId,
          'category': category,
          'amount': amount,
          'discountPercent': discountPercent,
        },
        'theme': {
          "color": Theme.of(context).colorScheme.primary.value.toString(),
        },
        'timeout': 300,
      };

      _razorpay!.open(options);
    } catch (e) {
      // print('Error in handlePay: $e');
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final surface = colorScheme.surface;
    final onSurface = colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isVendor1 = isVendor.value;
    final isHindi = isHindiNotifier.value;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0B1020) : const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text(
          _t("Add Balance", "बैलेंस जोड़ें"),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDark ? Colors.white : onSurface,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : surface,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : onSurface,
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
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.2),
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
                                _t('Add Balance', 'बैलेंस जोड़ें'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${_t('Current Balance', 'वर्तमान बैलेंस')}: ₹${_currentBalance.toStringAsFixed(2)}',
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
                      child: Text(
                        _t('Transaction History', 'लेन-देन इतिहास'),
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
                        CircularProgressIndicator(color: primaryColor),
                        const SizedBox(height: 16),
                        Text(
                          _t(
                            'Preparing payment...',
                            'भुगतान तैयार हो रहा है...',
                          ),
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
                        primaryColor: primaryColor,
                        onSurface: onSurface,
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
    required Color primaryColor,
    required Color onSurface,
  }) {
    final isSelected = _loadingIndex == index;
    final discounted = option['discounted'];
    final original = option['original'];
    final savings = original - discounted;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 200 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Card(
        elevation: isSelected ? 8 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? primaryColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        shadowColor: isSelected ? primaryColor.withOpacity(0.3) : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient:
                isSelected
                    ? LinearGradient(
                      colors: [
                        primaryColor.withOpacity(0.08),
                        primaryColor.withOpacity(0.03),
                      ],
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
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
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
                  color: isDark ? Colors.white : onSurface,
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
                  '${_t('Save', 'बचाएं')} ₹$savings',
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
                          : () => handlePay(
                            original.toInt(),
                            discountPercent,
                            index,
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isSelected || _isLoading
                            ? Colors.grey.shade400
                            : primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: isSelected ? 0 : 2,
                    shadowColor: primaryColor.withOpacity(0.3),
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
                          : Text(
                            _t('Pay Now', 'अभी भुगतान करें'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

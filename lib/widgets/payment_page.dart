import 'dart:convert';
import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  Razorpay? _razorpay;
  int? _loadingIndex;
  String? _errorMessage;

  // Temporary storage for the active transaction details
  Map<String, dynamic>? _currentTransactionDetails;

  final List<Map<String, dynamic>> pricingOptions = [
    {"original": 100, "discounted": 100},
    {"original": 500, "discounted": 475},
    {"original": 1000, "discounted": 900},
    {"original": 1500, "discounted": 1270},
    {"original": 2000, "discounted": 1600},
  ];

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_currentTransactionDetails == null) return;

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
          "name": _currentTransactionDetails!['name'],
          "email": _currentTransactionDetails!['email'],
          "phoneNo": _currentTransactionDetails!['contact'],
          "userId": _currentTransactionDetails!['userId'],
          "vendorId": _currentTransactionDetails!['vendorId'],
          "category": _currentTransactionDetails!['category'],
          "balance": _currentTransactionDetails!['amount'],
          "discountPercent": _currentTransactionDetails!['discountPercent'],
        }),
      );

      final data = jsonDecode(verifyRes.body);
      if (data['success'] == true) {
        Navigator.pushNamed(
          context,
          "/paymentSuccessful",
          arguments: {
            "razorpay_payment_id": response.paymentId,
            "razorpay_order_id": response.orderId,
          },
        );
      } else {
        Navigator.pushNamed(context, "/paymentFailed");
      }
    } catch (e) {
      setState(() => _errorMessage = "Verification failed: ${e.toString()}");
      Navigator.pushNamed(context, "/paymentFailed");
    } finally {
      setState(() {
        _loadingIndex = null;
        _currentTransactionDetails = null;
      });
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _loadingIndex = null;
      _currentTransactionDetails = null;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Payment failed")));
  }

  Future<void> handlePay(int amount, int discountPercent, int index) async {
    setState(() {
      _loadingIndex = index;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final isVendor1 = prefs.getBool('isVendor') ?? false;
      final category = isVendor1 ? 'vendor' : 'user';
      final categoryData = prefs.getString(category);

      if (categoryData == null) {
        setState(() => _errorMessage = 'User data not found');
        return;
      }

      final decoded = jsonDecode(categoryData);
      final token = decoded['token'];
      final name = decoded['name'] ?? '';
      final email = decoded['email'] ?? 'admin@aapkakaam.com';
      final contact = decoded['phoneNo'] ?? '';
      final userId = decoded['userId'];
      final vendorId = decoded['vendorId'];

      // Save details globally so the success event listener can safely access it
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

      const serverUrl = KConstantURL.url;

      final createOrderRes = await http.post(
        Uri.parse("$serverUrl/payment/create-order"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"amount": amount}),
      );

      if (createOrderRes.statusCode != 200) {
        throw Exception("Order creation failed");
      }

      final orderData = jsonDecode(createOrderRes.body);
      final order = orderData['order'];

      var options = {
        'key': 'rzp_live_ymm3SOr7DUIJiM',
        'amount': order['amount'],
        'currency': order['currency'],
        'name': 'Aapkakaam',
        'description': 'Purchase Credits',
        'order_id': order['id'],
        'prefill': {'contact': contact, 'email': email, 'name': name},
        'theme': {"color": "#4f46e5"},
      };

      _razorpay!.open(options);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _loadingIndex = null;
        _currentTransactionDetails = null;
      });
    }
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
            final bgColor = isDarkTheme ? Colors.teal[800] : Colors.amber[200];
            final textColor = isDarkTheme ? Colors.white : Colors.black;
            return Scaffold(
              backgroundColor: bgColor,
              appBar: AppBar(
                elevation: 0,
                title: Text(
                  "Payment Page",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: mediaQuery.size.width * 0.06,
                  ),
                ),
                centerTitle: true,
                iconTheme: IconThemeData(color: textColor),
                backgroundColor: isDarkTheme ? Colors.black : Colors.white,
              ),
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ...pricingOptions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final option = entry.value;
                        final discountPercent =
                            ((option['original'] - option['discounted']) /
                                    option['original'] *
                                    100)
                                .round();

                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  "₹${option['discounted']}",
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Original: ₹${option['original']}",
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  "Save ₹${option['original'] - option['discounted']}",
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                  ),
                                  onPressed:
                                      _loadingIndex == index
                                          ? null
                                          : () => handlePay(
                                            option['discounted'],
                                            discountPercent,
                                            index,
                                          ),
                                  child:
                                      _loadingIndex == index
                                          ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : Text(
                                            "Pay Now (-$discountPercent%)",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// this file is made responsive with theme colors and Hindi support.
// Includes ₹50 payment for vendor signup using Razorpay (inline payment)

import 'dart:async';
import 'dart:convert';
import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/navBarWidgets/home_page.dart';
import 'package:flutter/material.dart';
import 'package:app_aapkakaam/widgets/login_page.dart';
import 'package:app_aapkakaam/widgets/welcome_page.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupPage extends StatefulWidget {
  final String? category;
  final String? cd;
  final String? id;

  const SignupPage({super.key, this.category, this.cd, this.id});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // ============================================================
  // THEME COLORS
  // ============================================================
  static const Color primaryBlue = Color(0xFF4F46E5);
  static const Color primaryPurple = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFFEEF2FF);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textLight = Color(0xFF6B7280);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF22C55E);

  // ============================================================
  // CONSTANTS
  // ============================================================
  static const int maxJobs = 5;
  static const int vendorSignupFee = 50;

  // ============================================================
  // RAZORPAY - FIXED: Using nullable type
  // ============================================================
  Razorpay? _razorpay;

  // ============================================================
  // FORM DATA
  // ============================================================
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool isLoading = false;
  bool isPhoneOtpLoading = false;
  bool isOtpSent = false;
  bool isNumberLengthIsTen = false;
  bool isNumberVerified = false;
  String otpId = "";
  bool _agreedToTnC = false;

  // Signup token for vendor payment
  String? _signupToken;
  Map<String, dynamic>? _vendorSignupData;

  late Map<String, dynamic> data;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _rePasswordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  final List<String> _selectedProfessions = [];
  String? _selectedGender;
  final List<String> _gender = ['Male', 'Female', 'Other'];

  // ============================================================
  // PROFESSION MAPS
  // ============================================================
  final Map<String, String> _professionHindiMap = {
    'Labour': 'मजदूर',
    'Mason': 'राजमिस्त्री',
    'Electrician': 'बिजली मिस्त्री',
    'Plumber': 'प्लंबर',
    'Painter': 'पेंटर',
    'Carpenter': 'बढ़ई',
    'Tiles Fitter': 'टाइल मिस्त्री',
    'Marble Fitter': 'मार्बल मिस्त्री',
    'Shuttering': 'शटरिंग',
    'Welder': 'वेल्डर',
    'Fabricator': 'फैब्रिकेटर',
    'Glass Fitter': 'कांच मिस्त्री',
    'POP Worker': 'पीओपी मिस्त्री',
    'AC Mechanic': 'एसी मिस्त्री',
    'Fridge Mechanic': 'फ्रिज मिस्त्री',
    'Bike Repair': 'बाइक रिपेयर',
    'Car Repair': 'कार रिपेयर',
    'Laptop Repair': 'लैपटॉप रिपेयर',
    'CCTV Installation': 'सीसीटीवी इंस्टालेशन',
    'Inverter Repair': 'इन्वर्टर मरम्मत',
    'Microwave Repair': 'माइक्रोवेव मरम्मत',
    'Driver': 'ड्राइवर',
    'Home Tutor': 'होम ट्यूटर',
    'Milk Man': 'दूध वाला',
    'Washer Man': 'धोबी',
    'Gardener': 'माली',
    'Security Guard': 'सुरक्षा गार्ड',
    'House Maid': 'घरेलू सहायिका',
    'Baby Sitter': 'बेबी सिटर',
    'Old Age Caregiver': 'बुजुर्ग देखभालकर्ता',
    'Parlour': 'पार्लर',
    'Mehandi Maker': 'मेहंदी कलाकार',
    'Pandit Ji': 'पंडित जी',
    'Cook': 'रसोइया',
    'Lights': 'लाइट',
    'Tent House': 'टेंट हाउस',
    'Kirtan Mandali': 'कीर्तन मंडली',
    'Generator': 'जनरेटर',
    'DJ': 'डीजे',
    'Waiter': 'वेटर',
    'RO Water': 'आरओ पानी',
    'Chaat': 'चाट',
    'Dulha Rath': 'दूल्हा रथ',
    'Paan Wala': 'पान वाला',
    'Fruits Seller': 'फल विक्रेता',
    'Marriage Hall': 'मैरिज हॉल',
    'Photographer': 'फोटोग्राफर',
    'Videographer': 'वीडियोग्राफर',
    'Makeup Artist': 'मेकअप कलाकार',
    'Band Party': 'बैंड पार्टी',
    'Fireworks': 'पटाखे',
    'Catering': 'कैटरिंग',
    'Four Wheeler': 'चार पहिया',
    'Bus': 'बस',
    'Auto': 'ऑटो',
    'E-Rikshaw': 'ई-रिक्शा',
    'Mini Truck': 'मिनी ट्रक',
    'Dhankutti': 'धान कुट्टी',
    'Aata Chakki': 'आटा चक्की',
    'Tank Cleaner': 'टैंक क्लीनर',
    'Pual Cutter': 'पुआल कटर',
    'Bhoonsa Seller': 'भूसा विक्रेता',
    'Pest Control': 'कीट नियंत्रण',
    'Deep Cleaning': 'गहरी सफाई',
    'Water Tank Cleaning': 'पानी की टंकी सफाई',
    'Geyser Repair': 'गीजर मरम्मत',
    'Washing Machine Repair': 'वॉशिंग मशीन मरम्मत',
    'TV Repair': 'टीवी मरम्मत',
    'Computer Trainer': 'कंप्यूटर प्रशिक्षक',
    'Music Teacher': 'संगीत शिक्षक',
    'Dance Teacher': 'नृत्य शिक्षक',
    'Art Teacher': 'कला शिक्षक',
    'Language Trainer': 'भाषा प्रशिक्षक',
  };

  final Map<String, String> _professionToJobType = {
    'Labour': 'labour',
    'Mason': 'mason',
    'Electrician': 'electrician',
    'Plumber': 'plumber',
    'Painter': 'painter',
    'Carpenter': 'carpenter',
    'Tiles Fitter': 'tiles fitter',
    'Marble Fitter': 'marble fitter',
    'Shuttering': 'shuttering',
    'Welder': 'welder',
    'Fabricator': 'fabricator',
    'Glass Fitter': 'glass fitter',
    'POP Worker': 'pop worker',
    'AC Mechanic': 'ac mechanic',
    'Fridge Mechanic': 'fridge mechanic',
    'Bike Repair': 'bike repaire',
    'Car Repair': 'car repaire',
    'Laptop Repair': 'laptop repaire',
    'CCTV Installation': 'cctv installation',
    'Inverter Repair': 'inverter repair',
    'Microwave Repair': 'microwave repair',
    'Driver': 'driver',
    'Home Tutor': 'home tutor',
    'Milk Man': 'milk man',
    'Washer Man': 'washer man',
    'Gardener': 'gardener',
    'Security Guard': 'security guard',
    'House Maid': 'house maid',
    'Baby Sitter': 'baby sitter',
    'Old Age Caregiver': 'old age caregiver',
    'Parlour': 'parlour',
    'Mehandi Maker': 'menhandi maker',
    'Pandit Ji': 'pundit ji',
    'Cook': 'cook',
    'Lights': 'lights',
    'Tent House': 'tent house',
    'Kirtan Mandali': 'kirtan mandli',
    'Generator': 'generator',
    'DJ': 'dj',
    'Waiter': 'waiter',
    'RO Water': 'ro',
    'Chaat': 'chaat',
    'Dulha Rath': 'dulha rath',
    'Paan Wala': 'paan wala',
    'Fruits Seller': 'fruit seller',
    'Marriage Hall': 'marriage hall',
    'Photographer': 'photographer',
    'Videographer': 'videographer',
    'Makeup Artist': 'makeup artist',
    'Band Party': 'band party',
    'Fireworks': 'fireworks',
    'Catering': 'catering',
    'Four Wheeler': 'four wheeler',
    'Bus': 'bus',
    'Auto': 'auto',
    'E-Rikshaw': 'e-riksha',
    'Mini Truck': 'mini truck',
    'Dhankutti': 'dhankutti',
    'Aata Chakki': 'aata chakki',
    'Tank Cleaner': 'latrine tank cleaner',
    'Pual Cutter': 'pual cutter',
    'Bhoonsa Seller': 'bhoonsa pual seller',
    'Pest Control': 'pest control',
    'Deep Cleaning': 'deep cleaning',
    'Water Tank Cleaning': 'water tank cleaning',
    'Geyser Repair': 'geyser repair',
    'Washing Machine Repair': 'washing machine repair',
    'TV Repair': 'tv repair',
    'Computer Trainer': 'computer trainer',
    'Music Teacher': 'music teacher',
    'Dance Teacher': 'dance teacher',
    'Art Teacher': 'art teacher',
    'Language Trainer': 'language trainer',
  };

  // ============================================================
  // HELPERS
  // ============================================================

  List<String> get _professions {
    final List<String> professions = [];
    for (final entry in _professionHindiMap.keys) {
      professions.add(entry);
    }
    professions.sort();
    return professions;
  }

  String get _profileCategory {
    if (widget.category == null) return '';
    return widget.category![0].toUpperCase() + widget.category!.substring(1);
  }

  String _jobTypeForBackend(String profession) {
    return _professionToJobType[profession] ?? profession.trim().toLowerCase();
  }

  String _t(String english, String hindi) {
    return isHindiNotifier.value ? hindi : english;
  }

  String _getProfessionDisplay(String value) {
    if (isHindiNotifier.value) {
      return _professionHindiMap[value] ?? value;
    }
    return value;
  }

  String get _serverUrl => KConstantURL.url;

  // ============================================================
  // INIT & DISPOSE - FIXED
  // ============================================================

  @override
  void initState() {
    super.initState();
    _mobileController.addListener(_checkMobileLength);

    // ✅ Initialize Razorpay here
    _initRazorpay();
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _checkMobileLength() {
    final text = _mobileController.text;
    if (text.length == 10 && !isNumberLengthIsTen) {
      setState(() => isNumberLengthIsTen = true);
    } else if (text.length != 10 && isNumberLengthIsTen) {
      setState(() => isNumberLengthIsTen = false);
    }
  }

  @override
  void dispose() {
    _mobileController.removeListener(_checkMobileLength);
    _nameController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _rePasswordController.dispose();
    _otpController.dispose();
    _experienceController.dispose();

    // ✅ Clear Razorpay
    if (_razorpay != null) {
      _razorpay!.clear();
    }
    super.dispose();
  }

  // ============================================================
  // PHONE VERIFICATION
  // ============================================================

  Future<void> _phoneNoVerification() async {
    if (widget.category == null) {
      _showSnackBar('Invalid access. Please try again.', errorRed);
      return;
    }

    if (!isOtpSent) {
      if (_mobileController.text.length != 10) {
        _showSnackBar('Mobile Number must be 10 digits', errorRed);
        return;
      }

      setState(() => isPhoneOtpLoading = true);

      try {
        final response = await http.post(
          Uri.parse("$_serverUrl/${widget.category}/phoneVerification"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"phoneNo": int.parse(_mobileController.text)}),
        );

        data = jsonDecode(response.body);

        if (data['verified'] == true || response.statusCode == 200) {
          setState(() {
            isPhoneOtpLoading = false;
            isOtpSent = true;
            otpId = data['otpId'];
          });
          otpId1.value = otpId;
          _showSnackBar(
            data['message'] ?? 'OTP sent successfully',
            primaryBlue,
          );
        } else {
          setState(() => isPhoneOtpLoading = false);
          _showSnackBar(
            data['message'] ?? 'Phone verification failed',
            errorRed,
          );
        }
      } catch (err) {
        setState(() => isPhoneOtpLoading = false);
        print('err: $err');
        _showSnackBar('Phone verification failed', errorRed);
      }
    } else {
      if (_otpController.text.length != 6) {
        _showSnackBar('Please enter valid OTP', errorRed);
        return;
      }

      setState(() => isPhoneOtpLoading = true);

      try {
        final response = await http.post(
          Uri.parse("$_serverUrl/${widget.category}/otpVerification"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "otp": int.parse(_otpController.text),
            "otpId": otpId,
          }),
        );

        data = jsonDecode(response.body);

        if (data['verified'] == true) {
          setState(() {
            isPhoneOtpLoading = false;
            isNumberVerified = true;
            isOtpSent = false;
            otpId = "";
          });
          _showSnackBar(
            data['message'] ?? 'OTP verified successfully',
            primaryBlue,
          );
        } else {
          setState(() => isPhoneOtpLoading = false);
          _showSnackBar(data['message'] ?? 'OTP verification failed', errorRed);
        }
      } catch (err) {
        setState(() => isPhoneOtpLoading = false);
        print('err: $err');
        _showSnackBar('OTP verification failed', errorRed);
      }
    }
  }

  // ============================================================
  // PAYMENT HANDLERS
  // ============================================================

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // print('Payment Success: ${response.paymentId}');

    setState(() => isLoading = true);

    try {
      final verifyResponse = await http.post(
        Uri.parse("$_serverUrl/vendor/signup/verify-payment"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "signupToken": _signupToken,
          "razorpay_payment_id": response.paymentId,
          "razorpay_order_id": response.orderId,
          "razorpay_signature": response.signature,
        }),
      );

      final result = jsonDecode(verifyResponse.body);

      if (result['success'] == true) {
        // Save vendor data to local storage
        if (result['vendor'] != null) {
          final prefs = await SharedPreferences.getInstance();
          final vendorData = result['vendor'];
          vendorData['token'] = _vendorSignupData!['token'];

          await prefs.setString('vendor', jsonEncode(vendorData));
          isVendor.value = true;
          isLoggedIn.value = true;
        }

        _showSnackBar(
          _t(
            '₹$vendorSignupFee payment successful! Your vendor account has been created and ₹$vendorSignupFee has been added to your balance.',
            '₹$vendorSignupFee भुगतान सफल! आपका वेंडर अकाउंट बन गया है और ₹$vendorSignupFee बैलेंस में जोड़ दिए गए हैं।',
          ),
          primaryBlue,
        );

        // Navigate to home after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => LoginPage(category: widget.category),
              ),
            );
          }
        });
      } else {
        _showSnackBar(
          result['message'] ??
              _t('Payment verification failed', 'भुगतान सत्यापन विफल'),
          errorRed,
        );
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Payment verification error: $e');
      _showSnackBar(
        _t('Payment verification failed', 'भुगतान सत्यापन विफल'),
        errorRed,
      );
      setState(() => isLoading = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('Payment Error: ${response.code} - ${response.message}');
    setState(() => isLoading = false);
    _showSnackBar(
      response.message ?? _t('Payment failed', 'भुगतान विफल हो गया'),
      errorRed,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // print('External Wallet: ${response.walletName}');
  }

  // ============================================================
  // VENDOR SIGNUP WITH INLINE PAYMENT
  // ============================================================

  
Future<void> _initiateVendorPayment() async {
  // ==========================================================
  // VALIDATION - NAME
  // ==========================================================
final name = _nameController.text.trim();

if (name.isEmpty) {
  _showSnackBar(
    _t(
      'Please enter your name',
      'कृपया अपना नाम दर्ज करें',
    ),
    errorRed,
  );
  return;
}

// ==========================================================
// VALIDATION - MOBILE NUMBER
// मोबाइल नंबर की जाँच
// ==========================================================

final mobileText = _mobileController.text.trim();

if (mobileText.length != 10) {
  _showSnackBar(
    _t(
      'Please enter a valid mobile number',
      'कृपया सही मोबाइल नंबर डालें',
    ),
    errorRed,
  );
  return;
}

final phoneNumber = int.tryParse(mobileText);

if (phoneNumber == null) {
  _showSnackBar(
    _t(
      'Please enter a valid mobile number',
      'कृपया सही मोबाइल नंबर डालें',
    ),
    errorRed,
  );
  return;
}

// ==========================================================
// VALIDATION - PASSWORD
// पासवर्ड की जाँच
// ==========================================================

if (_passwordController.text.length < 6) {
  _showSnackBar(
    _t(
      'Password must be at least 6 characters',
      'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए',
    ),
    errorRed,
  );
  return;
}

if (_passwordController.text != _rePasswordController.text) {
  _showSnackBar(
    _t(
      'Passwords do not match',
      'पासवर्ड मैच नहीं हो रहा है',
    ),
    errorRed,
  );
  return;
}
// ==========================================================
// VALIDATION - GENDER
// लिंग की जाँच
// ==========================================================

if (_selectedGender == null) {
  _showSnackBar(
    _t(
      'Please select your gender',
      'कृपया अपना लिंग चुनें',
    ),
    errorRed,
  );
  return;
}

// ==========================================================
// VALIDATION - JOBS
// काम (जॉब) की जाँच
// ==========================================================

if (_selectedProfessions.isEmpty) {
  _showSnackBar(
    _t(
      'Please select at least one job',
      'कृपया कम से कम एक काम चुनें',
    ),
    errorRed,
  );
  return;
}

if (_selectedProfessions.length > maxJobs) {
  _showSnackBar(
    _t(
      'You can select a maximum of $maxJobs jobs',
      'आप अधिकतम $maxJobs काम चुन सकते हैं',
    ),
    errorRed,
  );
  return;
}

// ==========================================================
// VALIDATION - EXPERIENCE
// अनुभव की जाँच
// ==========================================================

final experienceText = _experienceController.text.trim();

if (experienceText.isEmpty) {
  _showSnackBar(
    _t(
      'Please enter your experience',
      'कृपया अपना अनुभव दर्ज करें',
    ),
    errorRed,
  );
  return;
}

final experience = int.tryParse(experienceText);

if (experience == null || experience < 0) {
  _showSnackBar(
    _t(
      'Please enter a valid experience',
      'कृपया वैध अनुभव दर्ज करें',
    ),
    errorRed,
  );
  return;
}

// ==========================================================
// VALIDATION - TERMS & CONDITIONS
// नियम व शर्तों की जाँच
// ==========================================================

if (!_agreedToTnC) {
  _showSnackBar(
    _t(
      'You must accept the Terms & Conditions and Privacy Policy',
      'आपको नियम व शर्तें और गोपनीयता नीति स्वीकार करनी होगी',
    ),
    errorRed,
  );
  return;
}

  // ==========================================================
  // START LOADING
  // ==========================================================

  if (mounted) {
    setState(() {
      isLoading = true;
    });
  }

  try {
    // ==========================================================
    // JOB TYPES
    // ==========================================================

    final jobTypesForBackend =
        _selectedProfessions.map(_jobTypeForBackend).toList();

    // ==========================================================
    // API URL
    // ==========================================================

    final url = "$_serverUrl/vendor/signup/create-order";

    // ==========================================================
    // REQUEST BODY
    // ==========================================================

    final requestBody = {
      "name": name,

      "phoneNo": phoneNumber,

      "password": _passwordController.text,

      "gender": _selectedGender?.toLowerCase(),

      "type": jobTypesForBackend,

      "experience": experience,

      "sharedBy": widget.id ?? "",

      "cd": widget.cd ?? "",

      "validPhoneNoId": otpId1.value,

      "agreedToTnCnP": true,

      // ========================================================
      // FCM TOKEN
      // ========================================================

      "fcmToken": fcmToken.value,
    };

    // ==========================================================
    // DEBUG REQUEST
    // ==========================================================

    debugPrint(
      "══════════════════════════════════════",
    );

    debugPrint(
      "Signup API URL: $url",
    );

    debugPrint(
      "Signup request body: "
      "${{
        ...requestBody,
        "password": "***",
      }}",
    );

    debugPrint(
      "══════════════════════════════════════",
    );

    // ==========================================================
    // CREATE PAYMENT ORDER
    // ==========================================================

    final response = await http.post(
      Uri.parse(url),

      headers: {
        "Content-Type": "application/json",
      },

      body: jsonEncode(requestBody),
    );

    // ==========================================================
    // DEBUG RESPONSE
    // ==========================================================

    debugPrint(
      '══════════════════════════════════════',
    );

    debugPrint(
      'Signup API status: ${response.statusCode}',
    );

    debugPrint(
      'Signup API response: ${response.body}',
    );

    debugPrint(
      '══════════════════════════════════════',
    );

    // ==========================================================
    // HTTP STATUS VALIDATION
    // ==========================================================

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      String errorMessage = 'An error occurred';

      try {
        final responseData = jsonDecode(response.body);

        if (responseData is Map<String, dynamic>) {
          errorMessage =
              responseData['message'] ??
              responseData['error'] ??
              errorMessage;
        }
      } catch (e) {
        debugPrint(
          'Error decoding API error response: $e',
        );
      }

      debugPrint(
        'Signup API error: $errorMessage',
      );

      throw Exception(errorMessage);
    }

    // ==========================================================
    // PARSE RESPONSE
    // ==========================================================

    final decodedResponse = jsonDecode(response.body);

    if (decodedResponse is! Map<String, dynamic>) {
      throw Exception(
        'Invalid response received from server',
      );
    }

    final result = decodedResponse;

    // ==========================================================
    // CHECK SUCCESS
    // ==========================================================

    if (result['success'] != true) {
      throw Exception(
        result['message'] ??
            'Unable to create payment order',
      );
    }

    // ==========================================================
    // GET PAYMENT ORDER
    // ==========================================================

    final order = result['order'];

    // ==========================================================
    // STORE SIGNUP TOKEN
    // ==========================================================

    _signupToken = result['signupToken'];

    if (_signupToken == null ||
        _signupToken.toString().isEmpty) {
      throw Exception(
        'Signup token was not returned by server',
      );
    }

    // ==========================================================
    // VALIDATE PAYMENT ORDER
    // ==========================================================

    if (order == null) {
      throw Exception(
        'Payment order was not returned by server',
      );
    }

    if (order is! Map) {
      throw Exception(
        'Invalid payment order received from server',
      );
    }

    if (order['id'] == null ||
        order['id'].toString().isEmpty) {
      throw Exception(
        'Payment order ID was not returned by server',
      );
    }

    if (order['key'] == null ||
        order['key'].toString().isEmpty) {
      throw Exception(
        'Razorpay key was not returned by server',
      );
    }

    // ==========================================================
    // STORE VENDOR DATA LOCALLY
    // ==========================================================

    _vendorSignupData = {
      "token": "",

      "name": name,

      "phoneNo": mobileText,

      "email": "",

      "fcmToken": fcmToken.value,
    };

    // ==========================================================
    // STOP LOADING BEFORE RAZORPAY
    // ==========================================================

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }

    // ==========================================================
    // RAZORPAY OPTIONS
    // ==========================================================

    final options = {
      'key': order['key'],

      'amount': order['amount'],

      'currency': order['currency'] ?? 'INR',

      'name': 'Aapkakaam',

      'description': _t(
        'Vendor Registration Fee ₹$vendorSignupFee',
        'वेंडर रजिस्ट्रेशन शुल्क ₹$vendorSignupFee',
      ),

      'order_id': order['id'],

      'prefill': {
        'contact': mobileText,

        'name': name,
      },

      'notes': {
        'purpose': 'vendor_signup',

        'fcmToken': fcmToken.value,
      },

      'theme': {
        'color': '#4F46E5',
      },
    };

    // ==========================================================
    // DEBUG RAZORPAY
    // ==========================================================

    debugPrint(
      'Opening Razorpay payment...',
    );

    debugPrint(
      'Razorpay Order ID: ${order['id']}',
    );

    debugPrint(
      'Razorpay Amount: ${order['amount']}',
    );

    // ==========================================================
    // INITIALIZE RAZORPAY
    // ==========================================================

    if (_razorpay == null) {
      _initRazorpay();
    }

    // ==========================================================
    // OPEN RAZORPAY
    // ==========================================================

    _razorpay!.open(options);
  } catch (e, stackTrace) {
    // ==========================================================
    // ERROR LOGGING
    // ==========================================================

    debugPrint(
      '══════════════════════════════════════',
    );

    debugPrint(
      'Error during vendor signup: $e',
    );

    debugPrint(
      'Stack trace:',
    );

    debugPrint(
      stackTrace.toString(),
    );

    debugPrint(
      '══════════════════════════════════════',
    );

    // ==========================================================
    // STOP LOADING
    // ==========================================================

    if (!mounted) {
      return;
    }

    setState(() {
      isLoading = false;
    });

    // ==========================================================
    // SHOW ERROR
    // ==========================================================

    _showSnackBar(
      e
          .toString()
          .replaceFirst('Exception: ', ''),
      errorRed,
    );
  }
}


  // ============================================================
  // USER SIGNUP (Free)
  // ============================================================

  Future<void> _userSignup() async {
    // Validation checks
   if (_nameController.text.isEmpty) {
  _showSnackBar(
    _t(
      'Please enter your name',
      'कृपया अपना नाम दर्ज करें',
    ),
    errorRed,
  );
  return;
}
if (_mobileController.text.length != 10) {
  _showSnackBar(
    _t(
      'Please enter a valid mobile number',
      'कृपया सही मोबाइल नंबर दर्ज करें',
    ),
    errorRed,
  );
  return;
}
if (_passwordController.text.length < 6) {
  _showSnackBar(
    _t(
      'Password must be at least 6 characters',
      'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए',
    ),
    errorRed,
  );
  return;
}
if (_passwordController.text != _rePasswordController.text) {
  _showSnackBar(
    _t(
      'Passwords do not match',
      'पासवर्ड मैच नहीं हो रहा है',
    ),
    errorRed,
  );
  return;
}
if (_selectedGender == null) {
  _showSnackBar(
    _t(
      'Please select your gender',
      'कृपया अपना लिंग चुनें',
    ),
    errorRed,
  );
  return;
}
if (!_agreedToTnC) {
  _showSnackBar(
    _t(
      'You must accept the Terms & Conditions and Privacy Policy',
      'आपको नियम व शर्तें और गोपनीयता नीति स्वीकार करनी होगी',
    ),
    errorRed,
  );
  return;
}

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("$_serverUrl/${widget.category}/signup"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": _nameController.text,
          "phoneNo": int.parse(_mobileController.text),
          "password": _passwordController.text,
          "sharedBy": widget.id,
          "gender": _selectedGender?.toLowerCase(),
          "cd": widget.cd,
          "validPhoneNoId": otpId1.value,
          "agreedToTnCnP": _agreedToTnC,
        }),
      );

      data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        _showSnackBar(data['message'] ?? 'Signup successful!', successGreen);
        Timer(
          const Duration(seconds: 2),
          () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LoginPage(category: widget.category),
            ),
          ),
        );
      } else {
        _showSnackBar(data['message'] ?? 'Signup failed', errorRed);
      }
    } catch (e) {
      _showSnackBar("An error occurred. Please try again.", errorRed);
      print('Error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ============================================================
  // SUBMIT FORM
  // ============================================================

  Future<void> _submitForm() async {
    if (widget.category == null) {
      _showSnackBar('Invalid access. Please try again.', errorRed);
      return;
    }

    // For vendor, initiate payment flow
    if (widget.category == 'vendor') {
      await _initiateVendorPayment();
    } else {
      await _userSignup();
    }
  }

  // ============================================================
  // UI HELPERS
  // ============================================================

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _openTerms() => launchUrl(Uri.parse("https://aapkakaam.com/terms"));
  void _openPrivacyPolicy() =>
      launchUrl(Uri.parse("https://aapkakaam.com/privacy-policy"));

  // ============================================================
  // JOB SELECTION BOTTOM SHEET
  // ============================================================

  Future<void> _selectProfessions(
    bool isDarkTheme,
    Color text,
    Color muted,
  ) async {
    final tempSelected = List<String>.from(_selectedProfessions);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final surface =
                isDarkTheme ? const Color(0xFF1A1A2E) : Colors.white;

            return SafeArea(
              child: Container(
                height: MediaQuery.sizeOf(context).height * 0.82,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: muted.withOpacity(.35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: primaryBlue.withOpacity(.10),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.handyman_rounded,
                              color: primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _t('Select your jobs', 'अपने काम चुनें'),
                                  style: TextStyle(
                                    color: text,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _t(
                                    'Choose up to 5 services you provide',
                                    'आप अधिकतम 5 काम चुन सकते हैं',
                                  ),
                                  style: TextStyle(
                                    color: muted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  tempSelected.length >= maxJobs
                                      ? primaryBlue.withOpacity(.12)
                                      : muted.withOpacity(.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${tempSelected.length}/$maxJobs',
                              style: TextStyle(
                                color:
                                    tempSelected.length >= maxJobs
                                        ? primaryBlue
                                        : muted,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: muted.withOpacity(.12)),
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
                        itemCount: _professions.length,
                        itemBuilder: (context, index) {
                          final profession = _professions[index];
                          final selected = tempSelected.contains(profession);
                          final disabled =
                              !selected && tempSelected.length >= maxJobs;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap:
                                    disabled
                                        ? null
                                        : () {
                                          setSheetState(() {
                                            if (selected) {
                                              tempSelected.remove(profession);
                                            } else if (tempSelected.length <
                                                maxJobs) {
                                              tempSelected.add(profession);
                                            }
                                          });
                                        },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 11,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        selected
                                            ? primaryBlue.withOpacity(.08)
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color:
                                          selected
                                              ? primaryBlue.withOpacity(.35)
                                              : muted.withOpacity(.08),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color:
                                              selected
                                                  ? primaryBlue.withOpacity(.12)
                                                  : muted.withOpacity(.07),
                                          borderRadius: BorderRadius.circular(
                                            11,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.work_outline_rounded,
                                          size: 19,
                                          color: selected ? primaryBlue : muted,
                                        ),
                                      ),
                                      const SizedBox(width: 11),
                                      Expanded(
                                        child: Text(
                                          _getProfessionDisplay(profession),
                                          style: TextStyle(
                                            color: disabled ? muted : text,
                                            fontWeight:
                                                selected
                                                    ? FontWeight.w800
                                                    : FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Checkbox(
                                        value: selected,
                                        activeColor: primaryBlue,
                                        onChanged:
                                            disabled
                                                ? null
                                                : (value) {
                                                  setSheetState(() {
                                                    if (value == true &&
                                                        tempSelected.length <
                                                            maxJobs) {
                                                      if (!tempSelected
                                                          .contains(
                                                            profession,
                                                          )) {
                                                        tempSelected.add(
                                                          profession,
                                                        );
                                                      }
                                                    } else {
                                                      tempSelected.remove(
                                                        profession,
                                                      );
                                                    }
                                                  });
                                                },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed:
                              tempSelected.isEmpty
                                  ? null
                                  : () {
                                    setState(() {
                                      _selectedProfessions
                                        ..clear()
                                        ..addAll(tempSelected);
                                    });
                                    Navigator.pop(sheetContext);
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: primaryBlue.withOpacity(
                              .35,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _t('Done', 'हो गया'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.height < 720;
    final isNarrow = size.width < 380;

    if (widget.category == null) {
      return _invalidAccess();
    }

    return ValueListenableBuilder<bool>(
      valueListenable: isHindiNotifier,
      builder: (context, isHindi, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: isDarkThemeNotifier,
          builder: (context, isDarkTheme, _) {
            final bg = isDarkTheme ? const Color(0xFF0B1020) : primaryLight;
            final surface =
                isDarkTheme ? const Color(0xFF1A1A2E) : Colors.white;
            final text = isDarkTheme ? Colors.white : textDark;
            final muted = isDarkTheme ? Colors.white60 : textLight;

            return Scaffold(
              backgroundColor: bg,
              body: Stack(
                children: [
                  // Decorative Background
                  Positioned(
                    top: -150,
                    right: -120,
                    child: _circle(
                      330,
                      primaryBlue.withOpacity(isDarkTheme ? .10 : .06),
                    ),
                  ),
                  Positioned(
                    bottom: -180,
                    left: -130,
                    child: _circle(
                      360,
                      primaryPurple.withOpacity(isDarkTheme ? .08 : .04),
                    ),
                  ),
                  Positioned(
                    top: 200,
                    left: -80,
                    child: _circle(
                      200,
                      primaryBlue.withOpacity(isDarkTheme ? .04 : .02),
                    ),
                  ),
                  SafeArea(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 540),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              isNarrow ? 18 : 26,
                              14,
                              isNarrow ? 18 : 26,
                              30,
                            ),
                            child: Column(
                              children: [
                                _topBar(context, isHindi, isDarkTheme, text),
                                SizedBox(height: isCompact ? 20 : 30),

                                // Header
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(22),
                                  decoration: BoxDecoration(
                                    color: surface,
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color:
                                          isDarkTheme
                                              ? Colors.white.withOpacity(.07)
                                              : primaryBlue.withOpacity(0.12),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryBlue.withOpacity(
                                          isDarkTheme ? .12 : .055,
                                        ),
                                        blurRadius: 28,
                                        offset: const Offset(0, 13),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              primaryBlue,
                                              primaryPurple,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: primaryBlue.withOpacity(
                                                .20,
                                              ),
                                              blurRadius: 18,
                                              offset: const Offset(0, 7),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          widget.category == 'vendor'
                                              ? Icons.handyman_rounded
                                              : Icons.person_add_alt_1_rounded,
                                          color: Colors.white,
                                          size: 31,
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _t(
                                                'Create your account',
                                                'अपना खाता बनाएं',
                                              ),
                                              style: TextStyle(
                                                color: text,
                                                fontSize: 22,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: -.5,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              _t(
                                                widget.category == 'vendor'
                                                    ? 'Start offering your services'
                                                    : 'Find trusted local services',
                                                widget.category == 'vendor'
                                                    ? 'अपनी सेवाएं देना शुरू करें'
                                                    : 'भरोसेमंद स्थानीय सेवाएं पाएं',
                                              ),
                                              style: TextStyle(
                                                color: muted,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // Form Card
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(isNarrow ? 16 : 20),
                                  decoration: BoxDecoration(
                                    color: surface,
                                    borderRadius: BorderRadius.circular(26),
                                    border: Border.all(
                                      color:
                                          isDarkTheme
                                              ? Colors.white.withOpacity(.07)
                                              : primaryBlue.withOpacity(0.12),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryBlue.withOpacity(
                                          isDarkTheme ? .10 : .04,
                                        ),
                                        blurRadius: 24,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _sectionLabel(
                                          _t(
                                            'Personal details',
                                            'व्यक्तिगत जानकारी',
                                          ),
                                          Icons.person_outline_rounded,
                                          isDarkTheme,
                                          text,
                                        ),
                                        const SizedBox(height: 14),

                                        // Name
                                        _field(
                                          label: _t('Full name', 'पूरा नाम'),
                                          hint: _t(
                                            'Enter your full name',
                                            'अपना पूरा नाम डालें',
                                          ),
                                          controller: _nameController,
                                          icon: Icons.person_rounded,
                                          isDarkTheme: isDarkTheme,
                                          text: text,
                                          muted: muted,
                                          validator:
                                              (v) =>
                                                  v == null || v.isEmpty
                                                      ? _t(
                                                        'Name is required',
                                                        'नाम आवश्यक है',
                                                      )
                                                      : null,
                                        ),

                                        const SizedBox(height: 13),

                                        // Phone / OTP
                                        _phoneField(
                                          isDarkTheme: isDarkTheme,
                                          text: text,
                                          muted: muted,
                                          isOtpSent: isOtpSent,
                                          isNumberVerified: isNumberVerified,
                                          isPhoneOtpLoading: isPhoneOtpLoading,
                                          mobileController: _mobileController,
                                          otpController: _otpController,
                                          isNumberLengthIsTen:
                                              isNumberLengthIsTen,
                                          onPhoneVerify: _phoneNoVerification,
                                          onMobileChange: () => setState(() {}),
                                          isHindi: isHindi,
                                        ),

                                        const SizedBox(height: 13),

                                        // Password
                                        _passwordField(
                                          label: _t('Password', 'पासवर्ड'),
                                          hint: _t(
                                            'At least 6 characters',
                                            'कम से कम 6 अक्षर',
                                          ),
                                          controller: _passwordController,
                                          isDarkTheme: isDarkTheme,
                                          text: text,
                                          muted: muted,
                                          obscureText: _obscurePassword,
                                          onToggleObscure:
                                              () => setState(
                                                () =>
                                                    _obscurePassword =
                                                        !_obscurePassword,
                                              ),
                                          validator:
                                              (v) =>
                                                  v == null || v.length < 6
                                                      ? _t(
                                                        'Password must be at least 6 characters',
                                                        'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए',
                                                      )
                                                      : null,
                                        ),

                                        const SizedBox(height: 13),

                                        // Confirm Password
                                        _field(
                                          label: _t(
                                            'Confirm Password',
                                            'पासवर्ड दोबारा',
                                          ),
                                          hint: _t(
                                            'Re-enter your password',
                                            'पासवर्ड दोबारा डालें',
                                          ),
                                          controller: _rePasswordController,
                                          icon: Icons.lock_outline_rounded,
                                          isDarkTheme: isDarkTheme,
                                          text: text,
                                          muted: muted,
                                          obscureText: _obscurePassword,
                                          validator:
                                              (v) =>
                                                  v != _passwordController.text
                                                      ? _t(
                                                        'Passwords do not match',
                                                        'पासवर्ड मैच नहीं हो रहा',
                                                      )
                                                      : null,
                                        ),

                                        // Vendor Jobs
                                        if (widget.category == 'vendor') ...[
                                          const SizedBox(height: 22),
                                          _sectionLabel(
                                            _t(
                                              'Professional details',
                                              'काम की जानकारी',
                                            ),
                                            Icons.handyman_outlined,
                                            isDarkTheme,
                                            text,
                                          ),
                                          const SizedBox(height: 14),

                                          _jobsField(
                                            isDarkTheme: isDarkTheme,
                                            text: text,
                                            muted: muted,
                                            selectedProfessions:
                                                _selectedProfessions,
                                            onTap:
                                                () => _selectProfessions(
                                                  isDarkTheme,
                                                  text,
                                                  muted,
                                                ),
                                            getProfessionDisplay:
                                                _getProfessionDisplay,
                                            isHindi: isHindi,
                                          ),

                                          const SizedBox(height: 13),

                                          _field(
                                            label: _t(
                                              'Years of experience',
                                              'अनुभव के वर्ष',
                                            ),
                                            hint: _t('e.g. 5', 'जैसे 5'),
                                            controller: _experienceController,
                                            icon:
                                                Icons.workspace_premium_rounded,
                                            isDarkTheme: isDarkTheme,
                                            text: text,
                                            muted: muted,
                                            keyboardType: TextInputType.number,
                                            validator:
                                                (v) =>
                                                    v == null || v.isEmpty
                                                        ? _t(
                                                          'Experience is required',
                                                          'अनुभव आवश्यक है',
                                                        )
                                                        : null,
                                          ),
                                        ],

                                        const SizedBox(height: 22),

                                        _sectionLabel(
                                          _t('Basic details', 'मूल जानकारी'),
                                          Icons.badge_outlined,
                                          isDarkTheme,
                                          text,
                                        ),
                                        const SizedBox(height: 14),

                                        // Gender
                                        _dropdown(
                                          value: _selectedGender,
                                          items: _gender,
                                          hint: _t(
                                            'Select gender',
                                            'लिंग चुनें',
                                          ),
                                          isDarkTheme: isDarkTheme,
                                          text: text,
                                          muted: muted,
                                          display: (value) {
                                            if (!isHindiNotifier.value) {
                                              return value;
                                            }
                                            switch (value.toLowerCase()) {
                                              case 'male':
                                                return 'पुरुष';
                                              case 'female':
                                                return 'महिला';
                                              case 'other':
                                                return 'अन्य';
                                              default:
                                                return value;
                                            }
                                          },
                                          onChanged:
                                              (v) => setState(
                                                () => _selectedGender = v,
                                              ),
                                          validator:
                                              (v) =>
                                                  v == null
                                                      ? _t(
                                                        'Please select your gender',
                                                        'कृपया अपना लिंग चुनें',
                                                      )
                                                      : null,
                                        ),

                                        const SizedBox(height: 16),

                                        // Terms
                                        _termsWidget(
                                          isDarkTheme: isDarkTheme,
                                          agreed: _agreedToTnC,
                                          onChanged:
                                              (value) => setState(
                                                () => _agreedToTnC = value,
                                              ),
                                          onTermsTap: _openTerms,
                                          onPrivacyTap: _openPrivacyPolicy,
                                          muted: muted,
                                        ),
                                        // Payment Info Card
                                        const SizedBox(height: 16),
                                      if (widget.category ==
                                                            'vendor') ...[  _paymentInfoCard(
                                          isDarkTheme,
                                          text,
                                          muted,
                                        ),],
                                        const SizedBox(height: 18),

                                        // Submit Button
                                        SizedBox(
                                          width: double.infinity,
                                          height: 56,
                                          child: ElevatedButton(
                                            onPressed:
                                                isLoading ? null : _submitForm,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: primaryBlue,
                                              foregroundColor: Colors.white,
                                              disabledBackgroundColor:
                                                  primaryBlue.withOpacity(.5),
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(17),
                                              ),
                                            ),
                                            child:
                                                isLoading
                                                    ? const SizedBox(
                                                      width: 23,
                                                      height: 23,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2.5,
                                                            color: Colors.white,
                                                          ),
                                                    )
                                                    : Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        if (widget.category ==
                                                            'vendor') ...[
                                                          const Icon(
                                                            Icons
                                                                .payments_rounded,
                                                            size: 21,
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Text(
                                                            '₹$vendorSignupFee ',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w900,
                                                                ),
                                                          ),
                                                        ] else ...[
                                                          const Icon(
                                                            Icons
                                                                .person_add_rounded,
                                                            size: 21,
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                        ],
                                                        Text(
                                                          widget.category ==
                                                                  'vendor'
                                                              ? _t(
                                                                'Pay & Signup',
                                                                'भुगतान करें और खाता बनाएं',
                                                              )
                                                              : _t(
                                                                'Create Account',
                                                                'खाता बनाएं',
                                                              ),
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w900,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Login Link
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 11,
                                  ),
                                  decoration: BoxDecoration(
                                    color: surface,
                                    borderRadius: BorderRadius.circular(17),
                                    border: Border.all(
                                      color:
                                          isDarkTheme
                                              ? Colors.white.withOpacity(.07)
                                              : primaryBlue.withOpacity(0.12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _t(
                                          'Already have an account?',
                                          'पहले से खाता है?',
                                        ),
                                        style: TextStyle(
                                          color: muted,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) => LoginPage(
                                                      category: widget.category,
                                                    ),
                                              ),
                                            ),
                                        child: Text(
                                          _t('Login', 'लॉगिन'),
                                          style: const TextStyle(
                                            color: primaryBlue,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // PAYMENT INFO CARD
  // ============================================================

  Widget _paymentInfoCard(bool isDarkTheme, Color text, Color muted) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primaryBlue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBlue.withOpacity(0.15), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.credit_card_rounded,
              color: primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('Vendor Account Creation Fee', 'वेंडर खाता निर्माण शुल्क'),
                  style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _t(
                    'Pay ₹$vendorSignupFee to complete vendor signup.',
                    'साइनअप पूरा करने के लिए ₹$vendorSignupFee भुगतान करें।',
                  ),
                  style: TextStyle(color: muted, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  _t(
                    '₹$vendorSignupFee will be added to your vendor balance.',
                    '₹$vendorSignupFee आपके वेंडर बैलेंस में जोड़ दिए जाएंगे।',
                  ),
                  style: TextStyle(
                    color: successGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '₹$vendorSignupFee',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGET BUILDERS
  // ============================================================

  Widget _topBar(
    BuildContext context,
    bool isHindi,
    bool isDarkTheme,
    Color text,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Material(
          color: isDarkTheme ? Colors.white.withOpacity(.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap:
                () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomePage()),
                  (route) => false,
                ),
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isDarkTheme
                          ? Colors.white.withOpacity(.08)
                          : primaryBlue.withOpacity(0.15),
                ),
              ),
              child: Icon(Icons.arrow_back_rounded, color: text),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDarkTheme ? Colors.white.withOpacity(.06) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color:
                  isDarkTheme
                      ? Colors.white.withOpacity(.08)
                      : primaryBlue.withOpacity(0.15),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => isHindiNotifier.value = !isHindiNotifier.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color:
                      isDarkTheme
                          ? Colors.white.withOpacity(.08)
                          : primaryBlue.withOpacity(0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.language_rounded, color: primaryBlue, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    isHindi ? 'हिंदी' : 'English',
                    style: TextStyle(
                      color: text,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(
    String text,
    IconData icon,
    bool isDarkTheme,
    Color textC,
  ) {
    return Row(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color:
                isDarkTheme
                    ? Colors.white.withOpacity(0.08)
                    : primaryBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: primaryBlue, size: 19),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: textC,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required bool isDarkTheme,
    required Color text,
    required Color muted,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool readOnly = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      readOnly: readOnly,
      validator: validator,
      cursorColor: primaryBlue,
      style: TextStyle(
        color: text,
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: muted, fontWeight: FontWeight.w600),
        hintStyle: TextStyle(color: muted.withOpacity(.65), fontSize: 12.5),
        prefixIcon: Icon(icon, color: primaryBlue, size: 21),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor:
            isDarkTheme ? const Color(0xFF0B1626) : const Color(0xFFF8FAFD),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color:
                isDarkTheme
                    ? Colors.white.withOpacity(.08)
                    : primaryBlue.withOpacity(0.15),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color:
                isDarkTheme
                    ? Colors.white.withOpacity(.08)
                    : primaryBlue.withOpacity(0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBlue, width: 1.7),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
      ),
    );
  }

  Widget _phoneField({
    required bool isDarkTheme,
    required Color text,
    required Color muted,
    required bool isOtpSent,
    required bool isNumberVerified,
    required bool isPhoneOtpLoading,
    required TextEditingController mobileController,
    required TextEditingController otpController,
    required bool isNumberLengthIsTen,
    required VoidCallback onPhoneVerify,
    required VoidCallback onMobileChange,
    required bool isHindi,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: isOtpSent ? otpController : mobileController,
          keyboardType: TextInputType.phone,
          readOnly: isNumberVerified,
          cursorColor: primaryBlue,
          style: TextStyle(
            color: text,
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            labelText:
                isOtpSent
                    ? _t('Enter OTP', 'OTP डालें')
                    : _t('Mobile number', 'मोबाइल नंबर'),
            hintText:
                isOtpSent
                    ? _t('Enter 6-digit OTP', '6 अंकों का OTP डालें')
                    : _t(
                      'Enter 10-digit mobile number',
                      '10 अंकों का मोबाइल नंबर डालें',
                    ),
            labelStyle: TextStyle(color: muted, fontWeight: FontWeight.w600),
            hintStyle: TextStyle(color: muted.withOpacity(.65), fontSize: 12.5),
            prefixIcon: Icon(
              isOtpSent ? Icons.password_rounded : Icons.phone_rounded,
              color: primaryBlue,
              size: 21,
            ),
            suffixIcon:
                isNumberVerified
                    ? Icon(Icons.verified_rounded, color: successGreen)
                    : null,
            filled: true,
            fillColor:
                isDarkTheme ? const Color(0xFF0B1626) : const Color(0xFFF8FAFD),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 17,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color:
                    isDarkTheme
                        ? Colors.white.withOpacity(.08)
                        : primaryBlue.withOpacity(0.15),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color:
                    isDarkTheme
                        ? Colors.white.withOpacity(.08)
                        : primaryBlue.withOpacity(0.15),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: primaryBlue, width: 1.7),
            ),
          ),
          onChanged: (value) {
            onMobileChange();
          },
        ),
        if (isNumberLengthIsTen && !isNumberVerified) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: isPhoneOtpLoading ? null : onPhoneVerify,
              icon:
                  isPhoneOtpLoading
                      ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : Icon(
                        isOtpSent ? Icons.verified_rounded : Icons.sms_rounded,
                        size: 20,
                      ),
              label: Text(
                isOtpSent
                    ? _t('Verify OTP', 'OTP सत्यापित करें')
                    : _t('Send OTP', 'OTP भेजें'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _passwordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool isDarkTheme,
    required Color text,
    required Color muted,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    required String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      cursorColor: primaryBlue,
      style: TextStyle(
        color: text,
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: muted, fontWeight: FontWeight.w600),
        hintStyle: TextStyle(color: muted.withOpacity(.65), fontSize: 12.5),
        prefixIcon: Icon(Icons.lock_rounded, color: primaryBlue, size: 21),
        suffixIcon: IconButton(
          onPressed: onToggleObscure,
          icon: Icon(
            obscureText
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            color: muted,
            size: 20,
          ),
        ),
        filled: true,
        fillColor:
            isDarkTheme ? const Color(0xFF0B1626) : const Color(0xFFF8FAFD),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color:
                isDarkTheme
                    ? Colors.white.withOpacity(.08)
                    : primaryBlue.withOpacity(0.15),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color:
                isDarkTheme
                    ? Colors.white.withOpacity(.08)
                    : primaryBlue.withOpacity(0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBlue, width: 1.7),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
      ),
    );
  }

  Widget _jobsField({
    required bool isDarkTheme,
    required Color text,
    required Color muted,
    required List<String> selectedProfessions,
    required VoidCallback onTap,
    required String Function(String) getProfessionDisplay,
    required bool isHindi,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: _t('Jobs / services', 'काम / सेवाएं'),
          labelStyle: TextStyle(
            color: muted,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          filled: true,
          fillColor:
              isDarkTheme ? const Color(0xFF0B1626) : const Color(0xFFF8FAFD),
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 0, right: 2),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.workspaces_rounded,
              color: primaryBlue,
              size: 20,
            ),
          ),
          suffixIcon: Container(
            margin: const EdgeInsets.only(right: 0),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(.09),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: primaryBlue,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color:
                  isDarkTheme
                      ? Colors.white.withOpacity(.08)
                      : primaryBlue.withOpacity(.15),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color:
                  isDarkTheme
                      ? Colors.white.withOpacity(.08)
                      : primaryBlue.withOpacity(.15),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primaryBlue, width: 1.7),
          ),
          contentPadding: const EdgeInsets.fromLTRB(15, 14, 8, 10),
        ),
        child:
            selectedProfessions.isEmpty
                ? Padding(
                  padding: const EdgeInsets.only(top: 3, bottom: 3),
                  child: Text(
                    _t('Select up to 5 jobs', 'अधिकतम 5 काम चुनें'),
                    style: TextStyle(
                      color: muted.withOpacity(.65),
                      fontSize: 13,
                    ),
                  ),
                )
                : Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children:
                      selectedProfessions.map((profession) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: primaryBlue.withOpacity(.10),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: primaryBlue.withOpacity(.20),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 15,
                                color: primaryBlue,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                getProfessionDisplay(profession),
                                style: const TextStyle(
                                  color: primaryBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
      ),
    );
  }

  Widget _dropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required bool isDarkTheme,
    required Color text,
    required Color muted,
    required String Function(String) display,
    required void Function(String?) onChanged,
    required String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      menuMaxHeight: 320,
      validator: validator,
      onChanged: onChanged,
      icon: const SizedBox.shrink(),
      dropdownColor: isDarkTheme ? const Color(0xFF1A1A2E) : Colors.white,
      style: TextStyle(
        color: text,
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: TextStyle(
          color: muted,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: 0.3,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        filled: true,
        fillColor:
            isDarkTheme ? const Color(0xFF0B1626) : const Color(0xFFF8FAFD),
        prefixIcon: Container(
          margin: const EdgeInsets.only(left: 0, right: 2),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.list_alt_rounded, color: primaryBlue, size: 20),
        ),
        suffixIcon: Container(
          margin: const EdgeInsets.only(right: 0),
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(.09),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: primaryBlue,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color:
                isDarkTheme
                    ? Colors.white.withOpacity(.08)
                    : primaryBlue.withOpacity(0.15),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color:
                isDarkTheme
                    ? Colors.white.withOpacity(.08)
                    : primaryBlue.withOpacity(0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBlue, width: 1.7),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
      ),
      items:
          items.map((item) {
            final isSelected = item == value;
            return DropdownMenuItem<String>(
              value: item,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? primaryBlue.withOpacity(0.08)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (isSelected) ...[
                      Icon(
                        Icons.check_circle_rounded,
                        color: primaryBlue,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                    ] else ...[
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isDarkTheme
                                    ? Colors.white.withOpacity(0.2)
                                    : const Color(0xFFE0E7F0),
                            width: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        display(item),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? primaryBlue : text,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
      selectedItemBuilder: (context) {
        return items.map((item) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  display(item),
                  style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _termsWidget({
    required bool isDarkTheme,
    required bool agreed,
    required ValueChanged<bool> onChanged,
    required VoidCallback onTermsTap,
    required VoidCallback onPrivacyTap,
    required Color muted,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color:
            isDarkTheme
                ? Colors.white.withOpacity(0.03)
                : const Color(0xFFF6F8FC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color:
              isDarkTheme
                  ? Colors.white.withOpacity(0.05)
                  : const Color(0xFFE1E8F2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: agreed,
            activeColor: primaryBlue,
            onChanged: (value) => onChanged(value ?? false),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Wrap(
                children: [
                  Text(
                    _t('I agree to the ', 'मैं सहमत हूं '),
                    style: TextStyle(
                      fontSize: 12,
                      color: muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: onTermsTap,
                    child: Text(
                      _t('Terms & Conditions', 'नियम व शर्तें'),
                      style: TextStyle(
                        fontSize: 12,
                        color: primaryBlue,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Text(
                    _t(' and ', ' और '),
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                  GestureDetector(
                    onTap: onPrivacyTap,
                    child: Text(
                      _t('Privacy Policy', 'गोपनीयता नीति'),
                      style: TextStyle(
                        fontSize: 12,
                        color: primaryBlue,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _invalidAccess() {
    return Scaffold(
      backgroundColor: primaryLight,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(.07),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 58,
                  color: errorRed,
                ),
                const SizedBox(height: 14),
                Text(
                  _t('Invalid access', 'गलत प्रवेश'),
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _t(
                    'Please try again from the welcome page.',
                    'कृपया स्वागत पेज से दोबारा प्रयास करें।',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textLight),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WelcomePage(),
                          ),
                        ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      _t('Go to Home', 'होम पर जाएं'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
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
}

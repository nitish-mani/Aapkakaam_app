// this file is made responsive for all devices with theme colors.

import 'dart:async';
import 'dart:convert';

import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/models/data_model.dart';
import 'package:app_aapkakaam/navBarWidgets/home_page.dart';
import 'package:app_aapkakaam/widgets/change_password.dart';
import 'package:app_aapkakaam/widgets/signup_page.dart';
import 'package:app_aapkakaam/widgets/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_aapkakaam/widgets/firebase_notification.dart';

class LoginPage extends StatefulWidget {
  final String? category;
  final String? cd;
  final String? id;

  const LoginPage({super.key, this.category, this.cd, this.id});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Theme Colors
  static const Color _primaryBlue = Color(0xFF4F46E5);
  static const Color _primaryPurple = Color(0xFF7C3AED);
  static const Color _primaryLight = Color(0xFFEEF2FF);
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _textLight = Color(0xFF6B7280);
  static const Color _errorRed = Color(0xFFEF4444);

  String _t(String english, String hindi) {
    return isHindiNotifier.value ? hindi : english;
  }

  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool isLoading = false;
  bool isLoggedInL = false;
  late Map<String, dynamic> data = {};

  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String get _profileCategory {
    if (widget.category == null) return '';
    return widget.category![0].toUpperCase() + widget.category!.substring(1);
  }

  Future<void> _submitForm(
    bool isVendor,
    ValueNotifier<bool> isLoggedIn,
  )async {
    if (widget.category == null) {
      _showSnackBar(
        _t(
          'Invalid access. Please try again.',
          'अमान्य पहुँच। कृपया पुनः प्रयास करें।',
        ),
        _errorRed,
      );
      return;
    }

    if (_mobileController.text.isEmpty) {
      _showSnackBar(
        _t(
          'Please enter your mobile number',
          'कृपया अपना मोबाइल नंबर दर्ज करें',
        ),
        _errorRed,
      );
      return;
    }
    if (_mobileController.text.length != 10) {
      _showSnackBar(
        _t(
          'Please enter a valid 10-digit mobile number',
          'कृपया सही 10 अंकों का मोबाइल नंबर दर्ज करें',
        ),
        _errorRed,
      );
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showSnackBar(
        _t(
          'Please enter your password',
          'कृपया अपना पासवर्ड दर्ज करें',
        ),
        _errorRed,
      );
      return;
    }
    if (_passwordController.text.length < 6) {
      _showSnackBar(
        _t(
          'Password must be at least 6 characters',
          'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए',
        ),
        _errorRed,
      );
      return;
    }
    setState(() {
      isLoading = true;
    });

    final String serverUrl = KConstantURL.url;
    final String category = isVendor ? 'vendor' : 'user';
    final Uri url = Uri.parse("$serverUrl/$category/login");

    try {
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "phoneNo": int.parse(_mobileController.text),
              "password": _passwordController.text,
              "fcmToken": fcmToken.value,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        try {
          data = jsonDecode(response.body);
        } catch (e) {
          throw Exception("Invalid JSON format from server");
        }

        isAddressAvailable.value = data['address']?.isNotEmpty ?? false;
        isWageRateAvailable.value = data['wageRate'] != null;

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("isLoggedIn", "true");

        if (isVendor) {
          final vendor = VendorModel.fromJson(data);
          await prefs.setString("vendor", jsonEncode(vendor.toJson()));
        } else {
          final user = UserModel.fromJson(data);
          await prefs.setString("user", jsonEncode(user.toJson()));
        }

        setState(() {
          isLoading = false;
          isLoggedInL = true;
        });

        if (!mounted) return;
        _showSnackBar(data['message'] ?? 'Login successful!', _primaryPurple);

        isLoggedIn.value = true;

        Future.delayed(const Duration(seconds: 2), () async {
          if (!mounted) return;

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );

          await FirebaseNotifications.synchronizeCurrentToken();
        });
      } else if (response.statusCode == 401) {
        data = jsonDecode(response.body);
        setState(() {
          isLoading = false;
        });
        _showSnackBar(data['message'] ?? 'Invalid credentials', _errorRed);
      } else {
        throw Exception("Unexpected response: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print(e);
      _showSnackBar(
        e.toString().contains("timeout")
            ? "Connection timeout. Please check your internet."
            : "Something went wrong. Please try again.",
        _errorRed,
      );
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.1,
          vertical: MediaQuery.of(context).size.height * 0.02,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.height < 700;
    final isNarrow = size.width < 380;

    if (widget.category == null) {
      return _buildInvalidAccess();
    }

    return ValueListenableBuilder<bool>(
      valueListenable: isHindiNotifier,
      builder: (context, isHindi, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: isDarkThemeNotifier,
          builder: (context, isDarkTheme, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: isVendor,
              builder: (context, vendorMode, _) {
                final bg =
                    isDarkTheme ? const Color(0xFF0B1020) : _primaryLight;
                final surface =
                    isDarkTheme ? const Color(0xFF1A1A2E) : Colors.white;
                final text = isDarkTheme ? Colors.white : _textDark;
                final muted = isDarkTheme ? Colors.white60 : _textLight;

                return Scaffold(
                  backgroundColor: bg,
                  body: Stack(
                    children: [
                      // Background decorations
                      Positioned(
                        top: -150,
                        right: -100,
                        child: _circle(
                          320,
                          _primaryBlue.withOpacity(isDarkTheme ? .12 : .07),
                        ),
                      ),
                      Positioned(
                        bottom: -180,
                        left: -130,
                        child: _circle(
                          350,
                          _primaryPurple.withOpacity(isDarkTheme ? .08 : .055),
                        ),
                      ),
                      Positioned(
                        top: 200,
                        left: -80,
                        child: _circle(
                          180,
                          _primaryBlue.withOpacity(isDarkTheme ? .05 : .03),
                        ),
                      ),

                      SafeArea(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  isNarrow ? 18 : 26,
                                  14,
                                  isNarrow ? 18 : 26,
                                  28,
                                ),
                                child: Column(
                                  children: [
                                    _topBar(
                                      context,
                                      isHindi,
                                      isDarkTheme,
                                      text,
                                    ),
                                    SizedBox(height: isCompact ? 22 : 34),

                                    // Brand / category hero
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.fromLTRB(
                                        22,
                                        24,
                                        22,
                                        22,
                                      ),
                                      decoration: BoxDecoration(
                                        color: surface,
                                        borderRadius: BorderRadius.circular(28),
                                        border: Border.all(
                                          color:
                                              isDarkTheme
                                                  ? Colors.white.withOpacity(
                                                    .07,
                                                  )
                                                  : _primaryBlue.withOpacity(
                                                    0.12,
                                                  ),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _primaryBlue.withOpacity(
                                              isDarkTheme ? .15 : .06,
                                            ),
                                            blurRadius: 28,
                                            offset: const Offset(0, 14),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 76,
                                            height: 76,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  _primaryBlue,
                                                  _primaryPurple,
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(23),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: _primaryBlue
                                                      .withOpacity(.24),
                                                  blurRadius: 22,
                                                  offset: const Offset(0, 9),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              vendorMode
                                                  ? Icons.handyman_rounded
                                                  : Icons.person_rounded,
                                              color: Colors.white,
                                              size: 38,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            _t(
                                              '${_profileCategory} Login',
                                              '${vendorMode ? "सेवा प्रदाता" : "उपयोगकर्ता"} लॉगिन',
                                            ),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: text,
                                              fontSize: isNarrow ? 24 : 27,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -.6,
                                            ),
                                          ),
                                          const SizedBox(height: 7),
                                          Text(
                                            _t(
                                              'Sign in to continue to Aapkakaam',
                                              'आपकाकाम पर आगे बढ़ने के लिए लॉगिन करें',
                                            ),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: muted,
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // Form card
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(
                                        isNarrow ? 16 : 20,
                                      ),
                                      decoration: BoxDecoration(
                                        color: surface,
                                        borderRadius: BorderRadius.circular(26),
                                        border: Border.all(
                                          color:
                                              isDarkTheme
                                                  ? Colors.white.withOpacity(
                                                    .07,
                                                  )
                                                  : _primaryBlue.withOpacity(
                                                    0.12,
                                                  ),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _primaryBlue.withOpacity(
                                              isDarkTheme ? .12 : .04,
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
                                            Text(
                                              _t(
                                                'Account details',
                                                'खाते की जानकारी',
                                              ),
                                              style: TextStyle(
                                                color: text,
                                                fontSize: 17,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            const SizedBox(height: 15),

                                            _field(
                                              context: context,
                                              label: _t(
                                                'Mobile number',
                                                'मोबाइल नंबर',
                                              ),
                                              hint: _t(
                                                'Enter 10-digit mobile number',
                                                '10 अंकों का मोबाइल नंबर डालें',
                                              ),
                                              controller: _mobileController,
                                              icon: Icons.phone_rounded,
                                              text: text,
                                              muted: muted,
                                              isDarkTheme: isDarkTheme,
                                              keyboardType: TextInputType.phone,
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return _t(
                                                    'Mobile number is required',
                                                    'मोबाइल नंबर आवश्यक है',
                                                  );
                                                }
                                                if (value.length != 10 ||
                                                    int.tryParse(value) ==
                                                        null) {
                                                  return _t(
                                                    'Enter a valid 10-digit number',
                                                    'सही 10 अंकों का नंबर डालें',
                                                  );
                                                }
                                                return null;
                                              },
                                            ),

                                            const SizedBox(height: 14),

                                            _field(
                                              context: context,
                                              label: _t('Password', 'पासवर्ड'),
                                              hint: _t(
                                                'Enter your password',
                                                'अपना पासवर्ड डालें',
                                              ),
                                              controller: _passwordController,
                                              icon: Icons.lock_rounded,
                                              text: text,
                                              muted: muted,
                                              isDarkTheme: isDarkTheme,
                                              obscureText: _obscurePassword,
                                              suffixIcon: IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _obscurePassword =
                                                        !_obscurePassword;
                                                  });
                                                },
                                                icon: Icon(
                                                  _obscurePassword
                                                      ? Icons
                                                          .visibility_off_rounded
                                                      : Icons
                                                          .visibility_rounded,
                                                  color: muted,
                                                ),
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return _t(
                                                    'Password is required',
                                                    'पासवर्ड आवश्यक है',
                                                  );
                                                }
                                                if (value.length < 6) {
                                                  return _t(
                                                    'Password must be at least 6 characters',
                                                    'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए',
                                                  );
                                                }
                                                return null;
                                              },
                                            ),

                                            const SizedBox(height: 7),

                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: TextButton(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (_) =>
                                                              const ChangePasswordPage(),
                                                    ),
                                                  );
                                                },
                                                child: Text(
                                                  _t(
                                                    'Forgot password?',
                                                    'पासवर्ड भूल गए?',
                                                  ),
                                                  style: TextStyle(
                                                    color: _primaryBlue,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                            ),

                                            const SizedBox(height: 8),

                                            SizedBox(
                                              width: double.infinity,
                                              height: 56,
                                              child: ElevatedButton(
                                                onPressed:
                                                    isLoading
                                                        ? null
                                                        : () => _submitForm(
                                                          vendorMode,
                                                          isLoggedIn,
                                                        ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      _primaryPurple,
                                                  foregroundColor: Colors.white,
                                                  disabledBackgroundColor:
                                                      _primaryPurple
                                                          .withOpacity(.55),
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          17,
                                                        ),
                                                  ),
                                                ),
                                                child: AnimatedSwitcher(
                                                  duration: const Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  child:
                                                      isLoading
                                                          ? const SizedBox(
                                                            key: ValueKey(
                                                              'loading',
                                                            ),
                                                            width: 23,
                                                            height: 23,
                                                            child:
                                                                CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2.5,
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                ),
                                                          )
                                                          : Row(
                                                            key: const ValueKey(
                                                              'login',
                                                            ),
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .login_rounded,
                                                                size: 21,
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              Text(
                                                                _t(
                                                                  'Login',
                                                                  'लॉगिन',
                                                                ),
                                                                style: const TextStyle(
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
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 18),

                                    // Signup card
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isDarkTheme
                                                ? const Color(0xFF1A1A2E)
                                                : _primaryBlue.withOpacity(
                                                  0.05,
                                                ),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color:
                                              isDarkTheme
                                                  ? Colors.white.withOpacity(
                                                    .05,
                                                  )
                                                  : _primaryBlue.withOpacity(
                                                    0.10,
                                                  ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              _t(
                                                "Don't have an account?",
                                                'खाता नहीं है?',
                                              ),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: muted,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) => SignupPage(
                                                        category:
                                                            widget.category,
                                                        cd: widget.cd,
                                                        id: widget.id,
                                                      ),
                                                ),
                                              );
                                            },
                                            child: Text(
                                              _t('Sign Up', 'साइन अप करें'),
                                              style: TextStyle(
                                                color: _primaryBlue,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 18),

                                    Text(
                                      _t(
                                        'Secure login • Aapkakaam',
                                        'सुरक्षित लॉगिन • आपकाकाम',
                                      ),
                                      style: TextStyle(
                                        color: muted.withOpacity(.85),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
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
      },
    );
  }

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
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const WelcomePage()),
                (route) => false,
              );
            },
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isDarkTheme
                          ? Colors.white.withOpacity(.08)
                          : _primaryBlue.withOpacity(0.15),
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
                      : _primaryBlue.withOpacity(0.15),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () {
              isHindiNotifier.value = !isHindiNotifier.value;
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.language_rounded, color: _primaryBlue, size: 18),
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

  Widget _field({
    required BuildContext context,
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required Color text,
    required Color muted,
    required bool isDarkTheme,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(color: text, fontSize: 15, fontWeight: FontWeight.w600),
      cursorColor: _primaryBlue,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: muted, fontWeight: FontWeight.w600),
        hintStyle: TextStyle(color: muted.withOpacity(.65), fontSize: 13),
        prefixIcon: Icon(icon, color: _primaryBlue, size: 21),
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
                    : _primaryBlue.withOpacity(0.15),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color:
                isDarkTheme
                    ? Colors.white.withOpacity(.08)
                    : _primaryBlue.withOpacity(0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _primaryBlue, width: 1.7),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _errorRed, width: 1.5),
        ),
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

  Widget _buildInvalidAccess() {
    return Scaffold(
      backgroundColor: _primaryLight,
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
                  color: _primaryBlue.withOpacity(.07),
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
                  color: _errorRed,
                ),
                const SizedBox(height: 14),
                Text(
                  _t('Invalid access', 'गलत प्रवेश'),
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _t(
                    'Please try again from the welcome page.',
                    'कृपया स्वागत पेज से दोबारा प्रयास करें।',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _textLight),
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
                      backgroundColor: _primaryBlue,
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

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/widgets/login_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  // Theme Colors
  static const Color _primaryBlue = Color(0xFF4F46E5);
  static const Color _primaryPurple = Color(0xFF7C3AED);
  static const Color _primaryLight = Color(0xFFEEF2FF);
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _textLight = Color(0xFF6B7280);
  static const Color _errorRed = Color(0xFFEF4444);
  static const Color _successGreen = Color(0xFF22C55E);
  static const Color _accentOrange = Color(0xFFF59E0B);

  // Controllers
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  // State variables
  String _otpId = "";
  bool _isLoading = false;
  bool _isOtpSent = false;
  bool _otpVerified = false;
  bool _otpTimer = false;
  Timer? _timer;
  int _timerSeconds = 0;

  String _category = 'user';
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ============================================================
  // HINDI TRANSLATION HELPER
  // ============================================================

  String _t(String en, String hi) {
    return isHindiNotifier.value ? hi : en;
  }

  // ============================================================
  // LOAD USER DATA
  // ============================================================

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final isVendor1 = isVendor.value;
    _category = isVendor1 ? 'vendor' : 'user';
    final categoryData = prefs.getString(_category);

    if (categoryData != null) {
      final decoded = jsonDecode(categoryData);
      _token = decoded['token'];
    }
  }

  void _startTimer() {
    setState(() {
      _otpTimer = true;
      _timerSeconds = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timerSeconds > 0) {
          _timerSeconds--;
        } else {
          _timer?.cancel();
          setState(() {
            _otpTimer = false;
          });
        }
      });
    });
  }

  // ============================================================
  // API CALLS
  // ============================================================

  Future<void> _sendOTP() async {
    if (_category.isEmpty) {
      _showSnackbar(
        _t('User data not found', 'उपयोगकर्ता डेटा नहीं मिला'),
        _errorRed,
      );
      return;
    }

    if (_phoneController.text.length != 10) {
      _showSnackbar(
        _t(
          'Mobile Number must be 10 digits',
          'मोबाइल नंबर 10 अंकों का होना चाहिए',
        ),
        _errorRed,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(
          "${KConstantURL.url}/${_category}/phoneVerificationPasswordReset",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phoneNo": int.parse(_phoneController.text),
          "changingPass": true,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _otpId = data['otpId'];
          _isOtpSent = true;
          _isLoading = false;
        });
        _startTimer();
        _showSnackbar(
          _t('OTP sent successfully', 'OTP सफलतापूर्वक भेजा गया'),
          _primaryBlue,
        );
      } else {
        setState(() => _isLoading = false);
        _showSnackbar(
          _t('Failed to send OTP', 'OTP भेजने में विफल'),
          _errorRed,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar(
        _t('Error: ${e.toString()}', 'त्रुटि: ${e.toString()}'),
        _errorRed,
      );
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length != 6) {
      _showSnackbar(
        _t('Please enter valid 6-digit OTP', 'कृपया सही 6 अंकों का OTP डालें'),
        _errorRed,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(
          "${KConstantURL.url}/${_category}/otpVerificationResetPassword",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "otp": int.parse(_otpController.text),
          "otpId": _otpId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['verified'] == true) {
          setState(() {
            _otpVerified = true;
            _isOtpSent = false;
            _isLoading = false;
            _otpController.clear();
          });
          _showSnackbar(
            _t('OTP verified successfully', 'OTP सफलतापूर्वक सत्यापित हुआ'),
            _primaryBlue,
          );
        } else {
          setState(() => _isLoading = false);
          _showSnackbar(
            data['message'] ??
                _t('OTP verification failed', 'OTP सत्यापन विफल'),
            _errorRed,
          );
        }
      } else {
        setState(() => _isLoading = false);
        _showSnackbar(
          _t('OTP verification failed', 'OTP सत्यापन विफल'),
          _errorRed,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar(
        _t('Error: ${e.toString()}', 'त्रुटि: ${e.toString()}'),
        _errorRed,
      );
    }
  }

  Future<void> _updatePassword() async {
    if (_passwordController.text.length < 6) {
      _showSnackbar(
        _t(
          'Password must be at least 6 characters',
          'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए',
        ),
        _errorRed,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.patch(
        Uri.parse("${KConstantURL.url}/${_category}/edit/password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phoneNo": int.parse(_phoneController.text),
          "password": _passwordController.text,
          "otpId": _otpId,
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;

        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t(
                'Password Updated Successfully',
                'पासवर्ड सफलतापूर्वक अपडेट हुआ',
              ),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: _primaryBlue,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(category: _category),
          ),
          (route) => false,
        );

        return;
      } else {
        setState(() => _isLoading = false);
        _showSnackbar(
          _t('Failed to update password', 'पासवर्ड अपडेट करने में विफल'),
          _errorRed,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar(
        _t('Error: ${e.toString()}', 'त्रुटि: ${e.toString()}'),
        _errorRed,
      );
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _getButtonText() {
    if (!_otpVerified) {
      if (_isOtpSent) {
        return _t('Verify OTP', 'OTP सत्यापित करें');
      } else {
        return _t('Send OTP', 'OTP भेजें');
      }
    } else {
      return _t('Update Password', 'पासवर्ड अपडेट करें');
    }
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
            return _buildPage(context, isDarkTheme: isDarkTheme);
          },
        );
      },
    );
  }

  Widget _buildPage(BuildContext context, {required bool isDarkTheme}) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 400;

    final backgroundColor =
        isDarkTheme ? const Color(0xFF0B1020) : const Color(0xFFF0F2F8);
    final cardColor = isDarkTheme ? const Color(0xFF1A1A2E) : Colors.white;
    final textColor = isDarkTheme ? Colors.white : _textDark;
    final secondaryTextColor = isDarkTheme ? Colors.white60 : _textLight;
    final borderColor =
        isDarkTheme ? Colors.white.withOpacity(0.06) : Colors.grey[200]!;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          _t('Change Password', 'पासवर्ड बदलें'),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 18 : 20,
            color: textColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                isDarkTheme ? Colors.white.withOpacity(0.05) : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkTheme ? 0.2 : 0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Icon
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryBlue, _primaryPurple],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _primaryBlue.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Center(
                    child: Text(
                      _t('Reset Your Password', 'अपना पासवर्ड बदलें '),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _t(
                        'Enter your mobile number to receive OTP',
                        'OTP प्राप्त करने के लिए अपना मोबाइल नंबर डालें',
                      ),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        color: secondaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mobile Number Field
                  if (!_otpVerified)
                    _buildTextField(
                      controller: _phoneController,
                      label: _t('Mobile Number', 'मोबाइल नंबर'),
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      readOnly: _isOtpSent,
                      maxLength: 10,
                      isDarkTheme: isDarkTheme,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      borderColor: borderColor,
                    ),

                  // OTP Field
                  if (_isOtpSent && !_otpVerified)
                    _buildTextField(
                      controller: _otpController,
                      label: _t('Enter OTP', 'OTP डालें'),
                      icon: Icons.numbers_rounded,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      isDarkTheme: isDarkTheme,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      borderColor: borderColor,
                    ),

                  // New Password Field
                  if (_otpVerified)
                    _buildTextField(
                      controller: _passwordController,
                      label: _t('New Password', 'नया पासवर्ड'),
                      icon: Icons.lock_rounded,
                      obscureText: true,
                      isDarkTheme: isDarkTheme,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      borderColor: borderColor,
                      hintText: _t(
                        'Enter new password (min 6 characters)',
                        'नया पासवर्ड डालें (कम से कम 6 अक्षर)',
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed:
                          _isLoading
                              ? null
                              : !_otpVerified
                              ? _isOtpSent
                                  ? _verifyOTP
                                  : _sendOTP
                              : _updatePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _primaryBlue.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                              : Text(
                                _getButtonText(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // OTP Timer
                  if (_otpTimer && !_otpVerified)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _accentOrange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _accentOrange.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: _accentOrange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _t(
                              'Resend OTP After ${_timerSeconds}s',
                              'OTP पुनः भेजें ${_timerSeconds} सेकंड बाद',
                            ),
                            style: TextStyle(
                              color: _accentOrange,
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Info Text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _primaryBlue.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _primaryBlue.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: _primaryBlue,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _t(
                              'You will be redirected to login page after password update',
                              'पासवर्ड अपडेट करने के बाद आपको लॉगिन पेज पर रीडायरेक्ट किया जाएगा',
                            ),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              color: _primaryBlue,
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
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool readOnly = false,
    int? maxLength,
    required bool isDarkTheme,
    required Color textColor,
    required Color secondaryTextColor,
    required Color borderColor,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        readOnly: readOnly,
        maxLength: maxLength,
        style: TextStyle(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          hintStyle: TextStyle(
            color: secondaryTextColor.withOpacity(0.6),
            fontSize: 13,
          ),
          labelStyle: TextStyle(
            color: secondaryTextColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          prefixIcon: Icon(icon, color: _primaryBlue, size: 22),
          counterText: '',
          filled: true,
          fillColor:
              isDarkTheme ? const Color(0xFF0B1626) : const Color(0xFFF8FAFD),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: borderColor, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _primaryBlue, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

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

  String _errorMessage = '';
  String _successMessage = '';

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

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final isVendor1 = isVendor.value;
    _category = isVendor1 ? 'vendor' : 'user';
    final categoryData = prefs.getString(_category!);

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

  Future<void> _sendOTP() async {
    if (_category == null) {
      _showSnackbar('User data not found', Colors.red);
      return;
    }

    if (_phoneController.text.length != 10) {
      _showSnackbar('Mobile Number must be 10 digits', Colors.red);
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
        _showSnackbar('OTP sent successfully', Colors.green);
      } else {
        setState(() => _isLoading = false);
        _showSnackbar('Failed to send OTP', Colors.red);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar('Error: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length != 6) {
      _showSnackbar('Please enter valid 6-digit OTP', Colors.red);
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
          _showSnackbar('OTP verified successfully', Colors.green);
        } else {
          setState(() => _isLoading = false);
          _showSnackbar(
            data['message'] ?? 'OTP verification failed',
            Colors.red,
          );
        }
      } else {
        setState(() => _isLoading = false);
        _showSnackbar('OTP verification failed', Colors.red);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar('Error: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _updatePassword() async {
    if (_passwordController.text.length < 6) {
      _showSnackbar('Password must be at least 6 characters', Colors.red);
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
          const SnackBar(
            content: Text('Password Updated Successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
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
        _showSnackbar('Failed to update password', Colors.red);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar('Error: ${e.toString()}', Colors.red);
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
        return 'Verify OTP';
      } else {
        return 'Send OTP';
      }
    } else {
      return 'Update Password';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Change Password',
          style: TextStyle(fontWeight: FontWeight.bold),
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24),
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
                            colors: [
                              Colors.blue.shade600,
                              Colors.purple.shade600,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_reset,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Center(
                      child: Text(
                        'Reset Your Password',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Enter your mobile number to receive OTP',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Mobile Number Field
                    if (!_otpVerified)
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Mobile Number',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        readOnly: _isOtpSent,
                        maxLength: 10,
                        isDark: isDark,
                      ),

                    // OTP Field
                    if (_isOtpSent && !_otpVerified)
                      _buildTextField(
                        controller: _otpController,
                        label: 'Enter OTP',
                        icon: Icons.numbers,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        isDark: isDark,
                      ),

                    // New Password Field
                    if (_otpVerified)
                      _buildTextField(
                        controller: _passwordController,
                        label: 'New Password',
                        icon: Icons.lock,
                        obscureText: true,
                        isDark: isDark,
                        hintText: 'Enter new password (min 6 characters)',
                      ),

                    const SizedBox(height: 20),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
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
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
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
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Resend OTP After ${_timerSeconds}s',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
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
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You will be redirected to login page after password update',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool readOnly = false,
    int? maxLength,
    required bool isDark,
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
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          hintStyle: TextStyle(
            color: isDark ? Colors.grey[500] : Colors.grey[400],
          ),
          labelStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          prefixIcon: Icon(icon, color: Colors.blue.shade600),
          counterText: '',
          filled: true,
          fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
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

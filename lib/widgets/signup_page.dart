// this file is made responsive.

import 'dart:async';
import 'dart:convert';
import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/widgets/body_page.dart';
import 'package:flutter/material.dart';
import 'package:app_aapkakaam/widgets/login_page.dart';
import 'package:app_aapkakaam/widgets/welcome_page.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class SignupPage extends StatefulWidget {
  final String? category;
  final String? cd;
  final String? id;

  const SignupPage({super.key, this.category, this.cd, this.id});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool isLoading = false;
  bool isPhoneOtpLoading = false;
  bool isOtpSent = false;
  bool isNumberLenthIsTen = false;
  bool isNumberVerified = false;
  String otpId = "";
  bool _agreedToTnC = false;

  late Map<String, dynamic> data;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  String? _selectedProfession;
  String? _selectedGender;
  final List<String> _gender = ['Male', 'Female', 'Other'];

  // Extract all unique profession titles from serviceData
  List<String> get _professions {
    final List<String> professions = [];
    for (final category in serviceData) {
      for (final service in category.services) {
        final String jobType = service.jobType;
        final String displayName = jobType
            .split(' ')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
        if (!professions.contains(displayName)) {
          professions.add(displayName);
        }
      }
    }
    professions.sort();
    return professions;
  }

  String get _profileCategory {
    if (widget.category == null) return '';
    return widget.category![0].toUpperCase() + widget.category!.substring(1);
  }

  @override
  void initState() {
    super.initState();
    _mobileController.addListener(_checkMobileLength);
  }

  void _checkMobileLength() {
    final text = _mobileController.text;

    if (text.length == 10 && !isNumberLenthIsTen) {
      setState(() {
        isNumberLenthIsTen = true;
      });
    } else if (text.length != 10 && isNumberLenthIsTen) {
      setState(() {
        isNumberLenthIsTen = false;
      });
    }
  }

  @override
  void dispose() {
    _mobileController.removeListener(_checkMobileLength);
    _nameController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _phoneNoVerification() async {
    if (widget.category == null) {
      _showSnackBar('Invalid access. Please try again.', Colors.red);
      return;
    }

    if (!isOtpSent) {
      if (_mobileController.text.length != 10) {
        _showSnackBar('Mobile Number must be 10 digits', Colors.red);
        return;
      }

      setState(() => isPhoneOtpLoading = true);

      try {
        final response = await http.post(
          Uri.parse("${KConstantURL.url}/${widget.category}/phoneVerification"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"phoneNo": int.parse(_mobileController.text)}),
        );

        data = jsonDecode(response.body);
        print(data);

        if (data['verified'] == true || response.statusCode == 200) {
          setState(() {
            isPhoneOtpLoading = false;
            isOtpSent = true;
            otpId = data['otpId'];
          });
          otpId1.value = otpId;
          _showSnackBar(
            data['message'] ?? 'OTP sent successfully',
            Colors.green,
          );
        } else {
          setState(() => isPhoneOtpLoading = false);
          _showSnackBar(
            data['message'] ?? 'Phone verification failed',
            Colors.red,
          );
        }
      } catch (err) {
        setState(() => isPhoneOtpLoading = false);
        print('err --------------------------------: $err');
        _showSnackBar('Phone verification failed', Colors.red);
      }
    } else {
      if (_otpController.text.length != 6) {
        _showSnackBar('Please enter valid OTP', Colors.red);
        return;
      }

      setState(() => isPhoneOtpLoading = true);

      try {
        final response = await http.post(
          Uri.parse("${KConstantURL.url}/${widget.category}/otpVerification"),
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
            Colors.green,
          );
        } else {
          setState(() => isPhoneOtpLoading = false);
          _showSnackBar(
            data['message'] ?? 'OTP verification failed',
            Colors.red,
          );
        }
      } catch (err) {
        setState(() => isPhoneOtpLoading = false);
        print('err --------------------------------: $err');
        _showSnackBar('OTP verification failed', Colors.red);
      }
    }
  }

  Future<void> _submitForm() async {
    if (widget.category == null) {
      _showSnackBar('Invalid access. Please try again.', Colors.red);
      return;
    }

    // Validation checks
    if (_nameController.text.isEmpty) {
      _showSnackBar('Please enter your name', Colors.red);
      return;
    }
    if (_mobileController.text.length != 10) {
      _showSnackBar('Please enter a valid mobile number', Colors.red);
      return;
    }
    // if (!isNumberVerified) {
    //   _showSnackBar('Please verify your mobile number', Colors.red);
    //   return;
    // }
    if (_passwordController.text.length < 6) {
      _showSnackBar('Password must be at least 6 characters', Colors.red);
      return;
    }
    if (_selectedGender == null) {
      _showSnackBar('Please select your gender', Colors.red);
      return;
    }
    if (widget.category == 'vendor' && _selectedProfession == null) {
      _showSnackBar('Please select your profession', Colors.red);
      return;
    }
    if (!_agreedToTnC) {
      _showSnackBar(
        'You must accept the Terms & Conditions and Privacy Policy',
        Colors.red,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("${KConstantURL.url}/${widget.category}/signup"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": _nameController.text,
          "phoneNo": int.parse(_mobileController.text),
          "password": _passwordController.text,
          "sharedBy": widget.id,
          "gender": _selectedGender?.toLowerCase(),
          if (widget.category == 'vendor')
            "type": _selectedProfession?.toLowerCase(),
          if (widget.category == 'vendor')
            "experience": _experienceController.text,
          "cd": widget.cd,
          "validPhoneNoId": otpId1.value,
          "agreedToTnCnP": _agreedToTnC,
        }),
      );

      data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        _showSnackBar(data['message'] ?? 'Signup successful!', Colors.green);
        Timer(
          Duration(seconds: 2),
          () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LoginPage(category: widget.category),
            ),
          ),
        );
      } else {
        _showSnackBar(data['message'] ?? 'Signup failed', Colors.red);
      }
    } catch (e) {
      _showSnackBar("An error occurred. Please try again.", Colors.red);
      print('Error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Center(
          child: Text(
            message,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(10),
      ),
    );
  }

  void _openTerms() => launchUrl(Uri.parse("https://aapkakaam.com/terms"));
  void _openPrivacyPolicy() =>
      launchUrl(Uri.parse("https://aapkakaam.com/privacy-policy"));

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 375;

    if (widget.category == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Invalid access',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please try again from proper navigation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed:
                      () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WelcomePage(),
                        ),
                      ),
                  child: const Text('Go to Home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed:
              () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => WelcomePage()),
                (route) => false,
              ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade700, Colors.teal.shade400],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16 : 24,
              vertical: 16,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 500),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 10,
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_profileCategory Sign Up',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 22 : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade700,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 20),

                        // Name Field
                        _buildTextField(
                          label: "Full Name",
                          controller: _nameController,
                          icon: Icons.person,
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                        SizedBox(height: 12),

                        // Mobile/OTP Field with Verify Button
                        isOtpSent
                            ? _buildTextField(
                              label: "Enter OTP",
                              controller: _otpController,
                              icon: Icons.numbers,
                              keyboardType: TextInputType.phone,
                              validator:
                                  (v) => v!.length != 6 ? "Invalid" : null,
                            )
                            : _buildTextField(
                              label: "Mobile Number",
                              controller: _mobileController,
                              icon: Icons.phone,
                              keyboardType: TextInputType.phone,
                              readOnly: isNumberVerified ? true : false,
                              suffixIcon:
                                  isNumberVerified
                                      ? Icon(
                                        Icons.verified,
                                        color: Colors.green,
                                      )
                                      : null,
                              validator:
                                  (v) => v!.length != 10 ? "Invalid" : null,
                            ),
                        SizedBox(height: 12),

                        // Verify Button
                        if (isNumberLenthIsTen && !isNumberVerified)
                          SizedBox(
                            width: double.infinity,
                            height: isSmallScreen ? 45 : 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  48,
                                  207,
                                  189,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _phoneNoVerification,
                              child:
                                  isPhoneOtpLoading
                                      ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : isOtpSent
                                      ? Text(
                                        "Verify OTP",
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 16 : 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      )
                                      : Text(
                                        "Verify Mobile Number",
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 16 : 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                            ),
                          ),
                        if (isNumberLenthIsTen && !isNumberVerified)
                          SizedBox(height: 12),

                        // Password Field
                        _buildTextField(
                          label: "Password",
                          controller: _passwordController,
                          icon: Icons.lock,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.teal,
                              size: isSmallScreen ? 20 : 24,
                            ),
                            onPressed:
                                () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                          ),
                          validator:
                              (v) => v!.length < 6 ? "Min 6 characters" : null,
                        ),
                        SizedBox(height: 12),

                        // Profession Dropdown (Vendor only)
                        if (widget.category == 'vendor')
                          _buildDropdown(
                            value: _selectedProfession,
                            items: _professions,
                            hint: "Select profession",
                            onChanged:
                                (v) => setState(() => _selectedProfession = v),
                            validator: (v) => v == null ? "Required" : null,
                          ),
                        if (widget.category == 'vendor') SizedBox(height: 12),

                        // Experience Field (Vendor only)
                        if (widget.category == 'vendor')
                          _buildTextField(
                            label: "How many years of experience do you have?",
                            controller: _experienceController,
                            icon: Icons.work_outline,
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                        if (widget.category == 'vendor') SizedBox(height: 12),

                        // Gender Dropdown
                        _buildDropdown(
                          value: _selectedGender,
                          items: _gender,
                          hint: "Select gender",
                          onChanged: (v) => setState(() => _selectedGender = v),
                          validator: (v) => v == null ? "Required" : null,
                        ),
                        SizedBox(height: 12),

                        // Terms & Conditions
                        Row(
                          children: [
                            Checkbox(
                              value: _agreedToTnC,
                              onChanged: (val) {
                                setState(() {
                                  _agreedToTnC = val ?? false;
                                });
                              },
                            ),
                            Expanded(
                              child: Wrap(
                                children: [
                                  const Text("I agree to the "),
                                  GestureDetector(
                                    onTap: _openTerms,
                                    child: const Text(
                                      "Terms & Conditions",
                                      style: TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  const Text(" and "),
                                  GestureDetector(
                                    onTap: _openPrivacyPolicy,
                                    child: const Text(
                                      "Privacy Policy",
                                      style: TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: isSmallScreen ? 16 : 20),

                        // Sign Up Button
                        SizedBox(
                          width: double.infinity,
                          height: isSmallScreen ? 45 : 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _submitForm,
                            child:
                                isLoading
                                    ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Text(
                                      "Sign Up",
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 16 : 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                          ),
                        ),
                        SizedBox(height: 12),

                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Already Have an Account? "),
                            TextButton(
                              onPressed:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => LoginPage(
                                            category: widget.category,
                                          ),
                                    ),
                                  ),
                              child: Text(
                                "Login",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
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
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required void Function(String?) onChanged,
    required String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items:
          items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
      onChanged: onChanged,
      validator: validator,
      menuMaxHeight: 300,
      isExpanded: true,
      icon: Icon(Icons.arrow_drop_down, color: Colors.teal),
    );
  }
}

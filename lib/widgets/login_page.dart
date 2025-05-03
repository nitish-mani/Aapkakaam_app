// this file is made responsive for all devices.

import 'dart:async';
import 'dart:convert';

import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/models/data_model.dart';
import 'package:app_aapkakaam/navBarWidgets/home_page.dart';
import 'package:app_aapkakaam/widgets/signup_page.dart';
import 'package:app_aapkakaam/widgets/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool isLoading = false;
  bool isLoggedInL = false;
  late Map<String, dynamic> data = {};

  // Controllers
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _submitForm(
    bool isVendor,
    ValueNotifier<bool> isLoggedIn,
  ) async {
    if (_formKey.currentState!.validate()) {
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
            .timeout(const Duration(seconds: 15)); // Add timeout for better UX

        if (response.statusCode == 200) {
          try {
            data = jsonDecode(response.body);
          } catch (e) {
            throw Exception("Invalid JSON format from server");
          }

          // Update value notifiers
          isAddressAvailable.value = data['address']?.isNotEmpty ?? false;
          isWageRateAvailable.value = data['wageRate'] != null;

          // Store user data
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

          // Show success message
          if (!mounted) return;
          _showSnackBar(data['message'] ?? 'Login successful!', Colors.green);

          // Update login state and navigate
          isLoggedIn.value = true;
          Future.delayed(const Duration(seconds: 2), () {
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
              (route) => false,
            );
          });
        } else if (response.statusCode == 401) {
          data = jsonDecode(response.body);
          setState(() {
            isLoading = false;
          });

          _showSnackBar(data['message'] ?? 'Invalid credentials', Colors.red);
        } else {
          throw Exception("Unexpected response: ${response.statusCode}");
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });

        _showSnackBar(
          e.toString().contains("timeout")
              ? "Connection timeout. Please check your internet."
              : "Something went wrong. Please try again.",
          Colors.red,
        );
      }
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
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    // Calculate responsive sizing
    final horizontalPadding = screenSize.width * 0.06;
    final cardPadding = screenSize.width * 0.05;
    final iconSize = screenSize.width * 0.12;
    final buttonHeight = screenSize.height * 0.065;

    return ValueListenableBuilder(
      valueListenable: isDarkThemeNotifier,
      builder: (context, isDarkTheme, _) {
        return ValueListenableBuilder(
          valueListenable: isLoggedIn,
          builder: (context, _, __) {
            return Scaffold(
              appBar: AppBar(
                backgroundColor: isDarkTheme ? Colors.black : Colors.white,
                leading: IconButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WelcomePage(),
                      ),
                      (route) => false,
                    );
                  },
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDarkTheme ? Colors.white : Colors.black,
                  ),
                ),
              ),
              backgroundColor: isDarkTheme ? Colors.teal : Colors.amber,
              body: ValueListenableBuilder(
                valueListenable: isVendor,
                builder: (context, isVendor, _) {
                  return SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: screenSize.height * 0.02,
                          ),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 10,
                            color: isDarkTheme ? Colors.black87 : Colors.white,
                            child: Padding(
                              padding: EdgeInsets.all(cardPadding),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Login icon
                                    Icon(
                                      Icons.lock,
                                      size: iconSize,
                                      color:
                                          isDarkTheme
                                              ? Colors.amber
                                              : Colors.teal,
                                    ),
                                    SizedBox(height: screenSize.height * 0.015),

                                    // Login title
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        isVendor
                                            ? "Login to Vendor Account"
                                            : "Login to User Account",
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 20 : 22,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              isDarkTheme
                                                  ? Colors.amber
                                                  : Colors.teal,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: screenSize.height * 0.025),

                                    // Mobile Number Field
                                    _buildTextField(
                                      label: "Mobile Number",
                                      controller: _mobileController,
                                      isDarkTheme: isDarkTheme,
                                      icon: Icons.phone,
                                      keyboardType: TextInputType.phone,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "Mobile number is required";
                                        }
                                        if (value.length != 10 ||
                                            int.tryParse(value) == null) {
                                          return "Enter a valid 10-digit number";
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: screenSize.height * 0.015),

                                    // Password Field
                                    _buildTextField(
                                      label: "Password",
                                      controller: _passwordController,
                                      isDarkTheme: isDarkTheme,
                                      icon: Icons.lock,
                                      obscureText: _obscurePassword,
                                      suffixIcon: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                        child: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          transitionBuilder:
                                              (child, anim) => ScaleTransition(
                                                scale: anim,
                                                child: child,
                                              ),
                                          child: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            key: ValueKey(_obscurePassword),
                                            color:
                                                isDarkTheme
                                                    ? Colors.amber
                                                    : Colors.teal,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "Password is required";
                                        }
                                        if (value.length < 6) {
                                          return "Password must be at least 6 characters";
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: screenSize.height * 0.01),

                                    // Forgot Password
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {},
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: screenSize.width * 0.02,
                                            vertical: screenSize.height * 0.005,
                                          ),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          "Forgot Password?",
                                          style: TextStyle(
                                            color:
                                                !isDarkTheme
                                                    ? Colors.teal.shade700
                                                    : Colors.amber.shade700,
                                            fontWeight: FontWeight.bold,
                                            fontSize: isSmallScreen ? 12 : 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: screenSize.height * 0.015),

                                    // Login Button
                                    SizedBox(
                                      width: double.infinity,
                                      height: buttonHeight,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              isDarkTheme
                                                  ? Colors.amber
                                                  : Colors.teal,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                          ),
                                          elevation: 3,
                                        ),
                                        onPressed:
                                            isLoading
                                                ? null
                                                : () => _submitForm(
                                                  isVendor,
                                                  isLoggedIn,
                                                ),
                                        child:
                                            isLoading
                                                ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2.5,
                                                        color: Colors.white,
                                                      ),
                                                )
                                                : Text(
                                                  "Login",
                                                  style: TextStyle(
                                                    fontSize:
                                                        isSmallScreen ? 16 : 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                      ),
                                    ),

                                    SizedBox(height: screenSize.height * 0.02),

                                    // Signup Redirect
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Don't have an account?",
                                          style: TextStyle(
                                            color:
                                                isDarkTheme
                                                    ? Colors.white70
                                                    : Colors.black54,
                                            fontSize: isSmallScreen ? 12 : 14,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) => SignupPage(),
                                              ),
                                            );
                                          },
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  screenSize.width * 0.01,
                                            ),
                                            tapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                          child: Text(
                                            "Sign Up",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  !isDarkTheme
                                                      ? Colors.teal.shade700
                                                      : Colors.amber.shade700,
                                              fontSize: isSmallScreen ? 12 : 14,
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
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool isDarkTheme,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(
        color: isDarkTheme ? Colors.white : Colors.black,
        fontSize: isSmallScreen ? 14 : 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDarkTheme ? Colors.white70 : Colors.black87,
          fontSize: isSmallScreen ? 14 : 16,
        ),
        prefixIcon: Icon(
          icon,
          color: !isDarkTheme ? Colors.teal : Colors.amber,
          size: isSmallScreen ? 20 : 24,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDarkTheme ? Colors.black54 : Colors.white,
        contentPadding: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.height * 0.018,
          horizontal: MediaQuery.of(context).size.width * 0.03,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: isDarkTheme ? Colors.amber : Colors.teal,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: isDarkTheme ? Colors.teal : Colors.amber,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.red.shade700, width: 2),
        ),
        errorStyle: TextStyle(fontSize: isSmallScreen ? 11 : 12),
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

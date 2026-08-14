// this file is made responsive.

import 'dart:async';
import 'dart:convert';
import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:flutter/material.dart';
import 'package:app_aapkakaam/widgets/login_page.dart';
import 'package:app_aapkakaam/widgets/welcome_page.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool isLoading = false;
  bool isLoggedIn = false;
  bool isLoading1 = false;
  bool isNumberLenthIsTen = false;
  bool isNumberVarified = false;
  String otpId = "";

  bool _agreedToTnC = false;

  late Map<String, dynamic> data;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String? _selectedProfession;
  String? _selectedGender;
  final List<String> _gender = ['Male', 'Female', 'Other'];

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

  final List<String> _professions = [
    "AC Mechanic",
    "Aata Chakki",
    "Auto",
    "Bhoonsa Pual Seller",
    "Bike Repair",
    "Bus",
    "Carpenter",
    "Car Repair",
    "Chaat",
    "Cook",
    "DJ",
    "Dhankutti",
    "Dulha Rath",
    "E-Riksha",
    "Electrician",
    "Four Wheeler",
    "Fridge Mechanic",
    "Fruit Seller",
    "Generator",
    "Home Tutor",
    "Kirtan Mandli",
    "Labour",
    "Laptop Repair",
    "Latrine Tank Cleaner",
    "Lights",
    "Marble Fitter",
    "Marriage Hall",
    "Mason",
    "Menhandi Maker",
    "Milk Man",
    "Mini Truck",
    "Painter",
    "Paan Wala",
    "Parlour",
    "Plumber",
    "Pual Cutter",
    "Pundit Ji",
    "RO",
    "Shuttering",
    "Tent House",
    "Tiles Fitter",
    "Waiter",
    "Washer Man",
  ];

  @override
  void dispose() {
    _mobileController.removeListener(_checkMobileLength);
    _nameController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _phoneNoVarification(bool isVendor) async {
    setState(() => isLoading1 = true);

    try {
      if (otpId.isEmpty) {
        final response = await http.post(
          Uri.parse(
            "${KConstantURL.url}/${isVendor ? 'vendor' : 'user'}/phoneVerification",
          ),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"phoneNo": int.parse(_mobileController.text)}),
        );

        data = jsonDecode(response.body);
        print(data);
        if (data['status_code'] == 995) {
          _showSnackBar(data['message'], Colors.red);
        }
        if (response.statusCode == 200) {
          setState(() {
            isLoading1 = false;
            otpId = data['otpId'];
          });

          _showSnackBar(data['message'], Colors.green);
        }
      } else {
        final response = await http.post(
          Uri.parse(
            "${KConstantURL.url}/${isVendor ? 'vendor' : 'user'}/otpVerification",
          ),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "otp": int.parse(_otpController.text),
            "otpId": otpId,
          }),
        );

        data = jsonDecode(response.body);
        // print(data);
        if (data['verify']) {
          otpId1.value = otpId;
          setState(() {
            isLoading1 = false;
            isNumberVarified = true;
            otpId = "";
          });

          _showSnackBar(data['message'], Colors.green);
        } else {
          _showSnackBar(data['message'], Colors.red);
          setState(() {
            isLoading1 = false;
          });
        }
      }
    } catch (err) {
      // _showSnackBar('Something went wrong', Colors.red);
      setState(() {
        isLoading1 = false;
      });
      print('err --------------------------------: $err');
    }
  }

  Future<void> _submitForm(bool isVendor) async {
    if (_formKey.currentState!.validate() && isNumberVarified) {
      if (!_agreedToTnC) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "You must accept Terms & Conditions and Privacy Policy",
            ),
          ),
        );
        return;
      }
      setState(() => isLoading = true);

      try {
        final response = await http.post(
          Uri.parse(
            "${KConstantURL.url}/${isVendor ? 'vendor' : 'user'}/signup",
          ),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "name": _nameController.text,
            "phoneNo": int.parse(_mobileController.text),
            "password": _passwordController.text,
            "sharedBy": null, // You might want to handle these values
            "gender": _selectedGender?.toLowerCase(),
            if (isVendor) "type": _selectedProfession?.toLowerCase(),
            "cd": null,
            "validPhoneNoId": otpId1.value,
            "fcmToken": fcmToken.value,
            "agreedToTnCnP": _agreedToTnC,
          }),
        );

        data = jsonDecode(response.body);

        if (response.statusCode == 200) {
          _showSnackBar(data['message'], Colors.green);
          Timer(
            Duration(seconds: 2),
            () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            ),
          );
        } else {
          _showSnackBar(data['message'], Colors.red);
        }
      } catch (e) {
        _showSnackBar("An error occurred. Please try again.", Colors.red);
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
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
                  child: ValueListenableBuilder(
                    valueListenable: isVendor,
                    builder: (context, isVendor, _) {
                      return Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isVendor ? "Vendor Sign Up" : "User Sign Up",
                              style: TextStyle(
                                fontSize: isSmallScreen ? 22 : 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade700,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 16 : 20),

                            _buildTextField(
                              label: "Name",
                              controller: _nameController,
                              icon: Icons.person,
                              validator: (v) => v!.isEmpty ? "Required" : null,
                            ),
                            SizedBox(height: 12),

                            otpId.isEmpty
                                ? _buildTextField(
                                  label: "Mobile",
                                  controller: _mobileController,
                                  icon: Icons.phone,
                                  keyboardType: TextInputType.phone,
                                  readOnly: isNumberVarified ? true : false,
                                  suffixIcon:
                                      isNumberVarified
                                          ? Icon(
                                            Icons.verified,
                                            color: Colors.green,
                                          )
                                          : null,
                                  validator:
                                      (v) => v!.length != 10 ? "Invalid" : null,
                                )
                                : _buildTextField(
                                  label: "Enter OTP",
                                  controller: _otpController,
                                  icon: Icons.numbers,
                                  keyboardType: TextInputType.phone,
                                  validator:
                                      (v) => v!.length != 6 ? "Invalid" : null,
                                ),
                            SizedBox(height: 12),
                            isNumberLenthIsTen && !isNumberVarified
                                ? SizedBox(
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
                                    onPressed:
                                        () => _phoneNoVarification(isVendor),
                                    child:
                                        isLoading1
                                            ? SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                            : otpId.isEmpty
                                            ? Text(
                                              "Send OTP",
                                              style: TextStyle(
                                                fontSize:
                                                    isSmallScreen ? 16 : 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            )
                                            : Text(
                                              "Verify OTP",
                                              style: TextStyle(
                                                fontSize:
                                                    isSmallScreen ? 16 : 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                  ),
                                )
                                : SizedBox.shrink(),
                            isNumberLenthIsTen && !isNumberVarified
                                ? SizedBox(height: 12)
                                : SizedBox.shrink(),

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
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                              ),
                              validator:
                                  (v) =>
                                      v!.length < 6 ? "Min 6 characters" : null,
                            ),
                            SizedBox(height: 12),

                            if (isVendor)
                              _buildDropdown(
                                value: _selectedProfession,
                                items: _professions,
                                hint: "Select profession",
                                onChanged:
                                    (v) =>
                                        setState(() => _selectedProfession = v),
                                validator: (v) => v == null ? "Required" : null,
                              ),
                            if (isVendor) SizedBox(height: 12),

                            _buildDropdown(
                              value: _selectedGender,
                              items: _gender,
                              hint: "Select gender",
                              onChanged:
                                  (v) => setState(() => _selectedGender = v),
                              validator: (v) => v == null ? "Required" : null,
                            ),
                            SizedBox(height: 12),
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
                                            decoration:
                                                TextDecoration.underline,
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
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: isSmallScreen ? 16 : 20),
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
                                onPressed: () => _submitForm(isVendor),
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

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Have an account? "),
                                TextButton(
                                  onPressed:
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => LoginPage(),
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
                      );
                    },
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

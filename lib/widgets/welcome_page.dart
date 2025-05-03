// this file is made responsive.

import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/widgets/login_page.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  Future<void> _navigateToLogin(BuildContext context, bool isVendorMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isVendor", isVendorMode);
    isVendor.value = isVendorMode;

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 375;
    final buttonWidth = screenSize.width * 0.8;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenSize.height),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 20.0 : 32.0),
                child: ValueListenableBuilder<bool>(
                  valueListenable: isVendor,
                  builder: (context, _, __) {
                    return ValueListenableBuilder(
                      valueListenable: isDarkThemeNotifier,
                      builder: (context, value, child) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Aapkakaam',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 32.0 : 38.0,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDarkThemeNotifier.value
                                        ? Colors.white30
                                        : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Lottie.asset(
                              'assets/lotties/welcome.json',
                              height: isSmallScreen ? 200 : 250,
                              width: isSmallScreen ? 200 : 250,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: buttonWidth,
                              child: _buildAuthButton(
                                context: context,
                                label: 'Continue as User',
                                isVendor: false,
                                isSmallScreen: isSmallScreen,
                                onPressed:
                                    () => _navigateToLogin(context, false),
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 12 : 16),
                            SizedBox(
                              width: buttonWidth,
                              child: _buildAuthButton(
                                context: context,
                                label: 'Continue as Vendor',
                                isVendor: true,
                                isSmallScreen: isSmallScreen,
                                onPressed:
                                    () => _navigateToLogin(context, true),
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 24 : 32),
                            Text(
                              'Select your account type',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthButton({
    required BuildContext context,
    required String label,
    required bool isVendor,
    required bool isSmallScreen,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isVendor ? Colors.blue : Colors.teal,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 14 : 16,
          horizontal: 24,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          fontSize: isSmallScreen ? 16 : 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

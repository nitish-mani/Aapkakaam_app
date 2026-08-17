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
      MaterialPageRoute(
        builder:
            (context) => LoginPage(category: isVendorMode ? 'vendor' : 'user'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 375;
    final buttonWidth = screenSize.width * 0.8;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal.shade700,
              Colors.teal.shade500,
              Colors.teal.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    screenSize.height - MediaQuery.of(context).padding.top,
              ),
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
                              const SizedBox(height: 24),
                              // Lottie Animation with Logo Overlay
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Lottie Animation
                                    Lottie.asset(
                                      'assets/lotties/welcome.json',
                                      height: isSmallScreen ? 200 : 280,
                                      width: isSmallScreen ? 200 : 280,
                                      fit: BoxFit.contain,
                                    ),
                                    // Logo Overlay with Gradient Background
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.teal.shade700,
                                            Colors.teal.shade500,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.teal.withOpacity(0.4),
                                            blurRadius: 20,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Image.asset(
                                          'assets/images/aapkakaam_aa.jpg',
                                          height: isSmallScreen ? 40 : 60,
                                          width: isSmallScreen ? 40 : 60,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                              // Welcome Text
                              Text(
                                'Welcome to Aapkakaam',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 20 : 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Find the best services near you',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  color: Colors.white.withOpacity(0.85),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 32),
                              // User Button
                              SizedBox(
                                width: buttonWidth,
                                child: _buildAuthButton(
                                  context: context,
                                  label: 'Continue as User',
                                  isVendor: false,
                                  isSmallScreen: isSmallScreen,
                                  icon: Icons.person_outline,
                                  onPressed:
                                      () => _navigateToLogin(context, false),
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 12 : 16),
                              // Vendor Button
                              SizedBox(
                                width: buttonWidth,
                                child: _buildAuthButton(
                                  context: context,
                                  label: 'Continue as Vendor',
                                  isVendor: true,
                                  isSmallScreen: isSmallScreen,
                                  icon: Icons.business_outlined,
                                  onPressed:
                                      () => _navigateToLogin(context, true),
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 24 : 32),
                              // Footer Text
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Select your account type to continue',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    color: Colors.white.withOpacity(0.7),
                                    letterSpacing: 0.3,
                                  ),
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
      ),
    );
  }

  Widget _buildAuthButton({
    required BuildContext context,
    required String label,
    required bool isVendor,
    required bool isSmallScreen,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isVendor ? Colors.blue.shade600 : Colors.green.shade600,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 14 : 16,
          horizontal: 24,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 3,
        shadowColor:
            isVendor
                ? Colors.blue.withOpacity(0.3)
                : Colors.green.withOpacity(0.3),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: isSmallScreen ? 20 : 24),
      label: Text(
        label,
        style: TextStyle(
          fontSize: isSmallScreen ? 16 : 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

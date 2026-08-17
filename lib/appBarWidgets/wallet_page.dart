// this file is made responsive for all devices.

import 'dart:convert';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/models/data_model.dart';
import 'package:app_aapkakaam/navBarWidgets/home_page.dart';
import 'package:app_aapkakaam/widgets/payment_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  UserModel? _user;
  VendorModel? _vendor;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (isVendor.value) {
        final vendorData = prefs.getString("vendor");
        if (vendorData != null) {
          setState(
            () => _vendor = VendorModel.fromJson(jsonDecode(vendorData)),
          );
        }
      } else {
        final userData = prefs.getString("user");
        if (userData != null) {
          setState(() => _user = UserModel.fromJson(jsonDecode(userData)));
        }
      }
    } catch (e) {
      debugPrint("Error loading wallet data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    // final isPortrait = mediaQuery.orientation == Orientation.portrait;

    return ValueListenableBuilder<bool>(
      valueListenable: isDarkThemeNotifier,
      builder: (context, isDarkTheme, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: isVendor,
          builder: (context, isVendor, _) {
            final balance = isVendor ? _vendor?.balance : _user?.balance;
            final bgColor = isDarkTheme ? Colors.teal[800] : Colors.amber[200];
            final textColor = isDarkTheme ? Colors.white : Colors.black;

            return Scaffold(
              backgroundColor: bgColor,
              appBar: AppBar(
                elevation: 0,
                title: Text(
                  "Wallet",
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
              body:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.all(mediaQuery.size.width * 0.05),
                          child: Column(
                            children: [
                              WalletCard(
                                label: "Balance",
                                amount: "₹ ${balance?.toStringAsFixed(2) ?? 0}",
                                isDark: isDarkTheme,
                                mediaQuery: mediaQuery,
                              ),

                              SizedBox(height: mediaQuery.size.height * 0.05),
                              _buildActionButton(
                                context,
                                "Add Balance",
                                Icons.add_circle_outline,
                                isDarkTheme
                                    ? Colors.tealAccent[700]
                                    : Colors.amber[400],
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PaymentPage(),
                                  ),
                                ),
                                mediaQuery,
                              ),
                              SizedBox(height: mediaQuery.size.height * 0.03),
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

  Widget _buildActionButton(
    BuildContext context,
    String text,
    IconData icon,
    Color? backgroundColor,
    VoidCallback onPressed,
    MediaQueryData mediaQuery,
  ) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.black,
        padding: EdgeInsets.symmetric(
          horizontal: mediaQuery.size.width * 0.1,
          vertical: mediaQuery.size.height * 0.02,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: Size(
          mediaQuery.size.width * 0.8,
          mediaQuery.size.height * 0.07,
        ),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: mediaQuery.size.width * 0.06),
      label: Text(
        text,
        style: TextStyle(
          fontSize: mediaQuery.size.width * 0.04,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class WalletCard extends StatelessWidget {
  final String label;
  final String amount;
  final bool isDark;
  final MediaQueryData mediaQuery;

  const WalletCard({
    super.key,
    required this.label,
    required this.amount,
    required this.isDark,
    required this.mediaQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? Colors.grey[850] : Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: mediaQuery.size.height * 0.03,
          horizontal: mediaQuery.size.width * 0.05,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: mediaQuery.size.width * 0.05,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                fontSize: mediaQuery.size.width * 0.055,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

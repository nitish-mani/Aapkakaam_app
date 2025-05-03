// this file is made responsive for all devices.

import 'dart:convert';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/models/data_model.dart';
import 'package:app_aapkakaam/widgets/address_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  UserModel? _user;
  VendorModel? _vendor;
  bool _isLoading = false;

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
      debugPrint("Error loading user data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAddressUpdate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddAddressDialog()),
    );

    if (result == true) {
      await _loadUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    // final isPortrait = mediaQuery.orientation == Orientation.portrait;

    return ValueListenableBuilder<bool>(
      valueListenable: isDarkThemeNotifier,
      builder: (context, isDarkTheme, _) {
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text(
              "Location",
              style: TextStyle(
                color: isDarkTheme ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: mediaQuery.size.width * 0.06,
              ),
            ),
          ),
          body:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                    padding: EdgeInsets.all(mediaQuery.size.width * 0.05),
                    decoration: BoxDecoration(
                      color: isDarkTheme ? Colors.teal[100] : Colors.amber[100],
                    ),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLocationCard(isDarkTheme, mediaQuery),
                            SizedBox(height: mediaQuery.size.height * 0.03),
                            _buildUpdateButton(isDarkTheme, mediaQuery),
                          ],
                        ),
                      ),
                    ),
                  ),
        );
      },
    );
  }

  Widget _buildLocationCard(bool isDarkTheme, MediaQueryData mediaQuery) {
    final address =
        isVendor.value
            ? _vendor?.address.firstOrNull
            : _user?.address.firstOrNull;
    final post = address?.post ?? "Not Available";
    final pincode = address?.pincode ?? "-----";

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkTheme ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: mediaQuery.size.width * 0.04,
        vertical: mediaQuery.size.height * 0.03,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Location:',
            style: TextStyle(
              fontSize: mediaQuery.size.width * 0.045,
              fontWeight: FontWeight.bold,
              color: isDarkTheme ? Colors.white : Colors.black,
            ),
          ),
          Flexible(
            child: Text(
              '$post ($pincode)',
              style: TextStyle(
                fontSize: mediaQuery.size.width * 0.04,
                fontWeight: FontWeight.bold,
                color: isDarkTheme ? Colors.blue[200] : Colors.red[700],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateButton(bool isDarkTheme, MediaQueryData mediaQuery) {
    return ElevatedButton(
      onPressed: _handleAddressUpdate,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDarkTheme ? Colors.teal[400] : Colors.amber[600],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: Size(
          mediaQuery.size.width * 0.8,
          mediaQuery.size.height * 0.06,
        ),
        padding: EdgeInsets.symmetric(vertical: mediaQuery.size.height * 0.02),
      ),
      child: Text(
        'Add / Update Address',
        style: TextStyle(
          fontSize: mediaQuery.size.width * 0.045,
          fontWeight: FontWeight.bold,
          color: isDarkTheme ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}

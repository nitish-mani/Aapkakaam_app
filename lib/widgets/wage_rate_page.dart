// this file is made responsive.

import 'dart:convert';
import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/models/data_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WageRatePage extends StatelessWidget {
  const WageRatePage({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWageRateDialog(context);
    });

    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.shrink(),
    );
  }

  Future<void> _showWageRateDialog(BuildContext context) async {
    final wageRateController = TextEditingController();
    bool isLoading = false;
    String? selectedWageRateType;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> updateWageRate() async {
              final wageRateText = wageRateController.text.trim();

              if (wageRateText.isEmpty ||
                  double.tryParse(wageRateText) == null) {
                _showErrorSnackbar(context, "Please enter a valid wage rate");
                return;
              }

              setState(() => isLoading = true);

              try {
                final prefs = await SharedPreferences.getInstance();
                final vendorJson = prefs.getString('vendor');

                if (vendorJson == null) throw Exception("Vendor not logged in");

                final decoded = jsonDecode(vendorJson);
                final token = decoded["token"];
                final vendorId = decoded["vendorId"];
                if (selectedWageRateType == null) {
                  _showErrorSnackbar(context, "Please select wage rate type");
                  setState(() => isLoading = false);
                  return;
                }
                final url = Uri.parse("${KConstantURL.url}/vendor/wageRate");

                final response = await http.patch(
                  url,
                  headers: {
                    "Authorization": "Bearer $token",
                    "Content-Type": "application/json",
                  },

                  body: jsonEncode({
                    "wageRate": int.parse(wageRateText),
                    "wageRateType": selectedWageRateType,
                    "vendorId": vendorId,
                  }),
                );

                if (response.statusCode == 200) {
                  final result = jsonDecode(response.body);

                  await _updateVendorWageRate(decoded, result);

                  isWageRateAvailable.value = true;
                  Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pop(); // close dialog
                  Navigator.pop(context, true);

                  _showSuccessSnackbar(
                    context,
                    "Wage rate updated successfully",
                  );
                } else {
                  throw Exception("Failed to update wage rate");
                }
              } catch (e) {
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).pop(); // close dialog

                Navigator.pop(context, false);
                _showErrorSnackbar(context, "Something went wrong");
              } finally {
                setState(() => isLoading = false);
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: isDark ? Colors.grey[900] : Colors.white,
              elevation: 8,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.06,
                  vertical: screenWidth * 0.06,
                ),
                width: screenWidth * 0.85,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon Header
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.attach_money,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Title
                    Text(
                      "Update Wage Rate",
                      style: TextStyle(
                        fontSize: screenWidth * 0.055,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.grey[900],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Set your rate per service",
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Wage Rate Input
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: wageRateController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.currency_rupee,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            size: 22,
                          ),
                          hintText: "Enter amount",
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                            fontSize: screenWidth * 0.04,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Wage Rate Type Dropdown
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                          width: 1.5,
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedWageRateType,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.timer_outlined,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            size: 22,
                          ),
                          hintText: "Select rate type",
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                            fontSize: screenWidth * 0.04,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                        ),
                        dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: "Day",
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 18),
                                SizedBox(width: 8),
                                Text("Per Day"),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: "Hour",
                            child: Row(
                              children: [
                                Icon(Icons.access_time, size: 18),
                                SizedBox(width: 8),
                                Text("Per Hour"),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: "Km",
                            child: Row(
                              children: [
                                Icon(Icons.directions_car, size: 18),
                                SizedBox(width: 8),
                                Text("Per Km"),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: "1k People",
                            child: Row(
                              children: [
                                Icon(Icons.people_outline, size: 18),
                                SizedBox(width: 8),
                                Text("Per 1k People"),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: "Service",
                            child: Row(
                              children: [
                                Icon(Icons.build_circle_outlined, size: 18),
                                SizedBox(width: 8),
                                Text("Per Service"),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: "Other",
                            child: Row(
                              children: [
                                Icon(Icons.accessibility_new, size: 18),
                                SizedBox(width: 8),
                                Text("Other"),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedWageRateType = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color:
                                      isDark
                                          ? Colors.grey[700]!
                                          : Colors.grey[300]!,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context, rootNavigator: true).pop();
                              Navigator.pop(context);
                            },
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              shadowColor: Colors.green.withOpacity(0.3),
                            ),
                            onPressed: isLoading ? null : updateWageRate,
                            child:
                                isLoading
                                    ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                    : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.check_circle_outline,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Confirm",
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.04,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateVendorWageRate(
    Map<String, dynamic> decoded,
    Map<String, dynamic> responseJson,
  ) async {
    // Get current vendor data
    final prefs = await SharedPreferences.getInstance();
    final vendorJson = prefs.getString('vendor');
    if (vendorJson == null) return;

    final currentVendor = jsonDecode(vendorJson);

    // Create updated vendor with proper types
    final updatedVendor = {
      ...currentVendor,
      'wageRate': (responseJson['wageRate'] as num).toDouble(),
      'wageRateType': responseJson['wageRateType'] ?? '',
      'message': responseJson['message'] ?? currentVendor['message'] ?? '',
    };

    // Save updated vendor data
    await prefs.setString('vendor', jsonEncode(updatedVendor));

    // Update the VendorModel in memory if needed
    // This will be picked up when the profile page reloads
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Center(
          child: Text(message, style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Center(
          child: Text(message, style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}

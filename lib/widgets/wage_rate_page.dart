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

                final url = Uri.parse("${KConstantURL.url}/vendor/wageRate");

                final response = await http.patch(
                  url,
                  headers: {
                    "Authorization": "Bearer $token",
                    "Content-Type": "application/json",
                  },
                  body: jsonEncode({
                    "wageRate": int.parse(wageRateText),
                    "vendorId": vendorId,
                  }),
                );

                if (response.statusCode == 200) {
                  final result = jsonDecode(response.body);

                  VendorModel currentVendor = VendorModel.fromJson(decoded);
                  await _updateVendorWageRate(currentVendor, result);

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

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: isDark ? Colors.grey[900] : Colors.white,
              title: Text(
                "Update Wage Rate",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: screenWidth * 0.8,
                child: TextField(
                  controller: wageRateController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: screenWidth * 0.04),
                  decoration: InputDecoration(
                    labelText: "Enter new wage rate",
                    labelStyle: TextStyle(fontSize: screenWidth * 0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    textStyle: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed:
                      () => {
                        Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pop(), // close dialog
                        Navigator.pop(context),
                      },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: isLoading ? null : updateWageRate,
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            "Confirm",
                            style: TextStyle(color: Colors.black),
                          ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateVendorWageRate(
    VendorModel vendor,
    Map<String, dynamic> responseJson,
  ) async {
    int updatedWageRate = (responseJson['wageRate'] as num).toInt();

    VendorModel updatedVendor = VendorModel(
      token: vendor.token,
      vendorId: vendor.vendorId,
      name: vendor.name,
      email: vendor.email,
      verifyEmail: vendor.verifyEmail,
      phoneNo: vendor.phoneNo,
      verifyPhoneNo: vendor.verifyPhoneNo,
      type: vendor.type,
      gender: vendor.gender,
      rating: vendor.rating,
      ratingCount: vendor.ratingCount,
      wageRate: updatedWageRate,
      address: vendor.address,
      balance: vendor.balance,
      bonusAmount: vendor.bonusAmount,
      imgURL: vendor.imgURL,
      message: responseJson['message'] ?? vendor.message,
    );

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('vendor', jsonEncode(updatedVendor.toJson()));
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

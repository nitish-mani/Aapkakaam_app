// this file is made responsive for all devices.

import 'dart:convert';
import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/models/data_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddAddressDialog extends StatefulWidget {
  const AddAddressDialog({super.key});

  @override
  State<AddAddressDialog> createState() => _AddAddressDialogState();
}

class _AddAddressDialogState extends State<AddAddressDialog> {
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final FocusNode _pincodeFocusNode = FocusNode();

  String _errorMessage = '';
  bool _isLoading = false;
  List<String> _postOffices = [];
  String? _selectedPost;

  // Language helper
  String _t(String en, String hi) => isHindiNotifier.value ? hi : en;

  @override
  void dispose() {
    _villageController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _pincodeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchAddressByPincode(String pincode) async {
    if (pincode.length != 6) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final isVendor1 = isVendor.value;
      final category = isVendor1 ? 'vendor' : 'user';
      final categoryData = prefs.getString(category);

      if (categoryData == null) {
        setState(
          () =>
              _errorMessage = _t(
                'User data not found',
                'उपयोगकर्ता डेटा नहीं मिला',
              ),
        );
        return;
      }

      final decoded = jsonDecode(categoryData);
      final response = await http
          .post(
            Uri.parse(
              '${KConstantURL.url}/pincode/${category == 'user' ? 'getU' : 'getV'}',
            ),
            headers: {
              "Authorization": 'Bearer ${decoded['token']}',
              "Content-Type": "application/json",
            },
            body: jsonEncode({'pincode': pincode}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body)['data'];
        final offices = result['offices'] ?? [];

        final cleanedOffices = List<Map<String, dynamic>>.from(
          offices.map((office) {
            final name =
                office['officename']
                    ?.replaceAll(RegExp(r'\s(BO|SO|HO)$'), '')
                    ?.toUpperCase();
            return {'Name': name, 'original': office};
          }),
        );

        final allOffices = [
          {'Name': _t('Select Post Office', 'पोस्ट ऑफिस चुनें')},
          ...cleanedOffices,
        ];

        setState(() {
          _districtController.text = offices[0]?['district'] ?? '';
          _stateController.text = offices[0]?['statename'] ?? '';
          _postOffices = allOffices.map((e) => e['Name'] as String).toList();
          _selectedPost = _postOffices.isNotEmpty ? _postOffices.first : null;
        });
      } else {
        setState(() {
          _errorMessage = _t('Enter Valid Pincode', 'सही पिनकोड डालें');
          _districtController.clear();
          _stateController.clear();
          _postOffices.clear();
        });
      }
    } catch (e) {
      setState(
        () =>
            _errorMessage =
                _t('Network error: ', 'नेटवर्क त्रुटि: ') + e.toString(),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitAddress() async {
    final village = _villageController.text.trim();
    final pincode = _pincodeController.text.trim();
    final post = _selectedPost ?? '';
    final district = _districtController.text.trim();
    final state = _stateController.text.trim();

    if (village.isEmpty ||
        pincode.isEmpty ||
        post.isEmpty ||
        district.isEmpty ||
        state.isEmpty) {
      setState(
        () =>
            _errorMessage = _t(
              'Please fill all fields correctly',
              'कृपया सभी फील्ड सही भरें',
            ),
      );
      return;
    }

    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final isVendor1 = isVendor.value;
      final category = isVendor1 ? 'vendor' : 'user';
      final categoryData = prefs.getString(category);

      if (categoryData == null) {
        setState(
          () =>
              _errorMessage = _t(
                'User data not found',
                'उपयोगकर्ता डेटा नहीं मिला',
              ),
        );
        return;
      }

      final decoded = jsonDecode(categoryData);
      final url = Uri.parse("${KConstantURL.url}/$category/update/address");

      final body = {
        "vill": village.toUpperCase(),
        "post": post,
        "dist": district,
        "state": state,
        "pincode": pincode,
        if (category == "user") "userId": decoded['userId'],
        if (category == "vendor") "vendorId": decoded['vendorId'],
      };

      final response = await http
          .patch(
            url,
            headers: {
              "Authorization": 'Bearer ${decoded['token']}',
              "Content-Type": "application/json",
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        isAddressAvailable.value = true;

        if (isVendor1) {
          await _updateVendorAddress(prefs, decoded, result);
        } else {
          await _updateUserAddress(prefs, decoded, result);
        }

        Navigator.pop(context, true);
        _showSuccessSnackbar(context);
      } else {
        setState(
          () =>
              _errorMessage = _t(
                'Failed to update address',
                'पता अपडेट करने में विफल',
              ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = _t('Error: ', 'त्रुटि: ') + e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateVendorAddress(
    SharedPreferences prefs,
    Map<String, dynamic> decoded,
    Map<String, dynamic> result,
  ) async {
    final vendor = VendorModel.fromJson(decoded);
    final updatedAddress =
        (result['address'] as List).map((e) => Address.fromJson(e)).toList();

    final updatedVendor = VendorModel(
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
      wageRate: vendor.wageRate,
      address: updatedAddress,
      balance: vendor.balance,
      wageRateType: vendor.wageRateType,
      transactionCount: vendor.transactionCount,
      totalDiscount: vendor.totalDiscount,
      totalOriginalAmount: vendor.totalOriginalAmount,
      pending: vendor.pending,
      completed: vendor.completed,
      canceled: vendor.canceled,
      pincode: vendor.pincode,
      earning: vendor.earning,
      message: result['message'] ?? vendor.message,
    );

    await prefs.setString('vendor', jsonEncode(updatedVendor.toJson()));
  }

  Future<void> _updateUserAddress(
    SharedPreferences prefs,
    Map<String, dynamic> decoded,
    Map<String, dynamic> result,
  ) async {
    final user = UserModel.fromJson(decoded);
    final updatedAddress =
        (result['address'] as List).map((e) => Address.fromJson(e)).toList();

    final updatedUser = UserModel(
      token: user.token,
      userId: user.userId,
      name: user.name,
      email: user.email,
      verifyEmail: user.verifyEmail,
      phoneNo: user.phoneNo,
      verifyPhoneNo: user.verifyPhoneNo,
      gender: user.gender,
      address: updatedAddress,
      balance: user.balance,
      transactionCount: user.transactionCount,
      totalDiscount: user.totalDiscount,
      totalOriginalAmount: user.totalOriginalAmount,
      pending: user.pending,
      completed: user.completed,
      canceled: user.canceled,
      pincode: user.pincode,
      message: result['message'] ?? user.message,
    );

    await prefs.setString('user', jsonEncode(updatedUser.toJson()));
  }

  void _showSuccessSnackbar(BuildContext context) {
    final message = _t(
      'Address updated successfully',
      'पता सफलतापूर्वक अपडेट किया गया',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        content: Center(
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final surface = colorScheme.surface;
    final onSurface = colorScheme.onSurface;
    final onSurfaceVariant = colorScheme.onSurfaceVariant;

    final screenWidth = mediaQuery.size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<bool>(
      valueListenable: isHindiNotifier,
      builder: (context, isHindi, _) {
        return Dialog(
          insetPadding: EdgeInsets.all(screenWidth * 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: isDark ? const Color(0xFF1A1A2E) : surface,
          elevation: 8,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.06),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header with Icon
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, primaryColor.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.location_on_outlined,
                        color: colorScheme.onPrimary,
                        size: 30,
                      ),
                    ),
                  ),
                  SizedBox(height: mediaQuery.size.height * 0.02),

                  // Title
                  Text(
                    _t('Add Address', 'पता जोड़ें'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: screenWidth * 0.055,
                      color: isDark ? Colors.white : onSurface,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: mediaQuery.size.height * 0.005),

                  Text(
                    _t(
                      'Enter your location details',
                      'अपना स्थान विवरण दर्ज करें',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: isDark ? Colors.grey[400] : onSurfaceVariant,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: mediaQuery.size.height * 0.025),

                  // Error Message
                  if (_errorMessage.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.03),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_errorMessage.isNotEmpty)
                    SizedBox(height: mediaQuery.size.height * 0.02),

                  // Village Field
                  _buildTextField(
                    _t('Village', 'गाँव'),
                    _villageController,
                    mediaQuery,
                    icon: Icons.house_outlined,
                    primaryColor: primaryColor,
                    isDark: isDark,
                  ),
                  SizedBox(height: mediaQuery.size.height * 0.015),

                  // Pincode Field
                  _buildPincodeField(mediaQuery, primaryColor, isDark),
                  SizedBox(height: mediaQuery.size.height * 0.015),

                  // Post Office Dropdown
                  _buildPostDropdown(mediaQuery, primaryColor, isDark),
                  SizedBox(height: mediaQuery.size.height * 0.015),

                  // District Field (Read-only)
                  _buildTextField(
                    _t('District', 'जिला'),
                    _districtController,
                    mediaQuery,
                    readOnly: true,
                    icon: Icons.location_city_outlined,
                    primaryColor: primaryColor,
                    isDark: isDark,
                  ),
                  SizedBox(height: mediaQuery.size.height * 0.015),

                  // State Field (Read-only)
                  _buildTextField(
                    _t('State', 'राज्य'),
                    _stateController,
                    mediaQuery,
                    readOnly: true,
                    icon: Icons.map_outlined,
                    primaryColor: primaryColor,
                    isDark: isDark,
                  ),
                  SizedBox(height: mediaQuery.size.height * 0.025),

                  // Action Buttons
                  _buildActionButtons(
                    context,
                    mediaQuery,
                    primaryColor,
                    isDark,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    MediaQueryData mediaQuery, {
    bool readOnly = false,
    IconData? icon,
    required Color primaryColor,
    required bool isDark,
  }) {
    final screenWidth = mediaQuery.size.width;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252540) : const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE8ECF3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        style: TextStyle(
          fontSize: screenWidth * 0.04,
          color: isDark ? Colors.white : const Color(0xFF172033),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
            fontSize: screenWidth * 0.035,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon:
              icon != null
                  ? Icon(
                    icon,
                    color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                    size: 22,
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: mediaQuery.size.height * 0.018,
          ),
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
        cursorColor: primaryColor,
      ),
    );
  }

  Widget _buildPincodeField(
    MediaQueryData mediaQuery,
    Color primaryColor,
    bool isDark,
  ) {
    final screenWidth = mediaQuery.size.width;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252540) : const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE8ECF3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _pincodeController,
        focusNode: _pincodeFocusNode,
        keyboardType: TextInputType.number,
        maxLength: 6,
        style: TextStyle(
          fontSize: screenWidth * 0.04,
          color: isDark ? Colors.white : const Color(0xFF172033),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: _t('Pincode', 'पिनकोड'),
          labelStyle: TextStyle(
            color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
            fontSize: screenWidth * 0.035,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            Icons.pin_drop_outlined,
            color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
            size: 22,
          ),
          counterText: '',
          suffixIcon:
              _isLoading
                  ? Padding(
                    padding: EdgeInsets.all(screenWidth * 0.02),
                    child: SizedBox(
                      width: screenWidth * 0.05,
                      height: screenWidth * 0.05,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: primaryColor,
                      ),
                    ),
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: mediaQuery.size.height * 0.018,
          ),
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
        cursorColor: primaryColor,
        onChanged: (value) {
          if (value.length == 6) {
            _fetchAddressByPincode(value);
          }
        },
      ),
    );
  }

  Widget _buildPostDropdown(
    MediaQueryData mediaQuery,
    Color primaryColor,
    bool isDark,
  ) {
    final screenWidth = mediaQuery.size.width;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252540) : const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE8ECF3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedPost,
        dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        style: TextStyle(
          fontSize: screenWidth * 0.04,
          color: isDark ? Colors.white : const Color(0xFF172033),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: _t('Post Office', 'पोस्ट ऑफिस'),
          labelStyle: TextStyle(
            color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
            fontSize: screenWidth * 0.035,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            Icons.local_post_office_outlined,
            color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: mediaQuery.size.height * 0.01,
          ),
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
        ),
        items:
            _postOffices
                .map(
                  (post) => DropdownMenuItem(
                    value: post,
                    child: Text(
                      post,
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: isDark ? Colors.white : const Color(0xFF172033),
                      ),
                    ),
                  ),
                )
                .toList(),
        onChanged: (value) => setState(() => _selectedPost = value),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    MediaQueryData mediaQuery,
    Color primaryColor,
    bool isDark,
  ) {
    final screenWidth = mediaQuery.size.width;

    return Row(
      children: [
        Expanded(
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: isDark ? Colors.grey[400] : Colors.grey[700],
              padding: EdgeInsets.symmetric(
                vertical: mediaQuery.size.height * 0.018,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color:
                      isDark
                          ? Colors.white.withOpacity(0.1)
                          : const Color(0xFFE8ECF3),
                  width: 1.5,
                ),
              ),
            ),
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: Text(
              _t('Cancel', 'रद्द करें'),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: screenWidth * 0.04,
                color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
              ),
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.03),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitAddress,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                vertical: mediaQuery.size.height * 0.018,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
              shadowColor: primaryColor.withOpacity(0.3),
            ),
            child:
                _isLoading
                    ? SizedBox(
                      width: screenWidth * 0.05,
                      height: screenWidth * 0.05,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _t('Submit', 'सबमिट करें'),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: screenWidth * 0.04,
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ],
    );
  }
}

// this file is made responsive for all devices.

import 'dart:convert';
import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/models/data_model.dart';
import 'package:app_aapkakaam/widgets/banner_ad_widget.dart';
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
        setState(() => _errorMessage = 'User data not found');
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
        print(result);
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
          {'Name': 'Select Post Office'},
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
          _errorMessage = 'Enter Valid Pincode';
          _districtController.clear();
          _stateController.clear();
          _postOffices.clear();
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Network error: ${e.toString()}');
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
      setState(() => _errorMessage = 'Please fill all fields correctly');
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
        setState(() => _errorMessage = 'User data not found');
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
        setState(() => _errorMessage = "Failed to update address");
      }
    } catch (e) {
      setState(() => _errorMessage = "Error: ${e.toString()}");
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: const Center(
          child: Text(
            "Address updated successfully",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isDark = Theme.of(context).brightness != Brightness.dark;
    final screenWidth = mediaQuery.size.width;

    return Dialog(
      insetPadding: EdgeInsets.all(screenWidth * 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              SizedBox(height: mediaQuery.size.height * 0.02),
              // Title
              Text(
                'Add Address',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: screenWidth * 0.055,
                  color: isDark ? Colors.white : Colors.grey[900],
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: mediaQuery.size.height * 0.01),
              Text(
                'Enter your location details',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: mediaQuery.size.height * 0.025),
              // Error Message
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 20),
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
                'Village',
                _villageController,
                mediaQuery,
                icon: Icons.house_outlined,
              ),
              SizedBox(height: mediaQuery.size.height * 0.02),
              // Pincode Field
              _buildPincodeField(mediaQuery),
              SizedBox(height: mediaQuery.size.height * 0.02),
              // Post Office Dropdown
              _buildPostDropdown(mediaQuery),
              SizedBox(height: mediaQuery.size.height * 0.02),
              // District Field (Read-only)
              _buildTextField(
                'District',
                _districtController,
                mediaQuery,
                readOnly: true,
                icon: Icons.location_city_outlined,
              ),
              SizedBox(height: mediaQuery.size.height * 0.02),
              // State Field (Read-only)
              _buildTextField(
                'State',
                _stateController,
                mediaQuery,
                readOnly: true,
                icon: Icons.map_outlined,
              ),
              SizedBox(height: mediaQuery.size.height * 0.025),
              // Action Buttons
              _buildActionButtons(context, mediaQuery),
              SizedBox(height: mediaQuery.size.height * 0.025),
              // Ad Banner
              Center(child: BannerAdWidget()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    MediaQueryData mediaQuery, {
    bool readOnly = false,
    IconData? icon,
  }) {
    final isDark = Theme.of(context).brightness != Brightness.dark;
    final screenWidth = mediaQuery.size.width;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        style: TextStyle(
          fontSize: screenWidth * 0.04,
          color: isDark ? Colors.white : Colors.grey[900],
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: screenWidth * 0.035,
          ),
          prefixIcon:
              icon != null
                  ? Icon(
                    icon,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    size: 22,
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: mediaQuery.size.height * 0.018,
          ),
        ),
      ),
    );
  }

  Widget _buildPincodeField(MediaQueryData mediaQuery) {
    final isDark = Theme.of(context).brightness != Brightness.dark;
    final screenWidth = mediaQuery.size.width;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: _pincodeController,
        focusNode: _pincodeFocusNode,
        keyboardType: TextInputType.number,
        maxLength: 6,
        style: TextStyle(
          fontSize: screenWidth * 0.04,
          color: isDark ? Colors.white : Colors.grey[900],
        ),
        decoration: InputDecoration(
          labelText: 'Pincode',
          labelStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: screenWidth * 0.035,
          ),
          prefixIcon: Icon(
            Icons.pin_drop_outlined,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                        color: Colors.blue,
                      ),
                    ),
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: mediaQuery.size.height * 0.018,
          ),
        ),
        onChanged: (value) {
          if (value.length == 6) {
            _fetchAddressByPincode(value);
          }
        },
      ),
    );
  }

  Widget _buildPostDropdown(MediaQueryData mediaQuery) {
    final isDark = Theme.of(context).brightness != Brightness.dark;
    final screenWidth = mediaQuery.size.width;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedPost,
        dropdownColor: isDark ? Colors.grey[800] : Colors.white,
        style: TextStyle(
          fontSize: screenWidth * 0.04,
          color: isDark ? Colors.white : Colors.grey[900],
        ),
        decoration: InputDecoration(
          labelText: 'Post Office',
          labelStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: screenWidth * 0.035,
          ),
          prefixIcon: Icon(
            Icons.local_post_office_outlined,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: mediaQuery.size.height * 0.01,
          ),
        ),
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        items:
            _postOffices
                .map(
                  (post) => DropdownMenuItem(
                    value: post,
                    child: Text(
                      post,
                      style: TextStyle(fontSize: screenWidth * 0.04),
                    ),
                  ),
                )
                .toList(),
        onChanged: (value) => setState(() => _selectedPost = value),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, MediaQueryData mediaQuery) {
    final isDark = Theme.of(context).brightness != Brightness.dark;
    final screenWidth = mediaQuery.size.width;

    return Row(
      children: [
        Expanded(
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
              padding: EdgeInsets.symmetric(
                vertical: mediaQuery.size.height * 0.018,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
            ),
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: screenWidth * 0.04,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.03),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitAddress,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                vertical: mediaQuery.size.height * 0.018,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              shadowColor: Colors.blue.withOpacity(0.3),
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
                          'Submit',
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

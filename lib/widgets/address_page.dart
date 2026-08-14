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
        "vill": _capitalizeFirstLetter(village),
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
      address: updatedAddress, // ✅ Updated address
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
      message: result['message'] ?? vendor.message, // ✅ Updated message
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
      address: updatedAddress, // ✅ Updated address
      balance: user.balance,
      transactionCount: user.transactionCount,
      totalDiscount: user.totalDiscount,
      totalOriginalAmount: user.totalOriginalAmount,
      pending: user.pending,
      completed: user.completed,
      canceled: user.canceled,
      pincode: user.pincode,
      message: result['message'] ?? user.message, // ✅ Updated message
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
    // final isPortrait = mediaQuery.orientation == Orientation.portrait;

    return Dialog(
      insetPadding: EdgeInsets.all(mediaQuery.size.width * 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(mediaQuery.size.width * 0.05),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Address',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: mediaQuery.size.width * 0.06,
                ),
              ),
              SizedBox(height: mediaQuery.size.height * 0.03),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: mediaQuery.size.height * 0.01),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: mediaQuery.size.width * 0.035,
                    ),
                  ),
                ),
              SizedBox(height: mediaQuery.size.height * 0.03),
              _buildTextField('Village', _villageController, mediaQuery),
              SizedBox(height: mediaQuery.size.height * 0.02),
              _buildPincodeField(mediaQuery),

              SizedBox(height: mediaQuery.size.height * 0.02),
              _buildPostDropdown(mediaQuery),
              SizedBox(height: mediaQuery.size.height * 0.02),
              _buildTextField(
                'District',
                _districtController,
                mediaQuery,
                readOnly: true,
              ),
              SizedBox(height: mediaQuery.size.height * 0.02),
              _buildTextField(
                'State',
                _stateController,
                mediaQuery,
                readOnly: true,
              ),
              SizedBox(height: mediaQuery.size.height * 0.03),
              _buildActionButtons(context, mediaQuery),
              SizedBox(height: mediaQuery.size.height * 0.03),

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
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: mediaQuery.size.width * 0.04,
          vertical: mediaQuery.size.height * 0.02,
        ),
      ),
      style: TextStyle(fontSize: mediaQuery.size.width * 0.04),
    );
  }

  Widget _buildPincodeField(MediaQueryData mediaQuery) {
    return TextField(
      controller: _pincodeController,
      focusNode: _pincodeFocusNode,
      keyboardType: TextInputType.number,
      maxLength: 6,
      decoration: InputDecoration(
        labelText: 'Pincode',
        border: const OutlineInputBorder(),
        counterText: '',
        suffixIcon:
            _isLoading
                ? Padding(
                  padding: EdgeInsets.all(mediaQuery.size.width * 0.03),
                  child: SizedBox(
                    width: mediaQuery.size.width * 0.04,
                    height: mediaQuery.size.width * 0.04,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
                : null,
        contentPadding: EdgeInsets.symmetric(
          horizontal: mediaQuery.size.width * 0.04,
          vertical: mediaQuery.size.height * 0.02,
        ),
      ),
      style: TextStyle(fontSize: mediaQuery.size.width * 0.04),
      onChanged: (value) {
        if (value.length == 6) {
          _fetchAddressByPincode(value);
        }
      },
    );
  }

  Widget _buildPostDropdown(MediaQueryData mediaQuery) {
    return DropdownButtonFormField<String>(
      value: _selectedPost,
      items:
          _postOffices
              .map(
                (post) => DropdownMenuItem(
                  value: post,
                  child: Text(
                    post,
                    style: TextStyle(fontSize: mediaQuery.size.width * 0.04),
                  ),
                ),
              )
              .toList(),
      onChanged: (value) => setState(() => _selectedPost = value),
      decoration: InputDecoration(
        labelText: 'Post Office',
        border: const OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: mediaQuery.size.width * 0.04,
          vertical: mediaQuery.size.height * 0.02,
        ),
      ),
      style: TextStyle(fontSize: mediaQuery.size.width * 0.04),
    );
  }

  Widget _buildActionButtons(BuildContext context, MediaQueryData mediaQuery) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: mediaQuery.size.width * 0.04,
            ),
          ),
        ),
        SizedBox(width: mediaQuery.size.width * 0.04),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitAddress,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: mediaQuery.size.width * 0.06,
              vertical: mediaQuery.size.height * 0.015,
            ),
          ),
          child:
              _isLoading
                  ? SizedBox(
                    width: mediaQuery.size.width * 0.05,
                    height: mediaQuery.size.width * 0.05,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                  : Text(
                    'Submit',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: mediaQuery.size.width * 0.04,
                      color: Colors.white,
                    ),
                  ),
        ),
      ],
    );
  }

  String _capitalizeFirstLetter(String str) {
    return str.isNotEmpty ? str[0].toUpperCase() + str.substring(1) : str;
  }
}

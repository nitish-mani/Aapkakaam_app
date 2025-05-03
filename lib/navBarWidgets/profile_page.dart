// this file is made responsive for all devices and screen sizes.

import 'dart:io';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/models/data_model.dart';
import 'package:app_aapkakaam/widgets/address_page.dart';
import 'package:app_aapkakaam/widgets/create_booking.dart';
import 'package:app_aapkakaam/widgets/image_uploader.dart';
import 'package:app_aapkakaam/widgets/payment_page.dart';
import 'package:app_aapkakaam/widgets/view_share.dart';
import 'package:app_aapkakaam/widgets/wage_rate_page.dart';
import 'package:app_aapkakaam/widgets/welcome_page.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserModel? user;
  VendorModel? vendor;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (isVendor.value) {
        await getVendorData();
      } else {
        await getUserData();
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> downloadAndSaveImage(String imageUrl, String fileName) async {
    if (imageUrl.isEmpty) return;

    try {
      // 1. Download image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) throw Exception('Image download failed');

      // 2. Get app directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';

      // 3. Delete previous image if it exists
      if (savedImagePath.value.isNotEmpty) {
        final oldFile = File(savedImagePath.value);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      }

      // 4. Save new image
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // 5. Update path (only if file exists)
      if (await file.exists()) {
        savedImagePath.value = filePath;
      }
    } catch (e) {
      debugPrint('Failed to save image: $e');
    }
  }

  Future<void> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString("user");

    if (userData != null && mounted) {
      try {
        setState(() {
          user = UserModel.fromJson(jsonDecode(userData));
        });

        if (user?.imgURL != null && user!.imgURL!.isNotEmpty) {
          await downloadAndSaveImage(
            user!.imgURL!,
            'user_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
        }
      } catch (e) {
        debugPrint('Error parsing user data: $e');
      }
    }
  }

  Future<void> getVendorData() async {
    final prefs = await SharedPreferences.getInstance();
    final vendorData = prefs.getString("vendor");

    if (vendorData != null && mounted) {
      try {
        setState(() {
          vendor = VendorModel.fromJson(jsonDecode(vendorData));
        });

        if (vendor?.imgURL != null && vendor!.imgURL!.isNotEmpty) {
          await downloadAndSaveImage(
            vendor!.imgURL!,
            'vendor_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
        }
      } catch (e) {
        debugPrint('Error parsing vendor data: $e');
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadData();
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Reset UI state
      selectedPageNotifier.value = 0;

      // Navigate back to Login Screen
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => WelcomePage()),
          (route) => false, // Clears navigation stack
        );
      }
    } catch (e) {
      debugPrint('Error during logout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final padding = mediaQuery.padding;
    final safeHeight = screenHeight - padding.top - padding.bottom;

    // Responsive size variables
    final avatarRadius = screenWidth * 0.1;
    final cardPadding = EdgeInsets.all(screenWidth * 0.03);

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ValueListenableBuilder(
          valueListenable: isDarkThemeNotifier,
          builder: (context, isDarkTheme, _) {
            return ValueListenableBuilder(
              valueListenable: isVendor,
              builder: (context, isVendorValue, _) {
                return ValueListenableBuilder(
                  valueListenable: isLoggedIn,
                  builder: (context, isLoggedIn, _) {
                    if (_isLoading) {
                      return SizedBox(
                        height: safeHeight * 0.77,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: !isDarkTheme ? Colors.teal : Colors.amber,
                          ),
                        ),
                      );
                    }

                    return ConstrainedBox(
                      constraints: BoxConstraints(minHeight: safeHeight * 0.77),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.02,
                            vertical: screenWidth * 0.02,
                          ),
                          child: Card(
                            elevation: 4,
                            color: isDarkTheme ? Colors.white : Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.025,
                              ),
                            ),
                            child: Padding(
                              padding: cardPadding,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildProfileHeader(
                                    isDarkTheme,
                                    isVendorValue,
                                    avatarRadius,
                                  ),
                                  SizedBox(height: screenHeight * 0.02),
                                  _buildProfileInfo(
                                    isDarkTheme,
                                    isVendorValue,
                                    screenWidth,
                                  ),
                                  SizedBox(height: screenHeight * 0.025),
                                  _buildActionButtons(
                                    isDarkTheme,
                                    isVendorValue,
                                    isLoggedIn,
                                    screenWidth,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    bool isDarkTheme,
    bool isVendorValue,
    double avatarRadius,
  ) {
    return Center(
      child: Column(
        children: [
          InkWell(
            child: CircleAvatar(
              radius: avatarRadius,
              backgroundColor: isDarkTheme ? Colors.teal : Colors.amber,
              backgroundImage:
                  savedImagePath.value.isNotEmpty
                      ? FileImage(File(savedImagePath.value))
                      : null,
              child:
                  savedImagePath.value.isEmpty
                      ? Icon(
                        Icons.person,
                        size: avatarRadius,
                        color: isDarkTheme ? Colors.white : Colors.black,
                      )
                      : null,
            ),
            onTap: () {
              if (savedImagePath.value.isNotEmpty) {
                showDialog(
                  context: context,
                  builder:
                      (context) => Dialog(
                        backgroundColor: Colors.white,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Image.file(
                                File(savedImagePath.value),
                                fit: BoxFit.contain,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                "Close",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                );
              }
            },
          ),
          SizedBox(height: avatarRadius * 0.2),
          Text(
            isVendorValue ? "Vendor" : "User",
            style: TextStyle(
              color: isDarkTheme ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: MediaQuery.of(context).size.width * 0.04,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(
    bool isDarkTheme,
    bool isVendorValue,
    double screenWidth,
  ) {
    final textSize = screenWidth * 0.038;
    final labelSize = screenWidth * 0.04;

    return Column(
      children: [
        _buildProfileRow(
          'Name',
          isVendorValue
              ? capitalizeWords(vendor?.name)
              : capitalizeWords(user?.name),
          isDarkTheme,
          labelSize,
          textSize,
        ),
        _buildProfileRow(
          'Mobile',
          isVendorValue ? vendor?.phoneNo.toString() : user?.phoneNo.toString(),
          isDarkTheme,
          labelSize,
          textSize,
        ),
        if (isVendorValue) ...[
          _buildRatingRow(isDarkTheme, screenWidth, labelSize),
          _buildProfileRow(
            'Wage Rate',
            vendor?.wageRate.toString() ?? 'N/A',
            isDarkTheme,
            labelSize,
            textSize,
          ),
        ],
        _buildFormattedAddress(
          isVendorValue
              ? _safeGetAddress(vendor?.address, 'vill')
              : _safeGetAddress(user?.address, 'vill'),
          isVendorValue
              ? _safeGetAddress(vendor?.address, 'post')
              : _safeGetAddress(user?.address, 'post'),
          isVendorValue
              ? _safeGetAddress(vendor?.address, 'dist')
              : _safeGetAddress(user?.address, 'dist'),
          isVendorValue
              ? _safeGetAddress(vendor?.address, 'state')
              : _safeGetAddress(user?.address, 'state'),
          isVendorValue
              ? _safeGetAddress(vendor?.address, 'pincode')
              : _safeGetAddress(user?.address, 'pincode'),
          isDarkTheme,
          labelSize,
          textSize,
        ),

        _buildProfileRow(
          'Balance',
          vendor?.balance.toString() ?? '0',
          isDarkTheme,
          labelSize,
          textSize,
        ),
        _buildProfileRow(
          'Bonus Amount',
          isVendorValue
              ? vendor?.bonusAmount.toString()
              : user?.bonusAmount.toString(),
          isDarkTheme,
          labelSize,
          textSize,
        ),
        if (isVendorValue)
          _buildProfileRow(
            'Profession',
            capitalizeWords(vendor?.type),
            isDarkTheme,
            labelSize,
            textSize,
          ),
      ],
    );
  }

  String _safeGetAddress(List<Address>? addresses, String field) {
    if (addresses == null || addresses.isEmpty) return 'N/A';

    final address = addresses[0];
    switch (field) {
      case 'vill':
        return address.vill;
      case 'post':
        return address.post;
      case 'dist':
        return address.dist;
      case 'state':
        return address.state;
      case 'pincode':
        return address.pincode;
      default:
        return 'N/A';
    }
  }

  Widget _buildRatingRow(
    bool isDarkTheme,
    double screenWidth,
    double labelSize,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Rating',
            style: TextStyle(
              color: isDarkTheme ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: labelSize,
            ),
          ),
          Flexible(
            child: buildStarRating(
              vendor?.rating ?? 0.0,
              vendor?.ratingCount ?? 0,
              isDarkTheme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    bool isDarkTheme,
    bool isVendorValue,
    bool isLoggedIn,
    double screenWidth,
  ) {
    final buttonHeight = screenWidth * 0.12;
    final buttonWidth = screenWidth * 0.85;
    final buttonSpacing = screenWidth * 0.02;
    final fontSize = screenWidth * 0.038;

    return Center(
      child: SizedBox(
        width: buttonWidth,
        child: Column(
          children: [
            _actionButton(
              'Upload Profile Image',
              isDarkTheme,
              () => _showImageUploader(),
              buttonHeight,
              fontSize,
            ),
            SizedBox(height: buttonSpacing),
            _actionButton(
              'View Sharing',
              isDarkTheme,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ViewShare()),
              ),
              buttonHeight,
              fontSize,
            ),
            SizedBox(height: buttonSpacing),
            if (isVendorValue) ...[
              _actionButton(
                'Create Booking',
                isDarkTheme,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateBooking(),
                  ),
                ),
                buttonHeight,
                fontSize,
              ),
              SizedBox(height: buttonSpacing),
            ],
            if (isVendorValue) ...[
              _actionButton(
                'Set Wage Rate',
                isDarkTheme,
                () => _showWageRateDialog(),
                buttonHeight,
                fontSize,
              ),
              SizedBox(height: buttonSpacing),
            ],
            _actionButton(
              'Add/Update Address',
              isDarkTheme,
              () => _showAddressDialog(),
              buttonHeight,
              fontSize,
            ),
            SizedBox(height: buttonSpacing),

            _actionButton(
              'Add Balance',
              isDarkTheme,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PaymentPage()),
              ),
              buttonHeight,
              fontSize,
            ),
            SizedBox(height: buttonSpacing),

            _actionButton(
              'Logout',
              isDarkTheme,
              _logout,
              buttonHeight,
              fontSize,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showImageUploader() async {
    final result = await showDialog(
      context: context,
      builder: (context) => const ImageUploader(),
    );

    if (result == true) {
      await _refreshData();
    }
  }

  Future<void> _showWageRateDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => const WageRatePage(),
    );

    if (result == true) {
      await _refreshData();
    }
  }

  Future<void> _showAddressDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => const AddAddressDialog(),
    );

    if (result == true) {
      await _refreshData();
    }
  }

  Widget _actionButton(
    String text,
    bool isDarkTheme,
    VoidCallback onPressed,
    double height,
    double fontSize,
  ) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(
            isDarkTheme ? Colors.teal : Colors.amber,
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(height * 0.2),
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isDarkTheme ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }

  Widget buildStarRating(double rating, int ratingCount, bool isDarkTheme) {
    final iconSize = MediaQuery.of(context).size.width * 0.04;
    final fontSize = MediaQuery.of(context).size.width * 0.035;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            if (index < rating.floor()) {
              return Icon(
                Icons.star,
                color: isDarkTheme ? Colors.teal : Colors.amber,
                size: iconSize,
              );
            } else if (index < rating && rating - index >= 0.5) {
              return Icon(
                Icons.star_half,
                color: isDarkTheme ? Colors.teal : Colors.amber,
                size: iconSize,
              );
            } else {
              return Icon(
                Icons.star_border,
                color: isDarkTheme ? Colors.teal : Colors.amber,
                size: iconSize,
              );
            }
          }),
        ),
        Flexible(
          child: Text(
            ' (${rating.toStringAsFixed(1)})',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Helper functions
  String capitalizeWords(String? input) {
    if (input == null) return '';
    return input
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '',
        )
        .join(' ');
  }

  Widget _buildProfileRow(
    String? label,
    String? value,
    bool isDarkTheme,
    double labelSize,
    double textSize,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label ?? "N/A",
            style: TextStyle(
              color: isDarkTheme ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: labelSize,
            ),
          ),
          Flexible(
            child: Text(
              (label == 'Wage Rate' ||
                      label == "Balance" ||
                      label == "Bonus Amount")
                  ? "₹ $value"
                  : value ?? "N/A",
              style: TextStyle(
                fontSize: textSize,
                color: isDarkTheme ? Colors.black : Colors.white,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedAddress(
    String? village,
    String? post,
    String? district,
    String? state,
    String? pincode,
    bool isDarkTheme,
    double labelSize,
    double textSize,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Address',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: labelSize,
              color: isDarkTheme ? Colors.black : Colors.white,
            ),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "$village",
                  style: TextStyle(
                    fontSize: textSize,
                    color: isDarkTheme ? Colors.black : Colors.white,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "$post",
                  style: TextStyle(
                    fontSize: textSize,
                    color: isDarkTheme ? Colors.black : Colors.white,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "$district",
                  style: TextStyle(
                    fontSize: textSize,
                    color: isDarkTheme ? Colors.black : Colors.white,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "$state",
                  style: TextStyle(
                    fontSize: textSize,
                    color: isDarkTheme ? Colors.black : Colors.white,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "$pincode",
                  style: TextStyle(
                    fontSize: textSize,
                    color: isDarkTheme ? Colors.black : Colors.white,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void updateVendorAddress(
    VendorModel vendor,
    Map<String, dynamic> responseJson,
  ) async {
    List<Address> updatedAddress =
        (responseJson['address'] as List)
            .map((e) => Address.fromJson(e))
            .toList();

    // Create a new VendorModel with updated address
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
      wageRate: vendor.wageRate,
      address: updatedAddress, // ✅ Update here
      balance: vendor.balance,
      bonusAmount: vendor.bonusAmount,
      imgURL: vendor.imgURL,
      message: responseJson['message'] ?? vendor.message,
    );

    // Save updated model to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('vendor', jsonEncode(updatedVendor.toJson()));
  }

  void updateUserAddress(
    UserModel user,
    Map<String, dynamic> responseJson,
  ) async {
    List<Address> updatedAddress =
        (responseJson['address'] as List)
            .map((e) => Address.fromJson(e))
            .toList();

    UserModel updatedUser = UserModel(
      token: user.token,
      userId: user.userId,
      name: user.name,
      email: user.email,
      verifyEmail: user.verifyEmail,
      phoneNo: user.phoneNo,
      verifyPhoneNo: user.verifyPhoneNo,
      gender: user.gender,
      address: updatedAddress, // ✅ Updated
      balance: user.balance,
      bonusAmount: user.bonusAmount,
      imgURL: user.imgURL,
      message: responseJson['message'] ?? user.message,
    );

    final prefs = await SharedPreferences.getInstance();
    prefs.setString('user', jsonEncode(updatedUser.toJson()));
  }
}

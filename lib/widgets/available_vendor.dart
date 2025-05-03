// this file is made responsive for all devices.

import 'dart:convert';
import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/models/data_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AvailableVendor extends StatefulWidget {
  const AvailableVendor({
    super.key,
    required this.bookingDate,
    this.profession = "",
  });

  final DateTime bookingDate;
  final String profession;

  @override
  State<AvailableVendor> createState() => _AvailableVendorState();
}

class _AvailableVendorState extends State<AvailableVendor> {
  Future<Map<String, dynamic>>? _futureVendors;
  VendorModel? _vendor;
  UserModel? _user;
  bool _isVendor = false;
  String _pincode = '';
  int _pageNo = 1;
  int itemCount = 10;
  final int _minRating = 0;
  final int _minWageRate = 0;
  bool _isLoading = false;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookingDate = widget.bookingDate.toString().split(' ')[0];

      final userData = prefs.getString('user');
      final vendorData = prefs.getString('vendor');

      if (userData != null) {
        final decodedUser = jsonDecode(userData);
        _user = UserModel.fromJson(decodedUser);
        _pincode = _user?.address.firstOrNull?.pincode.toString() ?? '';
      }

      if (vendorData != null) {
        final decodedVendor = jsonDecode(vendorData);
        _vendor = VendorModel.fromJson(decodedVendor);
        _isVendor = true;
        _pincode = _vendor?.address.firstOrNull?.pincode.toString() ?? '';
      }

      final token =
          _isVendor ? 'Bearer ${_vendor?.token}' : 'Bearer ${_user?.token}';

      setState(() {
        _futureVendors = _fetchVendors(token, bookingDate);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error loading user data: $e");
    }
  }

  Future<Map<String, dynamic>> _fetchVendors(
    String token,
    String bookingDate,
  ) async {
    try {
      final url = Uri.parse(
        "${KConstantURL.url}/vendor/${_isVendor ? 'getAllV' : 'getAll'}/"
        "${widget.profession.toLowerCase()}/$_pincode/$bookingDate/"
        "$_pageNo/$_minRating/$_minWageRate",
      );

      final response = await http
          .get(url, headers: {"Authorization": token})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        setState(() {
          itemCount = decodedResponse['total'] ?? 10;
        });
        return json.decode(response.body);
      }
      throw Exception("Failed to load vendors: ${response.statusCode}");
    } catch (e) {
      throw Exception("Error fetching vendors: $e");
    }
  }

  Future<void> _handleBookNow({
    required BuildContext context,
    required String vendorId,
    required String jobType,
  }) async {
    setState(() => _isBooking = true);
    try {
      final bookingDate = widget.bookingDate.toString().split(' ')[0];
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user');
      final vendorData = prefs.getString('vendor');

      if (userData == null && vendorData == null) {
        throw Exception("User data not found");
      }

      // final category = _isVendor ? 'vendor' : 'user';
      final decoded = jsonDecode(_isVendor ? vendorData! : userData!);
      final token = 'Bearer ${decoded['token']}';
      final userId = _isVendor ? decoded['vendorId'] : decoded['userId'];

      // Step 1: Create booking
      final bookingResponse = await http
          .post(
            Uri.parse(
              "${KConstantURL.url}/bookings/postToBookings${_isVendor ? 'V' : 'U'}",
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': token,
            },
            body: jsonEncode({
              'userId': userId,
              'vendorId': vendorId,
              'bookingDate': bookingDate,
              'pincode': _pincode,
              'type': jobType,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (bookingResponse.statusCode != 200) {
        throw Exception(jsonDecode(bookingResponse.body)['message']);
      }

      final bookingId = jsonDecode(bookingResponse.body)['bookingId'];
      final now = DateTime.now();

      // Step 2: Confirm booking with vendor
      final patchResponse = await http
          .patch(
            Uri.parse(
              "${KConstantURL.url}/vendor/bookNow${_isVendor ? 'V' : 'U'}/$vendorId",
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': token,
            },
            body: jsonEncode({
              'bookingId': bookingId,
              'name': decoded['name'],
              'phoneNo': decoded['phoneNo'],
              'vill': decoded['address'][0]['vill'],
              'post': decoded['address'][0]['post'],
              'dist': decoded['address'][0]['dist'],
              'pincode': _pincode,
              'date': now.day.toString(),
              'month': now.month.toString(),
              'year': now.year.toString(),
              if (_isVendor) 'vendorUser': decoded['vendorId'],
              if (!_isVendor) 'userId': decoded['userId'],
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (patchResponse.statusCode != 200) {
        throw Exception(jsonDecode(patchResponse.body)['message']);
      }

      // Update local balance
      final responseData = jsonDecode(patchResponse.body);
      if (_isVendor && _vendor != null) {
        await _updateVendorBalance(responseData);
      } else if (_user != null) {
        await _updateUserBalance(responseData);
      }

      // Refresh vendor list
      setState(() {
        _futureVendors = _fetchVendors(token, bookingDate);
        _showSuccessSnackbar(context, responseData['message']);
      });
    } catch (e) {
      _showErrorSnackbar(context, e.toString());
    } finally {
      setState(() => _isBooking = false);
    }
  }

  Future<void> _updateUserBalance(Map<String, dynamic> responseData) async {
    final updatedUser = UserModel(
      token: _user!.token,
      userId: _user!.userId,
      name: _user!.name,
      email: _user!.email,
      verifyEmail: _user!.verifyEmail,
      phoneNo: _user!.phoneNo,
      verifyPhoneNo: _user!.verifyPhoneNo,
      gender: _user!.gender,
      address: _user!.address,
      balance: responseData['balance'] ?? _user!.balance,
      bonusAmount: _user!.bonusAmount,
      imgURL: _user!.imgURL,
      message: responseData['message'] ?? _user!.message,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(updatedUser.toJson()));
    setState(() => _user = updatedUser);
  }

  Future<void> _updateVendorBalance(Map<String, dynamic> responseData) async {
    final updatedVendor = VendorModel(
      token: _vendor!.token,
      vendorId: _vendor!.vendorId,
      name: _vendor!.name,
      email: _vendor!.email,
      verifyEmail: _vendor!.verifyEmail,
      phoneNo: _vendor!.phoneNo,
      verifyPhoneNo: _vendor!.verifyPhoneNo,
      type: _vendor!.type,
      gender: _vendor!.gender,
      rating: _vendor!.rating,
      ratingCount: _vendor!.ratingCount,
      wageRate: _vendor!.wageRate,
      address: _vendor!.address,
      balance: responseData['balance'] ?? _vendor!.balance,
      bonusAmount: _vendor!.bonusAmount,
      imgURL: _vendor!.imgURL,
      message: responseData['message'] ?? _vendor!.message,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vendor', jsonEncode(updatedVendor.toJson()));
    setState(() => _vendor = updatedVendor);
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Center(
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Center(
          child: Text(
            error,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
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
            title: Text(
              'Available ${widget.profession}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: mediaQuery.size.width * 0.05,
              ),
            ),
            backgroundColor: isDarkTheme ? Colors.teal : Colors.amber,
          ),
          backgroundColor: isDarkTheme ? Colors.grey[100] : Colors.grey[900],
          body: SizedBox(
            height: mediaQuery.size.height * 0.85,
            child: Column(
              children: [
                Expanded(
                  child:
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _buildVendorList(isDarkTheme, mediaQuery),
                ),
                itemCount > 0
                    ? _buildPaginationControls(isDarkTheme, mediaQuery)
                    : SizedBox.shrink(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVendorList(bool isDarkTheme, MediaQueryData mediaQuery) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _futureVendors,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: isDarkTheme ? Colors.teal : Colors.amber,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error: ${snapshot.error}",
              style: TextStyle(
                color: isDarkTheme ? Colors.black : Colors.white,
                fontSize: mediaQuery.size.width * 0.04,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              "No ${widget.profession} available",
              style: TextStyle(
                color: isDarkTheme ? Colors.black : Colors.white,
                fontSize: mediaQuery.size.width * 0.045,
              ),
            ),
          );
        }

        final vendorList = snapshot.data!["vendors"] as List? ?? [];
        if (vendorList.isEmpty) {
          return Center(
            child: Text(
              "No ${widget.profession} available",
              style: TextStyle(
                color: isDarkTheme ? Colors.black : Colors.white,
                fontSize: mediaQuery.size.width * 0.045,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(mediaQuery.size.width * 0.03),
          itemCount: vendorList.length,
          itemBuilder:
              (context, index) =>
                  _buildVendorCard(vendorList[index], isDarkTheme, mediaQuery),
        );
      },
    );
  }

  Widget _buildVendorCard(
    dynamic vendor,
    bool isDarkTheme,
    MediaQueryData mediaQuery,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: mediaQuery.size.height * 0.015),
      elevation: 2,
      color: isDarkTheme ? Colors.white : Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(mediaQuery.size.width * 0.04),
        child: Row(
          children: [
            Icon(
              Icons.person,
              size: mediaQuery.size.width * 0.12,
              color: isDarkTheme ? Colors.teal : Colors.amber,
            ),
            SizedBox(width: mediaQuery.size.width * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _capitalizeWords(vendor['name']),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: mediaQuery.size.width * 0.045,
                      color: isDarkTheme ? Colors.black : Colors.white,
                    ),
                  ),
                  Text(
                    _capitalizeWords(vendor['type']),
                    style: TextStyle(
                      fontSize: mediaQuery.size.width * 0.04,
                      color: isDarkTheme ? Colors.black54 : Colors.white70,
                    ),
                  ),
                  _buildStarRating(
                    vendor['rating']?.toDouble() ?? 0.0,
                    vendor['ratingCount'] ?? 0,
                    mediaQuery,
                  ),
                  Text(
                    vendor['phoneNo'].toString(),
                    style: TextStyle(
                      fontSize: mediaQuery.size.width * 0.04,
                      color: isDarkTheme ? Colors.black : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  'Wage Rate',
                  style: TextStyle(
                    fontSize: mediaQuery.size.width * 0.04,
                    color: isDarkTheme ? Colors.black : Colors.white,
                  ),
                ),
                Text(
                  '₹${vendor['wageRate']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: mediaQuery.size.width * 0.045,
                    color: isDarkTheme ? Colors.teal : Colors.amber,
                  ),
                ),
                SizedBox(height: mediaQuery.size.height * 0.01),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkTheme ? Colors.teal : Colors.amber,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: mediaQuery.size.width * 0.04,
                      vertical: mediaQuery.size.height * 0.01,
                    ),
                  ),
                  onPressed:
                      _isBooking
                          ? null
                          : () => _handleBookNow(
                            context: context,
                            vendorId: vendor['_id'],
                            jobType: vendor['type'],
                          ),
                  child:
                      _isBooking
                          ? SizedBox(
                            width: mediaQuery.size.width * 0.05,
                            height: mediaQuery.size.width * 0.05,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: !isDarkTheme ? Colors.white : Colors.black,
                            ),
                          )
                          : Text(
                            'Book Now',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: mediaQuery.size.width * 0.04,
                              color: isDarkTheme ? Colors.white : Colors.black,
                            ),
                          ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(
    double rating,
    int ratingCount,
    MediaQueryData mediaQuery,
  ) {
    return Row(
      children: [
        Row(
          children: List.generate(5, (index) {
            if (index < rating.floor()) {
              return Icon(
                Icons.star,
                color: Colors.amber,
                size: mediaQuery.size.width * 0.04,
              );
            } else if (index < rating && rating - index >= 0.5) {
              return Icon(
                Icons.star_half,
                color: Colors.amber,
                size: mediaQuery.size.width * 0.04,
              );
            } else {
              return Icon(
                Icons.star_border,
                color: Colors.amber,
                size: mediaQuery.size.width * 0.04,
              );
            }
          }),
        ),
        SizedBox(width: mediaQuery.size.width * 0.02),
        Text(
          '$rating ($ratingCount)',
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: mediaQuery.size.width * 0.035,
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationControls(bool isDarkTheme, MediaQueryData mediaQuery) {
    return Container(
      margin: EdgeInsets.all(mediaQuery.size.width * 0.03),
      height: mediaQuery.size.height * 0.06,
      decoration: BoxDecoration(
        color: isDarkTheme ? Colors.white : Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              size: mediaQuery.size.width * 0.05,
            ),
            color: isDarkTheme ? Colors.black : Colors.white,
            onPressed: _pageNo > 1 ? _goToPreviousPage : null,
          ),
          Text(
            '$_pageNo',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: mediaQuery.size.width * 0.045,
              color: isDarkTheme ? Colors.black : Colors.white,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.arrow_forward_ios,
              size: mediaQuery.size.width * 0.05,
            ),
            color: isDarkTheme ? Colors.black : Colors.white,
            onPressed: itemCount > 12 ? _goToNextPage : null,
          ),
        ],
      ),
    );
  }

  void _goToPreviousPage() {
    setState(() {
      _pageNo = _pageNo > 1 ? _pageNo - 1 : 1;
      _refreshVendorList();
    });
  }

  void _goToNextPage() {
    setState(() {
      _pageNo++;
      _refreshVendorList();
    });
  }

  void _refreshVendorList() {
    final bookingDate = widget.bookingDate.toString().split(' ')[0];
    final token =
        _isVendor ? 'Bearer ${_vendor?.token}' : 'Bearer ${_user?.token}';
    setState(() {
      _futureVendors = _fetchVendors(token, bookingDate);
    });
  }

  String _capitalizeWords(String input) {
    return input
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '',
        )
        .join(' ');
  }
}

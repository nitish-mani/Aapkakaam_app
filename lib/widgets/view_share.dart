// this file is made responsive for all devices.

import 'dart:convert';
import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/models/data_model.dart';
import 'package:app_aapkakaam/widgets/banner_ad_widget.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ViewShare extends StatefulWidget {
  const ViewShare({super.key});

  @override
  State<ViewShare> createState() => _ViewShareState();
}

class _ViewShareState extends State<ViewShare> {
  Future<Map<String, dynamic>>? futureCards;
  int pageNo = 0;
  int totalShared = 0;
  int totalPages = 0;
  bool _isLoading = false;
  bool _isFetched = false;
  UserModel? user;
  VendorModel? vendor;
  List<dynamic> _shareList = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final vendorData = prefs.getString('vendor');

    if (userData != null) {
      final decodedUser = jsonDecode(userData);
      setState(() {
        user = UserModel.fromJson(decodedUser);
      });
    }

    if (vendorData != null) {
      final decodedVendor = jsonDecode(vendorData);
      setState(() {
        vendor = VendorModel.fromJson(decodedVendor);
      });
    }
  }

  Future<void> _fetchShareData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _isFetched = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final vendorData = prefs.getString('vendor');
    final isVendorUser = vendorData != null;

    String token;
    String userId;

    if (isVendorUser && vendorData != null) {
      final decodedVendor = jsonDecode(vendorData);
      token = 'Bearer ${decodedVendor['token']}';
      userId = decodedVendor['vendorId'];
    } else if (userData != null) {
      final decodedUser = jsonDecode(userData);
      token = 'Bearer ${decodedUser['token']}';
      userId = decodedUser['userId'];
    } else {
      setState(() => _isLoading = false);
      _showErrorDialog(context, 'User data not found');
      return;
    }

    try {
      final url = Uri.parse(
        isVendorUser
            ? "${KConstantURL.url}/vendor/getShare/$userId/$pageNo"
            : "${KConstantURL.url}/user/getShare/$userId/$pageNo",
      );

      final response = await http.get(url, headers: {"Authorization": token});
      print(json.decode(response.body));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final shareList = jsonResponse['share'] ?? [];
        final total = jsonResponse['total'] ?? 0;

        // Calculate total pages correctly (same as OrdersPage)
        int totalPages = (total / 12).ceil();
        // Ensure at least 1 page even if total is 0
        final int totalPagesFinal = totalPages > 0 ? totalPages : 1;

        if (mounted) {
          setState(() {
            _shareList = shareList;
            totalShared = total;
            totalPages = totalPagesFinal;
            _isLoading = false;
          });
        }
      } else {
        final error = json.decode(response.body);
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorDialog(
            context,
            error['message'] ?? 'Failed to load share data',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog(context, 'Error: $e');
      }
    }
  }

  void _goToPreviousPage() {
    setState(() {
      pageNo--;
      _fetchShareData();
    });
  }

  void _goToNextPage() {
    setState(() {
      pageNo++;
      _fetchShareData();
    });
  }

  void _showEndDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("No more pages"),
            content: const Text("You have reached the end."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Error',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  // Format date to local time (Asia/Kolkata)
  String _formatDate(String dateString) {
    try {
      final DateTime utcDate = DateTime.parse(dateString);
      // Convert to Asia/Kolkata (UTC+5:30)
      final DateTime localDate = utcDate.add(
        const Duration(hours: 5, minutes: 30),
      );
      return "${localDate.day}/${localDate.month}/${localDate.year} ${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return ValueListenableBuilder<bool>(
      valueListenable: isDarkThemeNotifier,
      builder: (context, isDarkTheme, _) {
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Share",
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: mediaQuery.size.width * 0.05,
                  ),
                ),
                Text(
                  "Total Share = $totalShared",
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white70 : Colors.black54,
                    fontSize: mediaQuery.size.width * 0.035,
                  ),
                ),
              ],
            ),
            backgroundColor: isDarkTheme ? Colors.black : Colors.white,
            iconTheme: IconThemeData(
              color: isDarkTheme ? Colors.white : Colors.black,
            ),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(
                Icons.close,
                color: isDarkTheme ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Container(
            height: mediaQuery.size.height * 0.85,
            padding: EdgeInsets.all(mediaQuery.size.width * 0.02),
            decoration: BoxDecoration(
              color: isDarkTheme ? Colors.teal : Colors.amber,
            ),
            child: Column(
              children: [
                Expanded(
                  child:
                      _isFetched
                          ? _buildShareList(isDarkTheme, mediaQuery)
                          : _buildFetchButton(isDarkTheme, mediaQuery),
                ),
                if (_isFetched && _shareList.isNotEmpty) ...[
                  SizedBox(height: mediaQuery.size.height * 0.01),
                  _buildPaginationControls(isDarkTheme, mediaQuery),
                ],
                if (!_isFetched) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Tap "Fetch Share Data" to view your shared contacts',
                    style: TextStyle(
                      color: isDarkTheme ? Colors.white70 : Colors.black54,
                      fontSize: mediaQuery.size.width * 0.035,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFetchButton(bool isDarkTheme, MediaQueryData mediaQuery) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.share_outlined,
            size: mediaQuery.size.width * 0.15,
            color: isDarkTheme ? Colors.white70 : Colors.black54,
          ),
          SizedBox(height: mediaQuery.size.height * 0.02),
          ElevatedButton(
            onPressed: _fetchShareData,
            style: ElevatedButton.styleFrom(
              backgroundColor: !isDarkTheme ? Colors.teal : Colors.amber,
              padding: EdgeInsets.symmetric(
                horizontal: mediaQuery.size.width * 0.08,
                vertical: mediaQuery.size.height * 0.02,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Fetch Share Data',
              style: TextStyle(
                color: isDarkTheme ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: mediaQuery.size.width * 0.04,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(bool isDarkTheme, MediaQueryData mediaQuery) {
    final canGoBack = pageNo > 1;
    final canGoForward = pageNo < totalPages;
    final totalPage = (totalShared / 12).ceil();
    final page = pageNo + 1;
    return Container(
      height: mediaQuery.size.height * 0.06,
      padding: EdgeInsets.symmetric(horizontal: mediaQuery.size.width * 0.02),
      decoration: BoxDecoration(
        color: isDarkTheme ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            color: isDarkTheme ? Colors.white : Colors.black,
            onPressed: canGoBack ? _goToPreviousPage : null,
          ),
          Text(
            '$page/$totalPage',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: mediaQuery.size.width * 0.045,
              color: isDarkTheme ? Colors.white : Colors.black,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            color: isDarkTheme ? Colors.white : Colors.black,
            onPressed:
                canGoForward ? _goToNextPage : () => _showEndDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildShareList(bool isDarkTheme, MediaQueryData mediaQuery) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.amber),
            SizedBox(height: mediaQuery.size.height * 0.02),
            Text(
              'Loading...',
              style: TextStyle(
                color: isDarkTheme ? Colors.white : Colors.black,
                fontSize: mediaQuery.size.width * 0.04,
              ),
            ),
          ],
        ),
      );
    }

    if (_shareList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.share_outlined,
              size: mediaQuery.size.width * 0.1,
              color: isDarkTheme ? Colors.white54 : Colors.black54,
            ),
            SizedBox(height: mediaQuery.size.height * 0.02),
            Text(
              "You haven't shared to anyone yet.",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: mediaQuery.size.width * 0.045,
                color: isDarkTheme ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: mediaQuery.size.height * 0.01),
            Center(child: BannerAdWidget()),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: mediaQuery.size.width * 0.02),
      itemCount: _shareList.length,
      itemBuilder:
          (context, index) => Column(
            children: [
              if (index % 5 == 0) ...[
                Center(child: BannerAdWidget()),
                SizedBox(height: 8),
              ],
              _buildShareCard(
                context,
                _shareList[index],
                isDarkTheme,
                mediaQuery,
              ),
            ],
          ),
    );
  }

  Widget _buildShareCard(
    BuildContext context,
    dynamic share,
    bool isDarkTheme,
    MediaQueryData mediaQuery,
  ) {
    final isSmallScreen = mediaQuery.size.width < 350;

    return Container(
      margin: EdgeInsets.only(bottom: mediaQuery.size.height * 0.015),
      padding: EdgeInsets.all(mediaQuery.size.width * 0.03),
      decoration: BoxDecoration(
        color: isDarkTheme ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Phone No :',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 12 : 14,
                  color: isDarkTheme ? Colors.white : Colors.black,
                ),
              ),
              Text(
                share['phoneNo']?.toString() ?? 'N/A',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: isDarkTheme ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: mediaQuery.size.height * 0.005),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Date :',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 12 : 14,
                  color: isDarkTheme ? Colors.white : Colors.black,
                ),
              ),
              Text(
                _formatDate(share['shareDate'] ?? share['date'] ?? ''),
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: isDarkTheme ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _capitalizeWords(String input) {
    if (input.isEmpty) return '';
    return input
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '',
        )
        .join(' ');
  }
}

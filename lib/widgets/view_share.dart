// this file is made responsive for all devices.

import 'dart:convert';
import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/models/data_model.dart';
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
  int orderDetails = 1;
  UserModel? user;
  VendorModel? vendor;
  int pageNo = 1;
  int totalShared = 0;
  late Map<dynamic, bool> isLoadingC;
  late Map<dynamic, bool> isLoading;
  String? ratingOrderId;
  final TextEditingController ratingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    isLoadingC = {}; // Initialize as empty map
    isLoading = {}; // Initialize as empty map
    _loadUserData();
  }

  @override
  void dispose() {
    ratingController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final vendorData = prefs.getString('vendor');

    if (userData != null) {
      final decodedUser = jsonDecode(userData);
      setState(() {
        user = UserModel.fromJson(decodedUser);
        futureCards = _fetchCards(
          decodedUser['userId'],
          pageNo,
          'Bearer ${decodedUser['token']}',
        );
      });
    }

    if (vendorData != null) {
      final decodedVendor = jsonDecode(vendorData);
      setState(() {
        vendor = VendorModel.fromJson(decodedVendor);
        futureCards = _fetchCards(
          decodedVendor['vendorId'],
          pageNo,
          'Bearer ${decodedVendor['token']}',
        );
      });
    }
  }

  Future<Map<String, dynamic>> _fetchCards(
    String userId,
    int pageNo,
    String token,
  ) async {
    final url = Uri.parse(
      isVendor.value
          ? "${KConstantURL.url}/vendor/getShare/$userId/$pageNo"
          : "${KConstantURL.url}/user/getShare/$userId/$pageNo",
    );

    try {
      final response = await http.get(url, headers: {"Authorization": token});
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        totalShared = jsonResponse['total'] ?? 0;
        // initializeIsLoadingCFromResponse(jsonResponse);
        print(jsonResponse);
        return jsonResponse;
      }
      throw Exception("Failed to load orders: ${response.statusCode}");
    } catch (e) {
      throw Exception("Error fetching orders: $e");
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
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  "View Sharing",
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: mediaQuery.size.width * 0.05,
                  ),
                ),
                backgroundColor: isDarkTheme ? Colors.black : Colors.white,
                iconTheme: IconThemeData(
                  color: isDarkTheme ? Colors.white : Colors.black,
                ),
                centerTitle: true,
              ),
              body: Container(
                height: mediaQuery.size.height * 0.85,
                padding: EdgeInsets.all(mediaQuery.size.width * 0.02),
                decoration: BoxDecoration(
                  color: isDarkTheme ? Colors.teal : Colors.amber,
                ),
                child: Column(
                  children: [
                    Expanded(child: _buildShareList(isDarkTheme, mediaQuery)),
                    SizedBox(height: mediaQuery.size.height * 0.01),
                    _buildPaginationControls(isDarkTheme, mediaQuery),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaginationControls(bool isDarkTheme, MediaQueryData mediaQuery) {
    final canGoBack = pageNo > 1;
    final canGoForward = totalShared > 12 && pageNo < totalShared / 12;

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
            '$pageNo',
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

  void _goToPreviousPage() {
    setState(() {
      pageNo--;
      futureCards = _fetchCards(
        user?.userId.toString() ?? vendor?.vendorId.toString() ?? '',
        pageNo,
        'Bearer ${user?.token ?? vendor?.token ?? ''}',
      );
    });
  }

  void _goToNextPage() {
    setState(() {
      pageNo++;
      futureCards = _fetchCards(
        user?.userId.toString() ?? vendor?.vendorId.toString() ?? '',
        pageNo,
        'Bearer ${user?.token ?? vendor?.token ?? ''}',
      );
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

  Widget _buildShareList(bool isDarkTheme, MediaQueryData mediaQuery) {
    return FutureBuilder<Map<String, dynamic>>(
      future: futureCards,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: isDarkTheme ? Colors.white : Colors.black,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error: ${snapshot.error}",
              style: TextStyle(
                color: isDarkTheme ? Colors.white : Colors.black,
                fontSize: mediaQuery.size.width * 0.04,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              "No share found.",
              style: TextStyle(
                color: isDarkTheme ? Colors.white : Colors.black,
                fontSize: mediaQuery.size.width * 0.04,
              ),
            ),
          );
        }

        final shareList = (snapshot.data!["share"] ?? []) as List<dynamic>;

        if (shareList.isEmpty) {
          return Center(
            child: Text(
              _getEmptyStateMessage(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: mediaQuery.size.width * 0.04,
                color: isDarkTheme ? Colors.white : Colors.black,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: mediaQuery.size.width * 0.02,
          ),
          itemCount: shareList.length,
          itemBuilder:
              (context, index) => _buildShareCard(
                context,
                shareList[index],
                isDarkTheme,
                mediaQuery,
              ),
        );
      },
    );
  }

  String _getEmptyStateMessage() {
    return "You haven't shared to anyone yet.";
  }

  Widget _buildShareCard(
    BuildContext context,
    dynamic order,
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
          _buildShareInfoRow('Name', order['name'], isDarkTheme, isSmallScreen),
          _buildShareInfoRow(
            'Mobile',
            order['phoneNo'].toString(),
            isDarkTheme,
            isSmallScreen,
          ),
          _buildShareInfoRow(
            'Profession',
            order['type'],
            isDarkTheme,
            isSmallScreen,
          ),
          _buildShareInfoRow('Date', order['date'], isDarkTheme, isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildShareInfoRow(
    String label,
    String value,
    bool isDarkTheme,
    bool isSmallScreen,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 2.0 : 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 12 : 14,
              color: isDarkTheme ? Colors.white : Colors.black,
            ),
          ),
          Text(
            _capitalizeWords(value),
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              color: _getStatusColor(orderDetails),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
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

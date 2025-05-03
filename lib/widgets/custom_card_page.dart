// This file is responsive and optimized.

import 'dart:convert';
import 'package:app_aapkakaam/widgets/address_page.dart';
import 'package:app_aapkakaam/widgets/booking_date_selection.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomCardPage extends StatefulWidget {
  const CustomCardPage({
    super.key,
    this.cardColor = Colors.amber,
    this.cardFirstChildColor = Colors.pink,
    this.cardSecondChildColor = Colors.black,
    this.isDarkTheme = false,
    required this.imageData,
  });

  final List<dynamic> imageData;
  final Color cardColor;
  final Color cardFirstChildColor;
  final Color cardSecondChildColor;
  final bool isDarkTheme;

  @override
  State<CustomCardPage> createState() => _CustomCardPageState();
}

class _CustomCardPageState extends State<CustomCardPage> {
  bool? _hasAddress;

  @override
  void initState() {
    super.initState();
    _checkAddressStatus();
  }

  Future<void> _checkAddressStatus() async {
    final hasAddress = await _userHasAddress();
    if (mounted) {
      setState(() => _hasAddress = hasAddress);
    }
  }

  Future<bool> _userHasAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user');
      final vendorData = prefs.getString('vendor');

      bool hasAddressInData(String? data) {
        if (data == null) return false;
        final decoded = jsonDecode(data);
        return decoded['address'] != null && decoded['address'].isNotEmpty;
      }

      return hasAddressInData(userData) || hasAddressInData(vendorData);
    } catch (e) {
      debugPrint('Error checking address status: $e');
      return false;
    }
  }

  void _showAddAddressDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Address Required',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text('Please add your address to continue.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final result = await showDialog(
                    context: context,
                    builder: (context) => const AddAddressDialog(),
                  );
                  if (result == true) {
                    Navigator.of(context).pop();
                    _checkAddressStatus();
                  }
                },
                child: const Text(
                  'Add Address',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }

  void _handleServiceTap(BuildContext context, String profession) async {
    final hasAddress = _hasAddress ?? await _userHasAddress();

    if (hasAddress) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingDateSelection(profession: profession),
        ),
      );
    } else {
      _showAddAddressDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final paddingV = _responsiveValue(screenWidth, 12, 16, 20);
    final paddingH = _responsiveValue(screenWidth, 8, 12, 16);
    final useGridView = screenWidth >= 500;

    return Container(
      padding: EdgeInsets.symmetric(vertical: paddingV, horizontal: paddingH),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child:
          useGridView
              ? _buildGridLayout(screenWidth)
              : _buildColumnLayout(screenWidth),
    );
  }

  Widget _buildGridLayout(double screenWidth) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: _responsiveValue(screenWidth, 180, 200, 220),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: widget.imageData.length,
      itemBuilder: (context, index) {
        final item = widget.imageData[index];
        final color =
            index % 2 == 0
                ? widget.cardFirstChildColor
                : widget.cardSecondChildColor;
        return _buildServiceCard(
          context,
          item['image'],
          item['title'],
          color,
          screenWidth,
        );
      },
    );
  }

  Widget _buildColumnLayout(double screenWidth) {
    List<Widget> rows = [];
    for (int i = 0; i < widget.imageData.length; i += 2) {
      final first = widget.imageData[i];
      final second =
          (i + 1 < widget.imageData.length) ? widget.imageData[i + 1] : null;
      final isReverse = (i ~/ 2) % 2 == 1;

      rows.add(
        Row(
          children: [
            Expanded(
              child: _buildServiceCard(
                context,
                first['image'],
                first['title'],
                isReverse
                    ? widget.cardSecondChildColor
                    : widget.cardFirstChildColor,
                screenWidth,
              ),
            ),
            if (second != null)
              Expanded(
                child: _buildServiceCard(
                  context,
                  second['image'],
                  second['title'],
                  isReverse
                      ? widget.cardFirstChildColor
                      : widget.cardSecondChildColor,
                  screenWidth,
                ),
              ),
          ],
        ),
      );

      rows.add(SizedBox(height: screenWidth * 0.03));
    }

    return Column(children: rows);
  }

  double _responsiveValue(
    double screenWidth,
    double small,
    double medium,
    double large,
  ) {
    if (screenWidth >= 900) return large;
    if (screenWidth >= 600) return medium;
    return small;
  }

  Widget _buildServiceCard(
    BuildContext context,
    String imagePath,
    String title,
    Color color,
    double screenWidth,
  ) {
    final fontSize = _responsiveValue(screenWidth, 12, 14, 16);
    final padding = _responsiveValue(screenWidth, 8, 10, 12);

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: InkWell(
        onTap: () => _handleServiceTap(context, title),
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            color: color,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: AspectRatio(
                  aspectRatio: 1.1,
                  child: Image.asset(imagePath, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkTheme ? Colors.white : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

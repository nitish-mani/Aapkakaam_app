// this file is made responsive for all devices.

import 'dart:convert';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/widgets/banner_ad_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharePage extends StatefulWidget {
  const SharePage({super.key});

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  String? _url;
  String? _shareText;
  final List<Map<String, dynamic>> _shareOptions = [
    {'label': 'Twitter', 'icon': 'assets/icons/twitter.svg'},
    {'label': 'Facebook', 'icon': 'assets/icons/facebook.svg'},
    {'label': 'LinkedIn', 'icon': 'assets/icons/linkedin.svg'},
    {'label': 'WhatsApp', 'icon': 'assets/icons/whatsapp.svg'},
    {'label': 'Telegram', 'icon': 'assets/icons/telegram.svg'},
    {'label': 'SMS', 'icon': 'assets/icons/message.svg'},
  ];

  @override
  void initState() {
    super.initState();
    _loadShareData();
  }

  Future<void> _loadShareData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoryKey = isVendor.value ? "vendor" : "user";
      final categoryData = prefs.getString(categoryKey);

      if (categoryData != null) {
        final json = jsonDecode(categoryData) as Map<String, dynamic>;
        final userId = json[categoryKey == 'user' ? 'userId' : 'vendorId'];
        final name = json['name'];

        setState(() {
          _url = "https://aapkakaam.com/category/$categoryKey/$userId";
          _shareText = "Shared by $name via AapKaKaam";
        });
      }
    } catch (e) {
      debugPrint("Error loading share data: $e");
    }
  }

  void _shareContent() {
    if (_shareText != null && _url != null) {
      Share.share('$_shareText\n$_url');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sharing content not available yet')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isPortrait = mediaQuery.orientation == Orientation.portrait;

    return ValueListenableBuilder<bool>(
      valueListenable: isDarkThemeNotifier,
      builder: (context, isDarkTheme, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: isVendor,
          builder: (context, isVendor, _) {
            return Padding(
              padding: EdgeInsets.all(mediaQuery.size.width * 0.04),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(mediaQuery.size.width * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Share Profile',
                        style: TextStyle(
                          fontSize: mediaQuery.size.width * 0.06,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: mediaQuery.size.height * 0.03),
                      _buildShareGrid(mediaQuery, isPortrait),
                      SizedBox(height: mediaQuery.size.height * 0.02),
                      ElevatedButton(
                        onPressed: _shareContent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size(
                            mediaQuery.size.width * 0.6,
                            mediaQuery.size.height * 0.06,
                          ),
                        ),
                        child: Text(
                          'Share via Other Apps',
                          style: TextStyle(
                            fontSize: mediaQuery.size.width * 0.045,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      SizedBox(height: mediaQuery.size.height * 0.03),
                      Center(child: BannerAdWidget()),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShareGrid(MediaQueryData mediaQuery, bool isPortrait) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isPortrait ? 3 : 6,
      childAspectRatio: isPortrait ? 0.9 : 1.2,
      mainAxisSpacing: mediaQuery.size.height * 0.02,
      crossAxisSpacing: mediaQuery.size.width * 0.04,
      padding: EdgeInsets.zero,
      children:
          _shareOptions.map((option) {
            return _buildShareButton(
              option['label'],
              option['icon'],
              mediaQuery,
            );
          }).toList(),
    );
  }

  Widget _buildShareButton(
    String label,
    String assetPath,
    MediaQueryData mediaQuery,
  ) {
    return GestureDetector(
      onTap: _shareContent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(mediaQuery.size.width * 0.04),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // ignore: deprecated_member_use
              color: Colors.grey.withOpacity(0.1),
            ),
            child: SvgPicture.asset(
              assetPath,
              height: mediaQuery.size.width * 0.08,
              width: mediaQuery.size.width * 0.08,
            ),
          ),
          SizedBox(height: mediaQuery.size.height * 0.01),
          Text(
            label,
            style: TextStyle(
              color: Colors.black,
              fontSize: mediaQuery.size.width * 0.035,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

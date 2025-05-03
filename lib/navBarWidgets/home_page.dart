// this file is made responsive for all devices using flutter_screenutil.

import 'package:app_aapkakaam/appBarWidgets/location_page.dart';
import 'package:app_aapkakaam/appBarWidgets/wallet_page.dart';
import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/navBarWidgets/bookings_page.dart';
import 'package:app_aapkakaam/navBarWidgets/orders_page.dart';
import 'package:app_aapkakaam/navBarWidgets/profile_page.dart';
import 'package:app_aapkakaam/navBarWidgets/search_page.dart';
import 'package:app_aapkakaam/navBarWidgets/share_page.dart';
import 'package:app_aapkakaam/widgets/body_page.dart';
import 'package:app_aapkakaam/widgets/navbar_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // <-- Added

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Define page lists outside of build method to avoid recreating them on every rebuild
  static final List<Widget> _allPages = [
    BodyPage(),
    BookingsPage(),
    OrdersPage(),
    SearchPage(),
    SharePage(),
    ProfilePage(),
  ];

  static final List<Widget> _userPages = [
    _allPages[0], // BodyPage
    _allPages[2], // OrdersPage
    _allPages[3], // SearchPage
    _allPages[4], // SharePage
    _allPages[5], // ProfilePage
  ];

  Future<void> _toggleTheme() async {
    isDarkThemeNotifier.value = !isDarkThemeNotifier.value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(KConstant.themeModeKey, isDarkThemeNotifier.value);
  }

  @override
  Widget build(BuildContext context) {
    // Use ScreenUtil for responsive values
    final double iconSize = 24.w; // previously screenWidth * 0.06 approx
    final double appBarHeight = 60.h; // previously screenHeight * 0.07 approx
    final double logoHeight = (appBarHeight * 0.8).h;
    final double horizontalPadding = 4.w; // ~1% of width

    return ValueListenableBuilder(
      valueListenable: isDarkThemeNotifier,
      builder: (context, isDarkTheme, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: !isDarkTheme ? Colors.black : Colors.white,
            toolbarHeight: appBarHeight,
            title: SvgPicture.asset(
              isDarkTheme
                  ? 'assets/images/aapkakaam_logo_dark.svg'
                  : 'assets/images/aapkakaam_logo_light.svg',
              height: logoHeight,
              fit: BoxFit.contain,
            ),
            actions: [
              _buildAppBarIconButton(
                icon: Icons.location_pin,
                isDarkTheme: isDarkTheme,
                iconSize: iconSize,
                onPressed: () => _navigateTo(context, const LocationPage()),
              ),
              _buildAppBarIconButton(
                icon: Icons.account_balance_wallet_outlined,
                isDarkTheme: isDarkTheme,
                iconSize: iconSize,
                onPressed: () => _navigateTo(context, const WalletPage()),
              ),
              _buildAppBarIconButton(
                icon: isDarkTheme ? Icons.dark_mode : Icons.light_mode,
                isDarkTheme: isDarkTheme,
                iconSize: iconSize,
                onPressed: _toggleTheme,
              ),
            ],
          ),
          body: Container(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            decoration: BoxDecoration(
              color: !isDarkTheme ? Colors.amber : Colors.teal,
            ),
            child: _buildPageContent(),
          ),
          bottomNavigationBar: NavbarPage(),
        );
      },
    );
  }

  Widget _buildAppBarIconButton({
    required IconData icon,
    required bool isDarkTheme,
    required double iconSize,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(
        icon,
        size: iconSize,
        color: !isDarkTheme ? Colors.white : Colors.black,
      ),
      onPressed: onPressed,
      padding: EdgeInsets.symmetric(horizontal: 8.w), // ~2% width before
      splashRadius: (iconSize * 0.9).r,
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  Widget _buildPageContent() {
    return ValueListenableBuilder<int>(
      valueListenable: selectedPageNotifier,
      builder: (context, selectedPage, _) {
        return ValueListenableBuilder(
          valueListenable: isVendor,
          builder: (context, isVendorValue, _) {
            final pages = isVendorValue ? _allPages : _userPages;
            final safeIndex = selectedPage.clamp(0, pages.length - 1);

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey<int>(safeIndex),
                child: pages[safeIndex],
              ),
            );
          },
        );
      },
    );
  }
}

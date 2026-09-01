import 'dart:ui';

// import 'package:app_aapkakaam/appBarWidgets/location_page.dart';
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
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static final List<Widget> _allPages = [
    BodyPage(),
    BookingsPage(),
    OrdersPage(),
    SearchPage(),
    SharePage(),
    ProfilePage(),
  ];

  static final List<Widget> _userPages = [
    _allPages[0],
    _allPages[2],
    _allPages[3],
    _allPages[4],
    _allPages[5],
  ];

  // ------------------------------------------------------------
  // THEME
  // ------------------------------------------------------------

  Future<void> _toggleTheme() async {
    isDarkThemeNotifier.value = !isDarkThemeNotifier.value;

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setBool(KConstant.themeModeKey, isDarkThemeNotifier.value);
  }

  // ------------------------------------------------------------
  // MAIN
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final surface = colorScheme.surface;
    final onSurface = colorScheme.onSurface;

    return ValueListenableBuilder<bool>(
      valueListenable: isDarkThemeNotifier,
      builder: (context, isDarkTheme, _) {
        return Scaffold(
          backgroundColor:
              isDarkTheme ? const Color(0xFF0B1020) : const Color(0xFFF7F8FC),
          extendBody: true,
          body: Stack(
            children: [
              _buildBackground(context, isDarkTheme, primaryColor, surface),

              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    _buildModernAppBar(
                      context,
                      isDarkTheme,
                      primaryColor,
                      colorScheme,
                    ),
                    Expanded(
                      child: _buildPageContent(
                        context,
                        isDarkTheme,
                        primaryColor,
                        surface,
                        onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildModernBottomNavigation(
            context,
            isDarkTheme,
            primaryColor,
            surface,
            onSurface,
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // BACKGROUND
  // ------------------------------------------------------------

  Widget _buildBackground(
    BuildContext context,
    bool isDarkTheme,
    Color primaryColor,
    Color surface,
  ) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color:
              isDarkTheme ? const Color(0xFF0B1020) : const Color(0xFFF7F8FC),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -100.h,
              right: -90.w,
              child: _buildGlow(
                size: 280.w,
                color: primaryColor,
                opacity: isDarkTheme ? 0.10 : 0.07,
              ),
            ),
            Positioned(
              top: 220.h,
              left: -130.w,
              child: _buildGlow(
                size: 250.w,
                color: const Color(0xFFFF8A3D),
                opacity: isDarkTheme ? 0.08 : 0.06,
              ),
            ),
            Positioned(
              bottom: 130.h,
              right: -100.w,
              child: _buildGlow(
                size: 220.w,
                color: const Color(0xFF22C55E),
                opacity: isDarkTheme ? 0.06 : 0.04,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlow({
    required double size,
    required Color color,
    required double opacity,
  }) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(opacity),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // APP BAR
  // ------------------------------------------------------------

  Widget _buildModernAppBar(
    BuildContext context,
    bool isDarkTheme,
    Color primaryColor,
    ColorScheme colorScheme,
  ) {
    final surface = colorScheme.surface;
    final onSurface = colorScheme.onSurface;

    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 8.h),
      child: Container(
        decoration: BoxDecoration(
          color:
              isDarkTheme
                  ? const Color(0xFF1A1A2E).withOpacity(0.95)
                  : surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color:
                isDarkTheme
                    ? Colors.white.withOpacity(0.08)
                    : const Color(0xFFE8EAF2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isDarkTheme
                      ? Colors.black.withOpacity(0.30)
                      : const Color(0xFF1F2937).withOpacity(0.06),
              blurRadius: 18.r,
              offset: Offset(0, 6.h),
            ),
          ],
        ),
        child: Row(
          children: [
            // LOGO
            Expanded(
              child: Container(
                height: 58.h,
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SvgPicture.asset(
                    isDarkTheme
                        ? 'assets/images/aapkakaam_logo_light.svg'
                        : 'assets/images/aapkakaam_logo_dark.svg',
                    fit: BoxFit.contain,
                    height: 52.h,
                    width: 130.w,
                  ),
                ),
              ),
            ),

            SizedBox(width: 8.w),

            // LANGUAGE
            ValueListenableBuilder<bool>(
              valueListenable: isHindiNotifier,
              builder: (context, isHindi, _) {
                return _buildLanguageButton(
                  context: context,
                  isDarkTheme: isDarkTheme,
                  isHindi: isHindi,
                  primaryColor: primaryColor,
                );
              },
            ),

            SizedBox(width: 7.w),

            // WALLET
            _buildHeaderButton(
              context: context,
              isDarkTheme: isDarkTheme,
              icon: Icons.account_balance_wallet_rounded,
              label: 'बटुआ',
              color: primaryColor,
              primaryColor: primaryColor,
              surface: surface,
              onSurface: onSurface,
              onTap: () {
                _navigateTo(context, const WalletPage());
              },
            ),

            SizedBox(width: 7.w),

            // THEME
            _buildThemeButton(
              context,
              isDarkTheme,
              primaryColor,
              surface,
              onSurface,
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // HEADER BUTTON
  // ------------------------------------------------------------

  Widget _buildHeaderButton({
    required BuildContext context,
    required bool isDarkTheme,
    required IconData icon,
    required String label,
    required Color color,
    required Color primaryColor,
    required Color surface,
    required Color onSurface,
    required VoidCallback onTap,
  }) {
    final bgColor = isDarkTheme ? const Color(0xFF2A2A3E) : surface;
    final borderColor =
        isDarkTheme ? Colors.white.withOpacity(0.1) : const Color(0xFFE8EAF2);
    final shadowColor =
        isDarkTheme
            ? Colors.black.withOpacity(0.30)
            : const Color(0xFF1F2937).withOpacity(0.06);

    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(17.r),
          onTap: onTap,
          child: Container(
            width: 49.w,
            height: 49.w,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(17.r),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 18.r,
                  offset: Offset(0, 6.h),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: color.withOpacity(isDarkTheme ? 0.20 : 0.10),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, size: 20.sp, color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // LANGUAGE BUTTON
  // ------------------------------------------------------------

  Widget _buildLanguageButton({
    required BuildContext context,
    required bool isDarkTheme,
    required bool isHindi,
    required Color primaryColor,
  }) {
    final bgColor = isDarkTheme ? const Color(0xFF2A2A3E) : Colors.white;
    final borderColor =
        isDarkTheme ? Colors.white.withOpacity(0.1) : const Color(0xFFE8EAF2);
    final shadowColor =
        isDarkTheme
            ? Colors.black.withOpacity(0.30)
            : const Color(0xFF1F2937).withOpacity(0.06);

    return Tooltip(
      message: isHindi ? 'English' : 'हिंदी',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(17.r),
          onTap: () async {
            final nextValue = !isHindiNotifier.value;
            isHindiNotifier.value = nextValue;

            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isHindi', nextValue);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 49.w,
            height: 49.w,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(17.r),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 18.r,
                  offset: Offset(0, 6.h),
                ),
              ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  );
                },
                child: Container(
                  key: ValueKey<bool>(isHindi),
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(isDarkTheme ? 0.20 : 0.09),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: Text(
                      isHindi ? 'हि' : 'EN',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // THEME BUTTON
  // ------------------------------------------------------------

  Widget _buildThemeButton(
    BuildContext context,
    bool isDarkTheme,
    Color primaryColor,
    Color surface,
    Color onSurface,
  ) {
    final bgColor = isDarkTheme ? const Color(0xFF2A2A3E) : surface;
    final borderColor =
        isDarkTheme ? Colors.white.withOpacity(0.1) : const Color(0xFFE8EAF2);
    final shadowColor =
        isDarkTheme
            ? Colors.black.withOpacity(0.30)
            : const Color(0xFF1F2937).withOpacity(0.06);

    return Tooltip(
      message: isDarkTheme ? 'दिन' : 'रात',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(17.r),
          onTap: _toggleTheme,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 49.w,
            height: 49.w,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(17.r),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 18.r,
                  offset: Offset(0, 6.h),
                ),
              ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  return RotationTransition(
                    turns: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Container(
                  key: ValueKey(isDarkTheme),
                  width: 34.w,
                  height: 34.w,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    isDarkTheme
                        ? Icons.wb_sunny_rounded
                        : Icons.dark_mode_rounded,
                    size: 20.sp,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // PAGE CONTENT
  // ------------------------------------------------------------

  Widget _buildPageContent(
    BuildContext context,
    bool isDarkTheme,
    Color primaryColor,
    Color surface,
    Color onSurface,
  ) {
    return ValueListenableBuilder<int>(
      valueListenable: selectedPageNotifier,
      builder: (context, selectedPage, _) {
        return ValueListenableBuilder(
          valueListenable: isVendor,
          builder: (context, isVendorValue, _) {
            final pages = isVendorValue ? _allPages : _userPages;

            final safeIndex = selectedPage.clamp(0, pages.length - 1);

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final slideAnimation = Tween<Offset>(
                  begin: const Offset(0.025, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                );

                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: slideAnimation,
                    child: child,
                  ),
                );
              },
              child: _buildContentCard(
                key: ValueKey<int>(safeIndex),
                page: pages[safeIndex],
                isDarkTheme: isDarkTheme,
                surface: surface,
                onSurface: onSurface,
                primaryColor: primaryColor,
              ),
            );
          },
        );
      },
    );
  }

  // ------------------------------------------------------------
  // CONTENT CARD
  // ------------------------------------------------------------

  Widget _buildContentCard({
    required Key key,
    required Widget page,
    required bool isDarkTheme,
    required Color surface,
    required Color onSurface,
    required Color primaryColor,
  }) {
    return Container(
      key: key,
      margin: EdgeInsets.fromLTRB(10.w, 4.h, 10.w, 105.h),
      decoration: BoxDecoration(
        color: isDarkTheme ? const Color(0xFF11182B) : surface,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color:
              isDarkTheme
                  ? Colors.white.withOpacity(0.055)
                  : const Color(0xFFE9EBF3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                isDarkTheme
                    ? Colors.black.withOpacity(0.24)
                    : Colors.black.withOpacity(0.07),
            blurRadius: 30.r,
            offset: Offset(0, 12.h),
          ),
          BoxShadow(
            color: primaryColor.withOpacity(0.03),
            blurRadius: 40.r,
            spreadRadius: -20.r,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(28.r), child: page),
    );
  }

  // ------------------------------------------------------------
  // BOTTOM NAVIGATION
  // ------------------------------------------------------------

  Widget _buildModernBottomNavigation(
    BuildContext context,
    bool isDarkTheme,
    Color primaryColor,
    Color surface,
    Color onSurface,
  ) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 10.h),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(27.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 72.h,
              decoration: BoxDecoration(
                color:
                    isDarkTheme
                        ? const Color(0xFF11182B).withOpacity(0.96)
                        : surface.withOpacity(0.96),
                borderRadius: BorderRadius.circular(27.r),
                border: Border.all(
                  color:
                      isDarkTheme
                          ? Colors.white.withOpacity(0.07)
                          : const Color(0xFFE5E7EF),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkTheme ? 0.30 : 0.10),
                    blurRadius: 30.r,
                    offset: Offset(0, 10.h),
                  ),
                  BoxShadow(
                    color: primaryColor.withOpacity(0.06),
                    blurRadius: 40.r,
                    spreadRadius: -20.r,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              child: const NavbarPage(),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // NAVIGATION
  // ------------------------------------------------------------

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          final slideAnimation = Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(curvedAnimation);

          return FadeTransition(
            opacity: curvedAnimation,
            child: SlideTransition(position: slideAnimation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }
}

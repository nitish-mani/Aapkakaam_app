// this file is made responsive.

import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:flutter/material.dart';

class NavbarPage extends StatefulWidget {
  const NavbarPage({super.key});

  @override
  State<NavbarPage> createState() => _NavbarPageState();
}

class _NavbarPageState extends State<NavbarPage> {
  // ✅ FIX: Define all tabs with their indices
  final List<NavItem> _allTabs = [
    NavItem(index: 0, icon: Icons.home_rounded, label: 'Home', labelHi: 'होम'),
    NavItem(
      index: 1,
      icon: Icons.receipt_long_rounded,
      label: 'Bookings',
      labelHi: 'बुकिंग',
      isBooking: true,
    ),
    NavItem(
      index: 2,
      icon: Icons.list_alt_rounded,
      label: 'Orders',
      labelHi: 'ऑर्डर',
    ),
    NavItem(
      index: 3,
      icon: Icons.search_rounded,
      label: 'Search',
      labelHi: 'खोजें',
    ),
    NavItem(
      index: 4,
      icon: Icons.share_rounded,
      label: 'Share',
      labelHi: 'शेयर',
    ),
    NavItem(
      index: 5,
      icon: Icons.person_rounded,
      label: 'Profile',
      labelHi: 'प्रोफ़ाइल',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isHindiNotifier,
      builder: (context, isHindi, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: isDarkThemeNotifier,
          builder: (context, isDarkTheme, _) {
            return ValueListenableBuilder<int>(
              valueListenable: selectedPageNotifier,
              builder: (context, selectedIndex, _) {
                return ValueListenableBuilder<Map<String, bool>>(
                  valueListenable: bookingIdNotifier,
                  builder: (context, bookingIds, _) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: isVendor,
                      builder: (context, isVender, _) {
                        return ValueListenableBuilder<int>(
                          valueListenable: bookingCountNotifier,
                          builder: (context, bookingCount, _) {
                            return _buildNavigationBar(
                              context: context,
                              isHindi: isHindi,
                              isDarkTheme: isDarkTheme,
                              selectedIndex: selectedIndex,
                              isVender: isVender,
                              bookingCount: bookingCount,
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildNavigationBar({
    required BuildContext context,
    required bool isHindi,
    required bool isDarkTheme,
    required int selectedIndex,
    required bool isVender,
    required int bookingCount,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final onSurface = colorScheme.onSurface;

    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = (screenWidth * 0.06).clamp(20.0, 24.0);
    final fontSize = (screenWidth * 0.025).clamp(10.0, 12.0);

    // ✅ FIX: Filter tabs based on vendor status
    // For vendor: show all tabs (Home, Bookings, Orders, Search, Share, Profile)
    // For non-vendor: show all tabs except Bookings (Home, Orders, Search, Share, Profile)
    final visibleTabs =
        _allTabs.where((tab) {
          // Show booking tab only for vendors
          if (tab.isBooking) {
            return isVender;
          }
          return true;
        }).toList();

    // ✅ FIX: Map selected index to visible tab index
    // Get the actual index of the selected tab in the original list
    final selectedTab = _allTabs.firstWhere(
      (tab) => tab.index == selectedIndex,
      orElse: () => _allTabs.first,
    );

    // Find the index of the selected tab in the visible list
    int visibleIndex = visibleTabs.indexWhere(
      (tab) => tab.index == selectedTab.index,
    );
    if (visibleIndex == -1) visibleIndex = 0;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: visibleIndex, // ✅ Use visible index
      backgroundColor: Colors.transparent,
      elevation: 0,
      unselectedItemColor:
          isDarkTheme ? Colors.white54 : onSurface.withOpacity(0.5),
      selectedItemColor: primaryColor,
      selectedLabelStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: fontSize,
        color: primaryColor,
      ),
      unselectedLabelStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: (screenWidth * 0.025).clamp(8.0, 10.0),
        color: isDarkTheme ? Colors.white54 : onSurface.withOpacity(0.5),
      ),
      onTap: (index) {
        // ✅ FIX: Get the actual tab index from visible tabs
        final tappedTab = visibleTabs[index];
        selectedPageNotifier.value = tappedTab.index;
      },
      items:
          visibleTabs.map((tab) {
            final isSelected = tab.index == selectedIndex;

            // For bookings tab with count
            if (tab.isBooking && isVender && bookingCount > 0) {
              return BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      tab.icon,
                      size: iconSize,
                      color:
                          isSelected
                              ? primaryColor
                              : (isDarkTheme
                                  ? Colors.white54
                                  : onSurface.withOpacity(0.5)),
                    ),
                    Positioned(
                      top: -12,
                      right: -13,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 3,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          bookingCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                label: isHindi ? tab.labelHi : tab.label,
              );
            }

            return BottomNavigationBarItem(
              icon: Icon(
                tab.icon,
                size: iconSize,
                color:
                    isSelected
                        ? primaryColor
                        : (isDarkTheme
                            ? Colors.white54
                            : onSurface.withOpacity(0.5)),
              ),
              label: isHindi ? tab.labelHi : tab.label,
            );
          }).toList(),
    );
  }
}

// ✅ Helper class for navigation items
class NavItem {
  final int index;
  final IconData icon;
  final String label;
  final String labelHi;
  final bool isBooking;

  const NavItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.labelHi,
    this.isBooking = false,
  });
}

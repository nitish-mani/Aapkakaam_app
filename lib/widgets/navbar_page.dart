// this file is made responsive .

import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:flutter/material.dart';

class NavbarPage extends StatefulWidget {
  const NavbarPage({super.key});

  @override
  State<NavbarPage> createState() => _NavbarPageState();
}

class _NavbarPageState extends State<NavbarPage> {
  // final messageCount = 0; // Example message count

  // Example message count
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isDarkThemeNotifier,
      builder: (context, isDarkTheme, _) {
        return ValueListenableBuilder(
          valueListenable: selectedPageNotifier,
          builder: (context, selectedIndex, _) {
            return ValueListenableBuilder(
              valueListenable: bookingIdNotifier,
              builder: (context, bookingIdNotifier, child) {
                return ValueListenableBuilder(
                  valueListenable: isVendor,
                  builder: (context, isVender, _) {
                    // Calculate icon size based on screen width
                    final iconSize = MediaQuery.of(context).size.width * 0.06;
                    // Calculate font size based on screen width
                    final fontSize = MediaQuery.of(context).size.width * 0.025;

                    return BottomNavigationBar(
                      type: BottomNavigationBarType.fixed,
                      currentIndex: selectedIndex,
                      backgroundColor:
                          isDarkTheme ? Colors.white : Colors.black,
                      unselectedItemColor:
                          isDarkTheme ? Colors.black : Colors.white,
                      selectedItemColor:
                          isDarkTheme ? Colors.teal : Colors.amber,
                      selectedLabelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize.clamp(10, 12), // Min 10, max 12
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize.clamp(8, 10), // Min 8, max 10
                      ),
                      onTap: (index) => selectedPageNotifier.value = index,
                      items: [
                        _buildNavItem(
                          icon: Icons.home,
                          label: 'Home',
                          iconSize: iconSize,
                        ),
                        if (isVender)
                          bookingCountNotifier.value > 0
                              ? BottomNavigationBarItem(
                                icon: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Icon(
                                      Icons.receipt_long,
                                      size: iconSize.clamp(20, 24),
                                    ), // Min 20, max 24
                                    Positioned(
                                      top: -16,
                                      right: -16,
                                      child: Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: BoxConstraints(
                                          minWidth: 20,
                                          minHeight: 20,
                                        ),
                                        child: Text(
                                          bookingCountNotifier.value.toString(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                label: 'Bookings',
                              )
                              : _buildNavItem(
                                icon: Icons.receipt_long,
                                label: 'Bookings',
                                iconSize: iconSize,
                              ),

                        _buildNavItem(
                          icon: Icons.list_alt,
                          label: 'Orders',
                          iconSize: iconSize,
                        ),
                        _buildNavItem(
                          icon: Icons.search,
                          label: 'Search',
                          iconSize: iconSize,
                        ),
                        _buildNavItem(
                          icon: Icons.share,
                          label: 'Share',
                          iconSize: iconSize,
                        ),
                        _buildNavItem(
                          icon: Icons.person,
                          label: 'Profile',
                          iconSize: iconSize,
                        ),
                      ],
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

  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required String label,
    required double iconSize,
  }) {
    return BottomNavigationBarItem(
      icon: Icon(icon, size: iconSize.clamp(20, 24)), // Min 20, max 24
      label: label,
    );
  }
}

// this file is made responsive for all devices using flutter_screenutil

import 'dart:convert';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/models/data_model.dart';
import 'package:app_aapkakaam/widgets/custom_card_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BodyPage extends StatefulWidget {
  const BodyPage({super.key});

  @override
  State<BodyPage> createState() => _BodyPageState();
}

class _BodyPageState extends State<BodyPage> {
  UserModel? user;
  VendorModel? vendor;

  final List<List<Map<String, String>>> allServiceCategories = [
    [
      {'image': 'assets/images/labour.jpg', 'title': 'Labour'},
      {'image': 'assets/images/mason.jpg', 'title': 'Mason'},
      {'image': 'assets/images/electrician.jpg', 'title': 'Electrician'},
      {'image': 'assets/images/plumber.jpg', 'title': 'Plumber'},
    ],
    [
      {'image': 'assets/images/ac_mechanic.jpg', 'title': 'AC Mechanic'},
      {
        'image': 'assets/images/fridge_mechanic.jpg',
        'title': 'Fridge Mechanic',
      },
      {'image': 'assets/images/driver.jpg', 'title': 'Driver'},
      {'image': 'assets/images/home_tutor.jpg', 'title': 'Home Tutor'},
    ],
    [
      {'image': 'assets/images/milk_man.jpg', 'title': 'Milk Man'},
      {'image': 'assets/images/parlour.jpg', 'title': 'Parlour'},
      {'image': 'assets/images/mehandi_maker.jpg', 'title': 'Mehandi Maker'},
      {'image': 'assets/images/pandit.jpg', 'title': 'Pandit Ji'},
    ],
    // Continue with all other categories...
    [
      {'image': 'assets/images/carpenter.jpg', 'title': 'Carpenter'},
      {'image': 'assets/images/laptop_repaire.jpg', 'title': 'Laptop Repair'},
      {'image': 'assets/images/washer_man.jpg', 'title': 'Washer Man'},
      {'image': 'assets/images/cook.jpg', 'title': 'Cook'},
    ],
    [
      {'image': 'assets/images/painter.jpg', 'title': 'Painter'},
      {'image': 'assets/images/bike_repaire.jpg', 'title': 'Bike Repair'},
      {'image': 'assets/images/car_repaire.jpg', 'title': 'Car Repair'},
      {'image': 'assets/images/tile_fitter.jpg', 'title': 'Tile Fitter'},
    ],
    [
      {'image': 'assets/images/car.jpg', 'title': 'Four Wheeler Booking'},
      {'image': 'assets/images/lights_booking.jpg', 'title': 'Lights Booking'},
      {'image': 'assets/images/tent.jpg', 'title': 'Tent House Booking'},
      {'image': 'assets/images/bus.jpg', 'title': 'Bus Booking'},
    ],
    [
      {'image': 'assets/images/auto.jpg', 'title': 'Auto Booking'},
      {'image': 'assets/images/generator.jpg', 'title': 'Generator Booking'},
      {'image': 'assets/images/dj.jpg', 'title': 'DJ Booking'},
      {'image': 'assets/images/dhankutti.jpg', 'title': 'Dhankutti Booking'},
    ],
    [
      {'image': 'assets/images/aata_chakki.jpg', 'title': 'Aata Chakki'},
      {
        'image': 'assets/images/latrine_tank_cleaner.jpg',
        'title': 'Latrine Tank Cleaner',
      },
      {
        'image': 'assets/images/marriage_hall.jpg',
        'title': 'Marriage Hall Booking',
      },
      {'image': 'assets/images/shuttering.jpg', 'title': 'Shuttering Booking'},
    ],
    [
      {'image': 'assets/images/waiters.jpg', 'title': 'Waiters Booking'},
      {'image': 'assets/images/marble_fitter.jpg', 'title': 'Marble Worker'},
      {'image': 'assets/images/e-rikshaw.jpg', 'title': 'E-Rikshaw Booking'},
      {
        'image': 'assets/images/pual_cutter.jpg',
        'title': 'Pual Cutter Booking',
      },
    ],
    [
      {'image': 'assets/images/ro.jpg', 'title': 'RO Water Booking'},
      {'image': 'assets/images/chaat.jpg', 'title': 'Chaat Booking'},
      {'image': 'assets/images/dulha_rath.jpg', 'title': 'Dulha Rath Booking'},
      {
        'image': 'assets/images/kirtan_mandali.jpg',
        'title': 'Kirtan Mandali Booking',
      },
    ],
    [
      {'image': 'assets/images/mini_truck.jpg', 'title': 'Mini Truck Booking'},
      {'image': 'assets/images/paan_wala.jpg', 'title': 'Paan Wala'},
      {'image': 'assets/images/fruits_seller.jpg', 'title': 'Fruits Seller'},
      {
        'image': 'assets/images/bhoonsa_pual_wala.jpg',
        'title': 'Bhoonsa Pual Seller',
      },
    ],
  ];

  // Category headings
  final List<String> categoryHeadings = [
    "Find & Book Trusted Local Services",
    "Book Your Service in Just a Few Clicks!",
    "Your One-Stop Solution for Daily Needs!",
    "Book Your Service in Just a Few Clicks!",
    "Hire Skilled Professionals & Book Essential Services",
    "Services at Your Fingertips",
    "The Smart Way to Hire Local Services!",
    "Reliable Help, Right Around the Corner!",
    "Hassle-Free Service Booking, Anytime!",
    "Trusted Professionals for Every Job!",
    "Quick, Reliable, and Affordable Services!",
  ];

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    final userData = prefs.getString('user');
    if (userData != null) {
      setState(() {
        user = UserModel.fromJson(jsonDecode(userData));
        isAddressAvailable.value = user?.address.isNotEmpty == true;
      });
    }

    final vendorData = prefs.getString('vendor');
    if (vendorData != null) {
      setState(() {
        vendor = VendorModel.fromJson(jsonDecode(vendorData));
        isWageRateAvailable.value = vendor?.wageRate != null;
        isAddressAvailable.value = vendor?.address.isNotEmpty == true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiNotifierBuilder(
      notifiers: [
        isDarkThemeNotifier,
        isAddressAvailable,
        isWageRateAvailable,
        isVendor,
      ],
      builder: (context, values, child) {
        final isDarkTheme = values[0] as bool;
        final isAddress = values[1] as bool;
        final isWageRate = values[2] as bool;
        final isVendor = values[3] as bool;

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            child: Column(
              children: [
                _buildWarningMessages(isVendor, isWageRate, isAddress),
                ...List.generate(
                  allServiceCategories.length,
                  (index) => _buildCategorySection(
                    categoryHeadings[index],
                    allServiceCategories[index],
                    isDarkTheme,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWarningMessages(bool isVendor, bool isWageRate, bool isAddress) {
    final List<String> warnings = [];

    if (isVendor) {
      if (!isWageRate) {
        warnings.add("Please add wage rate to make your profile visible");
      }
      if (!isAddress) {
        warnings.add("Please add address to make your profile visible");
      }
    } else if (!isAddress) {
      warnings.add("Please add address to avail services");
    }

    if (warnings.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        children:
            warnings.map((warning) => _buildWarningMessage(warning)).toList(),
      ),
    );
  }

  Widget _buildWarningMessage(String message) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4.r,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message,
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 14.sp,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCategorySection(
    String heading,
    List<Map<String, String>> imageData,
    bool isDarkTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            heading,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 8.h),
        CustomCardPage(
          imageData: imageData,
          cardColor: isDarkTheme ? Colors.white : Colors.black,
          cardFirstChildColor: isDarkTheme ? Colors.teal : Colors.amber,
          cardSecondChildColor: isDarkTheme ? Colors.black : Colors.white,
          isDarkTheme: isDarkTheme,
        ),
        SizedBox(height: 8.h),
      ],
    );
  }
}

// Same MultiNotifierBuilder — unchanged
class MultiNotifierBuilder extends StatelessWidget {
  final List<ValueNotifier> notifiers;
  final Widget Function(BuildContext, List<dynamic>, Widget?) builder;
  final Widget? child;

  const MultiNotifierBuilder({
    super.key,
    required this.notifiers,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _buildNestedListeners(0, context, [], child);
  }

  Widget _buildNestedListeners(
    int index,
    BuildContext context,
    List<dynamic> values,
    Widget? child,
  ) {
    if (index >= notifiers.length) {
      return builder(context, values, child);
    }

    return ValueListenableBuilder(
      valueListenable: notifiers[index],
      builder: (context, value, _) {
        final newValues = List<dynamic>.from(values)..add(value);
        return _buildNestedListeners(index + 1, context, newValues, child);
      },
    );
  }
}

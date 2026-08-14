// this file is made responsive for all devices using flutter_screenutil

import 'dart:convert';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/models/data_model.dart';
import 'package:app_aapkakaam/widgets/banner_ad_widget.dart';
import 'package:app_aapkakaam/widgets/custom_card_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Service Data Structure
class ServiceItem {
  final String title;
  final String hindi;
  final String image;
  final String jobType;

  ServiceItem({
    required this.title,
    required this.hindi,
    required this.image,
    required this.jobType,
  });

  Map<String, String> toMap() {
    return {'title': title, 'hindi': hindi, 'image': image, 'jobType': jobType};
  }
}

class ServiceCategory {
  final String heading;
  final String headingHindi;
  final List<ServiceItem> services;

  ServiceCategory({
    required this.heading,
    required this.headingHindi,
    required this.services,
  });
}

// Service Data
final List<ServiceCategory> serviceData = [
  ServiceCategory(
    heading: "Construction & Work",
    headingHindi: "निर्माण कार्य",
    services: [
      ServiceItem(
        title: "Labour",
        hindi: "मजदूर",
        image: "assets/images/labour.png",
        jobType: "labour",
      ),
      ServiceItem(
        title: "Mason",
        hindi: "राजमिस्त्री",
        image: "assets/images/mason.jpg",
        jobType: "mason",
      ),
      ServiceItem(
        title: "Electrician",
        hindi: "बिजली मिस्त्री",
        image: "assets/images/electrician.jpg",
        jobType: "electrician",
      ),
      ServiceItem(
        title: "Plumber",
        hindi: "प्लंबर",
        image: "assets/images/plumber.jpg",
        jobType: "plumber",
      ),
      ServiceItem(
        title: "Painter",
        hindi: "पेंटर",
        image: "assets/images/painter.jpg",
        jobType: "painter",
      ),
      ServiceItem(
        title: "Carpenter",
        hindi: "बढ़ई",
        image: "assets/images/carpenter.jpg",
        jobType: "carpenter",
      ),
      ServiceItem(
        title: "Tiles Fitter",
        hindi: "टाइल मिस्त्री",
        image: "assets/images/tile_fitter.jpg",
        jobType: "tiles fitter",
      ),
      ServiceItem(
        title: "Marble Fitter",
        hindi: "मार्बल मिस्त्री",
        image: "assets/images/marble_fitter.jpg",
        jobType: "marble fitter",
      ),
      ServiceItem(
        title: "Shuttering",
        hindi: "शटरिंग बुकिंग",
        image: "assets/images/shuttering.jpg",
        jobType: "shuttering",
      ),
    ],
  ),
  ServiceCategory(
    heading: "Repair",
    headingHindi: "मरम्मत सेवा",
    services: [
      ServiceItem(
        title: "AC Mechanic",
        hindi: "एसी मिस्त्री",
        image: "assets/images/ac_mechanic.jpg",
        jobType: "ac mechanic",
      ),
      ServiceItem(
        title: "Fridge Mechanic",
        hindi: "फ्रिज मिस्त्री",
        image: "assets/images/fridge_mechanic.jpg",
        jobType: "fridge mechanic",
      ),
      ServiceItem(
        title: "Bike Repair",
        hindi: "बाइक रिपेयर",
        image: "assets/images/bike_repaire.jpg",
        jobType: "bike repaire",
      ),
      ServiceItem(
        title: "Car Repair",
        hindi: "कार रिपेयर",
        image: "assets/images/car_repaire.jpg",
        jobType: "car repaire",
      ),
      ServiceItem(
        title: "Laptop Repair",
        hindi: "लैपटॉप रिपेयर",
        image: "assets/images/laptop_repaire.jpg",
        jobType: "laptop repaire",
      ),
    ],
  ),
  ServiceCategory(
    heading: "Daily Need",
    headingHindi: "दैनिक आवश्यकता",
    services: [
      ServiceItem(
        title: "Driver",
        hindi: "ड्राइवर",
        image: "assets/images/driver.jpg",
        jobType: "driver",
      ),
      ServiceItem(
        title: "Home Tutor",
        hindi: "होम ट्यूटर",
        image: "assets/images/home_tutor.jpg",
        jobType: "home tutor",
      ),
      ServiceItem(
        title: "Milk Man",
        hindi: "दूध वाला",
        image: "assets/images/milk_man.jpg",
        jobType: "milk man",
      ),
      ServiceItem(
        title: "Washer Man",
        hindi: "धोबी",
        image: "assets/images/washer_man.jpg",
        jobType: "washer man",
      ),
    ],
  ),
  ServiceCategory(
    heading: "Function",
    headingHindi: "कार्यक्रम सेवा",
    services: [
      ServiceItem(
        title: "Parlour",
        hindi: "पार्लर",
        image: "assets/images/parlour.jpg",
        jobType: "parlour",
      ),
      ServiceItem(
        title: "Mehandi Maker",
        hindi: "मेहंदी कलाकार",
        image: "assets/images/mehandi_maker.jpg",
        jobType: "menhandi maker",
      ),
      ServiceItem(
        title: "Pandit Ji",
        hindi: "पंडित जी",
        image: "assets/images/pandit.jpg",
        jobType: "pundit ji",
      ),
      ServiceItem(
        title: "Cook",
        hindi: "रसोइया",
        image: "assets/images/cook.jpg",
        jobType: "cook",
      ),
      ServiceItem(
        title: "Lights",
        hindi: "लाइट बुकिंग",
        image: "assets/images/lights_booking.jpg",
        jobType: "lights",
      ),
      ServiceItem(
        title: "Tent House",
        hindi: "टेंट हाउस",
        image: "assets/images/tent.jpg",
        jobType: "tent house",
      ),
      ServiceItem(
        title: "Kirtan Mandali",
        hindi: "कीर्तन मंडली",
        image: "assets/images/kirtan_mandali.jpg",
        jobType: "kirtan mandli",
      ),
      ServiceItem(
        title: "Generator",
        hindi: "जनरेटर",
        image: "assets/images/generator.jpg",
        jobType: "generator",
      ),
      ServiceItem(
        title: "DJ",
        hindi: "डीजे",
        image: "assets/images/dj.jpg",
        jobType: "dj",
      ),
      ServiceItem(
        title: "Waiter",
        hindi: "वेटर",
        image: "assets/images/waiters.jpg",
        jobType: "waiter",
      ),
      ServiceItem(
        title: "RO",
        hindi: "आरओ पानी",
        image: "assets/images/ro.jpg",
        jobType: "ro",
      ),
      ServiceItem(
        title: "Chaat",
        hindi: "चाट",
        image: "assets/images/chaat.jpg",
        jobType: "chaat",
      ),
      ServiceItem(
        title: "Dulha Rath",
        hindi: "दूल्हा रथ",
        image: "assets/images/dulha_rath.jpg",
        jobType: "dulha rath",
      ),
      ServiceItem(
        title: "Paan Wala",
        hindi: "पान वाला",
        image: "assets/images/paan_wala.jpg",
        jobType: "paan wala",
      ),
      ServiceItem(
        title: "Fruits Seller",
        hindi: "फल विक्रेता",
        image: "assets/images/fruits_seller.jpg",
        jobType: "fruit seller",
      ),
      ServiceItem(
        title: "Marriage Hall",
        hindi: "मैरिज हॉल",
        image: "assets/images/marriage_hall.jpg",
        jobType: "marriage hall",
      ),
    ],
  ),
  ServiceCategory(
    heading: "Transportation",
    headingHindi: "परिवहन सेवा",
    services: [
      ServiceItem(
        title: "Four Wheeler",
        hindi: "चार पहिया",
        image: "assets/images/car.jpg",
        jobType: "four wheeler",
      ),
      ServiceItem(
        title: "Bus",
        hindi: "बस",
        image: "assets/images/bus.jpg",
        jobType: "bus",
      ),
      ServiceItem(
        title: "Auto",
        hindi: "ऑटो",
        image: "assets/images/auto.jpg",
        jobType: "auto",
      ),
      ServiceItem(
        title: "E-Rikshaw",
        hindi: "ई-रिक्शा",
        image: "assets/images/e-rikshaw.jpg",
        jobType: "e-riksha",
      ),
      ServiceItem(
        title: "Mini Truck",
        hindi: "मिनी ट्रक",
        image: "assets/images/mini_truck.jpg",
        jobType: "mini truck",
      ),
    ],
  ),
  ServiceCategory(
    heading: "Rural Work",
    headingHindi: "ग्रामीण सेवाएँ",
    services: [
      ServiceItem(
        title: "Dhankutti",
        hindi: "धान कुट्टी",
        image: "assets/images/dhankutti.jpg",
        jobType: "dhankutti",
      ),
      ServiceItem(
        title: "Aata Chakki",
        hindi: "आटा चक्की",
        image: "assets/images/aata_chakki.jpg",
        jobType: "aata chakki",
      ),
      ServiceItem(
        title: "Latrine Tank Cleaner",
        hindi: "शौचालय टैंक सफाई",
        image: "assets/images/latrine_tank_cleaner.jpg",
        jobType: "latrine tank cleaner",
      ),
      ServiceItem(
        title: "Pual Cutter",
        hindi: "पुआल कटर",
        image: "assets/images/pual_cutter.jpg",
        jobType: "pual cutter",
      ),
      ServiceItem(
        title: "Bhoonsa Pual Seller",
        hindi: "भूसा विक्रेता",
        image: "assets/images/bhoonsa_pual_wala.jpg",
        jobType: "bhoonsa pual seller",
      ),
    ],
  ),
];

class BodyPage extends StatefulWidget {
  const BodyPage({super.key});

  @override
  State<BodyPage> createState() => _BodyPageState();
}

class _BodyPageState extends State<BodyPage>
    with AutomaticKeepAliveClientMixin {
  UserModel? user;
  VendorModel? vendor;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    final userData = prefs.getString('user');
    final vendorData = prefs.getString('vendor');
    setState(() {
      if (userData != null) {
        user = UserModel.fromJson(jsonDecode(userData));
        isAddressAvailable.value = user?.address.isNotEmpty == true;
      }
      if (vendorData != null) {
        vendor = VendorModel.fromJson(jsonDecode(vendorData));
        isWageRateAvailable.value = vendor?.wageRate != null;
        isAddressAvailable.value = vendor?.address.isNotEmpty == true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                  serviceData.length,
                  (index) => _buildCategorySection(
                    serviceData[index],
                    isDarkTheme,
                    index,
                  ),
                ),
                SizedBox(height: 16.h),
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
    ServiceCategory category,
    bool isDarkTheme,
    int index,
  ) {
    // Convert ServiceItem to Map<String, String> for CustomCardPage
    final List<Map<String, String>> imageData =
        category.services
            .map(
              (service) => {
                'image': service.image,
                'title': service.title,
                'hindi': service.hindi,
                'jobType': service.jobType,
              },
            )
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (index % 2 == 0) Center(child: BannerAdWidget()),
        if (index % 2 == 0) SizedBox(height: 8.h),
        Center(
          child: Text(
            category.heading,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
              color: isDarkTheme ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 4.h),
        Center(
          child: Text(
            category.headingHindi,
            style: TextStyle(
              fontSize: 12.sp,
              color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
            ),
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
        SizedBox(height: 16.h),
      ],
    );
  }
}

// MultiNotifierBuilder - unchanged
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

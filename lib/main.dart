import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/navBarWidgets/home_page.dart';
import 'package:app_aapkakaam/widgets/firebase_notification.dart';
import 'package:app_aapkakaam/widgets/version_checker.dart';
import 'package:app_aapkakaam/widgets/welcome_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// ✅ ADD THIS BACKGROUND HANDLER
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  FirebaseNotifications.setNotificationCount(message.data);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  // await FirebaseNotifications.initialize();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.white30,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((
    _,
  ) {
    runApp(const MyApp());
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    themeMode();
  }

  void themeMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool? repeat = prefs.getBool(KConstant.themeModeKey);
    final bool? isVendor1 = prefs.getBool("isVendor");
    final String? isLoggedInValue = prefs.getString("isLoggedIn");
    isDarkThemeNotifier.value = repeat ?? false;
    isVendor.value = isVendor1 ?? false;
    isLoggedIn.value = isLoggedInValue == "true" ? true : false;
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return ValueListenableBuilder(
          valueListenable: isDarkThemeNotifier,
          builder: (context, isDarkTheme, child) {
            return ValueListenableBuilder(
              valueListenable: isLoggedIn,
              builder: (context, isLoggedIn, child) {
                return ValueListenableBuilder(
                  valueListenable: isVendor,
                  builder: (context, value, child) {
                    return MaterialApp(
                      debugShowCheckedModeBanner: false,
                      title: 'Aapkakaam',
                      theme: ThemeData(
                        colorScheme: ColorScheme.fromSeed(
                          seedColor: Colors.blue,
                          brightness:
                              isDarkTheme ? Brightness.dark : Brightness.light,
                        ),
                      ),
                      home: VersionChecker(
                        child:
                            isLoggedIn ? const HomePage() : const WelcomePage(),
                      ),
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
}

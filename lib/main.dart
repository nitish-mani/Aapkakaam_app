import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/navBarWidgets/home_page.dart';
import 'package:app_aapkakaam/widgets/firebase_notification.dart';
import 'package:app_aapkakaam/widgets/version_checker.dart';
import 'package:app_aapkakaam/widgets/welcome_page.dart';
import 'package:app_aapkakaam/widgets/notification_permission_gate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // Firebase Initialization
  // ============================================================
  await Firebase.initializeApp();

  // Register background FCM handler before runApp()
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // ============================================================
  // Google Mobile Ads
  // ============================================================
  await MobileAds.instance.initialize();

  // ============================================================
  // Orientation Lock
  // ============================================================
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ============================================================
  // Firebase Notifications
  // ============================================================
  await FirebaseNotifications.initialize();

  // ============================================================
  // Start Application
  // ============================================================
  runApp(const MyApp());
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
    _loadThemeAndUserPreferences();
  }

  Future<void> _loadThemeAndUserPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final bool? themeMode = prefs.getBool(KConstant.themeModeKey);
    final bool? isVendorValue = prefs.getBool("isVendor");
    final String? isLoggedInValue = prefs.getString("isLoggedIn");

    isDarkThemeNotifier.value = themeMode ?? false;
    isVendor.value = isVendorValue ?? false;
    isLoggedIn.value = isLoggedInValue == "true";
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
          builder: (context, isDarkTheme, _) {
            return ValueListenableBuilder(
              valueListenable: isLoggedIn,
              builder: (context, loggedIn, _) {
                return ValueListenableBuilder(
                  valueListenable: isVendor,
                  builder: (context, vendor, _) {
                    return MaterialApp(
                      debugShowCheckedModeBanner: false,
                      title: 'AapKaKaam',
                      navigatorKey: navigatorKey,

                      theme: _buildLightTheme(),
                      darkTheme: _buildDarkTheme(),
                      themeMode: isDarkTheme ? ThemeMode.dark : ThemeMode.light,

                      builder: (context, child) {
                        final theme = Theme.of(context);
                        final isDark = theme.brightness == Brightness.dark;

                        SystemChrome.setSystemUIOverlayStyle(
                          SystemUiOverlayStyle(
                            // TOP: Time, network, battery area
                            statusBarColor: const Color(0xFF4A00E0),

                            // BOTTOM: Android navigation/gesture area
                            systemNavigationBarColor: theme.colorScheme.primary,

                            // Top icons/text
                            statusBarIconBrightness: Brightness.dark,

                            // Bottom navigation icons/gesture
                            systemNavigationBarIconBrightness:
                                isDark ? Brightness.light : Brightness.light,

                            // Android navigation divider
                            systemNavigationBarDividerColor:
                                theme.colorScheme.primary,
                          ),
                        );

                        return child!;
                      },

                      home: NotificationPermissionGate(
                        child: VersionChecker(
                          apiBaseUrl: KConstantURL.url,
                          child:
                              loggedIn ? const HomePage() : const WelcomePage(),
                        ),
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

  // ============================================================
  // Premium Light Theme
  // ============================================================
  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF4A00E0),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF4A00E0),
        secondary: Color(0xFF8E2DE2),
        tertiary: Color(0xFF6A11CB),
        surface: Colors.white,
        background: Color(0xFFF8F9FE),
        error: Color(0xFFE74C3C),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: Color(0xFF1A1A2E),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F9FE),
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        color: Colors.white,
        shadowColor: const Color(0xFF4A00E0).withOpacity(0.1),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          shadowColor: const Color(0xFF4A00E0).withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(
            color: const Color(0xFF4A00E0).withOpacity(0.2),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(color: Color(0xFF4A00E0), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32.sp,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1A1A2E),
        ),
        displayMedium: TextStyle(
          fontSize: 28.sp,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1A1A2E),
        ),
        displaySmall: TextStyle(
          fontSize: 24.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A1A2E),
        ),
        headlineMedium: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A1A2E),
        ),
        bodyLarge: TextStyle(fontSize: 16.sp, color: const Color(0xFF2D2D44)),
        bodyMedium: TextStyle(fontSize: 14.sp, color: const Color(0xFF4A4A6A)),
        bodySmall: TextStyle(fontSize: 12.sp, color: const Color(0xFF6A6A8A)),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF4A00E0), size: 24),
      dividerTheme: DividerThemeData(
        color: const Color(0xFF4A00E0).withOpacity(0.1),
        thickness: 1,
        space: 20.h,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF4A00E0).withOpacity(0.1),
        labelStyle: TextStyle(color: const Color(0xFF4A00E0), fontSize: 12.sp),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  // ============================================================
  // Premium Dark Theme
  // ============================================================
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF6A11CB),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF6A11CB),
        secondary: Color(0xFF8E2DE2),
        tertiary: Color(0xFF4A00E0),
        surface: Color(0xFF1A1A2E),
        background: Color(0xFF0F0F1A),
        error: Color(0xFFE74C3C),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F0F1A),
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        color: const Color(0xFF1A1A2E),
        shadowColor: const Color(0xFF6A11CB).withOpacity(0.2),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          shadowColor: const Color(0xFF6A11CB).withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A1A2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(
            color: const Color(0xFF6A11CB).withOpacity(0.3),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(color: Color(0xFF6A11CB), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displayMedium: TextStyle(
          fontSize: 28.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displaySmall: TextStyle(
          fontSize: 24.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(fontSize: 16.sp, color: const Color(0xFFCCCCE6)),
        bodyMedium: TextStyle(fontSize: 14.sp, color: const Color(0xFF9999B3)),
        bodySmall: TextStyle(fontSize: 12.sp, color: const Color(0xFF666680)),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF6A11CB), size: 24),
      dividerTheme: DividerThemeData(
        color: const Color(0xFF6A11CB).withOpacity(0.2),
        thickness: 1,
        space: 20.h,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF6A11CB).withOpacity(0.2),
        labelStyle: TextStyle(color: const Color(0xFF8E2DE2), fontSize: 12.sp),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }
}

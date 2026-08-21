import 'dart:async';
import 'dart:convert';

import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/models/data_model.dart';
import 'package:app_aapkakaam/models/card_model.dart';
import 'package:app_aapkakaam/widgets/banner_ad_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:app_aapkakaam/widgets/firebase_notification.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  _BookingsPageState createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  // ============================================================
  // STATE
  // ============================================================

  Future<List<BookingsCard>>? futureCards;

  int bookingsDetails = bookingStatusNotifier.value;

  VendorModel? vendor;

  DateTime selectedDate = DateTime.now();

  late Map<String, bool> isLoading;

  late Map<String, bool> isPermissionGranted;

  final ScrollController _scrollController = ScrollController();

  VoidCallback? _refreshListener;

  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;

  VoidCallback? _pendingNotificationListener;

  // ============================================================
  // NOTIFICATION NAVIGATION
  // ============================================================

  String? _pendingNotificationBookingId;

  bool _notificationNavigationInProgress = false;

  bool _highlightNotificationBooking = false;

  String? _highlightedBookingId;

  final Map<String, GlobalKey> _bookingKeys = {};

  Timer? _highlightTimer;

  // ============================================================
  // COUNTERS
  // ============================================================

  int newMessageCountPending = 0;

  int newMessageCountComplete = 0;

  int newMessageCountCanceled = 0;

  final bookingCountBySameDate = <String, int>{};

  // ============================================================
  // CALENDAR
  // ============================================================

  bool _isCalendarExpanded = true;

  double _lastScrollOffset = 0;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    isLoading = {};

    isPermissionGranted = {};

    _setupRefreshListener();

    loadUserData();

    // ==========================================================
    // Notification click listener
    // ==========================================================

    _notificationSubscription = FirebaseNotifications.notificationClickStream
        .listen((data) {
          _handleNotificationClick(data);
        });

    // ==========================================================
    // Pending notification listener
    // ==========================================================

    _pendingNotificationListener = () {
      final bookingId = pendingNotificationBookingIdNotifier.value;

      if (bookingId == null || bookingId.isEmpty) {
        return;
      }

      _pendingNotificationBookingId = bookingId;

      _tryOpenPendingNotificationBooking();
    };

    pendingNotificationBookingIdNotifier.addListener(
      _pendingNotificationListener!,
    );

    // ==========================================================
    // Scroll listener
    // ==========================================================

    _scrollController.addListener(_handleScroll);

    // ==========================================================
    // If notification arrived before
    // BookingsPage was created
    // ==========================================================

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookingId = pendingNotificationBookingIdNotifier.value;

      if (bookingId != null && bookingId.isNotEmpty) {
        _pendingNotificationBookingId = bookingId;

        _tryOpenPendingNotificationBooking();
      }
    });
  }

  // ============================================================
  // SCROLL
  // ============================================================

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final currentOffset = _scrollController.offset;

    if (currentOffset <= 0) {
      if (!_isCalendarExpanded) {
        setState(() {
          _isCalendarExpanded = true;
        });

        isCalendarCollapsedNotifier.value = false;
      }
    } else if (currentOffset > _lastScrollOffset && currentOffset > 100) {
      if (_isCalendarExpanded) {
        setState(() {
          _isCalendarExpanded = false;
        });

        isCalendarCollapsedNotifier.value = true;
      }
    }

    _lastScrollOffset = currentOffset;
  }

  // ============================================================
  // NOTIFICATION CLICK
  // ============================================================

  void _handleNotificationClick(Map<String, dynamic> data) {
    debugPrint('BookingsPage notification clicked: $data');

    try {
      final type = data['type']?.toString();
      final notificationType = data['notificationType']?.toString();

      final bookingId = data['bookingId']?.toString() ?? data['id']?.toString();

      debugPrint('Notification type: $type');
      debugPrint('Notification notificationType: $notificationType');
      debugPrint('Notification bookingId: $bookingId');

      // IMPORTANT:
      // Set the exact notification month/year BEFORE
      // fetching bookings.
      final hasCalendarDate = _setMonthYearFromNotification(data);

      // ========================================================
      // BOOKING CREATED / NEW BOOKING / BOOKING CONFIRMED
      // ========================================================

      if (type == 'booking' ||
          notificationType == 'new_booking' ||
          notificationType == 'booking_confirmed') {
        selectedPageNotifier.value = isVendor.value ? 1 : 2;

        bookingStatusNotifier.value = 1;
        bookingsDetails = 1;

        if (bookingId != null && bookingId.isNotEmpty) {
          _setPendingNotificationBooking(bookingId);
        }

        _reloadBookingsForNotification(data, forceMonthYear: hasCalendarDate);

        return;
      }

      // ========================================================
      // BOOKING CANCELLED
      // ========================================================

      if (type == 'cancelled' || notificationType == 'booking_cancelled') {
        selectedPageNotifier.value = isVendor.value ? 1 : 2;

        bookingStatusNotifier.value = 3;
        bookingsDetails = 3;

        if (bookingId != null && bookingId.isNotEmpty) {
          _setPendingNotificationBooking(bookingId);
        }

        _reloadBookingsForNotification(data, forceMonthYear: hasCalendarDate);

        return;
      }

      // ========================================================
      // BOOKING COMPLETED
      // ========================================================

      if (type == 'completed' || notificationType == 'booking_completed') {
        selectedPageNotifier.value = isVendor.value ? 1 : 2;

        bookingStatusNotifier.value = 2;
        bookingsDetails = 2;

        if (bookingId != null && bookingId.isNotEmpty) {
          _setPendingNotificationBooking(bookingId);
        }

        _reloadBookingsForNotification(data, forceMonthYear: hasCalendarDate);

        return;
      }

      // ========================================================
      // PROFILE
      // ========================================================

      if (type == 'profile_update' || data['screen']?.toString() == 'profile') {
        profileRefreshNotifier.value = !profileRefreshNotifier.value;

        return;
      }
    } catch (error, stackTrace) {
      debugPrint('Notification click handling error: $error');

      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // ============================================================
  // SET MONTH/YEAR FROM NOTIFICATION
  // ============================================================

  bool _setMonthYearFromNotification(Map<String, dynamic> data) {
    try {
      // Backend sends JavaScript month:
      //
      // January  = 0
      // February = 1
      // ...
      // December = 11
      int? backendMonth = int.tryParse(data['month']?.toString() ?? '');

      int? notificationYear = int.tryParse(data['year']?.toString() ?? '');

      // ========================================================
      // FALLBACK TO bookingDate
      // ========================================================

      if (backendMonth == null || notificationYear == null) {
        final bookingDateString = data['bookingDate']?.toString();

        if (bookingDateString != null && bookingDateString.isNotEmpty) {
          final parsedDate = DateTime.tryParse(bookingDateString);

          if (parsedDate != null) {
            backendMonth = parsedDate.month - 1;

            notificationYear = parsedDate.year;

            debugPrint(
              'Notification month/year '
              'extracted from bookingDate',
            );
          }
        }
      }

      // ========================================================
      // VALIDATE
      // ========================================================

      if (backendMonth == null || notificationYear == null) {
        debugPrint('Notification month/year missing');

        debugPrint('Notification data: $data');

        return false;
      }

      if (backendMonth < 0 || backendMonth > 11) {
        debugPrint(
          'Invalid backend month: '
          '$backendMonth',
        );

        return false;
      }

      if (notificationYear < 2000 || notificationYear > 2100) {
        debugPrint(
          'Invalid notification year: '
          '$notificationYear',
        );

        return false;
      }

      // ========================================================
      // JAVASCRIPT MONTH → FLUTTER MONTH
      // ========================================================

      final flutterMonth = backendMonth + 1;

      // ========================================================
      // UPDATE GLOBAL CALENDAR STATE
      // ========================================================

      monthNotifier.value = flutterMonth;

      yearNotifier.value = notificationYear;

      selectedDate = DateTime(notificationYear, flutterMonth, 1);

      debugPrint('========================================');

      debugPrint('Notification calendar target');

      debugPrint('Backend month: $backendMonth');

      debugPrint('Flutter month: $flutterMonth');

      debugPrint('Year: $notificationYear');

      debugPrint(
        'Selected date: '
        '${selectedDate.month}/'
        '${selectedDate.year}',
      );

      debugPrint('========================================');

      if (mounted) {
        setState(() {});
      }

      return true;
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to set notification month/year: '
        '$error',
      );

      debugPrintStack(stackTrace: stackTrace);

      return false;
    }
  }

  // ============================================================
  // RELOAD BOOKINGS FOR NOTIFICATION
  // ============================================================

  void _reloadBookingsForNotification(
    Map<String, dynamic> data, {
    required bool forceMonthYear,
  }) {
    // User notifications go to OrdersPage.
    // Do not call vendor/getBookings for users.
    if (!isVendor.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _tryOpenPendingNotificationBooking();
        }
      });

      return;
    }

    final targetMonth =
        forceMonthYear ? monthNotifier.value : selectedDate.month;

    final targetYear = forceMonthYear ? yearNotifier.value : selectedDate.year;

    // ==========================================================
    // VALIDATE
    // ==========================================================

    if (targetMonth < 1 || targetMonth > 12) {
      debugPrint(
        'Invalid target month: '
        '$targetMonth',
      );

      return;
    }

    if (targetYear < 2000 || targetYear > 2100) {
      debugPrint(
        'Invalid target year: '
        '$targetYear',
      );

      return;
    }

    // ==========================================================
    // VENDOR NOT LOADED YET
    // ==========================================================

    if (vendor == null) {
      debugPrint(
        'Vendor not loaded yet. '
        'Loading target month...',
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          loadUserData(
            notificationMonth: targetMonth,
            notificationYear: targetYear,
          );
        }
      });

      return;
    }

    final currentVendor = vendor!;

    if (!mounted) {
      return;
    }

    // ==========================================================
    // FETCH EXACT MONTH
    // ==========================================================

    setState(() {
      selectedDate = DateTime(targetYear, targetMonth, 1);

      futureCards = fetchBookings(
        currentVendor.vendorId,

        // Backend expects JS month:
        // January = 0
        // February = 1
        // ...
        // December = 11
        targetMonth - 1,

        targetYear,

        'Bearer ${currentVendor.token}',
      );
    });

    debugPrint(
      'Notification booking fetch started: '
      'month=$targetMonth '
      'year=$targetYear',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryOpenPendingNotificationBooking();
    });
  }

  // ============================================================
  // BACKWARD COMPATIBILITY
  // ============================================================

  void _setVendorMonthFromNotification(Map<String, dynamic> data) {
    final hasDate = _setMonthYearFromNotification(data);

    _reloadBookingsForNotification(data, forceMonthYear: hasDate);
  }

  void _setPendingNotificationBooking(String bookingId) {
    if (bookingId.isEmpty) {
      return;
    }

    debugPrint(
      'Pending notification booking: '
      '$bookingId',
    );

    _pendingNotificationBookingId = bookingId;

    pendingNotificationBookingIdNotifier.value = bookingId;

    // Give the page time to switch tabs
    // and start fetching the correct month.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryOpenPendingNotificationBooking();
    });
  }

  // ============================================================
  // TRY OPEN BOOKING
  // ============================================================

  void _tryOpenPendingNotificationBooking() {
    if (!mounted) {
      return;
    }

    if (_notificationNavigationInProgress) {
      return;
    }

    final bookingId =
        _pendingNotificationBookingId ??
        pendingNotificationBookingIdNotifier.value;

    if (bookingId == null || bookingId.isEmpty) {
      return;
    }

    // Future not created yet.
    if (futureCards == null) {
      debugPrint('Waiting for bookings Future...');

      return;
    }

    _notificationNavigationInProgress = true;

    final currentFuture = futureCards!;

    currentFuture.then(
      (bookings) async {
        if (!mounted) {
          _notificationNavigationInProgress = false;

          return;
        }

        // ------------------------------------------------------
        // Filter according to current tab
        // ------------------------------------------------------

        final filteredBookings = _filterBookingsByStatus(bookings);

        final index = filteredBookings.indexWhere(
          (booking) => booking.id == bookingId,
        );

        if (index == -1) {
          debugPrint(
            'Booking $bookingId not found '
            'in current status/month',
          );

          _notificationNavigationInProgress = false;

          return;
        }

        debugPrint(
          'Found notification booking '
          '$bookingId at index $index',
        );

        // ------------------------------------------------------
        // Highlight
        // ------------------------------------------------------

        _highlightedBookingId = bookingId;

        _highlightNotificationBooking = true;

        if (mounted) {
          setState(() {});
        }

        // ------------------------------------------------------
        // Wait for ListView to build
        // ------------------------------------------------------

        await Future.delayed(const Duration(milliseconds: 150));

        await _scrollToBooking(bookingId);

        // ------------------------------------------------------
        // Keep highlight for 3 seconds
        // ------------------------------------------------------

        _highlightTimer?.cancel();

        _highlightTimer = Timer(const Duration(seconds: 3), () {
          if (!mounted) {
            return;
          }

          setState(() {
            _highlightNotificationBooking = false;

            _highlightedBookingId = null;
          });
        });

        // ------------------------------------------------------
        // Clear pending notification
        // ------------------------------------------------------

        _pendingNotificationBookingId = null;

        if (pendingNotificationBookingIdNotifier.value == bookingId) {
          pendingNotificationBookingIdNotifier.value = null;
        }

        _notificationNavigationInProgress = false;
      },
      onError: (error) {
        debugPrint(
          'Failed to process notification booking: '
          '$error',
        );

        _notificationNavigationInProgress = false;
      },
    );
  }

  // ============================================================
  // SCROLL TO EXACT BOOKING
  // ============================================================

  Future<void> _scrollToBooking(String bookingId) async {
    if (!mounted) {
      return;
    }

    final key = _bookingKeys[bookingId];

    if (key == null) {
      debugPrint(
        'No GlobalKey found for booking '
        '$bookingId',
      );

      return;
    }

    final targetContext = key.currentContext;

    if (targetContext == null) {
      debugPrint(
        'Booking widget not built yet: '
        '$bookingId',
      );

      // Try again after another frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToBooking(bookingId);
        }
      });

      return;
    }

    try {
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        alignment: 0.2,
      );

      debugPrint('Scrolled to booking $bookingId');
    } catch (error) {
      debugPrint(
        'Failed to scroll to booking: '
        '$error',
      );
    }
  }

  // ============================================================
  // BOOKING GLOBAL KEY
  // ============================================================

  GlobalKey _getBookingKey(String bookingId) {
    return _bookingKeys.putIfAbsent(bookingId, () => GlobalKey());
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    if (_refreshListener != null) {
      bookingsRefreshNotifier.removeListener(_refreshListener!);
    }

    if (_notificationSubscription != null) {
      _notificationSubscription!.cancel();
    }

    if (_pendingNotificationListener != null) {
      pendingNotificationBookingIdNotifier.removeListener(
        _pendingNotificationListener!,
      );
    }

    _highlightTimer?.cancel();

    _scrollController.removeListener(_handleScroll);

    _scrollController.dispose();

    _bookingKeys.clear();

    super.dispose();
  }

  // ============================================================
  // REFRESH LISTENER
  // ============================================================

  void _setupRefreshListener() {
    _refreshListener = () {
      if (!mounted) {
        return;
      }

      final targetMonth =
          monthNotifier.value >= 1 && monthNotifier.value <= 12
              ? monthNotifier.value
              : selectedDate.month;

      final targetYear =
          yearNotifier.value >= 2000 ? yearNotifier.value : selectedDate.year;

      setState(() {
        selectedDate = DateTime(targetYear, targetMonth, 1);

        bookingsDetails = bookingStatusNotifier.value;
      });

      loadUserData(
        notificationMonth: targetMonth,
        notificationYear: targetYear,
      );
    };

    bookingsRefreshNotifier.addListener(_refreshListener!);
  }

  // ============================================================
  // BOOKING STATUS
  // ============================================================

  bool? getBookingStatus(String? id) {
    return id == null ? null : bookingIdNotifier.value[id];
  }

  void upsertBooking(String id, bool value) {
    bookingIdNotifier.value = {...bookingIdNotifier.value, id: value};
  }

  // ============================================================
  // INITIALIZE LOADING STATE
  // ============================================================

  void initializeIsLoadingFromResponse(List<BookingsCard> bookings) {
    final validBookings = bookings.where((b) => b.id.isNotEmpty).toList();

    isPermissionGranted = {
      for (var booking in validBookings) booking.id: false,
    };

    isLoading = {for (var booking in validBookings) booking.id: false};

    final updatedBookingIds = {...bookingIdNotifier.value};

    for (final booking in validBookings) {
      updatedBookingIds[booking.id] = updatedBookingIds[booking.id] ?? false;
    }

    bookingIdNotifier.value = updatedBookingIds;

    if (mounted) {
      setState(() {
        final bookingCategories = calculateBookingCategories(validBookings);

        newMessageCountPending = bookingCategories['pending']!;

        newMessageCountComplete = bookingCategories['completed']!;

        newMessageCountCanceled = bookingCategories['canceled']!;
      });
    }
  }

  // ============================================================
  // LOADING STATE
  // ============================================================

  void updateLoadingState(String id, bool value) {
    if (isLoading.containsKey(id)) {
      isLoading[id] = value;
    }
  }

  void updatePermissionState(String id, bool value) {
    if (isPermissionGranted.containsKey(id)) {
      isPermissionGranted[id] = value;
    }
  }

  // ============================================================
  // LOAD VENDOR FROM NOTIFICATION
  // ============================================================

  Future<void> loadUserDataFromNotification(int month, int year) async {
    final prefs = await SharedPreferences.getInstance();

    final vendorData = prefs.getString('vendor');

    if (vendorData != null) {
      final decodedVendor = jsonDecode(vendorData);

      vendor = VendorModel.fromJson(decodedVendor);

      if (!mounted) {
        return;
      }

      setState(() {
        futureCards = fetchBookings(
          decodedVendor['vendorId'],
          month - 1,
          year,
          'Bearer ${decodedVendor['token']}',
        );
      });
    }
  }

  // ============================================================
  // LOAD USER DATA
  // ============================================================

  Future<void> loadUserData({
    int? notificationMonth,
    int? notificationYear,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final vendorData = prefs.getString('vendor');

    if (vendorData == null || vendorData.isEmpty) {
      debugPrint('Vendor data not found in SharedPreferences');

      return;
    }

    try {
      final decodedVendor = jsonDecode(vendorData);

      vendor = VendorModel.fromJson(decodedVendor);

      // ========================================================
      // SELECT TARGET DATE
      // ========================================================

      final targetMonth =
          notificationMonth ??
          (monthNotifier.value >= 1 && monthNotifier.value <= 12
              ? monthNotifier.value
              : selectedDate.month);

      final targetYear =
          notificationYear ??
          (yearNotifier.value >= 2000 ? yearNotifier.value : selectedDate.year);

      selectedDate = DateTime(targetYear, targetMonth, 1);

      if (!mounted) {
        return;
      }

      setState(() {
        futureCards = fetchBookings(
          decodedVendor['vendorId']?.toString() ?? vendor!.vendorId,

          // Backend expects JS month.
          targetMonth - 1,

          targetYear,

          'Bearer ${decodedVendor['token']}',
        );
      });

      debugPrint(
        'loadUserData: '
        'month=$targetMonth '
        'year=$targetYear',
      );
    } catch (error, stackTrace) {
      debugPrint('loadUserData error: $error');

      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // ============================================================
  // FETCH BOOKINGS
  // ============================================================

  Future<List<BookingsCard>> fetchBookings(
    String userId,
    int month,
    int year,
    String token,
  ) async {
    final url = Uri.parse(
      "${KConstantURL.url}/vendor/getBookings/"
      "$userId/$month/$year",
    );

    try {
      final response = await http.get(url, headers: {"Authorization": token});

      if (response.statusCode != 200) {
        debugPrint(
          'fetchBookings failed: '
          '${response.statusCode}',
        );

        debugPrint('Response: ${response.body}');

        throw Exception(
          'Failed to fetch bookings: '
          '${response.statusCode}',
        );
      }

      final decodedResponse = json.decode(response.body);

      print(decodedResponse);

      final List<BookingsCard> bookings = [];

      Map<String, dynamic> toSafeMap(dynamic value) {
        if (value == null) {
          return {};
        }

        if (value is Map<String, dynamic>) {
          return value;
        }

        if (value is Map<dynamic, dynamic>) {
          return Map<String, dynamic>.from(value);
        }

        return {};
      }

      // ========================================================
      // ARRAY RESPONSE
      // ========================================================

      if (decodedResponse is List) {
        for (var item in decodedResponse) {
          try {
            final safeItem = toSafeMap(item);

            final bookingData = safeItem;

            print(
              'Processing booking: '
              '${bookingData['_id']} '
              '- orderCompleted: '
              '${bookingData['orderCompleted']}',
            );

            final booking = BookingsCard.fromJson(bookingData);

            bookings.add(booking);
          } catch (error) {
            print(
              'Error parsing booking: '
              '$error',
            );

            print('Problematic item: $item');
          }
        }
      }
      // ========================================================
      // DATA RESPONSE
      // ========================================================
      else if (decodedResponse is Map && decodedResponse.containsKey('data')) {
        final dataList = decodedResponse['data'] as List? ?? [];

        for (var item in dataList) {
          try {
            final safeItem = toSafeMap(item);

            Map<String, dynamic> bookingData;

            if (safeItem.containsKey('booking')) {
              bookingData = toSafeMap(safeItem['booking']);
            } else {
              bookingData = safeItem;
            }

            print(
              'Processing booking: '
              '${bookingData['_id']} '
              '- orderCompleted: '
              '${bookingData['orderCompleted']}',
            );

            final booking = BookingsCard.fromJson(bookingData);

            bookings.add(booking);
          } catch (error) {
            print(
              'Error parsing booking: '
              '$error',
            );

            print('Problematic item: $item');
          }
        }
      } else {
        print(
          'Unexpected response format: '
          '$decodedResponse',
        );
      }

      print(
        'Bookings loaded: '
        '${bookings.length}',
      );

      for (var booking in bookings) {
        print(
          'Booking ${booking.id}: '
          'cancelOrder=${booking.cancelOrder}, '
          'orderCompleted=${booking.orderCompleted}',
        );
      }

      initializeIsLoadingFromResponse(bookings);

      // ========================================================
      // Notification booking may now exist
      // ========================================================

      if (_pendingNotificationBookingId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _tryOpenPendingNotificationBooking();
        });
      }

      return bookings;
    } catch (error) {
      debugPrint('fetchBookings error: $error');

      return [];
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: bookingIdNotifier,
      builder: (context, value, _) {
        return ValueListenableBuilder(
          valueListenable: bookingStatusNotifier,
          builder: (context, _, __) {
            return ValueListenableBuilder<bool>(
              valueListenable: isDarkThemeNotifier,
              builder: (context, isDarkTheme, __) {
                final themeData = _buildTheme(context, !isDarkTheme);

                return Theme(
                  data: themeData,
                  child: Scaffold(
                    body: NestedScrollView(
                      controller: _scrollController,
                      physics: const ClampingScrollPhysics(),
                      headerSliverBuilder:
                          (context, innerBoxIsScrolled) => [
                            SliverAppBar(
                              pinned: false,
                              floating: true,
                              snap: false,
                              stretch: true,
                              primary: false,
                              expandedHeight: 328.h,
                              collapsedHeight: kToolbarHeight + 8.h,
                              elevation: 0,
                              backgroundColor:
                                  isDarkTheme ? Colors.teal : Colors.amber,
                              flexibleSpace: LayoutBuilder(
                                builder: (context, constraints) {
                                  final visibleHeight =
                                      constraints.biggest.height;

                                  final isCollapsed =
                                      visibleHeight <= kToolbarHeight;

                                  final opacity =
                                      visibleHeight > kToolbarHeight
                                          ? 1.0
                                          : (visibleHeight / kToolbarHeight)
                                              .clamp(0.0, 1.0);

                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (mounted) {
                                      isCalendarCollapsedNotifier.value =
                                          isCollapsed;
                                    }
                                  });

                                  return Opacity(
                                    opacity: opacity,
                                    child: FlexibleSpaceBar(
                                      collapseMode: CollapseMode.pin,
                                      background: Padding(
                                        padding: EdgeInsets.all(8.w),
                                        child: _buildCalendarSection(
                                          isDarkTheme,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: _SliverAppBarDelegate(
                                minHeight: 68.h,
                                maxHeight: 68.h,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                  ),
                                  color:
                                      isDarkTheme ? Colors.teal : Colors.amber,
                                  child: _buildStatusTabs(isDarkTheme),
                                ),
                              ),
                            ),
                          ],
                      body: _buildBookingsListSection(isDarkTheme),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ============================================================
  // BOOKINGS LIST
  // ============================================================

  Widget _buildBookingsListSection(bool isDarkTheme) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkTheme ? Colors.teal : Colors.amber,
      ),
      child: FutureBuilder<List<BookingsCard>>(
        future: futureCards,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.w,
                color: !isDarkTheme ? Colors.black : Colors.white,
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 40.sp, color: Colors.red),
                  SizedBox(height: 10.h),
                  Text(
                    'Failed to load bookings',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    snapshot.error?.toString() ?? 'Unknown error',
                    style: TextStyle(fontSize: 12.sp),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final bookingsList = _filterBookingsByStatus(snapshot.data ?? []);

          print(
            'Filtered bookings for status '
            '$bookingsDetails: '
            '${bookingsList.length}',
          );

          if (bookingsList.isEmpty) {
            return Center(
              child: Column(
                children: [
                  SizedBox(height: 18.h),
                  const Center(child: BannerAdWidget()),
                  SizedBox(height: 18.h),
                  Text(
                    _getEmptyStateMessage(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: isDarkTheme ? Colors.teal : Colors.amber,
            ),
            child: ListView.separated(
              itemCount: bookingsList.length,
              separatorBuilder: (context, index) => SizedBox(height: 5.h),
              itemBuilder: (context, index) {
                final booking = bookingsList[index];

                return Column(
                  children: [
                    if (index % 3 == 0) ...[
                      const Center(child: BannerAdWidget()),
                      SizedBox(height: 8.h),
                    ],

                    // IMPORTANT:
                    // GlobalKey allows us to
                    // scroll directly to this
                    // booking.
                    Container(
                      key: _getBookingKey(booking.id),
                      child: _buildBookingCard(booking, isDarkTheme),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // THEME
  // ============================================================

  ThemeData _buildTheme(BuildContext context, bool isDarkTheme) {
    final theme = Theme.of(context);

    final colorScheme =
        isDarkTheme
            ? const ColorScheme.light(
              primary: Colors.amber,
              onPrimary: Colors.teal,
              onSurface: Colors.white,
            )
            : const ColorScheme.dark(
              primary: Colors.teal,
              onPrimary: Colors.orange,
              onSurface: Colors.black,
            );

    return theme.copyWith(
      colorScheme: colorScheme,
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Colors.white),
      ),
      textTheme: theme.textTheme.copyWith(
        headlineMedium: TextStyle(
          color: Colors.blue,
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // CALENDAR
  // ============================================================

  Widget _buildCalendarSection(bool isDarkTheme) {
    return FutureBuilder<List<BookingsCard>>(
      future: futureCards,
      builder: (context, snapshot) {
        final bookedDates =
            snapshot.hasData
                ? _extractBookedDatesByStatus(snapshot.data!, bookingsDetails)
                : <DateTime>{};

        final today = DateTime.now();

        final todayDate = DateTime(today.year, today.month, today.day);

        final hasBookingToday = bookedDates.any((d) => isSameDay(d, todayDate));

        return Container(
          decoration: BoxDecoration(
            color: isDarkTheme ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: TableCalendar(
            firstDay: DateTime(2000),
            lastDay: DateTime(2100),
            focusedDay: selectedDate,
            rowHeight: 40.h,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              todayDecoration: const BoxDecoration(
                color: Colors.purple,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: isDarkTheme ? Colors.amber : Colors.teal,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 16.sp,
                color: isDarkTheme ? Colors.white : Colors.black,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: isDarkTheme ? Colors.white : Colors.black,
                fontSize: 12.sp,
              ),
              weekendStyle: TextStyle(
                color: isDarkTheme ? Colors.white : Colors.black,
                fontSize: 12.sp,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, date, focusedDay) {
                final hasBooking = bookedDates.any((d) => isSameDay(d, date));

                final isToday = isSameDay(date, todayDate);

                if (isToday) {
                  return null;
                }

                return Stack(
                  children: [
                    Container(
                      margin: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: hasBooking ? _getDateBackgroundColor() : null,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          color: isDarkTheme ? Colors.white : Colors.black,
                          fontSize: 14.sp,
                          fontWeight:
                              hasBooking ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (hasBooking &&
                        (bookingCountBySameDate['${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'] ??
                                0) >
                            1)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _buildDateCountBadge(date, isDarkTheme),
                      ),
                  ],
                );
              },
              todayBuilder: (context, date, focusedDay) {
                final hasBooking = bookedDates.any((d) => isSameDay(d, date));

                return Stack(
                  children: [
                    Container(
                      margin: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        shape: BoxShape.circle,
                        border:
                            hasBooking
                                ? Border.all(
                                  color: _getTodayBorderColor(bookingsDetails),
                                  width: 3.w,
                                )
                                : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (hasBooking &&
                        (bookingCountBySameDate['${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'] ??
                                0) >
                            1)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _buildDateCountBadge(date, isDarkTheme),
                      ),
                  ],
                );
              },
              markerBuilder: (context, date, events) {
                final hasBooking = bookedDates.any((d) => isSameDay(d, date));

                if (!hasBooking) {
                  return const SizedBox.shrink();
                }

                final matchingBookings =
                    snapshot.data?.where((booking) {
                      if (booking.bookingDate == null) {
                        return false;
                      }

                      final bookingDate = DateTime(
                        booking.bookingDate!.year,
                        booking.bookingDate!.month,
                        booking.bookingDate!.day,
                      );

                      return isSameDay(bookingDate, date);
                    }).toList() ??
                    [];

                if (matchingBookings.isEmpty) {
                  return const SizedBox.shrink();
                }

                final bookingForMarker = matchingBookings.first;

                return Positioned(
                  bottom: -3.h,
                  child: Container(
                    width: 12.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: _getDateMarkerColor(bookingForMarker),
                      border:
                          _getDateMarkerColor(bookingForMarker) !=
                                  Colors.transparent
                              ? Border.all(
                                color:
                                    isDarkTheme ? Colors.black : Colors.white,
                                width: 2.w,
                              )
                              : null,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
            onPageChanged: (focusedDay) {
              setState(() {
                selectedDate = focusedDay;

                monthNotifier.value = focusedDay.month;

                yearNotifier.value = focusedDay.year;

                if (vendor != null) {
                  futureCards = fetchBookings(
                    vendor!.vendorId,
                    focusedDay.month - 1,
                    focusedDay.year,
                    'Bearer ${vendor!.token}',
                  );
                }
              });
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // DATE BADGE
  // ============================================================

  Widget _buildDateCountBadge(DateTime date, bool isDarkTheme) {
    final key =
        '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    return Container(
      padding: EdgeInsets.all(2.w),
      constraints: BoxConstraints(minWidth: 16.w, minHeight: 16.h),
      decoration: BoxDecoration(
        color:
            bookingsDetails == 3
                ? Colors.red
                : bookingsDetails == 2
                ? Colors.green
                : Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDarkTheme ? Colors.black : Colors.white,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          '${bookingCountBySameDate[key]}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 8.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TODAY BORDER
  // ============================================================

  Color _getTodayBorderColor(int status) {
    switch (status) {
      case 1:
        return Colors.blue;

      case 2:
        return Colors.green;

      case 3:
        return Colors.red;

      default:
        return Colors.orange;
    }
  }

  // ============================================================
  // BOOKED DATES
  // ============================================================

  Set<DateTime> _extractBookedDatesByStatus(
    List<BookingsCard> bookings,
    int status,
  ) {
    bookingCountBySameDate.clear();

    final dates = <DateTime>{};

    for (final booking in bookings) {
      try {
        if (booking.bookingDate == null) {
          continue;
        }

        final date = DateTime(
          booking.bookingDate!.year,
          booking.bookingDate!.month,
          booking.bookingDate!.day,
        );

        final dateKey =
            '${date.year}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}';

        bool shouldInclude = false;

        if (status == 1 && !booking.cancelOrder && !booking.orderCompleted) {
          shouldInclude = true;
        } else if (status == 2 && booking.orderCompleted) {
          shouldInclude = true;
        } else if (status == 3 && booking.cancelOrder) {
          shouldInclude = true;
        }

        if (shouldInclude) {
          dates.add(date);

          bookingCountBySameDate[dateKey] =
              (bookingCountBySameDate[dateKey] ?? 0) + 1;
        }
      } catch (error) {
        print(
          'Date parsing error: '
          '$error',
        );
      }
    }

    return dates;
  }

  // ============================================================
  // DATE BACKGROUND
  // ============================================================

  Color _getDateBackgroundColor() {
    final status =
        bookingsDetails == 1
            ? 'pending'
            : bookingsDetails == 2
            ? 'completed'
            : 'canceled';

    return status == 'completed'
        ? Colors.green.withOpacity(0.3)
        : status == 'pending'
        ? Colors.blue.withOpacity(0.3)
        : Colors.red.withOpacity(0.3);
  }

  // ============================================================
  // DATE MARKER
  // ============================================================

  Color _getDateMarkerColor(BookingsCard booking) {
    final hasNewMessage = getBookingStatus(booking.id) == true;

    final status =
        bookingsDetails == 1
            ? 'pending'
            : bookingsDetails == 2
            ? 'completed'
            : 'canceled';

    if ((status == 'pending' || status == 'canceled') && hasNewMessage) {
      return Colors.green;
    }

    return Colors.transparent;
  }

  // ============================================================
  // STATUS TABS
  // ============================================================

  Widget _buildStatusTabs(bool isDarkTheme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDarkTheme ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildTabWithBadge(
            'Pending',
            1,
            Colors.blue,
            newMessageCountPending,
            isDarkTheme,
          ),
          _buildTabWithBadge(
            'Completed',
            2,
            Colors.green,
            newMessageCountComplete,
            isDarkTheme,
          ),
          _buildTabWithBadge(
            'Canceled',
            3,
            Colors.red,
            newMessageCountCanceled,
            isDarkTheme,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAB BADGE
  // ============================================================

  Widget _buildTabWithBadge(
    String text,
    int value,
    Color color,
    int count,
    bool isDarkTheme,
  ) {
    return count == 0
        ? _buildOrderTab(text, value, color, isDarkTheme)
        : Stack(
          clipBehavior: Clip.none,
          children: [
            _buildOrderTab(text, value, color, isDarkTheme),
            Positioned(
              top: -4.h,
              right: -4.w,
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: const BoxDecoration(
                  color: Colors.pink,
                  shape: BoxShape.circle,
                ),
                constraints: BoxConstraints(minWidth: 20.w, minHeight: 20.h),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
  }

  // ============================================================
  // BOOKING COUNTS
  // ============================================================

  Map<String, int> calculateBookingCategories(List<BookingsCard> bookingsList) {
    int pending = 0;

    int completed = 0;

    int canceled = 0;

    for (var booking in bookingsList) {
      if (booking.id.isEmpty) {
        continue;
      }

      if (booking.cancelOrder) {
        canceled++;
      } else if (booking.orderCompleted) {
        completed++;
      } else {
        pending++;
      }
    }

    print(
      'Categories - '
      'Pending: $pending, '
      'Completed: $completed, '
      'Canceled: $canceled',
    );

    return {'pending': pending, 'completed': completed, 'canceled': canceled};
  }

  // ============================================================
  // FILTER BOOKINGS
  // ============================================================

  List<BookingsCard> _filterBookingsByStatus(List<BookingsCard> bookings) {
    return bookings.where((booking) {
      switch (bookingsDetails) {
        case 1:
          return !booking.cancelOrder && !booking.orderCompleted;

        case 2:
          return booking.orderCompleted;

        case 3:
          return booking.cancelOrder;

        default:
          return true;
      }
    }).toList();
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  String _getEmptyStateMessage() {
    switch (bookingsDetails) {
      case 1:
        return "No pending bookings available for this month";

      case 2:
        return "No completed bookings available for this month";

      case 3:
        return "No canceled bookings available for this month";

      default:
        return "No bookings available";
    }
  }

  // ============================================================
  // CAPITALIZE
  // ============================================================

  String capitalizeWords(String? input) {
    if (input == null) {
      return '';
    }

    return input
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '',
        )
        .join(' ');
  }

  // ============================================================
  // NOTIFICATION COUNT
  // ============================================================

  int calculateNewNotificationCount(Map<String, bool> data) {
    int count = 0;

    data.forEach((_, value) {
      if (value) {
        count++;
      }
    });

    return count;
  }

  // ============================================================
  // BOOKING CARD
  // ============================================================

  Widget _buildBookingCard(BookingsCard booking, bool isDarkTheme) {
    final rating = booking.rating;

    final review = booking.review;

    final isCompleted = booking.orderCompleted;

    final isCancelled = booking.cancelOrder;

    final hasNewMessage = getBookingStatus(booking.id) == true;

    final isSelfBooked = booking.userId == booking.vendorId;

    final isNotificationBooking =
        _highlightNotificationBooking && _highlightedBookingId == booking.id;

    final address =
        booking.bookedById.address.isNotEmpty
            ? booking.bookedById.address.first
            : null;

    final village = isSelfBooked ? booking.vill : address?.vill ?? '';

    final post = isSelfBooked ? booking.post : address?.post ?? '';

    final district = isSelfBooked ? booking.dist : address?.dist ?? '';

    String formattedDate = 'Date not available';

    if (booking.bookingDate != null) {
      formattedDate =
          "${booking.bookingDate!.day}/"
          "${booking.bookingDate!.month}/"
          "${booking.bookingDate!.year}";
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color:
            isNotificationBooking
                ? Colors.yellow.withOpacity(0.25)
                : isDarkTheme
                ? Colors.black
                : Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border:
            isNotificationBooking
                ? Border.all(color: Colors.orange, width: 3.w)
                : null,
        boxShadow:
            isNotificationBooking
                ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.35),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
                : null,
      ),
      child: InkWell(
        onTap: () {
          if (booking.id.isNotEmpty && hasNewMessage) {
            upsertBooking(booking.id, false);

            bookingCountNotifier.value = calculateNewNotificationCount(
              bookingIdNotifier.value,
            );

            setState(() {});

            loadUserData();
          }
        },
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasNewMessage)
                Text(
                  "New Message",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),

              if (isNotificationBooking)
                Padding(
                  padding: EdgeInsets.only(bottom: 6.h),
                  child: Text(
                    "Opened from notification",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),

              _buildInfoRow('Name', booking.bookedById.name, booking.id),

              _buildInfoRow(
                'Mobile',
                booking.bookedById.phoneNo.toString(),
                booking.id,
              ),

              _buildInfoRow('Village', village, booking.id),

              _buildInfoRow('Post Office', post, booking.id),

              _buildInfoRow('District', district, booking.id),

              _buildInfoRow('Date', formattedDate, booking.id, isColored: true),

              if (bookingsDetails == 2)
                Column(
                  children: [
                    _buildInfoRow('Rating', _formatRating(rating), booking.id),
                    _buildInfoRow(
                      'Review',
                      _formatReview(review),
                      booking.id,
                      isReview: true,
                    ),
                  ],
                ),

              _buildInfoRow(
                'Status',
                isCompleted
                    ? "Completed"
                    : isCancelled
                    ? "Canceled"
                    : "Pending",
                booking.id,
                isColored: true,
                color: _getStatusColor(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RATING
  // ============================================================

  String _formatRating(int rating) {
    if (rating == 0) {
      return 'Not Rated';
    }

    return '$rating/5';
  }

  // ============================================================
  // REVIEW
  // ============================================================

  String _formatReview(String? review) {
    if (review == null || review.trim().isEmpty) {
      return 'Not Reviewed';
    }

    return review;
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _getStatusColor() {
    switch (bookingsDetails) {
      case 1:
        return Colors.blue;

      case 2:
        return Colors.green;

      case 3:
        return Colors.red;

      default:
        return Colors.black;
    }
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _buildInfoRow(
    String label,
    String value,
    String? bookingId, {
    bool isColored = false,
    Color? color,
    bool isReview = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: isColored ? color : null,
              ),
            ),
          ),

          SizedBox(width: 16.w),

          Expanded(
            child:
                isReview
                    ? Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        capitalizeWords(value),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isColored ? color : null,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                    : Text(
                      capitalizeWords(value),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isColored ? color : null,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ORDER TAB
  // ============================================================

  Widget _buildOrderTab(String text, int value, Color color, bool isDarkTheme) {
    final isSelected = bookingsDetails == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          bookingStatusNotifier.value = value;

          bookingsDetails = value;
        });
      },
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color:
                isSelected
                    ? (isDarkTheme ? Colors.white : Colors.black)
                    : (isDarkTheme ? Colors.black : Colors.white),
            width: 2.w,
          ),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isDarkTheme ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 12.sp,
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// SLIVER APP BAR DELEGATE
// ================================================================

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;

  final double maxHeight;

  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

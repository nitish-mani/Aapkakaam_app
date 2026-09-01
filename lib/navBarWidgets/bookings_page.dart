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

class _BookingsPageState extends State<BookingsPage>
    with SingleTickerProviderStateMixin {
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
  late TabController _tabController;

  // ============================================================
  // NOTIFICATION NAVIGATION
  // ============================================================

  String? _pendingNotificationBookingId;
  bool _notificationNavigationInProgress = false;
  bool _highlightNotificationBooking = false;
  String? _highlightedBookingId;
  final Map<String, GlobalKey> _bookingKeys = {};
  Timer? _highlightTimer;

  // Track which bookings have been seen (clicked)
  final Set<String> _seenBookingIds = {};

  // ============================================================
  // COUNTERS
  // ============================================================

  // Total counts (all bookings)
  int totalPendingCount = 0;
  int totalCompletedCount = 0;
  int totalCanceledCount = 0;

  // Unseen counts (bookings with "New" badge)
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
  // THEME COLORS
  // ============================================================

  static const Color _primaryBlue = Color(0xFF4F46E5);
  static const Color _primaryPurple = Color(0xFF7C3AED);
  static const Color _accentOrange = Color(0xFFF59E0B);
  static const Color _accentGreen = Color(0xFF22C55E);
  static const Color _accentRed = Color(0xFFEF4444);

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          bookingsDetails = _tabController.index + 1;
          bookingStatusNotifier.value = bookingsDetails;
        });
      }
    });

    isLoading = {};
    isPermissionGranted = {};
    _setupRefreshListener();
    loadUserData();

    _notificationSubscription = FirebaseNotifications.notificationClickStream
        .listen(_handleNotificationClick);

    _pendingNotificationListener = () {
      final bookingId = pendingNotificationBookingIdNotifier.value;
      if (bookingId != null && bookingId.isNotEmpty) {
        _pendingNotificationBookingId = bookingId;
        _tryOpenPendingNotificationBooking();
      }
    };
    pendingNotificationBookingIdNotifier.addListener(
      _pendingNotificationListener!,
    );

    _scrollController.addListener(_handleScroll);

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
    if (!_scrollController.hasClients) return;
    final currentOffset = _scrollController.offset;

    if (currentOffset <= 0) {
      if (!_isCalendarExpanded) {
        setState(() => _isCalendarExpanded = true);
        isCalendarCollapsedNotifier.value = false;
      }
    } else if (currentOffset > _lastScrollOffset && currentOffset > 100) {
      if (_isCalendarExpanded) {
        setState(() => _isCalendarExpanded = false);
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

      final hasCalendarDate = _setMonthYearFromNotification(data);

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
      int? backendMonth = int.tryParse(data['month']?.toString() ?? '');
      int? notificationYear = int.tryParse(data['year']?.toString() ?? '');

      if (backendMonth == null || notificationYear == null) {
        final bookingDateString = data['bookingDate']?.toString();
        if (bookingDateString != null && bookingDateString.isNotEmpty) {
          final parsedDate = DateTime.tryParse(bookingDateString);
          if (parsedDate != null) {
            backendMonth = parsedDate.month - 1;
            notificationYear = parsedDate.year;
          }
        }
      }

      if (backendMonth == null || notificationYear == null) return false;
      if (backendMonth < 0 || backendMonth > 11) return false;
      if (notificationYear < 2000 || notificationYear > 2100) return false;

      final flutterMonth = backendMonth + 1;
      monthNotifier.value = flutterMonth;
      yearNotifier.value = notificationYear;
      selectedDate = DateTime(notificationYear, flutterMonth, 1);

      if (mounted) setState(() {});
      return true;
    } catch (error) {
      debugPrint('Failed to set notification month/year: $error');
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
    if (!isVendor.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tryOpenPendingNotificationBooking();
      });
      return;
    }

    final targetMonth =
        forceMonthYear ? monthNotifier.value : selectedDate.month;
    final targetYear = forceMonthYear ? yearNotifier.value : selectedDate.year;

    if (targetMonth < 1 ||
        targetMonth > 12 ||
        targetYear < 2000 ||
        targetYear > 2100)
      return;

    if (vendor == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted)
          loadUserData(
            notificationMonth: targetMonth,
            notificationYear: targetYear,
          );
      });
      return;
    }

    final currentVendor = vendor!;
    if (!mounted) return;

    setState(() {
      selectedDate = DateTime(targetYear, targetMonth, 1);
      futureCards = fetchBookings(
        currentVendor.vendorId,
        targetMonth - 1,
        targetYear,
        'Bearer ${currentVendor.token}',
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryOpenPendingNotificationBooking();
    });
  }

  void _setPendingNotificationBooking(String bookingId) {
    if (bookingId.isEmpty) return;
    _pendingNotificationBookingId = bookingId;
    pendingNotificationBookingIdNotifier.value = bookingId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryOpenPendingNotificationBooking();
    });
  }

  // ============================================================
  // TRY OPEN BOOKING
  // ============================================================

  void _tryOpenPendingNotificationBooking() {
    if (!mounted || _notificationNavigationInProgress) return;

    final bookingId =
        _pendingNotificationBookingId ??
        pendingNotificationBookingIdNotifier.value;

    if (bookingId == null || bookingId.isEmpty || futureCards == null) {
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

        // Get bookings according to the currently selected status.
        final filteredBookings = _filterBookingsByStatus(bookings);

        // Find the booking that came from the notification.
        final index = filteredBookings.indexWhere(
          (booking) => booking.id == bookingId,
        );

        // Booking not found.
        if (index == -1) {
          _notificationNavigationInProgress = false;
          return;
        }

        // ============================================================
        // RESET BOOKING TAB COUNT
        // ============================================================
        //
        // Notification has been opened, so reset the count shown
        // on the Booking navigation button.
        //
        // IMPORTANT:
        // This does NOT mark the individual booking as seen.
        // The booking can still show the "NEW" badge.
        // ============================================================

        // ============================================================
        // HIGHLIGHT NOTIFICATION BOOKING
        // ============================================================

        _highlightedBookingId = bookingId;
        _highlightNotificationBooking = true;

        if (mounted) {
          setState(() {});
        }

        // Give Flutter time to build the highlighted booking card.
        await Future.delayed(const Duration(milliseconds: 150));

        if (!mounted) {
          _notificationNavigationInProgress = false;
          return;
        }

        // ============================================================
        // SCROLL TO NOTIFICATION BOOKING
        // ============================================================

        await _scrollToBooking(bookingId);

        // ============================================================
        // IMPORTANT
        // ============================================================
        //
        // DO NOT call:
        //
        // _markBookingAsSeen(bookingId);
        //
        // here.
        //
        // The booking must remain NEW until the user taps it.
        // ============================================================

        // ============================================================
        // REMOVE HIGHLIGHT AFTER 3 SECONDS
        // ============================================================

        _highlightTimer?.cancel();

        _highlightTimer = Timer(const Duration(seconds: 3), () {
          if (!mounted) return;

          setState(() {
            _highlightNotificationBooking = false;
            _highlightedBookingId = null;
          });
        });

        // ============================================================
        // CLEAR PENDING NOTIFICATION
        // ============================================================

        _pendingNotificationBookingId = null;

        if (pendingNotificationBookingIdNotifier.value == bookingId) {
          pendingNotificationBookingIdNotifier.value = null;
        }

        _notificationNavigationInProgress = false;
      },
      onError: (error, stackTrace) {
        debugPrint('Failed to process notification booking: $error');

        debugPrintStack(stackTrace: stackTrace);

        _notificationNavigationInProgress = false;
      },
    );
  }

  Future<void> _scrollToBooking(String bookingId) async {
    if (!mounted) return;
    final key = _bookingKeys[bookingId];
    if (key == null) return;

    final targetContext = key.currentContext;
    if (targetContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToBooking(bookingId);
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
    } catch (error) {
      debugPrint('Failed to scroll to booking: $error');
    }
  }

  GlobalKey _getBookingKey(String bookingId) {
    return _bookingKeys.putIfAbsent(bookingId, () => GlobalKey());
  }

  // ============================================================
  // MARK BOOKING AS SEEN
  // ============================================================

  void _markBookingAsSeen(String bookingId) {
    if (bookingId.isEmpty) return;

    // Add to seen set
    _seenBookingIds.add(bookingId);

    // Update the booking status to false (seen)
    bookingIdNotifier.value = {...bookingIdNotifier.value, bookingId: false};

    // Update all counts
    if (futureCards != null) {
      futureCards!.then((bookings) {
        if (mounted) {
          _updateAllCounts(bookings);
        }
      });
    }

    if (mounted) setState(() {});
  }

  // ============================================================
  // UPDATE ALL COUNTS
  // ============================================================

  void _updateAllCounts(List<BookingsCard> bookings) {
    int pendingTotal = 0;
    int completedTotal = 0;
    int canceledTotal = 0;

    int pendingUnseen = 0;
    int completedUnseen = 0;
    int canceledUnseen = 0;

    for (final booking in bookings) {
      final isUnseen =
          !_seenBookingIds.contains(booking.id) &&
          (bookingIdNotifier.value[booking.id] ?? false);

      if (booking.cancelOrder) {
        canceledTotal++;
        if (isUnseen) canceledUnseen++;
      } else if (booking.orderCompleted) {
        completedTotal++;
        if (isUnseen) completedUnseen++;
      } else {
        pendingTotal++;
        if (isUnseen) pendingUnseen++;
      }
    }

    setState(() {
      // Total counts
      totalPendingCount = pendingTotal;
      totalCompletedCount = completedTotal;
      totalCanceledCount = canceledTotal;

      // Unseen counts (for "New" badges)
      newMessageCountPending = pendingUnseen;
      newMessageCountComplete = completedUnseen;
      newMessageCountCanceled = canceledUnseen;
    });
  }

  // ============================================================
  // HANDLE BOOKING CARD TAP
  // ============================================================

  void _handleBookingCardTap(String bookingId) {
    if (bookingId.isEmpty) return;

    // ============================================================
    // CHECK WHETHER THIS BOOKING IS ACTUALLY NEW / UNSEEN
    // ============================================================

    final bool wasUnseen =
        bookingIdNotifier.value[bookingId] == true &&
        !_seenBookingIds.contains(bookingId);

    // ============================================================
    // DECREASE BOOKING COUNT BY 1
    // ============================================================
    //
    // Only decrease the count if this was a NEW booking.
    //
    // Example:
    // 5 → 4
    // 4 → 3
    // 3 → 2
    // 2 → 1
    // 1 → 0
    //
    // It will never become negative.
    // ============================================================

    if (wasUnseen && bookingCountNotifier.value > 0) {
      bookingCountNotifier.value = bookingCountNotifier.value - 1;
    }

    // ============================================================
    // MARK THIS BOOKING AS SEEN
    // ============================================================

    _markBookingAsSeen(bookingId);

    // ============================================================
    // REMOVE NOTIFICATION HIGHLIGHT
    // ============================================================

    if (_highlightedBookingId == bookingId) {
      _highlightTimer?.cancel();

      if (mounted) {
        setState(() {
          _highlightNotificationBooking = false;
          _highlightedBookingId = null;
        });
      }
    }
  }
  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _tabController.dispose();
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
    _seenBookingIds.clear();
    super.dispose();
  }

  // ============================================================
  // REFRESH LISTENER
  // ============================================================

  void _setupRefreshListener() {
    _refreshListener = () {
      if (!mounted) return;
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
    if (id == null) return null;
    // If the booking has been seen, return false
    if (_seenBookingIds.contains(id)) return false;
    return bookingIdNotifier.value[id];
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
      for (final booking in validBookings) booking.id: false,
    };

    isLoading = {for (final booking in validBookings) booking.id: false};

    // IMPORTANT:
    // Existing NEW state ko preserve karo.
    //
    // Agar booking Pending mein NEW thi aur baad mein
    // Cancelled/Completed ho gayi, to bhi usi booking ID
    // ki NEW state true rehni chahiye.
    final updatedBookingIds = {...bookingIdNotifier.value};

    for (final booking in validBookings) {
      final bookingId = booking.id;

      if (_seenBookingIds.contains(bookingId)) {
        // User already tapped this booking.
        updatedBookingIds[bookingId] = false;
      } else {
        // Existing value preserve karo.
        //
        // true  -> true  (NEW remains NEW)
        // false -> false
        // missing -> false
        updatedBookingIds[bookingId] = updatedBookingIds[bookingId] ?? false;
      }
    }

    bookingIdNotifier.value = updatedBookingIds;

    if (mounted) {
      setState(() {
        _updateAllCounts(validBookings);
      });
    }
  }

  void updateLoadingState(String id, bool value) {
    if (isLoading.containsKey(id)) isLoading[id] = value;
  }

  void updatePermissionState(String id, bool value) {
    if (isPermissionGranted.containsKey(id)) isPermissionGranted[id] = value;
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
    if (vendorData == null || vendorData.isEmpty) return;

    try {
      final decodedVendor = jsonDecode(vendorData);
      vendor = VendorModel.fromJson(decodedVendor);

      final targetMonth =
          notificationMonth ??
          (monthNotifier.value >= 1 && monthNotifier.value <= 12
              ? monthNotifier.value
              : selectedDate.month);
      final targetYear =
          notificationYear ??
          (yearNotifier.value >= 2000 ? yearNotifier.value : selectedDate.year);

      selectedDate = DateTime(targetYear, targetMonth, 1);
      if (!mounted) return;

      setState(() {
        futureCards = fetchBookings(
          decodedVendor['vendorId']?.toString() ?? vendor!.vendorId,
          targetMonth - 1,
          targetYear,
          'Bearer ${decodedVendor['token']}',
        );
      });
    } catch (error) {
      debugPrint('loadUserData error: $error');
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
      "${KConstantURL.url}/vendor/getBookings/$userId/$month/$year",
    );

    try {
      final response = await http.get(url, headers: {"Authorization": token});
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch bookings: ${response.statusCode}');
      }

      final decodedResponse = json.decode(response.body);
      final List<BookingsCard> bookings = [];

      Map<String, dynamic> toSafeMap(dynamic value) {
        if (value == null) return {};
        if (value is Map<String, dynamic>) return value;
        if (value is Map<dynamic, dynamic>)
          return Map<String, dynamic>.from(value);
        return {};
      }

      if (decodedResponse is List) {
        for (var item in decodedResponse) {
          try {
            final bookingData = toSafeMap(item);
            bookings.add(BookingsCard.fromJson(bookingData));
          } catch (error) {
            debugPrint('Error parsing booking: $error');
          }
        }
      } else if (decodedResponse is Map &&
          decodedResponse.containsKey('data')) {
        final dataList = decodedResponse['data'] as List? ?? [];
        for (var item in dataList) {
          try {
            final safeItem = toSafeMap(item);
            final bookingData =
                safeItem.containsKey('booking')
                    ? toSafeMap(safeItem['booking'])
                    : safeItem;
            bookings.add(BookingsCard.fromJson(bookingData));
          } catch (error) {
            debugPrint('Error parsing booking: $error');
          }
        }
      }

      initializeIsLoadingFromResponse(bookings);

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
                return Scaffold(
                  backgroundColor:
                      isDarkTheme
                          ? const Color(0xFF0B1020)
                          : const Color(0xFFF0F2F8),
                  body: NestedScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    headerSliverBuilder:
                        (context, innerBoxIsScrolled) => [
                          SliverAppBar(
                            pinned: false,
                            floating: true,
                            snap: false,
                            stretch: true,
                            primary: false,
                            expandedHeight: 340.h,
                            collapsedHeight: kToolbarHeight + 8.h,
                            elevation: 0,
                            backgroundColor: Colors.transparent,
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
                                      padding: EdgeInsets.all(12.w),
                                      child: _buildModernCalendarSection(
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
                              minHeight: 72.h,
                              maxHeight: 72.h,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12.w),
                                color:
                                    isDarkTheme
                                        ? const Color(0xFF0B1020)
                                        : const Color(0xFFF0F2F8),
                                child: _buildModernTabs(isDarkTheme),
                              ),
                            ),
                          ),
                        ],
                    body: _buildModernBookingsList(isDarkTheme),
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
  // MODERN CALENDAR SECTION
  // ============================================================

  Widget _buildModernCalendarSection(bool isDarkTheme) {
    return ValueListenableBuilder<bool>(
      valueListenable: isHindiNotifier,
      builder: (context, isHindi, _) {
        return FutureBuilder<List<BookingsCard>>(
          future: futureCards,
          builder: (context, snapshot) {
            final bookedDates =
                snapshot.hasData
                    ? _extractBookedDatesByStatus(
                      snapshot.data!,
                      bookingsDetails,
                    )
                    : <DateTime>{};

            final today = DateTime.now();
            final todayDate = DateTime(today.year, today.month, today.day);

            const List<String> hindiMonths = [
              'जनवरी',
              'फरवरी',
              'मार्च',
              'अप्रैल',
              'मई',
              'जून',
              'जुलाई',
              'अगस्त',
              'सितम्बर',
              'अक्टूबर',
              'नवम्बर',
              'दिसम्बर',
            ];

            const List<String> hindiWeekdays = [
              'सोम',
              'मंगल',
              'बुध',
              'गुरु',
              'शुक्र',
              'शनि',
              'रवि',
            ];

            const List<String> englishWeekdays = [
              'Mon',
              'Tue',
              'Wed',
              'Thu',
              'Fri',
              'Sat',
              'Sun',
            ];

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      isDarkTheme
                          ? [const Color(0xFF151B2D), const Color(0xFF1A2240)]
                          : [Colors.white, const Color(0xFFF8FAFD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color:
                      isDarkTheme
                          ? Colors.white.withOpacity(0.06)
                          : const Color(0xFFE8ECF3),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkTheme ? 0.25 : 0.06),
                    blurRadius: 24.r,
                    spreadRadius: 2.r,
                    offset: Offset(0, 8.h),
                  ),
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.04),
                    blurRadius: 40.r,
                    spreadRadius: -20.r,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: TableCalendar(
                  key: ValueKey(
                    'calendar_${isHindi}_${bookingsDetails}_${selectedDate.month}_${selectedDate.year}',
                  ),
                  firstDay: DateTime(2000),
                  lastDay: DateTime(2100),
                  focusedDay: selectedDate,
                  rowHeight: 36.h,
                  calendarFormat: CalendarFormat.month,
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    isTodayHighlighted: true,
                    todayDecoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF7C3AED),
                          const Color(0xFF4F46E5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withOpacity(0.3),
                          blurRadius: 12.r,
                          offset: Offset(0, 4.h),
                        ),
                      ],
                    ),
                    todayTextStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                    ),
                    selectedDecoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF4F46E5),
                          const Color(0xFF7C3AED),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withOpacity(0.3),
                          blurRadius: 12.r,
                          offset: Offset(0, 4.h),
                        ),
                      ],
                    ),
                    selectedTextStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                    ),
                    defaultTextStyle: TextStyle(
                      color:
                          isDarkTheme ? Colors.white : const Color(0xFF172033),
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    weekendTextStyle: TextStyle(
                      color:
                          isDarkTheme
                              ? Colors.white70
                              : const Color(0xFF6B7280),
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    outsideTextStyle: TextStyle(
                      color:
                          isDarkTheme
                              ? Colors.white24
                              : const Color(0xFFCBD5E1),
                      fontSize: 13.sp,
                    ),
                    markerDecoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF22C55E),
                          const Color(0xFF22C55E).withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF22C55E).withOpacity(0.3),
                          blurRadius: 6.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    cellMargin: EdgeInsets.all(1.w),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextFormatter: (date, locale) {
                      if (isHindi) {
                        return '${hindiMonths[date.month - 1]} ${date.year}';
                      }
                      return '${_getEnglishMonth(date.month)} ${date.year}';
                    },
                    titleTextStyle: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color:
                          isDarkTheme ? Colors.white : const Color(0xFF172033),
                      letterSpacing: 0.3,
                    ),
                    leftChevronIcon: Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        color: (isDarkTheme ? Colors.white : Colors.black)
                            .withOpacity(0.06),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color:
                            isDarkTheme
                                ? Colors.white
                                : const Color(0xFF4B5563),
                        size: 24.sp,
                      ),
                    ),
                    rightChevronIcon: Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        color: (isDarkTheme ? Colors.white : Colors.black)
                            .withOpacity(0.06),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color:
                            isDarkTheme
                                ? Colors.white
                                : const Color(0xFF4B5563),
                        size: 24.sp,
                      ),
                    ),
                    headerPadding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      color:
                          isDarkTheme
                              ? Colors.white60
                              : const Color(0xFF6B7280),
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    weekendStyle: TextStyle(
                      color:
                          isDarkTheme
                              ? Colors.white60
                              : const Color(0xFF6B7280),
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    dowBuilder: (context, dayIndex) {
                      final weekday = dayIndex.weekday - 1;
                      final weekdayName =
                          isHindi
                              ? hindiWeekdays[weekday]
                              : englishWeekdays[weekday];
                      return Center(
                        child: Text(
                          weekdayName,
                          style: TextStyle(
                            color:
                                isDarkTheme
                                    ? Colors.white60
                                    : const Color(0xFF6B7280),
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      );
                    },
                    defaultBuilder: (context, date, focusedDay) {
                      final hasBooking = bookedDates.any(
                        (d) => isSameDay(d, date),
                      );

                      final isToday = isSameDay(date, todayDate);

                      final count =
                          bookingCountBySameDate['${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'] ??
                          0;

                      if (isToday) return null;

                      return Container(
                        margin: EdgeInsets.all(1.w),
                        decoration: BoxDecoration(
                          color: hasBooking ? _getDateBackgroundColor() : null,
                          shape: BoxShape.circle,
                          border:
                              hasBooking &&
                                      _getDateBackgroundColor() !=
                                          Colors.transparent
                                  ? Border.all(
                                    color: _getDateBorderColor(bookingsDetails),
                                    width: 1.5,
                                  )
                                  : null,
                        ),
                        alignment: Alignment.center,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                color:
                                    hasBooking
                                        ? _getDateTextColor(bookingsDetails)
                                        : (isDarkTheme
                                            ? Colors.white
                                            : const Color(0xFF172033)),
                                fontSize: 13.sp,
                                fontWeight:
                                    hasBooking
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                              ),
                            ),

                            // Booking count badge
                            if (hasBooking && count > 1)
                              Positioned(
                                top: -15.h,
                                right: -15.w,
                                child: _buildModernDateBadge(
                                  count,
                                  isDarkTheme,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                    todayBuilder: (context, date, focusedDay) {
                      final hasBooking = bookedDates.any(
                        (d) => isSameDay(d, date),
                      );

                      final count =
                          bookingCountBySameDate['${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'] ??
                          0;

                      return Container(
                        margin: EdgeInsets.all(1.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF7C3AED),
                              const Color(0xFF4F46E5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withOpacity(0.4),
                              blurRadius: 12.r,
                              offset: Offset(0, 4.h),
                            ),
                          ],
                          border:
                              hasBooking
                                  ? Border.all(
                                    color: const Color(0xFFF59E0B),
                                    width: 2.5.w,
                                  )
                                  : null,
                        ),
                        alignment: Alignment.center,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            // Booking count badge
                            if (hasBooking && count > 1)
                              Positioned(
                                top: -15.h,
                                right: -15.w,
                                child: _buildModernDateBadge(
                                  count,
                                  isDarkTheme,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                    markerBuilder: (context, date, events) {
                      final hasBooking = bookedDates.any(
                        (d) => isSameDay(d, date),
                      );
                      if (!hasBooking) return const SizedBox.shrink();

                      final matchingBookings =
                          snapshot.data?.where((booking) {
                            if (booking.bookingDate == null) return false;
                            final bookingDate = DateTime(
                              booking.bookingDate!.year,
                              booking.bookingDate!.month,
                              booking.bookingDate!.day,
                            );
                            return isSameDay(bookingDate, date);
                          }).toList() ??
                          [];

                      if (matchingBookings.isEmpty)
                        return const SizedBox.shrink();

                      final hasNewMessage = matchingBookings.any(
                        (booking) => getBookingStatus(booking.id) == true,
                      );

                      return Positioned(
                        bottom: -1.h,
                        child: Container(
                          width: hasNewMessage ? 8.w : 5.w,
                          height: hasNewMessage ? 8.h : 5.h,
                          decoration: BoxDecoration(
                            gradient:
                                hasNewMessage
                                    ? LinearGradient(
                                      colors: [
                                        const Color(0xFF22C55E),
                                        const Color(
                                          0xFF22C55E,
                                        ).withOpacity(0.6),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                    : LinearGradient(
                                      colors: [
                                        _getDateMarkerColor(bookingsDetails),
                                        _getDateMarkerColor(
                                          bookingsDetails,
                                        ).withOpacity(0.6),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  isDarkTheme
                                      ? const Color(0xFF151B2D)
                                      : Colors.white,
                              width: 1.5,
                            ),
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
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // MODERN DATE BADGE
  // ============================================================

  Widget _buildModernDateBadge(int count, bool isDarkTheme) {
    return Container(
      padding: EdgeInsets.all(2.w),
      constraints: BoxConstraints(minWidth: 18.w, minHeight: 18.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              bookingsDetails == 3
                  ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                  : bookingsDetails == 2
                  ? [const Color(0xFF22C55E), const Color(0xFF16A34A)]
                  : [_primaryBlue, _primaryPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: isDarkTheme ? const Color(0xFF151B2D) : Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 4.r,
            spreadRadius: 1.r,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$count',
          style: TextStyle(
            color: Colors.white,
            fontSize: 9.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MODERN TABS
  // ============================================================

  Widget _buildModernTabs(bool isDarkTheme) {
    return ValueListenableBuilder<bool>(
      valueListenable: isHindiNotifier,
      builder: (context, isHindi, _) {
        final tabs = [
          {
            'label': isHindi ? 'लंबित' : 'Pending',
            'totalCount': totalPendingCount,
            'unseenCount': newMessageCountPending,
            'color': _primaryBlue,
          },
          {
            'label': isHindi ? 'पूर्ण' : 'Completed',
            'totalCount': totalCompletedCount,
            'unseenCount': newMessageCountComplete,
            'color': _accentGreen,
          },
          {
            'label': isHindi ? 'रद्द' : 'Canceled',
            'totalCount': totalCanceledCount,
            'unseenCount': newMessageCountCanceled,
            'color': _accentRed,
          },
        ];

        return Container(
          decoration: BoxDecoration(
            color: isDarkTheme ? const Color(0xFF151B2D) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color:
                  isDarkTheme
                      ? Colors.white.withOpacity(0.06)
                      : const Color(0xFFE8ECF3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkTheme ? 0.2 : 0.04),
                blurRadius: 16.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: List.generate(tabs.length, (index) {
                final tab = tabs[index];
                final isSelected = bookingsDetails == index + 1;
                final Color tabColor = tab['color'] as Color;
                final int totalCount = tab['totalCount'] as int;
                final int unseenCount = tab['unseenCount'] as int;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        bookingsDetails = index + 1;
                        bookingStatusNotifier.value = bookingsDetails;
                        _tabController.animateTo(index);
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 52.h,
                      decoration: BoxDecoration(
                        color: isSelected ? tabColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isSelected ? tabColor : Colors.transparent,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                tab['label'] as String,
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : (isDarkTheme
                                              ? Colors.white70
                                              : const Color(0xFF6B7280)),
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                  fontSize: 13.sp,
                                ),
                              ),
                              if (totalCount > 0) ...[
                                SizedBox(width: 6.w),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6.w,
                                        vertical: 1.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? Colors.white.withOpacity(0.3)
                                                : tabColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(
                                          20.r,
                                        ),
                                        border: Border.all(
                                          color:
                                              isSelected
                                                  ? Colors.white.withOpacity(
                                                    0.3,
                                                  )
                                                  : tabColor.withOpacity(0.3),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Text(
                                        '$totalCount',
                                        style: TextStyle(
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : tabColor,
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (unseenCount > 0) ...[
                                      SizedBox(width: 4.w),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 5.w,
                                          vertical: 1.h,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(0xFF22C55E),
                                              const Color(0xFF16A34A),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20.r,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF22C55E,
                                              ).withOpacity(0.3),
                                              blurRadius: 4.r,
                                              spreadRadius: 0,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '✦',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 8.sp,
                                              ),
                                            ),
                                            Text(
                                              '$unseenCount',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 9.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ],
                          ),
                          if (isSelected)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 3.h,
                                color: Colors.white.withOpacity(0.4),
                                margin: EdgeInsets.symmetric(horizontal: 16.w),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  String _getEmptyStateMessage() {
    final isHindi = isHindiNotifier.value;
    switch (bookingsDetails) {
      case 1:
        return isHindi
            ? 'इस महीने कोई लंबित बुकिंग नहीं'
            : 'No pending bookings for this month';
      case 2:
        return isHindi
            ? 'इस महीने कोई पूर्ण बुकिंग नहीं'
            : 'No completed bookings for this month';
      case 3:
        return isHindi
            ? 'इस महीने कोई रद्द बुकिंग नहीं'
            : 'No canceled bookings for this month';
      default:
        return isHindi ? 'कोई बुकिंग उपलब्ध नहीं' : 'No bookings available';
    }
  }

  Widget _buildEmptyState(String message, IconData icon, bool isDarkTheme) {
    return Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64.w,
                height: 64.w,
                decoration: BoxDecoration(
                  color: (isDarkTheme ? Colors.white : Colors.black)
                      .withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32.sp,
                  color: isDarkTheme ? Colors.white30 : Colors.grey[400],
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                message,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                  color: isDarkTheme ? Colors.white : const Color(0xFF172033),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  // ============================================================
  // MODERN BOOKINGS LIST - FIXED
  // ============================================================

  Widget _buildModernBookingsList(bool isDarkTheme) {
    return ValueListenableBuilder<bool>(
      valueListenable: isHindiNotifier,
      builder: (context, isHindi, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  isDarkTheme
                      ? [const Color(0xFF0B1020), const Color(0xFF151B2D)]
                      : [const Color(0xFFF0F2F8), const Color(0xFFE8ECF3)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: FutureBuilder<List<BookingsCard>>(
            future: futureCards,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Container(
                    width: 48.w,
                    height: 48.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.w,
                      color: _primaryBlue,
                    ),
                  ),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return _buildEmptyState(
                  isHindi
                      ? 'बुकिंग लोड करने में विफल'
                      : 'Failed to load bookings',
                  Icons.error_outline_rounded,
                  isDarkTheme,
                );
              }

              final bookingsList = _filterBookingsByStatus(snapshot.data ?? []);

              // ✅ FIX: Use addPostFrameCallback to avoid setState during build
              if (mounted && snapshot.data != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _updateAllCounts(snapshot.data!);
                  }
                });
              }

              if (bookingsList.isEmpty) {
                return _buildEmptyState(
                  _getEmptyStateMessage(),
                  Icons.calendar_today_rounded,
                  isDarkTheme,
                );
              }

              final List<Widget> items = [];

              for (int i = 0; i < bookingsList.length; i++) {
                final booking = bookingsList[i];

                items.add(
                  GestureDetector(
                    onTap: () {
                      _handleBookingCardTap(booking.id);
                    },
                    child: _buildModernBookingCard(booking, isDarkTheme),
                  ),
                );

                if (i < bookingsList.length - 1) {
                  items.add(SizedBox(height: 12.h));
                }
              }

              return ListView(padding: EdgeInsets.all(12.w), children: items);
            },
          ),
        );
      },
    );
  }
  // ============================================================
  // MODERN BOOKING CARD
  // ============================================================

  Widget _buildModernBookingCard(BookingsCard booking, bool isDarkTheme) {
    final rating = booking.rating;
    final review = booking.review;
    final isCompleted = booking.orderCompleted;
    final isCancelled = booking.cancelOrder;
    final hasNewMessage = getBookingStatus(booking.id) == true;
    final isSelfBooked = booking.userId == booking.vendorId;
    final isNotificationBooking =
        _highlightNotificationBooking && _highlightedBookingId == booking.id;
    final isHindi = isHindiNotifier.value;

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
          "${booking.bookingDate!.day}/${booking.bookingDate!.month}/${booking.bookingDate!.year}";
    }

    Color statusColor;
    String statusIcon;
    String statusLabel;

    if (isCancelled) {
      statusColor = _accentRed;
      statusIcon = '✕';
      statusLabel = isHindi ? 'रद्द' : 'Canceled';
    } else if (isCompleted) {
      statusColor = _accentGreen;
      statusIcon = '✓';
      statusLabel = isHindi ? 'पूर्ण' : 'Completed';
    } else {
      statusColor = _primaryBlue;
      statusIcon = '⏳';
      statusLabel = isHindi ? 'लंबित' : 'Pending';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDarkTheme
                  ? [const Color(0xFF151B2D), const Color(0xFF1A2240)]
                  : [Colors.white, Colors.white.withOpacity(0.95)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color:
              isNotificationBooking
                  ? _accentOrange
                  : hasNewMessage
                  ? _accentGreen.withOpacity(0.5)
                  : statusColor.withOpacity(0.15),
          width:
              isNotificationBooking
                  ? 3.w
                  : hasNewMessage
                  ? 2.w
                  : 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                isNotificationBooking
                    ? _accentOrange.withOpacity(0.3)
                    : hasNewMessage
                    ? _accentGreen.withOpacity(0.15)
                    : statusColor.withOpacity(0.06),
            blurRadius: isNotificationBooking ? 24.r : 16.r,
            spreadRadius: isNotificationBooking ? 4.r : 0,
            offset: Offset(0, isNotificationBooking ? 8.h : 4.h),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDarkTheme ? 0.15 : 0.04),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              color: statusColor.withOpacity(0.08),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24.w,
                        height: 24.w,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            statusIcon,
                            style: TextStyle(fontSize: 12.sp),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (hasNewMessage)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _accentGreen,
                                _accentGreen.withOpacity(0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            isHindi ? 'नया' : 'New',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (isNotificationBooking) ...[
                        if (hasNewMessage) SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _accentOrange,
                                _accentOrange.withOpacity(0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text('🔔', style: TextStyle(fontSize: 10.sp)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  // Header with Avatar
                  Row(
                    children: [
                      Container(
                        width: 48.w,
                        height: 48.w,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [statusColor, statusColor.withOpacity(0.6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14.r),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withOpacity(0.2),
                              blurRadius: 8.r,
                              offset: Offset(0, 4.h),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            booking.bookedById.name
                                .substring(0, 1)
                                .toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              capitalizeWords(booking.bookedById.name),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15.sp,
                                color:
                                    isDarkTheme
                                        ? Colors.white
                                        : const Color(0xFF172033),
                              ),
                            ),
                            Text(
                              'ID: #${booking.id.substring(0, booking.id.length > 8 ? 8 : booking.id.length)}',
                              style: TextStyle(
                                color:
                                    isDarkTheme
                                        ? Colors.white
                                        : const Color(0xFF6B7280),
                                fontSize: 10.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  // Details Grid
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color:
                          isDarkTheme
                              ? Colors.white.withOpacity(0.03)
                              : const Color(0xFFF8FAFD),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color:
                            isDarkTheme
                                ? Colors.white.withOpacity(0.06)
                                : const Color(0xFFE8ECF3),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildModernDetailRow(
                          '📞',
                          booking.bookedById.phoneNo.toString(),
                          isDarkTheme,
                        ),
                        _buildModernDivider(isDarkTheme),
                        _buildModernDetailRow('📍', village, isDarkTheme),
                        if (post.isNotEmpty) ...[
                          _buildModernDivider(isDarkTheme),
                          _buildModernDetailRow('🏤', post, isDarkTheme),
                        ],
                        if (district.isNotEmpty) ...[
                          _buildModernDivider(isDarkTheme),
                          _buildModernDetailRow('🏛️', district, isDarkTheme),
                        ],
                        _buildModernDivider(isDarkTheme),
                        _buildModernDetailRow(
                          '📅',
                          formattedDate,
                          isDarkTheme,
                          isColored: true,
                        ),
                        if (isSelfBooked) ...[
                          _buildModernDivider(isDarkTheme),
                          _buildModernDetailRow(
                            '👤',
                            isHindi ? 'स्वयं बुक' : 'Self Booked',
                            isDarkTheme,
                            isColored: true,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Rating Section for Completed
                  if (isCompleted) ...[
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color:
                            isDarkTheme
                                ? Colors.white.withOpacity(0.03)
                                : const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: _primaryPurple.withOpacity(0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 16.sp,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                '${isHindi ? 'रेटिंग' : 'Rating'}: ${_formatRating(rating)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.sp,
                                  color:
                                      isDarkTheme
                                          ? Colors.white
                                          : const Color(0xFF172033),
                                ),
                              ),
                            ],
                          ),
                          if (review != null && review.isNotEmpty) ...[
                            SizedBox(height: 4.h),
                            Text(
                              '"${_formatReview(review)}"',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 12.sp,
                                color:
                                    isDarkTheme
                                        ? Colors.white60
                                        : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Tap to view hint
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          size: 12.sp,
                          color:
                              isDarkTheme ? Colors.white30 : Colors.grey[400],
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          isHindi
                              ? 'विवरण देखने के लिए टैप करें'
                              : 'Tap to view details',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color:
                                isDarkTheme ? Colors.white30 : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HELPER WIDGETS
  // ============================================================

  Widget _buildModernDetailRow(
    String icon,
    String value,
    bool isDarkTheme, {
    bool isColored = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Text(icon, style: TextStyle(fontSize: 14.sp)),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              capitalizeWords(value),
              style: TextStyle(
                fontSize: 13.sp,
                color:
                    isColored
                        ? _primaryBlue
                        : (isDarkTheme
                            ? Colors.white70
                            : const Color(0xFF4B5563)),
                fontWeight: isColored ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDivider(bool isDarkTheme) {
    return Divider(
      height: 8.h,
      color:
          isDarkTheme
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFFE8ECF3),
    );
  }

  // ============================================================
  // HELPERS
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

  Set<DateTime> _extractBookedDatesByStatus(
    List<BookingsCard> bookings,
    int status,
  ) {
    bookingCountBySameDate.clear();
    final dates = <DateTime>{};

    for (final booking in bookings) {
      if (booking.bookingDate == null) continue;
      final date = DateTime(
        booking.bookingDate!.year,
        booking.bookingDate!.month,
        booking.bookingDate!.day,
      );
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

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
    }
    return dates;
  }

  Map<String, int> calculateBookingCategories(List<BookingsCard> bookingsList) {
    int pending = 0, completed = 0, canceled = 0;
    for (var booking in bookingsList) {
      if (booking.id.isEmpty) continue;
      if (booking.cancelOrder) {
        canceled++;
      } else if (booking.orderCompleted) {
        completed++;
      } else {
        pending++;
      }
    }
    return {'pending': pending, 'completed': completed, 'canceled': canceled};
  }

  String _getEnglishMonth(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  Color _getDateBackgroundColor() {
    switch (bookingsDetails) {
      case 1:
        return _primaryBlue.withOpacity(0.2);
      case 2:
        return _accentGreen.withOpacity(0.2);
      case 3:
        return _accentRed.withOpacity(0.2);
      default:
        return Colors.transparent;
    }
  }

  Color _getDateBorderColor(int status) {
    switch (status) {
      case 1:
        return _primaryBlue;
      case 2:
        return _accentGreen;
      case 3:
        return _accentRed;
      default:
        return Colors.transparent;
    }
  }

  Color _getDateTextColor(int status) {
    switch (status) {
      case 1:
        return _primaryBlue;
      case 2:
        return _accentGreen;
      case 3:
        return _accentRed;
      default:
        return const Color(0xFF172033);
    }
  }

  Color _getDateMarkerColor(int status) {
    switch (status) {
      case 1:
        return _primaryBlue;
      case 2:
        return _accentGreen;
      case 3:
        return _accentRed;
      default:
        return Colors.transparent;
    }
  }

  String capitalizeWords(String? input) {
    if (input == null) return '';
    return input
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '',
        )
        .join(' ');
  }

  String _formatRating(int rating) => rating == 0 ? 'Not Rated' : '$rating/5';
  String _formatReview(String? review) =>
      review == null || review.trim().isEmpty ? 'No review' : review;
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

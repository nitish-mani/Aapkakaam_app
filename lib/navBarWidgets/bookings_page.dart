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
  // State variables
  Future<List<BookingsCard>>? futureCards;
  int bookingsDetails = bookingStatusNotifier.value;
  VendorModel? vendor;
  DateTime selectedDate = DateTime.now();
  late Map<String, bool> isLoading;
  late Map<String, bool> isPermissionGranted;
  final ScrollController _scrollController = ScrollController();
  VoidCallback? _refreshListener;
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;

  // Counters
  int newMessageCountPending = 0;
  int newMessageCountComplete = 0;
  int newMessageCountCanceled = 0;
  final bookingCountBySameDate = <String, int>{};

  // Track if calendar should be expanded
  bool _isCalendarExpanded = true;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    isLoading = {};
    isPermissionGranted = {};
    _setupRefreshListener();
    loadUserData();

    _notificationSubscription = FirebaseNotifications.notificationClickStream
        .listen((data) {
          _handleNotificationClick(data);
        });

    // Add scroll listener
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    final currentOffset = _scrollController.offset;
    final maxScroll = _scrollController.position.maxScrollExtent;

    // If scrolling up and at the top, expand calendar
    if (currentOffset <= 0) {
      if (!_isCalendarExpanded) {
        setState(() {
          _isCalendarExpanded = true;
        });
        isCalendarCollapsedNotifier.value = false;
      }
    }
    // If scrolling down, collapse calendar
    else if (currentOffset > _lastScrollOffset && currentOffset > 100) {
      if (_isCalendarExpanded) {
        setState(() {
          _isCalendarExpanded = false;
        });
        isCalendarCollapsedNotifier.value = true;
      }
    }

    _lastScrollOffset = currentOffset;
  }

  void _handleNotificationClick(Map<String, dynamic> data) {
    print('Notification clicked with data: $data');

    final type = data['type'];

    switch (type) {
      case 'booking':
        selectedPageNotifier.value = isVendor.value ? 1 : 2;
        bookingStatusNotifier.value = 1;
        if (isVendor.value) {
          monthNotifier.value = int.parse(data['month']) + 1;
          yearNotifier.value = int.parse(data['year']);
        }
        break;

      case 'cancelled':
        selectedPageNotifier.value = isVendor.value ? 1 : 2;
        bookingStatusNotifier.value = 3;
        if (isVendor.value) {
          monthNotifier.value = int.parse(data['month']) + 1;
          yearNotifier.value = int.parse(data['year']);
        }
        break;

      case 'profile_update':
        profileRefreshNotifier.value = !profileRefreshNotifier.value;
        break;

      default:
        if (data['screen'] == 'profile') {
          // Handle profile navigation
        }
    }
  }

  @override
  void dispose() {
    if (_refreshListener != null) {
      bookingsRefreshNotifier.removeListener(_refreshListener!);
    }
    _notificationSubscription?.cancel();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _setupRefreshListener() {
    _refreshListener = () {
      if (mounted) {
        setState(() {
          if (monthNotifier.value != 0 || yearNotifier.value != 0) {
            selectedDate = DateTime(yearNotifier.value, monthNotifier.value);
          }
        });
        loadUserData();
      }
    };
    bookingsRefreshNotifier.addListener(_refreshListener!);
  }

  // Helper methods
  bool? getBookingStatus(String? id) =>
      id == null ? null : bookingIdNotifier.value[id];

  void upsertBooking(String id, bool value) {
    bookingIdNotifier.value = {...bookingIdNotifier.value, id: value};
  }

  void initializeIsLoadingFromResponse(List<BookingsCard> bookings) {
    // Filter out bookings with empty IDs
    final validBookings = bookings.where((b) => b.id.isNotEmpty).toList();

    isPermissionGranted = {
      for (var booking in validBookings) booking.id: false,
    };
    isLoading = {for (var booking in validBookings) booking.id: false};

    final updatedBookingIds = {...bookingIdNotifier.value};
    for (final booking in validBookings) {
      updatedBookingIds[booking.id] = false;
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

  Future<void> loadUserDataFromNotification(month, year) async {
    final prefs = await SharedPreferences.getInstance();
    final vendorData = prefs.getString('vendor');

    if (vendorData != null) {
      final decodedVendor = jsonDecode(vendorData);
      vendor = VendorModel.fromJson(decodedVendor);
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

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final vendorData = prefs.getString('vendor');

    if (vendorData != null) {
      final decodedVendor = jsonDecode(vendorData);
      vendor = VendorModel.fromJson(decodedVendor);
      setState(() {
        futureCards = fetchBookings(
          decodedVendor['vendorId'],
          selectedDate.month - 1,
          selectedDate.year,
          'Bearer ${decodedVendor['token']}',
        );
      });
    }
  }

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

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        print(decodedResponse);
        List<BookingsCard> bookings = [];

        // Helper to safely convert dynamic map to Map<String, dynamic>
        Map<String, dynamic> toSafeMap(dynamic value) {
          if (value == null) return {};
          if (value is Map<String, dynamic>) return value;
          if (value is Map<dynamic, dynamic>) {
            return Map<String, dynamic>.from(value);
          }
          return {};
        }

        if (decodedResponse is List) {
          for (var item in decodedResponse) {
            try {
              Map<String, dynamic> safeItem = toSafeMap(item);

              // The item itself is the booking data
              Map<String, dynamic> bookingData = safeItem;

              // Print for debugging
              print(
                'Processing booking: ${bookingData['_id']} - orderCompleted: ${bookingData['orderCompleted']}',
              );

              final booking = BookingsCard.fromJson(bookingData);
              bookings.add(booking);
            } catch (e) {
              print('Error parsing booking: $e');
              print('Problematic item: $item');
              continue;
            }
          }
        } else if (decodedResponse is Map &&
            decodedResponse.containsKey('data')) {
          final dataList = decodedResponse['data'] as List? ?? [];
          for (var item in dataList) {
            try {
              Map<String, dynamic> safeItem = toSafeMap(item);

              // Check if the booking has the 'booking' field or is the booking itself
              Map<String, dynamic> bookingData;
              if (safeItem.containsKey('booking')) {
                bookingData = toSafeMap(safeItem['booking']);
              } else {
                bookingData = safeItem;
              }

              print(
                'Processing booking: ${bookingData['_id']} - orderCompleted: ${bookingData['orderCompleted']}',
              );

              final booking = BookingsCard.fromJson(bookingData);
              bookings.add(booking);
            } catch (e) {
              print('Error parsing booking: $e');
              print('Problematic item: $item');
              continue;
            }
          }
        } else {
          print('Unexpected response format: $decodedResponse');
        }

        print('Bookings loaded: ${bookings.length}');

        // Debug: Print booking statuses
        for (var booking in bookings) {
          print(
            'Booking ${booking.id}: cancelOrder=${booking.cancelOrder}, orderCompleted=${booking.orderCompleted}',
          );
        }

        initializeIsLoadingFromResponse(bookings);
        return bookings;
      } else {
        debugPrint('fetchBookings failed with status: ${response.statusCode}');
        debugPrint('fetchBookings response body: ${response.body}');
        throw Exception('Failed to fetch bookings: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('fetchBookings error: $e');
      return [];
    }
  }

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
                              snap:
                                  false, // Changed to false for better control
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
            'Filtered bookings for status $bookingsDetails: ${bookingsList.length}',
          );

          if (bookingsList.isEmpty) {
            return Center(
              child: Column(
                children: [
                  SizedBox(height: 18),
                  const Center(child: BannerAdWidget()),
                  SizedBox(height: 18),
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
                return Column(
                  children: [
                    if (index % 3 == 0) ...[
                      const Center(child: BannerAdWidget()),
                      SizedBox(height: 8),
                    ],
                    _buildBookingCard(bookingsList[index], isDarkTheme),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(BuildContext context, bool isDarkTheme) {
    final theme = Theme.of(context);
    final colorScheme =
        isDarkTheme
            ? ColorScheme.light(
              primary: Colors.amber,
              onPrimary: Colors.teal,
              onSurface: Colors.white,
            )
            : ColorScheme.dark(
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

  Widget _buildCalendarSection(bool isDarkTheme) {
    return FutureBuilder<List<BookingsCard>>(
      future: futureCards,
      builder: (context, snapshot) {
        final bookedDates =
            snapshot.hasData
                ? _extractBookedDatesByStatus(snapshot.data!, bookingsDetails)
                : <DateTime>{};

        // Get today's date
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);

        // Check if there's a booking today
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
              todayDecoration: BoxDecoration(
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

                // If it's today, let the todayBuilder handle it
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
                        child: Container(
                          padding: EdgeInsets.all(2.w),
                          constraints: BoxConstraints(
                            minWidth: 16.w,
                            minHeight: 16.h,
                          ),
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
                              '${bookingCountBySameDate['${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}']}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
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
                        // Always purple for today
                        color: Colors.purple,
                        shape: BoxShape.circle,
                        // If booking exists, add colored border
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
                        child: Container(
                          padding: EdgeInsets.all(2.w),
                          constraints: BoxConstraints(
                            minWidth: 16.w,
                            minHeight: 16.h,
                          ),
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
                              '${bookingCountBySameDate['${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}']}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
              markerBuilder: (context, date, events) {
                final hasBooking = bookedDates.any((d) => isSameDay(d, date));
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

                if (matchingBookings.isEmpty) return const SizedBox.shrink();

                final bookingForMarker = matchingBookings.first;

                return Positioned(
                  bottom: -3.h,
                  child: Container(
                    width: 12.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: _getDateMarkerColor(bookingForMarker),
                      border:
                          (matchingBookings.isNotEmpty &&
                                  _getDateMarkerColor(bookingForMarker) !=
                                      Colors.transparent)
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

  Set<DateTime> _extractBookedDatesByStatus(
    List<BookingsCard> bookings,
    int status,
  ) {
    bookingCountBySameDate.clear();
    final dates = <DateTime>{};

    for (final booking in bookings) {
      try {
        // Skip if bookingDate is null
        if (booking.bookingDate == null) {
          continue;
        }

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
      } catch (e) {
        print('Date parsing error: $e');
      }
    }
    return dates;
  }

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
                decoration: BoxDecoration(
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

  Map<String, int> calculateBookingCategories(List<BookingsCard> bookingsList) {
    int pending = 0;
    int completed = 0;
    int canceled = 0;

    for (var booking in bookingsList) {
      // Skip if booking ID is empty
      if (booking.id.isEmpty) continue;

      // Count based on actual booking status - FIXED: removed bookingStatus check
      if (booking.cancelOrder == true) {
        canceled++;
      } else if (booking.orderCompleted == true) {
        completed++;
      } else if (booking.cancelOrder == false &&
          booking.orderCompleted == false) {
        pending++;
      }
    }

    print(
      'Categories - Pending: $pending, Completed: $completed, Canceled: $canceled',
    );
    return {'pending': pending, 'completed': completed, 'canceled': canceled};
  }

  List<BookingsCard> _filterBookingsByStatus(List<BookingsCard> bookings) {
    return bookings.where((booking) {
      switch (bookingsDetails) {
        case 1:
          return booking.cancelOrder == false &&
              booking.orderCompleted == false;
        case 2:
          return booking.orderCompleted == true;
        case 3:
          return booking.cancelOrder == true;
        default:
          return true;
      }
    }).toList();
  }

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

  int calculateNewNotificationCount(Map<String, bool> data) {
    int count = 0;
    data.forEach((key, value) {
      if (value) {
        count++;
      }
    });
    return count;
  }

  Widget _buildBookingCard(BookingsCard booking, bool isDarkTheme) {
    final rating = booking.rating;
    final review = booking.review;
    final isCompleted = booking.orderCompleted;
    final isCancelled = booking.cancelOrder;
    final hasNewMessage = getBookingStatus(booking.id) == true;
    final isSelfBooked = booking.userId == booking.vendorId;
    // Extract address from the first address object
    final address =
        booking.bookedById.address.isNotEmpty
            ? booking.bookedById.address.first
            : null;

    final village = isSelfBooked ? booking.vill : address?.vill ?? '';
    final post = isSelfBooked ? booking.post : address?.post ?? '';
    final district = isSelfBooked ? booking.dist : address?.dist ?? '';

    // Format date safely
    String formattedDate = 'Date not available';
    if (booking.bookingDate != null) {
      formattedDate =
          "${booking.bookingDate!.day}/${booking.bookingDate!.month}/${booking.bookingDate!.year}";
    }

    return InkWell(
      onTap: () {
        if (booking.id.isNotEmpty && hasNewMessage) {
          upsertBooking(booking.id, false);
          bookingCountNotifier.value = calculateNewNotificationCount(
            bookingIdNotifier.value,
          );
          setState(() => loadUserData());
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isDarkTheme ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(8.r),
        ),
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
                    isReview: true, // This will show review in a box
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
    );
  }

  String _formatRating(int rating) {
    if (rating == 0) return 'Not Rated';
    return '$rating/5';
  }

  String _formatReview(String? review) {
    if (review == null || review.trim().isEmpty) {
      return 'Not Reviewed';
    }
    return review;
  }

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

  Widget _buildOrderTab(String text, int value, Color color, bool isDarkTheme) {
    final isSelected = bookingsDetails == value;

    return GestureDetector(
      onTap:
          () => setState(() {
            bookingStatusNotifier.value = value;
            bookingsDetails = value;
          }),
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

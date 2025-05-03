import 'dart:async';
import 'dart:convert';
import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/models/data_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  _BookingsPageState createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  // State variables
  Future<List<dynamic>>? futureCards;
  int bookingsDetails = bookingStatusNotifier.value;
  VendorModel? vendor;
  DateTime selectedDate = DateTime.now();
  late Map<dynamic, bool> isLoading;
  late Map<dynamic, bool> isPermissionGranted;
  final ScrollController _scrollController = ScrollController();
  // double _calendarHeight = 300.h;

  // Counters
  int newMessageCountPending = 0;
  int newMessageCountComplete = 0;
  int newMessageCountCanceled = 0;
  final bookingCountBySameDate = <String, int>{};

  @override
  void initState() {
    super.initState();
    isLoading = {};
    isPermissionGranted = {};
    _setupRefreshListener();
    loadUserData();
  }

  @override
  void dispose() {
    bookingsRefreshNotifier.removeListener(_setupRefreshListener);
    super.dispose();
  }

  void _setupRefreshListener() {
    bookingsRefreshNotifier.addListener(() {
      if (mounted) {
        setState(() {
          if (monthNotifier.value != 0 || yearNotifier.value != 0) {
            selectedDate = DateTime(yearNotifier.value, monthNotifier.value);
          }
        });
        loadUserData();
      }
    });
  }

  // Helper methods
  bool? getBookingStatus(String? id) =>
      id == null ? null : bookingIdNotifier.value[id];

  void upsertBooking(String id, bool value) {
    bookingIdNotifier.value = {...bookingIdNotifier.value, id: value};
  }

  void initializeIsLoadingFromResponse(List<dynamic> response) {
    final bookings = response;
    isPermissionGranted = {
      for (var booking in bookings)
        booking['booking']['bookingId']?.toString() ?? '': false,
    };

    isLoading = {
      for (var booking in bookings)
        booking['booking']['bookingId']?.toString() ?? '': false,
    };

    final updatedBookingIds = {...bookingIdNotifier.value};
    for (final booking in bookings) {
      final bookingId = booking['booking']['bookingId']?.toString() ?? '';
      if (bookingId.isEmpty) {
        updatedBookingIds[bookingId] = false;
      }
    }
    bookingIdNotifier.value = updatedBookingIds;

    setState(() {
      final bookingCategories = calculateBookingCategories(response);
      newMessageCountPending = bookingCategories['pending']!;
      newMessageCountComplete = bookingCategories['completed']!;
      newMessageCountCanceled = bookingCategories['canceled']!;
    });
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

  // API calls
  Future<void> handleGrantPermission({
    required BuildContext context,
    required String bookingId,
    required String token,
  }) async {
    setState(() {
      isLoading[bookingId] = true;
    });
    try {
      final url = Uri.parse("${KConstantURL.url}/bookings/ratingPermission");
      final response = await http.patch(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"bookingId": bookingId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          isPermissionGranted[bookingId] = true;
          isLoading[bookingId] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Center(
              child: Text(
                data['message'],
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        final error = jsonDecode(response.body);
        setState(() {
          isLoading[bookingId] = false;
        });
        throw Exception(error['message'] ?? "Something went wrong");
      }
    } catch (e) {
      setState(() {
        isLoading[bookingId] = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e", style: TextStyle(fontSize: 14.sp)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> grantPermission(String bookingId) async {
    final prefs = await SharedPreferences.getInstance();
    final vendorData = prefs.getString('vendor');

    updateLoadingState(bookingId, true);
    if (vendorData != null) {
      final decodedVendor = jsonDecode(vendorData);
      vendor = VendorModel.fromJson(decodedVendor);
      setState(() {
        handleGrantPermission(
          context: context,
          bookingId: bookingId,
          token: decodedVendor['token'],
        );
      });
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

  Future<List<dynamic>> fetchBookings(
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
        initializeIsLoadingFromResponse(decodedResponse);

        return decodedResponse is List
            ? decodedResponse
            : (decodedResponse is Map && decodedResponse.containsKey('data'))
            ? decodedResponse['data'] ?? []
            : [];
      }
      return [];
    } catch (e) {
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
                      physics: ClampingScrollPhysics(),
                      headerSliverBuilder:
                          (context, innerBoxIsScrolled) => [
                            SliverAppBar(
                              pinned: false,
                              floating: true,
                              snap: true,
                              stretch: true,
                              primary: false,
                              expandedHeight: 328.h,
                              collapsedHeight:
                                  kToolbarHeight +
                                  8.h, // Minimum required height
                              elevation:
                                  0, // optional: remove shadow when floating in
                              // automaticallyImplyLeading:
                              //     false, // optional if you don't want back button
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
                                          : visibleHeight / kToolbarHeight;
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    isCalendarCollapsedNotifier.value =
                                        isCollapsed;
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
                                minHeight: 60.h,
                                maxHeight: 60.h,
                                child: ValueListenableBuilder<bool>(
                                  valueListenable: isCalendarCollapsedNotifier,
                                  builder: (context, isCollapsed, _) {
                                    return Container(
                                      padding: EdgeInsets.fromLTRB(
                                        8.w,
                                        isCollapsed ? 8.h : 0,
                                        8.w,
                                        0,
                                      ),

                                      color:
                                          isDarkTheme
                                              ? Colors.teal
                                              : Colors.amber,
                                      child: _buildStatusTabs(isDarkTheme),
                                    );
                                  },
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
      // padding: EdgeInsets.(8.w),
      decoration: BoxDecoration(
        color: isDarkTheme ? Colors.teal : Colors.amber,
      ),
      child: FutureBuilder<List<dynamic>>(
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
            return Center(child: Icon(Icons.error_outline, size: 40.sp));
          }

          final bookingsList = _filterBookingsByStatus(snapshot.data ?? []);

          if (bookingsList.isEmpty) {
            return Center(
              child: Text(
                _getEmptyStateMessage(),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                textAlign: TextAlign.center,
              ),
            );
          }

          // PROPERLY SCROLLABLE LIST
          return Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: isDarkTheme ? Colors.teal : Colors.amber,
            ),
            child: ListView.separated(
              itemCount: bookingsList.length,
              separatorBuilder: (context, index) => SizedBox(height: 5.h),
              itemBuilder: (context, index) {
                return _buildBookingCard(
                  bookingsList[index]['booking'],
                  isDarkTheme,
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
    return FutureBuilder<List<dynamic>>(
      future: futureCards,
      builder: (context, snapshot) {
        final bookedDates =
            snapshot.hasData
                ? _extractBookedDatesByStatus(snapshot.data!, bookingsDetails)
                : <DateTime>{};

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
              markerBuilder: (context, date, events) {
                final hasBooking = bookedDates.any((d) => isSameDay(d, date));
                if (!hasBooking) return SizedBox.shrink();

                final matchingBookings =
                    snapshot.data!.where((booking) {
                      final b = booking['booking'];
                      final bookingDate = DateTime(
                        b['year'],
                        b['month'] + 1,
                        b['date'],
                      );
                      return isSameDay(bookingDate, date);
                    }).toList();

                if (matchingBookings.isEmpty) return SizedBox.shrink();

                final bookingForMarker = matchingBookings.first;

                return Positioned(
                  bottom: -3.h,
                  child: Container(
                    width: 12.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: _getDateMarkerColor(bookingForMarker['booking']),
                      border:
                          (matchingBookings.isNotEmpty &&
                                  _getDateMarkerColor(
                                        bookingForMarker['booking'],
                                      ) !=
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

                futureCards = fetchBookings(
                  vendor!.vendorId,
                  focusedDay.month - 1,
                  focusedDay.year,
                  'Bearer ${vendor!.token}',
                );
              });
            },
          ),
        );
      },
    );
  }

  Set<DateTime> _extractBookedDatesByStatus(
    List<dynamic> bookings,
    int status,
  ) {
    bookingCountBySameDate.clear();
    final dates = <DateTime>{};

    for (final booking in bookings) {
      final b = booking['booking'];
      try {
        final date = DateTime(b['year'], b['month'] + 1, b['date']);
        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        final isPending = !b['cancelOrder'] && !b['orderCompleted'];
        final isCompleted = b['orderCompleted'];
        final isCanceled = b['cancelOrder'];

        bool shouldInclude = false;

        if (status == 1 && isPending) {
          shouldInclude = true;
        } else if (status == 2 && isCompleted) {
          shouldInclude = true;
        } else if (status == 3 && isCanceled) {
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

  Color _getDateMarkerColor(bookings) {
    final hasNewMessage = getBookingStatus(bookings['bookingId']) == true;
    final status =
        bookingsDetails == 1
            ? 'pending'
            : bookingsDetails == 2
            ? 'completed'
            : 'canceled';

    if ((status == 'pending') && hasNewMessage) {
      return Colors.green;
    } else if ((status == 'canceled') && hasNewMessage) {
      return Colors.green;
    }
    return Colors.transparent;
  }

  Widget _buildStatusTabs(bool isDarkTheme) {
    return Container(
      height: 60.h,
      padding: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: isDarkTheme ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                  color: Colors.green,
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

  Map<String, int> calculateBookingCategories(List<dynamic> bookingsList) {
    int pending = 0;
    int completed = 0;
    int canceled = 0;

    for (var element in bookingsList) {
      final booking = element['booking'];
      final bookingStatus = getBookingStatus(booking['bookingId']);
      if (booking['cancelOrder'] == true && bookingStatus == true) {
        canceled++;
      } else if (booking['orderCompleted'] == true && bookingStatus == true) {
        completed++;
      } else if (booking['cancelOrder'] == false &&
          booking['orderCompleted'] == false &&
          bookingStatus == true) {
        pending++;
      }
    }
    return {'pending': pending, 'completed': completed, 'canceled': canceled};
  }

  List<dynamic> _filterBookingsByStatus(List<dynamic> bookings) {
    return bookings.where((element) {
      final booking = element['booking'];
      switch (bookingsDetails) {
        case 1:
          return booking['cancelOrder'] == false &&
              booking['orderCompleted'] == false;
        case 2:
          return booking['orderCompleted'] == true;
        case 3:
          return booking['cancelOrder'] == true;
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

  Widget _buildBookingCard(Map<String, dynamic> booking, bool isDarkTheme) {
    final rating = booking['rating'] ?? 0;
    final isCompleted = booking['orderCompleted'] == true;
    final isCancelled = booking['cancelOrder'] == true;
    final hasNewMessage = getBookingStatus(booking['bookingId']) == true;

    return InkWell(
      onTap: () {
        if (booking['bookingId'] != null && hasNewMessage) {
          upsertBooking(booking['bookingId'], false);
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
            _buildInfoRow('Name', booking['name'], booking['bookingId']),
            _buildInfoRow(
              'Mobile',
              booking['phoneNo'].toString(),
              booking['bookingId'],
            ),
            _buildInfoRow(
              'Village',
              booking['address']['vill'],
              booking['bookingId'],
            ),
            _buildInfoRow(
              'Post Office',
              booking['address']['post'],
              booking['bookingId'],
            ),
            _buildInfoRow(
              'District',
              booking['address']['dist'],
              booking['bookingId'],
            ),
            _buildInfoRow(
              'Date',
              "${booking['date']}/${booking['month'] + 1}/${booking['year']}",
              booking['bookingId'],
              isColored: true,
            ),
            if (bookingsDetails == 2)
              _buildInfoRow(
                'Rating',
                _formatRating(rating),
                booking['bookingId'],
              ),
            _buildInfoRow(
              'Status',
              isCompleted
                  ? "Completed"
                  : isCancelled
                  ? "Canceled"
                  : "Pending",
              booking['bookingId'],
              isColored: true,
              color: _getStatusColor(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRating(dynamic rating) {
    if (rating == null || rating == 0) return 'Not Rated';
    final numericRating = rating is int ? rating : rating;
    return '${(numericRating)}/5';
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
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: isColored ? color : null,
            ),
          ),
          if (label == 'Rating' && value == 'Not Rated')
            _buildRatingAction(bookingId)
          else
            Text(
              capitalizeWords(value),
              style: TextStyle(
                fontSize: 12.sp,
                color: isColored ? color : null,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRatingAction(String? bookingId) {
    return Row(
      children: [
        Text('Not Rated', style: TextStyle(fontSize: 12.sp)),
        if (isBefore5PM(selectedDate) &&
            !isLoading[bookingId]! &&
            !isPermissionGranted[bookingId]!)
          InkWell(
            onTap: () => grantPermission(bookingId!),
            child: Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: Text(
                "Grant Permission",
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                ),
              ),
            ),
          )
        else if (isLoading[bookingId]!)
          Padding(
            padding: EdgeInsets.only(left: 8.w),
            child: SizedBox(
              width: 15.w,
              height: 15.h,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
      ],
    );
  }

  bool isBefore5PM(DateTime selectedDate) {
    final fivePM = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      17,
      0,
    );
    return DateTime.now().isBefore(fivePM);
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

import 'dart:convert';
import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/widgets/banner_ad_widget.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

class CreateBooking extends StatefulWidget {
  const CreateBooking({super.key});

  @override
  State<CreateBooking> createState() => _CreateBookingState();
}

class _CreateBookingState extends State<CreateBooking> {
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final FocusNode _pincodeFocusNode = FocusNode();

  // Date related variables
  DateTime selectedDate = selectedDateNotifier.value;
  late DateTime _focusedDay;
  late CalendarFormat _calendarFormat;
  final DateTime firstDate = DateTime.now();
  final DateTime lastDate = DateTime.now().add(const Duration(days: 90));
  Set<DateTime> pendingBookingDates = {};

  // State variables
  String _errorMessage = '';
  bool _isLoading = false;
  bool _isLoading1 = false;
  bool _isBooking = false;
  bool isLoadingBookings = false;
  List<String> _postOffices = [];
  String? _selectedPost;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _calendarFormat = CalendarFormat.month;
    _dateController.text = _formatDate(selectedDate);
    _fetchPendingBookings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _villageController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _dateController.dispose();
    _pincodeFocusNode.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Convert UTC date to Asia/Kolkata local time
  DateTime _toAsiaKolkataTime(DateTime utcDate) {
    return utcDate.add(const Duration(hours: 5, minutes: 30));
  }

  // Helper method to parse date from various formats and convert to Asia/Kolkata timezone
  DateTime? _parseDateFromBooking(Map<String, dynamic> bookingData) {
    try {
      if (bookingData.containsKey('bookingDate') &&
          bookingData['bookingDate'] != null) {
        final dateStr = bookingData['bookingDate'].toString();

        if (dateStr.contains('T')) {
          try {
            final utcDate = DateTime.parse(dateStr);
            final localDate = _toAsiaKolkataTime(utcDate);
            return DateTime(localDate.year, localDate.month, localDate.day);
          } catch (e) {
            print('Error parsing ISO date: $e');
          }
        }

        try {
          final date = DateTime.parse(dateStr);
          if (date.isUtc) {
            final localDate = _toAsiaKolkataTime(date);
            return DateTime(localDate.year, localDate.month, localDate.day);
          }
          return DateTime(date.year, date.month, date.day);
        } catch (e) {
          // Fall through to individual fields
        }
      }

      if (bookingData.containsKey('year') &&
          bookingData.containsKey('month') &&
          bookingData.containsKey('date')) {
        final year = bookingData['year'] as int?;
        final month = bookingData['month'] as int?;
        final day = bookingData['date'] as int?;
        if (year != null && month != null && day != null) {
          return DateTime(year, month + 1, day);
        }
      }

      if (bookingData.containsKey('date') && bookingData['date'] is String) {
        try {
          final dateStr = bookingData['date'].toString();
          final date = DateTime.parse(dateStr);
          if (date.isUtc) {
            final localDate = _toAsiaKolkataTime(date);
            return DateTime(localDate.year, localDate.month, localDate.day);
          }
          return DateTime(date.year, date.month, date.day);
        } catch (e) {
          // Ignore
        }
      }

      return null;
    } catch (e) {
      print('Error parsing date: $e');
      return null;
    }
  }

  Future<void> _fetchPendingBookings() async {
    setState(() => isLoadingBookings = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final vendorData = prefs.getString('vendor');
      if (vendorData == null) return;

      final decoded = jsonDecode(vendorData);
      final token = 'Bearer ${decoded['token']}';
      final userId = decoded['vendorId'];

      final response = await http
          .get(
            Uri.parse(
              "${KConstantURL.url}/vendor/getBookings/$userId/${_focusedDay.month - 1}/${_focusedDay.year}",
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': token,
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        List<dynamic> bookings;
        if (responseData is List) {
          bookings = responseData;
        } else if (responseData is Map && responseData.containsKey('orders')) {
          bookings = responseData['orders'] as List? ?? [];
        } else if (responseData is Map && responseData.containsKey('data')) {
          bookings = responseData['data'] as List? ?? [];
        } else {
          bookings = [];
        }

        print('Raw bookings count: ${bookings.length}');

        final extractedDates = _extractPendingBookingDates(bookings);
        setState(() {
          pendingBookingDates = extractedDates;
        });
        bookingPendingNotifier.value = extractedDates;
        print('Pending dates found: ${extractedDates.length}');
        for (var date in extractedDates) {
          print(
            'Pending (Asia/Kolkata): ${date.day}/${date.month}/${date.year}',
          );
        }
      } else {
        print('Failed to fetch bookings: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching pending bookings: $e');
    } finally {
      setState(() => isLoadingBookings = false);
    }
  }

  Set<DateTime> _extractPendingBookingDates(List<dynamic> bookings) {
    final dates = <DateTime>{};

    for (final booking in bookings) {
      try {
        if (booking is Map<String, dynamic>) {
          Map<String, dynamic> bookingData;

          if (booking.containsKey('booking') && booking['booking'] != null) {
            bookingData = booking['booking'] as Map<String, dynamic>;
          } else {
            bookingData = booking;
          }

          final isPending =
              !(bookingData['cancelOrder'] ?? false) &&
              !(bookingData['orderCompleted'] ?? false);

          print('Booking ${bookingData['_id']}: isPending=$isPending');

          if (isPending) {
            final bookingDate = _parseDateFromBooking(bookingData);

            if (bookingDate != null) {
              final normalizedDate = normalizeDate(bookingDate);
              dates.add(normalizedDate);
              print(
                'Added pending date: ${normalizedDate.day}/${normalizedDate.month}/${normalizedDate.year}',
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Date parsing error: $e');
      }
    }
    return dates;
  }

  Color _getDateBackgroundColor() {
    return isDarkThemeNotifier.value
        ? Colors.teal.withOpacity(0.7)
        : Colors.amber.withOpacity(0.7);
  }

  // Custom method to show SnackBar on top of the calendar using Overlay
  // Custom method to show SnackBar on top of the calendar using Overlay
  void _showCalendarSnackBar(
    String message,
    Color backgroundColor,
    IconData icon,
  ) {
    // Get the overlay state
    final overlay = Overlay.of(context);

    // Declare overlayEntry first
    late OverlayEntry overlayEntry;

    // Create an overlay entry
    overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: MediaQuery.of(context).size.height * 0.05,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (overlayEntry.mounted) {
                          overlayEntry.remove();
                        }
                      },
                      child: Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    // Insert the overlay entry
    overlay.insert(overlayEntry);

    // Auto remove after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  Widget _buildCalendar(MediaQueryData mediaQuery) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = mediaQuery.size.width;
    final today = normalizeDate(DateTime.now());

    return ValueListenableBuilder(
      valueListenable: bookingPendingNotifier,
      builder: (context, pendingDatesFromNotifier, child) {
        final pendingDates =
            pendingDatesFromNotifier.isNotEmpty
                ? pendingDatesFromNotifier
                : pendingBookingDates;

        print('Calendar rebuilding with ${pendingDates.length} pending dates');

        return ValueListenableBuilder(
          valueListenable: selectedDateNotifier,
          builder: (context, selectedDate1, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoadingBookings)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                      width: 1.5,
                    ),
                  ),
                  child: TableCalendar(
                    firstDay: firstDate,
                    lastDay: lastDate,
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate:
                        (day) => isSameDay(selectedDateNotifier.value, day),

                    onDaySelected: (selectedDay, focusedDay) {
                      final isPendingDate = pendingDates.any(
                        (d) => isSameDay(d, selectedDay),
                      );

                      if (isPendingDate) {
                        // Show custom SnackBar on top of calendar
                        _showCalendarSnackBar(
                          'You cannot select a pending booking date.',
                          Colors.red,
                          Icons.warning_amber_rounded,
                        );
                        return;
                      }

                      selectedDateNotifier.value = selectedDay;
                      setState(() {
                        _focusedDay = focusedDay;
                      });

                      // Show success message
                      _showCalendarSnackBar(
                        'Date selected: ${selectedDay.day}/${selectedDay.month}/${selectedDay.year}',
                        Colors.green,
                        Icons.check_circle_outline,
                      );
                    },
                    onFormatChanged:
                        (format) => setState(() => _calendarFormat = format),
                    onPageChanged: (focusedDay) async {
                      setState(() {
                        _focusedDay = focusedDay;
                      });
                      await _fetchPendingBookings();
                      setState(() {});
                    },
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      defaultDecoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                      ),
                      weekendDecoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                      ),
                      selectedDecoration: BoxDecoration(
                        color:
                            isDarkThemeNotifier.value
                                ? Colors.amber
                                : Colors.teal,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: const BoxDecoration(
                        color: Colors.purple,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        size: screenWidth * 0.06,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        size: screenWidth * 0.06,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.035,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                      weekendStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.035,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focusedDay) {
                        final hasPendingBooking = pendingDates.any(
                          (d) => isSameDay(d, day),
                        );
                        final isToday = isSameDay(day, today);

                        final showPendingColor =
                            hasPendingBooking &&
                            !isSameDay(selectedDateNotifier.value, day) &&
                            !isToday;

                        return Container(
                          margin: const EdgeInsets.all(4.0),
                          decoration: BoxDecoration(
                            color:
                                showPendingColor
                                    ? _getDateBackgroundColor()
                                    : null,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color:
                                  isDarkThemeNotifier.value
                                      ? Colors.white
                                      : Colors.black,
                              fontWeight:
                                  hasPendingBooking
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              fontSize: screenWidth * 0.04,
                            ),
                          ),
                        );
                      },
                      selectedBuilder: (context, day, focusedDay) {
                        final hasPendingBooking = pendingDates.any(
                          (d) => isSameDay(d, day),
                        );
                        final isToday = isSameDay(day, today);

                        if (hasPendingBooking && isToday) {
                          return Container(
                            margin: const EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _getDateBackgroundColor(),
                                width: 3.0,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }

                        if (hasPendingBooking) {
                          return Container(
                            margin: const EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                              color: _getDateBackgroundColor(),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    isDarkThemeNotifier.value
                                        ? Colors.amber
                                        : Colors.teal,
                                width: 2.0,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }

                        return Container(
                          margin: const EdgeInsets.all(4.0),
                          decoration: BoxDecoration(
                            color:
                                isDarkThemeNotifier.value
                                    ? Colors.amber
                                    : Colors.teal,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                      todayBuilder: (context, day, focusedDay) {
                        final isSelected = isSameDay(
                          selectedDateNotifier.value,
                          day,
                        );
                        final hasPendingBooking = pendingDates.any(
                          (d) => isSameDay(d, day),
                        );

                        if (isSelected && hasPendingBooking) {
                          return Container(
                            margin: const EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _getDateBackgroundColor(),
                                width: 3.0,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }

                        if (hasPendingBooking) {
                          return Container(
                            margin: const EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _getDateBackgroundColor(),
                                width: 3.0,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }

                        if (isSelected) {
                          return Container(
                            margin: const EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                              color:
                                  isDarkThemeNotifier.value
                                      ? Colors.amber
                                      : Colors.teal,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }

                        return Container(
                          margin: const EdgeInsets.all(4.0),
                          decoration: const BoxDecoration(
                            color: Colors.purple,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: mediaQuery.size.height * 0.02),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _dateController.text = _formatDate(selectedDate);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDarkThemeNotifier.value ? Colors.teal : Colors.amber,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.1,
                      vertical: mediaQuery.size.height * 0.02,
                    ),
                  ),
                  child: Text(
                    'Select Date',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    MediaQueryData mediaQuery, {
    bool readOnly = false,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = mediaQuery.size.width;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: screenWidth * 0.04,
          color: isDark ? Colors.white : Colors.grey[900],
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: screenWidth * 0.035,
          ),
          prefixIcon:
              icon != null
                  ? Icon(
                    icon,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    size: 22,
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: mediaQuery.size.height * 0.018,
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(BuildContext context, MediaQueryData mediaQuery) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = mediaQuery.size.width;

    return ValueListenableBuilder(
      valueListenable: selectedDateNotifier,
      builder: (context, selectedDate1, child) {
        _dateController.text = _formatDate(selectedDate1);

        return Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: _dateController,
            readOnly: true,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              color: isDark ? Colors.white : Colors.grey[900],
            ),
            decoration: InputDecoration(
              labelText: 'Booking Date',
              labelStyle: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: screenWidth * 0.035,
              ),
              prefixIcon: Icon(
                Icons.calendar_today_outlined,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                size: 22,
              ),
              suffixIcon:
                  isLoadingBookings
                      ? Padding(
                        padding: EdgeInsets.all(screenWidth * 0.02),
                        child: SizedBox(
                          width: screenWidth * 0.05,
                          height: screenWidth * 0.05,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.blue,
                          ),
                        ),
                      )
                      : Icon(
                        Icons.arrow_forward_ios,
                        color: isDark ? Colors.grey[400] : Colors.grey[400],
                        size: screenWidth * 0.04,
                      ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: mediaQuery.size.height * 0.018,
              ),
            ),
            onTap: () {
              // IMPORTANT:
              // Hide the keyboard before opening the calendar.
              FocusScope.of(context).unfocus();

              // Wait for keyboard dismissal/layout update.
              Future.delayed(const Duration(milliseconds: 200), () {
                if (!mounted) return;

                _showCalendarDialog(MediaQuery.of(context));
              });
            },
          ),
        );
      },
    );
  }

  void _showCalendarDialog(MediaQueryData mediaQuery) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = mediaQuery.size.width;

    showDialog(
      context: context,
      barrierDismissible: true,
      useSafeArea: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            // Get the CURRENT MediaQuery inside the dialog.
            final dialogMediaQuery = MediaQuery.of(dialogContext);

            final availableHeight = dialogMediaQuery.size.height;

            // Keep dialog inside the available screen height.
            final maxDialogHeight = availableHeight * 0.90;

            return Dialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: isDark ? Colors.grey[900] : Colors.white,
              elevation: 8,

              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: maxDialogHeight,
                  maxWidth: screenWidth * 0.90,
                ),

                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),

                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),

                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // =====================================================
                        // CALENDAR ICON
                        // =====================================================
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.calendar_month_outlined,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),

                        SizedBox(height: screenWidth * 0.04),

                        // =====================================================
                        // TITLE
                        // =====================================================
                        Text(
                          'Select Booking Date',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.grey[900],
                            letterSpacing: 0.5,
                          ),
                        ),

                        SizedBox(height: screenWidth * 0.02),

                        // =====================================================
                        // SUBTITLE
                        // =====================================================
                        Text(
                          'Choose a date for your booking',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            letterSpacing: 0.3,
                          ),
                        ),

                        SizedBox(height: screenWidth * 0.04),

                        // =====================================================
                        // CALENDAR
                        // =====================================================
                        _buildCalendar(dialogMediaQuery),

                        SizedBox(height: screenWidth * 0.03),

                        // =====================================================
                        // LEGEND
                        // =====================================================
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(screenWidth * 0.03),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Wrap(
                            spacing: screenWidth * 0.04,
                            runSpacing: screenWidth * 0.025,
                            alignment: WrapAlignment.center,
                            children: [
                              // -------------------------
                              // Today
                              // -------------------------
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: screenWidth * 0.05,
                                    height: screenWidth * 0.05,
                                    decoration: const BoxDecoration(
                                      color: Colors.purple,
                                      shape: BoxShape.circle,
                                    ),
                                  ),

                                  SizedBox(width: screenWidth * 0.02),

                                  Text(
                                    'Today',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.035,
                                      color:
                                          isDark
                                              ? Colors.grey[300]
                                              : Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),

                              // -------------------------
                              // Pending Booking
                              // -------------------------
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: screenWidth * 0.05,
                                    height: screenWidth * 0.05,
                                    decoration: BoxDecoration(
                                      color: _getDateBackgroundColor(),
                                      shape: BoxShape.circle,
                                    ),
                                  ),

                                  SizedBox(width: screenWidth * 0.02),

                                  Text(
                                    'Pending Booking',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.035,
                                      color:
                                          isDark
                                              ? Colors.grey[300]
                                              : Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),

                              // -------------------------
                              // Today + Pending
                              // -------------------------
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: screenWidth * 0.05,
                                    height: screenWidth * 0.05,
                                    decoration: BoxDecoration(
                                      color: Colors.purple,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _getDateBackgroundColor(),
                                        width: 3.0,
                                      ),
                                    ),
                                  ),

                                  SizedBox(width: screenWidth * 0.02),

                                  Text(
                                    'Today + Pending',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.035,
                                      color:
                                          isDark
                                              ? Colors.grey[300]
                                              : Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: screenWidth * 0.04),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPincodeField(MediaQueryData mediaQuery) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = mediaQuery.size.width;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: _pincodeController,
        focusNode: _pincodeFocusNode,
        keyboardType: TextInputType.number,
        maxLength: 6,
        style: TextStyle(
          fontSize: screenWidth * 0.04,
          color: isDark ? Colors.white : Colors.grey[900],
        ),
        decoration: InputDecoration(
          labelText: 'Pincode',
          labelStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: screenWidth * 0.035,
          ),
          prefixIcon: Icon(
            Icons.pin_drop_outlined,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            size: 22,
          ),
          counterText: '',
          suffixIcon:
              _isLoading1
                  ? Padding(
                    padding: EdgeInsets.all(screenWidth * 0.02),
                    child: SizedBox(
                      width: screenWidth * 0.05,
                      height: screenWidth * 0.05,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.blue,
                      ),
                    ),
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: mediaQuery.size.height * 0.018,
          ),
        ),
        onChanged: (value) {
          if (value.length == 6) {
            _fetchAddressByPincode(value);
          }
        },
      ),
    );
  }

  Future<void> _fetchAddressByPincode(String pincode) async {
    if (pincode.length != 6) return;

    setState(() {
      _isLoading1 = true;
      _errorMessage = '';
    });

    try {
      final response = await http
          .get(Uri.parse('https://api.postalpincode.in/pincode/$pincode'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data[0]['Status'] == 'Success') {
          final postOfficeList = data[0]['PostOffice'];
          setState(() {
            _districtController.text = postOfficeList[0]['District'] ?? '';
            _stateController.text = postOfficeList[0]['State'] ?? '';
            _postOffices = List<String>.from(
              postOfficeList.map((po) => po['Name'] as String),
            );
            _selectedPost = _postOffices.isNotEmpty ? _postOffices.first : null;
            _isLoading1 = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Invalid pincode';
            _districtController.clear();
            _stateController.clear();
            _postOffices.clear();
          });
        }
      } else {
        setState(() => _errorMessage = 'Failed to fetch address');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Network error: ${e.toString()}');
    } finally {
      setState(() => _isLoading1 = false);
    }
  }

  Widget _buildPostDropdown(MediaQueryData mediaQuery) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = mediaQuery.size.width;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedPost,
        dropdownColor: isDark ? Colors.grey[800] : Colors.white,
        style: TextStyle(
          fontSize: screenWidth * 0.04,
          color: isDark ? Colors.white : Colors.grey[900],
        ),
        decoration: InputDecoration(
          labelText: 'Post Office',
          labelStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: screenWidth * 0.035,
          ),
          prefixIcon: Icon(
            Icons.local_post_office_outlined,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: mediaQuery.size.height * 0.01,
          ),
        ),
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        items:
            _postOffices
                .map(
                  (post) => DropdownMenuItem(
                    value: post,
                    child: Text(
                      post,
                      style: TextStyle(fontSize: screenWidth * 0.04),
                    ),
                  ),
                )
                .toList(),
        onChanged: (value) => setState(() => _selectedPost = value),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, MediaQueryData mediaQuery) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = mediaQuery.size.width;

    return Row(
      children: [
        Expanded(
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
              padding: EdgeInsets.symmetric(
                vertical: mediaQuery.size.height * 0.018,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
            ),
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: screenWidth * 0.04,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.03),
        Expanded(
          child: ElevatedButton(
            onPressed:
                _isBooking
                    ? null
                    : () => _submitCreatedBooking(context: context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                vertical: mediaQuery.size.height * 0.018,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              shadowColor: Colors.blue.withOpacity(0.3),
            ),
            child:
                _isLoading
                    ? SizedBox(
                      width: screenWidth * 0.05,
                      height: screenWidth * 0.05,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Book Now',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: screenWidth * 0.04,
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitCreatedBooking({required BuildContext context}) async {
    // Validation
    if (_nameController.text.isEmpty ||
        _numberController.text.isEmpty ||
        _villageController.text.isEmpty ||
        _districtController.text.isEmpty ||
        _stateController.text.isEmpty ||
        _pincodeController.text.isEmpty) {
      _showErrorSnackbar(context, 'Please fill all fields');
      return;
    }
    if (_numberController.text.length != 10) {
      _showErrorSnackbar(context, 'Please enter a valid mobile number');
      return;
    }

    // Check if selected date has pending booking
    final isPendingDate = pendingBookingDates.any(
      (d) => isSameDay(d, selectedDateNotifier.value),
    );
    if (isPendingDate) {
      _showErrorSnackbar(context, 'You cannot book on a pending booking date.');
      return;
    }

    setState(() {
      _isBooking = true;
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final vendorData = prefs.getString('vendor');
      if (vendorData == null) {
        throw Exception("User data not found");
      }

      final decoded = jsonDecode(vendorData);
      final token = 'Bearer ${decoded['token']}';
      final userId = decoded['vendorId'];
      final jobType = decoded['type'];

      // Format date for API
      final bookingDate = selectedDateNotifier.value.toString().split(' ')[0];
      final now = selectedDateNotifier.value;

      // Single API call - combined booking creation and confirmation
      final response = await http
          .post(
            Uri.parse("${KConstantURL.url}/bookings/postToBookingsV"),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': token,
            },
            body: jsonEncode({
              'userId': userId,
              'vendorId': userId,
              'bookingDate': bookingDate,
              'name': _capitalizeFirstLetter(_nameController.text),
              'phoneNo': _numberController.text,
              'vill': _capitalizeFirstLetter(_villageController.text),
              'post': _selectedPost ?? '',
              'dist': _districtController.text,
              'pincode': _pincodeController.text,
              'type': jobType,
              'isSelfBooking': true,
              'date': now.day,
              'month': now.month - 1,
              'year': now.year,
              'vendorUser': userId,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        // Show success message
        _showSuccessSnackbar(
          context,
          responseData['message'] ?? 'Booking successful!',
        );

        // Reset form fields after delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _nameController.clear();
              _numberController.clear();
              _villageController.clear();
              _districtController.clear();
              _stateController.clear();
              _pincodeController.clear();
              _dateController.clear();
              _postOffices.clear();
              _selectedPost = null;
            });
          }
        });

        // Refresh pending bookings
        await _fetchPendingBookings();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Booking failed');
      }
    } catch (e) {
      _showErrorSnackbar(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
          _isLoading = false;
        });
      }
    }
  }

  String _capitalizeFirstLetter(String str) {
    return str.isNotEmpty ? str[0].toUpperCase() + str.substring(1) : str;
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = mediaQuery.size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Book Now',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: isDarkThemeNotifier.value ? Colors.teal : Colors.amber,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                (isDarkThemeNotifier.value ? Colors.teal : Colors.amber)
                    .withOpacity(0.1),
                Colors.transparent,
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.book_online_outlined,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    SizedBox(height: mediaQuery.size.height * 0.015),
                    Text(
                      'Create New Booking',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth * 0.055,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.grey[900],
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: mediaQuery.size.height * 0.005),
                    Text(
                      'Fill in the details to book your service',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: mediaQuery.size.height * 0.025),
                    if (_errorMessage.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Expanded(
                              child: Text(
                                _errorMessage,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: screenWidth * 0.035,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_errorMessage.isNotEmpty)
                      SizedBox(height: mediaQuery.size.height * 0.02),
                    _buildTextField(
                      'Name',
                      _nameController,
                      mediaQuery,
                      icon: Icons.person_outline,
                    ),
                    SizedBox(height: mediaQuery.size.height * 0.015),
                    _buildTextField(
                      'Mobile Number',
                      _numberController,
                      mediaQuery,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: mediaQuery.size.height * 0.015),
                    _buildTextField(
                      'Village',
                      _villageController,
                      mediaQuery,
                      icon: Icons.house_outlined,
                    ),
                    SizedBox(height: mediaQuery.size.height * 0.015),
                    _buildDateField(context, mediaQuery),
                    SizedBox(height: mediaQuery.size.height * 0.015),
                    _buildPincodeField(mediaQuery),
                    SizedBox(height: mediaQuery.size.height * 0.015),
                    if (_postOffices.isNotEmpty) ...[
                      _buildPostDropdown(mediaQuery),
                      SizedBox(height: mediaQuery.size.height * 0.015),
                    ],
                    _buildTextField(
                      'District',
                      _districtController,
                      mediaQuery,
                      readOnly: true,
                      icon: Icons.location_city_outlined,
                    ),
                    SizedBox(height: mediaQuery.size.height * 0.015),
                    _buildTextField(
                      'State',
                      _stateController,
                      mediaQuery,
                      readOnly: true,
                      icon: Icons.map_outlined,
                    ),
                    SizedBox(height: mediaQuery.size.height * 0.03),
                    _buildActionButtons(context, mediaQuery),
                    SizedBox(height: mediaQuery.size.height * 0.02),
                    Center(child: BannerAdWidget()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

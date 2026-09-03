import 'dart:convert';
import 'package:app_aapkakaam/data/constants.dart';
import 'package:app_aapkakaam/data/notifiers.dart';
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

  // Language helper
  String _t(String en, String hi) => isHindiNotifier.value ? hi : en;

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

  DateTime _toAsiaKolkataTime(DateTime utcDate) {
    return utcDate.add(const Duration(hours: 5, minutes: 30));
  }

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
          // Fall through
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

        final extractedDates = _extractPendingBookingDates(bookings);
        setState(() {
          pendingBookingDates = extractedDates;
        });
        bookingPendingNotifier.value = extractedDates;
      } else {
        print('Failed to fetch bookings: ${response.statusCode}');
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

          if (isPending) {
            final bookingDate = _parseDateFromBooking(bookingData);
            if (bookingDate != null) {
              final normalizedDate = normalizeDate(bookingDate);
              dates.add(normalizedDate);
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
    final theme = Theme.of(context);
    return theme.colorScheme.primary.withOpacity(0.3);
  }

  // ============================================================
  // UPDATED: MODERN SNACKBAR WITH THEME COLORS
  // ============================================================

  void _showCalendarSnackBar(
    String message,
    Color backgroundColor,
    IconData icon,
    ) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: MediaQuery.of(context).size.height * 0.05,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      backgroundColor,
                      backgroundColor.withOpacity(0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: backgroundColor.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
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
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: primaryColor,
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
        elevation: 0,
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final errorColor = colorScheme.error;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: errorColor,
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
        elevation: 0,
      ),
    );
  }

  void _showInfoSnackbar(BuildContext context, String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final infoColor = colorScheme.primaryContainer;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: infoColor,
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.info_outline, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
        elevation: 0,
      ),
    );
  }

  Widget _buildCalendar(MediaQueryData mediaQuery) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
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

        return ValueListenableBuilder(
          valueListenable: selectedDateNotifier,
          builder: (context, selectedDate1, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoadingBookings)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                Container(
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? const Color(0xFF1A1A2E)
                            : const Color(0xFFF8FAFD),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isDark
                              ? Colors.white.withOpacity(0.06)
                              : const Color(0xFFE8ECF3),
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
                        _showCalendarSnackBar(
                          _t(
                            'You cannot select a pending booking date.',
                            'आप लंबित बुकिंग तिथि का चयन नहीं कर सकते।',
                          ),
                          colorScheme.error,
                          Icons.warning_amber_rounded,
                        );
                        return;
                      }

                      selectedDateNotifier.value = selectedDay;
                      setState(() {
                        _focusedDay = focusedDay;
                      });

                      _showCalendarSnackBar(
                        _t(
                          'Date selected: ${selectedDay.day}/${selectedDay.month}/${selectedDay.year}',
                          'तिथि चयनित: ${selectedDay.day}/${selectedDay.month}/${selectedDay.year}',
                        ),
                        colorScheme.primary,
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
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, primaryColor.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF172033),
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        size: screenWidth * 0.06,
                        color: isDark ? Colors.white : const Color(0xFF4B5563),
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        size: screenWidth * 0.06,
                        color: isDark ? Colors.white : const Color(0xFF4B5563),
                      ),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.035,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      weekendStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.035,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                                  isDark
                                      ? Colors.white
                                      : const Color(0xFF172033),
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

                        if (hasPendingBooking) {
                          return Container(
                            margin: const EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                              color: _getDateBackgroundColor(),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: primaryColor,
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
                            color: primaryColor,
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

                        if (hasPendingBooking) {
                          return Container(
                            margin: const EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple,
                                  Colors.purple.withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
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
                              color: primaryColor,
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
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.purple,
                                Colors.purple.withOpacity(0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
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
                    backgroundColor: primaryColor,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.1,
                      vertical: mediaQuery.size.height * 0.02,
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _t('Select Date', 'तिथि चुनें'),
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: colorScheme.onPrimary,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = mediaQuery.size.width;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252540) : const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE8ECF3),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: screenWidth * 0.04,
          color: isDark ? Colors.white : const Color(0xFF172033),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: _t(label, _getHindiLabel(label)),
          labelStyle: TextStyle(
            color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
            fontSize: screenWidth * 0.035,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon:
              icon != null
                  ? Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: primaryColor, size: 20),
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: mediaQuery.size.height * 0.018,
          ),
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
        cursorColor: primaryColor,
      ),
    );
  }

  String _getHindiLabel(String label) {
    final map = {
      'Name': 'नाम',
      'Mobile Number': 'मोबाइल नंबर',
      'Village': 'गाँव',
      'District': 'जिला',
      'State': 'राज्य',
      'Pincode': 'पिनकोड',
      'Booking Date': 'बुकिंग तिथि',
    };
    return map[label] ?? label;
  }

  Widget _buildDateField(BuildContext context, MediaQueryData mediaQuery) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = mediaQuery.size.width;

    return ValueListenableBuilder(
      valueListenable: selectedDateNotifier,
      builder: (context, selectedDate1, child) {
        _dateController.text = _formatDate(selectedDate1);

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252540) : const Color(0xFFF8FAFD),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isDark
                      ? Colors.white.withOpacity(0.06)
                      : const Color(0xFFE8ECF3),
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: _dateController,
            readOnly: true,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              color: isDark ? Colors.white : const Color(0xFF172033),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: _t('Booking Date', 'बुकिंग तिथि'),
              labelStyle: TextStyle(
                color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w600,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calendar_today_outlined,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              suffixIcon:
                  isLoadingBookings
                      ? Padding(
                        padding: EdgeInsets.all(screenWidth * 0.02),
                        child: SizedBox(
                          width: screenWidth * 0.05,
                          height: screenWidth * 0.05,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: primaryColor,
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
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
            cursorColor: primaryColor,
            onTap: () {
              FocusScope.of(context).unfocus();
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
            final dialogMediaQuery = MediaQuery.of(dialogContext);
            final availableHeight = dialogMediaQuery.size.height;
            final maxDialogHeight = availableHeight * 0.90;

            return Dialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
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
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.calendar_month_outlined,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 28,
                            ),
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.04),
                        Text(
                          _t('Select Booking Date', 'बुकिंग तिथि चुनें'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.grey[900],
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.02),
                        Text(
                          _t(
                            'Choose a date for your booking',
                            'अपनी बुकिंग के लिए तिथि चुनें',
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.04),
                        _buildCalendar(dialogMediaQuery),
                        SizedBox(height: screenWidth * 0.03),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(screenWidth * 0.03),
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? const Color(0xFF252540)
                                    : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Wrap(
                            spacing: screenWidth * 0.04,
                            runSpacing: screenWidth * 0.025,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildLegendItem(
                                Colors.purple,
                                _t('Today', 'आज'),
                                screenWidth,
                              ),
                              _buildLegendItem(
                                _getDateBackgroundColor(),
                                _t('Pending Booking', 'लंबित बुकिंग'),
                                screenWidth,
                              ),
                              _buildLegendItemWithBorder(
                                Colors.purple,
                                _getDateBackgroundColor(),
                                _t('Today + Pending', 'आज + लंबित'),
                                screenWidth,
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

  Widget _buildLegendItem(Color color, String label, double screenWidth) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: screenWidth * 0.05,
          height: screenWidth * 0.05,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: screenWidth * 0.02),
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * 0.035,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[300]
                    : Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItemWithBorder(
    Color color,
    Color borderColor,
    String label,
    double screenWidth,
    ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: screenWidth * 0.05,
          height: screenWidth * 0.05,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 3.0),
          ),
        ),
        SizedBox(width: screenWidth * 0.02),
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * 0.035,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[300]
                    : Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _fetchAddressByPincode(String pincode) async {
    if (pincode.length != 6) return;

    setState(() {
      _isLoading1 = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final isVendor1 = isVendor.value;
      final category = isVendor1 ? 'vendor' : 'user';
      final categoryData = prefs.getString(category);

      if (categoryData == null) {
        setState(
          () =>
              _errorMessage = _t(
                'User data not found',
                'उपयोगकर्ता डेटा नहीं मिला',
              ),
        );
        return;
      }

      final decoded = jsonDecode(categoryData);
      final response = await http
          .post(
            Uri.parse(
              '${KConstantURL.url}/pincode/${category == 'user' ? 'getU' : 'getV'}',
            ),
            headers: {
              "Authorization": 'Bearer ${decoded['token']}',
              "Content-Type": "application/json",
            },
            body: jsonEncode({'pincode': pincode}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body)['data'];
        final offices = result['offices'] ?? [];

        final cleanedOffices = List<Map<String, dynamic>>.from(
          offices.map((office) {
            final name =
                office['officename']
                    ?.replaceAll(RegExp(r'\s(BO|SO|HO)$'), '')
                    ?.toUpperCase();
            return {'Name': name, 'original': office};
          }),
        );

        final allOffices = [
          {'Name': _t('Select Post Office', 'पोस्ट ऑफिस चुनें')},
          ...cleanedOffices,
        ];

        setState(() {
          _districtController.text = offices[0]?['district'] ?? '';
          _stateController.text = offices[0]?['statename'] ?? '';
          _postOffices = allOffices.map((e) => e['Name'] as String).toList();
          _selectedPost = _postOffices.isNotEmpty ? _postOffices.first : null;
          _isLoading1 = false;
        });
      } else {
        setState(() {
          _errorMessage = _t('Enter Valid Pincode', 'सही पिनकोड डालें');
          _districtController.clear();
          _stateController.clear();
          _postOffices.clear();
          _isLoading1 = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            _t('Network error: ', 'नेटवर्क त्रुटि: ') + e.toString();
        _isLoading1 = false;
      });
    }
  }

  Widget _buildPincodeField(MediaQueryData mediaQuery) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = mediaQuery.size.width;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252540) : const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE8ECF3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _pincodeController,
        focusNode: _pincodeFocusNode,
        keyboardType: TextInputType.number,
        maxLength: 6,
        style: TextStyle(
          fontSize: screenWidth * 0.04,
          color: isDark ? Colors.white : const Color(0xFF172033),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: _t('Pincode', 'पिनकोड'),
          labelStyle: TextStyle(
            color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
            fontSize: screenWidth * 0.035,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.pin_drop_outlined, color: primaryColor, size: 20),
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
                        color: primaryColor,
                      ),
                    ),
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: mediaQuery.size.height * 0.018,
          ),
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
        cursorColor: primaryColor,
        onChanged: (value) {
          if (value.length == 6) {
            _fetchAddressByPincode(value);
          }
        },
      ),
    );
  }

  Widget _buildPostDropdown(MediaQueryData mediaQuery) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = mediaQuery.size.width;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252540) : const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE8ECF3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedPost,
        dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        style: TextStyle(
          fontSize: screenWidth * 0.04,
          color: isDark ? Colors.white : const Color(0xFF172033),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: _t('Post Office', 'पोस्ट ऑफिस'),
          labelStyle: TextStyle(
            color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
            fontSize: screenWidth * 0.035,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.local_post_office_outlined,
              color: primaryColor,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: mediaQuery.size.height * 0.01,
          ),
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
        ),
        items:
            _postOffices
                .map(
                  (post) => DropdownMenuItem(
                    value: post,
                    child: Text(
                      post,
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: isDark ? Colors.white : const Color(0xFF172033),
                      ),
                    ),
                  ),
                )
                .toList(),
        onChanged: (value) => setState(() => _selectedPost = value),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, MediaQueryData mediaQuery) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = mediaQuery.size.width;

    return Row(
      children: [
        Expanded(
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: isDark ? Colors.grey[400] : Colors.grey[600],
              padding: EdgeInsets.symmetric(
                vertical: mediaQuery.size.height * 0.018,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color:
                      isDark
                          ? Colors.white.withOpacity(0.1)
                          : const Color(0xFFE8ECF3),
                  width: 1.5,
                ),
              ),
            ),
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: Text(
              _t('Cancel', 'रद्द करें'),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: screenWidth * 0.04,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
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
              backgroundColor: primaryColor,
              foregroundColor: colorScheme.onPrimary,
              padding: EdgeInsets.symmetric(
                vertical: mediaQuery.size.height * 0.018,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              shadowColor: primaryColor.withOpacity(0.3),
            ),
            child:
                _isLoading
                    ? SizedBox(
                      width: screenWidth * 0.05,
                      height: screenWidth * 0.05,
                      child: CircularProgressIndicator(
                        color: colorScheme.onPrimary,
                        strokeWidth: 2.5,
                      ),
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 20,
                          color: colorScheme.onPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _t('Book Now', 'अभी बुक करें'),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: screenWidth * 0.04,
                            color: colorScheme.onPrimary,
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
    if (_nameController.text.isEmpty ||
        _numberController.text.isEmpty ||
        _villageController.text.isEmpty ||
        _districtController.text.isEmpty ||
        _stateController.text.isEmpty ||
        _pincodeController.text.isEmpty) {
      _showErrorSnackbar(
        context,
        _t('Please fill all fields', 'कृपया सभी फील्ड भरें'),
      );
      return;
    }
    if (_numberController.text.length != 10) {
      _showErrorSnackbar(
        context,
        _t(
          'Please enter a valid mobile number',
          'कृपया सही मोबाइल नंबर दर्ज करें',
        ),
      );
      return;
    }

    final isPendingDate = pendingBookingDates.any(
      (d) => isSameDay(d, selectedDateNotifier.value),
    );
    if (isPendingDate) {
      _showErrorSnackbar(
        context,
        _t(
          'You cannot book on a pending booking date.',
          'आप लंबित बुकिंग तिथि पर बुक नहीं कर सकते।',
        ),
      );
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

      final bookingDate = selectedDateNotifier.value.toString().split(' ')[0];
      final now = selectedDateNotifier.value;

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
              'type': jobType[0],
              'isSelfBooking': true,
              'date': now.day,
              'month': now.month - 1,
              'year': now.year,
              'vendorUser': userId,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // final responseData = jsonDecode(response.body);
        _showSuccessSnackbar(context, _t('Booking successful!', 'बुकिंग सफल!'));

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

        await _fetchPendingBookings();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? _t('Booking failed', 'बुकिंग विफल'),
        );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final surface = colorScheme.surface;
    final onSurface = colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _t('Book Now', 'अभी बुक करें'),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: primaryColor,
        foregroundColor: colorScheme.onPrimary,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: colorScheme.onPrimary,
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [primaryColor.withOpacity(0.06), Colors.transparent],
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
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              primaryColor.withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.book_online_outlined,
                          color: colorScheme.onPrimary,
                          size: 32,
                        ),
                      ),
                    ),
                    SizedBox(height: mediaQuery.size.height * 0.015),
                    Text(
                      _t('Create New Booking', 'नई बुकिंग बनाएं'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth * 0.055,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : onSurface,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: mediaQuery.size.height * 0.005),
                    Text(
                      _t(
                        'Fill in the details to book your service',
                        'अपनी सेवा बुक करने के लिए विवरण भरें',
                      ),
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
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.2),
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
                      _t('Name', 'नाम'),
                      _nameController,
                      mediaQuery,
                      icon: Icons.person_outline,
                    ),
                    SizedBox(height: mediaQuery.size.height * 0.015),
                    _buildTextField(
                      _t('Mobile Number', 'मोबाइल नंबर'),
                      _numberController,
                      mediaQuery,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: mediaQuery.size.height * 0.015),
                    _buildTextField(
                      _t('Village', 'गाँव'),
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
                      _t('District', 'जिला'),
                      _districtController,
                      mediaQuery,
                      readOnly: true,
                      icon: Icons.location_city_outlined,
                    ),
                    SizedBox(height: mediaQuery.size.height * 0.015),
                    _buildTextField(
                      _t('State', 'राज्य'),
                      _stateController,
                      mediaQuery,
                      readOnly: true,
                      icon: Icons.map_outlined,
                    ),
                    SizedBox(height: mediaQuery.size.height * 0.03),
                    _buildActionButtons(context, mediaQuery),
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

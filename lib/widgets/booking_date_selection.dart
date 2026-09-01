// this file is made responsive and fully Hindi compatible with custom calendar.

import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/widgets/available_vendor.dart';
import 'package:flutter/material.dart';

class BookingDateSelection extends StatefulWidget {
  const BookingDateSelection({
    super.key,
    this.profession = '',
    this.hindiName = "",
  });

  final String profession;
  final String hindiName;

  @override
  State<BookingDateSelection> createState() => _BookingDateSelectionState();
}

class _BookingDateSelectionState extends State<BookingDateSelection> {
  DateTime selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();

  late final DateTime firstDate = DateTime.now();
  late final DateTime lastDate = DateTime.now().add(const Duration(days: 90));

  // ============================================================
  // HINDI CALENDAR HELPERS
  // ============================================================

  static const List<String> _hindiMonths = [
    '',
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

  static const List<String> _hindiMonthsShort = [
    '',
    'जन',
    'फर',
    'मार्च',
    'अप्रै',
    'मई',
    'जून',
    'जुल',
    'अग',
    'सित',
    'अक्टू',
    'नव',
    'दिस',
  ];

  static const List<String> _hindiWeekdays = [
    'सोम',
    'मंगल',
    'बुध',
    'गुरु',
    'शुक्र',
    'शनि',
    'रवि',
  ];

  static const List<String> _hindiWeekdaysFull = [
    'सोमवार',
    'मंगलवार',
    'बुधवार',
    'गुरुवार',
    'शुक्रवार',
    'शनिवार',
    'रविवार',
  ];

  static const List<String> _englishMonths = [
    '',
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

  static const List<String> _englishMonthsShort = [
    '',
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  static const List<String> _englishWeekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  String _getMonthName(int month, bool isHindi, {bool short = false}) {
    if (month < 1 || month > 12) return '';
    if (isHindi) {
      return short ? _hindiMonthsShort[month] : _hindiMonths[month];
    }
    return short ? _englishMonthsShort[month] : _englishMonths[month];
  }

  String _getWeekdayName(int weekday, bool isHindi, {bool short = true}) {
    final index = weekday - 1;
    if (index < 0 || index > 6) return '';
    if (isHindi) {
      return short ? _hindiWeekdays[index] : _hindiWeekdaysFull[index];
    }
    return _englishWeekdays[index];
  }

  String _getFormattedDate(DateTime date, bool isHindi) {
    if (isHindi) {
      final day = date.day;
      final month = _hindiMonthsShort[date.month];
      final year = date.year;
      return '$day $month $year';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isSelected(DateTime date) {
    return date.year == selectedDate.year &&
        date.month == selectedDate.month &&
        date.day == selectedDate.day;
  }

  bool _isDisabled(DateTime date) {
    return date.isBefore(firstDate) || date.isAfter(lastDate);
  }

  // ============================================================
  // BUILD CUSTOM CALENDAR GRID
  // ============================================================

  Widget _buildCalendarGrid(
    bool isHindi,
    bool isDarkTheme,
    Color primaryColor,
    Color primaryColorDark,
    Color textColor,
    Color cardColor,
    Color secondaryTextColor,
    double maxWidth,
  ) {
    // Get first day of the month
    final firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    // Get first weekday (1 = Monday, 7 = Sunday)
    int firstWeekday = firstDayOfMonth.weekday;
    // Convert to 0-based index for grid (Monday = 0, Sunday = 6)
    int startOffset = firstWeekday - 1;
    // Days in month
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    // Days in previous month
    final daysInPrevMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 0).day;

    // Build grid items
    List<Widget> dayWidgets = [];

    // Previous month days
    for (int i = startOffset - 1; i >= 0; i--) {
      final day = daysInPrevMonth - i;
      final date = DateTime(_currentMonth.year, _currentMonth.month - 1, day);
      dayWidgets.add(
        _buildDayCell(
          date,
          day,
          true,
          isHindi,
          isDarkTheme,
          primaryColor,
          textColor,
          secondaryTextColor,
          maxWidth,
        ),
      );
    }

    // Current month days
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      dayWidgets.add(
        _buildDayCell(
          date,
          day,
          false,
          isHindi,
          isDarkTheme,
          primaryColor,
          textColor,
          secondaryTextColor,
          maxWidth,
        ),
      );
    }

    // Next month days to fill the grid
    final remainingDays = (7 - (dayWidgets.length % 7)) % 7;
    for (int day = 1; day <= remainingDays; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month + 1, day);
      dayWidgets.add(
        _buildDayCell(
          date,
          day,
          true,
          isHindi,
          isDarkTheme,
          primaryColor,
          textColor,
          secondaryTextColor,
          maxWidth,
        ),
      );
    }

    // Calculate cell size based on available width
    final cellSize = (maxWidth - 32) / 7;

    return SizedBox(
      width: maxWidth,
      child: Wrap(
        spacing: 2,
        runSpacing: 2,
        children:
            dayWidgets.map((widget) {
              return SizedBox(width: cellSize, height: cellSize, child: widget);
            }).toList(),
      ),
    );
  }

  Widget _buildDayCell(
    DateTime date,
    int day,
    bool isOtherMonth,
    bool isHindi,
    bool isDarkTheme,
    Color primaryColor,
    Color textColor,
    Color secondaryTextColor,
    double maxWidth,
  ) {
    final isToday = _isToday(date);
    final isSelected = _isSelected(date);
    final isDisabled = _isDisabled(date);
    final isPast = date.isBefore(DateTime.now()) && !isToday;

    // Determine if day should be visible
    final isVisible = !isDisabled && !isPast;

    Color? backgroundColor;
    Color? foregroundColor;

    if (isSelected) {
      backgroundColor = primaryColor;
      foregroundColor = Colors.white;
    } else if (isToday) {
      backgroundColor = primaryColor.withOpacity(0.12);
      foregroundColor = primaryColor;
    } else if (isOtherMonth || isPast || isDisabled) {
      foregroundColor = secondaryTextColor.withOpacity(0.3);
    } else {
      foregroundColor = textColor;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap:
            isVisible
                ? () {
                  setState(() {
                    selectedDate = date;
                  });
                }
                : null,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border:
                isToday && !isSelected
                    ? Border.all(color: primaryColor, width: 1.5)
                    : null,
          ),
          child: Center(
            child: Text(
              day.toString(),
              style: TextStyle(
                color: foregroundColor,
                fontSize: 13,
                fontWeight:
                    isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isHindiNotifier,
      builder: (context, isHindi, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: isDarkThemeNotifier,
          builder: (context, isDarkTheme, _) {
            return _buildPage(
              context,
              isHindi: isHindi,
              isDarkTheme: isDarkTheme,
            );
          },
        );
      },
    );
  }

  Widget _buildPage(
    BuildContext context, {
    required bool isHindi,
    required bool isDarkTheme,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final primaryColorDark = primaryColor.withOpacity(0.7);
    final surface = colorScheme.surface;
    final onSurface = colorScheme.onSurface;
    final onSurfaceVariant = colorScheme.onSurfaceVariant;

    final screenSize = MediaQuery.of(context).size;
    final maxWidth = screenSize.width > 600 ? 600.0 : screenSize.width - 32;

    final horizontalPadding = screenSize.width * 0.04;
    final verticalPadding = screenSize.height * 0.02;

    final titleSize = 16.0;
    final subtitleSize = 14.0;

    final backgroundColor =
        isDarkTheme ? const Color(0xFF0B1020) : const Color(0xFFF7F9FC);
    final cardColor = isDarkTheme ? const Color(0xFF151B2D) : surface;
    final textColor = isDarkTheme ? Colors.white : onSurface;
    final secondaryTextColor = isDarkTheme ? Colors.white60 : onSurfaceVariant;

    // Get selected date formatted for display
    final selectedDateFormatted = _getFormattedDate(selectedDate, isHindi);

    // Get month name for header
    final monthName = _getMonthName(selectedDate.month, isHindi, short: true);
    final monthNameFull = _getMonthName(
      _currentMonth.month,
      isHindi,
      short: false,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isHindi ? 'बुकिंग की तारीख चुनें' : 'Booking Date Selection',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: titleSize),
        ),
        backgroundColor: primaryColor,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // =====================================================
              // HEADER
              // =====================================================
              Container(
                margin: EdgeInsets.only(bottom: verticalPadding * 1.5),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    Text(
                      isHindi
                          ? 'बुकिंग की तारीख चुनें: '
                          : 'Select Booking Date for ',
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      isHindi ? widget.hindiName : widget.profession,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // =====================================================
              // CALENDAR CARD
              // =====================================================
              Center(
                child: Container(
                  width: maxWidth + 24,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color:
                          isDarkTheme
                              ? Colors.white.withOpacity(0.06)
                              : const Color(0xFFE7EBF3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            isDarkTheme
                                ? Colors.black.withOpacity(0.30)
                                : primaryColor.withOpacity(0.08),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // =====================================================
                      // MODERN CALENDAR HEADER
                      // =====================================================
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, primaryColorDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.calendar_month_rounded,
                                color: colorScheme.onPrimary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isHindi
                                        ? 'बुकिंग की तारीख'
                                        : 'Booking Date',
                                    style: TextStyle(
                                      color: colorScheme.onPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    isHindi
                                        ? 'अपनी पसंद की तारीख चुनें'
                                        : 'Choose your preferred date',
                                    style: TextStyle(
                                      color: colorScheme.onPrimary.withOpacity(
                                        0.82,
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Selected day with Hindi month
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${selectedDate.day}',
                                    style: TextStyle(
                                      color: colorScheme.onPrimary,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    monthName,
                                    style: TextStyle(
                                      color: colorScheme.onPrimary.withOpacity(
                                        0.85,
                                      ),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // =====================================================
                      // MONTH NAVIGATION (Hindi Compatible)
                      // =====================================================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _currentMonth = DateTime(
                                  _currentMonth.year,
                                  _currentMonth.month - 1,
                                  1,
                                );
                              });
                            },
                            icon: Icon(
                              Icons.chevron_left_rounded,
                              color: textColor,
                              size: 28,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                          ),
                          Text(
                            '$monthNameFull ${_currentMonth.year}',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _currentMonth = DateTime(
                                  _currentMonth.year,
                                  _currentMonth.month + 1,
                                  1,
                                );
                              });
                            },
                            icon: Icon(
                              Icons.chevron_right_rounded,
                              color: textColor,
                              size: 28,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // =====================================================
                      // WEEKDAY HEADERS (Hindi Compatible)
                      // =====================================================
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(7, (index) {
                            final weekdayName =
                                isHindi
                                    ? _hindiWeekdays[index]
                                    : _englishWeekdays[index];
                            return Expanded(
                              child: Center(
                                child: Text(
                                  weekdayName,
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      const SizedBox(height: 4),

                      // =====================================================
                      // CALENDAR GRID (Fully Custom)
                      // =====================================================
                      _buildCalendarGrid(
                        isHindi,
                        isDarkTheme,
                        primaryColor,
                        primaryColorDark,
                        textColor,
                        cardColor,
                        secondaryTextColor,
                        maxWidth,
                      ),
                    ],
                  ),
                ),
              ),

              // =====================================================
              // SELECTED DATE (Hindi Compatible)
              // =====================================================
              Padding(
                padding: EdgeInsets.symmetric(vertical: verticalPadding),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      alignment: WrapAlignment.center,
                      children: [
                        Text(
                          isHindi ? 'चयनित तारीख: ' : 'Selected Date: ',
                          style: TextStyle(
                            fontSize: subtitleSize,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          selectedDateFormatted,
                          style: TextStyle(
                            fontSize: subtitleSize,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // =====================================================
              // SEARCH BUTTON
              // =====================================================
              Padding(
                padding: EdgeInsets.only(
                  top: verticalPadding,
                  bottom: verticalPadding * 0.5,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(
                        vertical: screenSize.height * 0.018,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => AvailableVendor(
                                bookingDate: selectedDate,
                                profession: widget.profession,
                                hindiName: widget.hindiName,
                              ),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.search_rounded,
                      color: colorScheme.onPrimary,
                    ),
                    label: // Search button
                        Text(
                      isHindi
                          ? 'उपलब्ध ${widget.hindiName} खोजें'
                          : 'Search Available ${widget.profession}',
                      style: TextStyle(
                        fontSize: subtitleSize,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

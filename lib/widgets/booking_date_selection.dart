// this file is made responsive .

import 'package:app_aapkakaam/data/notifiers.dart';
import 'package:app_aapkakaam/widgets/available_vendor.dart';
import 'package:app_aapkakaam/widgets/banner_ad_widget.dart';
import 'package:flutter/material.dart';

class BookingDateSelection extends StatefulWidget {
  const BookingDateSelection({super.key, this.profession = ''});
  final String profession;

  @override
  State<BookingDateSelection> createState() => _BookingDateSelectionState();
}

class _BookingDateSelectionState extends State<BookingDateSelection> {
  DateTime selectedDate = DateTime.now();
  late final DateTime initialDate = DateTime.now();
  late final DateTime firstDate = DateTime.now();
  late final DateTime lastDate = DateTime.now().add(const Duration(days: 90));

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = isDarkThemeNotifier.value;
    final screenSize = MediaQuery.of(context).size;
    // Responsive padding based on screen width
    final horizontalPadding = screenSize.width * 0.04;
    final verticalPadding = screenSize.height * 0.02;

    // Responsive text scaling
    final titleSize = 16.0;
    final subtitleSize = 14.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Booking Date Selection',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: titleSize),
        ),
        backgroundColor: isDarkTheme ? Colors.teal : Colors.amber,
      ),
      backgroundColor: isDarkTheme ? Colors.black : Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate calendar size based on screen width
            final calendarWidth =
                constraints.maxWidth > 600 ? 600.0 : constraints.maxWidth * 0.9;

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - verticalPadding * 2,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header section
                      Container(
                        margin: EdgeInsets.only(bottom: verticalPadding * 1.5),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            Text(
                              'Select Booking Date for ',
                              style: TextStyle(
                                fontSize: titleSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.profession,
                              style: TextStyle(
                                fontSize: titleSize,
                                fontWeight: FontWeight.bold,
                                color: isDarkTheme ? Colors.teal : Colors.amber,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Calendar section
                      Center(
                        child: SizedBox(
                          width: calendarWidth,
                          child: CalendarDatePicker(
                            initialDate: initialDate,
                            firstDate: firstDate,
                            lastDate: lastDate,
                            onDateChanged: (value) {
                              setState(() {
                                selectedDate = value;
                              });
                            },
                          ),
                        ),
                      ),

                      // Selected date display
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: verticalPadding,
                        ),
                        child: Center(
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            alignment: WrapAlignment.center,
                            children: [
                              Text(
                                'Selected Date: ',
                                style: TextStyle(
                                  fontSize: subtitleSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                style: TextStyle(
                                  fontSize: subtitleSize,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDarkTheme ? Colors.teal : Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Spacer to push button to bottom if there's room
                      const Spacer(),

                      // Search button
                      Padding(
                        padding: EdgeInsets.only(
                          top: verticalPadding,
                          bottom: verticalPadding * 0.5,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  isDarkTheme ? Colors.teal : Colors.amber,
                              padding: EdgeInsets.symmetric(
                                vertical: screenSize.height * 0.018,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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
                                      ),
                                ),
                              );
                            },
                            child: Text(
                              'Search',
                              style: TextStyle(
                                fontSize: subtitleSize,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDarkTheme ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Center(child: BannerAdWidget()),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

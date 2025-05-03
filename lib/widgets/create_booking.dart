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
        final bookings = jsonDecode(response.body) as List;
        setState(() {
          pendingBookingDates = _extractPendingBookingDates(bookings);
        });
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
        final b = booking['booking'];
        final isPending = !b['cancelOrder'] && !b['orderCompleted'];
        if (isPending) {
          dates.add(
            normalizeDate(DateTime(b['year'], b['month'] + 1, b['date'])),
          );
        }
      } catch (e) {
        debugPrint('Date parsing error: $e');
      }
    }
    bookingPendingNotifier.value = dates;
    return dates;
  }

  Color _getDateBackgroundColor() {
    return isDarkThemeNotifier.value
        ? Colors.teal.withOpacity(0.7)
        : Colors.amber.withOpacity(0.7);
  }

  Widget _buildCalendar(MediaQueryData mediaQuery) {
    return ValueListenableBuilder(
      valueListenable: bookingPendingNotifier,
      builder: (context, value, child) {
        return ValueListenableBuilder(
          valueListenable: selectedDateNotifier,
          builder: (context, value, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoadingBookings)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                TableCalendar(
                  firstDay: firstDate,
                  lastDay: lastDate,
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate:
                      (day) => isSameDay(selectedDateNotifier.value, day),

                  onDaySelected: (selectedDay, focusedDay) {
                    final isPendingDate = pendingBookingDates.any(
                      (d) => isSameDay(d, selectedDay),
                    );

                    if (isPendingDate) {
                      // Show warning and don't allow selection
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Center(
                            child: Text(
                              'You cannot select a pending booking date.',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return; // Stop further execution
                    }

                    // If not a pending date → allow selection
                    selectedDateNotifier.value = selectedDay;
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged:
                      (format) => setState(() => _calendarFormat = format),
                  onPageChanged: (focusedDay) async {
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                    await _fetchPendingBookings(); // Wait for data to load
                    setState(() {}); // Force UI update
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
                      fontSize: mediaQuery.size.width * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      size: mediaQuery.size.width * 0.06,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      size: mediaQuery.size.width * 0.06,
                    ),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: mediaQuery.size.width * 0.035,
                    ),
                    weekendStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: mediaQuery.size.width * 0.035,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      final hasPendingBooking = bookingPendingNotifier.value
                          .any((d) => isSameDay(d, day));

                      // Don't show pending color if the date is selected
                      final showPendingColor = hasPendingBooking;

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
                            fontSize: mediaQuery.size.width * 0.04,
                          ),
                        ),
                      );
                    },
                    selectedBuilder: (context, day, focusedDay) {
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
                      final hasPendingBooking = bookingPendingNotifier.value
                          .any((d) => isSameDay(d, day));

                      // Show purple for today unless it's selected
                      return Container(
                        margin: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? (isDarkThemeNotifier.value
                                      ? Colors.amber
                                      : Colors.teal)
                                  : Colors.purple,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight:
                                hasPendingBooking
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      );
                    },
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: mediaQuery.size.width * 0.1,
                      vertical: mediaQuery.size.height * 0.02,
                    ),
                  ),
                  child: Text(
                    'Select Date',
                    style: TextStyle(
                      fontSize: mediaQuery.size.width * 0.04,
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
  }) {
    setState(() {
      _errorMessage = '';
    });
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType:
          label == 'Mobile Number' ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: mediaQuery.size.width * 0.04,
          vertical: mediaQuery.size.height * 0.02,
        ),
      ),
      style: TextStyle(fontSize: mediaQuery.size.width * 0.04),
    );
  }

  Widget _buildDateField(BuildContext context, MediaQueryData mediaQuery) {
    return ValueListenableBuilder(
      valueListenable: selectedDateNotifier,
      builder: (context, selectedDate1, child) {
        _dateController.text = _formatDate(selectedDate1);
        return Column(
          children: [
            TextField(
              controller: _dateController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Booking Date',
                border: const OutlineInputBorder(),
                suffixIcon:
                    isLoadingBookings
                        ? SizedBox(
                          width: mediaQuery.size.width * 0.05,
                          height: mediaQuery.size.width * 0.05,
                          child: Transform.scale(
                            scale:
                                0.5, // scale the spinner itself (adjust between 0.5 to 1.5)
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                        : Icon(
                          Icons.calendar_today,
                          size: mediaQuery.size.width * 0.05,
                        ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: mediaQuery.size.width * 0.04,
                  vertical: mediaQuery.size.height * 0.02,
                ),
              ),
              style: TextStyle(fontSize: mediaQuery.size.width * 0.04),
              onTap: () {
                _showCalendarDialog(mediaQuery);
              },
            ),
          ],
        );
      },
    );
  }

  void _showCalendarDialog(MediaQueryData mediaQuery) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              child: Padding(
                padding: EdgeInsets.all(mediaQuery.size.width * 0.04),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCalendar(mediaQuery),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                          width: mediaQuery.size.width * 0.07,
                          height: mediaQuery.size.width * 0.07,
                          decoration: BoxDecoration(
                            color:
                                isDarkThemeNotifier.value
                                    ? Colors.teal
                                    : Colors.amber,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          'Pending Booking',
                          style: TextStyle(
                            fontSize: mediaQuery.size.width * 0.04,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Usage in your code:

  Widget _buildPincodeField(MediaQueryData mediaQuery) {
    return TextField(
      controller: _pincodeController,
      focusNode: _pincodeFocusNode,
      keyboardType: TextInputType.number,
      maxLength: 6,
      decoration: InputDecoration(
        labelText: 'Pincode',
        border: const OutlineInputBorder(),
        counterText: '',
        suffixIcon:
            _isLoading1
                ? SizedBox(
                  width:
                      mediaQuery.size.width * 0.04, // increase/decrease width
                  height:
                      mediaQuery.size.width * 0.04, // increase/decrease height
                  child: Transform.scale(
                    scale:
                        0.5, // scale the spinner itself (adjust between 0.5 to 1.5)
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
                : null,
        contentPadding: EdgeInsets.symmetric(
          horizontal: mediaQuery.size.width * 0.04,
          vertical: mediaQuery.size.height * 0.02,
        ),
      ),
      style: TextStyle(fontSize: mediaQuery.size.width * 0.04),
      onChanged: (value) {
        if (value.length == 6) {
          _fetchAddressByPincode(value);
        }
      },
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
    return DropdownButtonFormField<String>(
      value: _selectedPost,
      items:
          _postOffices
              .map(
                (post) => DropdownMenuItem(
                  value: post,
                  child: Text(
                    post,
                    style: TextStyle(fontSize: mediaQuery.size.width * 0.04),
                  ),
                ),
              )
              .toList(),
      onChanged: (value) => setState(() => _selectedPost = value),
      decoration: InputDecoration(
        labelText: 'Post Office',
        border: const OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: mediaQuery.size.width * 0.04,
          vertical: mediaQuery.size.height * 0.02,
        ),
      ),
      style: TextStyle(fontSize: mediaQuery.size.width * 0.04),
    );
  }

  Widget _buildActionButtons(BuildContext context, MediaQueryData mediaQuery) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: mediaQuery.size.width * 0.04,
            ),
          ),
        ),
        SizedBox(width: mediaQuery.size.width * 0.04),
        ElevatedButton(
          onPressed:
              _isBooking ? null : () => _submitCreatedBooking(context: context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: mediaQuery.size.width * 0.06,
              vertical: mediaQuery.size.height * 0.015,
            ),
          ),
          child:
              _isLoading
                  ? SizedBox(
                    width: mediaQuery.size.width * 0.05,
                    height: mediaQuery.size.width * 0.05,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                  : Text(
                    'Submit',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: mediaQuery.size.width * 0.04,
                      color: Colors.white,
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
      setState(() {
        _errorMessage = 'Please fill all fields';
      });
      return;
    }
    if (_numberController.text.length != 10) {
      setState(() {
        _errorMessage = 'Please enter a valid mobile number';
      });
      return;
    }
    setState(() {
      _isBooking = true;
      _isLoading = true;
    });
    try {
      final bookingDate = selectedDate.toString().split(' ')[0];
      final prefs = await SharedPreferences.getInstance();
      final vendorData = prefs.getString('vendor');

      if (vendorData == null) throw Exception("User data not found");

      final decoded = jsonDecode(vendorData);
      final token = 'Bearer ${decoded['token']}';
      final userId = decoded['vendorId'];
      final jobType = decoded['type'];

      // Step 1: Create booking
      final bookingResponse = await http
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
              'pincode': _pincodeController.text,
              'type': jobType,
              'isSelfBooking': true,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (bookingResponse.statusCode != 200) {
        throw Exception(jsonDecode(bookingResponse.body)['message']);
      }

      final bookingId = jsonDecode(bookingResponse.body)['bookingId'];
      final now = selectedDateNotifier.value;

      // Step 2: Confirm booking with vendor
      final patchResponse = await http
          .patch(
            Uri.parse("${KConstantURL.url}/vendor/bookNowV/$userId"),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': token,
            },
            body: jsonEncode({
              'bookingId': bookingId,
              'name': _capitalizeFirstLetter(_nameController.text),
              'phoneNo': _numberController.text,
              'vill': _capitalizeFirstLetter(_villageController.text),
              'post': _selectedPost ?? '',
              'dist': _districtController.text,
              'pincode': _pincodeController.text,
              'date': now.day,
              'month': now.month - 1,
              'year': now.year,
              'vendorUser': decoded['vendorId'],
              'isSelfBooking': true,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (patchResponse.statusCode != 200) {
        throw Exception(jsonDecode(patchResponse.body)['message']);
      }

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
        _isBooking = false;
        _isLoading = false;
        // selectedDateNotifier.value = DateTime.now();
      });

      final responseData = jsonDecode(patchResponse.body);
      _showSuccessSnackbar(context, responseData['message']);
    } catch (e) {
      setState(() {
        _isBooking = false;
        _isLoading = false;
      });
      _showErrorSnackbar(context, e.toString());
    } finally {
      setState(() {
        _isBooking = false;
        _isLoading = false;
      });
    }
  }

  String _capitalizeFirstLetter(String str) {
    return str.isNotEmpty ? str[0].toUpperCase() + str.substring(1) : str;
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Center(
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Center(
          child: Text(
            error,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Booking',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDarkThemeNotifier.value ? Colors.teal : Colors.amber,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(mediaQuery.size.width * 0.04),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage.isNotEmpty)
                    Center(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  if (_errorMessage.isNotEmpty)
                    SizedBox(height: mediaQuery.size.height * 0.02),
                  _buildTextField('Name', _nameController, mediaQuery),
                  SizedBox(height: mediaQuery.size.height * 0.02),
                  _buildTextField(
                    'Mobile Number',
                    _numberController,
                    mediaQuery,
                  ),
                  SizedBox(height: mediaQuery.size.height * 0.02),
                  _buildTextField('Village', _villageController, mediaQuery),
                  SizedBox(height: mediaQuery.size.height * 0.02),
                  _buildDateField(context, mediaQuery),
                  SizedBox(height: mediaQuery.size.height * 0.02),
                  _buildPincodeField(mediaQuery),
                  SizedBox(height: mediaQuery.size.height * 0.02),
                  if (_postOffices.isNotEmpty) ...[
                    _buildPostDropdown(mediaQuery),
                    SizedBox(height: mediaQuery.size.height * 0.02),
                  ],
                  _buildTextField(
                    'District',
                    _districtController,
                    mediaQuery,
                    readOnly: true,
                  ),
                  SizedBox(height: mediaQuery.size.height * 0.02),
                  _buildTextField(
                    'State',
                    _stateController,
                    mediaQuery,
                    readOnly: true,
                  ),
                  SizedBox(height: mediaQuery.size.height * 0.04),
                  _buildActionButtons(context, mediaQuery),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

// ValueNotifier :- hold a single value and notify its listeners when the value changes
// ValueListenableBuilder :- listen to data (setState not required)

ValueNotifier<int> selectedPageNotifier = ValueNotifier<int>(0);
ValueNotifier<int> bookingStatusNotifier = ValueNotifier<int>(1);
ValueNotifier<Map<String, bool>> bookingIdNotifier =
    ValueNotifier<Map<String, bool>>({});

ValueNotifier<Set<DateTime>> bookingPendingNotifier =
    ValueNotifier<Set<DateTime>>({});
final ValueNotifier<bool> isCalendarCollapsedNotifier = ValueNotifier(false);

ValueNotifier<DateTime> selectedDateNotifier = ValueNotifier<DateTime>(
  DateTime.now(),
); // Holds the selected date for booking
ValueNotifier<int> bookingCountNotifier = ValueNotifier<int>(0);

ValueNotifier<bool> isDarkThemeNotifier = ValueNotifier<bool>(true);

ValueNotifier<bool> isVendor = ValueNotifier<bool>(false);
ValueNotifier<bool> isLoggedIn = ValueNotifier<bool>(false);
ValueNotifier<bool> isAddressAvailable = ValueNotifier<bool>(true);
ValueNotifier<bool> isWageRateAvailable = ValueNotifier<bool>(true);

ValueNotifier<String> savedImagePath = ValueNotifier<String>('');
ValueNotifier<String> fcmToken = ValueNotifier<String>('');

final ValueNotifier<bool> bookingsRefreshNotifier = ValueNotifier<bool>(false);
final ValueNotifier<bool> profileRefreshNotifier = ValueNotifier<bool>(false);

ValueNotifier<int> monthNotifier = ValueNotifier<int>(0);
ValueNotifier<int> yearNotifier = ValueNotifier<int>(0);

ValueNotifier<String> otpId1 = ValueNotifier<String>("");

final ValueNotifier<String?> pendingNotificationBookingIdNotifier =
    ValueNotifier<String?>(null);
final ValueNotifier<Map<String, dynamic>?> pendingNotificationDataNotifier =
    ValueNotifier<Map<String, dynamic>?>(null);

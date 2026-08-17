// import 'package:app_aapkakaam/models/data_model.dart';

class OrderCard {
  final String bookingId;
  final bool cancelOrder;
  final String date;
  final String name;
  final bool orderCompleted;
  final String phoneNo;
  final int rating;
  final String type;
  final String id;
  final String review;
  final bool isSelfBooked;

  OrderCard({
    required this.bookingId,
    required this.cancelOrder,
    required this.date,
    required this.name,
    required this.orderCompleted,
    required this.phoneNo,
    required this.rating,
    required this.type,
    required this.id,
    required this.review,
    required this.isSelfBooked,
  });

  factory OrderCard.fromJson(Map<String, dynamic> json) {
    final String userId = json['userId']?.toString() ?? '';
    final String vendorId = json['vendorId']?.toString() ?? '';

    return OrderCard(
      bookingId: json['bookingId']?.toString() ?? json['_id']?.toString() ?? '',

      cancelOrder: json['cancelOrder'] == true,

      date: json['date']?.toString() ?? json['bookingDate']?.toString() ?? '',

      name: json['name']?.toString() ?? '',

      orderCompleted: json['orderCompleted'] == true,

      phoneNo: json['phoneNo']?.toString() ?? '',

      rating:
          json['rating'] is num
              ? (json['rating'] as num).toInt()
              : int.tryParse(json['rating']?.toString() ?? '') ?? 0,

      type: json['type']?.toString() ?? '',

      id: json['_id']?.toString() ?? '',

      review: json['review']?.toString() ?? '',

      // IMPORTANT:
      // Calculate instead of expecting it from API.
      isSelfBooked:
          userId.isNotEmpty && vendorId.isNotEmpty && userId == vendorId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'cancelOrder': cancelOrder,
      'date': date,
      'name': name,
      'orderCompleted': orderCompleted,
      'phoneNo': phoneNo,
      'rating': rating,
      'type': type,
      '_id': id,
      'review': review,
      'isSelfBooked': isSelfBooked,
    };
  }
}

class BookingsCard {
  final String id;
  final String userId;
  final String vendorId;
  final String type;
  final String pincode;
  final String bookingBy;
  final BookedBy bookedById;

  final DateTime? bookingDate;
  final DateTime? bookedOn;
  final DateTime? reviewedOn;

  final String name;
  final int phoneNo;
  final String vill;
  final String post;
  final String dist;

  final double expenseUser;
  final double expenseVendor;
  final double previousBalanceUser;
  final double previousBalanceVendor;

  final int bookingTime;
  final bool cancelOrder;
  final bool orderCompleted;
  final int rating;
  final bool isServed;
  final bool isBooked;
  final String? review;

  BookingsCard({
    required this.id,
    required this.userId,
    required this.vendorId,
    required this.type,
    required this.pincode,
    required this.bookingBy,
    required this.bookedById,
    this.bookingDate,
    this.bookedOn,
    this.reviewedOn,
    required this.expenseUser,
    required this.expenseVendor,
    required this.previousBalanceUser,
    required this.previousBalanceVendor,
    required this.bookingTime,
    required this.name,
    required this.phoneNo,
    required this.vill,
    required this.post,
    required this.dist,
    required this.cancelOrder,
    required this.orderCompleted,
    required this.rating,
    required this.isServed,
    required this.isBooked,
    this.review,
  });

  /// userId == vendorId means the booking is self-booked.
  bool get isSelfBooked {
    return userId.isNotEmpty && vendorId.isNotEmpty && userId == vendorId;
  }

  /// userId != vendorId means the booking belongs to another user.
  bool get isOtherUserBooking {
    return !isSelfBooked;
  }

  factory BookingsCard.fromJson(Map<String, dynamic> json) {
    // ─────────────────────────────────────────────
    // Safe date parser
    // ─────────────────────────────────────────────
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;

      final stringValue = value.toString().trim();

      if (stringValue.isEmpty || stringValue == 'null') {
        return null;
      }

      try {
        return DateTime.parse(stringValue).toLocal();
      } catch (e) {
        print('Failed to parse date: $value');
        return null;
      }
    }

    // ─────────────────────────────────────────────
    // Safe String
    // ─────────────────────────────────────────────
    String getString(dynamic value, {String defaultValue = ''}) {
      if (value == null) return defaultValue;

      final result = value.toString();

      if (result == 'null') {
        return defaultValue;
      }

      return result;
    }

    // ─────────────────────────────────────────────
    // Safe int
    // ─────────────────────────────────────────────
    int getInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;

      if (value is int) {
        return value;
      }

      if (value is double) {
        return value.toInt();
      }

      if (value is num) {
        return value.toInt();
      }

      return int.tryParse(value.toString()) ?? defaultValue;
    }

    // ─────────────────────────────────────────────
    // Safe double
    // ─────────────────────────────────────────────
    double getDouble(dynamic value, {double defaultValue = 0.0}) {
      if (value == null) return defaultValue;

      if (value is double) {
        return value;
      }

      if (value is num) {
        return value.toDouble();
      }

      return double.tryParse(value.toString()) ?? defaultValue;
    }

    // ─────────────────────────────────────────────
    // Safe bool
    // ─────────────────────────────────────────────
    bool getBool(dynamic value, {bool defaultValue = false}) {
      if (value == null) return defaultValue;

      if (value is bool) {
        return value;
      }

      if (value is String) {
        final normalized = value.toLowerCase().trim();

        if (normalized == 'true') return true;
        if (normalized == 'false') return false;
      }

      if (value is num) {
        return value != 0;
      }

      return defaultValue;
    }

    // ─────────────────────────────────────────────
    // Booking ID
    // ─────────────────────────────────────────────
    String getBookingId() {
      final value =
          json['_id'] ?? json['id'] ?? json['bookingId'] ?? json['booking_id'];

      if (value != null) {
        final id = value.toString();

        if (id.isNotEmpty && id != 'null') {
          return id;
        }
      }

      return '';
    }

    // ─────────────────────────────────────────────
    // Main IDs
    // ─────────────────────────────────────────────
    final userId = getString(json['userId']);
    final vendorId = getString(json['vendorId']);

    // ─────────────────────────────────────────────
    // SELF BOOKING
    //
    // userId == vendorId
    //
    // Example:
    // userId   = 6a772f...
    // vendorId = 6a772f...
    // ─────────────────────────────────────────────
    final isSelfBooked =
        userId.isNotEmpty && vendorId.isNotEmpty && userId == vendorId;

    // ─────────────────────────────────────────────
    // Direct booking fields
    //
    // These exist in your second booking:
    //
    // name
    // phoneNo
    // vill
    // post
    // dist
    // ─────────────────────────────────────────────
    final directName = getString(json['name']);
    final directPhoneNo = getInt(json['phoneNo']);
    final directVill = getString(json['vill']);
    final directPost = getString(json['post']);
    final directDist = getString(json['dist']);

    // ─────────────────────────────────────────────
    // bookedById
    //
    // It can be:
    //
    // 1. String
    // 2. Map
    // 3. null
    // ─────────────────────────────────────────────
    BookedBy getBookedBy(dynamic value) {
      // bookedById is an object
      if (value is Map) {
        final map = Map<String, dynamic>.from(value);

        return BookedBy.fromJson(map);
      }

      // bookedById is a String/ObjectId
      if (value != null) {
        return BookedBy(
          id: value.toString(),
          name: directName,
          phoneNo: directPhoneNo,
          address: [
            AddressModel(
              vill: directVill,
              post: directPost,
              dist: directDist,
              state: getString(json['state']),
              pincode: getString(json['pincode']),
            ),
          ],
        );
      }

      // No bookedById
      return BookedBy(
        id: isSelfBooked ? vendorId : userId,
        name: directName,
        phoneNo: directPhoneNo,
        address: [
          AddressModel(
            vill: directVill,
            post: directPost,
            dist: directDist,
            state: getString(json['state']),
            pincode: getString(json['pincode']),
          ),
        ],
      );
    }

    final bookedBy = getBookedBy(json['bookedById']);

    // ─────────────────────────────────────────────
    // If bookedById contains no data but direct
    // booking fields exist, use those fields.
    // ─────────────────────────────────────────────
    final finalName = directName.isNotEmpty ? directName : bookedBy.name;

    final finalPhoneNo = directPhoneNo != 0 ? directPhoneNo : bookedBy.phoneNo;

    final finalAddress =
        bookedBy.address.isNotEmpty
            ? bookedBy.address.first
            : AddressModel(
              vill: directVill,
              post: directPost,
              dist: directDist,
              state: getString(json['state']),
              pincode: getString(json['pincode']),
            );

    return BookingsCard(
      id: getBookingId(),

      userId: userId,
      vendorId: vendorId,

      type: getString(json['type']),
      pincode: getString(json['pincode']),
      bookingBy: getString(json['bookingBy']),

      bookedById: BookedBy(
        id: bookedBy.id,
        name: finalName,
        phoneNo: finalPhoneNo,
        address: [
          AddressModel(
            vill: directVill.isNotEmpty ? directVill : finalAddress.vill,
            post: directPost.isNotEmpty ? directPost : finalAddress.post,
            dist: directDist.isNotEmpty ? directDist : finalAddress.dist,
            state: finalAddress.state,
            pincode: getString(json['pincode']),
          ),
        ],
      ),

      bookingDate: parseDate(json['bookingDate']),
      bookedOn: parseDate(json['bookedOn']),
      reviewedOn: parseDate(json['reviewedOn']),

      expenseUser: getDouble(json['expenseUser']),
      expenseVendor: getDouble(json['expenseVendor']),
      previousBalanceUser: getDouble(json['previousBalanceUser']),
      previousBalanceVendor: getDouble(json['previousBalanceVendor']),

      bookingTime: getInt(json['bookingTime']),

      name: finalName,
      phoneNo: finalPhoneNo,
      vill: directVill.isNotEmpty ? directVill : finalAddress.vill,
      post: directPost.isNotEmpty ? directPost : finalAddress.post,
      dist: directDist.isNotEmpty ? directDist : finalAddress.dist,

      cancelOrder: getBool(json['cancelOrder']),
      orderCompleted: getBool(json['orderCompleted']),
      rating: getInt(json['rating']),
      isServed: getBool(json['isServed']),
      isBooked: getBool(json['isBooked']),

      review: json['review']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'vendorId': vendorId,
      'type': type,
      'pincode': pincode,
      'bookingBy': bookingBy,
      'bookedById': bookedById.toJson(),

      'bookingDate': bookingDate?.toUtc().toIso8601String(),
      'bookedOn': bookedOn?.toUtc().toIso8601String(),
      'reviewedOn': reviewedOn?.toUtc().toIso8601String(),

      'expenseUser': expenseUser,
      'expenseVendor': expenseVendor,
      'previousBalanceUser': previousBalanceUser,
      'previousBalanceVendor': previousBalanceVendor,

      'bookingTime': bookingTime,

      'name': name,
      'phoneNo': phoneNo,
      'vill': vill,
      'post': post,
      'dist': dist,

      'cancelOrder': cancelOrder,
      'orderCompleted': orderCompleted,
      'rating': rating,
      'isServed': isServed,
      'isBooked': isBooked,

      'review': review,
    };
  }
}

class BookedBy {
  final String id;
  final String name;
  final int phoneNo;
  final List<AddressModel> address;

  BookedBy({
    required this.id,
    required this.name,
    required this.phoneNo,
    required this.address,
  });

  factory BookedBy.fromJson(Map<String, dynamic> json) {
    List<AddressModel> addressList = [];

    final addressData = json['address'];

    if (addressData is List) {
      addressList =
          addressData
              .whereType<Map>()
              .map((e) => AddressModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
    }

    return BookedBy(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phoneNo:
          json['phoneNo'] is num
              ? (json['phoneNo'] as num).toInt()
              : int.tryParse(json['phoneNo']?.toString() ?? '') ?? 0,
      address: addressList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'phoneNo': phoneNo,
      'address': address.map((e) => e.toJson()).toList(),
    };
  }
}

class AddressModel {
  final String vill;
  final String post;
  final String dist;
  final String state;
  final String pincode;

  AddressModel({
    required this.vill,
    required this.post,
    required this.dist,
    required this.state,
    required this.pincode,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      vill: json['vill']?.toString() ?? '',
      post: json['post']?.toString() ?? '',
      dist: json['dist']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vill': vill,
      'post': post,
      'dist': dist,
      'state': state,
      'pincode': pincode,
    };
  }
}

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
  });

  factory OrderCard.fromJson(Map<String, dynamic> json) {
    return OrderCard(
      bookingId: json['bookingId'],
      cancelOrder: json['cancelOrder'],
      date: json['date'],
      name: json['name'],
      orderCompleted: json['orderCompleted'],
      phoneNo: json['phoneNo'],
      rating: json['rating'],
      type: json['type'],
      id: json['_id'],
      review: json['review'],
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

  // Made nullable
  final DateTime? bookingDate;
  final DateTime? bookedOn;
  final DateTime? reviewedOn;

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
    required this.expenseUser,
    required this.expenseVendor,
    required this.previousBalanceUser,
    required this.previousBalanceVendor,
    required this.bookingTime,
    this.bookedOn,
    required this.cancelOrder,
    required this.orderCompleted,
    required this.rating,
    required this.isServed,
    required this.isBooked,
    this.review,
    this.reviewedOn,
  });

  factory BookingsCard.fromJson(Map<String, dynamic> json) {
    // Safe date parser with UTC to local conversion
    DateTime? parseDate(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      try {
        // Parse the UTC date
        DateTime utcDate = DateTime.parse(value.toString());
        // Convert to local time (Asia/Kolkata is UTC+5:30)
        // Add 5 hours and 30 minutes
        return utcDate.add(Duration(hours: 5, minutes: 30));
      } catch (e) {
        print('Failed to parse date: $value');
        return null;
      }
    }

    // Helper to safely convert to Map<String, dynamic>
    Map<String, dynamic> toMap(dynamic value) {
      if (value == null) return {};
      if (value is Map<String, dynamic>) return value;
      if (value is Map<dynamic, dynamic>) {
        return Map<String, dynamic>.from(value);
      }
      return {};
    }

    // Helper to safely get boolean value
    bool getBool(dynamic value, {bool defaultValue = false}) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is String) {
        return value.toLowerCase() == 'true';
      }
      if (value is int) {
        return value == 1;
      }
      return defaultValue;
    }

    // Helper to safely get double value
    double getDouble(dynamic value, {double defaultValue = 0.0}) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? defaultValue;
      }
      return defaultValue;
    }

    // Helper to safely get int value
    int getInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ?? defaultValue;
      }
      return defaultValue;
    }

    // Helper to safely get ID from various field names
    String getId(dynamic json) {
      if (json == null) return '';

      // Try common field names
      final idFields = ['_id', 'id', 'Id', 'ID', 'bookingId', 'booking_id'];
      for (final field in idFields) {
        if (json[field] != null) {
          final value = json[field].toString();
          if (value.isNotEmpty && value != 'null') {
            return value;
          }
        }
      }

      // If no ID found, try to use a timestamp or generate one
      print('No ID found in booking data: $json');
      return DateTime.now().millisecondsSinceEpoch.toString();
    }

    return BookingsCard(
      id: getId(json),
      userId: json['userId']?.toString() ?? '',
      vendorId: json['vendorId']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      bookingBy: json['bookingBy']?.toString() ?? '',
      bookedById: BookedBy.fromJson(toMap(json['bookedById'] ?? {})),
      bookingDate: parseDate(json['bookingDate']),
      expenseUser: getDouble(json['expenseUser']),
      expenseVendor: getDouble(json['expenseVendor']),
      previousBalanceUser: getDouble(json['previousBalanceUser']),
      previousBalanceVendor: getDouble(json['previousBalanceVendor']),
      bookingTime: getInt(json['bookingTime']),
      bookedOn: parseDate(json['bookedOn']),
      cancelOrder: getBool(json['cancelOrder']),
      orderCompleted: getBool(json['orderCompleted']),
      rating: getInt(json['rating']),
      isServed: getBool(json['isServed']),
      isBooked: getBool(json['isBooked']),
      review: json['review']?.toString(),
      reviewedOn: parseDate(json['reviewedOn']),
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
      'expenseUser': expenseUser,
      'expenseVendor': expenseVendor,
      'previousBalanceUser': previousBalanceUser,
      'previousBalanceVendor': previousBalanceVendor,
      'bookingTime': bookingTime,
      'bookedOn': bookedOn?.toUtc().toIso8601String(),
      'cancelOrder': cancelOrder,
      'orderCompleted': orderCompleted,
      'rating': rating,
      'isServed': isServed,
      'isBooked': isBooked,
      'review': review,
      'reviewedOn': reviewedOn?.toUtc().toIso8601String(),
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
    // Helper to safely convert address list items
    List<AddressModel> parseAddresses(dynamic addressData) {
      if (addressData is List) {
        return addressData.map((item) {
          try {
            if (item is Map<String, dynamic>) {
              return AddressModel.fromJson(item);
            } else if (item is Map<dynamic, dynamic>) {
              return AddressModel.fromJson(Map<String, dynamic>.from(item));
            }
            return AddressModel.fromJson({});
          } catch (e) {
            print('Error parsing address: $e');
            return AddressModel.fromJson({});
          }
        }).toList();
      }
      return [];
    }

    // Helper to safely get phone number
    int getPhoneNo(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        return int.tryParse(value.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
      }
      return 0;
    }

    return BookedBy(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phoneNo: getPhoneNo(json['phoneNo']),
      address: parseAddresses(json['address']),
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

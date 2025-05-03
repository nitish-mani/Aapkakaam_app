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
    };
  }
}

class BookingsCard {
  final String bookingId;
  final bool cancelOrder;
  final String date;
  final String name;
  final bool orderCompleted;
  final String phoneNo;
  final int rating;
  final String type;
  final String id;

  BookingsCard({
    required this.bookingId,
    required this.cancelOrder,
    required this.date,
    required this.name,
    required this.orderCompleted,
    required this.phoneNo,
    required this.rating,
    required this.type,
    required this.id,
  });

  factory BookingsCard.fromJson(Map<String, dynamic> json) {
    return BookingsCard(
      bookingId: json['bookingId'],
      cancelOrder: json['cancelOrder'],
      date: json['date'],
      name: json['name'],
      orderCompleted: json['orderCompleted'],
      phoneNo: json['phoneNo'],
      rating: json['rating'],
      type: json['type'],
      id: json['_id'],
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
    };
  }
}

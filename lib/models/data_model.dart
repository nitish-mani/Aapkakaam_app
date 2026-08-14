class Address {
  final String vill;
  final String post;
  final String dist;
  final String state;
  final String pincode;

  Address({
    required this.vill,
    required this.post,
    required this.dist,
    required this.state,
    required this.pincode,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      vill: json['vill'],
      post: json['post'],
      dist: json['dist'],
      state: json['state'],
      pincode: json['pincode'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      "vill": vill,
      "post": post,
      "dist": dist,
      "state": state,
      "pincode": pincode,
    };
  }
}

class VendorModel {
  final String token;
  final String vendorId;
  final String name;
  final String? email;
  final bool verifyEmail;
  final int phoneNo;
  final bool verifyPhoneNo;
  final String type;
  final String gender;
  final double rating;
  final int ratingCount;
  final double? wageRate; // ✅ Changed from int? to double?
  final List<Address> address;
  final double balance; // ✅ Changed from int to double
  final String wageRateType;
  final double commission; // ✅ Changed from int to double
  final int transactionCount;
  final double totalDiscount; // ✅ Changed from int to double
  final double totalOriginalAmount; // ✅ Changed from int to double
  final String? imgURL;
  final int pending;
  final int completed;
  final int canceled;
  final double earning; // ✅ Changed from int to double
  final String pincode;
  final String? fcmToken;
  final int shareCount;
  final double? experience; // ✅ Changed from int? to double?
  final String message;

  VendorModel({
    required this.token,
    required this.vendorId,
    required this.name,
    required this.email,
    required this.verifyEmail,
    required this.phoneNo,
    required this.verifyPhoneNo,
    required this.type,
    required this.gender,
    required this.rating,
    required this.ratingCount,
    required this.wageRate,
    required this.address,
    required this.balance,
    required this.wageRateType,
    this.commission = 0.0, // ✅ Changed to double
    this.transactionCount = 0,
    this.totalDiscount = 0.0, // ✅ Changed to double
    this.totalOriginalAmount = 0.0, // ✅ Changed to double
    this.imgURL,
    this.pending = 0,
    this.completed = 0,
    this.canceled = 0,
    this.earning = 0.0, // ✅ Changed to double
    this.pincode = '',
    this.fcmToken,
    this.shareCount = 0,
    this.experience,
    required this.message,
  });

  VendorModel copyWith({
    String? token,
    String? vendorId,
    String? name,
    String? email,
    bool? verifyEmail,
    int? phoneNo,
    bool? verifyPhoneNo,
    String? type,
    String? gender,
    double? rating,
    int? ratingCount,
    double? wageRate, // ✅ Changed to double
    List<Address>? address,
    double? balance, // ✅ Changed to double
    String? wageRateType,
    double? commission, // ✅ Changed to double
    int? transactionCount,
    double? totalDiscount, // ✅ Changed to double
    double? totalOriginalAmount, // ✅ Changed to double
    String? imgURL,
    int? pending,
    int? completed,
    int? canceled,
    double? earning, // ✅ Changed to double
    String? pincode,
    String? fcmToken,
    int? shareCount,
    double? experience, // ✅ Changed to double
    String? message,
  }) {
    return VendorModel(
      token: token ?? this.token,
      vendorId: vendorId ?? this.vendorId,
      name: name ?? this.name,
      email: email ?? this.email,
      verifyEmail: verifyEmail ?? this.verifyEmail,
      phoneNo: phoneNo ?? this.phoneNo,
      verifyPhoneNo: verifyPhoneNo ?? this.verifyPhoneNo,
      type: type ?? this.type,
      gender: gender ?? this.gender,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      wageRate: wageRate ?? this.wageRate,
      address: address ?? this.address,
      balance: balance ?? this.balance,
      wageRateType: wageRateType ?? this.wageRateType,
      commission: commission ?? this.commission,
      transactionCount: transactionCount ?? this.transactionCount,
      totalDiscount: totalDiscount ?? this.totalDiscount,
      totalOriginalAmount: totalOriginalAmount ?? this.totalOriginalAmount,
      imgURL: imgURL ?? this.imgURL,
      pending: pending ?? this.pending,
      completed: completed ?? this.completed,
      canceled: canceled ?? this.canceled,
      earning: earning ?? this.earning,
      pincode: pincode ?? this.pincode,
      fcmToken: fcmToken ?? this.fcmToken,
      shareCount: shareCount ?? this.shareCount,
      experience: experience ?? this.experience,
      message: message ?? this.message,
    );
  }

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      token: json['token'] ?? '',
      vendorId: json['vendorId']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      verifyEmail: json['verifyEmail'] ?? false,
      phoneNo: json['phoneNo'] ?? 0,
      verifyPhoneNo: json['verifyPhoneNo'] ?? false,
      type: json['type'] ?? '',
      gender: json['gender'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      ratingCount: json['ratingCount'] ?? 0,
      wageRate: (json['wageRate'] as num?)?.toDouble(), // ✅ Convert to double
      address:
          (json['address'] as List?)
              ?.map((e) => Address.fromJson(e))
              .toList() ??
          [],
      balance: (json['balance'] ?? 0).toDouble(), // ✅ Convert to double
      wageRateType: json['wageRateType'] ?? '',
      commission: (json['commission'] ?? 0).toDouble(), // ✅ Convert to double
      transactionCount: json['transactionCount'] ?? 0,
      totalDiscount:
          (json['totalDiscount'] ?? 0).toDouble(), // ✅ Convert to double
      totalOriginalAmount:
          (json['totalOriginalAmount'] ?? 0).toDouble(), // ✅ Convert to double
      imgURL: json['imgURL'],
      pending: json['pending'] ?? 0,
      completed: json['completed'] ?? 0,
      canceled: json['canceled'] ?? 0,
      earning: (json['earning'] ?? 0).toDouble(), // ✅ Convert to double
      pincode: json['pincode']?.toString() ?? '',
      fcmToken: json['fcmToken'],
      shareCount: json['shareCount'] ?? 0,
      experience:
          (json['experience'] as num?)?.toDouble(), // ✅ Convert to double
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "token": token,
      "vendorId": vendorId,
      "name": name,
      "email": email,
      "verifyEmail": verifyEmail,
      "phoneNo": phoneNo,
      "verifyPhoneNo": verifyPhoneNo,
      "gender": gender,
      "type": type,
      "rating": rating,
      "ratingCount": ratingCount,
      "wageRate": wageRate,
      "address": address.map((e) => e.toJson()).toList(),
      "balance": balance,
      "wageRateType": wageRateType,
      "commission": commission,
      "transactionCount": transactionCount,
      "totalDiscount": totalDiscount,
      "totalOriginalAmount": totalOriginalAmount,
      "imgURL": imgURL,
      "pending": pending,
      "completed": completed,
      "canceled": canceled,
      "earning": earning,
      "pincode": pincode,
      "fcmToken": fcmToken,
      "shareCount": shareCount,
      "experience": experience,
      "message": message,
    };
  }
}

class UserModel {
  final String token;
  final String userId;
  final String name;
  final String? email;
  final bool verifyEmail;
  final int phoneNo;
  final bool verifyPhoneNo;
  final String gender;
  final List<Address> address;
  final double balance; // ✅ Changed from int to double
  final int transactionCount;
  final double totalDiscount; // ✅ Changed from int to double
  final double totalOriginalAmount; // ✅ Changed from int to double
  final String? imgURL;
  final int pending;
  final int completed;
  final int canceled;
  final String pincode;
  final String? fcmToken;
  final int shareCount;
  final String message;

  UserModel({
    required this.token,
    required this.userId,
    required this.name,
    required this.email,
    required this.verifyEmail,
    required this.phoneNo,
    required this.verifyPhoneNo,
    required this.gender,
    required this.address,
    required this.balance,
    this.transactionCount = 0,
    this.totalDiscount = 0.0, // ✅ Changed to double
    this.totalOriginalAmount = 0.0, // ✅ Changed to double
    this.imgURL,
    this.pending = 0,
    this.completed = 0,
    this.canceled = 0,
    this.pincode = '',
    this.fcmToken,
    this.shareCount = 0,
    required this.message,
  });

  UserModel copyWith({
    String? token,
    String? userId,
    String? name,
    String? email,
    bool? verifyEmail,
    int? phoneNo,
    bool? verifyPhoneNo,
    String? gender,
    List<Address>? address,
    double? balance, // ✅ Changed to double
    int? transactionCount,
    double? totalDiscount, // ✅ Changed to double
    double? totalOriginalAmount, // ✅ Changed to double
    String? imgURL,
    int? pending,
    int? completed,
    int? canceled,
    String? pincode,
    String? fcmToken,
    int? shareCount,
    String? message,
  }) {
    return UserModel(
      token: token ?? this.token,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      verifyEmail: verifyEmail ?? this.verifyEmail,
      phoneNo: phoneNo ?? this.phoneNo,
      verifyPhoneNo: verifyPhoneNo ?? this.verifyPhoneNo,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      balance: balance ?? this.balance,
      transactionCount: transactionCount ?? this.transactionCount,
      totalDiscount: totalDiscount ?? this.totalDiscount,
      totalOriginalAmount: totalOriginalAmount ?? this.totalOriginalAmount,
      imgURL: imgURL ?? this.imgURL,
      pending: pending ?? this.pending,
      completed: completed ?? this.completed,
      canceled: canceled ?? this.canceled,
      pincode: pincode ?? this.pincode,
      fcmToken: fcmToken ?? this.fcmToken,
      shareCount: shareCount ?? this.shareCount,
      message: message ?? this.message,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      token: json['token'] ?? '',
      userId: json['userId']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      verifyEmail: json['verifyEmail'] ?? false,
      phoneNo: json['phoneNo'] ?? 0,
      verifyPhoneNo: json['verifyPhoneNo'] ?? false,
      gender: json['gender'] ?? '',
      address:
          (json['address'] as List?)
              ?.map((e) => Address.fromJson(e))
              .toList() ??
          [],
      balance: (json['balance'] ?? 0).toDouble(), // ✅ Convert to double
      transactionCount: json['transactionCount'] ?? 0,
      totalDiscount:
          (json['totalDiscount'] ?? 0).toDouble(), // ✅ Convert to double
      totalOriginalAmount:
          (json['totalOriginalAmount'] ?? 0).toDouble(), // ✅ Convert to double
      imgURL: json['imgURL'],
      pending: json['pending'] ?? 0,
      completed: json['completed'] ?? 0,
      canceled: json['canceled'] ?? 0,
      pincode: json['pincode']?.toString() ?? '',
      fcmToken: json['fcmToken'],
      shareCount: json['shareCount'] ?? 0,
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "token": token,
      "userId": userId,
      "name": name,
      "email": email,
      "verifyEmail": verifyEmail,
      "phoneNo": phoneNo,
      "verifyPhoneNo": verifyPhoneNo,
      "gender": gender,
      "address": address.map((e) => e.toJson()).toList(),
      "balance": balance,
      "transactionCount": transactionCount,
      "totalDiscount": totalDiscount,
      "totalOriginalAmount": totalOriginalAmount,
      "imgURL": imgURL,
      "pending": pending,
      "completed": completed,
      "canceled": canceled,
      "pincode": pincode,
      "fcmToken": fcmToken,
      "shareCount": shareCount,
      "message": message,
    };
  }
}

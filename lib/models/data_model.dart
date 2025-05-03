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
  final int? wageRate;
  final List<Address> address;
  final int balance;
  final int bonusAmount;
  final String? imgURL;
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
    required this.bonusAmount,
    required this.imgURL,
    required this.message,
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      token: json['token'],
      vendorId: json['vendorId'],
      name: json['name'],
      email: json['email'],
      verifyEmail: json['verifyEmail'],
      phoneNo: json['phoneNo'],
      verifyPhoneNo: json['verifyPhoneNo'],
      type: json['type'],
      gender: json['gender'],
      rating: json['rating'].toDouble(),
      ratingCount: json['ratingCount'],
      wageRate: json['wageRate'],
      address:
          (json['address'] as List).map((e) => Address.fromJson(e)).toList(),
      balance: json['balance'],
      bonusAmount: json['bonusAmount'],
      imgURL: json['imgURL'],
      message: json['message'],
    );
  }
  // Convert to JSON
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
      "bonusAmount": bonusAmount,
      "imgURL": imgURL,
      "message": message,
    };
  }
}

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
  final int balance;
  final int bonusAmount;
  final String? imgURL;
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
    required this.bonusAmount,
    required this.imgURL,
    required this.message,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      token: json['token'],
      userId: json['userId'],
      name: json['name'],
      email: json['email'],
      verifyEmail: json['verifyEmail'],
      phoneNo: json['phoneNo'],
      verifyPhoneNo: json['verifyPhoneNo'],
      gender: json['gender'],
      address:
          (json['address'] as List).map((e) => Address.fromJson(e)).toList(),
      balance: json['balance'],
      bonusAmount: json['bonusAmount'],
      imgURL: json['imgURL'],
      message: json['message'],
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
      "bonusAmount": bonusAmount,
      "imgURL": imgURL,
      "message": message,
    };
  }
}

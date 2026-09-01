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
      vill: json['vill']?.toString() ?? '',
      post: json['post']?.toString() ?? '',
      dist: json['dist']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
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
  static const int maxJobs = 5;

  final String token;
  final String vendorId;
  final String name;
  final String? email;
  final bool verifyEmail;
  final int phoneNo;
  final bool verifyPhoneNo;

  // ============================================================
  // MULTIPLE JOBS
  // ============================================================
  final List<String> type;

  // ============================================================
  // WAGE RATES - Now arrays matching type length
  // ============================================================
  final List<double?> wageRate; // List of rates per job
  final List<String> wageRateType; // List of rate types per job

  // ============================================================
  // OTHER FIELDS
  // ============================================================
  final String gender;
  final double rating;
  final int ratingCount;
  final List<Address> address;
  final double balance;
  final double commission;
  final int transactionCount;
  final double totalDiscount;
  final double totalOriginalAmount;
  final String? imgURL;
  final int pending;
  final int completed;
  final int canceled;
  final double earning;
  final String pincode;
  final String? fcmToken;
  final int shareCount;
  final double? experience;
  final String message;
  final String? validPhoneNoId;
  final String? validEmailId;
  final bool isVerified;
  final bool isSelfBooked;
  final String status;
  final DateTime? accountCreatedOn;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VendorModel({
    required this.token,
    required this.vendorId,
    required this.name,
    required this.email,
    required this.verifyEmail,
    required this.phoneNo,
    required this.verifyPhoneNo,
    required this.type,
    required this.wageRate,
    required this.wageRateType,
    required this.gender,
    required this.rating,
    required this.ratingCount,
    required this.address,
    required this.balance,
    this.commission = 0.0,
    this.transactionCount = 0,
    this.totalDiscount = 0.0,
    this.totalOriginalAmount = 0.0,
    this.imgURL,
    this.pending = 0,
    this.completed = 0,
    this.canceled = 0,
    this.earning = 0.0,
    this.pincode = '',
    this.fcmToken,
    this.shareCount = 0,
    this.experience,
    this.validPhoneNoId,
    this.validEmailId,
    this.isVerified = false,
    this.isSelfBooked = false,
    this.status = 'active',
    this.accountCreatedOn,
    this.createdAt,
    this.updatedAt,
    required this.message,
  });

  // ============================================================
  // COPY WITH
  // ============================================================

  VendorModel copyWith({
    String? token,
    String? vendorId,
    String? name,
    String? email,
    bool? verifyEmail,
    int? phoneNo,
    bool? verifyPhoneNo,
    List<String>? type,
    List<double?>? wageRate,
    List<String>? wageRateType,
    String? gender,
    double? rating,
    int? ratingCount,
    List<Address>? address,
    double? balance,
    double? commission,
    int? transactionCount,
    double? totalDiscount,
    double? totalOriginalAmount,
    String? imgURL,
    int? pending,
    int? completed,
    int? canceled,
    double? earning,
    String? pincode,
    String? fcmToken,
    int? shareCount,
    double? experience,
    String? validPhoneNoId,
    String? validEmailId,
    bool? isVerified,
    bool? isSelfBooked,
    String? status,
    DateTime? accountCreatedOn,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      wageRate: wageRate ?? this.wageRate,
      wageRateType: wageRateType ?? this.wageRateType,
      gender: gender ?? this.gender,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      address: address ?? this.address,
      balance: balance ?? this.balance,
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
      validPhoneNoId: validPhoneNoId ?? this.validPhoneNoId,
      validEmailId: validEmailId ?? this.validEmailId,
      isVerified: isVerified ?? this.isVerified,
      isSelfBooked: isSelfBooked ?? this.isSelfBooked,
      status: status ?? this.status,
      accountCreatedOn: accountCreatedOn ?? this.accountCreatedOn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      message: message ?? this.message,
    );
  }

  // ============================================================
  // FROM JSON
  // ============================================================

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    // -----------------------------------------
    // Parse Jobs (type)
    // -----------------------------------------
    final dynamic rawType = json['type'];
    final List<String> parsedTypes;

    if (rawType is List) {
      parsedTypes =
          rawType
              .map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList();
    } else if (rawType != null && rawType.toString().trim().isNotEmpty) {
      parsedTypes = [rawType.toString()];
    } else {
      parsedTypes = [];
    }

    // -----------------------------------------
    // Parse Wage Rates (array)
    // -----------------------------------------
    final dynamic rawWageRate = json['wageRate'];
    final List<double?> parsedWageRates;

    if (rawWageRate is List) {
      parsedWageRates =
          rawWageRate.map((e) {
            if (e == null) return null;
            if (e is num) return e.toDouble();
            if (e is String && e.trim().isNotEmpty) {
              return double.tryParse(e);
            }
            return null;
          }).toList();
    } else if (rawWageRate != null) {
      // Backward compatibility: single value
      if (rawWageRate is num) {
        parsedWageRates = [rawWageRate.toDouble()];
      } else if (rawWageRate is String && rawWageRate.trim().isNotEmpty) {
        parsedWageRates = [double.tryParse(rawWageRate) ?? 0.0];
      } else {
        parsedWageRates = [];
      }
    } else {
      parsedWageRates = [];
    }

    // -----------------------------------------
    // Parse Wage Rate Types (array)
    // -----------------------------------------
    final dynamic rawWageRateType = json['wageRateType'];
    final List<String> parsedWageRateTypes;

    if (rawWageRateType is List) {
      parsedWageRateTypes =
          rawWageRateType.map((e) => e?.toString() ?? '').toList();
    } else if (rawWageRateType != null &&
        rawWageRateType.toString().isNotEmpty) {
      // Backward compatibility: single value
      parsedWageRateTypes = [rawWageRateType.toString()];
    } else {
      parsedWageRateTypes = [];
    }

    // -----------------------------------------
    // Parse Address
    // -----------------------------------------
    final List<Address> parsedAddress = [];
    final rawAddress = json['address'];
    if (rawAddress is List) {
      for (final item in rawAddress) {
        try {
          if (item is Map) {
            parsedAddress.add(
              Address.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        } catch (e) {
          // Skip invalid address entries
        }
      }
    }

    // -----------------------------------------
    // Parse Dates
    // -----------------------------------------
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    return VendorModel(
      token: json['token'] ?? '',
      vendorId: json['vendorId']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      verifyEmail: json['verifyEmail'] ?? false,
      phoneNo: json['phoneNo'] ?? 0,
      verifyPhoneNo: json['verifyPhoneNo'] ?? false,
      type: parsedTypes,
      wageRate: parsedWageRates,
      wageRateType: parsedWageRateTypes,
      gender: json['gender'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      ratingCount: json['ratingCount'] ?? 0,
      address: parsedAddress,
      balance: (json['balance'] ?? 0).toDouble(),
      commission: (json['commission'] ?? 0).toDouble(),
      transactionCount: json['transactionCount'] ?? 0,
      totalDiscount: (json['totalDiscount'] ?? 0).toDouble(),
      totalOriginalAmount: (json['totalOriginalAmount'] ?? 0).toDouble(),
      imgURL: json['imgURL'],
      pending: json['pending'] ?? 0,
      completed: json['completed'] ?? 0,
      canceled: json['canceled'] ?? 0,
      earning: (json['earning'] ?? 0).toDouble(),
      pincode: json['pincode']?.toString() ?? '',
      fcmToken: json['fcmToken'],
      shareCount: json['shareCount'] ?? 0,
      experience: (json['experience'] as num?)?.toDouble(),
      validPhoneNoId: json['validPhoneNoId'],
      validEmailId: json['validEmailId'],
      isVerified: json['isVerified'] ?? false,
      isSelfBooked: json['isSelfBooked'] ?? false,
      status: json['status'] ?? 'active',
      accountCreatedOn: parseDate(json['accountCreatedOn']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      message: json['message'] ?? '',
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      "token": token,
      "vendorId": vendorId,
      "name": name,
      "email": email,
      "verifyEmail": verifyEmail,
      "phoneNo": phoneNo,
      "verifyPhoneNo": verifyPhoneNo,
      "type": type,
      "wageRate": wageRate,
      "wageRateType": wageRateType,
      "gender": gender,
      "rating": rating,
      "ratingCount": ratingCount,
      "address": address.map((e) => e.toJson()).toList(),
      "balance": balance,
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
      "validPhoneNoId": validPhoneNoId,
      "validEmailId": validEmailId,
      "isVerified": isVerified,
      "isSelfBooked": isSelfBooked,
      "status": status,
      "accountCreatedOn": accountCreatedOn?.toIso8601String(),
      "createdAt": createdAt?.toIso8601String(),
      "updatedAt": updatedAt?.toIso8601String(),
      "message": message,
    };
  }

  // ============================================================
  // CONVENIENCE HELPERS
  // ============================================================

  /// First job, useful where old UI expects one job.
  String get primaryType => type.isNotEmpty ? type.first : '';

  /// Get wage rate for a specific job by index
  double? getWageRateForJob(int index) {
    if (index >= 0 && index < wageRate.length) {
      return wageRate[index];
    }
    return null;
  }

  /// Get wage rate type for a specific job by index
  String getWageRateTypeForJob(int index) {
    if (index >= 0 && index < wageRateType.length) {
      return wageRateType[index];
    }
    return '';
  }

  /// Get wage rate for a specific job by name
  double? getWageRateForJobName(String jobName) {
    final index = type.indexWhere(
      (item) => item.toLowerCase() == jobName.toLowerCase(),
    );
    if (index >= 0 && index < wageRate.length) {
      return wageRate[index];
    }
    return null;
  }

  /// Get wage rate type for a specific job by name
  String getWageRateTypeForJobName(String jobName) {
    final index = type.indexWhere(
      (item) => item.toLowerCase() == jobName.toLowerCase(),
    );
    if (index >= 0 && index < wageRateType.length) {
      return wageRateType[index];
    }
    return '';
  }

  /// Check whether vendor provides a particular job.
  bool hasJob(String job) {
    final normalized = job.trim().toLowerCase();
    return type.any((item) => item.trim().toLowerCase() == normalized);
  }

  /// Display jobs as comma-separated text.
  String get jobsDisplay => type.join(', ');

  /// Get all jobs with their rates as a map
  Map<String, Map<String, dynamic>> get jobsWithRates {
    final result = <String, Map<String, dynamic>>{};
    for (int i = 0; i < type.length; i++) {
      final job = type[i];
      final rate = i < wageRate.length ? wageRate[i] : null;
      final rateType = i < wageRateType.length ? wageRateType[i] : '';
      result[job] = {'rate': rate, 'rateType': rateType};
    }
    return result;
  }

  /// Get all jobs with their rates as a list of maps
  List<Map<String, dynamic>> get jobsWithRatesList {
    final result = <Map<String, dynamic>>[];
    for (int i = 0; i < type.length; i++) {
      final job = type[i];
      final rate = i < wageRate.length ? wageRate[i] : null;
      final rateType = i < wageRateType.length ? wageRateType[i] : '';
      result.add({'job': job, 'rate': rate, 'rateType': rateType});
    }
    return result;
  }

  /// Check if a job has a wage rate set
  bool hasWageRateForJob(String jobName) {
    final index = type.indexWhere(
      (item) => item.toLowerCase() == jobName.toLowerCase(),
    );
    if (index >= 0 && index < wageRate.length) {
      return wageRate[index] != null;
    }
    return false;
  }

  /// Get the total number of jobs with rates set
  int get jobsWithRatesCount {
    int count = 0;
    for (int i = 0; i < type.length && i < wageRate.length; i++) {
      if (wageRate[i] != null) count++;
    }
    return count;
  }

  /// Validate that wageRate and wageRateType arrays match type length
  bool get isWageDataValid {
    if (type.isEmpty) return true;
    if (wageRate.length != type.length) return false;
    if (wageRateType.length != type.length) return false;
    return true;
  }

  /// Normalize wage data to match type length
  VendorModel normalizeWageData() {
    if (type.isEmpty) {
      return copyWith(wageRate: [], wageRateType: []);
    }

    final List<double?> normalizedRates = List.from(wageRate);
    final List<String> normalizedTypes = List.from(wageRateType);

    // Pad or trim to match type length
    while (normalizedRates.length < type.length) {
      normalizedRates.add(null);
    }
    while (normalizedTypes.length < type.length) {
      normalizedTypes.add('');
    }

    // Trim excess
    if (normalizedRates.length > type.length) {
      normalizedRates.removeRange(type.length, normalizedRates.length);
    }
    if (normalizedTypes.length > type.length) {
      normalizedTypes.removeRange(type.length, normalizedTypes.length);
    }

    return copyWith(wageRate: normalizedRates, wageRateType: normalizedTypes);
  }

  /// Create a copy with updated wage rate for a specific job
  VendorModel updateWageRateForJob(String jobName, double? newRate) {
    final index = type.indexWhere(
      (item) => item.toLowerCase() == jobName.toLowerCase(),
    );
    if (index == -1) return this;

    final newRates = List<double?>.from(wageRate);
    while (newRates.length <= index) {
      newRates.add(null);
    }
    newRates[index] = newRate;

    return copyWith(wageRate: newRates);
  }

  /// Create a copy with updated wage rate type for a specific job
  VendorModel updateWageRateTypeForJob(String jobName, String newType) {
    final index = type.indexWhere(
      (item) => item.toLowerCase() == jobName.toLowerCase(),
    );
    if (index == -1) return this;

    final newTypes = List<String>.from(wageRateType);
    while (newTypes.length <= index) {
      newTypes.add('');
    }
    newTypes[index] = newType;

    return copyWith(wageRateType: newTypes);
  }

  /// Create a copy with updated wage rate and type for a specific job
  VendorModel updateWageRateForJobFull(
    String jobName,
    double? newRate,
    String newType,
  ) {
    final index = type.indexWhere(
      (item) => item.toLowerCase() == jobName.toLowerCase(),
    );
    if (index == -1) return this;

    final newRates = List<double?>.from(wageRate);
    final newTypes = List<String>.from(wageRateType);

    while (newRates.length <= index) {
      newRates.add(null);
    }
    while (newTypes.length <= index) {
      newTypes.add('');
    }

    newRates[index] = newRate;
    newTypes[index] = newType;

    return copyWith(wageRate: newRates, wageRateType: newTypes);
  }

  /// Get formatted display string for a job's wage
  String getWageDisplayForJob(String jobName) {
    final rate = getWageRateForJobName(jobName);
    final type = getWageRateTypeForJobName(jobName);

    if (rate == null) return 'Not set';
    if (type.isEmpty) return '₹${rate.toStringAsFixed(0)}';
    return '₹${rate.toStringAsFixed(0)} / $type';
  }

  /// Get all jobs with formatted wage display
  List<Map<String, String>> get jobsWithWageDisplay {
    final result = <Map<String, String>>[];
    for (int i = 0; i < type.length; i++) {
      final job = type[i];
      final rate = i < wageRate.length ? wageRate[i] : null;
      final rateType = i < wageRateType.length ? wageRateType[i] : '';
      final display =
          rate == null
              ? 'Not set'
              : rateType.isEmpty
              ? '₹${rate.toStringAsFixed(0)}'
              : '₹${rate.toStringAsFixed(0)} / $rateType';
      result.add({'job': job, 'display': display});
    }
    return result;
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

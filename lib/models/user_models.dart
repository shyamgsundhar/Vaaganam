class Driver {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? passcode;
  final int? age;
  final String? gender;
  final String? licenseNumber;
  final String? experience;
  final bool isActive;
  final int totalTrips;
  final double rating;
  final DateTime? joiningDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Driver({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.passcode,
    this.age,
    this.gender,
    this.licenseNumber,
    this.experience,
    this.isActive = true,
    this.totalTrips = 0,
    this.rating = 5.0,
    this.joiningDate,
    this.createdAt,
    this.updatedAt,
  });

  factory Driver.fromMap(Map<String, dynamic> map) {
    return Driver(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      passcode: map['passcode'],
      age: map['age'],
      gender: map['gender'],
      licenseNumber: map['licenseNumber'],
      experience: map['experience'],
      isActive: map['isActive'] ?? true,
      totalTrips: map['totalTrips'] ?? 0,
      rating: (map['rating'] ?? 5.0).toDouble(),
      joiningDate: map['joiningDate']?.toDate(),
      createdAt: map['createdAt']?.toDate(),
      updatedAt: map['updatedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'passcode': passcode,
      'age': age,
      'gender': gender,
      'licenseNumber': licenseNumber,
      'experience': experience,
      'role': 'driver',
      'isActive': isActive,
      'totalTrips': totalTrips,
      'rating': rating,
      'joiningDate': joiningDate,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Driver copyWith({
    String? name,
    String? email,
    String? phone,
    String? passcode,
    int? age,
    String? gender,
    String? licenseNumber,
    String? experience,
    bool? isActive,
    int? totalTrips,
    double? rating,
  }) {
    return Driver(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      passcode: passcode ?? this.passcode,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      experience: experience ?? this.experience,
      isActive: isActive ?? this.isActive,
      totalTrips: totalTrips ?? this.totalTrips,
      rating: rating ?? this.rating,
      joiningDate: joiningDate,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class Dispatcher {
  final String uid;
  final String name;
  final String email;
  final String? department;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Dispatcher({
    required this.uid,
    required this.name,
    required this.email,
    this.department,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Dispatcher.fromMap(Map<String, dynamic> map) {
    return Dispatcher(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      department: map['department'],
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt']?.toDate(),
      updatedAt: map['updatedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'department': department,
      'role': 'dispatcher',
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Dispatcher copyWith({
    String? name,
    String? email,
    String? department,
    bool? isActive,
  }) {
    return Dispatcher(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

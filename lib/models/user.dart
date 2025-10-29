enum UserRole { customer, owner, admin }

enum VerificationStatus { unverified, pending, verified, rejected }

class UNESAVerification {
  final String ktmImageUrl;
  final String nim;
  final String faculty;
  final String major;
  final VerificationStatus status;
  final DateTime? submittedAt;
  final DateTime? verifiedAt;
  final String? rejectionReason;

  UNESAVerification({
    required this.ktmImageUrl,
    required this.nim,
    required this.faculty,
    required this.major,
    required this.status,
    this.submittedAt,
    this.verifiedAt,
    this.rejectionReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'ktmImageUrl': ktmImageUrl,
      'nim': nim,
      'faculty': faculty,
      'major': major,
      'status': status.name,
      'submittedAt': submittedAt?.toIso8601String(),
      'verifiedAt': verifiedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
    };
  }

  factory UNESAVerification.fromJson(Map<String, dynamic> json) {
    return UNESAVerification(
      ktmImageUrl: json['ktmImageUrl'],
      nim: json['nim'],
      faculty: json['faculty'],
      major: json['major'],
      status: VerificationStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'])
          : null,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'])
          : null,
      rejectionReason: json['rejectionReason'],
    );
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final UserRole role;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isVerified;
  final List<String> ownedKosts;

  // NEW: UNESA Verification
  final UNESAVerification? unesaVerification;
  final bool hasUNESADiscount;

  // NEW: Social Login
  final String? googleId;
  final String? phoneVerificationId;

  // NEW: Profile completeness
  final String? bio;
  final String? address;
  final DateTime? dateOfBirth;
  final String? gender;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    required this.role,
    this.profileImageUrl,
    required this.createdAt,
    this.lastLoginAt,
    this.isVerified = false,
    List<String>? ownedKosts,
    this.unesaVerification,
    this.hasUNESADiscount = false,
    this.googleId,
    this.phoneVerificationId,
    this.bio,
    this.address,
    this.dateOfBirth,
    this.gender,
  }) : ownedKosts = ownedKosts ?? [];

  // Check if user is UNESA student
  bool get isUNESAStudent =>
      unesaVerification?.status == VerificationStatus.verified;

  // Check if profile is complete
  bool get isProfileComplete {
    return name.isNotEmpty &&
        email.isNotEmpty &&
        phoneNumber != null &&
        profileImageUrl != null &&
        bio != null &&
        address != null;
  }

  // Get profile completion percentage
  int get profileCompletionPercentage {
    int completed = 0;
    int total = 7;

    if (name.isNotEmpty) completed++;
    if (email.isNotEmpty) completed++;
    if (phoneNumber != null) completed++;
    if (profileImageUrl != null) completed++;
    if (bio != null) completed++;
    if (address != null) completed++;
    if (dateOfBirth != null) completed++;

    return ((completed / total) * 100).round();
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    UserRole? role,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isVerified,
    List<String>? ownedKosts,
    UNESAVerification? unesaVerification,
    bool? hasUNESADiscount,
    String? googleId,
    String? phoneVerificationId,
    String? bio,
    String? address,
    DateTime? dateOfBirth,
    String? gender,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isVerified: isVerified ?? this.isVerified,
      ownedKosts: ownedKosts ?? this.ownedKosts,
      unesaVerification: unesaVerification ?? this.unesaVerification,
      hasUNESADiscount: hasUNESADiscount ?? this.hasUNESADiscount,
      googleId: googleId ?? this.googleId,
      phoneVerificationId: phoneVerificationId ?? this.phoneVerificationId,
      bio: bio ?? this.bio,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role.name,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isVerified': isVerified,
      'ownedKosts': ownedKosts,
      'unesaVerification': unesaVerification?.toJson(),
      'hasUNESADiscount': hasUNESADiscount,
      'googleId': googleId,
      'phoneVerificationId': phoneVerificationId,
      'bio': bio,
      'address': address,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      role: UserRole.values.firstWhere((e) => e.name == json['role']),
      profileImageUrl: json['profileImageUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'])
          : null,
      isVerified: json['isVerified'] ?? false,
      ownedKosts: List<String>.from(json['ownedKosts'] ?? []),
      unesaVerification: json['unesaVerification'] != null
          ? UNESAVerification.fromJson(json['unesaVerification'])
          : null,
      hasUNESADiscount: json['hasUNESADiscount'] ?? false,
      googleId: json['googleId'],
      phoneVerificationId: json['phoneVerificationId'],
      bio: json['bio'],
      address: json['address'],
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      gender: json['gender'],
    );
  }

  String getRoleDisplayName() {
    switch (role) {
      case UserRole.customer:
        return 'Pencari Kost';
      case UserRole.owner:
        return 'Pemilik Kost';
      case UserRole.admin:
        return 'Admin';
    }
  }

  bool get isOwner => role == UserRole.owner;
  bool get isAdmin => role == UserRole.admin;
}

// Model untuk registrasi
class RegisterRequest {
  final String name;
  final String email;
  final String password;
  final String? phoneNumber;
  final UserRole role;
  final String? googleId;

  RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    this.phoneNumber,
    this.role = UserRole.customer,
    this.googleId,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'phoneNumber': phoneNumber,
      'role': role.name,
      'googleId': googleId,
    };
  }
}

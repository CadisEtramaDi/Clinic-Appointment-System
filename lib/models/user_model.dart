import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String fullName;
  final String role; // 'doctor', 'patient', 'admin'
  final String status; // 'Active' | 'Inactive'
  final String? specialty; // For doctors
  final String? phone;
  final String? profileImage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.fullName,
    required this.role,
    this.status = 'Active',
    this.specialty,
    this.phone,
    this.profileImage,
    this.createdAt,
    this.updatedAt,
  });

  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data);
  }

  /// Create UserModel from a map
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      fullName: data['fullName'] ?? data['name'] ?? '',
      role: data['role'] ?? 'patient',
      status: data['status'] ?? 'Active',
      specialty: data['specialty'],
      phone: data['phone'],
      profileImage: data['profileImage'],
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert UserModel to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'fullName': fullName,
      'role': role,
      status: status,
      'specialty': specialty,
      'phone': phone,
      'profileImage': profileImage,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Create a copy with modifications
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? fullName,
    String? role,
    String? status,
    String? specialty,
    String? phone,
    String? profileImage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      status: status ?? this.status,
      specialty: specialty ?? this.specialty,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'UserModel(uid: $uid, email: $email, fullName: $fullName, role: $role, status: $status)';
}

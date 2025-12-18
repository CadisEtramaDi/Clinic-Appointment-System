import 'package:cloud_firestore/cloud_firestore.dart';

class PatientRecord {
  final String id;
  final String patientId;
  final String patientName;
  final String? email;
  final String? phone;
  final String? dateOfBirth;
  final String? gender;
  final String? bloodType;
  final String? emergencyContact;
  final String? emergencyContactPhone;
  final List<String>? allergies;
  final List<String>? chronicConditions;
  final String? insuranceProvider;
  final String? insurancePolicyNumber;
  final String? primaryDoctorId;
  final String? primaryDoctorName;
  final DateTime? lastVisitDate;
  final DateTime? nextAppointmentDate;
  final String recordStatus; // 'active', 'inactive', 'archived'
  final bool dataComplete; // Flag for data completeness
  final List<String>? missingFields; // List of incomplete fields
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? archivedAt;

  PatientRecord({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.email,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.bloodType,
    this.emergencyContact,
    this.emergencyContactPhone,
    this.allergies,
    this.chronicConditions,
    this.insuranceProvider,
    this.insurancePolicyNumber,
    this.primaryDoctorId,
    this.primaryDoctorName,
    this.lastVisitDate,
    this.nextAppointmentDate,
    required this.recordStatus,
    required this.dataComplete,
    this.missingFields,
    this.createdAt,
    this.updatedAt,
    this.archivedAt,
  });

  /// Create PatientRecord from Firestore document
  factory PatientRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PatientRecord.fromMap(data, doc.id);
  }

  /// Create PatientRecord from a map
  factory PatientRecord.fromMap(Map<String, dynamic> data, [String? docId]) {
    return PatientRecord(
      id: docId ?? data['id'] ?? '',
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      email: data['email'],
      phone: data['phone'],
      dateOfBirth: data['dateOfBirth'],
      gender: data['gender'],
      bloodType: data['bloodType'],
      emergencyContact: data['emergencyContact'],
      emergencyContactPhone: data['emergencyContactPhone'],
      allergies: List<String>.from(data['allergies'] ?? []),
      chronicConditions: List<String>.from(data['chronicConditions'] ?? []),
      insuranceProvider: data['insuranceProvider'],
      insurancePolicyNumber: data['insurancePolicyNumber'],
      primaryDoctorId: data['primaryDoctorId'],
      primaryDoctorName: data['primaryDoctorName'],
      lastVisitDate: data['lastVisitDate'] is Timestamp
          ? (data['lastVisitDate'] as Timestamp).toDate()
          : null,
      nextAppointmentDate: data['nextAppointmentDate'] is Timestamp
          ? (data['nextAppointmentDate'] as Timestamp).toDate()
          : null,
      recordStatus: data['recordStatus'] ?? 'active',
      dataComplete: data['dataComplete'] ?? false,
      missingFields: List<String>.from(data['missingFields'] ?? []),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      archivedAt: data['archivedAt'] is Timestamp
          ? (data['archivedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert PatientRecord to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'email': email,
      'phone': phone,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'bloodType': bloodType,
      'emergencyContact': emergencyContact,
      'emergencyContactPhone': emergencyContactPhone,
      'allergies': allergies ?? [],
      'chronicConditions': chronicConditions ?? [],
      'insuranceProvider': insuranceProvider,
      'insurancePolicyNumber': insurancePolicyNumber,
      'primaryDoctorId': primaryDoctorId,
      'primaryDoctorName': primaryDoctorName,
      'lastVisitDate': lastVisitDate,
      'nextAppointmentDate': nextAppointmentDate,
      'recordStatus': recordStatus,
      'dataComplete': dataComplete,
      'missingFields': missingFields ?? [],
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'archivedAt': archivedAt,
    };
  }

  /// Create a copy with modifications
  PatientRecord copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? email,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? bloodType,
    String? emergencyContact,
    String? emergencyContactPhone,
    List<String>? allergies,
    List<String>? chronicConditions,
    String? insuranceProvider,
    String? insurancePolicyNumber,
    String? primaryDoctorId,
    String? primaryDoctorName,
    DateTime? lastVisitDate,
    DateTime? nextAppointmentDate,
    String? recordStatus,
    bool? dataComplete,
    List<String>? missingFields,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? archivedAt,
  }) {
    return PatientRecord(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodType: bloodType ?? this.bloodType,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      allergies: allergies ?? this.allergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      insuranceProvider: insuranceProvider ?? this.insuranceProvider,
      insurancePolicyNumber:
          insurancePolicyNumber ?? this.insurancePolicyNumber,
      primaryDoctorId: primaryDoctorId ?? this.primaryDoctorId,
      primaryDoctorName: primaryDoctorName ?? this.primaryDoctorName,
      lastVisitDate: lastVisitDate ?? this.lastVisitDate,
      nextAppointmentDate: nextAppointmentDate ?? this.nextAppointmentDate,
      recordStatus: recordStatus ?? this.recordStatus,
      dataComplete: dataComplete ?? this.dataComplete,
      missingFields: missingFields ?? this.missingFields,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }

  @override
  String toString() =>
      'PatientRecord(id: $id, patientId: $patientId, patientName: $patientName, recordStatus: $recordStatus)';
}

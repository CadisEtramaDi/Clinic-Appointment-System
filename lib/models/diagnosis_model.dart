import 'package:cloud_firestore/cloud_firestore.dart';

class DiagnosisModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String diagnosis;
  final String severity; // 'mild', 'moderate', 'severe'
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DiagnosisModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.diagnosis,
    required this.severity,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  /// Create DiagnosisModel from Firestore document
  factory DiagnosisModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DiagnosisModel.fromMap(data, doc.id);
  }

  /// Create DiagnosisModel from a map
  factory DiagnosisModel.fromMap(Map<String, dynamic> data, [String? docId]) {
    return DiagnosisModel(
      id: docId ?? data['id'] ?? '',
      patientId: data['patientId'] ?? '',
      doctorId: data['doctorId'] ?? '',
      diagnosis: data['diagnosis'] ?? '',
      severity: data['severity'] ?? 'moderate',
      notes: data['notes'],
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert DiagnosisModel to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'diagnosis': diagnosis,
      'severity': severity,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Create a copy with modifications
  DiagnosisModel copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? diagnosis,
    String? severity,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiagnosisModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      diagnosis: diagnosis ?? this.diagnosis,
      severity: severity ?? this.severity,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'DiagnosisModel(id: $id, diagnosis: $diagnosis, severity: $severity)';
}

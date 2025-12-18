import 'package:cloud_firestore/cloud_firestore.dart';

class PrescriptionModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String medicationName;
  final String dosage;
  final String frequency;
  final int duration; // in days
  final String? instructions;
  final bool hasSig; // Has e-signature
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PrescriptionModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.instructions,
    this.hasSig = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Create PrescriptionModel from Firestore document
  factory PrescriptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PrescriptionModel.fromMap(data, doc.id);
  }

  /// Create PrescriptionModel from a map
  factory PrescriptionModel.fromMap(
    Map<String, dynamic> data, [
    String? docId,
  ]) {
    return PrescriptionModel(
      id: docId ?? data['id'] ?? '',
      patientId: data['patientId'] ?? '',
      doctorId: data['doctorId'] ?? '',
      medicationName: data['medicationName'] ?? '',
      dosage: data['dosage'] ?? '',
      frequency: data['frequency'] ?? '',
      duration: data['duration'] ?? 0,
      instructions: data['instructions'],
      hasSig: data['hasSig'] ?? false,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert PrescriptionModel to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'medicationName': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
      'hasSig': hasSig,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Create a copy with modifications
  PrescriptionModel copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? medicationName,
    String? dosage,
    String? frequency,
    int? duration,
    String? instructions,
    bool? hasSig,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PrescriptionModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      instructions: instructions ?? this.instructions,
      hasSig: hasSig ?? this.hasSig,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'PrescriptionModel(id: $id, medicationName: $medicationName, dosage: $dosage)';
}

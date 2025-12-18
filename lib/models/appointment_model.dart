import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime appointmentDate;
  final String timeSlot;
  final String reason;
  final String status; // 'scheduled', 'completed', 'cancelled'
  final String? patientName;
  final String? doctorName;
  final String? additionalNotes;
  final int? queueNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.appointmentDate,
    required this.timeSlot,
    required this.reason,
    required this.status,
    this.patientName,
    this.doctorName,
    this.additionalNotes,
    this.queueNumber,
    this.createdAt,
    this.updatedAt,
  });

  /// Create AppointmentModel from Firestore document
  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppointmentModel.fromMap(data, doc.id);
  }

  /// Create AppointmentModel from a map
  factory AppointmentModel.fromMap(Map<String, dynamic> data, [String? docId]) {
    final appointmentDateField = data['appointmentDate'];
    DateTime appointmentDate = DateTime.now();

    if (appointmentDateField is Timestamp) {
      appointmentDate = appointmentDateField.toDate();
    } else if (appointmentDateField is DateTime) {
      appointmentDate = appointmentDateField;
    }

    return AppointmentModel(
      id: docId ?? data['id'] ?? '',
      patientId: data['patientId'] ?? '',
      doctorId: data['doctorId'] ?? '',
      appointmentDate: appointmentDate,
      timeSlot: data['timeSlot'] ?? '',
      reason: data['reason'] ?? '',
      status: data['status'] ?? 'scheduled',
      patientName: data['patientName'],
      doctorName: data['doctorName'],
      additionalNotes: data['additionalNotes'],
      queueNumber: data['queueNumber'] as int?,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert AppointmentModel to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'appointmentDate': appointmentDate,
      'timeSlot': timeSlot,
      'reason': reason,
      'status': status,
      'patientName': patientName,
      'doctorName': doctorName,
      'additionalNotes': additionalNotes,
      'queueNumber': queueNumber,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Create a copy with modifications
  AppointmentModel copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    DateTime? appointmentDate,
    String? timeSlot,
    String? reason,
    String? status,
    String? patientName,
    String? doctorName,
    String? additionalNotes,
    int? queueNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      timeSlot: timeSlot ?? this.timeSlot,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      patientName: patientName ?? this.patientName,
      doctorName: doctorName ?? this.doctorName,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      queueNumber: queueNumber ?? this.queueNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if appointment is in the future
  bool get isUpcoming => appointmentDate.isAfter(DateTime.now());

  /// Check if appointment is in the past
  bool get isPast => appointmentDate.isBefore(DateTime.now());

  @override
  String toString() =>
      'AppointmentModel(id: $id, patientId: $patientId, doctorId: $doctorId, appointmentDate: $appointmentDate)';
}

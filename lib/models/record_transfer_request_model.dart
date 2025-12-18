import 'package:cloud_firestore/cloud_firestore.dart';

class RecordTransferRequest {
  final String id;
  final String patientId;
  final String patientName;
  final String fromDoctorId;
  final String fromDoctorName;
  final String toDoctorId;
  final String toDoctorName;
  final String reason;
  final String status; // 'pending', 'approved', 'rejected', 'completed'
  final DateTime? requestDate;
  final DateTime? completedDate;
  final String? approvalNotes;
  final String? rejectionReason;

  RecordTransferRequest({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.fromDoctorId,
    required this.fromDoctorName,
    required this.toDoctorId,
    required this.toDoctorName,
    required this.reason,
    required this.status,
    this.requestDate,
    this.completedDate,
    this.approvalNotes,
    this.rejectionReason,
  });

  /// Create RecordTransferRequest from Firestore document
  factory RecordTransferRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecordTransferRequest.fromMap(data, doc.id);
  }

  /// Create RecordTransferRequest from a map
  factory RecordTransferRequest.fromMap(
    Map<String, dynamic> data, [
    String? docId,
  ]) {
    return RecordTransferRequest(
      id: docId ?? data['id'] ?? '',
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      fromDoctorId: data['fromDoctorId'] ?? '',
      fromDoctorName: data['fromDoctorName'] ?? '',
      toDoctorId: data['toDoctorId'] ?? '',
      toDoctorName: data['toDoctorName'] ?? '',
      reason: data['reason'] ?? '',
      status: data['status'] ?? 'pending',
      requestDate: data['requestDate'] is Timestamp
          ? (data['requestDate'] as Timestamp).toDate()
          : null,
      completedDate: data['completedDate'] is Timestamp
          ? (data['completedDate'] as Timestamp).toDate()
          : null,
      approvalNotes: data['approvalNotes'],
      rejectionReason: data['rejectionReason'],
    );
  }

  /// Convert RecordTransferRequest to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'fromDoctorId': fromDoctorId,
      'fromDoctorName': fromDoctorName,
      'toDoctorId': toDoctorId,
      'toDoctorName': toDoctorName,
      'reason': reason,
      'status': status,
      'requestDate': requestDate,
      'completedDate': completedDate,
      'approvalNotes': approvalNotes,
      'rejectionReason': rejectionReason,
    };
  }

  /// Create a copy with modifications
  RecordTransferRequest copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? fromDoctorId,
    String? fromDoctorName,
    String? toDoctorId,
    String? toDoctorName,
    String? reason,
    String? status,
    DateTime? requestDate,
    DateTime? completedDate,
    String? approvalNotes,
    String? rejectionReason,
  }) {
    return RecordTransferRequest(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      fromDoctorId: fromDoctorId ?? this.fromDoctorId,
      fromDoctorName: fromDoctorName ?? this.fromDoctorName,
      toDoctorId: toDoctorId ?? this.toDoctorId,
      toDoctorName: toDoctorName ?? this.toDoctorName,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      requestDate: requestDate ?? this.requestDate,
      completedDate: completedDate ?? this.completedDate,
      approvalNotes: approvalNotes ?? this.approvalNotes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  @override
  String toString() =>
      'RecordTransferRequest(id: $id, patientId: $patientId, status: $status)';
}

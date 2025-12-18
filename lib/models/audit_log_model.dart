import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLog {
  final String id;
  final String adminId;
  final String adminName;
  final String action; // 'view', 'edit', 'delete', 'archive', 'export', etc.
  final String targetPatientId;
  final String targetPatientName;
  final String? description;
  final Map<String, dynamic>? changes; // Track what was changed
  final String ipAddress;
  final DateTime timestamp;
  final String status; // 'success', 'failure'
  final String? errorMessage;

  AuditLog({
    required this.id,
    required this.adminId,
    required this.adminName,
    required this.action,
    required this.targetPatientId,
    required this.targetPatientName,
    this.description,
    this.changes,
    required this.ipAddress,
    required this.timestamp,
    required this.status,
    this.errorMessage,
  });

  /// Create AuditLog from Firestore document
  factory AuditLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuditLog.fromMap(data, doc.id);
  }

  /// Create AuditLog from a map
  factory AuditLog.fromMap(Map<String, dynamic> data, [String? docId]) {
    return AuditLog(
      id: docId ?? data['id'] ?? '',
      adminId: data['adminId'] ?? '',
      adminName: data['adminName'] ?? '',
      action: data['action'] ?? '',
      targetPatientId: data['targetPatientId'] ?? '',
      targetPatientName: data['targetPatientName'] ?? '',
      description: data['description'],
      changes: data['changes'],
      ipAddress: data['ipAddress'] ?? '',
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      status: data['status'] ?? 'success',
      errorMessage: data['errorMessage'],
    );
  }

  /// Convert AuditLog to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'adminId': adminId,
      'adminName': adminName,
      'action': action,
      'targetPatientId': targetPatientId,
      'targetPatientName': targetPatientName,
      'description': description,
      'changes': changes,
      'ipAddress': ipAddress,
      'timestamp': timestamp,
      'status': status,
      'errorMessage': errorMessage,
    };
  }

  /// Create a copy with modifications
  AuditLog copyWith({
    String? id,
    String? adminId,
    String? adminName,
    String? action,
    String? targetPatientId,
    String? targetPatientName,
    String? description,
    Map<String, dynamic>? changes,
    String? ipAddress,
    DateTime? timestamp,
    String? status,
    String? errorMessage,
  }) {
    return AuditLog(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      adminName: adminName ?? this.adminName,
      action: action ?? this.action,
      targetPatientId: targetPatientId ?? this.targetPatientId,
      targetPatientName: targetPatientName ?? this.targetPatientName,
      description: description ?? this.description,
      changes: changes ?? this.changes,
      ipAddress: ipAddress ?? this.ipAddress,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() =>
      'AuditLog(id: $id, action: $action, adminId: $adminId, timestamp: $timestamp)';
}

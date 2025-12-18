import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clinic/models/patient_record_model.dart';
import 'package:clinic/models/record_transfer_request_model.dart';
import 'package:clinic/models/audit_log_model.dart';

class PatientRecordManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<PatientRecord>> getAllPatientRecords({
    String? recordStatus,
    bool? dataComplete,
    String? searchQuery,
  }) async {
    try {
      Query query = _firestore.collection('patient_records');

      if (recordStatus != null) {
        query = query.where('recordStatus', isEqualTo: recordStatus);
      }

      if (dataComplete != null) {
        query = query.where('dataComplete', isEqualTo: dataComplete);
      }

      // Fetch without orderBy to avoid composite index requirement
      final snapshot = await query.get();

      var records = snapshot.docs
          .map((doc) => PatientRecord.fromFirestore(doc))
          .toList();

      // Sort in memory by patient name
      records.sort((a, b) => a.patientName.compareTo(b.patientName));

      // Apply search filter if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        records = records
            .where(
              (record) =>
                  record.patientName.toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  ) ||
                  record.email?.toLowerCase().contains(
                        searchQuery.toLowerCase(),
                      ) ==
                      true ||
                  record.phone?.contains(searchQuery) == true,
            )
            .toList();
      }

      return records;
    } catch (e) {
      throw Exception('Error fetching patient records: $e');
    }
  }

  /// Get a single patient record by ID
  Future<PatientRecord?> getPatientRecord(String patientId) async {
    try {
      final doc = await _firestore
          .collection('patient_records')
          .doc(patientId)
          .get();
      if (doc.exists) {
        return PatientRecord.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching patient record: $e');
    }
  }

  /// Create or update a patient record
  Future<String> savePatientRecord(PatientRecord record) async {
    try {
      final recordData = record.toMap();
      recordData['updatedAt'] = FieldValue.serverTimestamp();

      if (record.id.isEmpty) {
        // Creating new record
        recordData['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await _firestore
            .collection('patient_records')
            .add(recordData);
        return docRef.id;
      } else {
        // Updating existing record
        await _firestore
            .collection('patient_records')
            .doc(record.id)
            .set(recordData, SetOptions(merge: true));
        return record.id;
      }
    } catch (e) {
      throw Exception('Error saving patient record: $e');
    }
  }

  // ==================== DATA VALIDATION & COMPLETENESS ====================

  /// Check data completeness for a patient record
  List<String> validateRecordCompleteness(PatientRecord record) {
    final missingFields = <String>[];

    if (record.email == null || record.email!.isEmpty) {
      missingFields.add('Email');
    }
    if (record.phone == null || record.phone!.isEmpty) {
      missingFields.add('Phone Number');
    }
    if (record.dateOfBirth == null || record.dateOfBirth!.isEmpty) {
      missingFields.add('Date of Birth');
    }
    if (record.gender == null || record.gender!.isEmpty) {
      missingFields.add('Gender');
    }
    if (record.bloodType == null || record.bloodType!.isEmpty) {
      missingFields.add('Blood Type');
    }
    if (record.emergencyContact == null || record.emergencyContact!.isEmpty) {
      missingFields.add('Emergency Contact');
    }
    if (record.emergencyContactPhone == null ||
        record.emergencyContactPhone!.isEmpty) {
      missingFields.add('Emergency Contact Phone');
    }
    if (record.primaryDoctorId == null || record.primaryDoctorId!.isEmpty) {
      missingFields.add('Primary Doctor');
    }

    return missingFields;
  }

  /// Update record with validation and completeness check
  Future<void> updatePatientRecordWithValidation(
    PatientRecord record,
    String adminId,
    String adminName,
  ) async {
    try {
      final missingFields = validateRecordCompleteness(record);
      final updatedRecord = record.copyWith(
        dataComplete: missingFields.isEmpty,
        missingFields: missingFields,
        updatedAt: DateTime.now(),
      );

      await savePatientRecord(updatedRecord);

      // Log the update
      await logAuditAction(
        adminId: adminId,
        adminName: adminName,
        action: 'update',
        targetPatientId: record.patientId,
        targetPatientName: record.patientName,
        description:
            'Updated patient record${missingFields.isEmpty ? ' - Data complete' : ' - Missing fields: ${missingFields.join(', ')}'}',
      );
    } catch (e) {
      throw Exception('Error updating patient record with validation: $e');
    }
  }

  // ==================== RECORD REQUESTS & TRANSFERS ====================

  /// Create a record transfer request
  Future<String> createRecordTransferRequest(
    RecordTransferRequest request,
    String adminId,
    String adminName,
  ) async {
    try {
      final requestData = request.toMap();
      requestData['requestDate'] = FieldValue.serverTimestamp();

      final docRef = await _firestore
          .collection('record_transfer_requests')
          .add(requestData);

      // Log the action
      await logAuditAction(
        adminId: adminId,
        adminName: adminName,
        action: 'create_transfer_request',
        targetPatientId: request.patientId,
        targetPatientName: request.patientName,
        description:
            'Created transfer request from ${request.fromDoctorName} to ${request.toDoctorName}',
      );

      return docRef.id;
    } catch (e) {
      throw Exception('Error creating record transfer request: $e');
    }
  }

  /// Get all transfer requests with optional filtering
  Future<List<RecordTransferRequest>> getRecordTransferRequests({
    String? status,
    String? patientId,
  }) async {
    try {
      Query query = _firestore.collection('record_transfer_requests');

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }
      if (patientId != null) {
        query = query.where('patientId', isEqualTo: patientId);
      }

      final snapshot = await query
          .orderBy('requestDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => RecordTransferRequest.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error fetching transfer requests: $e');
    }
  }

  /// Approve a transfer request
  Future<void> approveTransferRequest(
    String requestId,
    String adminId,
    String adminName,
    String? approvalNotes,
  ) async {
    try {
      final requestDoc = await _firestore
          .collection('record_transfer_requests')
          .doc(requestId)
          .get();
      final request = RecordTransferRequest.fromFirestore(requestDoc);

      await _firestore
          .collection('record_transfer_requests')
          .doc(requestId)
          .update({
            'status': 'approved',
            'completedDate': FieldValue.serverTimestamp(),
            'approvalNotes': approvalNotes,
          });

      // Log the action
      await logAuditAction(
        adminId: adminId,
        adminName: adminName,
        action: 'approve_transfer_request',
        targetPatientId: request.patientId,
        targetPatientName: request.patientName,
        description:
            'Approved transfer request from ${request.fromDoctorName} to ${request.toDoctorName}',
      );
    } catch (e) {
      throw Exception('Error approving transfer request: $e');
    }
  }

  /// Reject a transfer request
  Future<void> rejectTransferRequest(
    String requestId,
    String adminId,
    String adminName,
    String rejectionReason,
  ) async {
    try {
      final requestDoc = await _firestore
          .collection('record_transfer_requests')
          .doc(requestId)
          .get();
      final request = RecordTransferRequest.fromFirestore(requestDoc);

      await _firestore
          .collection('record_transfer_requests')
          .doc(requestId)
          .update({'status': 'rejected', 'rejectionReason': rejectionReason});

      // Log the action
      await logAuditAction(
        adminId: adminId,
        adminName: adminName,
        action: 'reject_transfer_request',
        targetPatientId: request.patientId,
        targetPatientName: request.patientName,
        description: 'Rejected transfer request - Reason: $rejectionReason',
      );
    } catch (e) {
      throw Exception('Error rejecting transfer request: $e');
    }
  }

  // ==================== ARCHIVAL & RETENTION ====================

  /// Archive a patient record
  Future<void> archivePatientRecord(
    String patientId,
    String adminId,
    String adminName,
    String reason,
  ) async {
    try {
      final archivedRecord = (await getPatientRecord(patientId))?.copyWith(
        recordStatus: 'archived',
        archivedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (archivedRecord != null) {
        await savePatientRecord(archivedRecord);

        // Log the action
        await logAuditAction(
          adminId: adminId,
          adminName: adminName,
          action: 'archive',
          targetPatientId: patientId,
          targetPatientName: archivedRecord.patientName,
          description: 'Archived patient record - Reason: $reason',
        );
      }
    } catch (e) {
      throw Exception('Error archiving patient record: $e');
    }
  }

  /// Get archived records
  Future<List<PatientRecord>> getArchivedRecords() async {
    return getAllPatientRecords(recordStatus: 'archived');
  }

  /// Restore an archived record
  Future<void> restoreArchivedRecord(
    String patientId,
    String adminId,
    String adminName,
  ) async {
    try {
      final restoredRecord = (await getPatientRecord(patientId))?.copyWith(
        recordStatus: 'active',
        archivedAt: null,
        updatedAt: DateTime.now(),
      );

      if (restoredRecord != null) {
        await savePatientRecord(restoredRecord);

        // Log the action
        await logAuditAction(
          adminId: adminId,
          adminName: adminName,
          action: 'restore',
          targetPatientId: patientId,
          targetPatientName: restoredRecord.patientName,
          description: 'Restored archived patient record',
        );
      }
    } catch (e) {
      throw Exception('Error restoring archived record: $e');
    }
  }

  // ==================== AUDIT TRAIL ====================

  /// Log an admin action for audit trail
  Future<void> logAuditAction({
    required String adminId,
    required String adminName,
    required String action,
    required String targetPatientId,
    required String targetPatientName,
    String? description,
    Map<String, dynamic>? changes,
    String ipAddress = '0.0.0.0', // Would be actual IP in production
  }) async {
    try {
      final auditLog = AuditLog(
        id: '', // Firestore will generate
        adminId: adminId,
        adminName: adminName,
        action: action,
        targetPatientId: targetPatientId,
        targetPatientName: targetPatientName,
        description: description,
        changes: changes,
        ipAddress: ipAddress,
        timestamp: DateTime.now(),
        status: 'success',
      );

      final logData = auditLog.toMap();
      logData['timestamp'] = FieldValue.serverTimestamp();

      await _firestore.collection('audit_logs').add(logData);
    } catch (e) {
      print('Error logging audit action: $e');
      // Don't throw here to prevent audit failures from breaking operations
    }
  }

  /// Get audit logs with filtering
  Future<List<AuditLog>> getAuditLogs({
    String? adminId,
    String? targetPatientId,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore
          .collection('audit_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (adminId != null) {
        query = query.where('adminId', isEqualTo: adminId);
      }
      if (targetPatientId != null) {
        query = query.where('targetPatientId', isEqualTo: targetPatientId);
      }
      if (action != null) {
        query = query.where('action', isEqualTo: action);
      }

      final snapshot = await query.get();
      var logs = snapshot.docs
          .map((doc) => AuditLog.fromFirestore(doc))
          .toList();

      // Apply date filtering if needed
      if (startDate != null) {
        logs = logs.where((log) => log.timestamp.isAfter(startDate)).toList();
      }
      if (endDate != null) {
        logs = logs.where((log) => log.timestamp.isBefore(endDate)).toList();
      }

      return logs;
    } catch (e) {
      throw Exception('Error fetching audit logs: $e');
    }
  }

  /// Get audit logs for a specific patient
  Future<List<AuditLog>> getPatientAuditTrail(String patientId) async {
    return getAuditLogs(targetPatientId: patientId, limit: 50);
  }

  // ==================== REPORTS & ANALYTICS ====================

  /// Generate data quality report
  Future<Map<String, dynamic>> generateDataQualityReport() async {
    try {
      // Get all patients from users collection
      final patientsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'patient')
          .get();

      int totalRecords = patientsSnapshot.docs.length;
      int completeRecords = 0;

      // Calculate missing fields frequency
      final missingFieldsFrequency = <String, int>{};

      for (var doc in patientsSnapshot.docs) {
        final data = doc.data();
        final missingFields = <String>[];

        // Check for missing essential fields
        if (data['email'] == null || data['email'].toString().isEmpty) {
          missingFields.add('Email');
        }
        if (data['phone'] == null || data['phone'].toString().isEmpty) {
          missingFields.add('Phone');
        }
        if (data['birthdate'] == null) {
          missingFields.add('Date of Birth');
        }
        if (data['gender'] == null || data['gender'].toString().isEmpty) {
          missingFields.add('Gender');
        }
        if (data['address'] == null || data['address'].toString().isEmpty) {
          missingFields.add('Address');
        }

        // If no missing fields, record is complete
        if (missingFields.isEmpty) {
          completeRecords++;
        } else {
          // Count frequency of missing fields
          for (var field in missingFields) {
            missingFieldsFrequency[field] =
                (missingFieldsFrequency[field] ?? 0) + 1;
          }
        }
      }

      int incompleteRecords = totalRecords - completeRecords;

      return {
        'totalRecords': totalRecords,
        'completeRecords': completeRecords,
        'completePercentage': totalRecords > 0
            ? ((completeRecords / totalRecords) * 100).toStringAsFixed(2)
            : '0.00',
        'incompleteRecords': incompleteRecords,
        'missingFieldsFrequency': missingFieldsFrequency,
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Error generating data quality report: $e');
    }
  }

  // ==================== DASHBOARD METRICS ====================

  /// Fetch key dashboard metrics (users, appointments, patient records).
  /// Uses Firestore count() aggregation where available.
  Future<Map<String, int>> getDashboardMetrics() async {
    try {
      final usersCountFuture = _firestore.collection('users').count().get();
      final appointmentsCountFuture = _firestore
          .collection('appointments')
          .count()
          .get();
      final patientRecordsCountFuture = _firestore
          .collection('patient_records')
          .count()
          .get();

      final results = await Future.wait([
        usersCountFuture,
        appointmentsCountFuture,
        patientRecordsCountFuture,
      ]);

      return {
        'users': results[0].count ?? 0,
        'appointments': results[1].count ?? 0,
        'patientRecords': results[2].count ?? 0,
      };
    } catch (e) {
      throw Exception('Error fetching dashboard metrics: $e');
    }
  }

  /// Generate activity report for a date range
  Future<Map<String, dynamic>> generateActivityReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Get appointments within date range
      final appointmentsSnapshot = await _firestore
          .collection('appointments')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      // Get diagnoses within date range
      final diagnosesSnapshot = await _firestore
          .collection('diagnoses')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      // Count action types
      int totalAppointments = appointmentsSnapshot.docs.length;
      int totalDiagnoses = diagnosesSnapshot.docs.length;

      // Count appointments by status
      final appointmentStatusCounts = <String, int>{};
      for (var doc in appointmentsSnapshot.docs) {
        final status = doc.data()['status'] ?? 'unknown';
        appointmentStatusCounts[status] =
            (appointmentStatusCounts[status] ?? 0) + 1;
      }

      return {
        'totalActions': totalAppointments + totalDiagnoses,
        'totalAppointments': totalAppointments,
        'totalDiagnoses': totalDiagnoses,
        'appointmentStatusBreakdown': appointmentStatusCounts,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      // Fallback to simpler query if composite index not available
      try {
        final appointmentsSnapshot = await _firestore
            .collection('appointments')
            .get();

        final diagnosesSnapshot = await _firestore
            .collection('diagnoses')
            .get();

        // Filter by date in memory
        final appointmentsInRange = appointmentsSnapshot.docs.where((doc) {
          final createdAt = doc.data()['createdAt'] as Timestamp?;
          if (createdAt == null) return false;
          final date = createdAt.toDate();
          return date.isAfter(startDate) && date.isBefore(endDate);
        }).toList();

        final diagnosesInRange = diagnosesSnapshot.docs.where((doc) {
          final createdAt = doc.data()['createdAt'] as Timestamp?;
          if (createdAt == null) return false;
          final date = createdAt.toDate();
          return date.isAfter(startDate) && date.isBefore(endDate);
        }).toList();

        // Count appointments by status
        final appointmentStatusCounts = <String, int>{};
        for (var doc in appointmentsInRange) {
          final status = doc.data()['status'] ?? 'unknown';
          appointmentStatusCounts[status] =
              (appointmentStatusCounts[status] ?? 0) + 1;
        }

        return {
          'totalActions': appointmentsInRange.length + diagnosesInRange.length,
          'totalAppointments': appointmentsInRange.length,
          'totalDiagnoses': diagnosesInRange.length,
          'appointmentStatusBreakdown': appointmentStatusCounts,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'generatedAt': DateTime.now().toIso8601String(),
        };
      } catch (fallbackError) {
        throw Exception('Error generating activity report: $fallbackError');
      }
    }
  }

  /// Get patients requiring data completion
  Future<List<PatientRecord>> getPatientsRequiringCompletion() async {
    return getAllPatientRecords(dataComplete: false);
  }

  /// Get recently updated records
  Future<List<PatientRecord>> getRecentlyUpdatedRecords({
    int daysBack = 7,
  }) async {
    try {
      final allRecords = await getAllPatientRecords();
      final cutoffDate = DateTime.now().subtract(Duration(days: daysBack));

      return allRecords
          .where(
            (record) =>
                record.updatedAt != null &&
                record.updatedAt!.isAfter(cutoffDate),
          )
          .toList()
        ..sort((a, b) => b.updatedAt!.compareTo(a.updatedAt!));
    } catch (e) {
      throw Exception('Error fetching recently updated records: $e');
    }
  }
}

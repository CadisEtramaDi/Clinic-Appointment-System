import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  // Create a new transaction
  Future<String> createTransaction({
    required String patientId,
    required String patientName,
    String? doctorId,
    String? doctorName,
    String? appointmentId,
    required double amount,
    required String type,
    required String paymentMethod,
    required String description,
  }) async {
    try {
      final docRef = await _firestore.collection('transactions').add({
        'patientId': patientId,
        'patientName': patientName,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'appointmentId': appointmentId,
        'amount': amount,
        'type': type,
        'status': 'pending',
        'paymentMethod': paymentMethod,
        'description': description,
        'transactionDate': FieldValue.serverTimestamp(),
        'paidDate': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Error creating transaction: $e');
    }
  }

  // Mark transaction as paid
  Future<void> markAsPaid(String transactionId) async {
    try {
      await _firestore.collection('transactions').doc(transactionId).update({
        'status': 'paid',
        'paidDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error marking transaction as paid: $e');
    }
  }

  // Cancel transaction
  Future<void> cancelTransaction(String transactionId) async {
    try {
      await _firestore.collection('transactions').doc(transactionId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error cancelling transaction: $e');
    }
  }

  // Update transaction status
  Future<void> updateTransactionStatus(
    String transactionId,
    String status,
  ) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == 'paid') {
        updateData['paidDate'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection('transactions')
          .doc(transactionId)
          .update(updateData);
    } catch (e) {
      throw Exception('Error updating transaction status: $e');
    }
  }

  // Get patient transactions
  Stream<QuerySnapshot> getPatientTransactions(String patientId) {
    return _firestore
        .collection('transactions')
        .where('patientId', isEqualTo: patientId)
        .snapshots();
  }

  // Get doctor transactions
  Stream<QuerySnapshot> getDoctorTransactions(String doctorId) {
    return _firestore
        .collection('transactions')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots();
  }

  // Get all transactions (admin)
  Stream<QuerySnapshot> getAllTransactions() {
    return _firestore
        .collection('transactions')
        .orderBy('transactionDate', descending: true)
        .snapshots();
  }

  // Get transaction statistics
  Future<Map<String, dynamic>> getTransactionStats({
    String? patientId,
    String? doctorId,
  }) async {
    try {
      Query query = _firestore.collection('transactions');

      if (patientId != null) {
        query = query.where('patientId', isEqualTo: patientId);
      } else if (doctorId != null) {
        query = query.where('doctorId', isEqualTo: doctorId);
      }

      final snapshot = await query.get();

      double totalAmount = 0;
      double paidAmount = 0;
      double pendingAmount = 0;
      int totalTransactions = snapshot.docs.length;
      int paidCount = 0;
      int pendingCount = 0;

      final pendingStatuses = {
        'pending',
        'pending_cash',
        'pending_verification',
      };

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final amount = (data['amount'] ?? 0).toDouble();
        final status = data['status'] ?? 'pending';

        totalAmount += amount;

        if (status == 'paid') {
          paidAmount += amount;
          paidCount++;
        } else if (pendingStatuses.contains(status)) {
          pendingAmount += amount;
          pendingCount++;
        }
      }

      return {
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'pendingAmount': pendingAmount,
        'totalTransactions': totalTransactions,
        'paidCount': paidCount,
        'pendingCount': pendingCount,
      };
    } catch (e) {
      throw Exception('Error getting transaction stats: $e');
    }
  }

  // Delete transaction
  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _firestore.collection('transactions').doc(transactionId).delete();
    } catch (e) {
      throw Exception('Error deleting transaction: $e');
    }
  }

  // Get transactions by status
  Stream<QuerySnapshot> getTransactionsByStatus(String status) {
    // Fetch by status; sort on client to avoid composite index requirement
    return _firestore
        .collection('transactions')
        .where('status', isEqualTo: status)
        .snapshots();
  }

  // Get all pending-like transactions (including cash/gcash verification)
  Stream<QuerySnapshot> getPendingReviewTransactions() {
    return _firestore
        .collection('transactions')
        .where(
          'status',
          whereIn: ['pending', 'pending_cash', 'pending_verification'],
        )
        .snapshots();
  }

  // Get transactions for a specific appointment
  Future<List<Map<String, dynamic>>> getAppointmentTransactions(
    String appointmentId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('appointmentId', isEqualTo: appointmentId)
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      throw Exception('Error getting appointment transactions: $e');
    }
  }

  // Cleanup consultation transactions created at booking time.
  // Keeps one per completed appointment (prefer paid, else latest),
  // deletes all consultation bills for non-completed or unlinked appointments.
  Future<Map<String, int>> cleanupConsultationTransactions() async {
    final snap = await _firestore
        .collection('transactions')
        .where('type', isEqualTo: 'consultation')
        .get();

    final docs = snap.docs;
    final Map<String?, List<QueryDocumentSnapshot>> groups = {};
    for (final d in docs) {
      final data = d.data();
      final apptId = (data['appointmentId'] as String?)?.trim();
      groups.putIfAbsent(apptId, () => []).add(d);
    }

    // Fetch appointment docs for valid ids
    final apptIds = groups.keys
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toList();
    final Map<String, DocumentSnapshot> apptDocs = {};
    await Future.wait(
      apptIds.map((id) async {
        final d = await _firestore.collection('appointments').doc(id).get();
        apptDocs[id] = d;
      }),
    );

    final List<DocumentReference> toDelete = [];
    int kept = 0;

    DateTime extractDate(Map<String, dynamic> m, List<String> keys) {
      for (final k in keys) {
        final v = m[k];
        if (v is Timestamp) return v.toDate();
        if (v is DateTime) return v;
      }
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    for (final entry in groups.entries) {
      final apptId = entry.key;
      final list = entry.value;

      if (apptId == null || apptId.isEmpty) {
        // Unlinked consultation bills should not exist
        toDelete.addAll(list.map((e) => e.reference));
        continue;
      }

      final adoc = apptDocs[apptId];
      final aData = adoc?.data() as Map<String, dynamic>?;
      final status = (aData?['status']?.toString().toLowerCase() ?? '');

      if (status != 'completed') {
        // No bill until diagnosis/completion
        toDelete.addAll(list.map((e) => e.reference));
        continue;
      }

      // Keep one: prefer a paid one (latest), else latest by createdAt/transactionDate
      QueryDocumentSnapshot? keep;
      int compare(QueryDocumentSnapshot a, QueryDocumentSnapshot b) {
        final ma = a.data() as Map<String, dynamic>;
        final mb = b.data() as Map<String, dynamic>;
        final da = extractDate(ma, [
          'paidDate',
          'createdAt',
          'transactionDate',
        ]);
        final db = extractDate(mb, [
          'paidDate',
          'createdAt',
          'transactionDate',
        ]);
        return da.compareTo(db);
      }

      final paid = list.where((d) {
        final m = d.data() as Map<String, dynamic>;
        return (m['status']?.toString().toLowerCase() ?? '') == 'paid';
      }).toList();

      if (paid.isNotEmpty) {
        paid.sort(compare);
        keep = paid.last; // latest paid
      } else {
        list.sort(compare);
        keep = list.last; // latest
      }

      kept += 1;
      for (final d in list) {
        if (d.id != keep.id) toDelete.add(d.reference);
      }
    }

    // Batch delete in chunks
    int deleted = 0;
    const chunkSize = 450; // below 500 write limit
    for (int i = 0; i < toDelete.length; i += chunkSize) {
      final batch = _firestore.batch();
      final chunk = toDelete.sublist(
        i,
        i + chunkSize > toDelete.length ? toDelete.length : i + chunkSize,
      );
      for (final ref in chunk) {
        batch.delete(ref);
      }
      await batch.commit();
      deleted += chunk.length;
    }

    return {
      'examined': docs.length,
      'deleted': deleted,
      'kept': kept,
      'groups': groups.length,
    };
  }
}

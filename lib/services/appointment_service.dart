import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Fetch booked time slots for a specific date and doctor
  Future<List<String>> fetchBookedTimeSlots(
    DateTime date, {
    String? doctorId,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      Query query = _firestore
          .collection('appointments')
          .where(
            'appointmentDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('appointmentDate', isLessThan: Timestamp.fromDate(endOfDay));

      // Filter by doctor if provided
      if (doctorId != null && doctorId.isNotEmpty) {
        query = query.where('doctorId', isEqualTo: doctorId);
      }

      final snapshot = await query.get();

      // Filter by status in memory to avoid complex index
      return snapshot.docs
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            final status = data?['status'] as String?;
            return status != null &&
                ['pending', 'upcoming', 'confirmed'].contains(status);
          })
          .map(
            (d) =>
                ((d.data() as Map<String, dynamic>?)?['timeSlot'] as String?) ??
                '',
          )
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e) {
      print('Error fetching booked slots: $e');
      return [];
    }
  }

  // Check if a time slot is available (per doctor when provided)
  Future<bool> isTimeSlotAvailable(
    DateTime date,
    String timeSlot, {
    String? doctorId,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      Query query = _firestore
          .collection('appointments')
          .where(
            'appointmentDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('appointmentDate', isLessThan: Timestamp.fromDate(endOfDay))
          .where('timeSlot', isEqualTo: timeSlot)
          .where('status', whereIn: ['pending', 'upcoming', 'confirmed']);

      // Always check doctor-specific availability
      if (doctorId != null && doctorId.isNotEmpty) {
        query = query.where('doctorId', isEqualTo: doctorId);
      }

      final existing = await query.limit(1).get();
      return existing.docs.isEmpty;
    } catch (e) {
      print('Error checking slot availability: $e');
      return false; // Safer to block booking on error
    }
  }

  // Book a new appointment
  Future<Map<String, dynamic>> bookAppointment({
    required DateTime date,
    required String timeSlot,
    required String reason,
    String? additionalNotes,
    required String doctorId,
    required String doctorName,
    String? patientName,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'Please log in to book an appointment',
        };
      }

      // Check availability first - simplified query to avoid index requirements
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final existingQuery = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where(
            'appointmentDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('appointmentDate', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      // Filter in memory for the specific time slot and status
      final hasConflict = existingQuery.docs.any((doc) {
        final data = doc.data();
        return data['timeSlot'] == timeSlot &&
            ['pending', 'upcoming', 'confirmed'].contains(data['status']);
      });

      if (hasConflict) {
        return {
          'success': false,
          'message': 'This time slot is no longer available',
        };
      }

      // Calculate queue number for this time slot
      final queueNumber = await _getNextQueueNumber(
        doctorId: doctorId,
        date: date,
        timeSlot: timeSlot,
      );

      // Create appointment document
      final appointmentRef = _firestore.collection('appointments').doc();

      // Write appointment
      await appointmentRef.set({
        'userId': user.uid,
        'patientId': user.uid,
        'patientName': patientName ?? user.displayName ?? 'Patient',
        'doctorId': doctorId,
        'doctorName': doctorName,
        'appointmentDate': Timestamp.fromDate(date),
        'timeSlot': timeSlot,
        'reason': reason,
        'additionalNotes': additionalNotes?.trim() ?? '',
        'status': 'pending',
        'queueNumber': queueNumber,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message':
            'Appointment booked successfully! Queue number: $queueNumber',
        'appointmentId': appointmentRef.id,
      };
    } catch (e) {
      print('Error booking appointment: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Get next queue number for a specific time slot
  Future<int> _getNextQueueNumber({
    required String doctorId,
    required DateTime date,
    required String timeSlot,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where(
            'appointmentDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('appointmentDate', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      // Count ALL appointments for the day (not just same time slot)
      final allDayAppointments = snapshot.docs.where((doc) {
        final data = doc.data();
        return ['pending', 'upcoming', 'confirmed'].contains(data['status']);
      }).toList();

      // Return next queue number (current count + 1)
      return allDayAppointments.length + 1;
    } catch (e) {
      print('Error calculating queue number: $e');
      return 1; // Default to 1 if error
    }
  }

  // yyyyMMdd key for day partitioning
  String _dayKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  // Get appointments stream for current user (FIXED - no orderBy)
  Stream<QuerySnapshot> getAppointmentsStream({
    String? filterStatus,
    bool orderByRecent = true,
  }) {
    final user = currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    // Only query by patientId - sorting will be done in memory
    Query query = _firestore
        .collection('appointments')
        .where('patientId', isEqualTo: user.uid);

    return query.snapshots();
  }

  // Get appointments stream for current doctor
  Stream<QuerySnapshot> getDoctorAppointmentsStream(String doctorId) {
    return _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots();
  }

  // Get unique patients for a doctor
  Stream<QuerySnapshot> getDoctorPatients(String doctorId) {
    return _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots();
  }

  // Get upcoming appointments count
  Stream<int> getUpcomingAppointmentsCount() {
    final user = currentUser;
    if (user == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('appointments')
        .where('patientId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.where((doc) {
            final status = doc.data()['status'];
            return status == 'pending' || status == 'upcoming';
          }).length;
        });
  }

  // Get appointment statistics
  Stream<Map<String, int>> getAppointmentStats() {
    final user = currentUser;
    if (user == null) {
      return Stream.value({'total': 0, 'completed': 0, 'upcoming': 0});
    }

    return _firestore
        .collection('appointments')
        .where('patientId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs;
          final total = docs.length;
          final completed = docs
              .where((doc) => doc.data()['status'] == 'completed')
              .length;
          final upcoming = docs.where((doc) {
            final status = doc.data()['status'];
            return status == 'pending' || status == 'upcoming';
          }).length;

          return {'total': total, 'completed': completed, 'upcoming': upcoming};
        });
  }

  // Cancel an appointment
  Future<Map<String, dynamic>> cancelAppointment(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'Appointment cancelled successfully'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Error cancelling appointment: ${e.toString()}',
      };
    }
  }

  // Update appointment status
  Future<void> updateAppointmentStatus(
    String appointmentId,
    String status,
  ) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating appointment status: $e');
    }
  }

  // Get user data stream
  Stream<DocumentSnapshot> getUserDataStream() {
    final user = currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore.collection('users').doc(user.uid).snapshots();
  }

  // Check if date is in the past
  bool isPastDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);
    return checkDate.isBefore(today);
  }

  // Check if date is today
  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Clear all data except user accounts
  Future<void> clearAllDataExceptUsers() async {
    try {
      // Delete all appointments
      final appointments = await _firestore.collection('appointments').get();
      for (var doc in appointments.docs) {
        await doc.reference.delete();
      }

      // Delete all patient records and their subcollections
      final patients = await _firestore.collection('patients').get();
      for (var patientDoc in patients.docs) {
        // Delete diagnoses
        final diagnoses = await patientDoc.reference
            .collection('diagnoses')
            .get();
        for (var diagDoc in diagnoses.docs) {
          await diagDoc.reference.delete();
        }

        // Delete prescriptions
        final prescriptions = await patientDoc.reference
            .collection('prescriptions')
            .get();
        for (var prescDoc in prescriptions.docs) {
          await prescDoc.reference.delete();
        }

        // Delete the patient document itself
        await patientDoc.reference.delete();
      }

      // Delete all doctor records (but keep user accounts via Auth)
      final doctors = await _firestore.collection('doctors').get();
      for (var doc in doctors.docs) {
        await doc.reference.delete();
      }

      // Delete all admin records (but keep user accounts via Auth)
      final admins = await _firestore.collection('admins').get();
      for (var doc in admins.docs) {
        await doc.reference.delete();
      }

      // Delete all notifications
      final notifications = await _firestore.collection('notifications').get();
      for (var doc in notifications.docs) {
        await doc.reference.delete();
      }

      print('All data cleared successfully except user accounts');
    } catch (e) {
      print('Error clearing data: $e');
      rethrow;
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Fetch booked time slots for a specific date
  Future<List<String>> fetchBookedTimeSlots(DateTime date) async {
    try {
      final user = currentUser;
      if (user == null) return [];

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('appointments')
          .where(
            'appointmentDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where(
            'appointmentDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
          )
          .get();

      final bookedSlots = snapshot.docs
          .where((doc) {
            final status = doc.data()['status'];
            return status == 'pending' || status == 'upcoming';
          })
          .map((doc) => doc.data()['timeSlot'] as String)
          .toList();

      return bookedSlots;
    } catch (e) {
      return [];
    }
  }

  // Check if a time slot is available
  Future<bool> isTimeSlotAvailable(DateTime date, String timeSlot) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('appointments')
          .where(
            'appointmentDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where(
            'appointmentDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
          )
          .get();

      final hasConflict = snapshot.docs.any((doc) {
        final data = doc.data();
        final status = data['status'];
        final slot = data['timeSlot'];
        return slot == timeSlot &&
            (status == 'pending' || status == 'upcoming');
      });

      return !hasConflict;
    } catch (e) {
      return false;
    }
  }

  // Book a new appointment
  Future<Map<String, dynamic>> bookAppointment({
    required DateTime date,
    required String timeSlot,
    required String reason,
    String? additionalNotes,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'Please log in to book an appointment',
        };
      }

      final isAvailable = await isTimeSlotAvailable(date, timeSlot);
      if (!isAvailable) {
        return {
          'success': false,
          'message': 'This time slot is no longer available',
        };
      }

      final appointmentData = {
        'userId': user.uid,
        'appointmentDate': Timestamp.fromDate(date),
        'timeSlot': timeSlot,
        'reason': reason,
        'additionalNotes': additionalNotes?.trim() ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('appointments').add(appointmentData);

      return {'success': true, 'message': 'Appointment booked successfully!'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
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

    // Only query by userId - sorting will be done in memory
    Query query = _firestore
        .collection('appointments')
        .where('userId', isEqualTo: user.uid);

    return query.snapshots();
  }

  // Get upcoming appointments count
  Stream<int> getUpcomingAppointmentsCount() {
    final user = currentUser;
    if (user == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('appointments')
        .where('userId', isEqualTo: user.uid)
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
        .where('userId', isEqualTo: user.uid)
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
}

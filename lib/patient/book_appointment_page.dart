import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/appointment_service.dart';

class BookAppointmentPage extends StatefulWidget {
  const BookAppointmentPage({super.key});

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  final AppointmentService _appointmentService = AppointmentService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  String? _selectedReason;
  String? _selectedDoctorId;
  String? _selectedDoctorName;
  String? _patientName;
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = false;
  List<String> _bookedTimeSlots = [];

  final List<String> _timeSlots = [
    '8:00 AM - 9:00 AM',
    '9:00 AM - 10:00 AM',
    '10:00 AM - 11:00 AM',
    '11:00 AM - 12:00 PM',
    '1:00 PM - 2:00 PM',
    '2:00 PM - 3:00 PM',
    '3:00 PM - 4:00 PM',
    '4:00 PM - 5:00 PM',
  ];

  final List<String> _reasons = [
    'General Checkup',
    'Follow-up Consultation',
    'Dental Care',
    'Vaccination',
    'Lab Tests',
    'Other',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadPatientName();
    _initializeDefaultDate();
    _assignDefaultDoctor();
  }

  Future<void> _initializeDefaultDate() async {
    final today = DateTime.now();
    await _onDateSelected(DateTime(today.year, today.month, today.day));
  }

  Future<void> _assignDefaultDoctor() async {
    // Query for any doctor from Firestore with proper permissions
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', whereIn: ['doctor', 'Doctor'])
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doctorDoc = snapshot.docs.first;
        final doctorData = doctorDoc.data();
        setState(() {
          // Always use document ID as it matches Firebase Auth UID
          _selectedDoctorId = doctorDoc.id;
          _selectedDoctorName =
              doctorData['fullName'] ?? doctorData['name'] ?? 'Doctor';
        });
        print('=== DOCTOR ASSIGNMENT ===');
        print('Assigned Doctor ID: $_selectedDoctorId');
        print('Assigned Doctor Name: $_selectedDoctorName');
        print('Doctor Doc ID: ${doctorDoc.id}');
        print('Doctor UID from data: ${doctorData['uid']}');
        print('========================');
      } else {
        // Fallback - use a placeholder that at least shows in logs
        setState(() {
          _selectedDoctorId = 'no-doctor-available';
          _selectedDoctorName = 'Unassigned';
        });
        print('WARNING: No doctors found in database!');
      }
    } catch (e) {
      // If permissions fail, use placeholder
      setState(() {
        _selectedDoctorId = 'pending-assignment';
        _selectedDoctorName = 'Pending Assignment';
      });
      print('ERROR assigning doctor: $e');
    }
  }

  Future<void> _loadPatientName() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _patientName = data['fullName'] ?? data['name'];
        });
      }
    } catch (_) {}
  }

  // Fetch booked time slots when date is selected
  Future<void> _onDateSelected(DateTime date) async {
    setState(() {
      _selectedDate = date;
      _selectedTimeSlot = null; // Reset time slot
      _bookedTimeSlots = []; // Clear previous data
    });

    // Fetch booked slots from Firebase
    final bookedSlots = await _appointmentService.fetchBookedTimeSlots(
      date,
      doctorId: _selectedDoctorId,
    );
    setState(() {
      _bookedTimeSlots = bookedSlots;
    });
  }

  // Book appointment handler
  Future<void> _bookAppointment() async {
    if (_selectedDate == null ||
        _selectedTimeSlot == null ||
        _selectedReason == null) {
      _showSnackBar('Please fill in all required fields', isError: true);
      return;
    }

    if (_selectedDoctorId == null || _selectedDoctorName == null) {
      _showSnackBar(
        'System error: doctor assignment failed. Please try again.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _appointmentService.bookAppointment(
      date: _selectedDate!,
      timeSlot: _selectedTimeSlot!,
      reason: _selectedReason!,
      additionalNotes: _notesController.text,
      doctorId: _selectedDoctorId!,
      doctorName: _selectedDoctorName!,
      patientName: _patientName,
    );

    // Billing will be created after the doctor saves the diagnosis

    setState(() => _isLoading = false);

    if (mounted) {
      _showSnackBar(result['message'], isError: !result['success']);

      if (result['success']) {
        Navigator.pop(context);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Select Date'),
            const SizedBox(height: 16),
            _buildCalendarSection(),

            const SizedBox(height: 32),
            _buildSectionTitle('Select Time Slot'),
            const SizedBox(height: 16),
            _buildTimeSlotSection(),

            const SizedBox(height: 32),
            _buildSectionTitle('Reason for Visit'),
            const SizedBox(height: 16),
            _buildReasonSection(),

            const SizedBox(height: 32),
            _buildSectionTitle('Additional Notes (Optional)'),
            const SizedBox(height: 16),
            _buildNotesSection(),

            const SizedBox(height: 40),
            _buildBookButton(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1976D2), Color(0xFF2196F3), Color(0xFF64B5F6)],
          ),
        ),
      ),
      title: const Text(
        'Book Appointment',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1565C0),
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: CalendarDatePicker(
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 90)),
        onDateChanged: (date) {
          // Only allow selection if not a past date
          if (!_appointmentService.isPastDate(date)) {
            _onDateSelected(date);
          }
        },
        selectableDayPredicate: (date) {
          // Disable past dates completely
          return !_appointmentService.isPastDate(date);
        },
      ),
    );
  }

  Widget _buildTimeSlotSection() {
    if (_selectedDate == null) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.access_time, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Please select a date first',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    // Get current time plus 15 minutes buffer
    final now = DateTime.now();
    final bufferTime = now.add(const Duration(minutes: 15));
    final isToday =
        _selectedDate != null &&
        _selectedDate!.year == now.year &&
        _selectedDate!.month == now.month &&
        _selectedDate!.day == now.day;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _timeSlots.map((slot) {
        final isBooked = _bookedTimeSlots.contains(slot);
        final isSelected = _selectedTimeSlot == slot;

        // Check if slot is in the past (for today only)
        bool isPastSlot = false;
        if (isToday) {
          // Parse the start time from slot (e.g., "8:00 AM" from "8:00 AM - 9:00 AM")
          final startTimeStr = slot.split(' - ')[0];
          final slotDateTime = _parseTimeSlot(startTimeStr, _selectedDate!);
          isPastSlot = slotDateTime.isBefore(bufferTime);
        }

        final isDisabled = isBooked || isPastSlot;

        return GestureDetector(
          onTap: isDisabled
              ? null
              : () {
                  setState(() => _selectedTimeSlot = slot);
                },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFF1976D2), Color(0xFF2196F3)],
                    )
                  : null,
              color: isDisabled
                  ? Colors.grey.shade200
                  : (isSelected ? null : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDisabled
                    ? Colors.grey.shade300
                    : (isSelected ? Colors.transparent : Colors.grey.shade200),
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF2196F3).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDisabled ? Icons.lock : Icons.access_time,
                  size: 16,
                  color: isDisabled
                      ? Colors.grey.shade400
                      : (isSelected ? Colors.white : Colors.grey.shade600),
                ),
                const SizedBox(width: 8),
                Text(
                  slot,
                  style: TextStyle(
                    color: isBooked
                        ? Colors.grey.shade400
                        : (isSelected ? Colors.white : Colors.grey.shade700),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                    decoration: isBooked ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReasonSection() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _reasons.map((reason) {
        final isSelected = _selectedReason == reason;

        return GestureDetector(
          onTap: () {
            setState(() => _selectedReason = reason);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFF1976D2), Color(0xFF2196F3)],
                    )
                  : null,
              color: isSelected ? null : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.transparent : Colors.grey.shade200,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF2196F3).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Text(
              reason,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _notesController,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: 'Enter any additional information...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  // Helper method to parse time slot string into DateTime
  DateTime _parseTimeSlot(String timeStr, DateTime date) {
    // Remove whitespace and convert to uppercase
    timeStr = timeStr.trim().toUpperCase();

    // Parse hour and minute
    final parts = timeStr.split(':');
    if (parts.length != 2) return date;

    int hour = int.tryParse(parts[0]) ?? 0;
    final minuteParts = parts[1].split(' ');
    final minute = int.tryParse(minuteParts[0]) ?? 0;
    final period = minuteParts.length > 1 ? minuteParts[1] : '';

    // Convert to 24-hour format
    if (period == 'PM' && hour != 12) {
      hour += 12;
    } else if (period == 'AM' && hour == 12) {
      hour = 0;
    }

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  Widget _buildBookButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _bookAppointment,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1976D2),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Book Appointment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

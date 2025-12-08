import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/appointment_service.dart';

class BookAppointmentPage extends StatefulWidget {
  const BookAppointmentPage({Key? key}) : super(key: key);

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  final AppointmentService _appointmentService = AppointmentService();

  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  String? _selectedReason;
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

  // Fetch booked time slots when date is selected
  Future<void> _onDateSelected(DateTime date) async {
    setState(() {
      _selectedDate = date;
      _selectedTimeSlot = null; // Reset time slot
      _bookedTimeSlots = []; // Clear previous data
    });

    // Fetch booked slots from Firebase
    final bookedSlots = await _appointmentService.fetchBookedTimeSlots(date);
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

    setState(() => _isLoading = true);

    final result = await _appointmentService.bookAppointment(
      date: _selectedDate!,
      timeSlot: _selectedTimeSlot!,
      reason: _selectedReason!,
      additionalNotes: _notesController.text,
    );

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

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _timeSlots.map((slot) {
        final isBooked = _bookedTimeSlots.contains(slot);
        final isSelected = _selectedTimeSlot == slot;

        return GestureDetector(
          onTap: isBooked
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
              color: isBooked
                  ? Colors.grey.shade200
                  : (isSelected ? null : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isBooked
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
                  isBooked ? Icons.lock : Icons.access_time,
                  size: 16,
                  color: isBooked
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

import 'package:clinic/doctor/appointment_list_page.dart';
import 'package:clinic/doctor/doctor_dashboard_page.dart';
import 'package:clinic/doctor/patient_history_page.dart';
import 'package:clinic/models/appointment_model.dart';
import 'package:clinic/services/appointment_service.dart';
import 'package:clinic/services/medical_records_service.dart';
import 'package:clinic/services/transaction_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UpdateDiagnosisPage extends StatefulWidget {
  const UpdateDiagnosisPage({super.key});
  @override
  State<UpdateDiagnosisPage> createState() => _UpdateDiagnosisPageState();
}

class _UpdateDiagnosisPageState extends State<UpdateDiagnosisPage> {
  bool _followUpRequired = false;
  int _currentIndex = 1; // Start at Diagnosis tab (index 1)
  bool _hasLoadedInitialData = false; // Flag to prevent reload on every rebuild
  String _severity = 'moderate';
  bool _isSaving = false;

  late final AppointmentService _appointmentService;
  late final MedicalRecordsService _medicalRecordsService;
  late final TransactionService _transactionService;
  late final FirebaseAuth _auth;

  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _icdCodeController = TextEditingController();
  final TextEditingController _treatmentPlanController =
      TextEditingController();
  final TextEditingController _vitalsController = TextEditingController();
  final TextEditingController _prescriptionController = TextEditingController();

  final Color _primaryColor = const Color(0xFF2D5AEE);
  final Color _backgroundColor = const Color(0xFFF8FAFC);
  final Color _cardColor = Colors.white;
  final Color _textPrimary = const Color(0xFF1E293B);
  final Color _textSecondary = const Color(0xFF64748B);
  final Color _successColor = const Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _appointmentService = AppointmentService();
    _transactionService = TransactionService();
    _medicalRecordsService = MedicalRecordsService();
    _auth = FirebaseAuth.instance;
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _notesController.dispose();
    _symptomsController.dispose();
    _allergiesController.dispose();
    _icdCodeController.dispose();
    _treatmentPlanController.dispose();
    _vitalsController.dispose();
    _prescriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveDiagnosis(AppointmentModel appointment) async {
    print('\n🔵 _saveDiagnosis called');

    if (_diagnosisController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a diagnosis')));
      return;
    }

    print('🔵 Setting isSaving to true');
    setState(() => _isSaving = true);

    try {
      // Save comprehensive diagnosis to Firestore
      await _medicalRecordsService.addDiagnosis(
        patientId: appointment.patientId,
        diagnosis: _diagnosisController.text.trim(),
        notes: _notesController.text.trim(),
        severity: _severity,
        medications: const [],
        followUpRequired: _followUpRequired,
        symptoms: _symptomsController.text.trim(),
        allergies: _allergiesController.text.trim(),
        icdCode: _icdCodeController.text.trim(),
        treatmentPlan: _treatmentPlanController.text.trim(),
        vitals: _vitalsController.text.trim(),
        prescription: _prescriptionController.text.trim(),
      );

      // Ensure a consultation transaction exists for this appointment
      print('\n=== BILL CREATION START ===');
      print('Appointment ID: ${appointment.id}');
      print('Patient ID: ${appointment.patientId}');
      print('Doctor ID: ${_auth.currentUser?.uid}');

      try {
        final existing = await _transactionService.getAppointmentTransactions(
          appointment.id,
        );
        print('Existing transactions: ${existing.length}');

        final hasConsultation = existing.any(
          (t) => (t['type'] as String?)?.toLowerCase() == 'consultation',
        );
        print('Has consultation already: $hasConsultation');

        if (!hasConsultation) {
          print('Creating consultation bill...');
          final txId = await _transactionService.createTransaction(
            patientId: appointment.patientId,
            patientName: appointment.patientName ?? 'Patient',
            doctorId: _auth.currentUser?.uid,
            doctorName: appointment.doctorName ?? 'Doctor',
            appointmentId: appointment.id,
            amount: 500.0, // Default consultation fee
            type: 'consultation',
            paymentMethod: 'cash',
            description: 'Consultation - ${appointment.reason}',
          );
          print('✅ Bill created with ID: $txId');
          print('=== BILL CREATION SUCCESS ===\n');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Bill created: $txId'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          print('ℹ️ Bill already exists, skipping creation');
        }
      } catch (e, stackTrace) {
        // Do not block saving diagnosis if billing creation fails
        print('❌ Error ensuring consultation transaction: $e');
        print('Stack trace: $stackTrace');
        print('=== BILL CREATION FAILED ===\n');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Bill failed: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }

      // If prescription is provided, create a medication transaction
      if (_prescriptionController.text.trim().isNotEmpty) {
        // Create medication transaction
        try {
          await _transactionService.createTransaction(
            patientId: appointment.patientId,
            patientName: appointment.patientName ?? 'Patient',
            doctorId: _auth.currentUser?.uid,
            doctorName: 'Doctor',
            appointmentId: appointment.id,
            amount: 300.0, // Default medication fee
            type: 'medication',
            paymentMethod: 'cash',
            description:
                'Medication - ${_prescriptionController.text.trim().substring(0, _prescriptionController.text.trim().length > 50 ? 50 : _prescriptionController.text.trim().length)}',
          );
        } catch (e) {
          print('Error creating medication transaction: $e');
        }
      }

      // Update appointment status
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointment.id)
          .update({
            'status': 'completed',
            'diagnosis': _diagnosisController.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Diagnosis saved successfully!'),
            backgroundColor: _successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        // Don't pop, stay on page to allow updates
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving diagnosis: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return; // Don't navigate if already on this tab

    setState(() {
      _currentIndex = index;
    });

    // Handle navigation
    if (index == 0) {
      // Navigate to Home (DoctorDashboardPage)
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const DoctorDashboardPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      );
    } else if (index == 2) {
      // Navigate to Patient History page
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const PatientHistoryPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      );
    } else if (index == 3) {
      // Navigate to Appointments page
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AppointmentsListPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      );
    }
    // For index 1 (Diagnosis tab), we're already on this page, so no navigation needed
  }

  @override
  Widget build(BuildContext context) {
    final doctorId = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: doctorId == null
          ? const Center(child: Text('Please sign in to view diagnoses'))
          : StreamBuilder<QuerySnapshot>(
              stream: _appointmentService.getDoctorAppointmentsStream(doctorId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading appointments: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.medical_information_outlined,
                            color: _textSecondary,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No appointments to update yet',
                            style: TextStyle(
                              color: _textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Book or accept an appointment to start updating diagnoses.',
                            style: TextStyle(color: _textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final appointments =
                    docs
                        .map((doc) => AppointmentModel.fromFirestore(doc))
                        .where((appt) {
                          final status = appt.status.toLowerCase();
                          return status == 'pending' ||
                              status == 'upcoming' ||
                              status == 'scheduled' ||
                              status == 'confirmed' ||
                              status == 'accepted';
                        })
                        .toList()
                      ..sort(
                        (a, b) =>
                            a.appointmentDate.compareTo(b.appointmentDate),
                      );

                if (appointments.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event_available,
                            color: _textSecondary,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No upcoming appointments need diagnosis',
                            style: TextStyle(
                              color: _textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Completed or cancelled visits are hidden here.',
                            style: TextStyle(color: _textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      backgroundColor: _cardColor,
                      elevation: 0,
                      pinned: true,
                      automaticallyImplyLeading: true,
                      leading: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.arrow_back, color: _textPrimary),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      title: Text(
                        'Diagnosis',
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      centerTitle: true,
                      actions: [
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _backgroundColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.more_vert, color: _textPrimary),
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final appointment = appointments[index];
                          return Column(
                            children: [
                              _buildAppointmentCard(appointment),
                              if (index < appointments.length - 1)
                                const SizedBox(height: 16),
                            ],
                          );
                        }, childCount: appointments.length),
                      ),
                    ),
                  ],
                );
              },
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: _primaryColor,
          unselectedItemColor: _textSecondary,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _currentIndex == 0
                      ? _primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                ),
                child: Icon(Icons.home_outlined, size: 22),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _primaryColor.withOpacity(0.1),
                ),
                child: Icon(Icons.home_filled, size: 22, color: _primaryColor),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _currentIndex == 1
                      ? _primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                ),
                child: Icon(Icons.medical_information_outlined, size: 22),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _primaryColor.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.medical_information,
                  size: 22,
                  color: _primaryColor,
                ),
              ),
              label: 'Diagnosis',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _currentIndex == 2
                      ? _primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                ),
                child: Icon(Icons.history_outlined, size: 22),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _primaryColor.withOpacity(0.1),
                ),
                child: Icon(Icons.history, size: 22, color: _primaryColor),
              ),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _currentIndex == 3
                      ? _primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                ),
                child: Icon(Icons.calendar_today_outlined, size: 22),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _primaryColor.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.calendar_today,
                  size: 22,
                  color: _primaryColor,
                ),
              ),
              label: 'Schedule',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UpdateDiagnosisDetailPage(
              appointment: appointment,
              isUpdate: false,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.person, size: 32, color: _primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.patientName ?? 'Patient',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appointment.reason,
                        style: TextStyle(fontSize: 14, color: _textSecondary),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UpdateDiagnosisDetailPage(
                          appointment: appointment,
                          isUpdate: false,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Diagnosis'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: _primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(appointment.appointmentDate),
                        style: TextStyle(
                          fontSize: 13,
                          color: _primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: _successColor),
                      const SizedBox(width: 6),
                      Text(
                        appointment.timeSlot,
                        style: TextStyle(
                          fontSize: 13,
                          color: _successColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (appointment.queueNumber != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.numbers,
                          size: 14,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Q${appointment.queueNumber}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContent(AppointmentModel appointment) {
    return [
      // Patient Header Card
      Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.person, size: 32, color: _primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.patientName ?? 'Patient',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: _primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(appointment.appointmentDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: _primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _successColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: _successColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(appointment.timeSlot),
                              style: TextStyle(
                                fontSize: 12,
                                color: _successColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Comprehensive Clinical Diagnosis Form
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('patients')
            .doc(appointment.patientId)
            .collection('diagnoses')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          // Load existing diagnosis data into controllers (only once)
          if (snapshot.hasData &&
              snapshot.data!.docs.isNotEmpty &&
              !_hasLoadedInitialData) {
            final latest =
                snapshot.data!.docs.first.data() as Map<String, dynamic>;

            // Load all data synchronously without setState to prevent blinking
            if (_diagnosisController.text.isEmpty) {
              _diagnosisController.text = latest['diagnosis'] as String? ?? '';
            }
            if (_notesController.text.isEmpty) {
              _notesController.text = latest['notes'] as String? ?? '';
            }
            if (_symptomsController.text.isEmpty) {
              _symptomsController.text = latest['symptoms'] as String? ?? '';
            }
            if (_allergiesController.text.isEmpty) {
              _allergiesController.text = latest['allergies'] as String? ?? '';
            }
            if (_icdCodeController.text.isEmpty) {
              _icdCodeController.text = latest['icdCode'] as String? ?? '';
            }
            if (_treatmentPlanController.text.isEmpty) {
              _treatmentPlanController.text =
                  latest['treatmentPlan'] as String? ?? '';
            }
            if (_vitalsController.text.isEmpty) {
              _vitalsController.text = latest['vitals'] as String? ?? '';
            }
            if (_prescriptionController.text.isEmpty) {
              _prescriptionController.text =
                  latest['prescription'] as String? ?? '';
            }
            if (latest['severity'] != null) {
              _severity = latest['severity'] as String;
            }
            if (latest['followUpRequired'] != null) {
              _followUpRequired = latest['followUpRequired'] as bool;
            }

            // Mark as loaded so we don't reload on every rebuild
            _hasLoadedInitialData = true;
          }

          return Column(
            children: [
              // Appointment Information
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      icon: Icons.info_outline,
                      title: 'Appointment Information',
                      color: _primaryColor,
                    ),
                    const SizedBox(height: 20),
                    _buildInfoSection(
                      title: 'Reason for Visit',
                      content: appointment.reason.isNotEmpty
                          ? appointment.reason
                          : 'No reason provided',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoSection(
                      title: 'Additional Notes',
                      content: (appointment.additionalNotes ?? '').isNotEmpty
                          ? appointment.additionalNotes!
                          : 'No notes captured yet.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Vitals Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      icon: Icons.favorite_border,
                      title: 'Vital Signs',
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _vitalsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'Blood Pressure, Temperature, Heart Rate, Weight, etc.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: _backgroundColor,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: TextStyle(fontSize: 14, color: _textPrimary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Symptoms Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      icon: Icons.local_hospital,
                      title: 'Symptoms',
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _symptomsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Describe patient symptoms...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: _backgroundColor,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: TextStyle(fontSize: 14, color: _textPrimary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Allergies Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      icon: Icons.warning_amber,
                      title: 'Allergies',
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _allergiesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'List any known allergies...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: _backgroundColor,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: TextStyle(fontSize: 14, color: _textPrimary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Diagnosis & ICD Code
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      icon: Icons.healing,
                      title: 'Diagnosis',
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _diagnosisController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter diagnosis...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: _backgroundColor,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: TextStyle(fontSize: 14, color: _textPrimary),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _icdCodeController,
                      decoration: InputDecoration(
                        labelText: 'ICD-10 Code',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: _backgroundColor,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: TextStyle(fontSize: 14, color: _textPrimary),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _severity,
                      decoration: InputDecoration(
                        labelText: 'Severity',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: _backgroundColor,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'mild', child: Text('Mild')),
                        DropdownMenuItem(
                          value: 'moderate',
                          child: Text('Moderate'),
                        ),
                        DropdownMenuItem(
                          value: 'severe',
                          child: Text('Severe'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _severity = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Additional clinical notes...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: _backgroundColor,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: TextStyle(fontSize: 14, color: _textPrimary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Treatment Plan
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      icon: Icons.assignment,
                      title: 'Treatment Plan',
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _treatmentPlanController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                            'Medications, procedures, therapy recommendations, lifestyle changes...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: _backgroundColor,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: TextStyle(fontSize: 14, color: _textPrimary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Prescription
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      icon: Icons.medication,
                      title: 'Prescription',
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _prescriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                            'Medication name, dosage, frequency, duration, special instructions...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: _backgroundColor,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: TextStyle(fontSize: 14, color: _textPrimary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Follow-up Section (StatefulBuilder to prevent full page rebuild)
              StatefulBuilder(
                builder: (context, setFollowUpState) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          icon: Icons.calendar_today,
                          title: 'Follow-up Required',
                          color: _primaryColor,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFollowUpOption(
                                isSelected: _followUpRequired,
                                label: 'Yes',
                                onTap: () {
                                  setFollowUpState(() {
                                    _followUpRequired = true;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildFollowUpOption(
                                isSelected: !_followUpRequired,
                                label: 'No',
                                onTap: () {
                                  setFollowUpState(() {
                                    _followUpRequired = false;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: _textSecondary.withOpacity(0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            color: _textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving
                            ? null
                            : () => _saveDiagnosis(appointment),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Save Diagnosis',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 80),
            ],
          );
        },
      ),
    ];
  }

  String _formatDate(DateTime date) {
    return '${_monthName(date.month)} ${date.day}, ${date.year}';
  }

  String _formatTime(String timeSlot) {
    if (timeSlot.isEmpty) return 'Time TBD';
    return timeSlot;
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[(month - 1).clamp(0, 11)];
  }

  Widget _buildInfoSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(fontSize: 14, color: _textSecondary, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildFollowUpOption({
    required bool isSelected,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor.withOpacity(0.1) : _backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _primaryColor : Colors.grey[400]!,
                  width: 2,
                ),
                color: isSelected ? _primaryColor : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? _primaryColor : _textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Separate page for diagnosis form
class UpdateDiagnosisDetailPage extends StatefulWidget {
  final AppointmentModel appointment;
  final bool isUpdate;

  const UpdateDiagnosisDetailPage({
    super.key,
    required this.appointment,
    this.isUpdate = false,
  });

  @override
  State<UpdateDiagnosisDetailPage> createState() =>
      _UpdateDiagnosisDetailPageState();
}

class _UpdateDiagnosisDetailPageState extends State<UpdateDiagnosisDetailPage> {
  bool _followUpRequired = false;
  bool _hasLoadedInitialData = false;

  late final MedicalRecordsService _medicalRecordsService;
  late final TransactionService _transactionService;
  late final FirebaseAuth _auth;

  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _icdCodeController = TextEditingController();
  final TextEditingController _treatmentPlanController =
      TextEditingController();
  final TextEditingController _vitalsController = TextEditingController();
  final TextEditingController _prescriptionController = TextEditingController();
  String _severity = 'moderate';

  // Colors
  Color get _backgroundColor => Colors.grey.shade50;
  Color get _cardColor => Colors.white;
  Color get _primaryColor => Colors.blue;
  Color get _textPrimary => Colors.grey.shade900;
  Color get _textSecondary => Colors.grey.shade600;
  Color get _successColor => Colors.green.shade600;

  @override
  void initState() {
    super.initState();
    _medicalRecordsService = MedicalRecordsService();
    _transactionService = TransactionService();
    _auth = FirebaseAuth.instance;
    _loadExistingDiagnosis();
  }

  Future<void> _loadExistingDiagnosis() async {
    try {
      // Check if appointment has diagnosis data
      final appointmentDoc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointment.id)
          .get();

      if (!appointmentDoc.exists) {
        print('Appointment document does not exist');
        return;
      }

      final data = appointmentDoc.data();
      if (data == null) {
        print('Appointment data is null');
        return;
      }

      print('Loading diagnosis data: ${data['diagnosis']}');

      // Pre-populate form if data exists
      if (mounted) {
        setState(() {
          _diagnosisController.text = data['diagnosis'] ?? '';
          _notesController.text = data['notes'] ?? '';
          _symptomsController.text = data['symptoms'] ?? '';
          _allergiesController.text = data['allergies'] ?? '';
          _icdCodeController.text = data['icdCode'] ?? '';
          _treatmentPlanController.text = data['treatmentPlan'] ?? '';
          _vitalsController.text = data['vitals'] ?? '';
          _prescriptionController.text = data['prescription'] ?? '';
          _severity = data['severity'] ?? 'moderate';
          _followUpRequired = data['followUpRequired'] ?? false;
          _hasLoadedInitialData = true;
        });
        print(
          'Diagnosis loaded successfully. Diagnosis text: ${_diagnosisController.text}',
        );
      }
    } catch (e) {
      print('Error loading diagnosis: $e');
    }
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _notesController.dispose();
    _symptomsController.dispose();
    _allergiesController.dispose();
    _icdCodeController.dispose();
    _treatmentPlanController.dispose();
    _vitalsController.dispose();
    _prescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isUpdate ? 'Update Diagnosis' : 'Add Diagnosis',
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: _textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Patient Header
                    _buildPatientHeader(),
                    const SizedBox(height: 20),
                    // Diagnosis Form
                    ..._buildDiagnosisForm(),
                  ],
                ),
              ),
            ),
            // Save button
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.person, size: 32, color: _primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.appointment.patientName ?? 'Patient',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.appointment.timeSlot,
                        style: TextStyle(
                          fontSize: 12,
                          color: _primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (widget.appointment.queueNumber != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Q${widget.appointment.queueNumber}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDiagnosisForm() {
    return [
      // Symptoms Section
      _buildSectionHeader('Patient Symptoms', Icons.sick),
      const SizedBox(height: 12),
      _buildTextField(
        controller: _symptomsController,
        label: 'Symptoms',
        hint: 'Enter patient symptoms (e.g., fever, cough, headache)',
        icon: Icons.sick,
        maxLines: 3,
      ),
      const SizedBox(height: 20),

      // Vitals Section
      _buildSectionHeader('Vital Signs', Icons.favorite),
      const SizedBox(height: 12),
      _buildTextField(
        controller: _vitalsController,
        label: 'Vital Signs',
        hint: 'BP: 120/80, Temp: 98.6°F, Pulse: 72, Resp: 16',
        icon: Icons.favorite,
        maxLines: 2,
      ),
      const SizedBox(height: 20),

      // Allergies Section
      _buildSectionHeader('Allergies & Medical History', Icons.warning),
      const SizedBox(height: 12),
      _buildTextField(
        controller: _allergiesController,
        label: 'Known Allergies',
        hint: 'Penicillin, Peanuts, etc.',
        icon: Icons.warning,
        maxLines: 2,
      ),
      const SizedBox(height: 20),

      // Diagnosis Section
      _buildSectionHeader('Diagnosis', Icons.medical_services),
      const SizedBox(height: 12),
      _buildTextField(
        controller: _diagnosisController,
        label: 'Primary Diagnosis',
        hint: 'Enter the primary diagnosis',
        icon: Icons.medical_services,
        maxLines: 3,
      ),
      const SizedBox(height: 12),
      _buildTextField(
        controller: _icdCodeController,
        label: 'ICD-10 Code (Optional)',
        hint: 'e.g., J00 (Acute nasopharyngitis)',
        icon: Icons.code,
        maxLines: 1,
      ),
      const SizedBox(height: 12),
      _buildSeveritySelector(),
      const SizedBox(height: 20),

      // Treatment Plan Section
      _buildSectionHeader('Treatment Plan', Icons.healing),
      const SizedBox(height: 12),
      _buildTextField(
        controller: _treatmentPlanController,
        label: 'Treatment Plan',
        hint: 'Describe the treatment approach',
        icon: Icons.healing,
        maxLines: 4,
      ),
      const SizedBox(height: 20),

      // Prescription Section
      _buildSectionHeader('Prescription', Icons.medication),
      const SizedBox(height: 12),
      _buildTextField(
        controller: _prescriptionController,
        label: 'Medications',
        hint: 'Medicine name, dosage, frequency, duration',
        icon: Icons.medication,
        maxLines: 4,
      ),
      const SizedBox(height: 20),

      // Additional Notes Section
      _buildSectionHeader('Additional Notes', Icons.note),
      const SizedBox(height: 12),
      _buildTextField(
        controller: _notesController,
        label: 'Doctor\'s Notes',
        hint: 'Any additional observations or recommendations',
        icon: Icons.note,
        maxLines: 3,
      ),
      const SizedBox(height: 16),

      // Follow-up Toggle
      _buildFollowUpToggle(),
      const SizedBox(height: 20),
    ];
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSeveritySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.priority_high, color: _textSecondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Severity Level',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildSeverityChip('mild', 'Mild', Colors.green),
              _buildSeverityChip('moderate', 'Moderate', Colors.orange),
              _buildSeverityChip('severe', 'Severe', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityChip(String value, String label, Color color) {
    final isSelected = _severity == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _severity = value;
        });
      },
      selectedColor: color.withOpacity(0.2),
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        color: isSelected ? color : _textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? color : Colors.grey.shade300,
        width: isSelected ? 2 : 1,
      ),
    );
  }

  Widget _buildFollowUpToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.event_repeat, color: _primaryColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Follow-up Required',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                Text(
                  'Schedule a follow-up appointment',
                  style: TextStyle(fontSize: 13, color: _textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: _followUpRequired,
            onChanged: (value) {
              setState(() {
                _followUpRequired = value;
              });
            },
            activeThumbColor: _primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: Icon(icon, color: _primaryColor),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _saveDiagnosis,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          widget.isUpdate ? 'Update Diagnosis' : 'Add Diagnosis',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _saveDiagnosis() async {
    print('\n🔵 DETAIL PAGE _saveDiagnosis called');

    if (_diagnosisController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a diagnosis')));
      return;
    }

    print('🔵 Starting diagnosis save in detail page');
    try {
      final diagnosisData = {
        'diagnosis': _diagnosisController.text.trim(),
        'notes': _notesController.text.trim(),
        'symptoms': _symptomsController.text.trim(),
        'vitals': _vitalsController.text.trim(),
        'allergies': _allergiesController.text.trim(),
        'icdCode': _icdCodeController.text.trim(),
        'treatmentPlan': _treatmentPlanController.text.trim(),
        'prescription': _prescriptionController.text.trim(),
        'severity': _severity,
        'followUpRequired': _followUpRequired,
      };

      print('Saving diagnosis data: $diagnosisData');
      print('Appointment ID: ${widget.appointment.id}');

      // Update appointment document with diagnosis data
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointment.id)
          .set({
            ...diagnosisData,
            'treatment': _treatmentPlanController.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      print('Diagnosis saved to appointment document');

      // Check if diagnosis already exists in diagnoses collection
      final diagnosesSnapshot = await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.appointment.patientId)
          .collection('diagnoses')
          .where('appointmentId', isEqualTo: widget.appointment.id)
          .limit(1)
          .get();

      if (diagnosesSnapshot.docs.isNotEmpty) {
        // Update existing diagnosis
        final diagnosisId = diagnosesSnapshot.docs.first.id;
        await _medicalRecordsService.updateDiagnosis(
          patientId: widget.appointment.patientId,
          diagnosisId: diagnosisId,
          diagnosis: _diagnosisController.text.trim(),
          notes: _notesController.text.trim(),
          severity: _severity,
          medications: const [],
          followUpRequired: _followUpRequired,
          symptoms: _symptomsController.text.trim(),
          vitals: _vitalsController.text.trim(),
          allergies: _allergiesController.text.trim(),
          icdCode: _icdCodeController.text.trim(),
          treatmentPlan: _treatmentPlanController.text.trim(),
          prescription: _prescriptionController.text.trim(),
        );
      } else {
        // Add new diagnosis with appointmentId reference
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(widget.appointment.patientId)
            .collection('diagnoses')
            .add({
              ...diagnosisData,
              'medications': [],
              'appointmentId': widget.appointment.id,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
              'status': 'active',
            });
      }

      // Update appointment status to completed
      await AppointmentService().updateAppointmentStatus(
        widget.appointment.id,
        'completed',
      );

      // Ensure a consultation transaction exists for this appointment
      print('\n=== DETAIL PAGE BILL CREATION START ===');
      print('Appointment ID: ${widget.appointment.id}');
      print('Patient ID: ${widget.appointment.patientId}');
      print('Doctor ID: ${_auth.currentUser?.uid}');

      try {
        final existing = await _transactionService.getAppointmentTransactions(
          widget.appointment.id,
        );
        print('Existing transactions: ${existing.length}');

        final hasConsultation = existing.any(
          (t) => (t['type'] as String?)?.toLowerCase() == 'consultation',
        );
        print('Has consultation already: $hasConsultation');

        if (!hasConsultation) {
          print('Creating consultation bill...');
          final txId = await _transactionService.createTransaction(
            patientId: widget.appointment.patientId,
            patientName: widget.appointment.patientName ?? 'Patient',
            doctorId: _auth.currentUser?.uid,
            doctorName: widget.appointment.doctorName ?? 'Doctor',
            appointmentId: widget.appointment.id,
            amount: 500.0,
            type: 'consultation',
            paymentMethod: 'cash',
            description: 'Consultation - ${widget.appointment.reason}',
          );
          print('✅ Bill created with ID: $txId');
          print('=== DETAIL PAGE BILL CREATION SUCCESS ===\n');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Bill created: $txId'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          print('ℹ️ Bill already exists, skipping creation');
        }
      } catch (e, stackTrace) {
        print('❌ Error creating bill: $e');
        print('Stack trace: $stackTrace');
        print('=== DETAIL PAGE BILL CREATION FAILED ===\n');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Bill failed: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isUpdate
                  ? 'Diagnosis updated successfully'
                  : 'Diagnosis added successfully',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving diagnosis: $e')));
    }
  }
}

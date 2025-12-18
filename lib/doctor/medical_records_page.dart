import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:clinic/models/appointment_model.dart';
import 'package:clinic/models/diagnosis_model.dart';
import 'package:clinic/models/prescription_model.dart';

class MedicalRecordsPage extends StatefulWidget {
  final String patientId;
  final String patientName;

  const MedicalRecordsPage({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<MedicalRecordsPage> createState() => _MedicalRecordsPageState();
}

class _MedicalRecordsPageState extends State<MedicalRecordsPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _doctorName =>
      _auth.currentUser?.displayName ??
      'Dr. ${_auth.currentUser?.email?.split('@').first ?? 'Doctor'}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Medical Records', style: TextStyle(fontSize: 18)),
            Text(
              widget.patientName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Appointments'),
            Tab(text: 'Diagnoses'),
            Tab(text: 'Prescriptions'),
            Tab(text: 'Doctor Notes'),
            Tab(text: 'Lab Orders'),
            Tab(text: 'Lab Results'),
            Tab(text: 'Images'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentsTab(),
          _buildDiagnosesTab(),
          _buildPrescriptionsTab(),
          _buildDoctorNotesTab(),
          _buildLabOrdersTab(),
          _buildLabResultsTab(),
          _buildMedicalImagesTab(),
        ],
      ),
    );
  }

  // ==================== APPOINTMENTS TAB ====================
  Widget _buildAppointmentsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: widget.patientId)
          .orderBy('appointmentDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No appointments booked');
        }

        // Convert to AppointmentModel and separate upcoming and past
        final now = DateTime.now();
        final allAppointments = snapshot.data!.docs
            .map((doc) => AppointmentModel.fromFirestore(doc))
            .toList();

        final upcomingAppointments = allAppointments
            .where((apt) => apt.appointmentDate.isAfter(now))
            .toList();
        final pastAppointments = allAppointments
            .where((apt) => !apt.appointmentDate.isAfter(now))
            .toList();

        // Sort upcoming by date ascending (nearest first)
        upcomingAppointments.sort(
          (a, b) => a.appointmentDate.compareTo(b.appointmentDate),
        );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Upcoming Appointments Section
            if (upcomingAppointments.isNotEmpty) ...[
              Text(
                'Upcoming Appointments',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 12),
              ...upcomingAppointments.map(
                (appointment) =>
                    _buildAppointmentCard(appointment, isUpcoming: true),
              ),
              const SizedBox(height: 24),
            ],

            // Past Appointments Section
            if (pastAppointments.isNotEmpty) ...[
              Text(
                'Past Appointments',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              ...pastAppointments.map(
                (appointment) =>
                    _buildAppointmentCard(appointment, isUpcoming: false),
              ),
            ],

            if (upcomingAppointments.isEmpty && pastAppointments.isEmpty)
              _buildEmptyState('No appointments found'),
          ],
        );
      },
    );
  }

  Widget _buildAppointmentCard(
    AppointmentModel appointment, {
    bool isUpcoming = true,
  }) {
    final formattedDate = DateFormat(
      'MMM dd, yyyy',
    ).format(appointment.appointmentDate);
    final time = appointment.timeSlot;
    final status = appointment.status;
    final reason = appointment.reason;
    final doctorName = appointment.doctorName ?? 'Not assigned';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isUpcoming ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isUpcoming
            ? BorderSide(color: Colors.blue.shade400, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isUpcoming)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.upcoming,
                      size: 20,
                      color: Colors.blue.shade600,
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isUpcoming
                        ? Colors.blue.shade100
                        : (status == 'confirmed'
                              ? Colors.green.shade100
                              : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isUpcoming ? 'UPCOMING' : status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isUpcoming
                          ? Colors.blue.shade800
                          : (status == 'confirmed'
                                ? Colors.green.shade800
                                : Colors.grey.shade700),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 18, color: Colors.teal.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    doctorName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reason:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(reason, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            if (appointment.additionalNotes != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appointment.additionalNotes ?? '',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==================== DIAGNOSES TAB ====================
  Widget _buildDiagnosesTab() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('patients')
                .doc(widget.patientId)
                .collection('diagnoses')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState('No diagnoses recorded');
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final diagnosis = DiagnosisModel.fromFirestore(
                    snapshot.data!.docs[index],
                  );
                  return _buildDiagnosisCard(diagnosis);
                },
              );
            },
          ),
        ),
        _buildAddButton('Add Diagnosis', () => _showAddDiagnosisDialog()),
      ],
    );
  }

  Widget _buildDiagnosisCard(DiagnosisModel diagnosis) {
    final date = diagnosis.createdAt;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    diagnosis.severity.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
                const Spacer(),
                if (date != null)
                  Text(
                    DateFormat('MMM dd, yyyy').format(date),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              diagnosis.diagnosis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (diagnosis.notes != null) ...[
              const SizedBox(height: 8),
              Text(
                diagnosis.notes ?? '',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddDiagnosisDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Diagnosis'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Diagnosis'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              await _firestore
                  .collection('patients')
                  .doc(widget.patientId)
                  .collection('diagnoses')
                  .add({
                    'diagnosis': controller.text,
                    'severity': 'moderate',
                    'createdAt': FieldValue.serverTimestamp(),
                    'doctorId': _auth.currentUser?.uid,
                    'doctorName': _doctorName,
                    'status': 'active',
                  });
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Diagnosis added')));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ==================== PRESCRIPTIONS TAB ====================
  Widget _buildPrescriptionsTab() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('patients')
                .doc(widget.patientId)
                .collection('prescriptions')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState('No prescriptions');
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final prescription = PrescriptionModel.fromFirestore(
                    snapshot.data!.docs[index],
                  );
                  return _buildPrescriptionCard(prescription);
                },
              );
            },
          ),
        ),
        _buildAddButton(
          'Generate Prescription',
          () => _showAddPrescriptionDialog(),
        ),
      ],
    );
  }

  Widget _buildPrescriptionCard(PrescriptionModel prescription) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medication, color: Colors.teal.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    prescription.medicationName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (prescription.hasSig)
                  Icon(Icons.verified, color: Colors.green),
              ],
            ),
            const SizedBox(height: 12),
            Text('Dosage: ${prescription.dosage}'),
            Text('Frequency: ${prescription.frequency}'),
            Text('Duration: ${prescription.duration} days'),
          ],
        ),
      ),
    );
  }

  void _showAddPrescriptionDialog() {
    final medController = TextEditingController();
    final dosageController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Prescription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: medController,
              decoration: const InputDecoration(labelText: 'Medication'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dosageController,
              decoration: const InputDecoration(labelText: 'Dosage'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (medController.text.isEmpty) return;
              await _firestore
                  .collection('patients')
                  .doc(widget.patientId)
                  .collection('prescriptions')
                  .add({
                    'medicationName': medController.text,
                    'dosage': dosageController.text,
                    'frequency': 'Twice daily',
                    'durationDays': 7,
                    'createdAt': FieldValue.serverTimestamp(),
                    'doctorId': _auth.currentUser?.uid,
                    'doctorName': _doctorName,
                    'eSignatureVerified': false,
                    'status': 'active',
                  });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Prescription generated')),
              );
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  // ==================== DOCTOR NOTES TAB ====================
  Widget _buildDoctorNotesTab() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('patients')
                .doc(widget.patientId)
                .collection('doctorNotes')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState('No doctor notes');
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final data =
                      snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  return _buildDoctorNoteCard(data);
                },
              );
            },
          ),
        ),
        _buildAddButton('Add Note', () => _showAddNoteDialog()),
      ],
    );
  }

  Widget _buildDoctorNoteCard(Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['doctorName'] ?? 'Doctor',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              data['notes'] ?? 'No notes',
              style: const TextStyle(fontSize: 14),
            ),
            if (data['followUpRequired'] == true) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Follow-up Required',
                  style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddNoteDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Doctor Note'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Clinical Notes'),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              await _firestore
                  .collection('patients')
                  .doc(widget.patientId)
                  .collection('doctorNotes')
                  .add({
                    'notes': controller.text,
                    'followUpRequired': false,
                    'createdAt': FieldValue.serverTimestamp(),
                    'doctorId': _auth.currentUser?.uid,
                    'doctorName': _doctorName,
                  });
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Note added')));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ==================== LAB ORDERS TAB ====================
  Widget _buildLabOrdersTab() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('patients')
                .doc(widget.patientId)
                .collection('labOrders')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState('No lab orders');
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final data =
                      snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  return _buildLabOrderCard(data);
                },
              );
            },
          ),
        ),
        _buildAddButton('Place Lab Order', () => _showAddLabOrderDialog()),
      ],
    );
  }

  Widget _buildLabOrderCard(Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    (data['status'] ?? 'pending').toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              data['testName'] ?? 'Lab Test',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text('Type: ${data['testType'] ?? '-'}'),
            Text('Priority: ${data['priority'] ?? 'normal'}'),
          ],
        ),
      ),
    );
  }

  void _showAddLabOrderDialog() {
    final testController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Place Lab Order'),
        content: TextField(
          controller: testController,
          decoration: const InputDecoration(labelText: 'Test Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (testController.text.isEmpty) return;
              await _firestore
                  .collection('patients')
                  .doc(widget.patientId)
                  .collection('labOrders')
                  .add({
                    'testName': testController.text,
                    'testType': 'blood',
                    'priority': 'normal',
                    'status': 'pending',
                    'createdAt': FieldValue.serverTimestamp(),
                    'doctorId': _auth.currentUser?.uid,
                    'doctorName': _doctorName,
                  });
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Lab order placed')));
            },
            child: const Text('Place'),
          ),
        ],
      ),
    );
  }

  // ==================== LAB RESULTS TAB ====================
  Widget _buildLabResultsTab() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('patients')
                .doc(widget.patientId)
                .collection('labOrders')
                .where('status', isEqualTo: 'completed')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState('No lab results');
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final data =
                      snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  return _buildLabResultCard(data);
                },
              );
            },
          ),
        ),
        _buildAddButton('Upload Result', () => _showUploadResultDialog()),
      ],
    );
  }

  Widget _buildLabResultCard(Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data['testName'] ?? 'Lab Test',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (data['results'] != null) Text('Results: ${data['results']}'),
          ],
        ),
      ),
    );
  }

  void _showUploadResultDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Lab Result'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Results'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  // ==================== MEDICAL IMAGES TAB ====================
  Widget _buildMedicalImagesTab() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('patients')
                .doc(widget.patientId)
                .collection('medicalImages')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState('No medical images');
              }
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final data =
                      snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  return _buildMedicalImageTile(data);
                },
              );
            },
          ),
        ),
        _buildAddButton('Attach Image', () => _showAddImageDialog()),
      ],
    );
  }

  Widget _buildMedicalImageTile(Map<String, dynamic> data) {
    return Card(
      child: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey.shade200,
              child: Center(
                child: Icon(Icons.image, size: 48, color: Colors.grey.shade600),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              data['imageType'] ?? 'Image',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddImageDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attach Medical Image'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Description'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              await _firestore
                  .collection('patients')
                  .doc(widget.patientId)
                  .collection('medicalImages')
                  .add({
                    'imageType': 'xray',
                    'description': controller.text,
                    'createdAt': FieldValue.serverTimestamp(),
                    'doctorId': _auth.currentUser?.uid,
                    'doctorName': _doctorName,
                  });
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Image attached')));
            },
            child: const Text('Attach'),
          ),
        ],
      ),
    );
  }

  // ==================== UTILITY WIDGETS ====================
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(String label, VoidCallback onPressed) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.add),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

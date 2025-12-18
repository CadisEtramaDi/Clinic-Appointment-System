import 'package:clinic/models/patient_record_model.dart';
import 'package:clinic/services/patient_record_management_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'manage_users_page.dart';
import 'appointment_management_page.dart';

class ManagePatientRecordsPage extends StatefulWidget {
  const ManagePatientRecordsPage({super.key});

  @override
  State<ManagePatientRecordsPage> createState() =>
      _ManagePatientRecordsPageState();
}

class _ManagePatientRecordsPageState extends State<ManagePatientRecordsPage> {
  final _searchController = TextEditingController();
  int _selectedIndex = 3;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Color _primaryColor = const Color(0xFF2D5AEE);
  final Color _backgroundColor = const Color(0xFFF8FAFC);
  final Color _cardColor = Colors.white;
  final Color _textPrimary = const Color(0xFF1E293B);
  final Color _textSecondary = const Color(0xFF64748B);
  final Color _successColor = const Color(0xFF10B981);
  final Color _warningColor = const Color(0xFFF59E0B);
  final Color _errorColor = const Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    if (index == 0) {
      Navigator.pop(context);
    } else if (index == 1) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const ManageUsersPage(),
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
    } else if (index == 2) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const ManageAppointmentsPage(),
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
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: _cardColor,
            elevation: 0,
            pinned: true,
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
              'Patient Records',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 20,
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
                  child: Icon(Icons.search, color: _textPrimary),
                ),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search and Add Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search by name, ID, or doctor...',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: _textSecondary,
                              ),
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                Icons.search,
                                color: _textSecondary,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.close,
                                        size: 20,
                                        color: _textSecondary,
                                      ),
                                      onPressed: () =>
                                          _searchController.clear(),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryColor.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.filter_list,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryColor.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All Patients', true),
                        const SizedBox(width: 8),
                        _buildFilterChip('Active', false),
                        const SizedBox(width: 8),
                        _buildFilterChip('Follow-up', false),
                        const SizedBox(width: 8),
                        _buildFilterChip('New This Month', false),
                        const SizedBox(width: 8),
                        _buildFilterChip('With Appointments', false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats Overview
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('users')
                        .where('role', isEqualTo: 'patient')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Error loading stats: ${snapshot.error}',
                            style: TextStyle(color: _errorColor),
                          ),
                        );
                      }

                      final patients = snapshot.data?.docs ?? [];
                      final now = DateTime.now();
                      final total = patients.length;

                      // Count new patients this month
                      final newThisMonth = patients.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final createdAt = data['createdAt'] as Timestamp?;
                        if (createdAt == null) return false;
                        final date = createdAt.toDate();
                        return date.year == now.year && date.month == now.month;
                      }).length;

                      // Count patients with pending status
                      final pending =
                          0; // Can be calculated based on incomplete records

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              value: total.toString(),
                              label: 'Total Patients',
                              color: _primaryColor,
                              icon: Icons.people,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              value: newThisMonth.toString(),
                              label: 'New This Month',
                              color: _successColor,
                              icon: Icons.person_add,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              value: pending.toString(),
                              label: 'Pending Records',
                              color: _warningColor,
                              icon: Icons.pending_actions,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('users')
                        .where('role', isEqualTo: 'patient')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Error loading records: ${snapshot.error}',
                            style: TextStyle(color: _errorColor),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'No patient records found.',
                            style: TextStyle(color: _textSecondary),
                          ),
                        );
                      }

                      final query = _searchController.text.trim().toLowerCase();
                      final patients = snapshot.data!.docs.where((doc) {
                        if (query.isEmpty) return true;
                        final data = doc.data() as Map<String, dynamic>;
                        final name = (data['fullName'] ?? data['name'] ?? '')
                            .toString()
                            .toLowerCase();
                        final email = (data['email'] ?? '')
                            .toString()
                            .toLowerCase();
                        final id = doc.id.toLowerCase();
                        return name.contains(query) ||
                            email.contains(query) ||
                            id.contains(query);
                      }).toList();

                      if (patients.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            query.isEmpty
                                ? 'No patient records found.'
                                : 'No patients match your search.',
                            style: TextStyle(color: _textSecondary),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          for (int i = 0; i < patients.length; i++)
                            FutureBuilder<Map<String, dynamic>>(
                              future: _getPatientDetails(patients[i].id),
                              builder: (context, detailsSnapshot) {
                                final data =
                                    patients[i].data() as Map<String, dynamic>;
                                final details = detailsSnapshot.data;

                                return Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    0,
                                    i == 0 ? 0 : 12,
                                    0,
                                    i == patients.length - 1 ? 24 : 0,
                                  ),
                                  child: _buildPatientCard({
                                    'name':
                                        data['fullName'] ??
                                        data['name'] ??
                                        'Unknown',
                                    'id': patients[i].id,
                                    'dob': data['birthdate'] != null
                                        ? (data['birthdate'] is Timestamp
                                              ? DateFormat('yyyy-MM-dd').format(
                                                  (data['birthdate']
                                                          as Timestamp)
                                                      .toDate(),
                                                )
                                              : data['birthdate'].toString())
                                        : '-',
                                    'age': _calculateAge(
                                      data['birthdate'] != null
                                          ? (data['birthdate'] is Timestamp
                                                ? DateFormat(
                                                    'yyyy-MM-dd',
                                                  ).format(
                                                    (data['birthdate']
                                                            as Timestamp)
                                                        .toDate(),
                                                  )
                                                : data['birthdate'].toString())
                                          : null,
                                    ),
                                    'lastVisit': details?['lastVisit'] ?? '-',
                                    'status':
                                        details?['hasAppointments'] == true
                                        ? 'Active'
                                        : 'New',
                                    'doctor': details?['doctor'] ?? '-',
                                    'avatarColor': _primaryColor,
                                    'nextAppointment':
                                        details?['nextAppointment'] ?? '-',
                                  }),
                                );
                              },
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
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
          currentIndex: _selectedIndex,
          onTap: _onNavItemTapped,
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
                  color: _selectedIndex == 0
                      ? _primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                ),
                child: const Icon(Icons.dashboard_outlined, size: 22),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _primaryColor.withOpacity(0.1),
                ),
                child: Icon(Icons.dashboard, size: 22, color: _primaryColor),
              ),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _selectedIndex == 1
                      ? _primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                ),
                child: const Icon(Icons.people_outline, size: 22),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _primaryColor.withOpacity(0.1),
                ),
                child: Icon(Icons.people, size: 22, color: _primaryColor),
              ),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _selectedIndex == 2
                      ? _primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                ),
                child: const Icon(Icons.calendar_today_outlined, size: 22),
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
              label: 'Appointments',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _selectedIndex == 3
                      ? _primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                ),
                child: const Icon(Icons.description_outlined, size: 22),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _primaryColor.withOpacity(0.1),
                ),
                child: Icon(Icons.description, size: 22, color: _primaryColor),
              ),
              label: 'Records',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 13, color: _textSecondary)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? _primaryColor : _backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? _primaryColor : _textSecondary.withOpacity(0.2),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: isSelected ? Colors.white : _textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final isActive = patient['status'] == 'Active';
    final isFollowUp = patient['status'] == 'Follow-up';
    final avatarColor = patient['avatarColor'] as Color;
    final hasNextAppointment = patient['nextAppointment'] != '-';
    final patientId = patient['id'] as String;

    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Header
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: avatarColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      patient['name'].split(' ').map((n) => n[0]).join(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: avatarColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient['name'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? _successColor.withOpacity(0.1)
                              : isFollowUp
                              ? _warningColor.withOpacity(0.1)
                              : _errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          patient['status'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isActive
                                ? _successColor
                                : isFollowUp
                                ? _warningColor
                                : _errorColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.more_vert, color: _textSecondary),
              ],
            ),
            const SizedBox(height: 20),

            // Medical Records Header Banner
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('patients')
                  .doc(patientId)
                  .collection('diagnoses')
                  .orderBy('createdAt', descending: true)
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  final diagnosis =
                      snapshot.data!.docs.first.data() as Map<String, dynamic>;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _successColor.withOpacity(0.1),
                          _successColor.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _successColor.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _successColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.check_circle,
                            color: _successColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Medical Records Available',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _successColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${diagnosis['diagnosis'] ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 16),

            // Patient Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          icon: Icons.cake,
                          label: 'Age',
                          value: '${patient['age']} years',
                        ),
                      ),
                      Expanded(
                        child: _buildDetailItem(
                          icon: Icons.calendar_today,
                          label: 'Last Visit',
                          value: patient['lastVisit'],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          icon: Icons.medical_services,
                          label: 'Doctor',
                          value: patient['doctor'],
                        ),
                      ),
                      Expanded(
                        child: _buildDetailItem(
                          icon: Icons.event_available,
                          label: 'Next Appointment',
                          value: patient['nextAppointment'],
                          isHighlighted: hasNextAppointment,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Medical History Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _primaryColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('patients')
                    .doc(patientId)
                    .collection('diagnoses')
                    .orderBy('createdAt', descending: true)
                    .limit(1)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Row(
                      children: [
                        const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Loading medical records...',
                          style: TextStyle(color: _textSecondary, fontSize: 14),
                        ),
                      ],
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Row(
                      children: [
                        Icon(Icons.info, color: _textSecondary, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'No medical records yet',
                          style: TextStyle(color: _textSecondary, fontSize: 14),
                        ),
                      ],
                    );
                  }

                  final diagnosis =
                      snapshot.data!.docs.first.data() as Map<String, dynamic>;
                  final diagnosisText = diagnosis['diagnosis'] ?? 'N/A';
                  final hasFollowUp =
                      diagnosis['followUpRequired'] as bool? ?? false;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Diagnosis Header
                      Row(
                        children: [
                          Icon(Icons.healing, color: _primaryColor, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Latest Diagnosis: $diagnosisText',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _primaryColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Severity Badge
                      if ((diagnosis['severity'] ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getSeverityColor(
                                diagnosis['severity'] ?? 'moderate',
                              ).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Severity: ${diagnosis['severity']}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getSeverityColor(
                                  diagnosis['severity'] ?? 'moderate',
                                ),
                              ),
                            ),
                          ),
                        ),

                      // ICD-10 Code
                      if ((diagnosis['icdCode'] ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(Icons.tag, size: 16, color: _textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                'ICD-10: ${diagnosis['icdCode']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _textPrimary,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Symptoms
                      if ((diagnosis['symptoms'] ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.sick, size: 16, color: _textSecondary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Symptoms: ${diagnosis['symptoms']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Allergies
                      if ((diagnosis['allergies'] ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning,
                                size: 16,
                                color: _warningColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Allergies: ${diagnosis['allergies']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Vitals
                      if ((diagnosis['vitals'] ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.favorite,
                                size: 16,
                                color: _warningColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Vitals: ${diagnosis['vitals']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Treatment Plan
                      if ((diagnosis['treatmentPlan'] ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.assignment,
                                size: 16,
                                color: _primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Treatment: ${diagnosis['treatmentPlan']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Prescription
                      if ((diagnosis['prescription'] ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.medication,
                                size: 16,
                                color: _successColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Prescription: ${diagnosis['prescription']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Notes
                      if ((diagnosis['notes'] ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.note, size: 16, color: _textSecondary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Notes: ${diagnosis['notes']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Follow-up Badge
                      if (hasFollowUp)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _warningColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.event_repeat,
                                  size: 14,
                                  color: _warningColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Follow-up Required',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _warningColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showPatientDetailsDialog(patient),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: _textSecondary.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.remove_red_eye_outlined,
                          size: 18,
                          color: _textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'View Details',
                          style: TextStyle(
                            color: _textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showMedicalHistoryDialog(patientId),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: _textSecondary.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 18, color: _textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          'History',
                          style: TextStyle(
                            color: _textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: _textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isHighlighted ? _primaryColor : _textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _calculateAge(String? dob) {
    if (dob == null || dob.isEmpty) return '-';
    try {
      final birthDate = DateTime.parse(dob);
      final now = DateTime.now();
      var age = now.year - birthDate.year;
      final hasHadBirthdayThisYear =
          (now.month > birthDate.month) ||
          (now.month == birthDate.month && now.day >= birthDate.day);
      if (!hasHadBirthdayThisYear) {
        age--;
      }
      return age.toString();
    } catch (_) {
      return '-';
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'mild':
        return const Color(0xFF3B82F6); // Blue
      case 'moderate':
        return _warningColor; // Orange/Warning color
      case 'severe':
        return const Color(0xFFEF4444); // Red
      default:
        return _textSecondary;
    }
  }

  void _showPatientDetailsDialog(Map<String, dynamic> patient) {
    final patientId = patient['id'] as String;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Patient Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            patient['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Patient ID', patient['id']),
                      _buildInfoRow('Date of Birth', patient['dob']),
                      _buildInfoRow('Age', '${patient['age']} years'),
                      _buildInfoRow('Status', patient['status']),
                      _buildInfoRow('Primary Doctor', patient['doctor']),
                      _buildInfoRow('Last Visit', patient['lastVisit']),
                      _buildInfoRow(
                        'Next Appointment',
                        patient['nextAppointment'],
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 20),
                      // Latest Medical Records
                      _buildSectionTitle('Latest Medical Records'),
                      const SizedBox(height: 12),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('patients')
                            .doc(patientId)
                            .collection('diagnoses')
                            .orderBy('createdAt', descending: true)
                            .limit(3)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Text(
                              'No medical records available',
                              style: TextStyle(color: _textSecondary),
                            );
                          }

                          return Column(
                            children: snapshot.data!.docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final date = data['createdAt'] as Timestamp?;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.medical_services,
                                            size: 16,
                                            color: _primaryColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            date != null
                                                ? DateFormat(
                                                    'MMM dd, yyyy',
                                                  ).format(date.toDate())
                                                : 'Date unknown',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: _textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      if (data['diagnosis'] != null)
                                        Text('Diagnosis: ${data['diagnosis']}'),
                                      if (data['prescription'] != null)
                                        Text(
                                          'Prescription: ${data['prescription']}',
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMedicalHistoryDialog(String patientId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _successColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Medical History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('patients')
                      .doc(patientId)
                      .collection('diagnoses')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: _textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No medical history available',
                              style: TextStyle(color: _textSecondary),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final data =
                            snapshot.data!.docs[index].data()
                                as Map<String, dynamic>;
                        final date = data['createdAt'] as Timestamp?;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ExpansionTile(
                            title: Text(
                              date != null
                                  ? DateFormat(
                                      'MMMM dd, yyyy',
                                    ).format(date.toDate())
                                  : 'Date unknown',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _textPrimary,
                              ),
                            ),
                            subtitle: Text(data['diagnosis'] ?? 'No diagnosis'),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (data['diagnosis'] != null) ...[
                                      _buildDetailRow2(
                                        'Diagnosis',
                                        data['diagnosis'],
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    if (data['prescription'] != null) ...[
                                      _buildDetailRow2(
                                        'Prescription',
                                        data['prescription'],
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    if (data['allergies'] != null) ...[
                                      _buildDetailRow2(
                                        'Allergies',
                                        data['allergies'],
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    if (data['vitals'] != null) ...[
                                      _buildDetailRow2(
                                        'Vitals',
                                        data['vitals'],
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    if (data['treatmentPlan'] != null) ...[
                                      _buildDetailRow2(
                                        'Treatment Plan',
                                        data['treatmentPlan'],
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    if (data['notes'] != null) ...[
                                      _buildDetailRow2('Notes', data['notes']),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrescriptionsDialog(String patientId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _warningColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.medication, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Prescriptions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Content - Get prescriptions from diagnoses
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('patients')
                      .doc(patientId)
                      .collection('diagnoses')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.medication,
                              size: 64,
                              color: _textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No prescriptions available',
                              style: TextStyle(color: _textSecondary),
                            ),
                          ],
                        ),
                      );
                    }

                    // Get only unique prescriptions based on content to avoid duplicates
                    final seenPrescriptions = <String>{};
                    final prescriptions = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final prescription = (data['prescription'] ?? '')
                          .toString()
                          .trim();
                      if (prescription.isEmpty) return false;

                      // Check if we've already seen this exact prescription
                      if (seenPrescriptions.contains(prescription)) {
                        return false;
                      }
                      seenPrescriptions.add(prescription);
                      return true;
                    }).toList();

                    if (prescriptions.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.medication,
                              size: 64,
                              color: _textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No prescriptions available',
                              style: TextStyle(color: _textSecondary),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: prescriptions.length,
                      itemBuilder: (context, index) {
                        final data =
                            prescriptions[index].data() as Map<String, dynamic>;
                        final date = data['createdAt'] as Timestamp?;
                        final prescription = data['prescription'] ?? '';
                        final diagnosis = data['diagnosis'] ?? '';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Prescription',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: _textPrimary,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _successColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'ACTIVE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: _successColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildPrescriptionRow('Dosage', prescription),
                                _buildPrescriptionRow(
                                  'Frequency',
                                  'As prescribed',
                                ),
                                _buildPrescriptionRow('Duration', '7 days'),
                                _buildPrescriptionRow('Notes', prescription),
                                if (diagnosis.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  _buildPrescriptionRow('Diagnosis', diagnosis),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  date != null
                                      ? 'Prescribed on ${DateFormat('MMM dd, yyyy').format(date.toDate())}'
                                      : 'Date unknown',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: _textPrimary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: _textPrimary,
      ),
    );
  }

  Widget _buildDetailRow2(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: _textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: _textPrimary, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildPrescriptionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 6, color: _primaryColor),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: _textPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getPatientDetails(String patientId) async {
    try {
      // Get all appointments for this patient
      final allAppointments = await _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .get();

      if (allAppointments.docs.isEmpty) {
        return {
          'lastVisit': '-',
          'doctor': '-',
          'nextAppointment': '-',
          'hasAppointments': false,
        };
      }

      // Filter completed appointments and sort manually
      final completedAppts = allAppointments.docs
          .where((doc) => doc.data()['status'] == 'completed')
          .toList();

      completedAppts.sort((a, b) {
        final dateA = (a.data()['appointmentDate'] as Timestamp?)?.toDate();
        final dateB = (b.data()['appointmentDate'] as Timestamp?)?.toDate();
        if (dateA == null || dateB == null) return 0;
        return dateB.compareTo(dateA); // descending
      });

      // Filter upcoming appointments and sort manually
      final upcomingStatuses = ['pending', 'confirmed', 'upcoming'];
      final upcomingAppts = allAppointments.docs
          .where((doc) => upcomingStatuses.contains(doc.data()['status']))
          .toList();

      upcomingAppts.sort((a, b) {
        final dateA = (a.data()['appointmentDate'] as Timestamp?)?.toDate();
        final dateB = (b.data()['appointmentDate'] as Timestamp?)?.toDate();
        if (dateA == null || dateB == null) return 0;
        return dateA.compareTo(dateB); // ascending
      });

      String? lastVisit;
      String? doctor;
      String? nextAppointment;

      // Get last visit
      if (completedAppts.isNotEmpty) {
        final lastAppt = completedAppts.first.data();
        final date = lastAppt['appointmentDate'] as Timestamp?;
        if (date != null) {
          lastVisit = DateFormat('MMM d, yyyy').format(date.toDate());
        }
        doctor = lastAppt['doctorName'] ?? '-';
      }

      // Get next appointment
      if (upcomingAppts.isNotEmpty) {
        final nextAppt = upcomingAppts.first.data();
        final date = nextAppt['appointmentDate'] as Timestamp?;
        if (date != null) {
          nextAppointment = DateFormat('MMM d, yyyy').format(date.toDate());
        }
      }

      return {
        'lastVisit': lastVisit ?? '-',
        'doctor': doctor ?? '-',
        'nextAppointment': nextAppointment ?? '-',
        'hasAppointments': true,
      };
    } catch (e) {
      print('Error getting patient details: $e');
      return {
        'lastVisit': '-',
        'doctor': '-',
        'nextAppointment': '-',
        'hasAppointments': false,
      };
    }
  }
}

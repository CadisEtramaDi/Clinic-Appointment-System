import 'package:clinic/patient/patient_page.dart';
import 'package:flutter/material.dart';
import 'book_appointment_page.dart';
import 'profile_page.dart';

class AppointmentHistoryPage extends StatefulWidget {
  const AppointmentHistoryPage({Key? key}) : super(key: key);

  @override
  State<AppointmentHistoryPage> createState() => _AppointmentHistoryPageState();
}

class _AppointmentHistoryPageState extends State<AppointmentHistoryPage>
    with SingleTickerProviderStateMixin {
  String _filterType = 'All';
  String _sortType = 'Recent';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _appointments = [
    {
      'date': 'Nov 20, 2025 - 2:00 PM',
      'doctor': 'Dr. Michael Smith',
      'specialty': 'Cardiologist',
      'reason': 'Follow-up Visit for post-surgery recovery',
      'diagnosis':
          'Patient is recovering well, sutures removed, continue medication for another week. Blood pressure stable.',
      'status': 'Completed',
      'statusColor': Color(0xFF10B981),
      'doctorImage': '👨‍⚕️',
      'duration': '45 mins',
      'prescription': 'Medication A, B, C',
      'color': Color(0xFF2196F3),
      'gradient': [Color(0xFF2196F3), Color(0xFF21CBF3)],
    },
    {
      'date': 'Oct 15, 2025 - 10:00 AM',
      'doctor': 'Dr. Sarah Johnson',
      'specialty': 'General Physician',
      'reason': 'Annual Check-up and general health assessment',
      'diagnosis':
          'Healthy, no issues detected. Advised to continue current diet and exercise routine. Cholesterol levels optimal.',
      'status': 'Completed',
      'statusColor': Color(0xFF10B981),
      'doctorImage': '👩‍⚕️',
      'duration': '30 mins',
      'prescription': 'Vitamin D, Calcium',
      'color': Color(0xFF42A5F5),
      'gradient': [Color(0xFF42A5F5), Color(0xFF64B5F6)],
    },
    {
      'date': 'Dec 5, 2025 - 11:00 AM',
      'doctor': 'Dr. Emily White',
      'specialty': 'Dermatologist',
      'reason': 'Skin allergy consultation',
      'diagnosis':
          'Mild allergic reaction to pollen. Prescribed antihistamines and topical cream.',
      'status': 'Upcoming',
      'statusColor': Color(0xFFF59E0B),
      'doctorImage': '👩‍⚕️',
      'duration': '25 mins',
      'prescription': 'Antihistamines, Topical Cream',
      'color': Color(0xFF29B6F6),
      'gradient': [Color(0xFF29B6F6), Color(0xFF4FC3F7)],
    },
    {
      'date': 'Sep 10, 2025 - 3:00 PM',
      'doctor': 'Dr. Robert Chen',
      'specialty': 'Orthopedic Surgeon',
      'reason': 'Knee pain evaluation',
      'diagnosis':
          'Mild arthritis detected. Recommended physical therapy and pain management.',
      'status': 'Completed',
      'statusColor': Color(0xFF10B981),
      'doctorImage': '👨‍⚕️',
      'duration': '60 mins',
      'prescription': 'Pain Relievers, Anti-inflammatory',
      'color': Color(0xFF26C6DA),
      'gradient': [Color(0xFF26C6DA), Color(0xFF4DD0E1)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return GestureDetector(
      onTap: () => setState(() => _filterType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF2196F3)])
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFF2196F3).withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check, size: 16, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F9FF),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // Custom App Bar with Blue Gradient
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              floating: true,
              expandedHeight: 100,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1976D2),
                        Color(0xFF2196F3),
                        Color(0xFF64B5F6),
                      ],
                    ),
                  ),
                ),
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Appointment History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Filter Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white, Color(0xFFE3F2FD)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF2196F3).withOpacity(0.1),
                            blurRadius: 30,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            'Total',
                            '${_appointments.length}',
                            Icons.history,
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.grey.shade200,
                          ),
                          _buildStatItem('Completed', '3', Icons.check_circle),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.grey.shade200,
                          ),
                          _buildStatItem('Upcoming', '1', Icons.calendar_today),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Filter by Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Filter Chips
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildFilterChip('All', 'All'),
                        _buildFilterChip('Completed', 'Completed'),
                        _buildFilterChip('Upcoming', 'Upcoming'),
                        _buildFilterChip('Cancelled', 'Cancelled'),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Sort Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.sort, color: Color(0xFF2196F3)),
                          const SizedBox(width: 12),
                          Text(
                            'Sort by:',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          DropdownButton<String>(
                            value: _sortType,
                            underline: const SizedBox(),
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: Color(0xFF2196F3),
                            ),
                            items: ['Recent', 'Oldest', 'Doctor'].map((
                              String item,
                            ) {
                              return DropdownMenuItem<String>(
                                value: item,
                                child: Text(
                                  item,
                                  style: TextStyle(color: Color(0xFF1565C0)),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _sortType = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Appointments List
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return _buildAppointmentCard(_appointments[index]);
              }, childCount: _appointments.length),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF2196F3).withOpacity(0.1),
                Color(0xFF64B5F6).withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Color(0xFF2196F3), size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0),
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final gradientColors = appointment['gradient'] as List<Color>;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 30,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with Blue Gradient
            Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              appointment['doctorImage'],
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              appointment['doctor'],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              appointment['specialty'],
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        appointment['duration'],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date and Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            size: 18,
                            color: Color(0xFF2196F3),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            appointment['date'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: appointment['statusColor'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: appointment['statusColor'].withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          appointment['status'],
                          style: TextStyle(
                            color: appointment['statusColor'],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Reason Card
                  _buildDetailCard(
                    icon: Icons.description_outlined,
                    title: 'Reason for Visit',
                    content: appointment['reason'],
                    color: Color(0xFF2196F3),
                  ),
                  const SizedBox(height: 16),

                  // Diagnosis Card
                  _buildDetailCard(
                    icon: Icons.medical_services_outlined,
                    title: 'Diagnosis & Notes',
                    content: appointment['diagnosis'],
                    color: Color(0xFF00BCD4),
                  ),
                  const SizedBox(height: 16),

                  // Prescription Card
                  _buildDetailCard(
                    icon: Icons.medication_outlined,
                    title: 'Prescription',
                    content: appointment['prescription'],
                    color: Color(0xFF4CAF50),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          icon: Icon(
                            Icons.remove_red_eye_outlined,
                            size: 18,
                            color: Color(0xFF2196F3),
                          ),
                          label: Text(
                            'View Full Report',
                            style: TextStyle(
                              color: Color(0xFF2196F3),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradientColors),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.share_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () {},
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
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Color(0xFF1565C0),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 40,
            spreadRadius: 5,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            Icons.home_outlined,
            'Home',
            false,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const PatientPage()),
              );
            },
          ),
          _buildNavItem(
            Icons.calendar_month,
            'Book',
            false,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookAppointmentPage(),
                ),
              );
            },
          ),
          _buildNavItem(Icons.history, 'History', true, onTap: () {}),
          _buildNavItem(
            Icons.person_outline,
            'Profile',
            false,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool active, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: active
                  ? LinearGradient(
                      colors: [
                        Color(0xFF2196F3).withOpacity(0.1),
                        Color(0xFF64B5F6).withOpacity(0.1),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 24,
              color: active ? Color(0xFF2196F3) : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: active ? Color(0xFF2196F3) : Colors.grey.shade400,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

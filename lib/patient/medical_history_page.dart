import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/appointment_service.dart';

class MedicalHistoryPage extends StatefulWidget {
  const MedicalHistoryPage({super.key});

  @override
  State<MedicalHistoryPage> createState() => _MedicalHistoryPageState();
}

class _MedicalHistoryPageState extends State<MedicalHistoryPage> {
  final AppointmentService _appointmentService = AppointmentService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final userId = _appointmentService.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Medical History')),
        body: const Center(
          child: Text('Please log in to view medical history'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical History'),
        elevation: 0,
        backgroundColor: Colors.blue.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHistorySection(
              context,
              'Diagnoses',
              Icons.medical_information,
              Colors.blue.shade700,
              userId,
              'diagnoses',
            ),
            const SizedBox(height: 24),
            _buildHistorySection(
              context,
              'Doctor Notes',
              Icons.notes,
              Colors.teal.shade700,
              userId,
              'doctorNotes',
            ),
            const SizedBox(height: 24),
            _buildHistorySection(
              context,
              'Treatment Outcomes',
              Icons.trending_up,
              Colors.green.shade700,
              userId,
              'treatmentOutcomes',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String userId,
    String collectionName,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('patients')
              .doc(userId)
              .collection(collectionName)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: color),
                ),
              );
            }

            if (snapshot.hasError) {
              return _buildEmptyCard('No ${title.toLowerCase()} found');
            }

            final items = snapshot.data?.docs ?? [];
            if (items.isEmpty) {
              return _buildEmptyCard('No ${title.toLowerCase()} found');
            }

            return Column(
              children: items.map((doc) {
                final item = doc.data() as Map<String, dynamic>;
                return _buildHistoryCard(item, color);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item, Color color) {
    final createdAt = item['createdAt'] as Timestamp?;
    final formattedDate = createdAt != null
        ? DateFormat('MMM dd, yyyy').format(createdAt.toDate())
        : 'Unknown date';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item['diagnosis'] != null)
            Text(
              item['diagnosis'] ?? '',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          if (item['planName'] != null)
            Text(
              item['planName'] ?? '',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          if (item['outcome'] != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getOutcomeColor(item['outcome']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item['outcome'] ?? '',
                style: TextStyle(
                  fontSize: 12,
                  color: _getOutcomeColor(item['outcome']),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                formattedDate,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          if (item['notes'] != null || item['description'] != null) ...[
            const SizedBox(height: 12),
            Text(
              item['notes'] ?? item['description'] ?? '',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        ),
      ),
    );
  }

  Color _getOutcomeColor(String? outcome) {
    switch (outcome?.toLowerCase()) {
      case 'successful':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      case 'unsuccessful':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/appointment_service.dart';

class VitalsTrackingPage extends StatefulWidget {
  const VitalsTrackingPage({super.key});

  @override
  State<VitalsTrackingPage> createState() => _VitalsTrackingPageState();
}

class _VitalsTrackingPageState extends State<VitalsTrackingPage> {
  final AppointmentService _appointmentService = AppointmentService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final userId = _appointmentService.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Track Vitals')),
        body: const Center(child: Text('Please log in to track vitals')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Vitals'),
        elevation: 0,
        backgroundColor: Colors.blue.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddVitalDialog(context, userId),
          ),
        ],
      ),
      body: _buildVitalsView(userId),
    );
  }

  Widget _buildVitalsView(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('patients')
          .doc(userId)
          .collection('vitals')
          .orderBy('recordedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: Colors.blue.shade800),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final vitals = snapshot.data?.docs ?? [];
        if (vitals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.monitor_heart,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No vital records found',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddVitalDialog(context, userId),
                  icon: const Icon(Icons.add),
                  label: const Text('Add First Record'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVitalsSummary(vitals),
              const SizedBox(height: 24),
              Text(
                'Vital Records',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              ...vitals.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildVitalCard(data);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVitalsSummary(List<QueryDocumentSnapshot> vitals) {
    if (vitals.isEmpty) return const SizedBox.shrink();

    final latestVital = vitals.first.data() as Map<String, dynamic>;
    final recordedAt = latestVital['recordedAt'] as Timestamp?;
    final formattedDate = recordedAt != null
        ? DateFormat('MMM dd, yyyy HH:mm').format(recordedAt.toDate())
        : 'N/A';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade50, Colors.blue.shade100],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latest Vitals',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Recorded: $formattedDate',
            style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2,
            children: [
              _buildVitalMetric(
                'Heart Rate',
                '${latestVital['heartRate'] ?? '--'} bpm',
                Icons.favorite,
                Colors.red,
              ),
              _buildVitalMetric(
                'Temperature',
                '${latestVital['temperature'] ?? '--'}°F',
                Icons.thermostat,
                Colors.orange,
              ),
              _buildVitalMetric(
                'Blood Pressure',
                latestVital['bloodPressure'] ?? '--',
                Icons.favorite_outline,
                Colors.blue,
              ),
              _buildVitalMetric(
                'Blood Oxygen',
                '${latestVital['bloodOxygen'] ?? '--'}%',
                Icons.air,
                Colors.teal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildVitalCard(Map<String, dynamic> vital) {
    final recordedAt = vital['recordedAt'] as Timestamp?;
    final formattedDate = recordedAt != null
        ? DateFormat('MMM dd, yyyy HH:mm').format(recordedAt.toDate())
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
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              if (vital['notes'] != null && vital['notes'].isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Has Notes',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.5,
            children: [
              _buildVitalInfo(
                'Heart Rate',
                '${vital['heartRate'] ?? '--'} bpm',
              ),
              _buildVitalInfo(
                'Temperature',
                '${vital['temperature'] ?? '--'}°F',
              ),
              _buildVitalInfo('Blood Pressure', vital['bloodPressure'] ?? '--'),
              _buildVitalInfo(
                'Blood Oxygen',
                '${vital['bloodOxygen'] ?? '--'}%',
              ),
            ],
          ),
          if (vital['notes'] != null && vital['notes'].isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vital['notes'],
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVitalInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  void _showAddVitalDialog(BuildContext context, String userId) {
    final formKey = GlobalKey<FormState>();
    String heartRate = '';
    String temperature = '';
    String bloodPressure = '';
    String bloodOxygen = '';
    String notes = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Vital Record'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Heart Rate (bpm)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => heartRate = value,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Temperature (°F)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) => temperature = value,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Blood Pressure (e.g., 120/80)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => bloodPressure = value,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Blood Oxygen (%)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => bloodOxygen = value,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  onChanged: (value) => notes = value,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await _firestore
                      .collection('patients')
                      .doc(userId)
                      .collection('vitals')
                      .add({
                        'heartRate': int.tryParse(heartRate),
                        'temperature': double.tryParse(temperature),
                        'bloodPressure': bloodPressure,
                        'bloodOxygen': int.tryParse(bloodOxygen),
                        'notes': notes,
                        'recordedAt': FieldValue.serverTimestamp(),
                      });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vital record added')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

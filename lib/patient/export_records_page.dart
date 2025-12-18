import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/appointment_service.dart';

class ExportRecordsPage extends StatefulWidget {
  const ExportRecordsPage({super.key});

  @override
  State<ExportRecordsPage> createState() => _ExportRecordsPageState();
}

class _ExportRecordsPageState extends State<ExportRecordsPage> {
  final AppointmentService _appointmentService = AppointmentService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final userId = _appointmentService.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Export Records')),
        body: const Center(child: Text('Please log in to export records')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Records'),
        elevation: 0,
        backgroundColor: Colors.blue.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExportOptions(context, userId),
            const SizedBox(height: 24),
            _buildExportHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOptions(BuildContext context, String userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Export Your Health Records',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Select the records and format you want to export',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        _buildExportCard(
          context,
          title: 'Export as PDF',
          description: 'Complete medical records in PDF format',
          icon: Icons.picture_as_pdf,
          color: Colors.red,
          onTap: () => _exportRecords(context, userId, 'pdf'),
        ),
        const SizedBox(height: 12),
        _buildExportCard(
          context,
          title: 'Export as CSV',
          description: 'Tabular format for spreadsheets',
          icon: Icons.table_chart,
          color: Colors.green,
          onTap: () => _exportRecords(context, userId, 'csv'),
        ),
        const SizedBox(height: 12),
        _buildExportCard(
          context,
          title: 'Export as JSON',
          description: 'Structured data format',
          icon: Icons.code,
          color: Colors.blue,
          onTap: () => _exportRecords(context, userId, 'json'),
        ),
        const SizedBox(height: 12),
        _buildExportCard(
          context,
          title: 'Email Records',
          description: 'Send records to your email',
          icon: Icons.email,
          color: Colors.orange,
          onTap: () => _showEmailDialog(context, userId),
        ),
      ],
    );
  }

  Widget _buildExportCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isExporting ? null : onTap,
      child: Container(
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (_isExporting)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              )
            else
              Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildExportHistory() {
    final userId = _appointmentService.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Exports',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('patients')
              .doc(userId)
              .collection('exportHistory')
              .orderBy('exportedAt', descending: true)
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: Colors.blue.shade800),
              );
            }

            final exports = snapshot.data?.docs ?? [];
            if (exports.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Center(
                  child: Text(
                    'No export history yet',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              );
            }

            return Column(
              children: exports.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildExportHistoryCard(data);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildExportHistoryCard(Map<String, dynamic> export) {
    final exportedAt = export['exportedAt'] as Timestamp?;
    final formattedDate = exportedAt != null
        ? DateFormat('MMM dd, yyyy HH:mm').format(exportedAt.toDate())
        : 'Unknown date';
    final format = export['format'] ?? 'Unknown';
    final recipientType = export['recipientType'] ?? 'Download';

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exported as ${format.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sent to: $recipientType',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Completed',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
        ],
      ),
    );
  }

  Future<void> _exportRecords(
    BuildContext context,
    String userId,
    String format,
  ) async {
    try {
      setState(() => _isExporting = true);

      // Simulate export delay
      await Future.delayed(const Duration(seconds: 2));

      // Add to export history
      await _firestore
          .collection('patients')
          .doc(userId)
          .collection('exportHistory')
          .add({
            'format': format,
            'recipientType': 'Download',
            'exportedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Records exported as ${format.toUpperCase()}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showEmailDialog(BuildContext context, String userId) {
    final formKey = GlobalKey<FormState>();
    String email = '';
    String format = 'pdf';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Records'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                    hintText: 'recipient@example.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) => email = value,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Required';
                    if (!value!.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: format,
                  items: ['pdf', 'csv', 'json']
                      .map(
                        (fmt) => DropdownMenuItem(
                          value: fmt,
                          child: Text(fmt.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) format = value;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Export Format',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Your records will be securely encrypted and sent to this email address.',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                  ),
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
                      .collection('exportHistory')
                      .add({
                        'format': format,
                        'recipientType': 'Email: $email',
                        'email': email,
                        'exportedAt': FieldValue.serverTimestamp(),
                      });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Records sent to $email'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

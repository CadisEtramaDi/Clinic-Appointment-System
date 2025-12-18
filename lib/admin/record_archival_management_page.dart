import 'package:flutter/material.dart';
import 'package:clinic/models/patient_record_model.dart';
import 'package:clinic/services/patient_record_management_service.dart';

class RecordArchivalManagementPage extends StatefulWidget {
  const RecordArchivalManagementPage({super.key});

  @override
  State<RecordArchivalManagementPage> createState() =>
      _RecordArchivalManagementPageState();
}

class _RecordArchivalManagementPageState
    extends State<RecordArchivalManagementPage> {
  final _service = PatientRecordManagementService();
  late Future<List<PatientRecord>> _activeRecords;
  late Future<List<PatientRecord>> _archivedRecords;
  bool _showArchived = false;

  final Color _primaryColor = const Color(0xFF2D5AEE);
  final Color _backgroundColor = const Color(0xFFF8FAFC);
  final Color _cardColor = Colors.white;
  final Color _textPrimary = const Color(0xFF1E293B);
  final Color _textSecondary = const Color(0xFF64748B);
  final Color _successColor = const Color(0xFF10B981);
  final Color _errorColor = const Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  void _loadRecords() {
    _activeRecords = _service.getAllPatientRecords(recordStatus: 'active');
    _archivedRecords = _service.getArchivedRecords();
  }

  void _refreshRecords() {
    setState(() {
      _loadRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Record Archival Management',
          style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: _primaryColor),
            onPressed: _refreshRecords,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Switcher
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showArchived = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: !_showArchived
                                ? _primaryColor
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        'Active Records',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: !_showArchived
                              ? _primaryColor
                              : _textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showArchived = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _showArchived
                                ? _primaryColor
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        'Archived Records',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _showArchived ? _primaryColor : _textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _showArchived
                ? _buildArchivedRecordsList()
                : _buildActiveRecordsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRecordsList() {
    return FutureBuilder<List<PatientRecord>>(
      future: _activeRecords,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: _primaryColor));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(color: _errorColor),
            ),
          );
        }

        final records = snapshot.data ?? [];

        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No Active Records',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: _textPrimary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return _buildRecordCard(context, record, isArchived: false);
          },
        );
      },
    );
  }

  Widget _buildArchivedRecordsList() {
    return FutureBuilder<List<PatientRecord>>(
      future: _archivedRecords,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: _primaryColor));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(color: _errorColor),
            ),
          );
        }

        final records = snapshot.data ?? [];

        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.archive, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No Archived Records',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: _textPrimary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return _buildRecordCard(context, record, isArchived: true);
          },
        );
      },
    );
  }

  Widget _buildRecordCard(
    BuildContext context,
    PatientRecord record, {
    required bool isArchived,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _primaryColor.withOpacity(0.1),
                child: Text(
                  record.patientName[0].toUpperCase(),
                  style: TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.patientName,
                      style: TextStyle(
                        color: _textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      record.email ?? 'No email',
                      style: TextStyle(color: _textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isArchived
                            ? Colors.grey.shade200
                            : _successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isArchived ? 'Archived' : 'Active',
                        style: TextStyle(
                          color: isArchived
                              ? Colors.grey.shade700
                              : _successColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last Visit',
                    style: TextStyle(color: _textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record.lastVisitDate?.toString().split(' ')[0] ?? 'N/A',
                    style: TextStyle(
                      color: _textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (isArchived && record.archivedAt != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Archived Date',
                      style: TextStyle(color: _textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.archivedAt!.toString().split(' ')[0],
                      style: TextStyle(
                        color: _textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Action Button
          SizedBox(
            width: double.infinity,
            child: isArchived
                ? ElevatedButton.icon(
                    onPressed: () => _showRestoreDialog(context, record),
                    icon: const Icon(Icons.restore, size: 18),
                    label: const Text('Restore Record'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _successColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: () => _showArchiveDialog(context, record),
                    icon: const Icon(Icons.archive, size: 18),
                    label: const Text('Archive Record'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showArchiveDialog(BuildContext context, PatientRecord record) {
    showDialog(
      context: context,
      builder: (context) {
        final reasonController = TextEditingController();
        return AlertDialog(
          title: const Text('Archive Record'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Archive record for ${record.patientName}?'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  hintText: 'Reason for archival (e.g., Patient inactive)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
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
                Navigator.pop(context);
                try {
                  await _service.archivePatientRecord(
                    record.id,
                    'admin_id', // Would be actual admin ID
                    'Admin Name', // Would be actual admin name
                    reasonController.text.isNotEmpty
                        ? reasonController.text
                        : 'Record archived by admin',
                  );
                  _refreshRecords();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Record archived')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Archive'),
            ),
          ],
        );
      },
    );
  }

  void _showRestoreDialog(BuildContext context, PatientRecord record) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Restore Record'),
          content: Text('Restore record for ${record.patientName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _service.restoreArchivedRecord(
                    record.id,
                    'admin_id', // Would be actual admin ID
                    'Admin Name', // Would be actual admin name
                  );
                  _refreshRecords();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Record restored')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _successColor),
              child: const Text('Restore'),
            ),
          ],
        );
      },
    );
  }
}

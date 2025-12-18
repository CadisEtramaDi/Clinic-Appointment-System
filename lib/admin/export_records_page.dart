import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminExportRecordsPage extends StatefulWidget {
  const AdminExportRecordsPage({super.key});

  @override
  State<AdminExportRecordsPage> createState() => _AdminExportRecordsPageState();
}

class _AdminExportRecordsPageState extends State<AdminExportRecordsPage> {
  final _firestore = FirebaseFirestore.instance;

  final Color _primaryColor = const Color(0xFF6366F1);
  final Color _successColor = const Color(0xFF10B981);
  final Color _errorColor = const Color(0xFFEF4444);
  final Color _textPrimary = const Color(0xFF1F2937);
  final Color _textSecondary = const Color(0xFF6B7280);
  final Color _cardColor = Colors.white;

  String _selectedDataType = 'patients';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Export Records',
          style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Export Database Records',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Export patient records, appointments, and medical data',
              style: TextStyle(fontSize: 14, color: _textSecondary),
            ),
            const SizedBox(height: 32),

            // Data Type Selection
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Data Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDataTypeOption(
                    'patients',
                    'Patient Records',
                    'Export all patient information and demographics',
                    Icons.people,
                  ),
                  _buildDataTypeOption(
                    'appointments',
                    'Appointments',
                    'Export appointment history and schedules',
                    Icons.calendar_today,
                  ),
                  _buildDataTypeOption(
                    'diagnoses',
                    'Medical Records',
                    'Export diagnoses, prescriptions, and treatments',
                    Icons.medical_services,
                  ),
                  _buildDataTypeOption(
                    'transactions',
                    'Transactions',
                    'Export payment and billing records',
                    Icons.account_balance_wallet,
                  ),
                  _buildDataTypeOption(
                    'all',
                    'Complete Database',
                    'Export all records from all collections',
                    Icons.storage,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Date Range Selection
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date Range (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField('Start Date', _startDate, (
                          date,
                        ) {
                          setState(() => _startDate = date);
                        }),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateField('End Date', _endDate, (date) {
                          setState(() => _endDate = date);
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Export Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isExporting ? null : _exportData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isExporting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.picture_as_pdf, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Export to PDF',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTypeOption(
    String value,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = _selectedDataType == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedDataType = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? _primaryColor.withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? _primaryColor : _textSecondary,
              size: 24,
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
                      fontWeight: FontWeight.w600,
                      color: isSelected ? _primaryColor : _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 13, color: _textSecondary),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: _primaryColor, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(
    String label,
    DateTime date,
    Function(DateTime) onDateSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              onDateSelected(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: _textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    DateFormat('MMM d, yyyy').format(date),
                    style: TextStyle(fontSize: 14, color: _textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);

    try {
      List<Map<String, dynamic>> data = [];
      int totalRecords = 0;

      if (_selectedDataType == 'all') {
        // Export all collections
        final collections = [
          'users',
          'appointments',
          'diagnoses',
          'transactions',
        ];
        for (var collection in collections) {
          final records = await _fetchCollectionData(collection);
          data.addAll(records);
          totalRecords += records.length;
        }
      } else if (_selectedDataType == 'patients') {
        final snapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'patient')
            .get();
        data = snapshot.docs.map((doc) {
          final docData = _convertTimestamps(doc.data());
          docData['id'] = doc.id;
          return docData;
        }).toList();
        totalRecords = data.length;
      } else {
        data = await _fetchCollectionData(_selectedDataType);
        totalRecords = data.length;
      }

      // Generate PDF
      final pdf = await _generatePDF(data, totalRecords);

      // Save PDF bytes
      final bytes = await pdf.save();

      // Create filename with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName =
          '${_getDataTypeName().replaceAll(' ', '_')}_$timestamp.pdf';

      // Save PDF to file
      if (mounted) {
        // For desktop testing - just show success and save info
        // On mobile, this would use platform-specific file saving
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PDF generated successfully!'),
                SizedBox(height: 4),
                Text('File: $fileName', style: TextStyle(fontSize: 12)),
                SizedBox(height: 4),
                Text(
                  'Note: File saving requires mobile device or emulator',
                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ],
            ),
            backgroundColor: _successColor,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: _errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchCollectionData(
    String collection,
  ) async {
    final snapshot = await _firestore.collection(collection).get();
    return snapshot.docs.map((doc) {
      final data = _convertTimestamps(doc.data());
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Map<String, dynamic> _convertTimestamps(Map<String, dynamic> data) {
    final converted = <String, dynamic>{};
    data.forEach((key, value) {
      if (value is Timestamp) {
        converted[key] = value.toDate().toIso8601String();
      } else if (value is Map) {
        converted[key] = _convertTimestamps(value as Map<String, dynamic>);
      } else if (value is List) {
        converted[key] = value.map((item) {
          if (item is Timestamp) {
            return item.toDate().toIso8601String();
          } else if (item is Map) {
            return _convertTimestamps(item as Map<String, dynamic>);
          }
          return item;
        }).toList();
      } else {
        converted[key] = value;
      }
    });
    return converted;
  }

  Future<pw.Document> _generatePDF(
    List<Map<String, dynamic>> data,
    int totalRecords,
  ) async {
    final pdf = pw.Document();

    // Load a font that supports Unicode
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    // Header information
    final now = DateTime.now();
    final dateStr = DateFormat('MMMM d, yyyy - h:mm a').format(now);

    // Define text styles with Unicode font
    final titleStyle = pw.TextStyle(
      fontSize: 24,
      fontWeight: pw.FontWeight.bold,
      font: fontBold,
    );
    final headerStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 9,
      font: fontBold,
    );
    final cellStyle = pw.TextStyle(fontSize: 8, font: font);
    final smallStyle = pw.TextStyle(fontSize: 10, font: font);

    if (_selectedDataType == 'patients') {
      // Patient Records PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            // Title
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Patient Records Export', style: titleStyle),
                  pw.SizedBox(height: 8),
                  pw.Text('Generated: $dateStr', style: smallStyle),
                  pw.Text('Total Records: $totalRecords', style: smallStyle),
                  pw.Divider(thickness: 2),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            // Patient Table
            pw.Table.fromTextArray(
              headerStyle: headerStyle,
              cellStyle: cellStyle,
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellHeight: 25,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerLeft,
              },
              headers: ['Name', 'Email', 'Phone', 'Birthdate', 'Gender'],
              data: data.map((patient) {
                return [
                  patient['fullName'] ?? patient['name'] ?? 'N/A',
                  patient['email'] ?? 'N/A',
                  patient['phone'] ?? 'N/A',
                  patient['birthdate'] ?? 'N/A',
                  patient['gender'] ?? 'N/A',
                ];
              }).toList(),
            ),
          ],
        ),
      );
    } else if (_selectedDataType == 'appointments') {
      // Appointments PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Appointments Export', style: titleStyle),
                  pw.SizedBox(height: 8),
                  pw.Text('Generated: $dateStr', style: smallStyle),
                  pw.Text('Total Records: $totalRecords', style: smallStyle),
                  pw.Divider(thickness: 2),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headerStyle: headerStyle,
              cellStyle: cellStyle,
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellHeight: 25,
              headers: ['Date', 'Patient', 'Doctor', 'Status', 'Type'],
              data: data.map((appt) {
                return [
                  appt['appointmentDate'] ?? 'N/A',
                  appt['patientName'] ?? 'N/A',
                  appt['doctorName'] ?? 'N/A',
                  appt['status'] ?? 'N/A',
                  appt['appointmentType'] ?? 'N/A',
                ];
              }).toList(),
            ),
          ],
        ),
      );
    } else if (_selectedDataType == 'diagnoses') {
      // Medical Records PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Medical Records Export', style: titleStyle),
                  pw.SizedBox(height: 8),
                  pw.Text('Generated: $dateStr', style: smallStyle),
                  pw.Text('Total Records: $totalRecords', style: smallStyle),
                  pw.Divider(thickness: 2),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headerStyle: headerStyle,
              cellStyle: cellStyle,
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellHeight: 30,
              headers: ['Date', 'Diagnosis', 'Severity', 'Prescription'],
              data: data.map((diag) {
                return [
                  diag['createdAt'] ?? 'N/A',
                  diag['diagnosis'] ?? 'N/A',
                  diag['severity'] ?? 'N/A',
                  (diag['prescription'] ?? 'N/A').toString().substring(
                    0,
                    (diag['prescription'] ?? 'N/A').toString().length > 30
                        ? 30
                        : (diag['prescription'] ?? 'N/A').toString().length,
                  ),
                ];
              }).toList(),
            ),
          ],
        ),
      );
    } else if (_selectedDataType == 'transactions') {
      // Transactions PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Transactions Export', style: titleStyle),
                  pw.SizedBox(height: 8),
                  pw.Text('Generated: $dateStr', style: smallStyle),
                  pw.Text('Total Records: $totalRecords', style: smallStyle),
                  pw.Divider(thickness: 2),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headerStyle: headerStyle,
              cellStyle: cellStyle,
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellHeight: 25,
              headers: ['Date', 'Type', 'Amount', 'Status', 'Payment Method'],
              data: data.map((trans) {
                return [
                  trans['createdAt'] ?? 'N/A',
                  trans['type'] ?? 'N/A',
                  '₱${trans['amount'] ?? 0}',
                  trans['status'] ?? 'N/A',
                  trans['paymentMethod'] ?? 'N/A',
                ];
              }).toList(),
            ),
          ],
        ),
      );
    } else {
      // Complete Database - Summary
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Complete Database Export', style: titleStyle),
                  pw.SizedBox(height: 8),
                  pw.Text('Generated: $dateStr', style: smallStyle),
                  pw.Text('Total Records: $totalRecords', style: smallStyle),
                  pw.Divider(thickness: 2),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Complete database exported with all collections.',
              style: pw.TextStyle(fontSize: 12, font: font),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'This export contains data from: Users, Appointments, Diagnoses, and Transactions.',
              style: smallStyle,
            ),
          ],
        ),
      );
    }

    return pdf;
  }

  void _showExportDialog(String jsonData, int recordCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: _successColor, size: 28),
            const SizedBox(width: 12),
            const Text('Export Complete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Successfully exported $recordCount records'),
            const SizedBox(height: 16),
            Text(
              'Data Type: ${_getDataTypeName()}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Date Range: ${DateFormat('MMM d, yyyy').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
              style: TextStyle(color: _textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: _primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Data is ready. You can copy the JSON below.',
                      style: TextStyle(fontSize: 12, color: _textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  jsonData,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: _textSecondary)),
          ),
        ],
      ),
    );
  }

  String _getDataTypeName() {
    switch (_selectedDataType) {
      case 'patients':
        return 'Patient Records';
      case 'appointments':
        return 'Appointments';
      case 'diagnoses':
        return 'Medical Records';
      case 'transactions':
        return 'Transactions';
      case 'all':
        return 'Complete Database';
      default:
        return _selectedDataType;
    }
  }
}

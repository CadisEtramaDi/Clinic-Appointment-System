import 'package:clinic/models/transaction_model.dart';
import 'package:clinic/services/transaction_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final TransactionService _transactionService = TransactionService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _filterStatus = 'all';

  Color get _backgroundColor => Colors.grey.shade50;
  Color get _cardColor => Colors.white;
  Color get _primaryColor => Colors.blue;
  Color get _textPrimary => Colors.grey.shade900;
  Color get _textSecondary => Colors.grey.shade600;
  Color get _successColor => Colors.green.shade600;
  Color get _warningColor => Colors.orange.shade600;
  Color get _errorColor => Colors.red.shade600;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        elevation: 0,
        title: Text(
          'Transactions',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Cleanup Bills',
            icon: Icon(Icons.cleaning_services_outlined, color: _textPrimary),
            onPressed: _confirmCleanup,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsSection(),
          _buildFilterChips(),
          Expanded(child: _buildTransactionsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionDialog(),
        backgroundColor: _primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Transaction',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _confirmCleanup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cleanup Consultation Bills?'),
        content: const Text(
          'This will remove consultation bills created at booking and keep only one per completed appointment (preferring paid or latest). This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.cleaning_services),
            label: const Text('Run Cleanup'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await _transactionService
          .cleanupConsultationTransactions();
      if (!mounted) return;
      Navigator.pop(context); // close progress
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cleanup complete: deleted ${result['deleted']} of ${result['examined']} (groups ${result['groups']}).',
          ),
          backgroundColor: _successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cleanup failed: $e'),
          backgroundColor: _errorColor,
        ),
      );
    }
  }

  Widget _buildStatsSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _transactionService.getTransactionStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 120);
        }

        final stats = snapshot.data!;
        return Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
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
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem(
                    'Total',
                    '₱${stats['totalAmount'].toStringAsFixed(2)}',
                    _primaryColor,
                  ),
                  _buildStatItem(
                    'Paid',
                    '₱${stats['paidAmount'].toStringAsFixed(2)}',
                    _successColor,
                  ),
                  _buildStatItem(
                    'Pending',
                    '₱${stats['pendingAmount'].toStringAsFixed(2)}',
                    _warningColor,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: _textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildFilterChip('All', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Pending', 'pending'),
          const SizedBox(width: 8),
          _buildFilterChip('Paid', 'paid'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
      selectedColor: _primaryColor.withOpacity(0.2),
      checkmarkColor: _primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? _primaryColor : _textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildTransactionsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _filterStatus == 'all'
          ? _transactionService.getAllTransactions()
          : _filterStatus == 'pending'
          ? _transactionService.getPendingReviewTransactions()
          : _transactionService.getTransactionsByStatus(_filterStatus),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: _primaryColor));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: _textSecondary),
                const SizedBox(height: 16),
                Text(
                  'No transactions found',
                  style: TextStyle(fontSize: 16, color: _textSecondary),
                ),
              ],
            ),
          );
        }

        final transactions =
            snapshot.data!.docs
                .map((doc) => TransactionModel.fromFirestore(doc))
                .toList()
              ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            return _buildTransactionCard(transactions[index]);
          },
        );
      },
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    final statusColor = _statusColor(transaction.status);

    return InkWell(
      onTap: () => _showTransactionDetails(transaction),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, size: 16, color: _textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              transaction.patientName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (transaction.doctorName != null &&
                          transaction.doctorName!.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.medical_services,
                              size: 14,
                              color: _textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Dr. ${transaction.doctorName}',
                              style: TextStyle(
                                fontSize: 12,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₱${transaction.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        transaction.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.description, size: 14, color: _textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          transaction.description,
                          style: TextStyle(fontSize: 14, color: _textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.category, size: 14, color: _textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        _formatType(transaction.type),
                        style: TextStyle(fontSize: 12, color: _textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: _textSecondary),
                const SizedBox(width: 4),
                Text(
                  DateFormat(
                    'MMM dd, yyyy • hh:mm a',
                  ).format(transaction.transactionDate),
                  style: TextStyle(fontSize: 12, color: _textSecondary),
                ),
                const SizedBox(width: 16),
                Icon(Icons.payment, size: 14, color: _textSecondary),
                const SizedBox(width: 4),
                Text(
                  _formatPaymentMethod(transaction.paymentMethod),
                  style: TextStyle(fontSize: 12, color: _textSecondary),
                ),
              ],
            ),
            if (_isPendingReview(transaction.status)) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _markAsPaid(transaction.id),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Mark as Paid'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _successColor,
                        side: BorderSide(color: _successColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectTransaction(transaction.id),
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _errorColor,
                        side: BorderSide(color: _errorColor),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (transaction.paidDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 14, color: _successColor),
                  const SizedBox(width: 4),
                  Text(
                    'Paid on ${DateFormat('MMM dd, yyyy').format(transaction.paidDate!)}',
                    style: TextStyle(fontSize: 12, color: _successColor),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatType(String type) {
    switch (type.toLowerCase()) {
      case 'consultation':
        return 'Consultation Fee';
      case 'medication':
        return 'Medication/Prescription';
      case 'lab_test':
        return 'Laboratory Test';
      case 'procedure':
        return 'Medical Procedure';
      default:
        return type;
    }
  }

  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Card Payment';
      case 'insurance':
        return 'Insurance';
      case 'online':
        return 'Online Payment';
      default:
        return method;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return _successColor;
      case 'pending':
      case 'pending_cash':
      case 'pending_verification':
        return _warningColor;
      default:
        return _errorColor;
    }
  }

  bool _isPendingReview(String status) {
    return status == 'pending' ||
        status == 'pending_cash' ||
        status == 'pending_verification';
  }

  void _showTransactionDetails(TransactionModel transaction) {
    final statusColor = _statusColor(transaction.status);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transaction Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Transaction ID', transaction.id),
              const Divider(),
              _buildDetailRow('Patient Name', transaction.patientName),
              if (transaction.doctorName != null &&
                  transaction.doctorName!.isNotEmpty)
                _buildDetailRow('Doctor', 'Dr. ${transaction.doctorName}'),
              const Divider(),
              _buildDetailRow(
                'Amount',
                '₱${transaction.amount.toStringAsFixed(2)}',
              ),
              _buildDetailRow('Type', _formatType(transaction.type)),
              _buildDetailRow(
                'Payment Method',
                _formatPaymentMethod(transaction.paymentMethod),
              ),
              if (transaction.gcashReference != null &&
                  transaction.gcashReference!.isNotEmpty)
                _buildDetailRow('GCash Reference', transaction.gcashReference!),
              _buildDetailRowWithColor(
                'Status',
                transaction.status.toUpperCase(),
                statusColor,
              ),
              const Divider(),
              _buildDetailRow('Description', transaction.description),
              _buildDetailRow(
                'Transaction Date',
                DateFormat(
                  'MMMM dd, yyyy • hh:mm a',
                ).format(transaction.transactionDate),
              ),
              if (transaction.paidDate != null)
                _buildDetailRow(
                  'Paid Date',
                  DateFormat(
                    'MMMM dd, yyyy • hh:mm a',
                  ).format(transaction.paidDate!),
                ),
              if (transaction.appointmentId != null &&
                  transaction.appointmentId!.isNotEmpty)
                _buildDetailRow('Appointment ID', transaction.appointmentId!),
            ],
          ),
        ),
        actions: [
          if (_isPendingReview(transaction.status)) ...[
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _rejectTransaction(transaction.id);
              },
              icon: const Icon(Icons.cancel),
              label: const Text('Reject'),
              style: TextButton.styleFrom(foregroundColor: _errorColor),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _markAsPaid(transaction.id);
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Mark as Paid'),
              style: ElevatedButton.styleFrom(backgroundColor: _successColor),
            ),
          ] else
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
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

  Widget _buildDetailRowWithColor(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _cancelTransaction(String transactionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Transaction'),
        content: const Text(
          'Are you sure you want to cancel this transaction?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _errorColor),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _transactionService.cancelTransaction(transactionId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction cancelled')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _rejectTransaction(String transactionId) async {
    try {
      await _transactionService.updateTransactionStatus(
        transactionId,
        'rejected',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Transaction rejected')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _markAsPaid(String transactionId) async {
    try {
      await _transactionService.updateTransactionStatus(transactionId, 'paid');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction marked as paid')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAddTransactionDialog() {
    final patientNameController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedType = 'consultation';
    String selectedPaymentMethod = 'cash';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Transaction'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: patientNameController,
                decoration: const InputDecoration(
                  labelText: 'Patient Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₱',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (patientNameController.text.isEmpty ||
                  amountController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              try {
                await _transactionService.createTransaction(
                  patientId: _auth.currentUser!.uid,
                  patientName: patientNameController.text,
                  amount: double.parse(amountController.text),
                  type: selectedType,
                  paymentMethod: selectedPaymentMethod,
                  description: descriptionController.text,
                );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaction created successfully'),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

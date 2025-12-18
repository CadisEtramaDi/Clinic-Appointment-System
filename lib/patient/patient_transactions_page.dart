import 'package:clinic/models/transaction_model.dart';
import 'package:clinic/services/transaction_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PatientTransactionsPage extends StatefulWidget {
  const PatientTransactionsPage({super.key});

  @override
  State<PatientTransactionsPage> createState() =>
      _PatientTransactionsPageState();
}

class _PatientTransactionsPageState extends State<PatientTransactionsPage> {
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
          'My Transactions',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: _textPrimary),
      ),
      body: Column(
        children: [
          _buildSummarySection(),
          _buildFilterChips(),
          Expanded(child: _buildTransactionsList()),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    final patientId = _auth.currentUser?.uid;
    if (patientId == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: _transactionService.getPatientTransactions(patientId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 100);
        }

        var transactions = snapshot.data!.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList();

        double totalAmount = 0;
        double paidAmount = 0;
        double pendingAmount = 0;

        final pendingStatuses = {
          'pending',
          'pending_cash',
          'pending_verification',
        };

        for (var transaction in transactions) {
          totalAmount += transaction.amount;
          if (transaction.status == 'paid') {
            paidAmount += transaction.amount;
          } else if (pendingStatuses.contains(transaction.status)) {
            pendingAmount += transaction.amount;
          }
        }

        return Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryColor, _primaryColor.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Billing Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryItem(
                    'Total',
                    '₱${totalAmount.toStringAsFixed(2)}',
                    Colors.white,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  _buildSummaryItem(
                    'Paid',
                    '₱${paidAmount.toStringAsFixed(2)}',
                    Colors.white,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  _buildSummaryItem(
                    'Pending',
                    '₱${pendingAmount.toStringAsFixed(2)}',
                    Colors.white,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.8),
            fontWeight: FontWeight.w500,
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
    final patientId = _auth.currentUser?.uid;
    if (patientId == null) {
      return Center(child: Text('Please log in to view transactions'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _transactionService.getPatientTransactions(patientId),
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
                const SizedBox(height: 8),
                Text(
                  'Your billing history will appear here',
                  style: TextStyle(fontSize: 14, color: _textSecondary),
                ),
              ],
            ),
          );
        }

        var transactions = snapshot.data!.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList();

        // Apply filter
        if (_filterStatus != 'all') {
          final pendingSet = {
            'pending',
            'pending_cash',
            'pending_verification',
          };
          transactions = transactions.where((t) {
            if (_filterStatus == 'pending') {
              return pendingSet.contains(t.status);
            }
            return t.status == _filterStatus;
          }).toList();
        }

        // Sort by date (newest first)
        transactions.sort(
          (a, b) => b.transactionDate.compareTo(a.transactionDate),
        );

        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_alt_off, size: 64, color: _textSecondary),
                const SizedBox(height: 16),
                Text(
                  'No $_filterStatus transactions',
                  style: TextStyle(fontSize: 16, color: _textSecondary),
                ),
              ],
            ),
          );
        }

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

    IconData typeIcon;
    Color typeColor;
    switch (transaction.type) {
      case 'consultation':
        typeIcon = Icons.medical_services;
        typeColor = Colors.blue;
        break;
      case 'medication':
        typeIcon = Icons.medication;
        typeColor = Colors.orange;
        break;
      case 'lab_test':
        typeIcon = Icons.biotech;
        typeColor = Colors.purple;
        break;
      case 'procedure':
        typeIcon = Icons.healing;
        typeColor = Colors.red;
        break;
      default:
        typeIcon = Icons.receipt;
        typeColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showTransactionDetails(transaction),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(typeIcon, color: typeColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.description,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (transaction.doctorName != null)
                            Text(
                              transaction.doctorName!,
                              style: TextStyle(
                                fontSize: 14,
                                color: _textSecondary,
                              ),
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
                            fontSize: 18,
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
                Divider(height: 1, color: _textSecondary.withOpacity(0.1)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: _textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat(
                        'MMM dd, yyyy',
                      ).format(transaction.transactionDate),
                      style: TextStyle(fontSize: 12, color: _textSecondary),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.payment, size: 14, color: _textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      transaction.paymentMethod.toUpperCase(),
                      style: TextStyle(fontSize: 12, color: _textSecondary),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, size: 20, color: _textSecondary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(TransactionModel transaction) {
    final statusColor = _statusColor(transaction.status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: _textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Description', transaction.description),
            _buildDetailRow(
              'Amount',
              '₱${transaction.amount.toStringAsFixed(2)}',
            ),
            _buildDetailRow('Type', transaction.type.toUpperCase()),
            _buildDetailRow(
              'Status',
              transaction.status.toUpperCase(),
              valueColor: statusColor,
            ),
            _buildDetailRow(
              'Payment Method',
              transaction.paymentMethod.toUpperCase(),
            ),
            _buildDetailRow(
              'Date',
              DateFormat('MMMM dd, yyyy').format(transaction.transactionDate),
            ),
            if (transaction.doctorName != null)
              _buildDetailRow('Doctor', transaction.doctorName!),
            if (transaction.paidDate != null)
              _buildDetailRow(
                'Paid Date',
                DateFormat('MMMM dd, yyyy').format(transaction.paidDate!),
              ),
            const SizedBox(height: 24),
            if (transaction.status == 'pending')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showPaymentDialog(transaction);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Pay Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: valueColor ?? _textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(TransactionModel transaction) {
    String selectedPaymentMethod = 'cash';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.payment, color: _primaryColor),
              const SizedBox(width: 8),
              const Text('Select Payment Method'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Amount to Pay:',
                      style: TextStyle(
                        fontSize: 14,
                        color: _textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '₱${transaction.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Choose how you want to pay:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildPaymentOption(
                'cash',
                'Cash',
                Icons.money,
                selectedPaymentMethod,
                (value) => setState(() => selectedPaymentMethod = value),
              ),
              const SizedBox(height: 8),
              _buildPaymentOption(
                'gcash',
                'GCash',
                Icons.phone_android,
                selectedPaymentMethod,
                (value) => setState(() => selectedPaymentMethod = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: _textSecondary)),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);

                // Different process for each payment method
                if (selectedPaymentMethod == 'cash') {
                  _processCashPayment(transaction);
                } else if (selectedPaymentMethod == 'gcash') {
                  _processGCashPayment(transaction);
                }
              },
              icon: const Icon(Icons.arrow_forward, color: Colors.white),
              label: const Text(
                'Proceed to Payment',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Process Cash Payment
  void _processCashPayment(TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.money, color: _primaryColor),
            const SizedBox(width: 8),
            const Text('Cash Payment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 64, color: _warningColor),
            const SizedBox(height: 16),
            Text(
              'Please pay ₱${transaction.amount.toStringAsFixed(2)} in cash at the clinic reception.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: _textPrimary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: _warningColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The admin will confirm your payment after receiving the cash.',
                      style: TextStyle(fontSize: 12, color: _textSecondary),
                    ),
                  ),
                ],
              ),
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
              try {
                // Update to cash payment method and keep as pending
                await FirebaseFirestore.instance
                    .collection('transactions')
                    .doc(transaction.id)
                    .update({
                      'paymentMethod': 'cash',
                      'status': 'pending_cash',
                      'updatedAt': FieldValue.serverTimestamp(),
                    });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Cash payment noted. Please pay at the clinic.',
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: _successColor,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: _errorColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            child: const Text(
              'I Understand',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Process GCash Payment
  void _processGCashPayment(TransactionModel transaction) {
    final referenceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.phone_android, color: _primaryColor),
              const SizedBox(width: 8),
              const Text('GCash Payment'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade700, Colors.blue.shade900],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'SEND PAYMENT TO:',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '0917 123 4567',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Clinic GCash Account',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₱${transaction.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Instructions:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInstruction('1', 'Open your GCash app'),
                _buildInstruction('2', 'Send money to the number above'),
                _buildInstruction('3', 'Enter the exact amount shown'),
                _buildInstruction('4', 'Copy the reference number'),
                _buildInstruction('5', 'Paste it below and submit'),
                const SizedBox(height: 20),
                TextField(
                  controller: referenceController,
                  decoration: InputDecoration(
                    labelText: 'GCash Reference Number',
                    hintText: 'e.g., 1234567890',
                    prefixIcon: Icon(Icons.confirmation_number),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (referenceController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter GCash reference number'),
                      backgroundColor: _errorColor,
                    ),
                  );
                  return;
                }

                try {
                  // Update with GCash reference and keep as pending verification
                  await FirebaseFirestore.instance
                      .collection('transactions')
                      .doc(transaction.id)
                      .update({
                        'paymentMethod': 'gcash',
                        'gcashReference': referenceController.text.trim(),
                        'status': 'pending_verification',
                        'updatedAt': FieldValue.serverTimestamp(),
                      });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'GCash payment submitted! Awaiting verification.',
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: _successColor,
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: _errorColor,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.send, color: Colors.white),
              label: const Text(
                'Submit Reference',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildInstruction(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: _textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    String value,
    String label,
    IconData icon,
    String selectedValue,
    Function(String) onSelect,
  ) {
    final isSelected = selectedValue == value;
    return InkWell(
      onTap: () => onSelect(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor.withOpacity(0.1) : _cardColor,
          border: Border.all(
            color: isSelected ? _primaryColor : _textSecondary.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? _primaryColor
                    : _textSecondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : _textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? _primaryColor : _textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: _primaryColor, size: 20),
          ],
        ),
      ),
    );
  }
}

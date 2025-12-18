import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String patientId;
  final String patientName;
  final String? doctorId;
  final String? doctorName;
  final String? appointmentId;
  final double amount;
  final String
  type; // 'consultation', 'medication', 'lab_test', 'procedure', 'other'
  final String status; // 'pending', 'paid', 'cancelled', 'refunded'
  final String paymentMethod; // 'cash', 'card', 'insurance', 'online'
  final String? gcashReference;
  final String description;
  final DateTime transactionDate;
  final DateTime? paidDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TransactionModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.doctorId,
    this.doctorName,
    this.appointmentId,
    required this.amount,
    required this.type,
    required this.status,
    required this.paymentMethod,
    this.gcashReference,
    required this.description,
    required this.transactionDate,
    this.paidDate,
    required this.createdAt,
    this.updatedAt,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel.fromMap(data, doc.id);
  }

  factory TransactionModel.fromMap(Map<String, dynamic> data, [String? docId]) {
    return TransactionModel(
      id: docId ?? data['id'] ?? '',
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      doctorId: data['doctorId'],
      doctorName: data['doctorName'],
      appointmentId: data['appointmentId'],
      amount: (data['amount'] ?? 0).toDouble(),
      type: data['type'] ?? 'other',
      status: data['status'] ?? 'pending',
      paymentMethod: data['paymentMethod'] ?? 'cash',
      gcashReference: data['gcashReference'],
      description: data['description'] ?? '',
      transactionDate: data['transactionDate'] is Timestamp
          ? (data['transactionDate'] as Timestamp).toDate()
          : DateTime.now(),
      paidDate: data['paidDate'] is Timestamp
          ? (data['paidDate'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'appointmentId': appointmentId,
      'amount': amount,
      'type': type,
      'status': status,
      'paymentMethod': paymentMethod,
      'gcashReference': gcashReference,
      'description': description,
      'transactionDate': Timestamp.fromDate(transactionDate),
      'paidDate': paidDate != null ? Timestamp.fromDate(paidDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? doctorId,
    String? doctorName,
    String? appointmentId,
    double? amount,
    String? type,
    String? status,
    String? paymentMethod,
    String? gcashReference,
    String? description,
    DateTime? transactionDate,
    DateTime? paidDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      appointmentId: appointmentId ?? this.appointmentId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      gcashReference: gcashReference ?? this.gcashReference,
      description: description ?? this.description,
      transactionDate: transactionDate ?? this.transactionDate,
      paidDate: paidDate ?? this.paidDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

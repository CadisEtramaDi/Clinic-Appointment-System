# Transaction System Integration

## Overview
The transaction/billing system has been successfully integrated with the appointment booking and diagnosis workflow.

## Features Implemented

### 1. **Automatic Transaction Creation**

#### During Appointment Booking
- When a patient books an appointment, a consultation transaction is automatically created
- **Default Amount**: ₱500.00 (consultation fee)
- **Status**: Pending
- **Type**: Consultation
- **Payment Method**: Cash (default)

**Location**: `lib/patient/book_appointment_page.dart`

#### During Diagnosis with Prescription
- When a doctor adds a prescription during diagnosis, a medication transaction is created
- **Default Amount**: ₱300.00 (medication fee)
- **Status**: Pending
- **Type**: Medication
- **Payment Method**: Cash (default)

**Location**: `lib/doctor/update_diagnosis_page.dart`

### 2. **Transaction Management Pages**

#### Admin Transactions Page (`lib/admin/transactions_page.dart`)
**Features**:
- View all transactions across the system
- Real-time statistics (Total, Paid, Pending amounts)
- Filter by status (All, Pending, Paid)
- Mark transactions as paid
- Add new transactions manually
- Color-coded status indicators

#### Patient Transactions Page (`lib/patient/patient_transactions_page.dart`)
**Features**:
- View personal billing history
- Billing summary card with gradient design
- Filter transactions by status
- Detailed transaction view in modal
- Payment processing dialog
- Type-specific icons (consultation, medication, lab test, procedure)
- Pay Now functionality for pending transactions

### 3. **Transaction Data Structure**

**Transaction Fields**:
- Patient ID and Name
- Doctor ID and Name (optional)
- Appointment ID (links to appointment)
- Amount (₱ Philippine Peso)
- Type (consultation, medication, lab_test, procedure, other)
- Status (pending, paid, cancelled, refunded)
- Payment Method (cash, card, insurance, online)
- Description
- Transaction Date
- Paid Date (when marked as paid)
- Created At / Updated At timestamps

### 4. **Integration Points**

#### Appointment Service
- Modified `bookAppointment()` to return `appointmentId`
- This allows transaction to be linked to the appointment

#### Book Appointment Flow
1. Patient selects date, time, doctor, and reason
2. Appointment is created successfully
3. **NEW**: Consultation transaction is automatically created
4. Transaction is linked to appointment via `appointmentId`
5. Patient receives confirmation with queue number

#### Diagnosis Flow
1. Doctor opens diagnosis page for pending appointment
2. Doctor fills in comprehensive medical form
3. Doctor adds prescription (optional)
4. **NEW**: If prescription is added, medication transaction is created
5. Appointment status updated to "completed"
6. Diagnosis saved to patient's medical records

### 5. **How to Use**

#### For Patients:
1. Navigate to Patient Transactions Page
2. View billing summary and transaction history
3. Click on any transaction to see details
4. For pending transactions, click "Pay Now"
5. Select payment method and confirm payment

#### For Admins:
1. Navigate to Admin Transactions Page (from admin dashboard)
2. View system-wide transaction statistics
3. Filter by status to see pending payments
4. Mark transactions as paid when payment is received
5. Add manual transactions if needed

#### For Doctors:
- Transactions are created automatically when prescriptions are added
- No additional action required during diagnosis
- Can view their revenue through admin transactions page (filtered by doctorId)

### 6. **Navigation**

**To Patient Transactions Page**:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const PatientTransactionsPage(),
  ),
);
```

**To Admin Transactions Page**:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const TransactionsPage(),
  ),
);
```

### 7. **Default Fees**
You can customize these in the code:
- **Consultation Fee**: ₱500.00 (in `book_appointment_page.dart`)
- **Medication Fee**: ₱300.00 (in `update_diagnosis_page.dart`)

To change the default fees, search for:
```dart
amount: 500.0, // Default consultation fee
amount: 300.0, // Default medication fee
```

### 8. **Payment Status Workflow**

```
[Pending] → [Paid]
    ↓
[Cancelled/Refunded] (manual admin action)
```

### 9. **Transaction Service Methods**

Available methods in `TransactionService`:
- `createTransaction()` - Create new transaction
- `markAsPaid()` - Update to paid status
- `updateTransactionStatus()` - Update any status
- `getPatientTransactions()` - Stream for patient view
- `getDoctorTransactions()` - Stream for doctor view
- `getAllTransactions()` - Stream for admin view
- `getTransactionStats()` - Calculate financial statistics
- `getAppointmentTransactions()` - Get all transactions for an appointment
- `getTransactionsByStatus()` - Filter by status
- `deleteTransaction()` - Remove transaction

### 10. **Firestore Collections**

**transactions** collection structure:
```
transactions/
  {transactionId}/
    - id
    - patientId
    - patientName
    - doctorId
    - doctorName
    - appointmentId
    - amount
    - type
    - status
    - paymentMethod
    - description
    - transactionDate
    - paidDate
    - createdAt
    - updatedAt
```

### 11. **Error Handling**

- Transaction creation failures don't block appointment booking
- Errors are logged to console for debugging
- User-friendly error messages displayed in UI
- Graceful fallbacks for missing data

### 12. **Future Enhancements**

Possible additions:
- Invoice generation (PDF export)
- Email receipts
- Payment gateway integration
- Discount/coupon system
- Insurance claim processing
- Multi-currency support
- Payment installments
- Revenue reports and charts
- Export to CSV/Excel
- Receipt printing

## Files Modified/Created

**Created**:
1. `lib/models/transaction_model.dart` - Transaction data model
2. `lib/services/transaction_service.dart` - Transaction business logic
3. `lib/admin/transactions_page.dart` - Admin transaction management
4. `lib/patient/patient_transactions_page.dart` - Patient billing view

**Modified**:
1. `lib/patient/book_appointment_page.dart` - Added transaction creation on booking
2. `lib/doctor/update_diagnosis_page.dart` - Added transaction for medications
3. `lib/services/appointment_service.dart` - Return appointmentId

## Testing Checklist

- [x] Book appointment creates consultation transaction
- [x] Transaction is linked to appointment
- [x] Add prescription creates medication transaction
- [x] Patient can view their transactions
- [x] Patient can see billing summary
- [x] Patient can filter transactions by status
- [x] Patient can view transaction details
- [x] Patient can pay pending transactions
- [x] Admin can view all transactions
- [x] Admin can see statistics
- [x] Admin can mark as paid
- [x] Admin can add manual transactions
- [ ] Multiple transactions per appointment (consultation + medication)
- [ ] Transaction updates reflect in real-time
- [ ] Payment method selection works correctly

## Notes

- All amounts are in Philippine Peso (₱)
- Transactions are created automatically, no manual intervention needed
- Real-time updates using Firestore streams
- Color-coded UI for better UX (green=paid, orange=pending, red=cancelled)
- Transaction IDs are auto-generated by Firestore
- Timestamps use Firestore server time for consistency

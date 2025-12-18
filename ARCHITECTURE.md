# Admin Record Management System Architecture

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    ADMIN DASHBOARD UI LAYER                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Dashboard    │  │ Quick Actions│  │ Navigation   │          │
│  │ Main Page    │  │   Menu       │  │   Bar        │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ADMIN UI PAGES LAYER                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐│
│  │ Quality Check   │  │ Record Transfer │  │  Analytics &    ││
│  │ Page            │  │ Management Page │  │  Reports Page   ││
│  └─────────────────┘  └─────────────────┘  └─────────────────┘│
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐                      │
│  │ Archival        │  │ Audit Trail     │                      │
│  │ Management Page │  │ Page            │                      │
│  └─────────────────┘  └─────────────────┘                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│               BUSINESS LOGIC & SERVICE LAYER                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  PatientRecordManagementService                          │  │
│  │  ┌────────────────────────────────────────────────────┐  │  │
│  │  │ • Record Management (CRUD)                         │  │  │
│  │  │ • Data Validation & Completeness Checks           │  │  │
│  │  │ • Transfer Request Processing                     │  │  │
│  │  │ • Archive/Restore Operations                      │  │  │
│  │  │ • Audit Log Creation & Retrieval                  │  │  │
│  │  │ • Reports & Analytics Generation                  │  │  │
│  │  └────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    DATA MODELS LAYER                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────┐  ┌──────────────────┐                   │
│  │ PatientRecord    │  │ RecordTransfer   │                   │
│  │ Model            │  │ Request Model    │                   │
│  │                  │  │                  │                   │
│  │ • Basic Info     │  │ • Request ID     │                   │
│  │ • Health Data    │  │ • Doctor Info    │                   │
│  │ • Status         │  │ • Reason         │                   │
│  │ • Timestamps     │  │ • Status         │                   │
│  │ • Completeness   │  │ • Timestamps     │                   │
│  └──────────────────┘  └──────────────────┘                   │
│                                                                 │
│  ┌──────────────────┐                                          │
│  │ AuditLog         │                                          │
│  │ Model            │                                          │
│  │                  │                                          │
│  │ • Admin Info     │                                          │
│  │ • Action Type    │                                          │
│  │ • Patient Info   │                                          │
│  │ • Timestamp      │                                          │
│  │ • Changes        │                                          │
│  └──────────────────┘                                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                  FIREBASE/FIRESTORE LAYER                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────┐  ┌──────────────────┐                   │
│  │ patient_records  │  │ record_transfer  │                   │
│  │ Collection       │  │ _requests Coll.  │                   │
│  │                  │  │                  │                   │
│  │ • CRUD Ops       │  │ • Create         │                   │
│  │ • Queries        │  │ • Query by       │                   │
│  │ • Indexes        │  │   status/patient │                   │
│  │                  │  │ • Update status  │                   │
│  └──────────────────┘  └──────────────────┘                   │
│                                                                 │
│  ┌──────────────────┐                                          │
│  │ audit_logs       │                                          │
│  │ Collection       │                                          │
│  │                  │                                          │
│  │ • Add entry      │                                          │
│  │ • Query by       │                                          │
│  │   criteria       │                                          │
│  │ • Index setup    │                                          │
│  └──────────────────┘                                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Data Flow Diagram

```
┌──────────────┐
│  Admin User  │
└──────┬───────┘
       │
       │ (Action: View Record)
       ▼
┌──────────────────────────────┐
│ Admin Dashboard              │
│ - Clicks Record Quality      │
└──────┬───────────────────────┘
       │
       │ (Calls Service Method)
       ▼
┌──────────────────────────────┐
│ PatientRecordManagementService
│ getAllPatientRecords()        │
└──────┬───────────────────────┘
       │
       │ (Query: dataComplete=false)
       ▼
┌──────────────────────────────┐
│ Firestore                    │
│ patient_records Collection   │
│ (Fetch documents)            │
└──────┬───────────────────────┘
       │
       │ (Return documents)
       ▼
┌──────────────────────────────┐
│ Service - Parse Results      │
│ Create PatientRecord objects │
└──────┬───────────────────────┘
       │
       │ (Return List<PatientRecord>)
       ▼
┌──────────────────────────────┐
│ UI Page                      │
│ Display Records List         │
│ - Show missing fields        │
│ - Enable edit button         │
└──────┬───────────────────────┘
       │
       │ (Admin clicks "Complete Record")
       ▼
┌──────────────────────────────┐
│ Admin Updates Fields         │
│ - Adds missing info          │
│ - Submits form               │
└──────┬───────────────────────┘
       │
       │ (Calls updatePatientRecordWithValidation)
       ▼
┌──────────────────────────────────────┐
│ Service - Validate Record            │
│ - Check all required fields          │
│ - Update completeness flag           │
│ - Set missingFields list             │
└──────┬───────────────────────────────┘
       │
       │ (Save to Firestore)
       ▼
┌──────────────────────────────────────┐
│ Firestore - Save PatientRecord       │
│ - Update patient_records document    │
│ - Set updatedAt timestamp            │
└──────┬───────────────────────────────┘
       │
       │ (Log audit entry)
       ▼
┌──────────────────────────────────────┐
│ Service - Log Audit Action           │
│ - Create AuditLog object             │
│ - Include: admin, action, patient    │
│ - Set timestamp and status           │
└──────┬───────────────────────────────┘
       │
       │ (Save to Firestore)
       ▼
┌──────────────────────────────────────┐
│ Firestore - Save AuditLog            │
│ - Add entry to audit_logs collection │
│ - Indexed for queries                │
└──────┬───────────────────────────────┘
       │
       │ (Return success)
       ▼
┌──────────────────────────────────────┐
│ UI - Show Confirmation               │
│ - Success snackbar                   │
│ - Refresh record list                │
└──────────────────────────────────────┘
```

---

## Service Layer Organization

```
PatientRecordManagementService
│
├─ RECORD MANAGEMENT
│  ├─ getAllPatientRecords(...)
│  ├─ getPatientRecord(patientId)
│  └─ savePatientRecord(record)
│
├─ DATA VALIDATION
│  ├─ validateRecordCompleteness(record)
│  └─ updatePatientRecordWithValidation(...)
│
├─ TRANSFER MANAGEMENT
│  ├─ createRecordTransferRequest(...)
│  ├─ getRecordTransferRequests(...)
│  ├─ approveTransferRequest(...)
│  └─ rejectTransferRequest(...)
│
├─ ARCHIVAL OPERATIONS
│  ├─ archivePatientRecord(...)
│  ├─ getArchivedRecords()
│  └─ restoreArchivedRecord(...)
│
├─ AUDIT OPERATIONS
│  ├─ logAuditAction(...)
│  ├─ getAuditLogs(...)
│  └─ getPatientAuditTrail(...)
│
└─ REPORTS & ANALYTICS
   ├─ generateDataQualityReport()
   ├─ generateActivityReport(...)
   ├─ getPatientsRequiringCompletion()
   └─ getRecentlyUpdatedRecords(...)
```

---

## Database Schema

```
firestore_root/
│
├─ patient_records/
│  │
│  └─ {patientId}/ (Document)
│     ├─ id: String
│     ├─ patientId: String
│     ├─ patientName: String
│     ├─ email: String
│     ├─ phone: String
│     ├─ dateOfBirth: String
│     ├─ gender: String
│     ├─ bloodType: String
│     ├─ emergencyContact: String
│     ├─ emergencyContactPhone: String
│     ├─ allergies: Array
│     ├─ chronicConditions: Array
│     ├─ insuranceProvider: String
│     ├─ insurancePolicyNumber: String
│     ├─ primaryDoctorId: String
│     ├─ primaryDoctorName: String
│     ├─ lastVisitDate: Timestamp
│     ├─ nextAppointmentDate: Timestamp
│     ├─ recordStatus: String (active|inactive|archived)
│     ├─ dataComplete: Boolean
│     ├─ missingFields: Array
│     ├─ createdAt: Timestamp
│     ├─ updatedAt: Timestamp
│     └─ archivedAt: Timestamp
│
├─ record_transfer_requests/
│  │
│  └─ {requestId}/ (Document)
│     ├─ id: String
│     ├─ patientId: String
│     ├─ patientName: String
│     ├─ fromDoctorId: String
│     ├─ fromDoctorName: String
│     ├─ toDoctorId: String
│     ├─ toDoctorName: String
│     ├─ reason: String
│     ├─ status: String (pending|approved|rejected|completed)
│     ├─ requestDate: Timestamp
│     ├─ completedDate: Timestamp
│     ├─ approvalNotes: String
│     └─ rejectionReason: String
│
└─ audit_logs/
   │
   └─ {logId}/ (Document)
      ├─ id: String
      ├─ adminId: String
      ├─ adminName: String
      ├─ action: String
      ├─ targetPatientId: String
      ├─ targetPatientName: String
      ├─ description: String
      ├─ changes: Map
      ├─ ipAddress: String
      ├─ timestamp: Timestamp
      ├─ status: String (success|failure)
      └─ errorMessage: String
```

---

## UI Pages Structure

```
admin/
│
├─ admin_dashboard_page.dart
│  │ (Main admin interface)
│  └─ Quick Action Cards
│     ├─ Data Quality
│     ├─ Record Transfers
│     ├─ Analytics
│     ├─ Record Archive
│     └─ Audit Trail
│
├─ record_quality_check_page.dart
│  │ (Data validation interface)
│  └─ Components
│     ├─ Summary Card
│     └─ Record List
│        └─ Missing Fields Display
│
├─ record_transfer_management_page.dart
│  │ (Transfer workflow)
│  └─ Components
│     ├─ Transfer Request Card
│     ├─ Transfer Details
│     └─ Approve/Reject Buttons
│
├─ health_reports_and_analytics_page.dart
│  │ (Reports dashboard)
│  └─ Components
│     ├─ Data Quality Section
│     │  └─ Metrics Cards & Charts
│     └─ Activity Report Section
│        └─ Action Breakdown
│
├─ record_archival_management_page.dart
│  │ (Archive management)
│  └─ Components
│     ├─ Tab: Active Records
│     ├─ Tab: Archived Records
│     └─ Record Cards
│        └─ Archive/Restore Buttons
│
└─ audit_trail_page.dart
   │ (Audit logging)
   └─ Components
      ├─ Filter Panel
      │  ├─ Action Type Chips
      │  └─ Date Range Picker
      └─ Audit Log List
         └─ Log Entry Cards
```

---

## Error Handling Flow

```
┌─────────────────┐
│ Admin Action    │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────┐
│ Service Method Call             │
└────────┬────────────────────────┘
         │
    ┌────▼─────┐
    │   TRY    │
    └────┬─────┘
         │
    ┌────▼──────────────────┐
    │ Attempt Operation     │
    └────┬──────────────────┘
         │
    ┌────▼────────┐
    │ Success?    │
    └─┬──────────┬┘
      │          │
     YES        NO
      │          │
      │     ┌────▼──────────┐
      │     │ CATCH Error   │
      │     └────┬──────────┘
      │          │
      │     ┌────▼──────────────┐
      │     │ Log Error Message │
      │     └────┬──────────────┘
      │          │
      │     ┌────▼──────────────┐
      │     │ Throw Exception   │
      │     └────┬──────────────┘
      │          │
      │     ┌────▼──────────────┐
      └─────► UI Catches Error  │
            └────┬──────────────┘
                 │
            ┌────▼──────────────┐
            │ Show Error Snack  │
            │ Bar to User       │
            └───────────────────┘
```

---

## State Management Flow

```
UI Page Widget
│
├─ StatefulWidget
│  │
│  ├─ State Variables
│  │  ├─ Future<List<T>> _data
│  │  ├─ bool _isLoading
│  │  └─ String _error
│  │
│  ├─ initState()
│  │  └─ Load initial data
│  │
│  ├─ _refreshData()
│  │  └─ Reload on user action
│  │
│  └─ build()
│     └─ FutureBuilder<T>
│        ├─ waiting state
│        │  └─ Show spinner
│        ├─ data state
│        │  └─ Display content
│        └─ error state
│           └─ Show error message
│
└─ Dialog/Modal
   └─ Local state
      ├─ TextEditingControllers
      ├─ Form validation
      └─ Submit callback
```

---

## Firestore Query Patterns

```
// Get all records with status filter
Query: patient_records
  where: recordStatus == 'active'
  orderBy: patientName

// Get incomplete records
Query: patient_records
  where: dataComplete == false
  orderBy: patientName

// Get audit logs for patient
Query: audit_logs
  where: targetPatientId == patientId
  orderBy: timestamp DESC
  limit: 50

// Get transfer requests by status
Query: record_transfer_requests
  where: status == 'pending'
  orderBy: requestDate DESC

// Get activity in date range
Query: audit_logs
  where: timestamp >= startDate
  where: timestamp <= endDate
  orderBy: timestamp DESC
```

---

## Summary

This architecture provides:
- ✓ Clean separation of concerns
- ✓ Scalable data layer
- ✓ Comprehensive logging
- ✓ Flexible querying
- ✓ Error handling
- ✓ Type safety
- ✓ Compliance tracking

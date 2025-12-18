import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalRecordsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new diagnosis for a patient
  Future<void> addDiagnosis({
    required String patientId,
    required String diagnosis,
    required String notes,
    required String severity, // mild, moderate, severe
    required List<String> medications,
    bool followUpRequired = false,
    String? symptoms,
    String? allergies,
    String? icdCode,
    String? treatmentPlan,
    String? vitals,
    String? prescription,
  }) async {
    try {
      await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('diagnoses')
          .add({
            'diagnosis': diagnosis,
            'notes': notes,
            'severity': severity,
            'medications': medications,
            'followUpRequired': followUpRequired,
            'symptoms': symptoms ?? '',
            'allergies': allergies ?? '',
            'icdCode': icdCode ?? '',
            'treatmentPlan': treatmentPlan ?? '',
            'vitals': vitals ?? '',
            'prescription': prescription ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'status': 'active',
          });
    } catch (e) {
      throw Exception('Error adding diagnosis: $e');
    }
  }

  // Get patient's medical history
  Future<List<Map<String, dynamic>>> getPatientMedicalHistory(
    String patientId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('diagnoses')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      throw Exception('Error fetching medical history: $e');
    }
  }

  // Add prescription
  Future<void> addPrescription({
    required String patientId,
    required String medicationName,
    required String dosage,
    required String frequency,
    required int durationDays,
    required String notes,
    required bool needsESignature,
  }) async {
    try {
      await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('prescriptions')
          .add({
            'medicationName': medicationName,
            'dosage': dosage,
            'frequency': frequency,
            'durationDays': durationDays,
            'notes': notes,
            'needsESignature': needsESignature,
            'createdAt': FieldValue.serverTimestamp(),
            'status': 'active',
            'eSignatureVerified': false,
          });
    } catch (e) {
      throw Exception('Error adding prescription: $e');
    }
  }

  // Get prescriptions for a patient
  Future<List<Map<String, dynamic>>> getPatientPrescriptions(
    String patientId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('prescriptions')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      throw Exception('Error fetching prescriptions: $e');
    }
  }

  // Add treatment plan
  Future<void> addTreatmentPlan({
    required String patientId,
    required String planName,
    required String description,
    required List<String> procedures,
    required int estimatedDurationDays,
    required String priority, // low, medium, high
  }) async {
    try {
      await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('treatmentPlans')
          .add({
            'planName': planName,
            'description': description,
            'procedures': procedures,
            'estimatedDurationDays': estimatedDurationDays,
            'priority': priority,
            'createdAt': FieldValue.serverTimestamp(),
            'status': 'active',
          });
    } catch (e) {
      throw Exception('Error adding treatment plan: $e');
    }
  }

  // Get treatment plans for a patient
  Future<List<Map<String, dynamic>>> getPatientTreatmentPlans(
    String patientId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('treatmentPlans')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      throw Exception('Error fetching treatment plans: $e');
    }
  }

  // Add lab order
  Future<void> addLabOrder({
    required String patientId,
    required String testName,
    required String testType, // blood, urine, imaging, etc.
    required String description,
    required String priority,
    required List<String> requiredTests,
  }) async {
    try {
      await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('labOrders')
          .add({
            'testName': testName,
            'testType': testType,
            'description': description,
            'priority': priority,
            'requiredTests': requiredTests,
            'createdAt': FieldValue.serverTimestamp(),
            'status': 'pending',
            'completedAt': null,
            'results': null,
          });
    } catch (e) {
      throw Exception('Error adding lab order: $e');
    }
  }

  // Get lab orders for a patient
  Future<List<Map<String, dynamic>>> getPatientLabOrders(
    String patientId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('labOrders')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      throw Exception('Error fetching lab orders: $e');
    }
  }

  // Add medical image reference (without file upload)
  Future<void> addMedicalImageReference({
    required String patientId,
    required String imageType, // xray, scan, photo, etc.
    required String description,
    required String imageUrl, // External URL or stored path
  }) async {
    try {
      await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('medicalImages')
          .add({
            'imageType': imageType,
            'description': description,
            'imageUrl': imageUrl,
            'uploadedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Error adding medical image reference: $e');
    }
  }

  // Get medical images for a patient
  Future<List<Map<String, dynamic>>> getPatientMedicalImages(
    String patientId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('medicalImages')
          .orderBy('uploadedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      throw Exception('Error fetching medical images: $e');
    }
  }

  // Add doctor notes
  Future<void> addDoctorNotes({
    required String patientId,
    required String notes,
    required String appointmentId,
  }) async {
    try {
      await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('doctorNotes')
          .add({
            'notes': notes,
            'appointmentId': appointmentId,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Error adding doctor notes: $e');
    }
  }

  // Get doctor notes for a patient
  Future<List<Map<String, dynamic>>> getPatientDoctorNotes(
    String patientId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('doctorNotes')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      throw Exception('Error fetching doctor notes: $e');
    }
  }

  // Digital prescription with e-signature
  Future<void> generateDigitalPrescription({
    required String patientId,
    required List<Map<String, String>> medications,
    required String notes,
    required String doctorSignature, // Base64 encoded signature
  }) async {
    try {
      await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('digitalPrescriptions')
          .add({
            'medications': medications,
            'notes': notes,
            'doctorSignature': doctorSignature,
            'createdAt': FieldValue.serverTimestamp(),
            'status': 'signed',
            'expiryDate': DateTime.now().add(Duration(days: 90)),
          });
    } catch (e) {
      throw Exception('Error generating digital prescription: $e');
    }
  }

  // Get digital prescriptions
  Future<List<Map<String, dynamic>>> getDigitalPrescriptions(
    String patientId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('digitalPrescriptions')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      throw Exception('Error fetching digital prescriptions: $e');
    }
  }

  // Update lab results
  Future<void> updateLabResults({
    required String patientId,
    required String labOrderId,
    required Map<String, dynamic> results,
  }) async {
    try {
      await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('labOrders')
          .doc(labOrderId)
          .update({
            'results': results,
            'status': 'completed',
            'completedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Error updating lab results: $e');
    }
  }

  // Get diagnosis by ID
  Future<Map<String, dynamic>?> getDiagnosisById(
    String patientId,
    String diagnosisId,
  ) async {
    try {
      final doc = await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('diagnoses')
          .doc(diagnosisId)
          .get();

      if (!doc.exists) return null;
      return {'id': doc.id, ...doc.data()!};
    } catch (e) {
      throw Exception('Error fetching diagnosis: $e');
    }
  }

  // Update diagnosis
  Future<void> updateDiagnosis({
    required String patientId,
    required String diagnosisId,
    required String diagnosis,
    required String notes,
    required String severity,
    required List<String> medications,
    bool followUpRequired = false,
    String? symptoms,
    String? allergies,
    String? icdCode,
    String? treatmentPlan,
    String? vitals,
    String? prescription,
  }) async {
    try {
      await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('diagnoses')
          .doc(diagnosisId)
          .update({
            'diagnosis': diagnosis,
            'notes': notes,
            'severity': severity,
            'medications': medications,
            'followUpRequired': followUpRequired,
            'symptoms': symptoms ?? '',
            'allergies': allergies ?? '',
            'icdCode': icdCode ?? '',
            'treatmentPlan': treatmentPlan ?? '',
            'vitals': vitals ?? '',
            'prescription': prescription ?? '',
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Error updating diagnosis: $e');
    }
  }

  // Get previous treatment outcomes
  Future<List<Map<String, dynamic>>> getPreviousTreatmentOutcomes(
    String patientId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('treatmentOutcomes')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      throw Exception('Error fetching treatment outcomes: $e');
    }
  }

  // Add treatment outcome
  Future<void> addTreatmentOutcome({
    required String patientId,
    required String treatmentPlanId,
    required String outcome, // successful, partial, unsuccessful
    required String notes,
    required Map<String, dynamic> metrics,
  }) async {
    try {
      await _firestore
          .collection('patients')
          .doc(patientId)
          .collection('treatmentOutcomes')
          .add({
            'treatmentPlanId': treatmentPlanId,
            'outcome': outcome,
            'notes': notes,
            'metrics': metrics,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Error adding treatment outcome: $e');
    }
  }
}

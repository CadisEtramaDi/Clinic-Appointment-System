# Deployment Guide

## Pre-Deployment Checklist

### Code Quality
- [ ] All tests pass
- [ ] No lint warnings
- [ ] Code formatted properly
- [ ] No console errors
- [ ] Null safety checks pass
- [ ] All imports are used
- [ ] Error handling complete

### Feature Validation
- [ ] All 6 features implemented
- [ ] All UI pages working
- [ ] All service methods tested
- [ ] Database collections created
- [ ] Firestore indexes configured

### Documentation
- [ ] README updated
- [ ] Architecture documented
- [ ] Testing guide created
- [ ] Quick reference guide created
- [ ] Code comments added

### Security
- [ ] Admin role verified
- [ ] Audit logging active
- [ ] Data validation working
- [ ] Error messages don't expose sensitive info
- [ ] Firestore rules configured

---

## Step 1: Setup Firestore Collections

### Create Collections in Firestore Console:

1. **patient_records**
   - Collection: `patient_records`
   - Document ID: Auto-generated
   - Fields: As per PatientRecord model
   - Indexes: Create for queries

2. **record_transfer_requests**
   - Collection: `record_transfer_requests`
   - Document ID: Auto-generated
   - Fields: As per RecordTransferRequest model
   - Indexes: Create for status queries

3. **audit_logs**
   - Collection: `audit_logs`
   - Document ID: Auto-generated
   - Fields: As per AuditLog model
   - Indexes: Create for filtering

### Create Firestore Indexes

```javascript
// patient_records collection
Index: recordStatus + patientName (Ascending)
Index: dataComplete + patientName (Ascending)
Index: recordStatus + updatedAt (Descending)

// record_transfer_requests collection
Index: status + requestDate (Descending)
Index: patientId + status (Ascending)

// audit_logs collection
Index: timestamp (Descending)
Index: action + timestamp (Descending)
Index: adminId + timestamp (Descending)
Index: targetPatientId + timestamp (Descending)
```

---

## Step 2: Configure Firestore Security Rules

```javascript
// Firestore Security Rules

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAdmin() {
      return request.auth.token.role == 'admin';
    }
    
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Patient Records Collection
    match /patient_records/{patientId} {
      // Admins can read all
      allow read: if isAdmin();
      // Admins can create/update
      allow create, update: if isAdmin();
      // Admins can delete (soft delete via status field)
      allow delete: if isAdmin();
      
      // Validate data on write
      allow write: if 
        request.resource.data.patientId != null &&
        request.resource.data.patientName != null &&
        request.resource.data.recordStatus in ['active', 'inactive', 'archived'];
    }
    
    // Record Transfer Requests Collection
    match /record_transfer_requests/{requestId} {
      // Admins can read all
      allow read: if isAdmin();
      // Admins can create
      allow create: if isAdmin();
      // Admins can update (status, approval info)
      allow update: if isAdmin();
      
      // Validate transfer request data
      allow write: if 
        request.resource.data.patientId != null &&
        request.resource.data.fromDoctorId != null &&
        request.resource.data.toDoctorId != null &&
        request.resource.data.status in ['pending', 'approved', 'rejected', 'completed'];
    }
    
    // Audit Logs Collection
    match /audit_logs/{logId} {
      // Only admins can read
      allow read: if isAdmin();
      // Only service can write
      allow create: if isAuthenticated();
      // Never allow update or delete
      allow update, delete: if false;
      
      // Validate audit log data
      allow create: if 
        request.resource.data.adminId != null &&
        request.resource.data.action != null &&
        request.resource.data.timestamp != null;
    }
    
    // Deny all other access
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## Step 3: Update Firebase Configuration

### Verify firebase_options.dart

Check that your Firebase project is properly configured:

```dart
// firebase_options.dart should contain:
// - apiKey
// - appId
// - messagingSenderId
// - projectId
// - storageBucket
// - etc.
```

### Initialize Firebase in main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");
  } catch (e) {
    print("Error initializing Firebase: $e");
  }
  
  runApp(const MyApp());
}
```

---

## Step 4: Update Package Dependencies

Ensure all required packages are in pubspec.yaml:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Existing dependencies
  firebase_core: ^4.2.1
  firebase_auth: ^6.1.2
  cloud_firestore: ^6.1.0
  
  # Should already be present
  google_fonts: ^6.1.0
  intl: ^0.20.2
  image_picker: ^1.1.2
  cloudinary_public: ^0.23.1
```

No new dependencies added - all features use existing packages!

---

## Step 5: Build & Test

### Run Tests
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/models/patient_record_model_test.dart

# Run with coverage
flutter test --coverage
```

### Build APK
```bash
# Build Android APK
flutter build apk --release

# Build iOS IPA
flutter build ios --release
```

### Build Web
```bash
# Build Web
flutter build web --release
```

---

## Step 6: Deployment to Platforms

### Android Deployment

```bash
# Build and upload to Play Store
flutter build appbundle --release

# Use Play Console to upload and release
```

### iOS Deployment

```bash
# Build for iOS
flutter build ios --release

# Use Xcode or Transporter to upload to App Store
```

### Web Deployment

```bash
# Build web
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting

# Or deploy to your server
# Copy build/web/* to your web server
```

---

## Step 7: Post-Deployment Verification

### Smoke Tests

- [ ] App launches successfully
- [ ] Admin can login
- [ ] Dashboard loads
- [ ] All menu items accessible
- [ ] Quality Check page loads
- [ ] Analytics page loads
- [ ] Transfer page loads
- [ ] Archive page loads
- [ ] Audit trail page loads

### Feature Tests

- [ ] Data validation works
- [ ] Records save to Firestore
- [ ] Audit logs are created
- [ ] Transfers can be approved/rejected
- [ ] Records can be archived/restored
- [ ] Reports generate correctly
- [ ] Filters work properly
- [ ] Date range picker works

### Performance Tests

- [ ] Page load time < 2 seconds
- [ ] List scrolling smooth
- [ ] Transitions smooth
- [ ] No memory leaks
- [ ] Battery drain acceptable

---

## Step 8: Monitor & Maintain

### Monitor Metrics

```
// Track in Firebase Console:
- User authentication success rate
- Function execution time
- Database read/write errors
- Storage quota usage
```

### Regular Maintenance

**Daily:**
- Check error logs
- Verify audit trail is growing
- Confirm no failed operations

**Weekly:**
- Review performance metrics
- Check storage quota
- Validate data quality
- Review admin activity

**Monthly:**
- Generate compliance reports
- Archive old audit logs
- Review security logs
- Plan feature updates

---

## Troubleshooting Deployment

### Issue: "Firestore not initialized"
**Solution:** Verify Firebase initialization in main.dart and firebase_options.dart

### Issue: "Permission denied" errors
**Solution:** Check Firestore security rules and admin role assignment

### Issue: "Collection not found"
**Solution:** Verify collections are created in Firestore Console

### Issue: "Slow performance"
**Solution:** 
- Check Firestore indexes are created
- Optimize queries
- Reduce pagination size
- Cache frequently accessed data

### Issue: "Audit logs not being created"
**Solution:**
- Verify audit_logs collection exists
- Check service method is being called
- Review error logs in Firebase Console

---

## Rollback Plan

If issues occur after deployment:

### Quick Rollback (Same Day)
```bash
# Deploy previous working version
flutter build apk --release
# Upload to Play Store as new version
```

### Feature Rollback (Keep Current)
```dart
// Comment out new UI page navigation in admin_dashboard_page.dart
// Revert imports
// Rebuild and redeploy
```

### Database Rollback
```javascript
// Firestore doesn't support true rollback
// Instead:
// 1. Export collections to backup
// 2. Review audit logs for changes
// 3. Manually restore if needed
```

---

## Rollout Strategy

### Phase 1: Internal Testing (Week 1)
- Deploy to test environment
- Internal admin team tests
- Verify all features work
- Fix any issues found

### Phase 2: Beta Testing (Week 2)
- Deploy to small group of admins
- Gather feedback
- Monitor performance
- Fix issues as they arise

### Phase 3: Full Rollout (Week 3)
- Deploy to all admins
- Provide training
- Monitor heavily
- Have support ready

---

## Documentation Deployment

Deploy documentation:
- [ ] ADMIN_RECORD_MANAGEMENT.md - Technical reference
- [ ] ADMIN_QUICK_REFERENCE.md - User guide
- [ ] ARCHITECTURE.md - System design
- [ ] TESTING_GUIDE.md - Testing procedures
- [ ] IMPLEMENTATION_SUMMARY.md - Feature summary
- [ ] This file - Deployment guide

Place in:
- Project repository
- Internal wiki/documentation site
- Print for reference

---

## Training & Support

### Train Administrators On:
- How to use each feature
- Data validation concepts
- Transfer request workflow
- Record archival policies
- How to read audit logs
- Report generation
- Troubleshooting

### Create Support Documentation:
- [ ] FAQ document
- [ ] Troubleshooting guide
- [ ] Video tutorials
- [ ] Screen captures
- [ ] Workflow diagrams

### Setup Support Channels:
- [ ] Email support group
- [ ] Slack channel
- [ ] Documentation wiki
- [ ] Issue tracking system

---

## Success Metrics

Track these KPIs after deployment:

```
1. Feature Adoption
   - % of admins using each feature
   - Feature usage frequency
   - Time spent in each section

2. Data Quality
   - % of complete records
   - Reduction in missing fields
   - Archival compliance

3. System Performance
   - Average page load time
   - Error rate
   - Database query performance

4. User Satisfaction
   - Support ticket volume
   - User feedback rating
   - Feature request count

5. Compliance
   - Audit log completeness
   - Transfer approval rate
   - Archive compliance
```

---

## Version Management

### Version Numbering
- MAJOR.MINOR.PATCH
- Example: 1.0.0

### Current Version
- **Version:** 1.0.0
- **Release Date:** [Deployment Date]
- **Features:** All 6 core features included

### Future Updates
```
1.1.0 - Bulk operations
1.2.0 - Export functionality
2.0.0 - Advanced permissions
```

---

## Backup & Recovery

### Daily Backups
```bash
# Firestore export
gsutil -m cp -r gs://backup-bucket/firestore gs://backup-bucket/firestore-$(date +%Y%m%d)
```

### Recovery Procedure
```
1. Stop application
2. Restore Firestore from backup
3. Verify data integrity
4. Restart application
5. Notify users
6. Monitor for issues
```

---

## Final Checklist

- [ ] All code committed and pushed
- [ ] All tests passing
- [ ] Documentation complete
- [ ] Firestore configured
- [ ] Security rules deployed
- [ ] Team trained
- [ ] Monitoring setup
- [ ] Support ready
- [ ] Backup procedures tested
- [ ] Rollback plan documented

---

## Go Live!

Once all checklist items are complete:

1. **Announce** to team
2. **Deploy** to production
3. **Monitor** closely for first 24 hours
4. **Gather feedback** from users
5. **Fix any issues** quickly
6. **Celebrate** the successful deployment!

---

## Support Contact

For deployment issues:
- Technical Issues: Development team
- User Issues: Support team
- Compliance Issues: Compliance officer
- Performance Issues: DevOps team

---

**Deployment Date:** _____________
**Deployed By:** _____________
**Verified By:** _____________

All features successfully deployed and verified!

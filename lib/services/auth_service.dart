import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with Email and Password
  Future<Map<String, dynamic>> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      if (user != null) {
        // Check if user document exists
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (!userDoc.exists) {
          // Create user document if it doesn't exist (for existing users)
          await _createUserDocument(user.uid, email);
        }

        print('✓ Sign in successful: ${user.uid}');
        return {'success': true, 'user': user};
      }
      return {'success': false, 'message': 'Sign in failed'};
    } on FirebaseAuthException catch (e) {
      print('✗ Sign in error: ${e.code} - ${e.message}');
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email';
          break;
        case 'wrong-password':
          message = 'Wrong password';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
        default:
          message = 'Login failed: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      print('✗ Unexpected error: $e');
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  // Register with Email and Password
  Future<Map<String, dynamic>> registerWithEmailPassword(
    String email,
    String password,
    String name, // Add name parameter
  ) async {
    try {
      print('Attempting to register user: $email');

      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      if (user != null) {
        print('✓ User created in Auth: ${user.uid}');

        // Create user document in Firestore
        await _createUserDocument(user.uid, email, name: name);

        // Update display name
        await user.updateDisplayName(name);

        print('✓ User document created successfully');
        return {'success': true, 'user': user};
      }
      return {'success': false, 'message': 'Registration failed'};
    } on FirebaseAuthException catch (e) {
      print('✗ Registration error: ${e.code} - ${e.message}');
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered';
          break;
        case 'weak-password':
          message = 'Password is too weak. Use at least 6 characters';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'operation-not-allowed':
          message = 'Email/password accounts are not enabled';
          break;
        default:
          message = 'Registration failed: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      print('✗ Unexpected error during registration: $e');
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(
    String userId,
    String email, {
    String? name,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set(
        {
          'email': email,
          'name': name ?? 'User',
          'role': 'patient', // Default role
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      ); // Use merge to avoid overwriting existing data

      print('✓ User document created for: $userId');
    } catch (e) {
      print('✗ Error creating user document: $e');
      throw e; // Re-throw to handle in calling function
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    String? name,
    String? phone,
    String? address,
    DateTime? dateOfBirth,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (address != null) updates['address'] = address;
      if (dateOfBirth != null) {
        updates['dateOfBirth'] = Timestamp.fromDate(dateOfBirth);
      }

      await _firestore.collection('users').doc(userId).update(updates);

      // Update display name in Auth
      if (name != null && _auth.currentUser != null) {
        await _auth.currentUser!.updateDisplayName(name);
      }

      return {'success': true, 'message': 'Profile updated successfully'};
    } catch (e) {
      print('Error updating profile: $e');
      return {'success': false, 'message': 'Failed to update profile'};
    }
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Stream user data
  Stream<DocumentSnapshot> getUserDataStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  // Sign out the user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('✓ User signed out successfully');
    } catch (e) {
      print('✗ Error signing out: $e');
    }
  }

  // Check if user is authenticated
  bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  // Listen to auth state changes
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  // Send password reset email
  Future<Map<String, dynamic>> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Password reset email sent. Check your inbox.',
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        default:
          message = 'Failed to send reset email';
      }
      return {'success': false, 'message': message};
    }
  }

  // Delete account
  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'No user logged in'};
      }

      // Delete user document
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete all user's appointments
      final appointments = await _firestore
          .collection('appointments')
          .where('userId', isEqualTo: user.uid)
          .get();

      for (var doc in appointments.docs) {
        await doc.reference.delete();
      }

      // Delete auth account
      await user.delete();

      return {'success': true, 'message': 'Account deleted successfully'};
    } catch (e) {
      print('Error deleting account: $e');
      return {'success': false, 'message': 'Failed to delete account'};
    }
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/app_logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      AppLogger.info('🔥 Attempting sign up for: $email');
      AppLogger.info('🔥 Firebase Auth instance: ${_auth.app.name}');

      // Create user in Firebase Auth
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      AppLogger.info('✅ Sign up successful!');

      final User? user = userCredential.user;
      if (user == null) return null;

      // Update display name
      await user.updateDisplayName(displayName);

      // Create user document in Firestore
      final UserModel userModel = UserModel.fromFirebaseUser(
        user.uid,
        email,
        displayName,
      );

      AppLogger.info('📝 Creating Firestore document...');
      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
      AppLogger.info('✅ Firestore document created!');

      return userModel;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('❌ Firebase Auth Error: ${e.code} - ${e.message}', e);
      throw _handleAuthException(e);
    } catch (e) {
      AppLogger.error('❌ Unknown Error during sign up', e);
      throw Exception('Failed to sign up: $e');
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('🔥 Attempting sign in for: $email');

      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      AppLogger.info('✅ Sign in successful!');

      final User? user = userCredential.user;
      if (user == null) {
        AppLogger.error('❌ User is null after sign in');
        return null;
      }

      AppLogger.info('📖 Fetching user data from Firestore for: ${user.uid}');

      try {
        // Get user data from Firestore
        final DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          AppLogger.info('✅ User document found in Firestore');
          return UserModel.fromMap(
            doc.data() as Map<String, dynamic>,
            documentId: doc.id,
          );
        }

        AppLogger.warning(
          '⚠️ User document does not exist in Firestore, creating one...',
        );

        final userModel = UserModel.fromFirebaseUser(
          user.uid,
          user.email ?? '',
          user.displayName ?? user.email?.split('@')[0] ?? 'User',
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());
        AppLogger.info('✅ User document created');
        return userModel;
      } catch (e) {
        AppLogger.warning(
          '⚠️ Firestore user profile unavailable during sign in. Continuing with Firebase Auth profile.',
        );
        return UserModel.fromFirebaseUser(
          user.uid,
          user.email ?? '',
          user.displayName ?? user.email?.split('@')[0] ?? 'User',
        );
      }
    } on FirebaseAuthException catch (e) {
      AppLogger.error('❌ Firebase Auth Error: ${e.code} - ${e.message}', e);
      throw _handleAuthException(e);
    } catch (e) {
      AppLogger.error('❌ Error during sign in: $e', e);
      throw Exception('Failed to sign in: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String userId) async {
    try {
      AppLogger.info('📖 Getting user data for: $userId');

      final DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        AppLogger.info('✅ User document exists');
        return UserModel.fromMap(
          doc.data() as Map<String, dynamic>,
          documentId: doc.id,
        );
      } else {
        AppLogger.warning(
          '⚠️ User document missing, creating from Firebase Auth...',
        );

        // Get user info from Firebase Auth
        final User? currentUser = _auth.currentUser;
        if (currentUser != null) {
          final userModel = UserModel.fromFirebaseUser(
            currentUser.uid,
            currentUser.email ?? '',
            currentUser.displayName ??
                currentUser.email?.split('@')[0] ??
                'User',
          );

          // Create the document
          await _firestore
              .collection('users')
              .doc(userId)
              .set(userModel.toMap());
          AppLogger.info('✅ User document created');
          return userModel;
        }

        AppLogger.error('❌ No current user in Firebase Auth');
        return null;
      }
    } catch (e) {
      AppLogger.error('❌ Failed to get user data: $e', e);
      throw Exception('Failed to get user data: $e');
    }
  }

  // Update FCM token
  Future<void> updateFCMToken(String userId, String fcmToken) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': fcmToken,
      });
    } catch (e) {
      throw Exception('Failed to update FCM token: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}

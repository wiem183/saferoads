import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as models;

class AuthService {
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get current user
  auth.User? get currentUser => _firebaseAuth.currentUser;

  // Stream of auth state changes
  Stream<auth.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Sign up with email and password
  Future<models.User?> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        return null;
      }

      // Create user document in Firestore
      final user = models.User(
        id: userCredential.user!.uid,
        email: email,
        name: name,
        phone: phone,
        createdAt: DateTime.now(),
      );

      await _db.collection('users').doc(user.id).set(user.toJson());

      // Update display name
      await userCredential.user!.updateDisplayName(name);

      return user;
    } on auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Une erreur s\'est produite lors de l\'inscription: $e');
    }
  }

  // Sign in with email and password
  Future<models.User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        return null;
      }

      // Get user document from Firestore
      final doc = await _db
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!doc.exists) {
        return null;
      }

      return models.User.fromJson(doc.data()!);
    } on auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Une erreur s\'est produite lors de la connexion: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // Get user data from Firestore
  Future<models.User?> getUserData(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) {
        return null;
      }
      return models.User.fromJson(doc.data()!);
    } catch (e) {
      return null;
    }
  }

  // Create user in Firestore (pour Google Sign-In)
  Future<void> createUserInFirestore(models.User user) async {
    try {
      await _db.collection('users').doc(user.id).set(user.toJson());
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'utilisateur: $e');
    }
  }

  // Update user data
  Future<void> updateUserData(models.User user) async {
    await _db.collection('users').doc(user.id).update(user.toJson());
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Deactivate account (soft delete)
  Future<void> deactivateAccount(String userId) async {
    try {
      await _db.collection('users').doc(userId).update({'isActive': false});
      // Sign out the user after deactivation
      await signOut();
    } catch (e) {
      throw Exception('Erreur lors de la désactivation du compte: $e');
    }
  }

  // Reactivate account
  Future<void> reactivateAccount(String userId) async {
    try {
      await _db.collection('users').doc(userId).update({'isActive': true});
    } catch (e) {
      throw Exception('Erreur lors de la réactivation du compte: $e');
    }
  }

  // Delete account permanently
  Future<void> deleteAccount(String userId) async {
    try {
      // Delete user data from Firestore
      await _db.collection('users').doc(userId).delete();

      // Delete user from Firebase Auth
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } on auth.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
          'Pour des raisons de sécurité, veuillez vous reconnecter avant de supprimer votre compte.',
        );
      }
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erreur lors de la suppression du compte: $e');
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Le mot de passe est trop faible';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé';
      case 'invalid-email':
        return 'Email invalide';
      case 'user-disabled':
        return 'Ce compte a été désactivé';
      case 'user-not-found':
        return 'Aucun compte trouvé avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'too-many-requests':
        return 'Trop de tentatives. Veuillez réessayer plus tard';
      case 'operation-not-allowed':
        return 'Opération non autorisée';
      default:
        return 'Une erreur s\'est produite: ${e.message}';
    }
  }
}

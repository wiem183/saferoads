import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Connexion avec Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Déclencher le flux d'authentification Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // L'utilisateur a annulé la connexion
        return null;
      }

      // Obtenir les détails d'authentification de la requête
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Créer une nouvelle credential Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Se connecter à Firebase avec la credential Google
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('❌ Erreur Google Sign-In: $e');
      rethrow;
    }
  }

  /// Déconnexion Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('❌ Erreur déconnexion Google: $e');
      rethrow;
    }
  }

  /// Vérifier si l'utilisateur est connecté avec Google
  bool isSignedIn() {
    return _googleSignIn.currentUser != null;
  }

  /// Obtenir l'utilisateur Google actuel
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
}

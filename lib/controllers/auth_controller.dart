import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';
import '../models/user.dart' as models;
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/google_auth_service.dart';

class AuthController with ChangeNotifier {
  final AuthService _authService = AuthService();
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  models.User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  models.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  AuthController() {
    _initAuthListener();
  }

  // Initialize auth state listener
  void _initAuthListener() {
    _authService.authStateChanges.listen((auth.User? firebaseUser) async {
      if (firebaseUser != null) {
        _currentUser = await _authService.getUserData(firebaseUser.uid);
        if (_currentUser != null) {
          await StorageService.setString('userId', _currentUser!.id);
          await StorageService.setString('myPhone', _currentUser!.phone);
        }
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  // Sign up
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _currentUser = await _authService.signUp(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );

      if (_currentUser != null) {
        await StorageService.setString('userId', _currentUser!.id);
        await StorageService.setString('myPhone', _currentUser!.phone);
      }

      _isLoading = false;
      notifyListeners();
      return _currentUser != null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Sign in
  Future<bool> signIn({required String email, required String password}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _currentUser = await _authService.signIn(
        email: email,
        password: password,
      );

      if (_currentUser != null) {
        await StorageService.setString('userId', _currentUser!.id);
        await StorageService.setString('myPhone', _currentUser!.phone);
      }

      _isLoading = false;
      notifyListeners();
      return _currentUser != null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userCredential = await _googleAuthService.signInWithGoogle();

      if (userCredential == null) {
        _isLoading = false;
        _errorMessage = 'Connexion annulée';
        notifyListeners();
        return false;
      }

      // Créer ou récupérer l'utilisateur dans Firestore
      final firebaseUser = userCredential.user!;

      // Vérifier si l'utilisateur existe déjà dans Firestore
      _currentUser = await _authService.getUserData(firebaseUser.uid);

      if (_currentUser == null) {
        // Créer un nouveau profil utilisateur
        final newUser = models.User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ?? 'Utilisateur Google',
          phone: '', // À compléter plus tard si nécessaire
          createdAt: DateTime.now(),
        );

        await _authService.createUserInFirestore(newUser);
        _currentUser = newUser;
      }

      await StorageService.setString('userId', _currentUser!.id);
      await StorageService.setString('myPhone', _currentUser!.phone);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erreur lors de la connexion Google: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _currentUser = null;
      await StorageService.setString('userId', '');
      await StorageService.setString('myPhone', '');
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Update user data
  Future<void> updateUser(models.User user) async {
    try {
      await _authService.updateUserData(user);
      _currentUser = user;
      await StorageService.setString('myPhone', user.phone);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.resetPassword(email);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Deactivate account
  Future<bool> deactivateAccount() async {
    try {
      if (_currentUser == null) return false;

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.deactivateAccount(_currentUser!.id);
      _currentUser = null;
      await StorageService.setString('userId', '');
      await StorageService.setString('myPhone', '');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete account permanently
  Future<bool> deleteAccount() async {
    try {
      if (_currentUser == null) return false;

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.deleteAccount(_currentUser!.id);
      _currentUser = null;
      await StorageService.setString('userId', '');
      await StorageService.setString('myPhone', '');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}

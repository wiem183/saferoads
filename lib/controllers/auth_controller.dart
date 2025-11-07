import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';
import '../models/user.dart' as models;
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthController with ChangeNotifier {
  final AuthService _authService = AuthService();
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
}

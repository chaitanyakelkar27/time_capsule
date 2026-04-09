import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../utils/app_logger.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated {
    final authenticated = _user != null;
    AppLogger.debug(
      '🔐 isAuthenticated: $authenticated, user: ${_user?.email}',
    );
    return authenticated;
  }

  AuthProvider() {
    AppLogger.info('🔧 AuthProvider initialized');
    // Listen to auth state changes
    _authService.authStateChanges.listen(
      (User? firebaseUser) async {
        AppLogger.info(
          '🔔 Auth state changed: ${firebaseUser?.email ?? "null"}',
        );
        if (firebaseUser != null) {
          try {
            _user = await _authService.getUserData(firebaseUser.uid);
            AppLogger.info('👤 User data loaded: ${_user?.email}');
          } catch (e) {
            AppLogger.warning(
              '⚠️ Failed to load Firestore profile from auth state. Using Firebase Auth profile fallback.',
            );
            _user = UserModel.fromFirebaseUser(
              firebaseUser.uid,
              firebaseUser.email ?? '',
              firebaseUser.displayName ??
                  firebaseUser.email?.split('@')[0] ??
                  'User',
            );
          }
          notifyListeners();
        } else {
          _user = null;
          AppLogger.info('👤 User signed out');
          notifyListeners();
        }
      },
      onError: (Object e) {
        AppLogger.error('❌ authStateChanges stream error: $e', e);
        _user = null;
        notifyListeners();
      },
    );
  }

  // Sign up
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign in
  Future<bool> signIn({required String email, required String password}) async {
    AppLogger.info('🔑 Starting sign in process...');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      _isLoading = false;
      final success = _user != null;
      AppLogger.info('🔑 Sign in result: $success, user: ${_user?.email}');
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      AppLogger.error('❌ Sign in failed: $e', e);
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _user = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

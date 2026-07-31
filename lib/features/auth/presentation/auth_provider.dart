import 'dart:async';
import 'package:flutter/material.dart';
import '../data/auth_repository.dart';
import '../domain/auth_user.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  AuthUser? _currentUser;
  bool _isLoading = false;
  String _errorMessage = '';
  StreamSubscription<AuthUser?>? _authSubscription;

  AuthProvider(this._authRepository) {
    _isLoading = true;
    _authSubscription = _authRepository.onAuthStateChanged.listen((AuthUser? user) {
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
    });
  }

  AuthUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _currentUser = await _authRepository.signInWithEmail(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _currentUser = await _authRepository.registerWithEmail(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInGuest() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _currentUser = await _authRepository.signInAnonymously();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final user = await _authRepository.signInWithGoogle();
      if (user != null) {
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        _errorMessage = 'Google Sign-In was cancelled or failed.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfileName(String displayName) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updatedUser = await _authRepository.updateUserProfile(displayName);
      if (updatedUser != null) {
        _currentUser = updatedUser;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    await _authRepository.signOut();
    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

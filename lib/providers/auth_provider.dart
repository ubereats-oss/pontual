import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? service}) : _service = service ?? AuthService() {
    _service.authStateChanges.listen(_onAuthChanged);
  }

  final AuthService _service;

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  String? _error;
  bool _loading = false;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  String? get error => _error;
  bool get loading => _loading;

  Future<void> _onAuthChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _status = AuthStatus.unauthenticated;
      _user = null;
    } else {
      _status = AuthStatus.authenticated;
      _user = await _service.getCurrentUserModel();
    }
    notifyListeners();
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      _user = await _service.signInWithEmail(email, password);
      _status = AuthStatus.authenticated;
      _setLoading(false);
      return true;
    } on Object catch (error) {
      _setError(_parseFirebaseError(error));
      return false;
    }
  }

  Future<bool> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      _user = await _service.registerWithEmail(
        name: name,
        email: email,
        password: password,
      );
      _status = AuthStatus.authenticated;
      _setLoading(false);
      return true;
    } on Object catch (error) {
      _setError(_parseFirebaseError(error));
      return false;
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    _error = null;
    notifyListeners();
  }

  void _setError(String message) {
    _loading = false;
    _error = message;
    notifyListeners();
  }

  String _parseFirebaseError(Object error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'user-not-found' => 'E-mail nao encontrado.',
        'wrong-password' => 'Senha incorreta.',
        'invalid-credential' => 'E-mail ou senha incorretos.',
        'email-already-in-use' => 'E-mail ja cadastrado.',
        'weak-password' => 'Senha muito fraca.',
        'invalid-email' => 'E-mail invalido.',
        _ => error.message ?? 'Erro de autenticacao.',
      };
    }
    return error.toString();
  }
}

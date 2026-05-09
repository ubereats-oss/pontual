import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

import '../models/app_user.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<AppUser?> signInWithEmail(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _upsertUser(result.user!);
  }

  Future<AppUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = result.user!;
    await user.updateDisplayName(name);

    final model = AppUser(
      uid: user.uid,
      name: name,
      email: email,
      createdAt: DateTime.now(),
    );
    await _db.collection('users').doc(user.uid).set(model.toMap());
    return model;
  }

  Future<AppUser?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return _upsertUser(user);
    return AppUser.fromDoc(doc);
  }

  Future<void> signOut() => _auth.signOut();

  Future<AppUser> _upsertUser(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final doc = await ref.get();
    if (doc.exists) return AppUser.fromDoc(doc);

    final model = AppUser(
      uid: user.uid,
      name: user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : 'Usuario',
      email: user.email ?? '',
      createdAt: DateTime.now(),
    );
    await ref.set(model.toMap());
    return model;
  }
}

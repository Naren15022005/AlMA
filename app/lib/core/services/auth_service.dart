import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> register({
    required String email,
    required String name,
    required String password,
    String? birthday,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    final pairCode = await _generateUniquePairCode();

    await _db.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'pairCode': pairCode,
      'coupleId': null,
      'avatarUrl': null,
      'birthday': birthday,
      'fcmToken': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('pairCodes').doc(pairCode).set({'userId': uid});

    return credential;
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> logout() => _auth.signOut();

  Future<void> updateFcmToken(String token) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({'fcmToken': token});
  }

  Future<String> _generateUniquePairCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    while (true) {
      final code = List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
      final doc = await _db.collection('pairCodes').doc(code).get();
      if (!doc.exists) return code;
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final firebaseUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

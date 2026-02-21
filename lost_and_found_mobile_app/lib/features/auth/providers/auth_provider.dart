import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/user_model.dart';
import '../../../shared/constants/app_constants.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection(AppConstants.colUsers)
      .doc(uid)
      .snapshots()
      .map((snap) => snap.exists ? UserModel.fromFirestore(snap) : null);
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier() : super(const AsyncValue.data(null));

  final _auth      = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    required String studentNumber,
  }) async {
    state = const AsyncValue.loading();
    try {
      final domain = email.split('@').last.toLowerCase();
      if (!AppConstants.allowedDomains.contains(domain)) {
        throw Exception(
          'Only @student.cut.ac.za and @cut.ac.za email addresses are allowed.',
        );
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await credential.user?.updateDisplayName(displayName.trim());

      final user = UserModel(
        userId:        credential.user!.uid,
        studentNumber: studentNumber.trim(),
        displayName:   displayName.trim(),
        email:         email.trim().toLowerCase(),
        role:          AppConstants.roleStudent,
        createdAt:     DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.colUsers)
          .doc(credential.user!.uid)
          .set(user.toFirestore());

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      state = const AsyncValue.data(null);
    } on FirebaseAuthException catch (e, st) {
      final message = _friendlyError(e.code);
      state = AsyncValue.error(message, st);
      rethrow;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> logout() async {
    await _auth.signOut();
    state = const AsyncValue.data(null);
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':        return 'No account found with this email address.';
      case 'wrong-password':        return 'Incorrect password. Please try again.';
      case 'invalid-credential':    return 'Incorrect email or password.';
      case 'invalid-email':         return 'Please enter a valid email address.';
      case 'user-disabled':         return 'This account has been disabled.';
      case 'email-already-in-use':  return 'An account already exists with this email.';
      case 'weak-password':         return 'Password must be at least 6 characters.';
      case 'too-many-requests':     return 'Too many attempts. Please wait and try again.';
      default:                      return 'Authentication failed. Please try again.';
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>(
  (ref) => AuthNotifier(),
);
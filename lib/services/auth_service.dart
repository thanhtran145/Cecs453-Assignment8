import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Handles all Firebase Authentication logic (email/password + Google) and
/// exposes the current user as a ChangeNotifier so any widget in the tree
/// can react to sign-in state without manual navigation logic.
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  User? _user;
  User? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AuthService() {
    // Automatically listen to Firebase auth changes on startup.
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ---------------- Email & password ----------------

  Future<bool> signUp(String email, String password) async {
    _errorMessage = null;
    _setLoading(true);
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn(String email, String password) async {
    _errorMessage = null;
    _setLoading(true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _errorMessage = null;
    _setLoading(true);
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------- Google sign-in ----------------
  // Uses the current (v7+) google_sign_in API: GoogleSignIn.instance is a
  // singleton, .authenticate() replaces the old .signIn(), and
  // googleUser.authentication is now a synchronous getter (not a Future).

  Future<bool> signInWithGoogle() async {
    _errorMessage = null;
    _setLoading(true);
    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);
      await _auth.signInWithCredential(credential);
      return true;
    } on GoogleSignInException catch (e) {
      // Don't show an error if the user simply closed the account picker.
      if (e.code != GoogleSignInExceptionCode.canceled) {
        _errorMessage = 'Google sign-in failed. Please try again.';
      }
      return false;
    } on UnimplementedError {
      _errorMessage = 'Google sign-in is not supported on this platform.';
      return false;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------- Sign out ----------------

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Wasn't signed in with Google — nothing to do.
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}

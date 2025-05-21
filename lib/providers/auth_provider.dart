import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initializeUser();
  }

  void _initializeUser() {
    _user = _auth.currentUser;

    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // Sign in with email and password
  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = _handleAuthError(e);
      notifyListeners();
      throw _error!;
    }
  }

  // Sign up with email and password
  Future<void> signUp(String email, String password, {String? name, String? major}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Create the user account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create a user profile document in Firestore
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'name': name ?? email.split('@').first, // Use part of email if no name provided
          'major': major ?? '', // Major field added
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = _handleAuthError(e);
      notifyListeners();
      throw _error!;
    }
  }

  // Sign out the current user
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.signOut();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Get user profile data from Firestore
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (_user == null) return null;

    try {
      final docSnapshot = await _firestore.collection('users').doc(_user!.uid).get();
      return docSnapshot.data();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Update user profile in Firestore
  Future<void> updateUserProfile(Map<String, dynamic> userData) async {
    if (_user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection('users').doc(_user!.uid).update(userData);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      throw _error!;
    }
  }

  // Handle Firebase Auth errors with user-friendly messages
  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'user-disabled':
          return 'This user has been disabled.';
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'The password is invalid.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'weak-password':
          return 'The password provided is too weak.';
        case 'operation-not-allowed':
          return 'This operation is not allowed.';
        case 'network-request-failed':
          return 'A network error occurred. Please check your connection.';
        default:
          return error.message ?? 'An unknown error occurred.';
      }
    }
    return error.toString();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
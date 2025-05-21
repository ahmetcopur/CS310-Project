import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class GpaProvider with ChangeNotifier {
  double _gpa = 0.0;
  bool _isLoading = true;
  StreamSubscription? _subscription;
  StreamSubscription? _authSubscription;
  String? _currentUserId;
  
  double get gpa => _gpa;
  bool get isLoading => _isLoading;

  GpaProvider() {
    // Listen to auth state changes
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      final newUserId = user?.uid;
      
      // Only refresh listener if user ID actually changed
      if (newUserId != _currentUserId) {
        _currentUserId = newUserId;
        _refreshListener();
      }
    });
    
    // Initial setup
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _refreshListener();
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
  
  void _refreshListener() {
    // Cancel any existing subscription
    _subscription?.cancel();
    
    // Reset values if user is logged out
    if (_currentUserId == null) {
      _gpa = 0.0;
      _isLoading = false;
      notifyListeners();
      return;
    }
    
    // User is logged in, set up new listener
    _isLoading = true;
    notifyListeners();
    
    const gradePoints = {
      'A': 4.00,
      'A-': 3.70,
      'B+': 3.30,
      'B': 3.00,
      'B-': 2.70,
      'C+': 2.30,
      'C': 2.00,
      'C-': 1.70,
      'D+': 1.30,
      'D': 1.00,
      'F': 0.00,
    };
    
    _subscription = FirebaseFirestore.instance
        .collection('user_course_data')
        .where('createdBy', isEqualTo: _currentUserId)
        .where('isCompleted', isEqualTo: true)
        .snapshots()
        .listen((snapshot) async {
      double totalPoints = 0.0;
      int totalCredits = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final letter = (data['letterGrade'] as String?)?.trim().toUpperCase();
        final courseId = data['courseId'] as String? ?? '';
        final courseDoc = await FirebaseFirestore.instance
            .collection('courses')
            .doc(courseId)
            .get();
        int credits = 0;
        if (courseDoc.exists) {
          credits = (courseDoc.data()?['credits'] as num?)?.toInt() ?? 0;
        }
        // Debug print
        print('GPA DEBUG: courseId=$courseId, letter=$letter, credits=$credits');
        if (courseDoc.exists && letter != null && gradePoints.containsKey(letter)) {
          totalPoints += gradePoints[letter]! * credits;
          totalCredits += credits;
        }
      }
      _gpa = totalCredits > 0 ? totalPoints / totalCredits : 0.0;
      _isLoading = false;
      notifyListeners();
    });
  }

  // Method to manually refresh GPA calculation
  void refreshGpa() {
    _refreshListener();
  }
}

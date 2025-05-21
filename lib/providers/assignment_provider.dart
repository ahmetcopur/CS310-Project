import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/assignment.dart';

class AssignmentProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  List<Assignment> _assignments = [];
  bool _isLoading = false;
  String? _error;
  String? _currentCourseId;
  StreamSubscription<QuerySnapshot>? _assignmentsSubscription;

  List<Assignment> get assignments => _assignments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentCourseId => _currentCourseId;

  // Filtered assignments
  List<Assignment> get upcomingAssignments =>
      _assignments.where((a) =>
          a.dueDate.isAfter(DateTime.now()) &&
          a.dueDate.isBefore(DateTime.now().add(Duration(days: 7)))
      ).toList();

  List<Assignment> get overdueAssignments =>
      _assignments.where((a) =>
          a.dueDate.isBefore(DateTime.now())
      ).toList();

  AssignmentProvider() {
    if (_userId.isNotEmpty) {
      loadUpcomingAssignments();
    }
  }

  @override
  void dispose() {
    _assignmentsSubscription?.cancel();
    super.dispose();
  }

  // Load assignments for a specific course
  void loadCourseAssignments(String courseId) {
    _currentCourseId = courseId;
    notifyListeners();

    _assignmentsSubscription?.cancel();
    _assignmentsSubscription = _firestore
        .collection('assignments')
        .where('courseId', isEqualTo: courseId)
        .orderBy('dueDate')
        .snapshots()
        .listen(
          (snapshot) {
        _assignments = snapshot.docs
            .map((doc) => Assignment.fromFirestore(doc))
            .toList();
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Load upcoming assignments (due in the next 7 days)
  void loadUpcomingAssignments() {
    _isLoading = true;
    _currentCourseId = null;
    notifyListeners();

    final now = DateTime.now();
    final nextWeek = now.add(Duration(days: 7));

    _assignmentsSubscription?.cancel();
    try {
      // First try without date filters (simpler query)
      _assignmentsSubscription = _firestore
          .collection('assignments')
          .orderBy('dueDate')
          .snapshots()
          .listen(
            (snapshot) {
          print('Loaded ${snapshot.docs.length} assignments from Firestore');
          _assignments = snapshot.docs
              .map((doc) => Assignment.fromFirestore(doc))
              .toList();
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          print('Firestore error loading assignments: $error');
          _error = error.toString();
          _isLoading = false;
          
          // On error, try to load dummy assignments for testing
          _assignments = [
            Assignment(
              id: 'dummy1',
              courseId: 'CS101',
              description: 'Homework 1: Basic Programming', 
              dueDate: DateTime(2025, 9, 15),
            ),
            Assignment(
              id: 'dummy2',
              courseId: 'CS102',
              description: 'Project: Simple Calculator', 
              dueDate: DateTime(2025, 10, 1),
            ),
            Assignment(
              id: 'dummy3',
              courseId: 'CS201',
              description: 'Assignment: Linked Lists', 
              dueDate: DateTime(2025, 9, 25),
            ),
          ];
          notifyListeners();
        },
      );
    } catch (e) {
      print('Exception when setting up Firestore listener: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new assignment
  Future<void> addAssignment(Assignment assignment) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection('assignments').add(assignment.toFirestore());
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      throw _error!;
    }
  }

  // Update an existing assignment
  Future<void> updateAssignment(Assignment assignment) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore
          .collection('assignments')
          .doc(assignment.id)
          .update(assignment.toFirestore());
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      throw _error!;
    }
  }

  // Delete an assignment
  Future<void> deleteAssignment(String assignmentId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore
          .collection('assignments')
          .doc(assignmentId)
          .delete();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      throw _error!;
    }
  }

  // Get all assignments for all courses
  Future<List<Assignment>> getAllAssignments() async {
    try {
      final query = await _firestore
          .collection('assignments')
          .orderBy('dueDate')
          .get();

      return query.docs
          .map((doc) => Assignment.fromFirestore(doc))
          .toList();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
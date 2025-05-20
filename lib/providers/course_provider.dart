import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/course.dart';

class CourseProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Course> _courses = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<QuerySnapshot>? _coursesSubscription;

  List<Course> get courses => _courses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Stats getters
  int get totalCredits => _courses.fold(0, (sum, course) => sum + course.credits);

  CourseProvider() {
    loadUserCourses();
  }

  @override
  void dispose() {
    _coursesSubscription?.cancel();
    super.dispose();
  }

  // Load all courses
  void loadUserCourses() {
    _isLoading = true;
    notifyListeners();

    _coursesSubscription?.cancel();
    _coursesSubscription = _firestore
        .collection('courses')
        // fetch all courses
        .snapshots()
        .listen(
          (snapshot) {
        _courses = snapshot.docs
            .map((doc) => Course.fromFirestore(doc))
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

  // Get a single course by ID
  Future<Course?> getCourseById(String courseId) async {
    try {
      final docSnapshot = await _firestore.collection('courses').doc(courseId).get();
      if (docSnapshot.exists) {
        return Course.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Get a course by its course code (e.g., "CS301")
  Future<Course?> getCourseByCode(String courseCode) async {
    try {
      final querySnapshot = await _firestore
          .collection('courses')
          .where('code', isEqualTo: courseCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return Course.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Add a new course to Firestore
  Future<void> addCourse(Course course) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection('courses').add(course.toFirestore());
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      throw _error!;
    }
  }

  // Update an existing course
  Future<void> updateCourse(Course course) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore
          .collection('courses')
          .doc(course.id)
          .update(course.toFirestore());
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      throw _error!;
    }
  }

  // Delete a course
  Future<void> deleteCourse(String courseId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // First, delete all assignments for this course
      final assignmentQuery = await _firestore
          .collection('assignments')
          .where('courseId', isEqualTo: courseId)
          .get();

      final batch = _firestore.batch();

      // Add all assignment deletions to the batch
      for (var doc in assignmentQuery.docs) {
        batch.delete(doc.reference);
      }

      // Add course deletion to the batch
      batch.delete(_firestore.collection('courses').doc(courseId));

      // Commit the batch
      await batch.commit();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      throw _error!;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
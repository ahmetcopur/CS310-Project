import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:su_credit/models/course.dart';
import 'package:su_credit/models/assignment.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Course CRUD Operations
  // ======================

  // Create a new course
  Future<String> addCourse(Course course) async {
    final docRef = await _firestore.collection('courses').add(course.toMap());
    return docRef.id;
  }

  // Read all courses for current user
  Stream<List<Course>> getUserCourses() {
    return _firestore
        .collection('courses')
        .where('createdBy', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Course.fromMap(doc.data(), doc.id))
        .toList());
  }

  // Read courses for a specific semester
  Stream<List<Course>> getCoursesBySemester(String semester) {
    return _firestore
        .collection('courses')
        .where('createdBy', isEqualTo: _userId)
        .where('semester', isEqualTo: semester)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Course.fromMap(doc.data(), doc.id))
        .toList());
  }

  // Update a course
  Future<void> updateCourse(Course course) async {
    await _firestore.collection('courses').doc(course.id).update(course.toMap());
  }

  // Delete a course
  Future<void> deleteCourse(String courseId) async {
    // First, delete all assignments related to this course
    final assignmentQuery = await _firestore
        .collection('assignments')
        .where('courseId', isEqualTo: courseId)
        .get();

    for (var doc in assignmentQuery.docs) {
      await doc.reference.delete();
    }

    // Then delete the course
    await _firestore.collection('courses').doc(courseId).delete();
  }

  // Assignment CRUD Operations
  // =========================

  // Create a new assignment
  Future<String> addAssignment(Assignment assignment) async {
    final docRef = await _firestore.collection('assignments').add(assignment.toMap());
    return docRef.id;
  }

  // Read assignments for a course
  Stream<List<Assignment>> getCourseAssignments(String courseId) {
    return _firestore
        .collection('assignments')
        .where('courseId', isEqualTo: courseId)
        .where('createdBy', isEqualTo: _userId)
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Assignment.fromMap(doc.data(), doc.id))
        .toList());
  }

  // Read upcoming assignments (due in the next 7 days)
  Stream<List<Assignment>> getUpcomingAssignments() {
    final now = DateTime.now();
    final nextWeek = now.add(Duration(days: 7));

    return _firestore
        .collection('assignments')
        .where('createdBy', isEqualTo: _userId)
        .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(nextWeek))
        .where('isCompleted', isEqualTo: false)
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Assignment.fromMap(doc.data(), doc.id))
        .toList());
  }

  // Update an assignment
  Future<void> updateAssignment(Assignment assignment) async {
    await _firestore.collection('assignments').doc(assignment.id).update(assignment.toMap());
  }

  // Delete an assignment
  Future<void> deleteAssignment(String assignmentId) async {
    await _firestore.collection('assignments').doc(assignmentId).delete();
  }

  // Calculate GPA
  Future<double> calculateGPA() async {
    final courseQuery = await _firestore
        .collection('courses')
        .where('createdBy', isEqualTo: _userId)
        .where('isCompleted', isEqualTo: true)
        .get();

    double totalPoints = 0;
    int totalCredits = 0;

    for (var doc in courseQuery.docs) {
      final course = Course.fromMap(doc.data(), doc.id);
      if (course.grade != null) {
        totalPoints += course.grade! * course.credits;
        totalCredits += course.credits;
      }
    }

    return totalCredits > 0 ? totalPoints / totalCredits : 0.0;
  }
}
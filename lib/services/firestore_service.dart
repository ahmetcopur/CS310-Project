import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:su_credit/models/course.dart';
import 'package:su_credit/models/assignment.dart';
import 'package:su_credit/models/user_course_data.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Course CRUD Operations
  // ======================

  // Create a new course definition
  Future<String> addCourse(Course course) async {
    final docRef = await _firestore.collection('courses').add(course.toMap());
    return docRef.id;
  }

  // Read all global course definitions
  Stream<List<Course>> getAllCourses() {
    return _firestore
        .collection('courses')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Course.fromMap(doc.data(), doc.id))
        .toList());
  }

  // Update a course
  Future<void> updateCourse(Course course) async {
    await _firestore.collection('courses').doc(course.id).update(course.toMap());
  }

  // Delete a course definition
  Future<void> deleteCourse(String courseId) async {
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

  // User-specific course data CRUD
  Stream<List<UserCourseData>> getUserCourseData() {
    return _firestore
        .collection('user_course_data')
        .where('createdBy', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => UserCourseData.fromMap(doc.data(), doc.id))
        .toList());
  }

  Future<String> addUserCourseData(UserCourseData ucd) async {
    final docRef = await _firestore
        .collection('user_course_data')
        .add(ucd.toMap());
    return docRef.id;
  }

  Future<void> updateUserCourseData(UserCourseData ucd) async {
    await _firestore
        .collection('user_course_data')
        .doc(ucd.id)
        .set(ucd.toMap());
  }

  Future<void> deleteUserCourseData(String id) async {
    await _firestore
        .collection('user_course_data')
        .doc(id)
        .delete();
  }
}
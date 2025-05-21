import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_course_data.dart';

/// Provider to manage user-specific course data (grades, completion)
class UserCourseDataProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _userId;

  List<UserCourseData> _entries = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<QuerySnapshot>? _subscription;
  StreamSubscription? _authSubscription;

  List<UserCourseData> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  UserCourseDataProvider()
      : _userId = FirebaseAuth.instance.currentUser?.uid ?? '' {
    // Listen to auth changes
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      final newUserId = user?.uid ?? '';
      if (newUserId != _userId) {
        _startListening(newUserId);
      }
    });
    
    // Initial setup
    _startListening(_userId);
  }

  void _startListening(String userId) {
    _subscription?.cancel();
    _entries = [];
    _isLoading = true;
    _error = null;
    _userId = userId;
    notifyListeners();
    
    if (userId.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    
    _subscription = _firestore
        .collection('user_course_data')
        .where('createdBy', isEqualTo: _userId)
        .snapshots()
        .listen((snap) {
      _entries = snap.docs
          .map((doc) => UserCourseData.fromMap(doc.data(), doc.id))
          .toList();
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  void listenToUser(String userId) {
    _startListening(userId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  /// Clear all entries and cancel Firestore subscription
  void clear() {
    _subscription?.cancel();
    _entries = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  /// Create or update an entry
  Future<void> upsertEntry(UserCourseData data) async {
    try {
      if (data.id.isNotEmpty) {
        // update
        await _firestore.collection('user_course_data').doc(data.id).set(data.toMap());
      } else {
        // create
        await _firestore.collection('user_course_data').add(data.toMap());
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Delete an entry
  Future<void> deleteEntry(String id) async {
    try {
      await _firestore.collection('user_course_data').doc(id).delete();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Find entry by courseId
  UserCourseData? entryForCourse(String courseId) {
    try {
      return _entries.firstWhere((e) => e.courseId == courseId);
    } catch (e) {
      return null;
    }
  }

  /// Add a course that's currently being taken (not completed yet)
  Future<void> addCurrentCourse(String courseId) async {
    if (_userId.isEmpty) return;
    
    try {
      // Check if course already exists for this user
      final existingCourse = entryForCourse(courseId);
      if (existingCourse != null) {
        // If course exists but marked as completed, update it
        if (existingCourse.isCompleted) {
          await _firestore.collection('user_course_data')
              .doc(existingCourse.id)
              .update({
            'isCompleted': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        // Otherwise do nothing, course is already registered
        return;
      }
      
      // Create new entry for current course
      final data = UserCourseData(
        id: '',
        createdBy: _userId,
        courseId: courseId,
        isCompleted: false, // Currently taking this course
        grade: null,
        letterGrade: null,
      );
      
      await _firestore.collection('user_course_data').add(data.toMap());
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  /// Get all courses that are completed by the user
  List<UserCourseData> getCompletedCourses() {
    return _entries.where((entry) => entry.isCompleted).toList();
  }
  
  /// Get all courses that are currently being taken by the user
  List<UserCourseData> getCurrentCourses() {
    return _entries.where((entry) => !entry.isCompleted).toList();
  }
}

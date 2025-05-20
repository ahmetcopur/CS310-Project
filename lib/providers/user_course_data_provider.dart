import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_course_data.dart';

/// Provider to manage user-specific course data (grades, completion)
class UserCourseDataProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  List<UserCourseData> _entries = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<QuerySnapshot>? _subscription;

  List<UserCourseData> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  UserCourseDataProvider() {
    if (_userId.isNotEmpty) _listenToUserCourseData();
  }

  void _listenToUserCourseData() {
    _isLoading = true;
    notifyListeners();

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

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
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
}

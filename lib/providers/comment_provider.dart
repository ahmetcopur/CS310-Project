// filepath: lib/providers/comment_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment.dart';

/// Provider to manage comments for courses
class CommentProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Comment> _comments = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<QuerySnapshot>? _commentsSubscription;

  List<Comment> get comments => _comments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Start listening to comments for a specific course
  void loadCommentsForCourse(String courseId) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _commentsSubscription?.cancel();
    _commentsSubscription = _firestore
        .collection('courseComments')
        .where('courseId', isEqualTo: courseId)
        .snapshots()
        .listen((snapshot) {
      final loaded = snapshot.docs
          .map((doc) => Comment.fromMap(doc.data(), doc.id))
          .toList();
      // Sort by date descending
      loaded.sort((a, b) => b.date.compareTo(a.date));
      _comments = loaded;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Add a new comment
  Future<void> addComment(Comment comment) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestore.collection('courseComments').add(comment.toMap());
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _commentsSubscription?.cancel();
    super.dispose();
  }
}

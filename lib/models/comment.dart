// filepath: lib/models/comment.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a comment on a course
class Comment {
  final String id;
  final String courseId;
  final String text;
  final int rating;
  final DateTime date;
  final String userId;

  Comment({
    required this.id,
    required this.courseId,
    required this.text,
    required this.rating,
    required this.date,
    required this.userId,
  });

  /// Create a Comment from Firestore document data
  factory Comment.fromMap(Map<String, dynamic> data, String id) {
    return Comment(
      id: id,
      courseId: data['courseId'] ?? '',
      text: data['text'] ?? '',
      rating: data['rating'] ?? 0,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: data['userId'] ?? '',
    );
  }

  /// Convert this Comment to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'text': text,
      'rating': rating,
      'date': Timestamp.fromDate(date),
      'userId': userId,
    };
  }
}

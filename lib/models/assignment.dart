import 'package:cloud_firestore/cloud_firestore.dart';

class Assignment {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final DateTime dueDate;
  final double? score;
  final double? maxScore;
  final String createdBy;
  final DateTime createdAt;

  Assignment({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.dueDate,
    this.score,
    this.maxScore,
    required this.createdBy,
    required this.createdAt,
  });

  // For FirestoreService
  factory Assignment.fromMap(Map<String, dynamic> data, String id) {
    return Assignment(
      id: id,
      courseId: data['courseId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : DateTime.now(),
      score: data['score']?.toDouble(),
      maxScore: data['maxScore']?.toDouble(),
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // For Provider
  factory Assignment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Assignment(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : DateTime.now(),
      score: data['score']?.toDouble(),
      maxScore: data['maxScore']?.toDouble(),
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // For FirestoreService
  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'score': score,
      'maxScore': maxScore,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // For Provider
  Map<String, dynamic> toFirestore() {
    return toMap(); // Reuse the same Map to avoid duplication
  }

  // Helper method for creating copies with modified fields
  Assignment copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    double? score,
    double? maxScore,
  }) {
    return Assignment(
      id: this.id,
      courseId: this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      createdBy: this.createdBy,
      createdAt: this.createdAt,
    );
  }
}
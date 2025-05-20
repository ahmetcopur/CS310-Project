import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing user-specific data for a course, stored separately from the Course model.
class UserCourseData {
  final String id;
  final String createdBy;
  final String courseId;
  final bool isCompleted;
  final double? grade;
  final String? letterGrade;
  final DateTime createdAt;

  UserCourseData({
    required this.id,
    required this.createdBy,
    required this.courseId,
    this.isCompleted = false,
    this.grade,
    this.letterGrade,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Creates an instance from Firestore data
  factory UserCourseData.fromMap(Map<String, dynamic> data, String id) {
    return UserCourseData(
      id: id,
      createdBy: data['createdBy'] as String? ?? '',
      courseId: data['courseId'] as String? ?? '',
      isCompleted: data['isCompleted'] as bool? ?? false,
      grade: (data['grade'] as num?)?.toDouble(),
      letterGrade: data['letterGrade'] as String?,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Converts this instance to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'createdBy': createdBy,
      'courseId': courseId,
      'isCompleted': isCompleted,
      'grade': grade,
      'letterGrade': letterGrade,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

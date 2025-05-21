import 'package:cloud_firestore/cloud_firestore.dart';

class Assignment {
  final String id;
  final String courseId;
  final String description;
  final DateTime dueDate;

  Assignment({
    required this.id,
    required this.courseId,
    required this.description,
    required this.dueDate,
  });

  factory Assignment.fromMap(Map<String, dynamic> data, String id) {
    return Assignment(
      id: id,
      courseId: data['courseId'] ?? '',
      description: data['description'] ?? '',
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory Assignment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Assignment(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      description: data['description'] ?? '',
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
    };
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  Assignment copyWith({
    String? courseId,
    String? description,
    DateTime? dueDate,
  }) {
    return Assignment(
      id: this.id,
      courseId: courseId ?? this.courseId,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}
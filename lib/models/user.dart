import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a user profile stored in Firestore

class AppUser {
  /// Firestore document ID (same as Firebase Auth UID)
  final String id;

  /// User email
  final String email;

  /// User display name
  final String name;

  /// User major or faculty/department
  final String major;

  /// Timestamp when profile was created
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.major,
    required this.createdAt,
  });

  /// Creates an [AppUser] from Firestore document data
  factory AppUser.fromMap(Map<String, dynamic> data, String id) {
    return AppUser(
      id: id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      major: data['major'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts this [AppUser] to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'major': major,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

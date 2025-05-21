import 'package:cloud_firestore/cloud_firestore.dart';

// Class to represent a single course session (day + time)
class CourseSession {
  final String day;         // "monday", "tuesday", etc.
  final int startHour;      // 9 for 9:00
  final int endHour;        // 12 for 12:00
  final String? location;   // Room or building information

  CourseSession({
    required this.day,
    required this.startHour,
    required this.endHour,
    this.location,
  });

  // Convert to and from Firestore
  factory CourseSession.fromMap(Map<String, dynamic> data) {
    return CourseSession(
      day: data['day'] ?? '',
      startHour: data['startHour'] ?? 0,
      endHour: data['endHour'] ?? 0,
      location: data['location'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'startHour': startHour,
      'endHour': endHour,
      'location': location,
    };
  }

  // Formatted display
  String get formattedSchedule {
    return '$day ${startHour.toString().padLeft(2, '0')}:00-${endHour.toString().padLeft(2, '0')}:00';
  }

  // Location display
  String get formattedLocation {
    return location != null ? ' ($location)' : '';
  }
}

class Course {
  final String id;
  final String code;
  final String name;
  final int credits;
  final String? instructor;
  final List<CourseSession> sessions;
  final List<String> requirements;

  Course({
    required this.id,
    required this.code,
    required this.name,
    required this.credits,
    this.instructor,
    this.sessions = const [],
    this.requirements = const [],
  });

  // For FirestoreService
  factory Course.fromMap(Map<String, dynamic> data, String id) {
    // Convert sessions from List<Map> to List<CourseSession>
    List<CourseSession> sessions = [];
    if (data['sessions'] != null && data['sessions'] is List) {
      sessions = (data['sessions'] as List)
          .map((sessionData) => CourseSession.fromMap(sessionData))
          .toList();
    }
    // Parse prerequisites from List to List<String>
    List<String> requirements = [];
    if (data['requirements'] != null && data['requirements'] is List) {
      requirements = (data['requirements'] as List)
          .map((e) => e.toString())
          .toList();
    }

    return Course(
      id: id,
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      credits: data['credits'] ?? 0,
      instructor: data['instructor'],
      sessions: sessions,
      requirements: requirements,
    );
  }

  // For Provider
  factory Course.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Convert sessions from List<Map> to List<CourseSession>
    List<CourseSession> sessions = [];
    if (data['sessions'] != null && data['sessions'] is List) {
      sessions = (data['sessions'] as List)
          .map((sessionData) => CourseSession.fromMap(sessionData))
          .toList();
    }
    // Parse prerequisites from List to List<String>
    List<String> requirements = [];
    if (data['requirements'] != null && data['requirements'] is List) {
      requirements = (data['requirements'] as List)
          .map((e) => e.toString())
          .toList();
    }

    return Course(
      id: doc.id,
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      credits: data['credits'] ?? 0,
      instructor: data['instructor'],
      sessions: sessions,
      requirements: requirements,
    );
  }

  // For FirestoreService
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'credits': credits,
      'instructor': instructor,
      'sessions': sessions.map((session) => session.toMap()).toList(),
      'requirements': requirements,
    };
  }

  // For Provider
  Map<String, dynamic> toFirestore() {
    return toMap(); // Reuse the same Map to avoid duplication
  }

  // Helper method for creating copies with modified fields
  Course copyWith({
    String? code,
    String? name,
    int? credits,
    String? instructor,
    List<CourseSession>? sessions,
    List<String>? requirements,
  }) {
    return Course(
      id: id,
      code: code ?? this.code,
      name: name ?? this.name,
      credits: credits ?? this.credits,
      instructor: instructor ?? this.instructor,
      sessions: sessions ?? this.sessions,
      requirements: requirements ?? this.requirements,
    );
  }

  // Add a new session to this course
  Course addSession(CourseSession session) {
    final newSessions = List<CourseSession>.from(sessions)..add(session);
    return copyWith(sessions: newSessions);
  }

  // Remove a session from this course
  Course removeSession(int index) {
    if (index < 0 || index >= sessions.length) return this;
    final newSessions = List<CourseSession>.from(sessions)..removeAt(index);
    return copyWith(sessions: newSessions);
  }

  // Helper to check if a course has a session at a specific day and time
  bool hasSessionAt(String day, int hour) {
    return sessions.any((session) =>
    session.day == day && hour >= session.startHour && hour < session.endHour
    );
  }

  // Get all sessions for a specific day
  List<CourseSession> getSessionsForDay(String day) {
    return sessions.where((session) => session.day == day).toList();
  }

  // Get formatted sessions for display
  String get formattedSessions {
    if (sessions.isEmpty) return "No scheduled sessions";
    return sessions.map((s) => "${s.formattedSchedule}${s.formattedLocation}").join("\n");
  }
}
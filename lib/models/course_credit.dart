/// Model for mapping a course to its credit type within a specific program or faculty.

enum CreditType { 
  area,
  core,
  free,
}

/// Represents how a given course (by code) should be counted for a particular program or faculty.
class CourseCredit {
  /// Course code (e.g., "CS201").
  final String courseCode;

  /// Map of program codes to how this course counts toward each program's requirements.
  final Map<String, CreditType> creditTypes;

  const CourseCredit({
    required this.courseCode,
    required this.creditTypes,
  });

  /// Deserialize from JSON
  factory CourseCredit.fromJson(Map<String, dynamic> json) {
    final raw = json['creditTypes'] as Map<String, dynamic>? ?? {};
    final creditMap = raw.map((prog, val) => MapEntry(
      prog,
      CreditType.values.firstWhere(
        (e) => e.toString().split('.').last == val,
        orElse: () => CreditType.free,
      ),
    ));
    return CourseCredit(
      courseCode: json['courseCode'] as String,
      creditTypes: creditMap,
    );
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'courseCode': courseCode,
      'creditTypes': creditTypes.map((prog, ct) => MapEntry(prog, ct.toString().split('.').last)),
    };
  }
}

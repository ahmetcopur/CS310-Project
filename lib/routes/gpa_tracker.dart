import 'package:flutter/material.dart';
import 'package:su_credit/utils/colors.dart';
import 'package:su_credit/utils/styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GpaTrackerPage extends StatefulWidget {
  const GpaTrackerPage({super.key});

  @override
  State<GpaTrackerPage> createState() => _GpaTrackerPageState();
}

class _GpaTrackerPageState extends State<GpaTrackerPage> {
  static const Map<String, double> gradePoints = {
    'A': 4.00,
    'A-': 3.70,
    'B+': 3.30,
    'B': 3.00,
    'B-': 2.70,
    'C+': 2.30,
    'C': 2.00,
    'C-': 1.70,
    'D+': 1.30,
    'D': 1.00,
    'F': 0.00,
  };

  // Firebase references
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  List<_Course> _courses = [];
  bool _isLoading = true;
  double _gpa = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  // Load courses from Firestore
  Future<void> _loadCourses() async {
    if (_userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Load user-specific course entries
      final userCourseSnapshots = await _firestore
          .collection('user_course_data')
          .where('createdBy', isEqualTo: _userId)
          .where('isCompleted', isEqualTo: true)
          .get();
      final List<_Course> loadedCourses = [];
      for (var ucDoc in userCourseSnapshots.docs) {
        final ucData = ucDoc.data();
        final courseId = ucData['courseId'] as String? ?? '';
        final letterGrade = ucData['letterGrade'] as String? ?? 'N/A';
        // Fetch course code
        final courseDoc = await _firestore.collection('courses').doc(courseId).get();
        final courseCode = courseDoc.data()?['code'] as String? ?? '';
        loadedCourses.add(_Course(id: ucDoc.id, code: courseCode, grade: letterGrade));
      }
      if (loadedCourses.isEmpty) {
        _loadPlaceholderCourses();
      } else {
        setState(() {
          _courses = loadedCourses;
          _gpa = _calculateLocalGPA();
          _isLoading = false;
        });
      }
    } catch (e) {
      _loadPlaceholderCourses();
    }
  }

  // Load placeholder courses if no data is available
  void _loadPlaceholderCourses() {
    setState(() {
      _courses = [
        _Course(code: 'PSY‑340', grade: 'B'),
        _Course(code: 'CS‑310', grade: 'A-'),
        _Course(code: 'CS‑408', grade: 'B+'),
        _Course(code: 'CS‑307', grade: 'C'),
        _Course(code: 'ORG‑301', grade: 'D+'),
        _Course(code: 'SPS‑303', grade: 'C-'),
      ];
      _gpa = _calculateLocalGPA();
      _isLoading = false;
    });
  }

  // Calculate GPA locally (only used for placeholder data)
  double _calculateLocalGPA() {
    if (_courses.isEmpty) return 0;
    final total = _courses
        .where((c) => gradePoints.containsKey(c.grade))
        .map((c) => gradePoints[c.grade]!)
        .fold(0.0, (a, b) => a + b);
    final countedCourses = _courses.where((c) => gradePoints.containsKey(c.grade)).length;
    return countedCourses > 0 ? total / countedCourses : 0.0;
  }

  // Save a new course grade to Firestore
  Future<void> _addCourseToFirestore(String code, String grade) async {
    if (_userId == null) return;

    try {
      // Resolve or create course document
      String courseId;
      final courseSnap = await _firestore.collection('courses')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();
      if (courseSnap.docs.isNotEmpty) {
        courseId = courseSnap.docs.first.id;
      } else {
        final newCourse = await _firestore.collection('courses').add({
          'code': code,
          'name': code,
          'credits': 3,
          'instructor': null,
          'sessions': [],
          'requirements': [],
        });
        courseId = newCourse.id;
      }

      // Upsert user course data
      final ucColl = _firestore.collection('user_course_data');
      final ucQuery = await ucColl
          .where('createdBy', isEqualTo: _userId)
          .where('courseId', isEqualTo: courseId)
          .limit(1)
          .get();
      if (ucQuery.docs.isNotEmpty) {
        final docId = ucQuery.docs.first.id;
        await ucColl.doc(docId).update({
          'letterGrade': grade,
          'grade': gradePoints[grade],
          'isCompleted': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        setState(() {
          _courses = _courses
              .map((c) => c.code == code ? _Course(id: docId, code: code, grade: grade) : c)
              .toList();
        });
      } else {
        final docRef = await ucColl.add({
          'createdBy': _userId,
          'courseId': courseId,
          'letterGrade': grade,
          'grade': gradePoints[grade],
          'isCompleted': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        setState(() {
          _courses.add(_Course(id: docRef.id, code: code, grade: grade));
        });
      }
      // Update GPA locally
      setState(() {
        _gpa = _calculateLocalGPA();
      });
    } catch (e) {
      // If Firebase fails, just add to local state
      setState(() {
        _courses.add(_Course(code: code, grade: grade));
        _gpa = _calculateLocalGPA();
      });
    }
  }

  // Delete a course grade from Firestore
  Future<void> _removeCourse(int index) async {
    final course = _courses[index];

    setState(() {
      _courses.removeAt(index);
      _gpa = _calculateLocalGPA(); // Update local GPA immediately for UI
    });

    if (_userId == null) return;

    try {
      // Mark entry incomplete in user_course_data
      await _firestore.collection('user_course_data').doc(course.id).update({
        'isCompleted': false,
        'letterGrade': null,
        'grade': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Recalculate GPA
    } catch (e) {
      // If update fails, just continue with local state update
    }
  }

  Future<void> _showAddDialog() async {
    String code = '';
    String grade = 'A';
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Course'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Course Code'),
              onChanged: (v) => code = v.trim(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: grade,
              items: gradePoints.keys
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => grade = v!,
              decoration: const InputDecoration(labelText: 'Grade'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (code.isNotEmpty) {
                _addCourseToFirestore(code, grade);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(8, 40, 16, 12),
            width: double.infinity,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: AppColors.surface),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 6),
                Text(
                  'GPA Tracker',
                  style: AppStyles.screenTitle.copyWith(
                    color: AppColors.surface,
                    fontSize: 28,
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: AppColors.primary,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Container(
                width: 220,
                height: 220,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Current GPA',
                      style: AppStyles.sectionHeading.copyWith(
                        color: AppColors.surface,
                        fontSize: 18,
                      ),
                    ),
                    _isLoading
                        ? CircularProgressIndicator(color: AppColors.surface)
                        : Text(
                      _gpa.toStringAsFixed(2),
                      style: AppStyles.screenTitle.copyWith(
                        color: AppColors.surface,
                        fontSize: 64,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Current Program',
                style: AppStyles.sectionHeading.copyWith(
                  color: AppColors.heading,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              itemCount: _courses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final c = _courses[i];
                return Dismissible(
                  key: ValueKey(c.code),
                  background: Container(
                    color: AppColors.accentRed,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: const Icon(Icons.delete, color: AppColors.surface),
                  ),
                  onDismissed: (_) => _removeCourse(i),
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.code.toUpperCase(),
                            style: AppStyles.bodyText.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.heading,
                            ),
                          ),
                        ),
                        Container(
                          width: 60,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            c.grade,
                            style: AppStyles.bodyText.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removeCourse(i),
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Course {
  final String? id; // Firestore document ID
  final String code;
  final String grade;
  const _Course({this.id, required this.code, required this.grade});
}
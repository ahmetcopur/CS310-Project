import 'package:flutter/material.dart';
import 'package:su_credit/utils/colors.dart';
import 'package:su_credit/utils/styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:su_credit/providers/gpa_provider.dart';
import 'package:provider/provider.dart';
import 'package:su_credit/providers/user_course_data_provider.dart';
import 'package:su_credit/providers/course_provider.dart';

class GpaTrackerPage extends StatefulWidget {
  const GpaTrackerPage({super.key});
  @override
  State<GpaTrackerPage> createState() => _GpaTrackerPageState();
}

class _GpaTrackerPageState extends State<GpaTrackerPage> {
  // In-memory list of new courses: each map has 'credits' (int) and 'grade' (String)
  final List<Map<String, dynamic>> _newCourses = [];
  static const Map<String, double> _gradePoints = {
    'A': 4.00, 'A-': 3.70, 'B+': 3.30, 'B': 3.00,
    'B-': 2.70, 'C+': 2.30, 'C': 2.00, 'C-': 1.70,
    'D+': 1.30, 'D': 1.00, 'F': 0.00,
  };

  Future<void> _showAddSemesterCourseDialog() async {
    String name = '';
    int credits = 3;
    String grade = 'A';
    final letters = _gradePoints.keys.toList();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Course'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Course Name'),
                onChanged: (v) => name = v.trim(),
              ),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Credits'),
                onChanged: (v) {
                  final c = int.tryParse(v);
                  if (c != null) credits = c;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: grade,
                items: letters
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => grade = v!,
                decoration: const InputDecoration(labelText: 'Grade'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
          ],
        );
      },
    );
    if (result == true && _newCourses.length < 7) {
      setState(() => _newCourses.add({'name': name, 'credits': credits, 'grade': grade}));
    }
  }

  Future<void> _showEditCourseDialog(int index) async {
    String grade = _newCourses[index]['grade'] as String;
    final letters = _gradePoints.keys.toList();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Grade'),
        content: DropdownButtonFormField<String>(
          value: grade,
          items: letters.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
          onChanged: (v) => grade = v!,
          decoration: const InputDecoration(labelText: 'Grade'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (result == true) {
      setState(() {
        _newCourses[index]['grade'] = grade;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProv = Provider.of<UserCourseDataProvider>(context);
    final courseProv = Provider.of<CourseProvider>(context);
    // Compute completed semester points & credits
    double basePoints = 0;
    int baseCredits = 0;
    for (var entry in userProv.getCompletedCourses()) {
      final matches = courseProv.courses.where((c) => c.id == entry.courseId);
      if (matches.isEmpty) continue; // skip if course not found
      final course = matches.first;
      final letter = entry.letterGrade ?? 'F';
      final gp = _gradePoints[letter] ?? 0;
      basePoints += gp * course.credits;
      baseCredits += course.credits;
    }
    // Add new semester courses
    double newPoints = 0;
    int newCredits = 0;
    for (var m in _newCourses) {
      final cred = m['credits'] as int;
      newPoints += (_gradePoints[m['grade']] ?? 0) * cred;
      newCredits += cred;
    }
    final totalCredits = baseCredits + newCredits;
    final totalPoints = basePoints + newPoints;
    final displayGpa = totalCredits > 0 ? totalPoints / totalCredits : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _newCourses.length < 7 ? _showAddSemesterCourseDialog : null,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.surface),
      ),
      body: Column(
        children: [
          // header and GPA circle
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
                Text('GPA Tracker', style: AppStyles.screenTitle.copyWith(color: AppColors.surface, fontSize: 28)),
              ],
            ),
          ),
          Container(
            color: AppColors.primary,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Container(
                width: 220, height: 220,
                decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                child: Center(
                  child: Text(displayGpa.toStringAsFixed(2), style: AppStyles.screenTitle.copyWith(color: AppColors.surface, fontSize: 64)),
                ),
              ),
            ),
          ),
          // list of new courses
          Expanded(
            child: ListView.builder(
              itemCount: _newCourses.length,
              itemBuilder: (_, i) {
                final m = _newCourses[i];
                return ListTile(
                  title: Text('${m['name']} - ${m['credits']}cr'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(m['grade']),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showEditCourseDialog(i),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                        onPressed: () => setState(() => _newCourses.removeAt(i)),
                      ),
                    ],
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

class _AddCourseDialog extends StatefulWidget {
  @override
  State<_AddCourseDialog> createState() => _AddCourseDialogState();
}

class _AddCourseDialogState extends State<_AddCourseDialog> {
  String code = '';
  String grade = 'A';
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
            onChanged: (v) => setState(() => grade = v!),
            decoration: const InputDecoration(labelText: 'Grade'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (code.isNotEmpty) {
              await _addCourseToFirestore(code, grade);
              // Force refresh GPA provider
              Provider.of<GpaProvider>(context, listen: false).refreshGpa();
            }
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _addCourseToFirestore(String code, String grade) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    try {
      String courseId;
      final courseSnap = await FirebaseFirestore.instance
          .collection('courses')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();
      if (courseSnap.docs.isNotEmpty) {
        courseId = courseSnap.docs.first.id;
      } else {
        final newCourse = await FirebaseFirestore.instance.collection('courses').add({
          'code': code,
          'name': code,
          'credits': 3,
          'instructor': null,
          'sessions': [],
          'requirements': [],
        });
        courseId = newCourse.id;
      }
      final ucColl = FirebaseFirestore.instance.collection('user_course_data');
      final ucQuery = await ucColl
          .where('createdBy', isEqualTo: userId)
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
      } else {
        await ucColl.add({
          'createdBy': userId,
          'courseId': courseId,
          'letterGrade': grade,
          'grade': gradePoints[grade],
          'isCompleted': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Optionally handle error
    }
  }
}
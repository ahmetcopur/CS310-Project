import 'package:flutter/material.dart';
import 'package:su_credit/utils/colors.dart';
import 'package:su_credit/utils/styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:su_credit/providers/gpa_provider.dart';
import 'package:provider/provider.dart';

class GpaTrackerPage extends StatelessWidget {
  const GpaTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => _AddCourseDialog(),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.surface), // Changed icon color to AppColors.surface
    ),
      body: Consumer<GpaProvider>(
        builder: (context, gpaProvider, _) {
          return Column(
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
                        gpaProvider.isLoading
                            ? CircularProgressIndicator(color: AppColors.surface)
                            : Text(
                                gpaProvider.gpa.toStringAsFixed(2),
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
              // No list of courses is shown here
            ],
          );
        },
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
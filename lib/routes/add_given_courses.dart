import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:su_credit/utils/colors.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../models/user_course_data.dart';
import '../models/course.dart';
import '../providers/user_course_data_provider.dart';
import '../providers/course_provider.dart';

class AddGivenCoursesPage extends StatefulWidget {
  const AddGivenCoursesPage({super.key});

  @override
  State<AddGivenCoursesPage> createState() => _AddGivenCoursesPageState();
}

class _AddGivenCoursesPageState extends State<AddGivenCoursesPage> {
  final TextEditingController _gradeController = TextEditingController();
  String? _selectedCourseId;
  String? _editingCourseDocId;

  static const List<String> _validGrades = [
    'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'F', 'S', 'U', 'P', 'NP', 'W', 'NA', 'I'
  ];

  String? _validateGrade(String? value) {
    if (value == null || value.trim().isEmpty) return 'Grade required';
    final formatted = value.trim().toUpperCase();
    if (!_validGrades.contains(formatted)) {
      return 'Invalid grade';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);
      if (courseProvider.courses.isNotEmpty) {
        setState(() {
          _selectedCourseId = courseProvider.courses.first.id;
        });
      }
    });
  }

  @override
  void dispose() {
    _gradeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userCourseProvider = Provider.of<UserCourseDataProvider>(context);
    final courseProvider = Provider.of<CourseProvider>(context);
    final userCourses = userCourseProvider.entries;
    final allCourses = courseProvider.courses;
    final isLoading = userCourseProvider.isLoading || courseProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Given Courses'),
        backgroundColor: AppColors.primary,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Already Given Courses:',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: userCourses.length,
                      itemBuilder: (context, i) {
                        final c = userCourses[i];
                        final course = allCourses.firstWhere(
                          (course) => course.id == c.courseId,
                          orElse: () => Course(
                            id: c.courseId,
                            code: c.courseId,
                            name: '',
                            credits: 0,
                          ),
                        );
                        return ListTile(
                          title: Text('${course.code} - ${course.name}'),
                          subtitle: Text('Grade: ${c.letterGrade ?? c.grade?.toString() ?? '-'}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  setState(() {
                                    _editingCourseDocId = c.id;
                                    _selectedCourseId = c.courseId;
                                    _gradeController.text = c.letterGrade ?? c.grade?.toString() ?? '';
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  await userCourseProvider.deleteEntry(c.id);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  const Text('Add a Course:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  DropdownButtonFormField<String>(
                    value: _selectedCourseId ?? (allCourses.isNotEmpty ? allCourses.first.id : null),
                    items: allCourses.map((course) {
                      return DropdownMenuItem<String>(
                        value: course.id,
                        child: Text('${course.code} - ${course.name}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCourseId = val;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Course'),
                  ),
                  TextFormField(
                    controller: _gradeController,
                    decoration: const InputDecoration(labelText: 'Grade'),
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      // Only allow letters, plus, minus
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z+-]')),
                    ],
                    onChanged: (val) {
                      final upper = val.toUpperCase();
                      if (val != upper) {
                        _gradeController.value = _gradeController.value.copyWith(
                          text: upper,
                          selection: TextSelection.collapsed(offset: upper.length),
                        );
                      }
                      setState(() {});
                    },
                    validator: _validateGrade,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: isLoading || _selectedCourseId == null || _validateGrade(_gradeController.text) != null
                        ? null
                        : () async {
                            if (_editingCourseDocId != null) {
                              // Update
                              final entry = userCourses.firstWhere((e) => e.id == _editingCourseDocId);
                              await userCourseProvider.upsertEntry(
                                UserCourseData(
                                  id: entry.id,
                                  createdBy: entry.createdBy,
                                  courseId: entry.courseId,
                                  isCompleted: entry.isCompleted,
                                  grade: double.tryParse(_gradeController.text.trim()),
                                  letterGrade: _gradeController.text.trim(),
                                  createdAt: entry.createdAt,
                                ),
                              );
                              setState(() {
                                _editingCourseDocId = null;
                                _gradeController.clear();
                              });
                            } else {
                              // Prevent duplicate
                              if (userCourses.any((e) => e.courseId == _selectedCourseId)) return;
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null) return;
                              await userCourseProvider.upsertEntry(
                                UserCourseData(
                                  id: '',
                                  createdBy: user.uid,
                                  courseId: _selectedCourseId!,
                                  isCompleted: true,
                                  grade: double.tryParse(_gradeController.text.trim()),
                                  letterGrade: _gradeController.text.trim(),
                                  createdAt: DateTime.now(),
                                ),
                              );
                              setState(() {
                                _gradeController.clear();
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: Text(_editingCourseDocId != null ? 'Update Course' : 'Add Course'),
                  ),
                ],
              ),
            ),
    );
  }
}

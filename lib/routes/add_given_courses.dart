import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:su_credit/utils/colors.dart';

class AddGivenCoursesPage extends StatefulWidget {
  const AddGivenCoursesPage({super.key});

  @override
  State<AddGivenCoursesPage> createState() => _AddGivenCoursesPageState();
}

class _AddGivenCoursesPageState extends State<AddGivenCoursesPage> {
  final TextEditingController _courseCodeController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('user_course_data')
        .where('userId', isEqualTo: user.uid)
        .get();
    setState(() {
      _courses = snapshot.docs.map((doc) => doc.data()).toList();
      _isLoading = false;
    });
  }

  Future<void> _addCourse() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final code = _courseCodeController.text.trim();
    final grade = _gradeController.text.trim();
    if (code.isEmpty || grade.isEmpty) return;
    await FirebaseFirestore.instance.collection('user_course_data').add({
      'userId': user.uid,
      'courseCode': code,
      'grade': grade,
      'addedAt': FieldValue.serverTimestamp(),
    });
    _courseCodeController.clear();
    _gradeController.clear();
    _fetchCourses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Given Courses'),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
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
                      itemCount: _courses.length,
                      itemBuilder: (context, i) {
                        final c = _courses[i];
                        return ListTile(
                          title: Text(c['courseCode'] ?? ''),
                          subtitle: Text('Grade: ${c['grade'] ?? '-'}'),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  const Text('Add a Course:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  TextField(
                    controller: _courseCodeController,
                    decoration: const InputDecoration(labelText: 'Course Code'),
                  ),
                  TextField(
                    controller: _gradeController,
                    decoration: const InputDecoration(labelText: 'Grade'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _addCourse,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Add Course'),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _courseCodeController.dispose();
    _gradeController.dispose();
    super.dispose();
  }
}

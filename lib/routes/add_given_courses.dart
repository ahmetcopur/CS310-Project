import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:su_credit/utils/colors.dart'; // Ensure this path is correct
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../models/user_course_data.dart';
import '../models/course.dart';
import '../providers/user_course_data_provider.dart';
import '../providers/course_provider.dart';
import '../providers/gpa_provider.dart';

class AddGivenCoursesPage extends StatefulWidget {
  const AddGivenCoursesPage({super.key});

  @override
  State<AddGivenCoursesPage> createState() => _AddGivenCoursesPageState();
}

class _AddGivenCoursesPageState extends State<AddGivenCoursesPage> {
  final TextEditingController _gradeController = TextEditingController();
  String? _selectedCourseId;
  String? _editingCourseDocId; // Stores the document ID of UserCourseData being edited

  static const List<String> _validGrades = [
    'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'F',
    'S', 'U', 'P', 'NP', 'W', 'NA', 'I'
  ];

  String? _validateGrade(String? value) {
    if (value == null || value.trim().isEmpty) return 'Grade is required';
    final formattedGrade = value.trim().toUpperCase();
    if (!_validGrades.contains(formattedGrade)) {
      return 'Invalid grade (e.g., A, B+, S)';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _gradeController.addListener(() {
      // Re-evaluate button's enabled state based on grade validation
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);
      // Initialize _selectedCourseId if not editing, null, and courses are available
      if (_editingCourseDocId == null && _selectedCourseId == null && courseProvider.courses.isNotEmpty) {
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

  InputDecoration _inputDecoration(String label, {String? hint, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.9)),
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textTertiary.withOpacity(0.7)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: AppColors.text.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: AppColors.text.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: AppColors.accentRed, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: AppColors.accentRed, width: 1.5),
      ),
      filled: true,
      fillColor: AppColors.background.withOpacity(0.8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      suffixIcon: suffixIcon,
    );
  }

  void _resetForm() {
    _gradeController.clear();
    _editingCourseDocId = null;
    // Optionally reset selected course to the first available if not empty
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    if (courseProvider.courses.isNotEmpty) {
      _selectedCourseId = courseProvider.courses.first.id;
    } else {
      _selectedCourseId = null;
    }
    setState(() {});
  }

  Future<void> _submitForm() async {
    final userCourseProvider = Provider.of<UserCourseDataProvider>(context, listen: false);
    final gpaProvider = Provider.of<GpaProvider>(context, listen: false);
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    String? courseIdToProcess = _selectedCourseId;

    // If _selectedCourseId is somehow null but courses are available, pick first (safety net)
    // This helps if the UI shows a default but state _selectedCourseId didn't update.
    // However, the button should be disabled if _selectedCourseId is null.
    if (courseIdToProcess == null && courseProvider.courses.isNotEmpty) {
      courseIdToProcess = courseProvider.courses.first.id;
    }

    if (courseIdToProcess == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select a course.'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
      return;
    }

    final gradeText = _gradeController.text.trim().toUpperCase();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Should be handled by route guards

    try {
      if (_editingCourseDocId != null) {
        // Update existing entry
        final entry = userCourseProvider.entries.firstWhere((e) => e.id == _editingCourseDocId);
        await userCourseProvider.upsertEntry(
          UserCourseData(
            id: entry.id,
            createdBy: entry.createdBy,
            courseId: entry.courseId, // Course ID cannot be changed during edit
            isCompleted: true, // Given courses are assumed completed
            grade: double.tryParse(gradeText), // Firestore handles non-numeric as null
            letterGrade: gradeText,
            createdAt: entry.createdAt, // Preserve original creation date
          ),
        );
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course updated successfully!'), backgroundColor: AppColors.coolGreen));

      } else {
        // Create new entry
        // Prevent duplicate addition
        if (userCourseProvider.entries.any((e) => e.courseId == courseIdToProcess)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('This course has already been added with a grade.'),
                backgroundColor: AppColors.accentOrange,
              ),
            );
          }
          return;
        }

        await userCourseProvider.upsertEntry(
          UserCourseData(
            id: '', // Firestore will generate ID
            createdBy: user.uid,
            courseId: courseIdToProcess,
            isCompleted: true, // Given courses are completed
            grade: double.tryParse(gradeText),
            letterGrade: gradeText,
            createdAt: DateTime.now(),
          ),
        );
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course added successfully!'), backgroundColor: AppColors.coolGreen));
      }

      gpaProvider.refreshGpa(); // Refresh GPA after add/update
      _resetForm();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final userCourseProvider = Provider.of<UserCourseDataProvider>(context);
    final courseProvider = Provider.of<CourseProvider>(context);

    final userGivenCourses = userCourseProvider.entries.where((e) => e.isCompleted).toList(); // Only show completed/given courses
    final allCourses = courseProvider.courses;
    final isLoading = userCourseProvider.isLoading || courseProvider.isLoading;

    // Synchronize _selectedCourseId if it's null, not editing, and courses are available
    if (_editingCourseDocId == null && _selectedCourseId == null && allCourses.isNotEmpty) {
      _selectedCourseId = allCourses.first.id;
    }
    // If selected course is no longer in allCourses (and not editing), reset it
    if (_editingCourseDocId == null && _selectedCourseId != null && !allCourses.any((c) => c.id == _selectedCourseId)) {
      _selectedCourseId = allCourses.isNotEmpty ? allCourses.first.id : null;
    }


    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Manage Graded Courses', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 2.0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 20),
            Text('Loading course data...', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
          ],
        ),
      )
          : SingleChildScrollView( // Added SingleChildScrollView for responsiveness
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch buttons etc.
          children: [
            Text(
              'Your Graded Courses',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.heading),
            ),
            const SizedBox(height: 12),
            userGivenCourses.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30.0),
                child: Text(
                  'No graded courses added yet.',
                  style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            )
                : ListView.builder(
              shrinkWrap: true, // Important for ListView inside SingleChildScrollView
              physics: const NeverScrollableScrollPhysics(), // Disable scrolling for this ListView
              itemCount: userGivenCourses.length,
              itemBuilder: (context, i) {
                final userCourseEntry = userGivenCourses[i];
                final courseDetails = allCourses.firstWhere(
                      (c) => c.id == userCourseEntry.courseId,
                  orElse: () => Course( // Fallback Course object
                    id: userCourseEntry.courseId,
                    code: 'UNKNOWN',
                    name: 'Course details not found',
                    credits: 0,
                  ),
                );
                return Card(
                  elevation: 3.0,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    title: Text(
                      '${courseDetails.code} - ${courseDetails.name}',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 16),
                    ),
                    subtitle: Text(
                      'Grade: ${userCourseEntry.letterGrade ?? userCourseEntry.grade?.toStringAsFixed(1) ?? 'N/A'}',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_note, color: AppColors.secondary, size: 26),
                          tooltip: 'Edit Grade',
                          onPressed: () {
                            setState(() {
                              _editingCourseDocId = userCourseEntry.id;
                              _selectedCourseId = userCourseEntry.courseId; // Keep the same course selected
                              _gradeController.text = userCourseEntry.letterGrade ?? userCourseEntry.grade?.toString() ?? '';
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.accentRed, size: 26),
                          tooltip: 'Delete Course Record',
                          onPressed: () async {
                            // Confirmation dialog
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Confirm Deletion'),
                                content: Text('Are you sure you want to delete the grade for ${courseDetails.code}?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Delete', style: TextStyle(color: AppColors.accentRed))),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await userCourseProvider.deleteEntry(userCourseEntry.id);
                              Provider.of<GpaProvider>(context, listen: false).refreshGpa();
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course record deleted.'), backgroundColor: AppColors.coolGreen));
                              if (_editingCourseDocId == userCourseEntry.id) _resetForm(); // Reset form if deleting the one being edited
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Divider(color: AppColors.text.withOpacity(0.5), thickness: 1),
            const SizedBox(height: 16),
            Text(
              _editingCourseDocId != null ? 'Edit Course Grade' : 'Add New Graded Course',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.heading),
            ),
            const SizedBox(height: 16),
            if (allCourses.isNotEmpty)
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: (_selectedCourseId != null && allCourses.any((c) => c.id == _selectedCourseId))
                    ? _selectedCourseId
                    : (allCourses.isNotEmpty ? allCourses.first.id : null),
                items: allCourses.map((course) {
                  return DropdownMenuItem<String>(
                    value: course.id,
                    child: Text('${course.code} - ${course.name}', overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: _editingCourseDocId != null ? null : (val) { // Disable changing course when editing
                  setState(() {
                    _selectedCourseId = val;
                  });
                },
                decoration: _inputDecoration('Select Course', hint: 'Choose a course'),
                disabledHint: _editingCourseDocId != null && _selectedCourseId != null
                    ? Text(allCourses.firstWhere((c) => c.id == _selectedCourseId, orElse: () => Course(id: '', name: 'Selected Course', code: '', credits: 0)).name)
                    : null,
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'No courses available to add. Please ensure courses are loaded.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _gradeController,
              decoration: _inputDecoration('Grade (e.g., A, B+, S)', hint: 'Enter letter grade'),
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z+\-]')), // Allow letters, +, -
                LengthLimitingTextInputFormatter(2), // Max 2 chars e.g. A-
              ],
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: _validateGrade,
              onChanged: (val) {
                final upper = val.toUpperCase();
                if (val != upper) {
                  _gradeController.value = _gradeController.value.copyWith(
                    text: upper,
                    selection: TextSelection.collapsed(offset: upper.length),
                  );
                }
                // setState is called by listener
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                elevation: 2.0,
              ),
              onPressed: (isLoading || _selectedCourseId == null || _validateGrade(_gradeController.text) != null || allCourses.isEmpty)
                  ? null // Disabled state
                  : _submitForm,
              child: Text(_editingCourseDocId != null ? 'Update Grade' : 'Add Graded Course'),
            ),
            if (_editingCourseDocId != null)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: TextButton(
                  onPressed: _resetForm,
                  child: const Text('Cancel Edit', style: TextStyle(color: AppColors.secondary)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
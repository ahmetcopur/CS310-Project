import 'package:flutter/material.dart';
import 'package:su_credit/utils/colors.dart';
import 'package:su_credit/utils/styles.dart';
import 'package:provider/provider.dart';
import 'package:su_credit/providers/gpa_provider.dart';
import 'dart:math' as math;
import 'package:su_credit/providers/assignment_provider.dart';
import 'package:su_credit/routes/schedule.dart';
import 'package:intl/intl.dart';
import 'package:flutter/painting.dart';
import 'dart:ui' as ui;

// Assuming AppColors and AppStyles are defined as before

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        children: [
          _DashboardHeader(title: 'Student Dashboard'),
          Expanded(
            child: Consumer<GpaProvider>(
              builder: (context, gpaProvider, _) {
                if (gpaProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, '/graduation_progress'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.surface,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.school, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                'View Graduation Progress',
                                style: AppStyles.sectionHeading.copyWith(
                                  color: AppColors.surface,
                                  fontSize: 18,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.arrow_forward_ios, size: 18),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _GpaStatusCard(currentGpa: gpaProvider.gpa),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      _SectionHeader(
                        title: 'Exam & Assignments',
                        buttonLabel: 'See More',
                        onPressed: () => Navigator.pushNamed(context, '/assignments'),
                      ),
                      _ExamList(),
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

class _DashboardHeader extends StatelessWidget {
  final String title;
  const _DashboardHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(12, 60, 20, 16),
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.surface),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppStyles.screenTitle.copyWith(
              color: AppColors.surface,
              fontSize: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String buttonLabel;
  final VoidCallback onPressed;
  const _SectionHeader({
    required this.title,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: AppStyles.screenTitle.copyWith(
              color: AppColors.primary,
              fontSize: 24,
            ),
          ),
          const Spacer(),
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onPressed,
            child: Text(
              buttonLabel,
              style: AppStyles.bodyText.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GpaStatusCard extends StatelessWidget {
  final double currentGpa;
  const _GpaStatusCard({required this.currentGpa});

  Color _getGpaColor(double gpa) {
    if (gpa > 3.5) {
      return Colors.amber.shade600; // High Honor
    } else if (gpa > 3.0) {
      return Colors.green.shade600; // Honor
    } else if (gpa >= 2.0) {
      return Colors.orange.shade600; // Okay / Needs Improvement
    } else {
      return Colors.red.shade600; // Danger / Cannot Graduate
    }
  }

  @override
  Widget build(BuildContext context) {
    String graduationStatusText = '';
    Color graduationStatusTextColor = AppColors.textPrimary; // Default

    if (currentGpa > 3.5) {
      graduationStatusText = 'Graduation Status: High Honor';
      graduationStatusTextColor = _getGpaColor(currentGpa);
    } else if (currentGpa > 3.0 && currentGpa < 3.5) { // Ensure GPA < 3.5 for Honor as per previous prompt.
      graduationStatusText = 'Graduation Status: Honor';
      graduationStatusTextColor = _getGpaColor(currentGpa);
    } else if (currentGpa < 2.0) {
      graduationStatusText = 'Graduation Status: Can not graduate';
      graduationStatusTextColor = _getGpaColor(currentGpa);
    }


    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
              'GPA Status',
              style: AppStyles.screenTitle.copyWith(
                color: AppColors.primary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              )
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 150, // Adjust size as needed for the circular gauge
            height: 150,
            child: CustomPaint(
              painter: _CircularGpaPainter(
                gpa: currentGpa,
                gpaColor: _getGpaColor(currentGpa), // Color for the progress arc
                trackColor: Colors.grey.shade300, // Background track color
                strokeWidth: 12.0, // Thickness of the arcs
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (graduationStatusText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                graduationStatusText,
                textAlign: TextAlign.center,
                style: AppStyles.bodyText.copyWith(
                  color: graduationStatusTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => Navigator.pushNamed(context, '/graduation_progress'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Check graduation credits',
                  style: AppStyles.bodyText.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularGpaPainter extends CustomPainter {
  final double gpa;
  final Color gpaColor;
  final Color trackColor;
  final double strokeWidth;

  _CircularGpaPainter({
    required this.gpa,
    required this.gpaColor,
    required this.trackColor,
    this.strokeWidth = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width / 2, size.height / 2) - strokeWidth / 2;

    // Background track paint
    final Paint trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round; // Makes the ends of the track rounded

    // GPA progress arc paint
    final Paint gpaPaint = Paint()
      ..color = gpaColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round; // Makes the ends of the progress arc rounded

    const double startAngle = -math.pi / 2 - math.pi /4; // Start at roughly -135 degrees (top-left)
    const double totalAngle = math.pi * 1.5; // Sweep 270 degrees (3/4 of a circle)

    // Draw the background track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalAngle,
      false,
      trackPaint,
    );

    // Calculate sweep angle for GPA
    // Clamp GPA to 0-4 range for calculation, though visual should handle actual values
    final double clampedGpa = gpa.clamp(0.0, 4.0);
    final double gpaSweepAngle = (clampedGpa / 4.0) * totalAngle;

    // Draw the GPA progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      gpaSweepAngle,
      false,
      gpaPaint,
    );

    // Paint the GPA text in the center
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: gpa.toStringAsFixed(1),
        style: AppStyles.sectionHeading.copyWith( // Or a custom style for the gauge text
          color: AppColors.primary, // Use a prominent color
          fontSize: math.min(size.width, size.height) / 3.5, // Scale font size with gauge size
          fontWeight: FontWeight.bold,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _CircularGpaPainter oldDelegate) {
    return oldDelegate.gpa != gpa ||
        oldDelegate.gpaColor != gpaColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _ExamList extends StatelessWidget {
  const _ExamList();

  @override
  Widget build(BuildContext context) {
    return Consumer<AssignmentProvider>(
      builder: (context, assignmentProvider, _) {
        if (assignmentProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        // Trigger load on first build if not loaded
        if (assignmentProvider.assignments.isEmpty) {
          assignmentProvider.loadUpcomingAssignments();
          return const Center(child: CircularProgressIndicator());
        }
        final assignments = assignmentProvider.assignments;
        // Filter for primary schedule courses
        final primaryIndex = primaryScheduleIndex.value;
        final primaryCourses = (primaryIndex != null && primaryIndex >= 0 && primaryIndex < savedSchedules.value.length)
            ? savedSchedules.value[primaryIndex]
            : <dynamic>{};
        final primaryCourseIds = primaryCourses.map((c) => c.courseId).toSet();
        final filtered = (primaryIndex == null)
            ? []
            : assignments.where((a) => primaryCourseIds.contains(a.courseId)).toList();

        if (filtered.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: Text('No assignments found')),
          );
        }

        // Wrap assignments in a scrollable decorated container
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                physics: AlwaysScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final assignment = filtered[index];
                  final daysRemaining = assignment.dueDate.difference(DateTime.now()).inDays;
                  final Color colour = daysRemaining < 7 ? Colors.pinkAccent : Colors.lightBlue;
                  final String date = DateFormat('EEEE, d MMMM').format(assignment.dueDate);
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignment.description,
                          style: AppStyles.sectionHeading.copyWith(
                            color: colour,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date,
                          style: AppStyles.bodyTextSecondary.copyWith(
                            color: colour,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
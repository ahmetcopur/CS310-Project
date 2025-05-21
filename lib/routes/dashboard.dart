import 'package:flutter/material.dart';
import 'package:su_credit/utils/colors.dart';
import 'package:su_credit/utils/styles.dart';
import 'package:provider/provider.dart';
// import 'package:su_credit/providers/assignment_provider.dart'; // Not used in the provided snippet directly for GpaPainter
// import 'package:firebase_auth/firebase_auth.dart'; // Not used in the provided snippet directly for GpaPainter
// import 'package:cloud_firestore/cloud_firestore.dart'; // Not used in the provided snippet directly for GpaPainter
import 'package:su_credit/providers/gpa_provider.dart';

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
                      _SectionHeader(
                        title: 'Graduation Progress',
                        buttonLabel: 'See All',
                        onPressed: () => Navigator.pushNamed(context, '/graduation_progress'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: const [
                            Expanded(
                              child: _CreditChip(
                                label: 'Area Credits',
                                current: 3,
                                required: 9,
                                accentColor: AppColors.accentBlue,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _CreditChip(
                                label: 'Core Credits',
                                current: 12,
                                required: 31,
                                accentColor: AppColors.accentTeal,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _CreditChip(
                                label: 'Free Credits',
                                current: 5,
                                required: 9,
                                accentColor: AppColors.accentPink,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _CreditChip(
                                label: 'Total Credits',
                                current: 20,
                                required: 49,
                                accentColor: AppColors.accentOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _GpaStatusCard(currentGpa: gpaProvider.gpa),
                            const SizedBox(width: 16),
                            const Expanded(child: _WarningsCard()),
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
            style: AppStyles.sectionHeading.copyWith(
              color: AppColors.heading,
              fontSize: 22,
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
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditChip extends StatelessWidget {
  final String label;
  final int current;
  final int required;
  final Color accentColor;
  const _CreditChip({
    required this.label,
    required this.current,
    required this.required,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppStyles.bodyTextSecondary.copyWith(
                fontWeight: FontWeight.w600, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 8),
          Text(
            '$current/$required',
            style: AppStyles.sectionHeading.copyWith(
              color: accentColor,
              fontSize: 26,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            'GPA Status',
            style: AppStyles.sectionHeading.copyWith(
              color: AppColors.heading,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 90,
            height: 220,
            child: CustomPaint(painter: _GpaPainter(currentGpa)),
          ),
        ],
      ),
    );
  }
}

class _GpaPainter extends CustomPainter {
  final double gpa;
  _GpaPainter(this.gpa);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint barPaint = Paint();
    // Main vertical bar
    barPaint.color = AppColors.textTertiary; // Color of the background bar
    canvas.drawRect(Rect.fromLTWH(0, 0, 20, size.height), barPaint); // The bar itself (width 20, full height)

    final TextPainter tp = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.start,
    );

    // Define scale parameters
    const double scaleMax = 4.0;
    const double scaleMin = 0.0; // Changed from 1.0 to 0.0
    const double totalScaleSpan = scaleMax - scaleMin; // Now 4.0 (was 3.0)

    // Effective drawing height for the scale, assuming padding for labels
    // Assuming 10px padding at the top and 10px at the bottom of the scale itself
    final double drawableHeight = size.height - 20;
    const double topOffsetForScale = 10; // Top padding for the scale markings

    // Ticks to display - added 0.0
    final List<double> ticks = <double>[4.0, 3.0, 2.0, 1.0, 0.0];

    for (final double tickValue in ticks) {
      // Calculate y position for the tick mark
      // (scaleMax - tickValue) / totalScaleSpan gives a normalized value (0 for top, 1 for bottom of scale range)
      final double y = ((scaleMax - tickValue) / totalScaleSpan) * drawableHeight + topOffsetForScale;

      barPaint.color = AppColors.background; // To "cut out" the tick from the main bar
      barPaint.strokeWidth = 2.0;
      canvas.drawLine(Offset(0, y), Offset(35, y), barPaint); // Tick line extends from x=0 to x=35

      // Draw tick label
      tp.text = TextSpan(
        text: tickValue.toStringAsFixed(1), // e.g., "4.0", "3.0", "0.0"
        // Assuming AppStyles.bodyText has a color that contrasts with AppColors.background
        style: AppStyles.bodyText.copyWith(fontSize: 12),
      );
      tp.layout();
      // Center text vertically against the tick mark
      tp.paint(canvas, Offset(40, y - (tp.height / 2)));
    }

    // Clamp GPA to be within the new visual scale range (0.0 to 4.0)
    final double clampedGpa = gpa.clamp(scaleMin, scaleMax); // scaleMin is now 0.0

    // Calculate y position for the GPA indicator line based on clamped GPA and new scale span
    final double yValue = ((scaleMax - clampedGpa) / totalScaleSpan) * drawableHeight + topOffsetForScale;

    // Draw GPA indicator line
    barPaint.color = AppColors.accentPink; // Color for the GPA line
    barPaint.strokeWidth = 3.0;
    canvas.drawLine(Offset(0, yValue), Offset(60, yValue), barPaint); // GPA line extends from x=0 to x=60

    // Draw GPA value text (displaying the original GPA value, not necessarily clamped)
    tp.text = TextSpan(
      text: gpa.toStringAsFixed(1),
      style: AppStyles.sectionHeading.copyWith(
        fontSize: 18,
        color: AppColors.accentPink,
      ),
    );
    tp.layout();
    // Position GPA text next to its line, centered vertically
    tp.paint(canvas, Offset(62, yValue - (tp.height / 2)));
  }

  @override
  bool shouldRepaint(covariant _GpaPainter old) {
    return old.gpa != gpa;
  }
}


class _WarningsCard extends StatelessWidget {
  const _WarningsCard();

  @override
  Widget build(BuildContext context) {
    // warning tuples
    final List<(String, Color)> warnings = [
      ('No Deadline for\nCourse Registration', AppColors.coolGreen),
      ('GPA currently below\n2.0\nMay need Assistance\nfor Graduation',
      AppColors.coolPink),
      ('GPA currently below\n2.3\nMay need Assistance\nfor second area',
      AppColors.coolPink),
    ];

    final List<Widget> children = [];
    children.add(
      Text(
        'Warnings',
        style: AppStyles.sectionHeading.copyWith(
          color: AppColors.heading,
          fontSize: 22,
        ),
      ),
    );
    children.add(const SizedBox(height: 8));

    for (var i = 0; i < warnings.length; i++) {
      final text = warnings[i].$1;
      final c = warnings[i].$2;
      children.add(
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppStyles.bodyText.copyWith(
              color: c,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ),
      );
      if (i < warnings.length - 1) {
        children.add(Divider(color: AppColors.text, height: 1));
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _ExamList extends StatelessWidget {
  const _ExamList();

  @override
  Widget build(BuildContext context) {
    // If no Firestore data, use hardcoded data
    final displayAssignments = [
      {'title': 'CS 310 - Project Phase 2 Submission in 5 days!', 'color': Colors.lightBlue},
      {'title': 'CS 307 - Midterm Exam in 7 days!', 'color': Colors.lightBlue},
      {'title': 'CS 403 - Midterm Exam in 10 days!', 'color': Colors.lightBlue},
      {'title': 'CS 305 - Homework 2 Submission in 12 days!', 'color': Colors.pinkAccent},
      {'title': 'Math 306 - Midterm Exam in 15 days!', 'color': Colors.pinkAccent},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          children: displayAssignments.map((e) =>
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    Expanded(
                      child: Text(
                        e['title'] as String,
                        style: AppStyles.bodyText.copyWith(
                          color: e['color'] as Color?,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              )
          ).toList(),
        ),
      ),
    );
  }
}
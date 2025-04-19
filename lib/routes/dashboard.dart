import 'package:flutter/material.dart';
import 'package:su_credit/utils/colors.dart';
import 'package:su_credit/utils/styles.dart';

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    title: 'Graduation Progress',
                    buttonLabel: 'See All',
                    onPressed: () =>
                        Navigator.pushNamed(context, '/graduation_progress'),
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
                      children: const [
                        _GpaStatusCard(currentGpa: 1.95),
                        SizedBox(width: 16),
                        Expanded(child: _WarningsCard()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _SectionHeader(
                    title: 'Exam & Assignments',
                    buttonLabel: 'See More',
                    onPressed: () => Navigator.pushNamed(context, '/assignments'),
                  ),
                  const _ExamList(),
                ],
              ),
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
    barPaint.color = AppColors.textTertiary;
    canvas.drawRect(Rect.fromLTWH(0, 0, 20, size.height), barPaint);

    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    for (final double tick in <double>[4.0, 3.0, 2.0, 1.0]) {
      final double y = (4 - tick) / 3 * (size.height - 20) + 10;
      barPaint.color = AppColors.background;
      barPaint.strokeWidth = 2.0;
      canvas.drawLine(Offset(0, y), Offset(35, y), barPaint);
      tp.text = TextSpan(
        text: tick.toStringAsFixed(1),
        style: AppStyles.bodyText.copyWith(fontSize: 12),
      );
      tp.layout();
      tp.paint(canvas, Offset(40, y - 7));
    }
    final double x = gpa.clamp(1.0, 4.0);
    final double yValue = (4 - x) / 3 * (size.height - 20) + 10;
    barPaint.color = AppColors.accentPink;
    barPaint.strokeWidth = 3.0;
    canvas.drawLine(Offset(0, yValue), Offset(60, yValue), barPaint);
    tp.text = TextSpan(
      text: gpa.toStringAsFixed(1),
      style: AppStyles.sectionHeading.copyWith(
        fontSize: 18,
        color: AppColors.accentPink,
      ),
    );
    tp.layout();
    tp.paint(canvas, Offset(62, yValue - 10));
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
    const exams = [
      ('CS 310 - Project Phase 2 Submission in 5 days!', Colors.lightBlue),
      ('CS 307 - Midterm Exam in 7 days!', Colors.lightBlue),
      ('CS 403 - Midterm Exam in 10 days!', Colors.lightBlue),
      ('CS 305 - Homework 2 Submission in 12 days!', Colors.pinkAccent),
      ('Math 306 - Midterm Exam in 15 days!', Colors.pinkAccent),
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
          children: exams.map((e) =>
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    Expanded(
                      child: Text(
                        e.$1,
                        style: AppStyles.bodyText.copyWith(
                          color: e.$2,
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
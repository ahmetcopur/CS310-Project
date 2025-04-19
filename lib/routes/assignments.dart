import 'package:flutter/material.dart';
import 'package:su_credit/utils/colors.dart';
import 'package:su_credit/utils/styles.dart';

class AssignmentsPage extends StatelessWidget {
  const AssignmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      ('CS310: PROJECT PHASE 1 IS DUE', 'Monday, 24 March', Colors.lightBlue),
      ('MIDTERM: CS307 – OS MIDTERM', 'Friday, 28 March', Colors.lightBlue),
      ('CS403: MIDTERM EXAM', 'Saturday, 29 March', Colors.lightBlue),
      ('CS305: HOMEWORK 2 IS DUE', 'Friday, 4 April', Colors.pinkAccent),
      ('MATH306: MIDTERM EXAM', 'Monday, 7 April', Colors.pinkAccent),
      ('OPIM302: PRESENTATION IS DUE', 'Wednesday, 9 April', Colors.pinkAccent),
      ('PSY201: ASSIGNMENT IS DUE', 'Friday, 11 April', Colors.pinkAccent),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(12, 60, 20, 16),
            width: double.infinity,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: AppColors.background),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 6),
                Text(
                  'Exam & Assignments',
                  style: AppStyles.screenTitle.copyWith(
                    color: AppColors.background,
                    fontSize: 26,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, i) {
                final (title, date, colour) = items[i];
                return Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
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
        ],
      ),
    );
  }
}
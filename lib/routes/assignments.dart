import 'package:flutter/material.dart';
import 'package:su_credit/utils/colors.dart';
import 'package:su_credit/utils/styles.dart';
import 'package:provider/provider.dart';
import 'package:su_credit/providers/assignment_provider.dart';
import 'package:intl/intl.dart'; // For date formatting

class AssignmentsPage extends StatefulWidget {
  const AssignmentsPage({super.key});

  @override
  State<AssignmentsPage> createState() => _AssignmentsPageState();
}

class _AssignmentsPageState extends State<AssignmentsPage> {
  @override
  void initState() {
    super.initState();
    // Load assignments when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AssignmentProvider>(context, listen: false).loadUpcomingAssignments();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get the assignment provider for Firebase data
    final assignmentProvider = Provider.of<AssignmentProvider>(context);

    // Use assignments from provider
    final assignments = assignmentProvider.assignments;

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
            child: assignmentProvider.isLoading
                ? Center(child: CircularProgressIndicator())
                : assignments.isEmpty
                    // Show placeholder if no real data
                    ? Center(child: Text('No assignments found'))
                    // Show real data list
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        itemCount: assignments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, i) {
                          final assignment = assignments[i];

                          // Determine color based on days remaining
                          final daysRemaining = assignment.dueDate.difference(DateTime.now()).inDays;
                          final Color colour = daysRemaining < 7 ? Colors.pinkAccent : Colors.lightBlue;

                          // Format the date to match original format
                          String date = DateFormat('EEEE, d MMMM').format(assignment.dueDate);

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
                                  assignment.title,
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
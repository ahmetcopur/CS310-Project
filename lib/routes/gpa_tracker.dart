import 'package:flutter/material.dart';
import 'package:su_credit/utils/colors.dart';
import 'package:su_credit/utils/styles.dart';

class GpaTrackerPage extends StatefulWidget {
  const GpaTrackerPage({super.key});

  @override
  State<GpaTrackerPage> createState() => _GpaTrackerPageState();
}

class _GpaTrackerPageState extends State<GpaTrackerPage> {
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

  //Placeholder values
  final List<_Course> _courses = [
    _Course(code: 'PSY‑340', grade: 'B'),
    _Course(code: 'CS‑310', grade: 'A-'),
    _Course(code: 'CS‑408', grade: 'B+'),
    _Course(code: 'CS‑307', grade: 'C'),
    _Course(code: 'ORG‑301', grade: 'D+'),
    _Course(code: 'SPS‑303', grade: 'C-'),
  ];

  double get _gpa {
    if (_courses.isEmpty) return 0;
    final total = _courses
        .map((c) => gradePoints[c.grade]!)
        .reduce((a, b) => a + b);
    return total / _courses.length;
  }

  Future<void> _showAddDialog() async {
    String code = '';
    String grade = 'A';
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
              onChanged: (v) => grade = v!,
              decoration: const InputDecoration(labelText: 'Grade'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (code.isNotEmpty) {
                setState(() => _courses.add(_Course(code: code, grade: grade)));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body: Column(
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
                    Text(
                      _gpa.toStringAsFixed(2),
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
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Current Program',
                style: AppStyles.sectionHeading.copyWith(
                  color: AppColors.heading,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              itemCount: _courses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final c = _courses[i];
                return Dismissible(
                  key: ValueKey(c),
                  background: Container(
                    color: AppColors.accentRed,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: const Icon(Icons.delete, color: AppColors.surface),
                  ),
                  onDismissed: (_) =>
                      setState(() => _courses.removeAt(i)),
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.code.toUpperCase(),
                            style: AppStyles.bodyText.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.heading,
                            ),
                          ),
                        ),
                        Container(
                          width: 60,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            c.grade,
                            style: AppStyles.bodyText.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              setState(() => _courses.removeAt(i)),
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                      ],
                    ),
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

class _Course {
  final String code;
  final String grade;
  const _Course({required this.code, required this.grade});
}

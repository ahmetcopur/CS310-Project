import 'package:flutter/material.dart';
import 'package:su_credit/utils/colors.dart';
import 'package:su_credit/utils/styles.dart';
import 'package:su_credit/utils/dimensions.dart';

class _CourseData {
  final String info;
  final String requirements;
  final String description;
  const _CourseData({
    required this.info,
    required this.requirements,
    required this.description,
  });
}

const Map<String, _CourseData> _courseData = {
  'CS301': _CourseData(
    info: '''
CS301 – Algorithms
Credits: 3.000
Campus: Sabanci University
Lecture Type: In‑person''',
    requirements: '''
Undergraduate only
Corequisite: CS301R
Prerequisites: MATH204 (Min.Grade:D)
& CS300        (Min.Grade:D)''',
    description: '''
This course is about the analysis and design of computer algorithms. We will study various methods to analyze the correctness and asymptotic performance of algorithms, important algorithms (e.g., search, sort, path finding, spanning tree, network flow) and data structures (e.g., dynamic sets, augmented data structures), algorithmic design paradigms (e.g., randomized, divide‑and‑conquer, dynamic programming, greedy, incremental), and hardness of problems (e.g., NP‑completeness, reductions, approximation algorithms).''',
  ),
  'CS302': _CourseData(
    info: '''
CS302 - Formal Languages and Automata
Credits: 3.000
Campus: Sabanci University
Lecture Type: Interactive,Learner centered,Communicative''',
    requirements: '''
Undergraduate only
Corequisite: CS302R
Prerequisites: --''',
    description: '''
This course introduces the mathematical foundations of computer languages and computation. You’ll study the Chomsky hierarchy of grammars, regular languages and expressions, and both deterministic and nondeterministic finite automata (including determinization and minimization). You’ll learn the pumping lemmas and closure properties for regular and context‑free languages, explore context‑free grammars and push‑down automata, and get an introductory look at Turing machines. Throughout, you’ll examine the algorithms and complexity bounds for key decision problems in language theory.''',
  ),
};

class CourseDetailPage extends StatefulWidget {
  final String courseName;
  const CourseDetailPage({super.key, required this.courseName});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  int _selectedRating = 0;
  final _ctrl = TextEditingController();
  final List<_Comment> _comments = [];

  void _addComment() {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _selectedRating == 0) return;
    setState(() {
      _comments.insert(
        0,
        _Comment(text: text, rating: _selectedRating, date: DateTime.now()),
      );
      _ctrl.clear();
      _selectedRating = 0;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String key = widget.courseName.split(' ').first;

    final _CourseData data = _courseData[key] ??
        const _CourseData(
          info: 'TBD',
          requirements: 'TBD',
          description: 'TBD',
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.surface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.courseName,
            style: AppStyles.screenTitle.copyWith(color: AppColors.surface)),
      ),
      body: SingleChildScrollView(
        padding: AppDimensions.regularParentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info & Requirements
            Row(
              children: [
                Expanded(child: _whiteBox(data.info, 'Course Info')),
                const SizedBox(width: 12),
                Expanded(child: _whiteBox(data.requirements, 'Requirements')),
              ],
            ),
            const SizedBox(height: 24),
            Text('Description',
                style:
                AppStyles.sectionHeading.copyWith(color: AppColors.primary)),
            const SizedBox(height: 8),
            _whiteBox(data.description),
            const SizedBox(height: 24),
            Text('Comments',
                style:
                AppStyles.sectionHeading.copyWith(color: AppColors.primary)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                BorderRadius.circular(AppDimensions.borderRadiusSmall),
              ),
              padding: EdgeInsets.all(AppDimensions.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List<Widget>.generate(5, (i) {
                      final star = i + 1;
                      return IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          _selectedRating >= star
                              ? Icons.star
                              : Icons.star_border,
                          color: AppColors.accentOrange,
                        ),
                        onPressed: () =>
                            setState(() => _selectedRating = star),
                      );
                    }),
                  ),
                  TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(
                      hintText: 'Add comment and rate difficulty',
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    onSubmitted: (_) => _addComment(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary),
                      onPressed: _addComment,
                      child: const Text('Post'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            for (final c in _comments) _commentTile(c),
          ],
        ),
      ),
    );
  }

  Widget _whiteBox(String text, [String? header]) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (header != null)
        Text(header,
            style:
            AppStyles.sectionHeading.copyWith(color: AppColors.primary)),
      if (header != null) const SizedBox(height: 6),
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius:
          BorderRadius.circular(AppDimensions.borderRadiusMedium),
        ),
        padding: EdgeInsets.all(AppDimensions.paddingMedium),
        child: Text(text, style: AppStyles.bodyText),
      ),
    ],
  );

  Widget _commentTile(_Comment c) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius:
      BorderRadius.circular(AppDimensions.borderRadiusSmall),
    ),
    margin: EdgeInsets.only(bottom: AppDimensions.paddingMedium),
    padding: EdgeInsets.all(AppDimensions.paddingMedium),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (int i = 0; i < c.rating; i++)
              Icon(Icons.star,
                  size: AppDimensions.iconSizeSmall,
                  color: AppColors.accentOrange),
            const Spacer(),
            Text(
              '${c.date.day}.${c.date.month}.${c.date.year}',
              style: AppStyles.bodyTextSecondary,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(c.text, style: AppStyles.bodyText),
      ],
    ),
  );
}

class _Comment {
  final String text;
  final int rating;
  final DateTime date;
  _Comment({required this.text, required this.rating, required this.date});
}

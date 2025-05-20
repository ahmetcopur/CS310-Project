import 'package:flutter/material.dart';
import 'package:su_credit/utils/colors.dart';
import 'package:su_credit/utils/styles.dart';
import 'package:su_credit/utils/dimensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // for Timestamp
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/comment_provider.dart';
import '../models/comment.dart';

class CourseDetailPage extends StatefulWidget {
  final String courseName;
  const CourseDetailPage({super.key, required this.courseName});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  int _selectedRating = 0;
  final _ctrl = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  late final String _courseId;
  // no flags needed

  @override
  void initState() {
    super.initState();
    _courseId = widget.courseName.split(' ').first;
    // Load comments after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommentProvider>().loadCommentsForCourse(_courseId);
    });
  }

  // Add a comment via provider
  void _addComment() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _selectedRating == 0 || _currentUserId == null) return;

    try {
      // Create Comment model and add via provider
      final comment = Comment(
        id: '',
        courseId: _courseId,
        text: text,
        rating: _selectedRating,
        date: DateTime.now(),
        userId: _currentUserId,
      );
      await context.read<CommentProvider>().addComment(comment);

      // Clear input fields
      setState(() {
        _ctrl.clear();
        _selectedRating = 0;
      });
    } catch (e) {
      // Show error using snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding comment: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            // Course Info from Firestore using real-time listener
            StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('courses')
                    .where('code', isEqualTo: _courseId)
                    .limit(1)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading course: ${snapshot.error}',
                        style: AppStyles.bodyText,
                      ),
                    );
                  }
                  final docs = snapshot.data?.docs;
                  if (docs == null || docs.isEmpty) {
                    return Center(
                      child: Text(
                        'Course not found',
                        style: AppStyles.bodyText,
                      ),
                    );
                  }
                  // Use the first matching document
                  final doc = docs.first;
                  final data = doc.data() as Map<String, dynamic>;

                  // Format course info
                  final String code = data['code'] ?? 'Unknown';
                  final String name = data['name'] ?? 'Unknown Course';
                  final int credits = data['credits'] ?? 0;
                  final String instructor = data['instructor'] ?? 'Not specified';
                  final String semester = data['semester'] ?? 'Not specified';
                  final String description = data['description'] ?? 'No description available';

                  // Format information for display
                  final String info = '''
$code – $name
Credits: $credits.000
Campus: Sabanci University
Lecture Type: In‑person''';

                  final String requirements = '''
Undergraduate only
Instructor: $instructor
Prerequisites: $semester''';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _whiteBox(info, 'Course Info')),
                          const SizedBox(width: 12),
                          Expanded(child: _whiteBox(requirements, 'Requirements')),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('Description',
                          style: AppStyles.sectionHeading.copyWith(color: AppColors.primary)),
                      const SizedBox(height: 8),
                      _whiteBox(description),
                    ],
                  );
                }
            ),

            const SizedBox(height: 24),
            Text('Comments',
                style: AppStyles.sectionHeading.copyWith(color: AppColors.primary)),
            const SizedBox(height: 8),

            // Comment input area
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
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
                          _selectedRating >= star ? Icons.star : Icons.star_border,
                          color: AppColors.accentOrange,
                        ),
                        onPressed: () => setState(() => _selectedRating = star),
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

            // Comments via CommentProvider
            Consumer<CommentProvider>(
              builder: (_, commentProv, __) {
                if (commentProv.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }
                if (commentProv.error != null) {
                  return Center(
                    child: Text(
                      'Error loading comments: ${commentProv.error}',
                      style: AppStyles.bodyTextSecondary,
                    ),
                  );
                }
                final comments = commentProv.comments;
                if (comments.isEmpty) {
                  return Center(
                    child: Text('No comments yet', style: AppStyles.bodyTextSecondary),
                  );
                }
                return Column(
                  children: comments.map((c) => _commentTile(c)).toList(),
                );
              },
            ),
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
            style: AppStyles.sectionHeading.copyWith(color: AppColors.primary)),
      if (header != null) const SizedBox(height: 6),
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        ),
        padding: EdgeInsets.all(AppDimensions.paddingMedium),
        child: Text(text, style: AppStyles.bodyText),
      ),
    ],
  );

  Widget _commentTile(Comment c) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
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
import 'package:flutter/material.dart';
import 'package:su_credit/utils/colors.dart';
import 'package:su_credit/utils/styles.dart';
import 'package:su_credit/utils/dimensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  @override
  void initState() {
    super.initState();
    _courseId = widget.courseName.split(' ').first;
  }

  // Add a comment to Firestore
  void _addComment() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _selectedRating == 0 || _currentUserId == null) return;

    try {
      final commentData = {
        'courseId': _courseId,
        'text': text,
        'rating': _selectedRating,
        'date': FieldValue.serverTimestamp(),
        'userId': _currentUserId,
      };

      // Add to Firestore - will automatically update UI via Stream
      await _firestore.collection('courseComments').add(commentData);

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
            StreamBuilder<DocumentSnapshot>(
                stream: _firestore.collection('courses').doc(_courseId).snapshots(),
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

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Center(
                      child: Text(
                        'Course not found',
                        style: AppStyles.bodyText,
                      ),
                    );
                  }

                  // Extract course data
                  final data = snapshot.data!.data() as Map<String, dynamic>;

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

            // Comments from Firestore using real-time listener
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('courseComments')
                  .where('courseId', isEqualTo: _courseId)
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading comments: ${snapshot.error}',
                      style: AppStyles.bodyTextSecondary,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text('No comments yet', style: AppStyles.bodyTextSecondary),
                  );
                }

                // Convert snapshot to comments
                final comments = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _Comment(
                    id: doc.id,
                    text: data['text'] ?? '',
                    rating: data['rating'] ?? 0,
                    date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  );
                }).toList();

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

  Widget _commentTile(_Comment c) => Container(
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

class _Comment {
  final String? id;
  final String text;
  final int rating;
  final DateTime date;
  _Comment({this.id, required this.text, required this.rating, required this.date});
}
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
        id: '', // ID will be set by the provider/backend
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
      // Hide keyboard
      FocusScope.of(context).unfocus();
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
                    return const Center(child: CircularProgressIndicator());
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
                  final String description = data['description'] ?? 'No description available.'; // Added a period for empty description.

                  // Format information for display
                  final String info = '''
$code – $name
Credits: $credits.000
Campus: Sabanci University
Lecture Type: In‑person''';

                  // Build requirements info from Firestore
                  final List<dynamic> reqList = data['requirements'] ?? [];
                  final String prerequisites = reqList.isNotEmpty
                      ? reqList.map((e) => e.toString()).join(', ')
                      : 'None';
                  final String requirements = '''
Instructor: $instructor
Prerequisites: $prerequisites''';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start, // Align boxes to top
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
                      _whiteBox(description.isEmpty ? 'No description available.' : description),
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
                boxShadow: [ // Optional: add a subtle shadow for depth
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: EdgeInsets.all(AppDimensions.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rate Difficulty:', style: AppStyles.bodyText.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppDimensions.paddingSmall / 2),
                  Row(
                    children: List<Widget>.generate(5, (i) {
                      final star = i + 1;
                      return IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(), // Remove extra padding
                        icon: Icon(
                          _selectedRating >= star ? Icons.star : Icons.star_border,
                          color: AppColors.accentOrange,
                          size: AppDimensions.iconSizeLarge, // Slightly larger stars
                        ),
                        onPressed: () => setState(() => _selectedRating = star),
                      );
                    }),
                  ),
                  const Divider( // MODIFIED: Added Divider
                    height: AppDimensions.paddingLarge, // More space for the divider
                    thickness: 0.5,
                    color: AppColors.textTertiary,
                  ),
                  TextField(
                    controller: _ctrl,
                    decoration: InputDecoration( // MODIFIED: Using InputDecoration for better styling
                      hintText: 'Share your experience with this course...',
                      border: OutlineInputBorder( // Added a subtle border
                        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
                        borderSide: BorderSide(color: AppColors.textTertiary.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
                        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingMedium,
                        vertical: AppDimensions.paddingSmall,
                      ),
                    ),
                    maxLines: 3, // Set a max lines
                    minLines: 1, // Set a min lines
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addComment(),
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.surface, // MODIFIED: Text color to white/surface
                        padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge, vertical: AppDimensions.paddingSmall),
                        textStyle: AppStyles.buttonText,
                      ),
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
                  return const Center(child: CircularProgressIndicator());
                }
                if (commentProv.error != null) {
                  return Center(
                    child: Text(
                      'Error loading comments: ${commentProv.error}',
                      style: AppStyles.bodyTextSecondary.copyWith(color: AppColors.accentRed),
                    ),
                  );
                }
                final comments = commentProv.comments;
                if (comments.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingLarge),
                      child: Text('Be the first to comment!', style: AppStyles.bodyTextSecondary.copyWith(fontSize: 16)),
                    ),
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
        Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.paddingSmall / 2),
          child: Text(header,
              style: AppStyles.sectionHeading.copyWith(color: AppColors.primary, fontSize: 18)), // Slightly smaller header
        ),
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
          boxShadow: [ // Optional: add a subtle shadow for depth
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: EdgeInsets.all(AppDimensions.paddingMedium),
        child: Text(text, style: AppStyles.bodyText.copyWith(height: 1.4)), // Improved line height
      ),
    ],
  );

  Widget _commentTile(Comment c) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
      boxShadow: [ // Optional: add a subtle shadow for depth
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    margin: EdgeInsets.only(bottom: AppDimensions.paddingMedium),
    padding: EdgeInsets.all(AppDimensions.paddingMedium),
    child: Row( // MODIFIED: Wrap with Row for icon
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding( // MODIFIED: Icon padding
          padding: EdgeInsets.only(top: AppDimensions.paddingSmall / 3, right: AppDimensions.paddingSmall),
          child: Icon(
            Icons.account_circle,
            color: AppColors.primary.withOpacity(0.8), // Slightly more opaque icon
            size: AppDimensions.iconSizeLarge, // Consistent icon size
          ),
        ),
        Expanded( // MODIFIED: Existing content goes here
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // User placeholder (could be replaced with actual user name later)
                  Text(
                    'User', // Placeholder
                    style: AppStyles.bodyText.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  Text(
                    '${c.date.day.toString().padLeft(2, '0')}.${c.date.month.toString().padLeft(2, '0')}.${c.date.year}', // Formatted date
                    style: AppStyles.bodyTextSecondary.copyWith(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingSmall / 2),
              Row( // Stars row
                children: [
                  for (int i = 0; i < c.rating; i++)
                    Icon(Icons.star,
                        size: AppDimensions.iconSizeSmall, // Smaller stars for comments
                        color: AppColors.accentOrange),
                  for (int i = c.rating; i < 5; i++) // Show empty stars
                    Icon(Icons.star_border,
                        size: AppDimensions.iconSizeSmall,
                        color: AppColors.accentOrange.withOpacity(0.5)),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingSmall),
              Text(c.text, style: AppStyles.bodyText.copyWith(height: 1.4, color: AppColors.textSecondary)), // Improved line height and text color
            ],
          ),
        ),
      ],
    ),
  );
}
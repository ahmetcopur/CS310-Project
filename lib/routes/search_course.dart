import 'package:flutter/material.dart';
import 'package:su_credit/utils/colors.dart';
import 'package:su_credit/utils/styles.dart';
import 'package:su_credit/utils/dimensions.dart';
import 'package:su_credit/routes/course_info.dart';
import 'package:su_credit/utils/favoriteCourses.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchCoursesPage extends StatefulWidget {
  const SearchCoursesPage({super.key});

  @override
  State<SearchCoursesPage> createState() => _SearchCoursesPageState();
}

class _SearchCoursesPageState extends State<SearchCoursesPage> {
  String searchQuery = '';
  bool _isLoading = true;
  String? _userId;

  // Add sorting state variable
  bool _isAscending = true;

  // Keep original list as fallback
  final List<String> _staticCourses = [
    'CS301 - Algorithms',
    'CS302 - Formal Languages and Automata',
    'CS305 - Programming Languages',
    'CS308 - Software Engineering',
    'CS403 - Distributed Systems',
    'CS407 - Theory of Computation',
  ];

  // List to be populated from Firestore
  List<String> courses = [];

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _loadCourses();
    _loadFavorites();
  }

  // Fetch courses from Firestore
  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final courseSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .orderBy('code')
          .get();

      if (courseSnapshot.docs.isNotEmpty) {
        final loadedCourses = courseSnapshot.docs.map((doc) {
          final data = doc.data();
          return '${data['code'] ?? 'Unknown'} - ${data['name'] ?? 'Course'}';
        }).toList();

        setState(() {
          courses = loadedCourses;
          _isLoading = false;
        });
      } else {
        // Use static data if no courses found
        setState(() {
          courses = _staticCourses;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fallback to static data on error
      debugPrint('Error loading courses: $e');
      setState(() {
        courses = _staticCourses;
        _isLoading = false;
      });
    }
  }

  // Load favorite courses from Firestore
  Future<void> _loadFavorites() async {
    if (_userId == null) return;

    try {
      final favoriteDoc = await FirebaseFirestore.instance
          .collection('userPreferences')
          .doc(_userId)
          .get();

      if (favoriteDoc.exists && favoriteDoc.data()?['favoriteCourses'] is List) {
        final List<String> storedFavorites = List<String>.from(
            favoriteDoc.data()?['favoriteCourses'] ?? []);

        // Update the ValueNotifier without losing local changes
        final currentFavorites = favoriteCourses.value;
        final newFavorites = [...currentFavorites, ...storedFavorites]
            .toSet()
            .toList(); // Remove duplicates

        favoriteCourses.value = newFavorites;
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      // Keep existing favorites on error
    }
  }

  // Toggle course favorite status with Firestore support
  void _toggleFavorite(String course) {
    // Update local state first (for immediate feedback)
    final list = favoriteCourses.value;
    List<String> newList;

    if (list.contains(course)) {
      newList = List.from(list)..remove(course);
    } else {
      newList = List.from(list)..add(course);
    }

    favoriteCourses.value = newList;

    // Then update Firestore if user is logged in
    if (_userId != null) {
      try {
        FirebaseFirestore.instance
            .collection('userPreferences')
            .doc(_userId)
            .set({
          'favoriteCourses': newList,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error saving favorites: $e');
        // Local change was already made, so user still sees their action
      }
    }
  }

  // Method to toggle sort order and sort the course list
  void _toggleSort() {
    setState(() {
      _isAscending = !_isAscending;
      courses.sort((a, b) {
        final codeA = a.split(' - ')[0];
        final codeB = b.split(' - ')[0];
        return _isAscending ? codeA.compareTo(codeB) : codeB.compareTo(codeA);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.primary,
            padding: EdgeInsets.symmetric(
              vertical: AppDimensions.paddingLarge,
              horizontal: AppDimensions.paddingMedium,
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.surface),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Search Courses',
                    style: AppStyles.screenTitle.copyWith(color: AppColors.surface),
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: AppColors.textPrimary,
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMedium,
              vertical: AppDimensions.paddingSmall,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: AppDimensions.textFieldHeight -
                        AppDimensions.paddingSmall * 2,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingSmall,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.borderRadiusSmall,
                      ),
                    ),
                    child: TextField(
                      onChanged: (v) => setState(() => searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search for...',
                        hintStyle: AppStyles.bodyTextSecondary,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _toggleSort,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Sort',
                        style: AppStyles.buttonText.copyWith(color: AppColors.surface),
                      ),
                      Icon(
                        _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        color: AppColors.surface,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ValueListenableBuilder<List<String>>(
              valueListenable: favoriteCourses,
              builder: (context, favs, _) {
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: courses.length,
                  separatorBuilder: (_, __) => const Divider(
                    color: AppColors.textPrimary,
                    height: 2,
                  ),
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    if (searchQuery.isNotEmpty &&
                        !course.toLowerCase().contains(searchQuery.toLowerCase())) {
                      return const SizedBox.shrink();
                    }
                    final isFav = favs.contains(course);
                    final codeVar = course.split(' - ')[0];
                    return InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CourseDetailPage(courseName: course),
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(
                            color: AppColors.textPrimary,
                            width: 2,
                          ),
                        ),
                        child: ListTile(
                          title: Text(course, style: AppStyles.bodyText),
                          // Subtitle showing prerequisites
                          subtitle: FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('courses')
                                .where('code', isEqualTo: codeVar)
                                .limit(1)
                                .get(),
                            builder: (context, snapshotReq) {
                              if (snapshotReq.connectionState == ConnectionState.waiting) {
                                return const SizedBox();
                              }
                              if (snapshotReq.hasError) {
                                return const Text('Prerequisites: Error');
                              }
                              final docs = snapshotReq.data?.docs;
                              if (docs == null || docs.isEmpty) {
                                return const Text('Prerequisites: None');
                              }
                              final dataReq = docs.first.data() as Map<String, dynamic>;
                              final List<dynamic> reqs = dataReq['requirements'] ?? [];
                              final String prereqText = reqs.isNotEmpty
                                  ? reqs.map((e) => e.toString()).join(', ')
                                  : 'None';
                              return Text('Prerequisites: $prereqText');
                            },
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.info_outline, color: AppColors.primary),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          CourseDetailPage(courseName: course),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  isFav ? Icons.bookmark : Icons.bookmark_border,
                                  color: AppColors.primary,
                                ),
                                onPressed: () => _toggleFavorite(course),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
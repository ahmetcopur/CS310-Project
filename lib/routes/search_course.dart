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
  bool _isAscending = true;

  final List<String> _staticCourses = [
    'CS301 - Algorithms',
    'CS302 - Formal Languages and Automata',
    // ... other static courses
  ];

  List<String> courses = [];

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _loadCourses();
    _loadFavorites();
  }

  Future<void> _loadCourses() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final courseSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .orderBy('code')
          .get();

      if (!mounted) return;

      if (courseSnapshot.docs.isNotEmpty) {
        final loadedCourses = courseSnapshot.docs.map((doc) {
          final data = doc.data();
          final code = data['code'] as String? ?? 'N/A';
          final name = data['name'] as String? ?? 'Unknown Course';
          return '$code - $name';
        }).toList();
        setState(() {
          courses = loadedCourses;
          _isLoading = false;
        });
      } else {
        setState(() {
          courses = List.from(_staticCourses);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading courses: $e');
      if (!mounted) return;
      setState(() {
        courses = List.from(_staticCourses);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFavorites() async {
    if (_userId == null) return;
    try {
      final favoriteDoc = await FirebaseFirestore.instance
          .collection('userPreferences')
          .doc(_userId)
          .get();
      if (!mounted) return;
      if (favoriteDoc.exists && favoriteDoc.data()?['favoriteCourses'] is List) {
        final storedFavorites = List<String>.from(favoriteDoc.data()?['favoriteCourses'] ?? []);
        final currentFavorites = favoriteCourses.value;
        final combinedFavoritesSet = {...currentFavorites, ...storedFavorites};
        favoriteCourses.value = combinedFavoritesSet.toList();
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  void _toggleFavorite(String courseDisplayString) {
    final currentFavs = favoriteCourses.value;
    List<String> newFavList;
    if (currentFavs.contains(courseDisplayString)) {
      newFavList = List.from(currentFavs)..remove(courseDisplayString);
    } else {
      newFavList = List.from(currentFavs)..add(courseDisplayString);
    }
    favoriteCourses.value = newFavList;

    if (_userId != null) {
      FirebaseFirestore.instance
          .collection('userPreferences')
          .doc(_userId)
          .set({'favoriteCourses': newFavList, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true))
          .catchError((e) => debugPrint('Error saving favorites: $e'));
    }
  }

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

  void _navigateToCourseDetail(String courseName) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CourseDetailPage(courseName: courseName)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        children: [
          // Custom App Bar
          Container(
            color: AppColors.primary,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              bottom: AppDimensions.paddingSmall,
              left: AppDimensions.paddingSmall / 2,
              right: AppDimensions.paddingMedium,
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    'Search Courses',
                    style: AppStyles.screenTitle.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
          ),

          // Search and Sort Bar
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMedium,
                vertical: AppDimensions.paddingSmall),
            child: Material(
              elevation: AppDimensions.elevationLow,
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
              color: AppColors.surface,
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingSmall,
                    vertical: AppDimensions.paddingSmall / 2.5),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) => setState(() => searchQuery = value.trim()),
                        style: AppStyles.bodyText.copyWith(color: AppColors.textPrimary, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Search by code or name...',
                          hintStyle: AppStyles.bodyTextSecondary.copyWith(color: AppColors.textTertiary, fontSize: 15),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none, // Keep it clean, focus indicated by cursor
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: AppColors.primary.withAlpha((255 * 0.7).round()), // Slightly more subtle
                            size: 22,
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: AppDimensions.paddingSmall * 0.9),
                        ),
                      ),
                    ),
                    SizedBox(width: AppDimensions.paddingSmall / 2),
                    TextButton.icon(
                      onPressed: _toggleSort,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppDimensions.paddingSmall,
                            vertical: AppDimensions.paddingSmall / 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
                        ),
                      ),
                      icon: Icon(
                        _isAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      label: Text(
                        'Sort',
                        style: AppStyles.buttonText.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Course List
          Expanded(
            child: _isLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  AppDimensions.verticalSpace(AppDimensions.paddingMedium),
                  Text('Loading courses...', style: AppStyles.bodyTextSecondary),
                ],
              ),
            )
                : ValueListenableBuilder<List<String>>(
              valueListenable: favoriteCourses,
              builder: (context, favs, _) {
                final filteredCourses = courses.where((course) {
                  if (searchQuery.isEmpty) return true;
                  return course.toLowerCase().contains(searchQuery.toLowerCase());
                }).toList();

                if (filteredCourses.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: AppDimensions.regularParentPadding,
                      child: Text(
                        searchQuery.isNotEmpty
                            ? 'No courses found matching "$searchQuery".'
                            : 'No courses available at the moment.',
                        style: AppStyles.bodyTextSecondary.copyWith(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.only(
                    left: AppDimensions.paddingMedium,
                    right: AppDimensions.paddingMedium,
                    bottom: AppDimensions.paddingLarge, // Space for FAB or bottom nav
                  ),
                  itemCount: filteredCourses.length,
                  itemBuilder: (context, index) {
                    final courseDisplayString = filteredCourses[index];
                    final isFav = favs.contains(courseDisplayString);
                    final courseCode = courseDisplayString.split(' - ')[0];

                    return Card(
                      elevation: AppDimensions.elevationLow,
                      margin: EdgeInsets.symmetric(vertical: AppDimensions.marginSmall * 0.75),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium)),
                      clipBehavior: Clip.antiAlias, // Ensures InkWell splash respects border radius
                      child: InkWell(
                        onTap: () => _navigateToCourseDetail(courseDisplayString),
                        child: Padding(
                          padding: EdgeInsets.only( // Adjusted padding
                            left: AppDimensions.paddingMedium,
                            top: AppDimensions.paddingSmall * 1.2,
                            bottom: AppDimensions.paddingSmall * 1.2,
                            right: AppDimensions.paddingSmall * 0.5, // Less padding on right for icons
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      courseDisplayString,
                                      style: AppStyles.bodyText.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15.5,
                                          color: AppColors.textPrimary),
                                      maxLines: 2, // Prevent overflow with long names
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    AppDimensions.verticalSpace(AppDimensions.paddingSmall / 2),
                                    FutureBuilder<QuerySnapshot>(
                                      future: FirebaseFirestore.instance
                                          .collection('courses')
                                          .where('code', isEqualTo: courseCode)
                                          .limit(1)
                                          .get(),
                                      builder: (context, snapshotReq) {
                                        if (snapshotReq.connectionState == ConnectionState.waiting) {
                                          return Text('Checking prerequisites...',
                                              style: AppStyles.bodyTextSecondary.copyWith(
                                                  fontSize: 12, // Smaller
                                                  fontStyle: FontStyle.italic,
                                                  color: AppColors.textTertiary.withAlpha((255 * 0.8).round())));
                                        }
                                        if (snapshotReq.hasError) {
                                          return Text('Prerequisites: Error',
                                              style: AppStyles.bodyTextSecondary.copyWith(fontSize: 12.5, color: AppColors.accentRed));
                                        }
                                        final docs = snapshotReq.data?.docs;
                                        if (docs == null || docs.isEmpty) {
                                          return Text('Prerequisites: Not specified',
                                              style: AppStyles.bodyTextSecondary.copyWith(fontSize: 12.5, color: AppColors.textTertiary));
                                        }
                                        final dataReq = docs.first.data() as Map<String, dynamic>;
                                        final List<dynamic> reqs = dataReq['requirements'] ?? [];
                                        final String prereqText = reqs.isNotEmpty
                                            ? reqs.map((e) => e.toString()).join(', ')
                                            : 'None';
                                        return Text(
                                          'Prerequisites: $prereqText',
                                          style: AppStyles.bodyTextSecondary.copyWith(fontSize: 13, color: AppColors.textTertiary),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              // Row for icons
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.info_outline_rounded),
                                    color: AppColors.secondary.withAlpha((255 * 0.9).round()),
                                    iconSize: 23,
                                    tooltip: 'View Details',
                                    padding: const EdgeInsets.all(AppDimensions.paddingSmall * 0.75),
                                    constraints: const BoxConstraints(), // To use smaller padding
                                    onPressed: () => _navigateToCourseDetail(courseDisplayString),
                                  ),
                                  Tooltip(
                                    message: isFav ? 'Remove from favorites' : 'Add to favorites',
                                    child: InkWell(
                                      onTap: () => _toggleFavorite(courseDisplayString),
                                      borderRadius: BorderRadius.circular(100.0),
                                      child: Padding(
                                        padding: const EdgeInsets.all(AppDimensions.paddingSmall * 0.75),
                                        child: Icon(
                                          isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                          color: isFav ? AppColors.accent : AppColors.textSecondary,
                                          size: 23,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
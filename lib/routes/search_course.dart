import 'package:flutter/material.dart';
import 'package:su_credit/utils/colors.dart';
import 'package:su_credit/utils/styles.dart';
import 'package:su_credit/utils/dimensions.dart';
import 'package:su_credit/routes/course_info.dart';
import 'package:su_credit/utils/favoriteCourses.dart';

class SearchCoursesPage extends StatefulWidget {
  const SearchCoursesPage({super.key});

  @override
  State<SearchCoursesPage> createState() => _SearchCoursesPageState();
}

class _SearchCoursesPageState extends State<SearchCoursesPage> {
  String searchQuery = '';
  final List<String> courses = [
    'CS301 - Algorithms',
    'CS302 - Formal Languages and Automata',
    'CS305 - Programming Languages',
    'CS308 - Software Engineering',
    'CS403 - Distributed Systems',
    'CS407 - Theory of Computation',
  ];

  void _toggleFavorite(String course) {
    final list = favoriteCourses.value;
    if (list.contains(course)) {
      favoriteCourses.value = List.from(list)..remove(course);
    } else {
      favoriteCourses.value = List.from(list)..add(course);
    }
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
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Filter',
                        style: AppStyles.buttonText.copyWith(color: AppColors.surface),
                      ),
                      const Icon(Icons.arrow_drop_down, color: AppColors.surface),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<String>>(
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

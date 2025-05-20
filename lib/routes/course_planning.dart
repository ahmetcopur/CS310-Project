import 'package:flutter/material.dart';
import 'package:su_credit/utils/colors.dart';
import 'package:su_credit/utils/dimensions.dart';
import 'package:su_credit/utils/styles.dart';
import 'package:su_credit/utils/favoriteCourses.dart';
import 'package:su_credit/routes/schedule.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoursePlanningPage extends StatefulWidget {
  const CoursePlanningPage({super.key});

  @override
  State<CoursePlanningPage> createState() => _CoursePlanningPageState();
}

class _CoursePlanningPageState extends State<CoursePlanningPage> {
  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    try {
      final favoritesDoc = await FirebaseFirestore.instance
          .collection('userPreferences')
          .doc(userId)
          .get();
      if (favoritesDoc.exists &&
          favoritesDoc.data()?['favoriteCourses'] is List) {
        favoriteCourses.value =
            List<String>.from(favoritesDoc.data()?['favoriteCourses'] ?? []);
      }
    } catch (e) {
      debugPrint('Error loading favorites in CoursePlanningPage: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: EdgeInsets.symmetric(
                vertical: AppDimensions.paddingLarge,
                horizontal: AppDimensions.paddingMedium,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon:
                    const Icon(Icons.arrow_back, color: AppColors.surface),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text('Course Planning',
                      style: AppStyles.screenTitle
                          .copyWith(color: AppColors.surface)),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: AppColors.backgroundColor,
                padding: EdgeInsets.all(AppDimensions.paddingMedium),
                child: Column(
                  children: [
                    const Expanded(child: _ScheduleSection()),
                    AppDimensions.verticalSpace(AppDimensions.paddingMedium),
                    Expanded(
                      child: _SectionBox(
                        title: 'Recommended Course Plan',
                        child: InteractiveViewer(
                          maxScale: 4,
                          minScale: 1,
                          panEnabled: true,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                                AppDimensions.borderRadiusMedium),
                            child: Image.asset('assets/schedule.png',
                                fit: BoxFit.contain),
                          ),
                        ),
                      ),
                    ),
                    AppDimensions.verticalSpace(AppDimensions.paddingMedium),
                    const Expanded(child: _SearchCoursesSection()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleSection extends StatelessWidget {
  const _ScheduleSection();

  @override
  Widget build(BuildContext context) => _SectionBox(
    title: 'Schedule',
    child: ValueListenableBuilder<List<Set<dynamic>>>(
      valueListenable: savedSchedules,
      builder: (_, list, __) {
        final tiles = <Widget>[];
        for (var i = 0; i < list.length; i++) {
          tiles.add(Expanded(
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (ctx) => SchedulePage(index: i)),
              ),
              child: Container(
                margin: EdgeInsets.only(
                    right: i == 0 ? AppDimensions.paddingSmall : 0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(
                      AppDimensions.borderRadiusMedium),
                ),
                child: Center(
                    child: Text('Schedule ${i + 1}',
                        style: AppStyles.bodyText)),
              ),
            ),
          ));
        }
        tiles.add(Expanded(
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (ctx) => const SchedulePage(index: -1)),
            ),
            child: Container(
              margin: EdgeInsets.only(
                  left: list.isEmpty ? 0 : AppDimensions.paddingSmall),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius:
                BorderRadius.circular(AppDimensions.borderRadiusMedium),
              ),
              child: const Center(
                  child: Icon(Icons.add, size: 48, color: AppColors.surface)),
            ),
          ),
        ));
        return Row(children: tiles);
      },
    ),
  );
}

class _SearchCoursesSection extends StatelessWidget {
  const _SearchCoursesSection();

  @override
  Widget build(BuildContext context) => _SectionBox(
    title: 'Search Courses',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Favorites',
            style: AppStyles.bodyText.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.accentTeal)),
        const Divider(thickness: 1),
        ValueListenableBuilder<List<String>>(
          valueListenable: favoriteCourses,
          builder: (_, favs, __) => favs.isEmpty
              ? Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('No favorites yet.',
                style: AppStyles.bodyText),
          )
              : Column(
            children: favs
                .map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(c,
                        style: AppStyles.bodyText,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ))
                .toList(),
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: () => Navigator.pushNamed(context, '/search_courses'),
          child: Text('See More',
              style: AppStyles.bodyText.copyWith(
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
        ),
      ],
    ),
  );
}

class _SectionBox extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionBox({required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(AppDimensions.paddingMedium),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius:
      BorderRadius.circular(AppDimensions.borderRadiusMedium),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
            AppStyles.sectionHeading.copyWith(color: AppColors.primary)),
        AppDimensions.verticalSpace(AppDimensions.paddingSmall),
        Expanded(child: child),
      ],
    ),
  );
}

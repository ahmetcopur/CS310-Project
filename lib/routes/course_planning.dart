import 'package:flutter/material.dart';
import 'package:su_credit/utils/colors.dart';
import 'package:su_credit/utils/dimensions.dart';
import 'package:su_credit/utils/styles.dart';
import 'package:su_credit/utils/favoriteCourses.dart';
import 'package:su_credit/routes/schedule.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class CoursePlanningPage extends StatefulWidget {
  const CoursePlanningPage({super.key});

  @override
  State<CoursePlanningPage> createState() => _CoursePlanningPageState();
}

class _CoursePlanningPageState extends State<CoursePlanningPage> {
  late StreamSubscription<User?> _authSubscription;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    loadSchedulesForCurrentUser();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      loadSchedulesForCurrentUser();
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    favoriteCourses.value = [];

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
                  AppDimensions.horizontalSpace(AppDimensions.paddingSmall),
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
                    const Expanded(child: _CoursePlanningTipsSection()),
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
    title: 'Your Schedules',
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
                    left: i > 0 ? AppDimensions.paddingSmall : 0,
                    right: AppDimensions.paddingSmall
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(
                      AppDimensions.borderRadiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: AppDimensions.elevationLow,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Schedule ${i + 1}', style: AppStyles.bodyText),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ValueListenableBuilder<int?>(
                          valueListenable: primaryScheduleIndex,
                          builder: (_, primary, __) {
                            final isPrimary = primary == i;
                            return IconButton(
                              icon: Icon(
                                isPrimary ? Icons.star : Icons.star_border,
                                color: isPrimary ? Colors.amber : Colors.grey.shade400,
                                size: AppDimensions.iconSizeMedium,
                              ),
                              onPressed: () => setPrimarySchedule(i),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: AppColors.accentRed, size: AppDimensions.iconSizeMedium),
                          onPressed: () => deleteSchedule(i),
                        ),
                      ],
                    ),
                  ],
                ),
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
              margin: EdgeInsets.only(left: list.isEmpty ? 0 : AppDimensions.paddingSmall),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.9),
                borderRadius:
                BorderRadius.circular(AppDimensions.borderRadiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: AppDimensions.elevationLow,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                  child: Icon(Icons.add, size: AppDimensions.iconSizeLarge * 1.5, color: AppColors.surface)),
            ),
          ),
        ));
        return Row(children: tiles);
      },
    ),
  );
}

class _CoursePlanningTipsSection extends StatelessWidget {
  const _CoursePlanningTipsSection();

  @override
  Widget build(BuildContext context) {
    return _SectionBox(
      title: 'Course Planning Tips',
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildTipItem(
            context,
            icon: Icons.checklist_rtl_outlined,
            text: 'Review degree requirements and prerequisites early on.',
          ),
          AppDimensions.verticalSpace(AppDimensions.paddingSmall / 2),
          _buildTipItem(
            context,
            icon: Icons.calendar_today_outlined,
            text: 'Plan your schedule to balance workload and avoid time conflicts.',
          ),
          AppDimensions.verticalSpace(AppDimensions.paddingSmall / 2),
          _buildTipItem(
            context,
            icon: Icons.explore_outlined,
            text: 'Explore electives aligning with your interests or career goals.',
          ),
          AppDimensions.verticalSpace(AppDimensions.paddingSmall / 2),
          _buildTipItem(
            context,
            icon: Icons.group_work_outlined,
            text: 'Consult with your academic advisor regularly for guidance.',
          ),
          AppDimensions.verticalSpace(AppDimensions.paddingSmall / 2),
          _buildTipItem(
            context,
            icon: Icons.favorite_border_outlined,
            text: 'Use "Favorite Courses" to shortlist courses for future planning.',
          ),
          AppDimensions.verticalSpace(AppDimensions.paddingSmall / 2),
          _buildTipItem(
            context,
            icon: Icons.lightbulb_outline,
            text: 'Mix challenging and manageable courses each semester.',
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, {required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.accentTeal, size: AppDimensions.iconSizeMedium - 4),
        AppDimensions.horizontalSpace(AppDimensions.paddingSmall),
        Expanded(
          child: Text(
            text,
            style: AppStyles.bodyText.copyWith(
              color: AppColors.textPrimary,
              fontSize: AppDimensions.fontSizeSmall,
            ),
          ),
        ),
      ],
    );
  }
}


class _SearchCoursesSection extends StatelessWidget {
  const _SearchCoursesSection();

  @override
  Widget build(BuildContext context) => _SectionBox(
    title: 'Your Course Shortlist',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Favorite Courses',
            style: AppStyles.subHeading.copyWith(
                color: AppColors.accentTeal
            )
        ),
        Divider(
          thickness: 1,
          height: AppDimensions.paddingSmall * 1.5,
          color: AppColors.backgroundColor,
        ),
        ValueListenableBuilder<List<String>>(
          valueListenable: favoriteCourses,
          builder: (_, favs, __) => favs.isEmpty
              ? Padding(
            padding: EdgeInsets.only(top: AppDimensions.paddingSmall),
            child: Text('No favorite courses yet. Use search to find and add them!',
                style: AppStyles.bodyTextSecondary),
          )
              : Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(right: AppDimensions.paddingSmall / 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: favs
                      .map((c) => Padding(
                    padding: EdgeInsets.symmetric(vertical: AppDimensions.paddingSmall / 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Icon(
                            Icons.star_border_purple500_outlined,
                            color: AppColors.accent,
                            size: AppDimensions.iconSizeSmall,
                          ),
                        ),
                        AppDimensions.horizontalSpace(AppDimensions.paddingSmall),
                        Expanded(
                          child: Text(c,
                            style: AppStyles.bodyText.copyWith(
                              fontSize: AppDimensions.fontSizeSmall,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ))
                      .toList(),
                ),
              ),
            ),
          ),
        ),
        if (favoriteCourses.value.isNotEmpty)
          AppDimensions.verticalSpace(AppDimensions.paddingSmall),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            icon: Icon(Icons.search, size: AppDimensions.iconSizeSmall),
            label: Text('Find Courses',
                style: AppStyles.buttonText.copyWith(
                  fontSize: AppDimensions.fontSizeSmall,
                )
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMedium,
                  vertical: AppDimensions.paddingSmall
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
              ),
              elevation: AppDimensions.elevationLow,
            ),
            onPressed: () => Navigator.pushNamed(context, '/search_courses'),
          ),
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
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.07),
          blurRadius: AppDimensions.elevationMedium,
          offset: const Offset(0, 2),
        ),
      ],
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
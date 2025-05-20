import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:su_credit/utils/colors.dart';
import 'package:su_credit/utils/dimensions.dart';
import 'package:su_credit/utils/styles.dart';
import 'package:provider/provider.dart';
import 'package:su_credit/providers/course_provider.dart';

class GraduationProgressPage extends StatefulWidget {
  const GraduationProgressPage({super.key});

  @override
  State<GraduationProgressPage> createState() => _GraduationProgressPageState();
}

class _GraduationProgressPageState extends State<GraduationProgressPage> {
  bool _isLoading = true;

  // Credit values - will be updated from Firebase
  int _requiredTotal = 125;
  int _earned = 75;
  int _minJunior = 64;
  int _maxSenior = 94;

  // Credit distribution
  int _coreCredits = 50;
  int _areaCredits = 15;
  int _freeCredits = 15;
  int _requiredCredits = 20;
  int _remainingCredits = 25;

  @override
  void initState() {
    super.initState();
    _loadCourseData();
  }

  Future<void> _loadCourseData() async {
    try {
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);
      courseProvider.loadUserCourses();

      final courses = courseProvider.courses;

      if (courses.isNotEmpty) {
        // Calculate total earned credits
        final totalEarned = courseProvider.totalCredits;

        // For simplicity, we'll calculate these as percentages of total
        final completedCredits = courseProvider.completedCredits;

        // Estimate different credit types (in a real app, you'd have proper categorization)
        // These are just estimates based on the total credits
        final coreCredits = (totalEarned * 0.5).round(); // 50% of earned credits
        final areaCredits = (totalEarned * 0.2).round(); // 20% of earned credits
        final freeCredits = (totalEarned * 0.15).round(); // 15% of earned credits
        final requiredCredits = (totalEarned * 0.15).round(); // 15% of earned credits
        final remainingCredits = _requiredTotal - totalEarned;

        if (mounted) {
          setState(() {
            _earned = totalEarned;
            _coreCredits = coreCredits;
            _areaCredits = areaCredits;
            _freeCredits = freeCredits;
            _requiredCredits = requiredCredits;
            _remainingCredits = remainingCredits;
            _isLoading = false;
          });
        }
      } else {
        // If no courses found, use default values
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // On error, use default values
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pieSections = [
      PieChartSectionData(value: _coreCredits.toDouble(), color: AppColors.accentOrange, title: ''),
      PieChartSectionData(value: _areaCredits.toDouble(), color: AppColors.accentTeal, title: ''),
      PieChartSectionData(value: _freeCredits.toDouble(), color: AppColors.accentBlue, title: ''),
      PieChartSectionData(value: _requiredCredits.toDouble(), color: AppColors.accentPink, title: ''),
      PieChartSectionData(value: _remainingCredits.toDouble(), color: AppColors.backgroundColor, title: ''),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.surface),
          onPressed: () { Navigator.pop(context); },
        ),
        title: Text('Graduation Progress',
            style: AppStyles.screenTitle.copyWith(color: AppColors.surface)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: AppDimensions.regularParentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _card(
              child: SizedBox(
                height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: pieSections,
                        sectionsSpace: 2,
                        centerSpaceRadius: 60,
                        startDegreeOffset: -90,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_earned/$_requiredTotal SU\nCredits Earned',
                        textAlign: TextAlign.center,
                        style: AppStyles.bodyText.copyWith(
                            color: AppColors.surface,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    _pieLabel('Free\nCredits', AppColors.accentPink,
                        const Offset(-130, -35)),
                    _pieLabel('Area\nCredits', AppColors.accentBlue,
                        const Offset(-96, 48)),
                    _pieLabel('Core\nCredits', AppColors.accentTeal,
                        const Offset(10, 85)),
                    _pieLabel('Required\nCredits', AppColors.accentOrange,
                        const Offset(110, -105)),
                  ],
                ),
              ),
            ),
            AppDimensions.verticalSpace(AppDimensions.paddingLarge),
            Text('Recommended SU Credits',
                style: AppStyles.sectionHeading
                    .copyWith(color: AppColors.primary, fontSize: 20)),
            AppDimensions.verticalSpace(AppDimensions.paddingSmall),
            _card(
              color: AppColors.primary,
              child: Column(
                children: [
                  Row(
                    children: [
                      _circle('$_minJunior', size: 56, textSize: 18),
                      Expanded(child: Container(height: 5, color: AppColors.surface)),
                      _circle('$_maxSenior', size: 56, textSize: 18),
                    ],
                  ),
                  SizedBox(
                    height: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          left: ((_earned - _minJunior) /
                              (_maxSenior - _minJunior))
                              .clamp(0, 1) *
                              (MediaQuery.of(context).size.width - 64),
                          child: Column(
                            children: [
                              const Icon(Icons.arrow_drop_up,
                                  size: 40, color: Colors.redAccent),
                              Text('$_earned',
                                  style: AppStyles.bodyText.copyWith(
                                      color: AppColors.surface,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Junior',
                          style: AppStyles.bodyText.copyWith(
                              color: AppColors.surface,
                              fontWeight: FontWeight.w600)),
                      Text('Senior',
                          style: AppStyles.bodyText.copyWith(
                              color: AppColors.surface,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Divider(color: AppColors.text, thickness: 1),
                  const SizedBox(height: 6),
                  Text('"Able to finish on time"',
                      style: AppStyles.bodyText.copyWith(
                          color: AppColors.surface,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ],
              ),
            ),
            AppDimensions.verticalSpace(AppDimensions.paddingLarge),
            Text('Notifications',
                style: AppStyles.sectionHeading
                    .copyWith(color: AppColors.primary, fontSize: 20)),
            AppDimensions.verticalSpace(AppDimensions.paddingSmall),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('You need to get:',
                      style: AppStyles.bodyText
                          .copyWith(fontWeight: FontWeight.bold)),
                  AppDimensions.verticalSpace(AppDimensions.paddingSmall),
                  _bullet('CS 301, CS 395, ENS 491, ENS 492',
                      AppColors.accentOrange),
                  _bullet('${_requiredTotal - _coreCredits - _earned} more Core Credits', AppColors.accentTeal),
                  _bullet('${(_requiredTotal * 0.2).round() - _areaCredits} more Area Credits', AppColors.secondary),
                  _bullet('${(_requiredTotal * 0.15).round() - _freeCredits} more Free Credits', AppColors.accentPink),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child, Color? color}) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: color ?? AppColors.surface,
      borderRadius:
      BorderRadius.circular(AppDimensions.borderRadiusMedium),
    ),
    padding: const EdgeInsets.all(16),
    child: child,
  );

  Widget _circle(String txt, {double size = 48, double textSize = 16}) =>
      Container(
        width: size,
        height: size,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration:
        const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(txt,
            style: AppStyles.bodyText.copyWith(
                color: AppColors.primary,
                fontSize: textSize,
                fontWeight: FontWeight.bold)),
      );

  Widget _bullet(String text, Color c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Container(
            width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AppStyles.bodyText)),
      ],
    ),
  );

  Widget _pieLabel(String txt, Color c, Offset off) => Positioned(
    left: 160 + off.dx,
    top: 160 + off.dy,
    child: Text(
      txt,
      textAlign: TextAlign.center,
      style: AppStyles.bodyText.copyWith(
          fontSize: 12, fontWeight: FontWeight.bold, color: c),
    ),
  );
}